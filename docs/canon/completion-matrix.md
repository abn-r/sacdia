# Completion Matrix - Canon Factory Wave 0

**Estado**: ACTIVE  
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

<!-- Verificado contra Reality Matrix 2026-03-14 -->

## 2. Resumen ejecutivo

| Área | Resultado | Verificación 2026-03-14 |
|---|---|---|
| Gobernanza y precedencia | `COMPLETE` | Sin cambios |
| Canon de producto | `COMPLETE` | Sin cambios |
| Canon técnico base | `PARTIAL` | Confirmado: storage drift corregido (Supabase Storage → Cloudflare R2) |
| Estándares operativos | `COMPLETE` | Sin cambios |
| Runtime API | `COMPLETE` | 180 documentados de 198 implementados; 17 FANTASMA removidos |
| Racionales/decisiones API | `PARTIAL` | Sin cambios |
| Modelo de datos | `PARTIAL` | Confirmado: 72 modelos en schema, 24 ALINEADO, 41 SIN CANON |
| Features por dominio | `PARTIAL` | Confirmado: 8 ALINEADO, 5 PARCIAL, 1 FANTASMA, 2 SIN CANON |

---

## 3. Matriz base de cobertura autorizada

| Área | Evidencia esperada según `source-of-truth` | Evidencia encontrada | Estado | Observaciones |
|---|---|---|---|---|
| Gobernanza documental | `source-of-truth.md`, `docs/README.md`, `gobernanza-canon.md` | Los tres documentos existen y están en uso | `COMPLETE` | La precedencia quedó explícita y operable |
| Canon de producto | `dominio-sacdia.md`, `identidad-sacdia.md`, `gobernanza-canon.md` | Los tres existen y están `ACTIVE` | `COMPLETE` | Cobertura base de identidad, lenguaje y reglas de interpretación |
| Arquitectura canónica | `arquitectura-sacdia.md`, `decisiones-clave.md` | Ambos existen y están `ACTIVE` | `COMPLETE` | Cobertura de arquitectura y decisiones duraderas |
| Baseline técnica global | `tech.md`, `structure.md`, `coding-standards.md`, `data-guidelines.md`, `agents.md` | Todos existen; `structure.md` está `HISTORICAL` | `PARTIAL` | La baseline existe, pero la guía de estructura quedó degradada por estatus/obsolescencia |
| Estándares de ingeniería | `coding-standards.md`, `data-guidelines.md`, `agents.md` | Los tres existen y cubren normas operativas | `COMPLETE` | Sirven como baseline operativa subordinada |
| Contrato runtime API | `ENDPOINTS-LIVE-REFERENCE.md` | Existe, base `/api/v1`, 180 endpoints, 18 módulos | `COMPLETE` | Es la fuente vigente para App/Admin |
| Decisiones API estructurales | `ARCHITECTURE-DECISIONS.md` | Existe, pero su alcance es selectivo (naming, `users_pr`, legal reps, año eclesiástico, roles/RBAC) | `PARTIAL` | Complementa, no reemplaza, al Live Reference |
| Modelo de datos estructural | `schema.prisma`, `docs/03-DATABASE/README.md`, `SCHEMA-REFERENCE.md` | Los tres existen; `README` declara `schema.prisma` como fuente de verdad, pero `SCHEMA-REFERENCE.md` deriva en varios puntos | `PARTIAL` | `schema.prisma` manda; `SCHEMA-REFERENCE.md` quedó desalineado como referencia humana |

---

## 4. Matriz de cobertura por feature documental

<!-- Verificado contra Reality Matrix 2026-03-14. Columna "Código" refleja estado real de implementación. -->

| Dominio | Requirements | Design | Tasks | Walkthrough(s) | Estado doc | Código (Reality Matrix) | Observación |
|---|---|---|---|---|---|---|---|
| `auth` | — | — | — | ✅ | `PARTIAL` | ALINEADO | Backend+admin+app implementados |
| `gestion-clubs` | — | ✅ | — | ✅ | `PARTIAL` | ALINEADO | Backend+admin+app implementados |
| `clases-progresivas` | — | ✅ | — | — | `PARTIAL` | ALINEADO | Backend+admin(read-only)+app implementados |
| `honores` | — | ✅ | — | ✅ | `PARTIAL` | ALINEADO | Backend+admin+app implementados |
| `catalogos` | — | ✅ | — | ✅ | `PARTIAL` | ALINEADO | Backend+admin(13 pages)+app implementados |
| `communications` | — | — | — | ✅ | `PARTIAL` | ALINEADO | Backend+admin+FCM tokens |
| `carpetas-evidencias` | — | — | — | — | `MISSING` | ALINEADO | Backend+admin(read-only)+app implementados |
| `rbac` | — | — | — | — | `MISSING` | ALINEADO | Backend+admin(3 pages) implementados |
| `actividades` | — | ✅ | — | ✅ | `PARTIAL` | PARCIAL | Backend+app completos, admin placeholder |
| `finanzas` | — | ✅ | — | ✅ | `PARTIAL` | PARCIAL | Backend+app completos, admin placeholder |
| `camporees` | — | — | — | — | `MISSING` | PARCIAL | Backend+admin(read-only), app sin screens |
| `certificaciones-guias-mayores` | ✅ | — | — | ✅ | `PARTIAL` | PARCIAL | Backend+admin(read-only), app sin screens |
| `inventario` | — | — | — | ✅ | `PARTIAL` | PARCIAL | Backend+app completos, admin placeholder |
| `gestion-seguros` | ✅ | — | — | — | `PARTIAL` | SIN CANON | App con screens, sin backend module dedicado |
| `infrastructure` | — | — | — | ✅ | `PARTIAL` | SIN CANON | Backend health/logging, no cubierto por canon |
| `validacion-investiduras` | ✅ | — | — | — | `PARTIAL` | FANTASMA | Tablas existen, sin módulo/endpoints/screens |

**Lectura de la fila**:

- `COMPLETE` en features requeriría, como mínimo, evidencia suficiente y trazable para operar el dominio sin huecos documentales obvios.
- En esta corrida no se encontró ningún dominio con set completo `requirements + design + tasks`.

---

## 5. Matriz de cobertura runtime por módulo API

Fuente única de esta sección: `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`

| Módulo runtime | Evidencia encontrada | Estado | Observación |
|---|---|---|---|
| `auth` | Sección presente | `COMPLETE` | Incluye notas de contrato de login/refresh/logout/MFA/OAuth |
| `users` | Sección presente | `COMPLETE` | Incluye notas de autorización, post-registro y progreso de clases |
| `activities` | Sección presente | `COMPLETE` | Runtime documentado |
| `admin` | Sección presente | `COMPLETE` | Runtime documentado |
| `camporees` | Sección presente | `COMPLETE` | Runtime documentado |
| `catalogs` | Sección presente | `COMPLETE` | Runtime documentado |
| `certifications` | Sección presente | `COMPLETE` | Runtime documentado |
| `classes` | Sección presente | `COMPLETE` | Runtime documentado |
| `club-roles` | Sección presente | `COMPLETE` | Runtime documentado |
| `clubs` | Sección presente | `COMPLETE` | Runtime documentado |
| `fcm-tokens` | Sección presente | `COMPLETE` | Runtime documentado |
| `finances` | Sección presente | `COMPLETE` | Runtime documentado |
| `folders` | Sección presente | `COMPLETE` | Runtime documentado |
| `health` | Sección presente | `COMPLETE` | Runtime documentado |
| `honors` | Sección presente | `COMPLETE` | Runtime documentado |
| `inventory` | Sección presente | `COMPLETE` | Runtime documentado |
| `notifications` | Sección presente | `COMPLETE` | Runtime documentado |
| `root` | Sección presente | `COMPLETE` | Runtime documentado |

---

## 6. Gaps operativos detectados

<!-- Actualizado con hallazgos de Reality Matrix 2026-03-14 -->

| Item | Evidencia esperada | Evidencia encontrada | Estado | Acción sugerida |
|---|---|---|---|---|
| Estructura técnica vigente | Guía de estructura activa y consistente con canon | `structure.md` existe pero está `HISTORICAL` | `MISSING` | Reemplazar o reactivar una guía de estructura vigente alineada con canon |
| Features con set completo | `requirements.md` + `design.md` + `tasks.md` por dominio operativo | Ningún dominio presenta el set completo | `MISSING` | Priorizar cierre documental por dominio antes de declarar cobertura completa |
| Tareas por dominio | `tasks.md` cuando el dominio necesite ejecución trazable | No se detectó `tasks.md` en los dominios listados | `MISSING` | Agregar task breakdown en dominios activos donde haga falta ejecución/verificación |
| Referencia humana de datos alineada | `SCHEMA-REFERENCE.md` consistente con `schema.prisma` | Drift en naming de campos (ej: `id`/`user_id`, `birthdate`/`birthday`, `avatar`/`user_image`) y falta `active_club_assignment_id` en `users_pr` | `MISSING` | Sincronizado parcialmente 2026-03-14; ver nota en SCHEMA-REFERENCE |
| Auditoría de servicios externos | Documento auxiliar si existe | No se encontró `docs/EXTERNAL-SERVICES-AUDIT.md` | `MISSING` | Crear solo si realmente se necesita como apoyo; no bloquea runtime |
| Storage provider drift | Canon documentaba Supabase Storage | Backend usa Cloudflare R2 (R2FileStorageService) | `FIXED` | Corregido en runtime-sacdia.md 2026-03-14 |
| Endpoints FANTASMA | Endpoints documentados que no existen en backend | 17 endpoints fantasma detectados (admin panel y app) | `FIXED` | Removidos de ENDPOINTS-LIVE-REFERENCE 2026-03-14 |
| API doc gap | 198 endpoints implementados vs 180 documentados | 18 endpoints sin documentar | `MISSING` | Agregar a ENDPOINTS-LIVE-REFERENCE cuando se confirmen |
| Canon de catálogos admin | 16+ endpoints CRUD admin sin mención en canon | Implementados y documentados pero SIN CANON | `MISSING` | Decidir si formalizar en canon o dejar como operación implícita |

---

## 7. Uso permitido para Runtime

`Runtime` puede tomar como base inmediata:

1. `docs/canon/source-of-truth.md` para precedencia;
2. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md` para API vigente;
3. `docs/03-DATABASE/schema.prisma` para modelo de datos vigente;
4. `docs/canon/dominio-sacdia.md`, `identidad-sacdia.md`, `arquitectura-sacdia.md` y `decisiones-clave.md` para interpretación canónica;
5. `docs/00-STEERING/tech.md`, `coding-standards.md`, `data-guidelines.md`, `agents.md` como baseline subordinada.

`Runtime` no debe usar esta matriz para redefinir autoridad; solo para saber qué cobertura ya está documentada y dónde hay huecos.
