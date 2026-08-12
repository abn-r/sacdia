# Certificaciones de Guías Mayores

**Estado**: MOTOR VERSIONADO (backend runtime en `feat/configurable-certifications`; admin/app en migración)

## Descripción de dominio

Las certificaciones de Guías Mayores son programas formativos avanzados para miembros investidos. A diferencia de las clases progresivas (secuenciales por edad), son electivas y se configuran como **definiciones versionadas**: cada inscripción queda fijada a una versión `PUBLISHED` inmutable.

Estructura: certificación → versión → módulos → secciones (requisitos) → componentes tipados. El progreso ya no es un toggle booleano por sección; cada requisito sigue estados `DRAFT` → `SUBMITTED` → `APPROVED` | `CHANGES_REQUESTED`, con revisión institucional requisito a requisito y cierre final con comprobante de junta.

## Qué existe (verificado contra código — `sacdia-backend` branch `feat/configurable-certifications`)

### Backend (`CertificationsModule`)

**Controladores:**

| Controlador | Endpoints | Rol |
| --- | ---: | --- |
| `CertificationsController` / `UserCertificationsController` | 8 | Catálogo, inscripción, elegibilidad, progreso, legacy |
| `UserCertificationRequirementsController` | 6 | Borrador, envío, evidencias por requisito |
| `CertificationCloseoutController` | 7 | Cierre participante + bandeja/certificación final |
| `CertificationReviewController` | 4 | Bandeja y decisión por requisito |
| `AdminCertificationsController` | 8 | Configuración y publicación de versiones |

Referencia canónica: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` §certifications y §Admin - Certifications.

**Servicios principales:** `CertificationsService`, `CertificationEligibilityService`, `CertificationRequirementsService`, `CertificationEvidenceService`, `CertificationReviewService`, `CertificationCloseoutService`, `CertificationDefinitionsService`.

**Dominio puro:** `certification-definition.types.ts`, `certification-state-machine.ts` (transiciones y bloqueos).

**Permisos runtime:**

- Participante/delegado: `user_certifications:read`, `user_certifications:manage`
- Configuración: `certifications:configure`, `certifications:publish`
- Revisión: `certifications:review`, `certifications:certify`

**Legacy (deprecado 2026-08-11):** `PATCH .../progress` responde `410 CERT_LEGACY_ENDPOINT_DEPRECATED` para inscripciones con `certification_version_id`.

### Admin (`sacdia-admin`)

- Catálogo de solo lectura existente; **panel de configuración versionada pendiente** (handoff en `docs/plans/handoffs/configurable-certifications-admin-handoff.md`).

### App (`sacdia-app`)

- Screens legacy con toggle booleano; **migración al flujo por requisito pendiente**.

### Base de datos

Modelos nuevos/ampliados (ver `docs/database/SCHEMA-REFERENCE.md`):

- Definición: `certification_versions`, `certification_eligibility_rules`, `certification_requirement_components`
- Ejecución: `users_certifications` (+ `certification_version_id`, `status`, `lock_version`), `certification_section_progress` (+ `status`, `enrollment_id`), `certification_component_responses`, `certification_evidences`, `certification_review_events`, `certification_closeout_evidences`
- Proyección legacy retenida: `certification_module_progress`

## Requisitos funcionales (motor versionado)

1. Elegibilidad configurable por versión (`MIN_AGE`, `BAPTIZED`, `INVESTED_CLASS`, `ACTIVE_CLUB_TYPE`, `ACTIVE_ROLE`); evaluada al inscribir y expuesta en endpoint de elegibilidad.
2. Una inscripción activa por usuario/certificación; fijada a versión publicada vigente.
3. Requisitos editables solo en `DRAFT` o `CHANGES_REQUESTED`.
4. Evidencias privadas en R2 con presign/confirm; MIME allow-list y máximo 10 MiB.
5. Revisión institucional por requisito con bandeja propia (no `evidence-review`).
6. Cierre: todos los requisitos obligatorios `APPROVED` + comprobante de junta confirmado → `submit-final` → revisión final → `certify`.
7. Historial append-only en `certification_review_events`.

## Decisiones de diseño

- **Versiones inmutables:** solo `DRAFT` es editable; publicar retira la versión anterior.
- **Paths de participante:** `/users/:userId/certifications/:certificationId/requirements/:sectionId/...` (sin `enrollmentId` en URL).
- **Bandeja propia:** estados `APPROVED`/`CHANGES_REQUESTED`, distintos de clases/honores (`VALIDATED`/`REJECTED`). Ver ADR #8 en `docs/api/ARCHITECTURE-DECISIONS.md`.
- **Browse vs progresión:** `certifications:read` (catálogo) separado de `user_certifications:*`. Ver `docs/canon/runtime-user-certifications.md`.

## Flujo operativo

Detalle paso a paso: [`certificaciones-guias-mayores-revision-workflow.md`](certificaciones-guias-mayores-revision-workflow.md).

## Gaps y pendientes

- UI admin para configurar/publicar versiones y árbol de componentes.
- App móvil: pantallas de requisito, presign/confirm, bandeja de revisión LF.
- Reportes administrativos por club/campo local.
- Seed de certificación “Capacitación básica para el personal del Club de Conquistadores” (PR 4 del plan).
- Retirar proyección `certification_module_progress` cuando clientes dejen de depender del porcentaje legacy.

## Prioridad y siguiente acción

- **Alta:** completar consumo en app del flujo por requisito; alinear admin con `AdminCertificationsController`.
- **Siguiente acción concreta:** implementar pantalla de detalle de requisito en app consumiendo `GET/PUT/POST .../requirements/:sectionId`.
