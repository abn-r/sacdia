# Feature Registry — SACDIA
Generado: 2026-03-14 | Actualizado: 2026-03-20
Fuente: Reality Matrix + Code Audits

## Resumen

| Dominio | Estado | Backend | Admin | App |
|---------|--------|---------|-------|-----|
| [auth](auth.md) | IMPLEMENTADO | AuthModule (22 endpoints) | Login funcional | 5 screens |
| [gestion-clubs](gestion-clubs.md) | IMPLEMENTADO | ClubsModule (13 endpoints) | 3 pages funcionales | club + members + units |
| [clases-progresivas](clases-progresivas.md) | IMPLEMENTADO | ClassesModule (7 endpoints) | Read-only | 6 screens |
| [honores](honores.md) | IMPLEMENTADO | HonorsModule (12 endpoints) | CRUD funcional | 4 screens |
| [actividades](actividades.md) | IMPLEMENTADO | ActivitiesModule (7 endpoints) | UI completa (list + detail + create/edit + delete) | 4 screens + edit/delete en detalle |
| [finanzas](finanzas.md) | IMPLEMENTADO | FinancesModule (7 endpoints) | Dashboard completo (resumen + tabla + filtros + CRUD) | 3 screens + eliminacion con AlertDialog |
| [catalogos](catalogos.md) | IMPLEMENTADO | CatalogsModule + AdminModule (54 endpoints) | 13 pages funcionales | Shared catalogs |
| [camporees](camporees.md) | IMPLEMENTADO | CamporeesModule (8 endpoints) | CRUD completo + gestion de miembros | 4 screens + capa de datos completa |
| [communications](communications.md) | IMPLEMENTADO | NotificationsModule (7 endpoints) | 1 page funcional | FCM tokens |
| [certificaciones-guias-mayores](certificaciones-guias-mayores.md) | IMPLEMENTADO | CertificationsModule (7 endpoints) | list + detail + progress | 4 screens |
| [inventario](inventario.md) | IMPLEMENTADO | InventoryModule (6 endpoints) | CRUD funcional | 4 screens |
| [gestion-seguros](gestion-seguros.md) | IMPLEMENTADO | InsurancesModule | CRUD funcional | 3 screens |
| [carpetas-evidencias](carpetas-evidencias.md) | IMPLEMENTADO | FoldersModule (7 endpoints) | Read-only | 2 screens |
| [rbac](rbac.md) | IMPLEMENTADO | RbacModule (10 endpoints) | 3 pages funcionales | No aplica |
| [infrastructure](infrastructure.md) | SIN CANON | CommonModule + AppModule | No implementado | No implementado |
| [validacion-investiduras](validacion-investiduras.md) | IMPLEMENTADO | InvestitureModule (5 endpoints) | table + dialogs + history | 3 screens |

## Conteo por estado

| Estado | Cantidad | Dominios |
|--------|----------|----------|
| IMPLEMENTADO | 15 | auth, gestion-clubs, clases-progresivas, honores, catalogos, communications, carpetas-evidencias, rbac, gestion-seguros, actividades, finanzas, camporees, certificaciones-guias-mayores, inventario, validacion-investiduras |
| PARCIAL | 0 | — |
| SIN CANON | 1 | infrastructure |
| FANTASMA | 0 | — |
