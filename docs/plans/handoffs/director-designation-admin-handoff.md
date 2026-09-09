# Handoff Admin — Preelección de director (T2)

> Contrato REAL implementado en `sacdia-backend` (T2, 2026-09-09).
> Prefijo global: `/api/v1`. Envelope de éxito: `{ status: 'success', data }`.
> Fuente: `sacdia-backend/src/clubs/clubs.controller.ts`, `DirectorDesignationService`.
>
> **Ownership visual:** Composer. La UI de designación ya existe:
> `sacdia-admin/src/components/clubs/detail/sections-tab.tsx` (`DesignationBlock`).
> No rediseñar ni duplicar el bloque. No inventar destitución en diciembre.
> Adaptar el cliente al JSON nuevo; no seguir el contrato `assignment_id` / PUT.

## 1) Modelo funcional

Hay **un** director operativo por sección **y año** (`club_role_assignments.status=active`).
Campo Local **preelege** al director del año siguiente en `director_succession_plans`.
**No** se crea CRA `status=designated`. El sucesor **no** recibe permisos ni aparece
en `/auth/me` ni en selectores operativos.

| Concepto | Qué es | Visible como director | Permisos de club |
|---|---|---|---|
| Operativo | CRA `status=active`, año vigente | Sí (un solo bloque) | Sí |
| Preelegido N+1 | `director_succession_plans.status=scheduled` | No. Solo GET de programación (actores LF/admin) | No |

Nunca hay dos directores operativos visibles en la misma sección.
`GET /clubs/:clubId/leadership` solo lista `status=active` del año vigente.

El corte anual (T3) activará el plan. Hasta T3 el cron local aún puede hablar
de CRA `designated` legado; el endpoint de preelección **ya no** escribe esas filas.

`POST .../director-succession` es **destitución del año vigente**
(`getCurrentYear()`). **No** es la herramienta de diciembre para N+1.

## 2) Actores y permisos

Todas las rutas `.../director-designation` (GET, POST, PATCH, DELETE):

- Permiso: `club_roles:assign`
- Recurso: `@AuthorizationResource` tipo `club`
- Extra: `assertCanDesignateDirector` — roles globales `super-admin`, `admin`,
  `director-lf`, `assistant-lf` **y** `canManageClub` sobre el club de la sección
- La sección debe pertenecer a `clubId` de la URL; si no → 403 `GUARD_ASSIGNMENT_SCOPE_INVALID`
- GET **también** exige esos actores
- 403 `GUARD_PERMISSION_DENIED` si falla el actor o `canManageClub`

## 3) Contrato JSON

### POST `/clubs/:clubId/sections/:sectionId/director-designation`

Header obligatorio: `Idempotency-Key`.

Body:

```json
{
  "user_id": "<uuid>",
  "ecclesiastical_year_id": 8
}
```

Crea `director_succession_plans` `status=scheduled`. **No** termina al director operativo.
Sección vacante: `outgoing_assignment_id` = `null`.

201 `data`:

```json
{
  "succession_id": "uuid",
  "user_id": "uuid",
  "ecclesiastical_year_id": 8,
  "effective_date": "2027-01-01",
  "status": "scheduled",
  "version": 1,
  "outgoing_assignment_id": "uuid | null"
}
```

Misma clave + mismo payload → mismo `succession_id`. Misma clave + payload distinto → 409 `IDEMPOTENCY_KEY_REUSED`.

### GET `/clubs/:clubId/sections/:sectionId/director-designation?yearId=`

Mismos actores que POST. `yearId` obligatorio. `data` es el objeto de programación
o `null`.

### PATCH misma path

Body:

```json
{
  "succession_id": "uuid",
  "version": 1,
  "successor_user_id": "uuid"
}
```

Reemplaza sucesor de un plan `scheduled`. No invalida caché del sucesor.

`PUT` **ya no existe**.

### DELETE misma path

Query: `successionId` (uuid) y `version` (int). Cancela el plan `scheduled`.

### Errores

| HTTP | Code | Cuándo |
|---|---|---|
| 400 | `CLUB_DIRECTOR_PLAN_YEAR_INVALID` | Año de preelección no es futuro (por fechas, no por `year_id`) |
| 400 | `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID` | Succession/assignment/update de director usa un año que no es el vigente |
| 409 | `CLUB_DIRECTOR_DESIGNATED_UNRECONCILED` | PATCH de CRA `designated` legado no reconciliado |
| 400 | `CLUB_DIRECTOR_PLAN_IDEMPOTENCY_REQUIRED` | POST sin `Idempotency-Key` |
| 409 | `CLUB_DIRECTOR_PLAN_CONFLICT` | Ya hay plan abierto (`scheduled`/`activated`/`blocked`) en esa sección/año |
| 409 | `CLUB_DIRECTOR_PLAN_VERSION_CONFLICT` | `version` obsoleta en PATCH/DELETE |
| 409 | `IDEMPOTENCY_KEY_REUSED` | Misma Idempotency-Key, payload distinto |
| 404 | `CLUB_DIRECTOR_PLAN_NOT_FOUND` | PATCH/DELETE sin plan `scheduled` |
| 403 | `GUARD_PERMISSION_DENIED` | Sin permiso o sin actor LF/admin + `canManageClub` |
| 403 | `GUARD_ASSIGNMENT_SCOPE_INVALID` | La sección no pertenece al `clubId` de la URL |

### POST `/clubs/:clubId/sections/:sectionId/director-succession`

Destitución **año vigente**. Body year y assignment year deben coincidir con `getCurrentYear()`.
No usar para N+1.

`POST .../director-assignment` también exige año vigente.

## 4) UI ya implementada — adaptar contrato, no duplicar

`DesignationBlock` en el tab de secciones del detalle de club:

- Un bloque de **director operativo** (leadership / officers). No añadir un
  segundo director operativo.
- Bloque aparte para la preelección (hoy habla de “designado”).
- Cliente a actualizar: `getClubSectionDirectorDesignation` /
  `designateClubSectionDirector` / `replaceClubSectionDirectorDesignation`
  en `sacdia-admin/src/lib/api/clubs.ts`
  - POST: enviar `Idempotency-Key`; leer `succession_id` (ya no `assignment_id`)
  - Reemplazo: PATCH con `{ succession_id, version, successor_user_id }`
  - Cancelar: DELETE con `successionId` + `version` si la UI lo ofrece

## 5) Qué Composer NO debe hacer

- **No destituir en diciembre.** No llamar `director-succession` al preelegir N+1.
- No mostrar al preelegido como director del año vigente.
- No añadir un segundo director en el bloque operativo.
- No blacklistear JWT ni pedir logout al cortar el año.
- No tocar `sacdia-backend` ni `sacdia-app`.
- No crear CRA `designated` desde el admin.
- No inventar endpoints, status ni error codes.

## 6) Polish opcional

1. Heading: mostrar nombre de calendario del año eclesiástico si hay dato.
2. El cliente no debe tratar `assignment_id` como contrato vigente.
