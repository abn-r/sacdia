# Runtime — User Certifications (progresión admin-level)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: operaciones admin-level sobre progresión de certificaciones de miembros (inscripción, requisitos, cierre, baja). Distinto del catálogo público de tipos de certificación que permanece bajo browse sin permiso fino.

<!-- VERIFICADO contra código 2026-08-11: motor configurable en feat/configurable-certifications. Permisos user_certifications:* + certifications:configure|publish|review|certify. -->

---

## 1. Propósito

Canoniza las operaciones **admin-level** sobre certificaciones por usuario (Guías Mayores): inscribir, ejecutar requisitos versionados, revisar, certificar y eliminar asignación. Es responsabilidad distinta del catálogo público de tipos de certificación.

La distinción explícita evita la colisión semántica detectada en Sprint C: `certifications:read` cubre browse catalog; `user_certifications:*` cubre progresión. Los permisos **`certifications:configure`**, **`certifications:publish`**, **`certifications:review`** y **`certifications:certify`** cubren configuración editorial y revisión institucional sin colapsar browse ni progresión del participante.

---

## 2. Alcance canonizado

Dentro del canon:
- operaciones sobre inscripciones versionadas (`users_certifications` + requisitos + cierre);
- permisos `user_certifications:read` / `user_certifications:manage` (participante/delegado);
- permisos `certifications:configure`, `certifications:publish`, `certifications:review`, `certifications:certify` (LF/admin);
- scope de autoridad por rol y campo local en revisión;
- separación explícita del dominio de browse catalog (`OptionalJwtAuthGuard` en listado/detalle).

Fuera del canon:
- fórmula detallada de elegibilidad por regla (responsabilidad de `CertificationEligibilityService`);
- UI admin/app (ver feature docs).

---

## 3. Permisos canonizados

### Progresión del participante (dominio `user_`, Sprint C)

- `user_certifications:read` — leer inscripciones, elegibilidad, progreso y requisitos;
- `user_certifications:manage` — inscribir, borrador/envío, evidencias, cierre, abandono.

Grants: liderazgo de club + `assistant-lf` (GLOBAL) + JOIN copies + admin/super-admin. Ver seeds en `role-permissions.seed.sql`.

**NO** granted ampliamente a `member`/`user` para operar sobre terceros; el owner del `userId` mantiene self-service vía `@AuthorizationResource`.

### Configuración y revisión institucional (motor versionado, 2026-08-11)

| Permiso | Acción |
| --- | --- |
| `certifications:configure` | Crear/editar certificaciones, versiones `DRAFT`, reglas y árbol |
| `certifications:publish` | Publicar o retirar versiones |
| `certifications:review` | Bandejas y decisiones sobre requisitos y cierre |
| `certifications:certify` | Marcar inscripción como `CERTIFIED` |

Grants seed (GLOBAL): `director-lf`, `assistant-lf`, `admin`, `super-admin`.

`certifications:read` (browse) **no** sustituye ninguno de los anteriores.

---

## 4. Superficie API canonizada

Paths efectivos bajo `/api/v1` (detalle en `ENDPOINTS-LIVE-REFERENCE.md`):

| Dominio | Ejemplos | Permiso |
| --- | --- | --- |
| Inscripción | `POST .../users/:userId/certifications/enroll` | `user_certifications:manage` |
| Lectura | `GET .../users/:userId/certifications`, `.../eligibility`, `.../progress` | `user_certifications:read` |
| Requisito | `GET/PATCH/POST .../certification-enrollments/:enrollmentId/requirements/:requirementId/...` | read / manage |
| Cierre participante | `POST .../closeout-evidence/*`, `POST .../submit-final` | `user_certifications:manage` |
| Revisión | `GET/POST /certifications/reviews/requirements/*` | `certifications:review` |
| Certificación final | `POST /certifications/reviews/final/:enrollmentId/certify` | `certifications:certify` |
| Configuración | `POST/PATCH /admin/certifications/...` | `configure` / `publish` |
| Legacy | `PATCH .../progress` | `user_certifications:manage` — **deprecado 2026-08-11** para inscripciones versionadas (`410 CERT_LEGACY_ENDPOINT_DEPRECATED`) |

**Invariante de path:** rutas de ejecución de participante (requisitos, evidencias y cierre) identifican la inscripción con **`userId` + `enrollmentId`** (`.../certification-enrollments/:enrollmentId/...`), validando que la inscripción exista, esté activa y pertenezca al `userId` autenticado. La revisión final también usa `enrollmentId` en bandeja institucional.

Catálogo público: `GET /certifications/certifications`, `GET /certifications/certifications/:id` — `OptionalJwtAuthGuard`, sin `@RequirePermissions`.

---

## 5. Relación con otros canones

- `docs/canon/runtime-member-of-month.md` §7 — patrón de dominio propio tras migración.
- `docs/canon/runtime-user-folders.md` — dominio hermano corregido por colisión de Sprint C.
- `docs/canon/decisiones-clave.md` §19 — decisión conjunta Sprint C + fix colisión.
- `docs/api/ARCHITECTURE-DECISIONS.md` §8 — bandeja propia vs. `evidence-review`.

---

## 6. Invariantes

- `user_certifications:*` es el único permiso canónico para operaciones de participante/delegado sobre progresión; no reutilizar `users:update_profile` ni `users:read_detail`;
- `certifications:read` (browse) ≠ `user_certifications:read` (progresión) ≠ `certifications:review` (institucional);
- `certifications:configure` / `:publish` / `:review` / `:certify` no amplían browse ni self-service del participante;
- inscripciones versionadas **no** usan `PATCH .../progress`; el progreso deriva de requisitos `APPROVED`;
- evidencias en R2 privado; URLs firmadas solo tras ownership o scope de revisor;
- endpoints de browse catalog mantienen `OptionalJwtAuthGuard` — visibilidad pública del catálogo.
