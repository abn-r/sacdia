# Feature Registry — SACDIA
Generado: 2026-03-14 | Actualizado: 2026-03-27
Fuente: Reality Matrix + Code Audits

## Resumen

| Dominio | Estado | Backend | Admin | App |
|---------|--------|---------|-------|-----|
| [auth](auth.md) | IMPLEMENTADO | AuthModule (22 endpoints) | Login funcional | 5 screens |
| [gestion-clubs](gestion-clubs.md) | IMPLEMENTADO | ClubsModule (13 endpoints) | 3 pages funcionales | club + members + units |
| [clases-progresivas](clases-progresivas.md) | IMPLEMENTADO | ClassesModule (7 endpoints) | Read-only | 6 screens |
| [honores](honores.md) | IMPLEMENTADO | HonorsModule (16 endpoints, incluye requirements + progress) | CRUD funcional | 4 screens + checklist de requisitos por honor |
| [actividades](actividades.md) | IMPLEMENTADO | ActivitiesModule (7 endpoints) | UI completa (list + detail + create/edit + delete) | 4 screens + edit/delete en detalle |
| [finanzas](finanzas.md) | IMPLEMENTADO | FinancesModule (7 endpoints) | Dashboard completo (resumen + tabla + filtros + CRUD) | 3 screens + eliminacion con AlertDialog |
| [catalogos](catalogos.md) | IMPLEMENTADO | CatalogsModule + AdminModule (54 endpoints) | 13 pages funcionales | Shared catalogs |
| [camporees](camporees.md) | IMPLEMENTADO | CamporeesModule (8 endpoints) | CRUD completo + gestion de miembros | 4 screens + capa de datos completa |
| [communications](communications.md) | IMPLEMENTADO | NotificationsModule (7 endpoints) | 1 page funcional | FCM tokens |
| [certificaciones-guias-mayores](certificaciones-guias-mayores.md) | IMPLEMENTADO | CertificationsModule (7 endpoints) | list + detail + progress | 4 screens |
| [inventario](inventario.md) | IMPLEMENTADO | InventoryModule (6 endpoints) | CRUD funcional | 4 screens |
| [gestion-seguros](gestion-seguros.md) | IMPLEMENTADO | InsurancesModule | CRUD funcional | 3 screens |
| [carpetas-evidencias](carpetas-evidencias.md) | IMPLEMENTADO | FoldersModule (7 endpoints) | Read-only | 2 screens |
| [annual-folders-scoring](annual-folders-scoring.md) | IMPLEMENTADO | EvaluationModule + AwardCategoriesModule + RankingsModule (11 endpoints) | Evaluacion + Rankings + CRUD categorias | Solo lectura |
| [rbac](rbac.md) | IMPLEMENTADO | RbacModule (10 endpoints) | 3 pages funcionales | No aplica |
| [aprobaciones-camporees](aprobaciones-camporees.md) | IMPLEMENTADO | CamporeesModule (approval endpoints) | Approval UI (pending badges, union routing, member status) | No aplica |
| [aprobaciones-masivas](aprobaciones-masivas.md) | IMPLEMENTADO | InvestitureModule (+2 bulk endpoints) | Bulk action bar + checkboxes (hasta 200) | No aplica |
| [validacion-evidencias](validacion-evidencias.md) | IMPLEMENTADO | EvidenceReviewModule (7 endpoints) | Dedicated review page + gallery + bulk ops | No aplica |
| [sla-dashboard](sla-dashboard.md) | IMPLEMENTADO | AnalyticsModule (1 endpoint) | Dashboard con metricas operacionales | No aplica |
| [recursos](recursos.md) | IMPLEMENTADO | ResourcesModule (14 endpoints) | Categorias CRUD + Recursos CRUD | Clean Architecture completa |
| [infrastructure](infrastructure.md) | SIN CANON | CommonModule + AppModule | No implementado | No implementado |
| [validacion-investiduras](validacion-investiduras.md) | IMPLEMENTADO | InvestitureModule (5 endpoints) | table + dialogs + history | 3 screens |

## Conteo por estado

| Estado | Cantidad | Dominios |
|--------|----------|----------|
| IMPLEMENTADO | 21 | auth, gestion-clubs, clases-progresivas, honores, catalogos, communications, carpetas-evidencias, annual-folders-scoring, rbac, gestion-seguros, actividades, finanzas, camporees, certificaciones-guias-mayores, inventario, validacion-investiduras, aprobaciones-camporees, aprobaciones-masivas, validacion-evidencias, sla-dashboard, recursos |
| PARCIAL | 0 | — |
| SIN CANON | 1 | infrastructure |
| FANTASMA | 0 | — |
