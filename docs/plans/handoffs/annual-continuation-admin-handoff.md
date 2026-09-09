# Handoff Admin — Inscripción anual de miembros (T7)

> Contrato REAL en `sacdia-backend` (T5–T6, 2026-09-09).
> Prefijo: `/api/v1`. Envelope de éxito: `{ status: 'success', data }`.
> Fuente: `sacdia-backend/src/annual-membership/`.
> Spec: `docs/superpowers/specs/2026-09-08-inscripcion-anual-miembros-design.md`.
> API canónica: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (annual-membership).
>
> **Ownership UI:** Cursor Composer. **Este handoff no incluye UI.**
> Codex no rediseña el admin. Adaptar pantallas existentes; no crear un flujo
> paralelo de autoinscripción ni mezclar esto con preelección de director.
>
> Preelección de director (Campo Local, año futuro): documento aparte
> [`director-designation-admin-handoff.md`](./director-designation-admin-handoff.md).
> Esa programación **no** es esta lista y **no** da acceso operativo.

---

## 0) Qué cambió respecto al handoff viejo

| No usar | Vigente |
|---|---|
| `originYearId` | Año **vigente** (`ecclesiastical_year_id` del item) |
| `already_continued` / `last_role` | `annual_status`, `current_role`, `eligibility` |
| POST `{ continued, skipped }` | `{ results: [{ outcome, enrollment_id, error_code }] }` |
| Autoinscripción `POST .../annual-enroll` | **403** `ANNUAL_ENROLL_REQUIRES_DIRECTIVE` (D01) |
| Copy «Continúan este año» | «Miembros no inscritos» / «Inscribir para {period}» |
| Lista = año anterior | No inscritos de **pertenencia de esta sección** en el año vigente |

El POST **sí matricula clase** en la misma transacción (`enrollment_id` cuando `outcome=enrolled`). No llamar `ClassesService.enrollUser`.

---

## 1) Modelo funcional

Tras el corte, quien vuelve a GM (u otro no inscrito) queda `member` + `status=inactive` en el año vigente. **No** hay permisos de club. La **directiva de la sección destino** activa esa fila.

| Estado | Significado | UI |
|---|---|---|
| `member` + `inactive` + año vigente | No inscrito | Lista de esta pantalla |
| `member` + `active` en **esta** sección | Ya inscrito aquí | No aparece en GET |
| Director `active` en **esta** sección | Nombramiento vigente | No aparece en GET |
| Director `active` en **otra** sección | Sigue siendo no inscrito **aquí** | Sí puede aparecer |
| Plan `director_succession_plans` | Preelección futura | **Otra** pantalla LF. Nunca en esta lista |

El rol creado/activado es siempre `member`. No copiar director/secretario. Cargos: rutas de asignación / designation.

---

## 2) Autorización

GET y POST `/club-sections/:sectionId/annual-continuations`:

- JWT
- Permiso: `club_members:approve`
- Recurso: `@AuthorizationResource` `{ type: 'club_section', idParam: 'sectionId' }`
- Territorio: el guard de sección. Campo Local **ajeno** → 403. Dueño del perfil **no** autoriza el POST.

`POST /users/:userId/membership/annual-enroll`:

- **No usar en admin.** Siempre 403 `ANNUAL_ENROLL_REQUIRES_DIRECTIVE`. Sin efectos. D01 pendiente.

---

## 3) GET `/api/v1/club-sections/:sectionId/annual-continuations`

Query:

| Param | Tipo | Default | Notas |
|---|---|---|---|
| `page` | number | 1 | 1-indexed |
| `limit` | number | 20 | Máx. **100** |
| `search` | string | — | Nombre, acotado |

**200:**

```json
{
  "status": "success",
  "data": {
    "data": [
      {
        "user_id": "uuid",
        "name": "Luis Pérez Soto",
        "base_section_id": 301,
        "ecclesiastical_year_id": 8,
        "annual_status": "not_enrolled",
        "current_role": null,
        "eligibility": "eligible",
        "blocked_reason": null,
        "suggested_class": { "status": "resolved", "class_id": 42 }
      }
    ],
    "meta": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPages": 1,
      "hasNextPage": false,
      "hasPreviousPage": false
    }
  }
}
```

`suggested_class`:

| status | Campos |
|---|---|
| `resolved` | `class_id` |
| `blocked` | `code` (p. ej. `ANNUAL_CLASS_POLICY_UNRESOLVED`) |
| `pending` | Política aún no evaluada |

`ecclesiastical_year_id` es el **ID** del año vigente (no necesariamente el calendario). El CTA usa ese valor: «Inscribir para {ecclesiastical_year_id}». No inventar un nombre de periodo.

Ignorar si llega `already_continued` o `last_role`.

**Errores GET:**

| HTTP | code | Cuándo |
|---|---|---|
| 401 | — | JWT ausente/inválido |
| 403 | `GUARD_PERMISSION_DENIED` / scope | Sin `club_members:approve` o sección fuera de territorio |
| 404 | `CLUB_SECTION_NOT_FOUND` | Sección inexistente |
| 404 | `CLASS_ACTIVE_YEAR_NOT_FOUND` | Sin año eclesiástico vigente |
| 409 | `ECCLESIASTICAL_YEAR_AMBIGUOUS` | Más de un año vigente |

**Estados UI GET:** loading, vacío («Nadie pendiente de inscripción»), error + reintento, filas `eligibility=blocked` no seleccionables.

---

## 4) POST misma ruta

Body:

```json
{ "user_ids": ["uuid-1", "uuid-2"] }
```

- UUIDs v4, 1–100, distintos (el servidor deduplica).
- No enviar IDs bloqueados si la UI ya los filtró; si se envían, vuelven `blocked`/`failed` por usuario. **No** hay 400 de lote «user not in origin».

**200:**

```json
{
  "status": "success",
  "data": {
    "results": [
      {
        "user_id": "uuid",
        "outcome": "enrolled",
        "club_section_id": 301,
        "ecclesiastical_year_id": 8,
        "enrollment_id": 99,
        "error_code": null
      }
    ]
  }
}
```

| outcome | Significado | UI |
|---|---|---|
| `enrolled` | Activó `member` + matrícula si aplicó | Contar como inscrito |
| `already_enrolled` | Ya `member active` (o director) **en esta sección** | Idempotente; no error |
| `blocked` | Política / base / solicitud pendiente | Mostrar `error_code` |
| `failed` | Error no clasificado como blocked | Mostrar `error_code` |

`enrollment_id` solo fiable en `enrolled`.

Códigos frecuentes en `error_code` / `suggested_class.code`:

- `ANNUAL_CLASS_POLICY_UNRESOLVED` (D02 / catálogo)
- `ANNUAL_MEMBERSHIP_BASE_UNRESOLVED`
- `CLASS_PREREQUISITE_NOT_MET`
- `CLASS_GM_INVESTITURE_REQUIRED`
- `CLASS_NOT_AVAILABLE_FOR_YEAR`
- `CLASS_NOT_FOUND`
- `MR_ALREADY_PENDING`
- `INTERNAL_SERVER_ERROR`

**Errores de petición (no por usuario):**

| HTTP | code | Cuándo |
|---|---|---|
| 400 | validación class-validator | Array vacío, >100, UUID inválido |
| 403 | permiso/recurso | Directiva de otra sección / sin approve |
| 404 | `CLUB_SECTION_NOT_FOUND` | Sección inexistente |
| 404 | `CLASS_ACTIVE_YEAR_NOT_FOUND` | Sin año vigente |

Tras POST: refetch GET. Invalidar caché de miembros de esa sección. Los clientes de los inscritos deben refrescar `/auth/me`. **FCM no es barrera de seguridad** ni sustituye el refresh.

**Estados UI POST:** loading del lote, éxito, **parcial** (mezcla enrolled + blocked/failed), error de red/403.

---

## 5) Copy

```
Título:     Miembros no inscritos
Subtítulo:  Selecciona a quién inscribir en esta sección. El cargo anterior no se copia.
CTA:        Inscribir para {ecclesiastical_year_id}

Columnas sugeridas:
  - Nombre
  - current_role (si viene; contexto, NO el rol que se creará)
  - Clase sugerida (suggested_class)
  - Elegibilidad: elegible / no elegible + blocked_reason

No escribir: «mantienen su cargo», «continúan como directores», «inscríbete tú».
```

Banner de miembro no inscrito (si el admin lo muestra): **«No inscrito este año. La directiva realiza tu inscripción»**. Sin botón Inscribirme.

---

## 6) Superficies admin a adaptar (no rediseñar)

- `sacdia-admin/src/lib/api/clubs.ts` — cliente GET/POST del contrato de arriba
- `sacdia-admin/src/lib/clubs/actions.ts` y `actions.test.ts`
- Detalle de club: `src/app/(dashboard)/dashboard/clubs/[id]/page.tsx` y bloques de sección
- Preelección: `src/lib/auth/director-succession.ts` + `DesignationBlock` — **separada** del director operativo. Ver handoff T2.

Campo Local ve al director **operativo** en leadership vigente y la **programación futura** en designation. No fusionar esos bloques. El sucesor no aparece como director en selectores operativos.

---

## 7) Verificación admin (runner real)

Desde `sacdia-admin` (package.json: `"test": "vitest run"`, `"typecheck": "tsc --noEmit"`):

```bash
cd sacdia-admin
pnpm test
pnpm exec tsc --noEmit
```

No ejecutar `next build` ni este handoff como implementación. D01/D02 siguen abiertos: no CTA de autoinscripción; no inventar reglas GM investido/multianual.
