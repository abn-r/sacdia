# Decisiones Pendientes para el Desarrollador

Generado: 2026-03-14
Fuente: Reality Matrix + Canon verification
**Estado: TODAS LAS DECISIONES RESUELTAS**

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
| `GET /club-instances/:id/evidence-folder` | Evidence folder feature sin backend | RESUELTO: pendiente de implementacion. Naming canonico: `/club-sections/:id/evidence-folder`. Documentado en features/carpetas-evidencias.md |
| `POST /club-instances/:id/evidence-folder/sections/:sectionId/submit` | Idem | Idem — usar `/club-sections/` en implementacion |
| `POST /club-instances/:id/evidence-folder/sections/:sectionId/files` | Idem | Idem |
| `DELETE /club-instances/:id/evidence-folder/sections/:sectionId/files/:fileId` | Idem | Idem |
| `GET /clubs/:clubId/instances/:type/:instanceId/members/insurance` | Insurance listing sin backend | RESUELTO: pendiente de implementacion. Seguros es canon de trayectoria. Documentado en features/gestion-seguros.md |
| `GET /users/:memberId/insurance` | Insurance detail sin backend | Idem |
| `POST /users/:memberId/insurance` | Create insurance sin backend | Idem |
| `PATCH /insurance/:insuranceId` | Update insurance sin backend | Idem |

**Nota**: Ninguno de estos endpoints estaba en ENDPOINTS-LIVE-REFERENCE.md, por lo que no se removio nada de ese documento. El gap es entre lo que los clientes consumen y lo que el backend expone. Todos marcados como pendientes de implementacion en sus respectivos archivos de features.
