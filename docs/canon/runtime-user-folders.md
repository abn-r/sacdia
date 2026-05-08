# Runtime — User Folders (progresión admin-level)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: operaciones admin-level sobre inscripción y progreso de carpetas por usuario (enrollUser, getUserFolders, getFolderProgress, updateSectionProgress, deleteAssignment). Distinto del catálogo público de carpetas (`folders:read`) y del subsistema de carpetas de evidencia (`evidence_folders:*`)

<!-- VERIFICADO contra código 2026-04-22: folders/folders.controller.ts con 5 handlers migrados, colisión semántica resuelta con prefix user_, permisos propios user_folders:read/manage. -->

---

## 1. Propósito

Canoniza las operaciones **admin-level** sobre inscripción y progreso de carpetas de usuario. Distinto de:
- browse del catálogo público de carpetas (`folders:read`, endpoints abiertos con `OptionalJwtAuthGuard`);
- carpetas de evidencia anual (dominio propio `evidence_folders:*` en `folders/evidence-folder.controller.ts`).

Tres dominios ortogonales que comparten la carpeta `src/folders/` por proximidad de código, pero con contratos y permisos independientes.

---

## 2. Alcance canonizado

Dentro del canon:
- operaciones admin sobre inscripción y progreso de carpetas por usuario;
- permisos propios `user_folders:read` / `user_folders:manage`;
- scope de autoridad por rol;
- separación de los otros dos dominios de carpetas.

Fuera del canon:
- browse de catálogo de carpetas (`folders:read`);
- carpetas de evidencia anual (`evidence_folders:*`, ver `docs/features/carpetas-evidencias.md` y `docs/canon/runtime-sacdia.md` §carpeta anual).

---

## 3. Permisos canonizados

Permisos vigentes (dominio propio, introducidos en 2026-04-22 por corrección de Sprint C):

- `user_folders:read` — leer inscripción y progreso de carpetas de cualquier usuario (admin-level);
- `user_folders:manage` — inscribir, actualizar progreso de sección, eliminar asignación (admin-level).

Grants tras corrección:
- `user_folders:read` → `counselor`, `secretary`, `treasurer`, `secretary-treasurer`, `deputy-director`, `director` (CLUB) + `assistant-lf` (GLOBAL) + JOIN copies + admin/super_admin.
- `user_folders:manage` → subconjunto: `deputy-director`, `director` + `assistant-lf` (+ JOIN) + admin/super_admin.

NO granted: `user`, `member`, `coordinator`, `zone-coordinator`, `general-coordinator`, `pastor`.

---

## 4. Superficie API canonizada

| Path | Método | Handler | Permiso |
|------|--------|---------|---------|
| `/folders/enroll` | POST | `enrollUser` | `user_folders:manage` |
| `/folders/user/:userId` | GET | `getUserFolders` | `user_folders:read` |
| `/folders/:assignmentId/progress` | GET | `getFolderProgress` | `user_folders:read` |
| `/folders/:assignmentId/progress/section` | PATCH | `updateSectionProgress` | `user_folders:manage` |
| `/folders/:assignmentId` | DELETE | `deleteAssignment` | `user_folders:manage` |

Los endpoints de catálogo público (GET `/folders`, GET `/folders/:id`) operan sin `@RequirePermissions` — visibilidad abierta del catálogo.

Los endpoints de `evidence-folder.controller.ts` quedan fuera de este canon — usan `evidence_folders:*` exclusivamente.

---

## 5. Relación con otros canones

- `docs/canon/runtime-user-certifications.md` — dominio hermano corregido por la misma colisión de Sprint C.
- `docs/canon/runtime-sacdia.md` — carpeta anual de evidencias (distinta).
- `docs/canon/decisiones-clave.md` §19 — decisión conjunta Sprint C + fix colisión.

---

## 6. Invariantes

- `user_folders:*` es el único permiso canónico para operaciones admin sobre progresión de carpetas de usuario;
- los tres dominios de carpeta (`folders:read` browse, `user_folders:*` admin progression, `evidence_folders:*` evidencia anual) deben permanecer separados — colapsarlos rompe el modelo canonizado;
- operaciones admin no pueden ejecutarse sin grant explícito de `user_folders:manage`;
- los endpoints de browse de catálogo permanecen abiertos con `OptionalJwtAuthGuard`.
