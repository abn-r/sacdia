# Decisiones Pendientes para el Desarrollador

Generado: 2026-03-14
Fuente: Reality Matrix + Canon verification
**Estado: TODAS LAS DECISIONES RESUELTAS**

---

## Consolidación club_sections (2026-03-17)

| Item | Detalle | Resolucion |
|---|---|---|
| 3 tablas idénticas → 1 | `club_adventurers`, `club_pathfinders`, `club_master_guilds` → `club_sections` | RESUELTO: consolidado en tabla única con `club_type_id` como discriminador. Decisión 10 en `decisiones-clave.md`. |
| 3 FK nullables → 1 FK directa | `club_adv_id`/`club_pathf_id`/`club_mg_id` → `club_section_id` en 10 tablas dependientes | RESUELTO: implementado en DB, backend, admin y app. |
| Naming convergencia | `instance` → `section` en URLs y código | RESUELTO: `/clubs/:id/sections/:sectionId`. Permisos: `club_sections:*`. |

---

## Canon aspiracional — mantener como objetivo?

| Claim canon | Archivo | Detalle | Resolucion |
|---|---|---|---|
| Validacion de investiduras como acto institucional | `decisiones-clave.md` (decision 6), `dominio-sacdia.md` | Tablas existen (`investiture_validation_history`, `investiture_config`, `investiture_status_enum` en enrollments) pero no hay modulo backend, endpoints, pages ni screens. Es FANTASMA. | RESUELTO: se mantiene como aspiracional. Ya marcado ASPIRACIONAL en decisiones-clave.md. |
| Supabase Storage | `runtime-sacdia.md` seccion 9 (CORREGIDO) | Ya corregido a Cloudflare R2 en esta actualizacion. No requiere decision adicional. | RESUELTO: corregido a R2 en actualizacion previa. |

---

## Codigo sin canon — agregar al negocio?

### Modulos sin canon
| Modulo | Estado | Detalle | Resolucion |
|---|---|---|---|
| gestion-seguros (insurance) | PARCIAL | App tiene 3 screens completas + datasource. Tabla `member_insurances` existe. No hay backend module dedicado ni endpoints. | RESUELTO: seguros ES canon — parte de la trayectoria institucional del miembro. Agregado a dominio-sacdia.md como "seguro institucional". Backend pendiente de implementacion. |
| infrastructure (health, logging) | NO CANON | Backend CommonModule + Sentry configurado. No mencionado en canon como dominio. | RESUELTO: NO es canon de negocio. Es infraestructura operativa. Documentado por referencia en runtime-sacdia.md seccion 9.1. |

### Endpoints admin de catalogos sin canon (16+ endpoints)
| Endpoints | Resolucion |
|---|---|
| `/admin/allergies` (CRUD completo) | RESUELTO: son catalogos de trayectoria — ES canon. Documentados en runtime-sacdia.md seccion 6.5. Acceso controlado via RBAC, no endpoints separados. |
| `/admin/diseases` (CRUD completo) | Idem |
| `/admin/relationship-types` (CRUD completo) | Idem |
| `/admin/ecclesiastical-years` (CRUD completo) | Idem |
| `/admin/medicines` (CRUD completo, SIN DOCS en ENDPOINTS-LIVE-REFERENCE) | Idem |

### Catalogos publicos sin canon
| Endpoints | Resolucion |
|---|---|
| `GET /catalogs/relationship-types` | RESUELTO: catalogos de trayectoria — ES canon. Soportan la trayectoria institucional del miembro. |
| `GET /catalogs/club-ideals` | Idem |
| `GET /catalogs/allergies` | Idem |
| `GET /catalogs/diseases` | Idem |

### Modelos de datos sin canon (41 de 72)
| Resolucion |
|---|
| RESUELTO: los 72 modelos han sido categorizados en runtime-sacdia.md seccion 8.3 como: core de trayectoria, catalogos de trayectoria, operativos, infraestructura, RBAC y organizacion. |

---

## Drift detectado — cual es la verdad?

| Item | Documentacion decia | Codigo dice | Resolucion |
|---|---|---|---|
| Storage provider | Supabase Storage | Cloudflare R2 (R2FileStorageService) | RESUELTO: canon actualizado a R2 |
| `users.id` vs `users.user_id` | SCHEMA-REFERENCE usaba `id UUID` | schema.prisma usa `user_id` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users.birthdate` vs `birthday` | SCHEMA-REFERENCE usaba `birthdate` | schema.prisma usa `birthday` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users.avatar` vs `user_image` | SCHEMA-REFERENCE usaba `avatar` | schema.prisma usa `user_image` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users_pr` PK | SCHEMA-REFERENCE mostraba `user_id` como PK | schema.prisma tiene `user_pr_id` INT como PK | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users_pr.active_club_assignment_id` | No existia en SCHEMA-REFERENCE | Existe en backend schema.prisma | RESUELTO: agregado a SCHEMA-REFERENCE |
| `club_master_guild` naming | SCHEMA-REFERENCE decia singular | schema.prisma usa `club_master_guilds` (plural) | RESUELTO: SCHEMA-REFERENCE actualizado |
| SCHEMA-REFERENCE cobertura | Cubria ~25 tablas | schema.prisma tiene 72 modelos | RESUELTO: fuera de scope para SCHEMA-REFERENCE. Modelos categorizados en runtime-sacdia.md seccion 8.3 |
| Roles globales en canon | runtime-sacdia.md lista: super_admin, admin, coordinator, user | SCHEMA-REFERENCE lista: super_admin, admin, assistant_admin, coordinator, user | RESUELTO: `assistant_admin` agregado a runtime-sacdia.md seccion 7.2 |

---

## Endpoints FANTASMA detectados

### Consumidos por admin panel
| Endpoint | Nota | Resolucion |
|---|---|---|
| `PATCH /admin/users/:userId/approval` | Usado en admin para aprobar usuarios | RESUELTO: pendiente de implementacion en backend. Documentado en features/auth.md |
| `PATCH /admin/users/:userId` | Fallback de approval en admin | RESUELTO: pendiente de implementacion en backend |
| `GET /admin/honor-categories` | CRUD completo en admin (5 endpoints) | RESUELTO: pendiente de implementacion en backend. Documentado en features/honores.md |
| `POST /admin/honor-categories` | Idem | Idem |
| `PATCH /admin/honor-categories/:id` | Idem | Idem |
| `DELETE /admin/honor-categories/:id` | Idem | Idem |
| `GET /admin/honor-categories/:id` | Idem | Idem |
| `GET /admin/club-ideals` | Read-only en admin | RESUELTO: pendiente de implementacion en backend. Documentado en features/catalogos.md |

### Consumidos por app movil
| Endpoint | Nota | Resolucion |
|---|---|---|
| `POST /auth/update-password` | Llamado por app pero no existe en backend | RESUELTO: pendiente de implementacion en backend. Documentado en features/auth.md |
| `GET /clubs/:clubId/sections/:sectionId/evidence-folder` | Evidence folder feature sin backend | RESUELTO: pendiente de implementacion. Naming canonico consolidado (2026-03-17). Documentado en features/carpetas-evidencias.md |
| `POST /clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/submit` | Idem | Idem |
| `POST /clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files` | Idem | Idem |
| `DELETE /clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files/:fileId` | Idem | Idem |
| `GET /clubs/:clubId/sections/:sectionId/members/insurance` | Insurance listing sin backend | RESUELTO: pendiente de implementacion. Seguros es canon de trayectoria. Documentado en features/gestion-seguros.md |
| `GET /users/:memberId/insurance` | Insurance detail sin backend | Idem |
| `POST /users/:memberId/insurance` | Create insurance sin backend | Idem |
| `PATCH /insurance/:insuranceId` | Update insurance sin backend | Idem |

**Nota**: Ninguno de estos endpoints estaba en ENDPOINTS-LIVE-REFERENCE.md, por lo que no se removio nada de ese documento. El gap es entre lo que los clientes consumen y lo que el backend expone. Todos marcados como pendientes de implementacion en sus respectivos archivos de features.

---

## Gaps de implementacion — Wave 2 (2026-03-20)

Descubiertos durante auditoría Wave 2. Fuente: docs de features bajo `docs/features/` y `docs/canon/completion-matrix.md` (OPEN).

### GAP-W2-01: Validacion de Investiduras — PARCIAL

| Item | Detalle |
|---|---|
| Infraestructura DB | Completa: `investiture_validation_history`, `investiture_config`, 3 enums, campos de investidura en `enrollments` |
| Runtime backend | IMPLEMENTADO: InvestitureModule con 5 endpoints, 23 tests. |
| Runtime frontend | CERO: no hay pages en admin, no hay screens en app |
| Severidad | Gap funcional — backend listo, falta UI |
| Estado | PARTIAL 2026-03-20: Backend implementado (InvestitureModule, 5 endpoints, 23 tests). Pendiente: UI admin y app. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-02: Actividades — hardcoded clubId=1 — RESUELTO

| Item | Detalle |
|---|---|
| Problema | El controller/service de actividades tiene `clubId=1` hardcodeado en vez de usar el contexto real del club |
| Tipo | Bug directo |
| Estado | RESUELTO 2026-03-20: Fix aplicado: ActivitiesListView resuelve clubId desde clubContextProvider. Commit dbb14eb. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-03: Finanzas — campos de auditoria faltantes — RESUELTO

| Item | Detalle |
|---|---|
| Problema | Los registros financieros carecen de campos `created_by`/`modified_by` que otros modulos si tienen |
| Tipo | Gap de consistencia / auditoria |
| Estado | RESUELTO 2026-03-20: modified_by_id agregado a finances (migration + schema + service). Commit 69b4b3e. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-04: Inventario — typo en PK de DB — RESUELTO

| Item | Detalle |
|---|---|
| Problema | La tabla `inventory_categories` tiene un typo en su columna PK: `inventory_categoty_id` en vez de `inventory_category_id` |
| Impacto | Prisma lo mapea correctamente, pero el nombre subyacente en la columna es incorrecto |
| Estado | RESUELTO 2026-03-20: Migration creada para rename. Commit d690a57. Pendiente: prisma migrate deploy. |
| Descubierto | Wave 2 (2026-03-20) |

### GAP-W2-05: Certificaciones Guias Mayores — cero UI cliente — RESUELTO

| Item | Detalle |
|---|---|
| Backend | Completamente implementado: 7 endpoints verificados y funcionales |
| Admin panel | UI implementada: list + detail + progress |
| App movil | UI implementada: 4 screens en Flutter |
| Estado | RESUELTO 2026-03-20: UI implementada en Flutter (4 screens) y admin (list + detail + progress). Commits 69cb026 + 37e5929. |
| Descubierto | Wave 2 (2026-03-20) |
