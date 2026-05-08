# Runtime — Validation (workflow de revisión)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: workflow de submit → review para progreso de clases y honores. Distinto del módulo `classes` (propio del currículo) y del módulo `users` (perfil). Coexiste con `classes:*` y `users:read_detail` que permanecen activos en su dominio original

<!-- VERIFICADO contra código 2026-04-22: validation.controller.ts con 5 handlers migrados a validation:*, permisos classes:* y users:read_detail preservados intactos. Patrón coexistencia canonizado. -->

---

## 1. Propósito

Canoniza el subsistema de **validación** como workflow institucional de revisión con dominio propio. Antes de la migración, los 5 handlers reutilizaban permisos de dominios ajenos (`classes:submit_progress`, `classes:validate`, `classes:read`, `users:read_detail`) — mezclando concerns entre "qué operas en el currículo" y "qué revisas en el workflow de aprobación".

Decisión canonizada: `validation:*` cubre exclusivamente el workflow de submit/review; `classes:*` conserva su alcance original (gestión del currículo); `users:read_detail` conserva su alcance (perfil de usuario).

---

## 2. Alcance canonizado

Dentro del canon:
- permisos propios `validation:submit` / `validation:review` / `validation:read`;
- contrato submit → review entre módulos clases y honores;
- patrón coexistencia (agregar sin reemplazar permisos originales).

Fuera del canon:
- gestión del currículo (módulo `classes/`, permisos `classes:*`);
- gestión de honores (`user_honors:*` en `honors/`);
- UI específica admin.

---

## 3. Permisos canonizados

Permisos vigentes (introducidos 2026-04-22 — Sprint E del audit de permisos):

- `validation:submit` — enviar progreso de clase/honor a revisión.
- `validation:review` — aprobar o rechazar envío en revisión.
- `validation:read` — leer cola pendiente, historial de validación, verificar elegibilidad.

Distribución tras migración:

| Rol | submit | review | read |
|-----|--------|--------|------|
| `user` | — | — | ✓ |
| `member` | ✓ | — | ✓ |
| `counselor` | ✓ | ✓ | ✓ |
| `secretary` | ✓ | ✓ | ✓ |
| `treasurer` | ✓ | ✓ | ✓ |
| `secretary-treasurer` | ✓ | ✓ | ✓ |
| `deputy-director` | ✓ | ✓ | ✓ |
| `director` | ✓ | ✓ | ✓ |
| `coordinator` | — | ✓ | ✓ |
| `zone-coordinator` | — | ✓ | ✓ |
| `general-coordinator` | — | ✓ | ✓ |
| `pastor` | — | — | ✓ |
| `assistant-lf` (+ JOIN copies) | ✓ | ✓ | ✓ |
| `admin` / `super_admin` | ✓ (wildcard) | ✓ | ✓ |

Grant de `validation:submit` a `member` es deliberado — members envían su propio progreso para revisión.

---

## 4. Patrón coexistencia

Los permisos originales no se retiraron:
- `classes:submit_progress` — sigue activo para uso en módulo `classes/` (si existen handlers ahí).
- `classes:validate` — sigue activo.
- `classes:read` — sigue activo.
- `users:read_detail` — sigue activo para `users.controller.ts`.

Los handlers de `validation/` usan exclusivamente `validation:*`. Si en el futuro se detectan otros callers legítimos de los permisos originales, conviven sin conflicto. Si no hay otros callers, los originales pueden deprecarse en ola posterior con decisión explícita.

---

## 5. Superficie API canonizada

| Path | Método | Handler | Permiso |
|------|--------|---------|---------|
| `/validation/submit` | POST | `submitForReview` | `validation:submit` |
| `/validation/review` | POST/PATCH | `review` | `validation:review` |
| `/validation/pending` | GET | `getPendingReviews` | `validation:read` |
| `/validation/history` | GET | `getValidationHistory` | `validation:read` |
| `/validation/eligibility` | GET | `checkEligibility` | `validation:read` |

Exact paths pueden variar según el controller — los handlers son los 5 canonicals. Ver `docs/features/validacion-evidencias.md` + `docs/features/validacion-investiduras.md` para detalle funcional.

---

## 6. Admin

Nav entry `/dashboard/validation` usa `validation:read` tras migración. Drift histórico detectado en Sprint E: la entrada previamente usaba `investiture:read` (módulo distinto) — corregido a `validation:read`, dominio correcto.

Las otras 4 entries del mismo grupo de nav ("Validación e Investiduras") — `evidence-review`, `investiture`, `sla-dashboard`, `year-end` — permanecen con sus permisos originales, pertenecen a dominios distintos.

---

## 7. Relación con otros canones

- `docs/canon/runtime-user-certifications.md` + `runtime-user-folders.md` — patrones de migración con prefix `user_` por colisión. Validation no tuvo colisión — permisos `validation:*` son nuevos sin conflicto.
- `docs/canon/runtime-communications.md` — notificaciones por revisión deben usar `source = 'validation:*'`.
- `docs/canon/decisiones-clave.md` §21 — canonización del dominio validation + coexistencia.

---

## 8. Invariantes

- `validation:*` es el único permiso canónico para handlers en `validation/`; reutilizar `classes:*` o `users:read_detail` en nuevos handlers de este módulo rompe la frontera de concerns;
- los permisos originales `classes:*` y `users:read_detail` permanecen activos para sus dominios propios — no se retiran sin decisión explícita;
- `member` solo puede `submit`, no `review` — el rol de auto-service para envío de progreso está canonizado;
- `coordinator`/`zone-coordinator`/`general-coordinator` pueden `review` pero no `submit` — son revisores institucionales, no submitters directos;
- el drift histórico de nav (`investiture:read` para ruta de validación) queda documentado como lesson learned — la revisión de permisos nav debe chequear que el permiso corresponda al dominio de la ruta.
