# 10 · Certificaciones (motor GM y programas electivos)

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14  
**Alcance:** programas formativos electivos versionados (p. ej. personal de
club / Guías Mayores), no el catálogo entero ni la carga OCR de certificados.

> El registro de features las marca `PARCIAL`. El motor backend y las
> pantallas de participante/revisión existen en este workspace; **no** se
> ensayó un programa publicado en un entorno de piloto. No es clase (08) ni
> especialidad (09). La carga masiva OCR es otro circuito.

## Cuatro mensajes para la presentación

1. **Es electiva y queda fijada a una versión.** Al inscribirse se ata a la
   versión `PUBLISHED` vigente. Publicar otra no reescribe inscripciones
   ya abiertas.
2. **No entra quien no cumple las reglas de esa versión.** Tipos:
   `MIN_AGE`, `BAPTIZED`, `INVESTED_CLASS` (por `class_id`, no por nombre),
   `ACTIVE_CLUB_TYPE`, `ACTIVE_ROLE`. Sin reglas configuradas: no elegible.
3. **Se revisa requisito a requisito, luego la junta, luego se certifica.**
   Cola propia (`/certifications/reviews/*`), no `evidence-review`. Devolver
   es `CHANGES_REQUESTED`, no `REJECTED`.
4. **El participante no se certifica a sí mismo.** El revisor debe ser de
   su campo local (o admin global) y **distinto** del inscrito.

## Vocabulario

| Término | Significado | No confundir con |
|---|---|---|
| Certificación | Programa del catálogo (`certifications`) | Investidura de clase |
| Versión | Definición inmutable `DRAFT` / `PUBLISHED` / `RETIRED` | Año eclesiástico |
| Inscripción | `users_certifications` atada a una versión | `enrollments` de clase |
| Requisito | Sección con componentes (texto, archivo, etc.) | Sección de clase / honor |
| Cierre | Comprobante de junta + revisión final | Submit de especialidad |
| `CERTIFIED` | Cierre institucional del programa | `INVESTIDO` o honor `APPROVED` |

El motor **no** es “solo Guías Mayores”: hay seed de capacitación básica
del personal de Conquistadores
(`prisma/seeds/certifications/basic-pathfinder-staff-training.seed.ts`).
En la cita: programas avanzados electivos, con ejemplo GM si el piloto
tiene uno publicado.

## Recorrido

```text
Catálogo (versión PUBLISHED + reglas)
  └─ GET eligibility → POST enroll (una activa por programa)
        └─ por requisito: DRAFT → SUBMITTED
              ├─ revisor LF: APPROVED
              └─ CHANGES_REQUESTED → corrige y reenvía
                    └─ todos los obligatorios APPROVED
                          → READY_FOR_CLOSEOUT
                          → comprobante de junta (R2)
                          → submit-final
                                ├─ aprobar comprobante → APPROVED
                                └─ certify → CERTIFIED
```

### Inscripción

`POST /certifications/users/:userId/certifications/enroll` exige versión
publicada y `eligible=true`
(`certifications.service.ts`:122-187). Duplicado activo:
`CERT_ALREADY_ENROLLED`. Permiso `user_certifications:manage` sobre el
dueño.

`INVESTED_CLASS` busca un `enrollments` de ese `class_id` en `INVESTIDO`,
cualquier año (`eligibility-rule-handlers.ts`:107-125). No usa el nombre
traducido de la clase.

Toggle legacy `PATCH .../progress`: `410 CERT_LEGACY_ENDPOINT_DEPRECATED`
si la inscripción ya es versionada.

### Trabajo y revisión por requisito

Editable solo en `DRAFT` o `CHANGES_REQUESTED`. Envío con `lock_version`
(si está viejo: `CERT_CONCURRENT_UPDATE`). Evidencias: presign → R2 →
confirm; JPEG/PNG/WebP/PDF, máx. 10 MiB.

Bandeja: `GET /certifications/reviews/requirements`. Aprobar o devolver
(`comment` obligatorio al devolver). Historial append-only. Scope: mismo
`local_field_id` o admin global; el dueño no revisa
(`CERT_REVIEW_SCOPE_FORBIDDEN`).

Cuando todos los obligatorios están `APPROVED`, la inscripción pasa a
`READY_FOR_CLOSEOUT`.

### Cierre y certificación

Participante sube comprobante de junta y `submit-final` (solo desde
`READY_FOR_CLOSEOUT` y evidencia `CONFIRMED`). Revisor aprueba el
comprobante (`APPROVED`) o lo devuelve. Certificador
(`certifications:certify`) marca `CERTIFIED` (idempotente) y **vuelve a
comprobar** requisitos y comprobante dentro de la transacción
(`certification-closeout.service.ts`:447-518).

## Superficies (código, no piloto)

| Superficie | Qué hay | Qué no hay / límite |
|---|---|---|
| Backend | Catálogo, eligibility, enroll, requisitos, evidencias, bandejas, cierre, admin de versiones | Vacío de reglas = no inscribe |
| App | `/home/certifications`, detalle, progreso, requisito, cierre (presign + `submit-final`) | Sin bandeja de revisor; closeout no relee el archivo ya subido |
| Admin | `/dashboard/certifications` (catálogo/versiones), `/dashboard/certifications/reviews` (requisitos y cierres) | El documento de dominio de agosto aún decía “panel pendiente”; el código actual sí lo tiene |
| OCR certificados | Circuito `certificate-bulk-imports` | No es este flujo |

## Contraste rápido

| | Certificación | Clase | Especialidad |
|---|---|---|---|
| Quién entra | Reglas de la versión | Edad/tipo/año o directiva | Sección activa + tipo |
| Unidad de revisión | Requisito compuesto | Evidencia de sección + pipeline de investidura | Paquete entero |
| Cola | `/certifications/reviews` | `/evidence-review` + investidura | `/evidence-review` |
| Cierre | Junta + `CERTIFIED` | `INVESTIDO` | `APPROVED` |

## Qué no demostrar todavía

- Un programa sin versión publicada o sin reglas.
- “Es el mismo circuito que honores”.
- Que el director de Unión, por cargo, certifica: hace falta
  `certifications:certify` y alcance de campo.
- Carga OCR como si fuera esta certificación.

## Guion mínimo (si el piloto tiene un programa publicado)

1. Elegibilidad: ticks y cruces por regla (clase investida, tipo de club…).
2. Inscribir. Abrir un requisito, enviar.
3. En panel, como revisor de **otro** usuario del mismo campo: aprobar.
4. Cuando esté listo: comprobante de junta → cierre → certificar.

Si no hay versión publicada: decir que el motor existe y el piloto debe
publicar el programa; no improvisar el toggle legacy.

## Fuentes

- Dominio: `docs/features/certificaciones-guias-mayores.md`,
  `certificaciones-guias-mayores-revision-workflow.md`.
- Canon: `docs/canon/runtime-user-certifications.md`.
- API: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` §certifications y Admin.
- Código: `certifications.service.ts`, `eligibility-rule-handlers.ts`,
  `certification-review.service.ts`, `certification-closeout.service.ts`,
  `certification_closeout_view.dart`, admin `certification-reviews-client.tsx`.
- Relacionadas: [08](08-clases-progresivas.md), [09](09-honores.md).

**Bloque 4 cerrado** a nivel de fichas de formación. Siguiente bloque del
calendario: eventos y camporees (semana 2).
