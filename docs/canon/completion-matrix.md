# Completion Matrix - Canon Factory Wave 2

**Estado**: ACTIVE
**Última actualización**: 2026-03-20 (Wave 2)
**Base de autoridad**: `docs/canon/source-of-truth.md`
**Propósito**: mapear cobertura documental y runtime sin redefinir autoridad.

> [!IMPORTANT]
> Esta matriz no crea jerarquía nueva.
> Solo registra qué evidencia autorizada existe, qué falta y qué puntos quedan degradados o disputados.

---

## 1. Escala de estado

- `COMPLETE`: la evidencia autorizada esperada existe y no se detectó conflicto para esa fila.
- `PARTIAL`: existe evidencia autorizada, pero la cobertura es incompleta o el set de artefactos es insuficiente.
- `MISSING`: no se encontró la evidencia autorizada esperada.
- `DISPUTED`: existen fuentes autorizadas, pero chocan entre sí para la fila.
- `BLOCKED`: la fila no puede cerrarse de forma segura sin arbitraje.

---

<!-- Verificado contra Reality Matrix 2026-03-14; actualizado Wave 2 2026-03-20 -->

## 2. Resumen ejecutivo

| Área | Resultado | Verificación 2026-03-20 (Wave 2) |
|---|---|---|
| Gobernanza y precedencia | `COMPLETE` | Sin cambios |
| Canon de producto | `COMPLETE` | Sin cambios |
| Canon técnico base | `PARTIAL` | Sin cambios respecto a Wave 0 |
| Estándares operativos | `COMPLETE` | Sin cambios |
| Runtime API | `COMPLETE` | 215 endpoints documentados (+19 nuevos, +2 corregidos, -1 fantasma removido) |
| Racionales/decisiones API | `PARTIAL` | Sin cambios |
| Modelo de datos | `COMPLETE` | ~72 modelos + 8 enums documentados en SCHEMA-REFERENCE (era ~25) |
| Features por dominio | `PARTIAL` | 16 dominios con spec completa; 9 COMPLETE (código IMPLEMENTADO), 5 PARTIAL (código PARCIAL), 1 NO CANON, 1 FANTASMA. Ningún dominio con set requirements+design+tasks |

---

## 3. Matriz base de cobertura autorizada

| Área | Evidencia esperada según `source-of-truth` | Evidencia encontrada | Estado | Observaciones |
|---|---|---|---|---|
| Gobernanza documental | `source-of-truth.md`, `docs/README.md`, `gobernanza-canon.md` | Los tres documentos existen y están en uso | `COMPLETE` | La precedencia quedó explícita y operable |
| Canon de producto | `dominio-sacdia.md`, `identidad-sacdia.md`, `gobernanza-canon.md` | Los tres existen y están `ACTIVE` | `COMPLETE` | Cobertura base de identidad, lenguaje y reglas de interpretación |
| Arquitectura canónica | `arquitectura-sacdia.md`, `decisiones-clave.md` | Ambos existen y están `ACTIVE` | `COMPLETE` | Cobertura de arquitectura y decisiones duraderas |
| Baseline técnica global | `tech.md`, `structure.md`, `coding-standards.md`, `data-guidelines.md`, `agents.md` | Todos existen; `structure.md` está `HISTORICAL` | `PARTIAL` | La baseline existe, pero la guía de estructura quedó degradada por estatus/obsolescencia |
| Estándares de ingeniería | `coding-standards.md`, `data-guidelines.md`, `agents.md` | Los tres existen y cubren normas operativas | `COMPLETE` | Sirven como baseline operativa subordinada |
| Contrato runtime API | `ENDPOINTS-LIVE-REFERENCE.md` | Existe, base `/api/v1`, 215 endpoints, 22+ módulos | `COMPLETE` | Actualizado Wave 2: +19 endpoints, +2 correcciones, -1 fantasma |
| Decisiones API estructurales | `ARCHITECTURE-DECISIONS.md` | Existe, pero su alcance es selectivo (naming, `users_pr`, legal reps, año eclesiástico, roles/RBAC) | `PARTIAL` | Complementa, no reemplaza, al Live Reference |
| Modelo de datos estructural | `schema.prisma`, `docs/03-DATABASE/README.md`, `SCHEMA-REFERENCE.md` | Los tres existen; `SCHEMA-REFERENCE.md` actualizado con ~72 modelos + 8 enums | `COMPLETE` | Actualizado Wave 2: ~48 modelos nuevos documentados. `schema.prisma` sigue mandando |

---

## 4. Matriz de cobertura por feature documental

<!-- Verificado contra Reality Matrix 2026-03-14. Actualizado Wave 2 2026-03-20. Columna "Código" refleja estado real de implementación. -->

| Dominio | Spec completa | Requirements | Design | Tasks | Walkthrough(s) | Estado doc | Código (Reality Matrix) | Observación |
|---|---|---|---|---|---|---|---|---|
| `auth` | ✅ | — | — | — | ✅ | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: auth.md (IMPLEMENTADO) |
| `gestion-clubs` | ✅ | — | ✅ | — | ✅ | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: gestion-clubs.md (IMPLEMENTADO) |
| `clases-progresivas` | ✅ | — | ✅ | — | — | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: clases-progresivas.md (IMPLEMENTADO, 82 líneas) |
| `honores` | ✅ | — | ✅ | — | ✅ | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: honores.md (IMPLEMENTADO, 80 líneas) |
| `catalogos` | ✅ | — | ✅ | — | ✅ | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: catalogos.md (IMPLEMENTADO) |
| `communications` | ✅ | — | — | — | ✅ | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: communications.md (IMPLEMENTADO) |
| `carpetas-evidencias` | ✅ | — | — | — | — | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: carpetas-evidencias.md (IMPLEMENTADO, 89 líneas). Era MISSING |
| `rbac` | ✅ | — | — | — | — | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: rbac.md (IMPLEMENTADO). Era MISSING |
| `gestion-seguros` | ✅ | ✅ | — | — | — | `COMPLETE` | IMPLEMENTADO | Spec Wave 2: gestion-seguros.md (IMPLEMENTADO). Corregido de SIN CANON |
| `actividades` | ✅ | — | ✅ | — | ✅ | `PARTIAL` | PARCIAL | Spec Wave 2: actividades.md (PARCIAL). Bug: clubId hardcoded |
| `finanzas` | ✅ | — | ✅ | — | ✅ | `PARTIAL` | PARCIAL | Spec Wave 2: finanzas.md (PARCIAL). Faltan campos de auditoría |
| `inventario` | ✅ | — | — | — | ✅ | `PARTIAL` | PARCIAL | Spec Wave 2: inventario.md (PARCIAL). Typo en PK |
| `camporees` | ✅ | — | — | — | — | `PARTIAL` | PARCIAL | Spec Wave 2: camporees.md (PARCIAL). Sin screens en app |
| `certificaciones-guias-mayores` | ✅ | ✅ | — | — | ✅ | `PARTIAL` | PARCIAL | Spec Wave 2: certificaciones-guias-mayores.md (PARCIAL). Backend done, zero client UI |
| `infrastructure` | ✅ | — | — | — | ✅ | `PARTIAL` | NO CANON | Spec Wave 2: infrastructure.md (NO CANON, cross-cutting) |
| `validacion-investiduras` | ✅ | ✅ | — | — | — | `PARTIAL` | FANTASMA | Spec Wave 2: validacion-investiduras.md (FANTASMA, 106 líneas). DB existe, zero runtime |

**Lectura de la fila**:

- `COMPLETE` en features requiere spec completa y código IMPLEMENTADO sin gaps documentados.
- `PARTIAL` indica que existe spec pero el código tiene gaps o el dominio no está completamente implementado.
- Wave 2 cerró 16 specs de dominio. 9 dominios `COMPLETE` (código implementado), 5 `PARTIAL` (código parcial), 1 `PARTIAL` (NO CANON), 1 `PARTIAL` (FANTASMA).
- Set completo `requirements + design + tasks` sigue sin existir para ningún dominio.

---

## 5. Matriz de cobertura runtime por módulo API

Fuente única de esta sección: `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
**Total**: 215 endpoints documentados (actualizado Wave 2, 2026-03-20)

| Módulo runtime | Evidencia encontrada | Estado | Observación |
|---|---|---|---|
| `auth` | Sección presente | `COMPLETE` | Incluye notas de contrato de login/refresh/logout/MFA/OAuth |
| `users` | Sección presente | `COMPLETE` | Incluye notas de autorización, post-registro y progreso de clases |
| `activities` | Sección presente | `COMPLETE` | Runtime documentado |
| `admin` | Sección presente | `COMPLETE` | Wave 2: +5 honor-categories CRUD, +4 medicines CRUD, +1 club-ideals |
| `camporees` | Sección presente | `COMPLETE` | Runtime documentado |
| `catalogs` | Sección presente | `COMPLETE` | Wave 2: +1 activity-types endpoint |
| `certifications` | Sección presente | `COMPLETE` | Runtime documentado |
| `classes` | Sección presente | `COMPLETE` | Runtime documentado |
| `club-roles` | Sección presente | `COMPLETE` | Runtime documentado |
| `clubs` | Sección presente | `COMPLETE` | Wave 2: -1 fantasma removido (DELETE clubs/sections/:sectionId) |
| `evidence-folder` | Sección presente | `COMPLETE` | Wave 2: +4 endpoints nuevos |
| `fcm-tokens` | Sección presente | `COMPLETE` | Wave 2: corrección de nombre de parámetro |
| `finances` | Sección presente | `COMPLETE` | Runtime documentado |
| `folders` | Sección presente | `COMPLETE` | Runtime documentado |
| `health` | Sección presente | `COMPLETE` | Runtime documentado |
| `honors` | Sección presente | `COMPLETE` | Wave 2: +endpoints grouped-by-category, user-honors create/bulk/files |
| `inventory` | Sección presente | `COMPLETE` | Runtime documentado |
| `notifications` | Sección presente | `COMPLETE` | Wave 2: corrección de route signature |
| `root` | Sección presente | `COMPLETE` | Runtime documentado |

---

## 6. Gaps operativos detectados

<!-- Actualizado Wave 2 2026-03-20 -->

| Item | Evidencia esperada | Evidencia encontrada | Estado | Acción sugerida |
|---|---|---|---|---|
| Estructura técnica vigente | Guía de estructura activa y consistente con canon | `structure.md` existe pero está `HISTORICAL` | `MISSING` | Reemplazar o reactivar una guía de estructura vigente alineada con canon |
| Features con set completo | `requirements.md` + `design.md` + `tasks.md` por dominio operativo | Ningún dominio presenta el set completo | `MISSING` | Priorizar cierre documental por dominio antes de declarar cobertura completa |
| Tareas por dominio | `tasks.md` cuando el dominio necesite ejecución trazable | No se detectó `tasks.md` en los dominios listados | `MISSING` | Agregar task breakdown en dominios activos donde haga falta ejecución/verificación |
| Auditoría de servicios externos | Documento auxiliar si existe | No se encontró `docs/EXTERNAL-SERVICES-AUDIT.md` | `MISSING` | Crear solo si realmente se necesita como apoyo; no bloquea runtime |
| Storage provider drift | Canon documentaba Supabase Storage | Backend usa Cloudflare R2 (R2FileStorageService) | `FIXED` | Corregido en runtime-sacdia.md 2026-03-14 |
| Endpoints FANTASMA (Wave 0) | Endpoints documentados que no existen en backend | 17 endpoints fantasma detectados | `FIXED` | Removidos de ENDPOINTS-LIVE-REFERENCE 2026-03-14 |
| Endpoint FANTASMA (Wave 2) | DELETE clubs/sections/:sectionId documentado | No existe en backend | `FIXED` | Removido de ENDPOINTS-LIVE-REFERENCE 2026-03-20 (Wave 2) |
| API doc gap (18 endpoints) | 198 endpoints implementados vs 180 documentados | 19 endpoints agregados, 2 corregidos en Wave 2. Total: 215 | `FIXED` | Cerrado en ENDPOINTS-LIVE-REFERENCE 2026-03-20 (Wave 2) |
| Referencia humana de datos alineada | `SCHEMA-REFERENCE.md` consistente con `schema.prisma` | ~72 modelos + 8 enums documentados (era ~25) | `FIXED` | Actualizado 2026-03-20 (Wave 2): +48 modelos nuevos documentados |
| Feature docs faltantes | Specs por dominio para los 16 dominios | 16 specs creadas en Wave 2 | `FIXED` | Cerrado 2026-03-20 (Wave 2). Todos los dominios tienen spec |
| Canon de catálogos admin | 16+ endpoints CRUD admin sin mención en canon | Implementados y documentados en ENDPOINTS-LIVE-REFERENCE + catalogos.md | `FIXED` | Cerrado 2026-03-20 (Wave 2): spec catalogos.md cubre el dominio |
| Notifications route signature | Firma de ruta incorrecta en doc | Corregido en ENDPOINTS-LIVE-REFERENCE | `FIXED` | Corregido 2026-03-20 (Wave 2) |
| FCM tokens param name | Nombre de parámetro incorrecto en doc | Corregido en ENDPOINTS-LIVE-REFERENCE | `FIXED` | Corregido 2026-03-20 (Wave 2) |
| `validacion-investiduras` FANTASMA | Módulo runtime esperado | DB tables existen, pero zero endpoints/módulos/screens | `OPEN` | Dominio documentado como FANTASMA en spec. Decidir si implementar o deprecar tablas |
| `actividades` bug clubId | clubId dinámico por contexto | clubId hardcoded en implementación | `OPEN` | Documentado en spec actividades.md. Requiere fix en backend |
| `finanzas` campos auditoría | Campos de auditoría en modelo | Faltan campos de auditoría | `OPEN` | Documentado en spec finanzas.md. Requiere migración |
| `inventario` PK typo | PK consistente | Typo en PK detectado | `OPEN` | Documentado en spec inventario.md. Requiere migración |
| `certificaciones-guias-mayores` sin UI | Client UI para certificaciones | Backend completo, zero client UI (admin y app) | `OPEN` | Documentado en spec. Requiere implementación de pantallas |

---

## 7. Uso permitido para Runtime

`Runtime` puede tomar como base inmediata:

1. `docs/canon/source-of-truth.md` para precedencia;
2. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md` para API vigente (215 endpoints, actualizado Wave 2);
3. `docs/03-DATABASE/schema.prisma` para modelo de datos vigente;
4. `docs/database/SCHEMA-REFERENCE.md` para referencia humana del modelo (~72 modelos + 8 enums, actualizado Wave 2);
5. `docs/canon/dominio-sacdia.md`, `identidad-sacdia.md`, `arquitectura-sacdia.md` y `decisiones-clave.md` para interpretación canónica;
6. `docs/00-STEERING/tech.md`, `coding-standards.md`, `data-guidelines.md`, `agents.md` como baseline subordinada;
7. `docs/features/*.md` para specs de dominio (16 specs, creadas Wave 2).

`Runtime` no debe usar esta matriz para redefinir autoridad; solo para saber qué cobertura ya está documentada y dónde hay huecos.

---

## 8. Changelog

| Fecha | Wave | Cambios |
|---|---|---|
| 2026-03-14 | Wave 0 | Matriz inicial. 180 endpoints, ~25 modelos, 17 fantasma removidos, storage drift corregido |
| 2026-03-20 | Wave 2 | +19 endpoints (total 215), +2 correcciones, -1 fantasma. SCHEMA-REFERENCE: +48 modelos (total ~72 + 8 enums). 16 feature specs creadas. 5 gaps OPEN nuevos documentados |
