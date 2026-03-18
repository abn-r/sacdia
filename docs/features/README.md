# Feature Registry — SACDIA
Generado: 2026-03-14
Fuente: Reality Matrix + Code Audits

## Resumen

| Dominio | Estado | Backend | Admin | App |
|---------|--------|---------|-------|-----|
| [auth](auth.md) | IMPLEMENTADO | AuthModule (22 endpoints) | Login funcional | 5 screens |
| [gestion-clubs](gestion-clubs.md) | IMPLEMENTADO | ClubsModule (13 endpoints) | 3 pages funcionales | club + members + units |
| [clases-progresivas](clases-progresivas.md) | IMPLEMENTADO | ClassesModule (7 endpoints) | Read-only | 6 screens |
| [honores](honores.md) | IMPLEMENTADO | HonorsModule (12 endpoints) | CRUD funcional | 4 screens |
| [actividades](actividades.md) | PARCIAL | ActivitiesModule (7 endpoints) | Placeholder | 4 screens |
| [finanzas](finanzas.md) | PARCIAL | FinancesModule (7 endpoints) | Placeholder | 3 screens |
| [catalogos](catalogos.md) | IMPLEMENTADO | CatalogsModule + AdminModule (54 endpoints) | 13 pages funcionales | Shared catalogs |
| [camporees](camporees.md) | PARCIAL | CamporeesModule (8 endpoints) | Read-only | No implementado |
| [communications](communications.md) | IMPLEMENTADO | NotificationsModule (7 endpoints) | 1 page funcional | FCM tokens |
| [certificaciones-guias-mayores](certificaciones-guias-mayores.md) | PARCIAL | CertificationsModule (7 endpoints) | Read-only | No implementado |
| [inventario](inventario.md) | PARCIAL | InventoryModule (6 endpoints) | Placeholder | 4 screens |
| [gestion-seguros](gestion-seguros.md) | SIN CANON | No hay modulo | Placeholder | 3 screens (FANTASMA) |
| [carpetas-evidencias](carpetas-evidencias.md) | IMPLEMENTADO | FoldersModule (7 endpoints) | Read-only | 2 screens |
| [rbac](rbac.md) | IMPLEMENTADO | RbacModule (10 endpoints) | 3 pages funcionales | No aplica |
| [infrastructure](infrastructure.md) | SIN CANON | CommonModule + AppModule | No implementado | No implementado |
| [validacion-investiduras](validacion-investiduras.md) | FANTASMA | No hay modulo | No implementado | No implementado |

## Conteo por estado

| Estado | Cantidad | Dominios |
|--------|----------|----------|
| IMPLEMENTADO | 8 | auth, gestion-clubs, clases-progresivas, honores, catalogos, communications, carpetas-evidencias, rbac |
| PARCIAL | 5 | actividades, finanzas, camporees, certificaciones-guias-mayores, inventario |
| SIN CANON | 2 | gestion-seguros, infrastructure |
| FANTASMA | 1 | validacion-investiduras |
