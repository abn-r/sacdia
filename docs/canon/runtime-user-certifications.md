# Runtime — User Certifications (progresión admin-level)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: operaciones admin-level sobre progresión de certificaciones de miembros (inscripción, actualización, baja). Distinto del catálogo público de tipos de certificación que permanece bajo `certifications:read` (browse)

<!-- VERIFICADO contra código 2026-04-22: certifications.controller.ts con 5 handlers migrados, colisión semántica resuelta con prefix user_, permisos propios user_certifications:read/manage. -->

---

## 1. Propósito

Canoniza las operaciones **admin-level** sobre certificaciones por usuario (Guías Mayores GM): inscribir a un miembro, actualizar progreso, eliminar asignación. Es responsabilidad distinta del catálogo público de tipos de certificación (browse de especialidades disponibles).

La distinción explícita evita la colisión semántica detectada en Sprint C: antes, `certifications:read` cubría browse catalog y estaba asignado ampliamente (member, user, counselor, etc.); reutilizarlo para endpoints admin-level habría expandido silenciosamente el scope. La solución canonizada: prefix `user_` para lo admin, conservar `certifications:read` para browse.

---

## 2. Alcance canonizado

Dentro del canon:
- operaciones admin sobre `user_certifications` (inscripción, progreso, baja);
- permisos propios `user_certifications:read` / `user_certifications:manage`;
- scope de autoridad por rol;
- separación explícita del dominio de browse catalog (`certifications:read`).

Fuera del canon:
- browse público de tipos de certificación (queda en dominio `certifications:*` original);
- fórmula de progreso (responsabilidad del servicio).

---

## 3. Permisos canonizados

Permisos vigentes (dominio propio, introducidos en 2026-04-22 por corrección de Sprint C):

- `user_certifications:read` — leer progreso de certificación de cualquier usuario (admin-level);
- `user_certifications:manage` — inscribir, actualizar progreso, eliminar asignación (admin-level).

Grants tras corrección:
- `user_certifications:read` → `counselor`, `secretary`, `treasurer`, `secretary-treasurer`, `deputy-director`, `director` (CLUB) + `assistant-lf` (GLOBAL) + JOIN copies (director-lf, assistant-union, director-union, assistant-dia, director-dia) + admin/super_admin.
- `user_certifications:manage` → subconjunto: `deputy-director`, `director` (CLUB leadership) + `assistant-lf` (GLOBAL) + JOIN + admin/super_admin.

NO granted: `user`, `member`, `coordinator`, `zone-coordinator`, `general-coordinator`, `pastor`. Estos roles conservan `certifications:read` (browse catalog) pero no operan sobre progresión de otros usuarios.

---

## 4. Superficie API canonizada

| Path | Método | Handler | Permiso |
|------|--------|---------|---------|
| `/certifications` (enroll user) | POST | `enrollUser` | `user_certifications:manage` |
| `/certifications/user/:userId` | GET | `getUserCertifications` | `user_certifications:read` |
| `/certifications/:assignmentId/progress` | GET | `getCertificationProgress` | `user_certifications:read` |
| `/certifications/:assignmentId/progress` | PATCH | `updateProgress` | `user_certifications:manage` |
| `/certifications/:assignmentId` | DELETE | `deleteCertification` | `user_certifications:manage` |

Los endpoints de catálogo público (GET `/certifications` list, GET `/certifications/:id` detail) operan sin `@RequirePermissions` (decorados con `OptionalJwtAuthGuard` solamente) — browsing abierto.

---

## 5. Relación con otros canones

- `docs/canon/runtime-member-of-month.md` §7 — patrón análogo de dominio propio tras migración.
- `docs/canon/runtime-user-folders.md` — dominio hermano también corregido por colisión de Sprint C.
- `docs/canon/decisiones-clave.md` §19 — decisión conjunta Sprint C + fix colisión.

---

## 6. Invariantes

- `user_certifications:*` es el único permiso canónico para operaciones admin sobre progresión de usuarios; reutilizar `users:update_profile` o `users:read_detail` rompe la frontera de concerns;
- `certifications:read` (browse catalog) y `user_certifications:read` (admin progression) son dos permisos distintos con grants distintos — jamás deben colapsarse;
- operaciones admin jamás pueden ejecutarse por rol sin grant explícito de `user_certifications:manage` (ej: member o coordinator no pueden inscribir a otro usuario aunque tengan `users:update_profile` por otras vías);
- endpoints de browse catalog mantienen `OptionalJwtAuthGuard` — son parte del canon como visibilidad pública.
