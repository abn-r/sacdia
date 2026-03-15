# Decisiones Pendientes para el Desarrollador

Generado: 2026-03-14
Fuente: Reality Matrix + Canon verification

---

## Canon aspiracional — mantener como objetivo?

Claims del canon que NO estan implementados en codigo. El desarrollador necesita decidir: mantener como spec/objetivo, o remover del canon.

| Claim canon | Archivo | Detalle |
|---|---|---|
| Validacion de investiduras como acto institucional | `decisiones-clave.md` (decision 6), `dominio-sacdia.md` | Tablas existen (`investiture_validation_history`, `investiture_config`, `investiture_status_enum` en enrollments) pero no hay modulo backend, endpoints, pages ni screens. Es FANTASMA. |
| Supabase Storage | `runtime-sacdia.md` seccion 9 (CORREGIDO) | Ya corregido a Cloudflare R2 en esta actualizacion. No requiere decision adicional. |

---

## Codigo sin canon — agregar al negocio?

Modulos, endpoints y modelos que existen en codigo pero canon no define. El desarrollador necesita decidir: formalizar en canon, o marcar como deuda tecnica/operacion implicita.

### Modulos sin canon
| Modulo | Estado | Detalle |
|---|---|---|
| gestion-seguros (insurance) | SIN CANON | App tiene 3 screens completas + datasource. Tabla `member_insurances` existe. No hay backend module dedicado ni endpoints. Necesita backend o remocion de screens. |
| infrastructure (health, logging) | SIN CANON | Backend CommonModule + Sentry configurado. No mencionado en canon como dominio. |

### Endpoints admin de catalogos sin canon (16+ endpoints)
Estos CRUD admin estan implementados y documentados en API docs pero no mencionados como capacidad en ningun documento canon:

- `/admin/allergies` (CRUD completo)
- `/admin/diseases` (CRUD completo)
- `/admin/relationship-types` (CRUD completo)
- `/admin/ecclesiastical-years` (CRUD completo)
- `/admin/medicines` (CRUD completo, SIN DOCS en ENDPOINTS-LIVE-REFERENCE)

### Catalogos publicos sin canon
- `GET /catalogs/relationship-types`
- `GET /catalogs/club-ideals`
- `GET /catalogs/allergies`
- `GET /catalogs/diseases`

### Modelos de datos sin canon (41 de 72)
Solo los mas relevantes (tablas auxiliares/pivote omitidas):

| Modelo | Contexto |
|---|---|
| `club_ideals` | Ideales de club, catalogo |
| `club_inventory` | Inventario de club |
| `finances_categories` | Categorias financieras |
| `folders` + 4 tablas relacionadas | Carpetas de evidencia (folders) — el concepto existe en canon pero las tablas no |
| `certifications` + 4 tablas relacionadas | Certificaciones GM — el concepto existe en canon pero tablas no documentadas |
| `member_insurances` | Seguros de miembros |
| `investiture_validation_history` + `investiture_config` | Investiduras — mencionado en canon como aspiracional |
| `weekly_records` | Registros semanales |
| `unit_members` + `units` | Unidades dentro de secciones |
| `user_fcm_tokens` | Tokens FCM para push notifications |
| `error_logs` | Logs de errores |

---

## Drift detectado — cual es la verdad?

Casos donde codigo difiere de documentacion. El desarrollador necesita decidir cual es correcto.

| Item | Documentacion decia | Codigo dice | Resolucion |
|---|---|---|---|
| Storage provider | Supabase Storage | Cloudflare R2 (R2FileStorageService) | RESUELTO: canon actualizado a R2 |
| `users.id` vs `users.user_id` | SCHEMA-REFERENCE usaba `id UUID` | schema.prisma usa `user_id` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users.birthdate` vs `birthday` | SCHEMA-REFERENCE usaba `birthdate` | schema.prisma usa `birthday` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users.avatar` vs `user_image` | SCHEMA-REFERENCE usaba `avatar` | schema.prisma usa `user_image` | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users_pr` PK | SCHEMA-REFERENCE mostraba `user_id` como PK | schema.prisma tiene `user_pr_id` INT como PK | RESUELTO: SCHEMA-REFERENCE actualizado |
| `users_pr.active_club_assignment_id` | No existia en SCHEMA-REFERENCE | Existe en backend schema.prisma | RESUELTO: agregado a SCHEMA-REFERENCE |
| `club_master_guild` naming | SCHEMA-REFERENCE decia singular | schema.prisma usa `club_master_guilds` (plural) | RESUELTO: SCHEMA-REFERENCE actualizado |
| SCHEMA-REFERENCE cobertura | Cubria ~25 tablas | schema.prisma tiene 72 modelos | SIN RESOLVER: no se agregan las 41+ tablas faltantes; fuera de scope |
| Roles globales en canon | runtime-sacdia.md lista: super_admin, admin, coordinator, user | SCHEMA-REFERENCE lista: super_admin, admin, assistant_admin, coordinator, user | PENDIENTE: decidir si `assistant_admin` debe mencionarse en runtime-sacdia.md |

---

## Endpoints FANTASMA detectados

Estos endpoints son consumidos por admin o app pero NO existen en el backend (198 endpoints auditados):

### Consumidos por admin panel
| Endpoint | Nota |
|---|---|
| `PATCH /admin/users/:userId/approval` | Usado en admin para aprobar usuarios |
| `PATCH /admin/users/:userId` | Fallback de approval en admin |
| `GET /admin/honor-categories` | CRUD completo en admin (5 endpoints) |
| `POST /admin/honor-categories` | Idem |
| `PATCH /admin/honor-categories/:id` | Idem |
| `DELETE /admin/honor-categories/:id` | Idem |
| `GET /admin/honor-categories/:id` | Idem |
| `GET /admin/club-ideals` | Read-only en admin |

### Consumidos por app movil
| Endpoint | Nota |
|---|---|
| `POST /auth/update-password` | Llamado por app pero no existe en backend |
| `GET /club-instances/:id/evidence-folder` | Evidence folder feature sin backend |
| `POST /club-instances/:id/evidence-folder/sections/:sectionId/submit` | Idem |
| `POST /club-instances/:id/evidence-folder/sections/:sectionId/files` | Idem |
| `DELETE /club-instances/:id/evidence-folder/sections/:sectionId/files/:fileId` | Idem |
| `GET /clubs/:clubId/instances/:type/:instanceId/members/insurance` | Insurance listing sin backend |
| `GET /users/:memberId/insurance` | Insurance detail sin backend |
| `POST /users/:memberId/insurance` | Create insurance sin backend |
| `PATCH /insurance/:insuranceId` | Update insurance sin backend |

**Nota**: Ninguno de estos endpoints estaba en ENDPOINTS-LIVE-REFERENCE.md, por lo que no se removio nada de ese documento. El gap es entre lo que los clientes consumen y lo que el backend expone.
