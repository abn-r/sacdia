# Plan: bandeja de revisión de certificaciones en el panel admin

> **Para el agente ejecutor:** sigue este plan tarea por tarea, en orden. Cada tarea termina en commit. Se trabaja DIRECTAMENTE sobre la rama `development` de `sacdia-backend`, `sacdia-admin` y el repo raíz `sacdia` (decisión del usuario; no crear feature branches). Si un supuesto no coincide con el código real, verifica en el archivo indicado y adapta el detalle sin cambiar diseño ni alcance; registra desviaciones en el resumen final.

**Objetivo:** dar UI en el panel admin a los revisores institucionales del motor de certificaciones: bandeja de requisitos enviados (aprobar / devolver con comentario), bandeja de cierres (aprobar comprobante de junta / devolver / certificar) y visualización segura de evidencias con URLs firmadas. Incluye el único faltante backend: endpoints de descarga firmada para el revisor.

**Contexto previo:** el motor completo ya está en `development` (plan base `docs/plans/2026-08-05-configurable-certifications-engine-implementation-plan.md`, reporte `docs/reports/2026-08-11-implementacion-certificaciones-configurables.md`). Los endpoints de revisión ya existen y están probados (287 unit + 17 e2e); esta fase solo agrega descarga firmada y consume el contrato desde el admin.

**Contexto obligatorio antes de empezar:** `AGENTS.md` raíz, `sacdia-admin/CLAUDE.md`, `sacdia-backend/src/certifications/review/certification-review.service.ts` (tipos del contrato), `sacdia-backend/src/certifications/controllers/certification-review.controller.ts` y `certification-closeout.controller.ts`, `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (sección certificaciones).

**Reglas duras:**
- Conventional commits. NUNCA `Co-Authored-By` ni atribución de IA. Tras cada commit verificar `git log -1 --format='%(trailers)'`; si hay trailer, recrear con `git commit-tree` + `git update-ref` sobre `development`.
- No builds. No tocar `.env`. No migraciones ni seeds (esta fase no cambia schema).
- Tests del área en verde antes de cada commit; typecheck limpio al cierre.
- Docs canónicas actualizadas en el mismo trabajo (Task 5).

**Decisiones ya tomadas (no re-discutir):**
1. La UI vive en el admin como sección nueva de revisión, separada del catálogo de configuración. Ruta: `src/app/(dashboard)/dashboard/certifications/reviews/page.tsx` con dos tabs: "Requisitos" y "Cierres". (Verificar convención de rutas existente en `src/app/(dashboard)/dashboard/`; si el patrón del proyecto exige otra ubicación, adaptar y anotar.)
2. Visibilidad por permisos: la página requiere `certifications:review`; el botón "Certificar" además `certifications:certify`. Resolver permisos con el mecanismo existente en `sacdia-admin/src/lib/auth/permissions.ts`.
3. Las URLs firmadas de evidencia son efímeras (TTL 15 min del `FileStorageService`): se piden on-demand al abrir/descargar, nunca se persisten ni se cachean en estado global.
4. Devolver (requisito o cierre) exige comentario no vacío — validar en el formulario antes de llamar la API (el backend ya lo exige).
5. Certificar muestra diálogo de confirmación; el endpoint es idempotente, repetirlo no rompe.
6. Filtro por defecto de la bandeja de requisitos: `status=SUBMITTED`. Sin paginación en esta fase (bandejas cortas); anotar como extensión futura.
7. No se toca la app móvil ni el flujo del participante.

---

## Contrato backend existente (verificado 2026-08-12)

Base: `/api/v1`. Guards: `JwtAuthGuard + PermissionsGuard`. Envelope: `{ status: 'success', data }`.

| Método | Ruta | Permiso | Notas |
|---|---|---|---|
| `GET` | `/certifications/reviews/requirements?status=` | `certifications:review` | Lista `TrayItem[]` |
| `GET` | `/certifications/reviews/requirements/:progressId` | `certifications:review` | `RequirementReviewDetail` |
| `POST` | `/certifications/reviews/requirements/:progressId/approve` | `certifications:review` | Solo desde `SUBMITTED` |
| `POST` | `/certifications/reviews/requirements/:progressId/request-changes` | `certifications:review` | Body `{ comment }` obligatorio |
| `GET` | `/certifications/reviews/final` | `certifications:review` | Bandeja de cierres |
| `POST` | `/certifications/reviews/final/:enrollmentId/approve-closeout-evidence` | `certifications:review` | → `APPROVED` |
| `POST` | `/certifications/reviews/final/:enrollmentId/request-changes` | `certifications:review` | Body con comentario |
| `POST` | `/certifications/reviews/final/:enrollmentId/certify` | `certifications:certify` | Idempotente |

Shapes (de `certification-review.service.ts`):

```typescript
TrayItem = {
  progress_id, enrollment_id, certification_id, certification_name,
  module_id, module_name, section_id, section_name,
  status: 'DRAFT'|'SUBMITTED'|'CHANGES_REQUESTED'|'APPROVED',
  submitted_at, participant: { user_id, name, paternal_last_name }
}
RequirementReviewDetail = TrayItem & {
  lock_version,
  components: Array<{ component_id, component_type, label, required,
    response: { text_value, attestation_confirmed, linked_user_honor_id, linked_activity_id } | null,
    evidences: Array<{ evidence_id, original_filename, mime_type, size_bytes, upload_status }> }>,
  history: Array<{ review_event_id, event_type, comment, performed_by_id, from_status, to_status, created_at }>
}
```

**Faltante confirmado:** no existe endpoint de descarga firmada para revisor (las evidencias solo devuelven metadata). `FileStorageService.getSignedDownloadUrl` ya existe (`src/common/services/file-storage.service.ts:98`).

---

## Task 1: Backend — descarga firmada de evidencias para el revisor

**Files:**
- Modify: `sacdia-backend/src/certifications/review/certification-review.service.ts`
- Modify: `sacdia-backend/src/certifications/controllers/certification-review.controller.ts`
- Modify: `sacdia-backend/src/certifications/closeout/certification-closeout.service.ts`
- Modify: `sacdia-backend/src/certifications/controllers/certification-closeout.controller.ts`
- Test: los specs correspondientes de service y controller

**Endpoints nuevos:**
- `GET /certifications/reviews/requirements/:progressId/evidences/:evidenceId/download` (`certifications:review`): re-verifica scope con el helper existente `getProgressInScopeOrThrow`, valida que la evidencia pertenezca a ese progress, esté `active` y `CONFIRMED`, y devuelve `{ url, expires_in, original_filename, mime_type }` vía `getSignedDownloadUrl`. 404 si no corresponde.
- `GET /certifications/reviews/final/:enrollmentId/closeout-evidence/download` (`certifications:review`): mismo patrón sobre `certification_closeout_evidences` (comprobante vigente de la inscripción, dentro de scope).

**Steps (TDD):**
1. Tests RED en los specs de service: scope ajeno → `CERT_REVIEW_SCOPE_FORBIDDEN`; evidencia de otro progress → not found; evidencia no confirmada → error; caso feliz devuelve URL firmada sin persistirla.
2. `npm test -- --runInBand src/certifications` → FAIL.
3. Implementar. Nunca aceptar object key del cliente; resolverlo de la fila de la evidencia.
4. GREEN + `npx tsc --noEmit -p tsconfig.build.json` limpio.
5. Revisar `getFinalTray` en `certification-closeout.service.ts`: la bandeja debe exponer metadata del comprobante (filename, mime, estado) y datos del participante suficientes para la UI; si falta, agregarlo en esta misma task con test.
6. Commit: `feat(certifications): add signed evidence downloads for reviewers`

## Task 2: Admin — cliente API de revisión

**Files:**
- Create: `sacdia-admin/src/lib/api/certification-reviews.ts`
- Test: `sacdia-admin/src/lib/api/certification-reviews.test.ts` (si el proyecto testea clients; si no hay convención, cubrir vía tests de componentes de Tasks 3–4)

**Steps:**
1. Tipos TS espejo del contrato (tabla anterior) + funciones: `getRequirementTray(status?)`, `getRequirementDetail(progressId)`, `approveRequirement(progressId)`, `requestRequirementChanges(progressId, comment)`, `getRequirementEvidenceDownload(progressId, evidenceId)`, `getFinalTray()`, `approveCloseoutEvidence(enrollmentId)`, `requestCloseoutChanges(enrollmentId, comment)`, `certify(enrollmentId)`, `getCloseoutEvidenceDownload(enrollmentId)`. Seguir el patrón de `src/lib/api/certifications.ts` (fetch wrapper, manejo de envelope y errores).
2. Typecheck limpio.
3. Commit: `feat(certifications): add review tray api client`

## Task 3: Admin — bandeja y detalle de requisitos

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/certifications/reviews/page.tsx`
- Create: `sacdia-admin/src/components/certifications/requirement-review-tray.tsx`
- Create: `sacdia-admin/src/components/certifications/requirement-review-detail.tsx`
- Test: `sacdia-admin/src/components/certifications/requirement-review-tray.test.tsx`
- Test: `sacdia-admin/src/components/certifications/requirement-review-detail.test.tsx`
- Modify: `sacdia-admin/messages/{es,en,fr,pt-BR}.json` + regenerar `src/i18n/messages.d.ts` con el script oficial
- Modify: navegación lateral del dashboard (localizar el componente de sidebar/menú y agregar entrada "Revisiones de certificaciones" visible con `certifications:review`)

**UI:**
- Página con `PageHeader`, tokens semánticos y shadcn/ui (regla de `sacdia-admin/CLAUDE.md`), tabs "Requisitos" / "Cierres".
- Bandeja: tabla con participante, certificación, módulo, requisito, estado (badge), fecha de envío; filtro por estado (default `SUBMITTED`); refresco tras cada acción.
- Detalle (sheet o dialog): por componente muestra la respuesta según tipo (texto, constancia confirmada, honor/actividad vinculada) y evidencias con botón "Ver" que pide la URL firmada on-demand y abre en pestaña nueva; historial de revisión cronológico con comentarios; acciones "Aprobar" y "Devolver" (textarea de comentario obligatorio, deshabilitar submit vacío). Estados no `SUBMITTED` → acciones deshabilitadas con explicación.
- Errores del backend (`CERT_REVIEW_SCOPE_FORBIDDEN`, `CERT_INVALID_TRANSITION`, `CERT_CONCURRENT_UPDATE`) → toasts legibles i18n.

**Steps:** tests RED de tray (render, filtro, acción llama API) y detalle (componentes por tipo, comentario obligatorio, URL firmada solicitada solo al click) → GREEN → commit: `feat(certifications): add requirement review tray to admin`

## Task 4: Admin — bandeja de cierres y certificación

**Files:**
- Create: `sacdia-admin/src/components/certifications/final-review-tray.tsx`
- Test: `sacdia-admin/src/components/certifications/final-review-tray.test.tsx`
- Modify: página de Task 3 (tab "Cierres"), i18n 4 locales

**UI:**
- Tabla de inscripciones en `SUBMITTED_FOR_FINAL_REVIEW`: participante, certificación, fecha de envío, comprobante (botón "Ver" con URL firmada on-demand).
- Acciones: "Aprobar comprobante" (→ `APPROVED`), "Devolver" (comentario obligatorio), "Certificar" (visible solo con `certifications:certify`, sobre inscripciones `APPROVED`, con diálogo de confirmación).
- Tras certificar, la fila sale de la bandeja; toast de éxito.

**Steps:** tests RED → GREEN → commit: `feat(certifications): add final review and certify tray to admin`

## Task 5: Docs

**Files (repo raíz):**
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`: 2 endpoints de descarga nuevos.
- `docs/features/certificaciones-guias-mayores-revision-workflow.md`: sección "UI de revisión en admin" con el flujo.
- `docs/reports/2026-08-11-implementacion-certificaciones-configurables.md`: en §7, actualizar la nota sobre bandeja sin UI.

Commit: `docs(certifications): document admin review tray and evidence downloads`

## Gates finales

```bash
cd sacdia-backend && npm test -- --runInBand src/certifications && npx tsc --noEmit -p tsconfig.build.json
cd sacdia-admin && npx vitest run src/components/certifications src/lib/api && npm run typecheck
```

Expected: todo verde (los fallos de copias en `.worktrees/` del admin son basura preexistente, ignorar). Sin builds.

## Resumen final (obligatorio)

Al terminar, entregar resumen con: endpoints agregados, archivos por repo, resultados de gates, hashes de commits y desviaciones. No se requiere reporte formal en `docs/reports/` (fase corta); el resumen va en la respuesta.

## Fuera de alcance

- Paginación/filtros avanzados de bandejas.
- UI de revisión en la app móvil.
- Notificaciones (push/email) al participante tras decisión.
- Cambios de schema o migraciones.
- Retiro de endpoints legacy.
