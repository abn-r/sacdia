# Matriz de Enforcement RBAC

**Status**: ACTIVE  
**Fecha**: 2026-03-08  
**Ámbito**: backend enforced permissions

## Propósito

Esta matriz define cómo se traduce un permiso en enforcement real de backend y cómo deben consumirlo `sacdia-admin` y `sacdia-app`.

La regla principal es:

- JWT autentica;
- `PermissionsGuard` autoriza;
- el frontend nunca es barrera de seguridad.

## Tipos de Recurso

| Tipo | Descripción | Resolución |
|------|-------------|------------|
| `global` | Recurso administrativo o territorial | Permisos globales + scope territorial |
| `club` | Recurso de club padre | Permiso efectivo + bypass global o contexto club activo |
| `club_instance` | Recurso de instancia exacta | Permiso efectivo + asignación activa exacta |
| `club_assignment` | Recurso de asignación | Permiso efectivo + relación con `assignment_id` |
| `user` | Recurso del propio usuario | Permiso global o fallback de ownership |

Nota de implementación:

- En código existen recursos derivados (`activity`, `finance`, `inventory_item`, `inventory_instance`) que resuelven finalmente a validación de `club_instance`.

## Reglas de Evaluación

1. Para recursos globales, solo cuentan grants globales.
2. Para recursos de club, puede entrar:
   - un permiso global suficiente dentro del territorio;
   - o la asignación activa exacta del usuario.
3. Los permisos de club salen solo de `active_assignment`.
4. No se unen todas las asignaciones del usuario para una request.
5. JWT-only solo es aceptable en self-service estricto con ownership real.

## Matriz Operativa

| Permiso | Acción | Recurso | Enforcement backend | Cliente esperado |
|---------|--------|---------|---------------------|------------------|
| `users:read` | Listar usuarios | `global` | permiso global | Admin |
| `users:read_detail` | Ver detalle de usuario | `global` o `user` | permiso global o ownership según ruta | Admin y self-service |
| `users:update` | Editar usuario | `global` o `user` | permiso global o guard de ownership | Admin y self-service |
| `clubs:read` | Ver club | `club` | permiso global territorial o contexto club | Admin y App |
| `clubs:create` | Crear club | `global` | permiso global | Admin |
| `clubs:update` | Editar club | `club` | permiso global territorial o active assignment compatible | Admin y App |
| `clubs:delete` | Desactivar club | `club` | permiso global territorial o active assignment compatible | Admin |
| `club_instances:read` | Ver instancias | `club` | permiso global territorial o contexto club | Admin y App |
| `club_instances:create` | Crear instancia | `club` | permiso global territorial o active assignment compatible | Admin |
| `club_instances:update` | Editar instancia | `club_instance` | permiso efectivo + asignación activa exacta o bypass global | Admin y App |
| `club_roles:read` | Ver miembros y asignaciones | `club` | permiso global territorial o contexto club | Admin y App |
| `club_roles:assign` | Crear asignación (`POST /clubs/:clubId/instances/:type/:instanceId/roles`) | `club` | permiso + contexto club válido + reglas complementarias (`ClubRolesGuard`) | Admin y App |
| `club_roles:assign` | Actualizar asignación (`PATCH /club-roles/:assignmentId`) | `club_assignment` | permiso efectivo + active assignment o bypass global | Admin y App |
| `club_roles:revoke` | Revocar asignación (`DELETE /club-roles/:assignmentId`) | `club_assignment` | permiso efectivo + active assignment o bypass global | Admin |
| `activities:read` | Ver actividades | `club` | permiso global territorial o contexto club | Admin y App |
| `activities:create` | Crear actividad | `club` | permiso efectivo + contexto válido | Admin y App |
| `activities:update` | Editar actividad | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `activities:delete` | Eliminar actividad | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin |
| `attendance:read` | Ver asistencia | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `attendance:manage` | Pasar asistencia | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `finances:read` | Ver finanzas | `club` | permiso global territorial o contexto club | Admin y App |
| `finances:create` | Crear movimiento | `club` | permiso efectivo + contexto válido | Admin y App |
| `finances:update` | Editar movimiento | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `finances:delete` | Eliminar movimiento | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin |
| `inventory:read` | Ver inventario | `club` | permiso global territorial o contexto club | Admin y App |
| `inventory:create` | Crear ítem | `club_instance` | permiso efectivo + asignación activa exacta o bypass global | Admin y App |
| `inventory:update` | Editar ítem | `club_instance` | permiso efectivo + asignación activa exacta o bypass global | Admin y App |
| `inventory:delete` | Eliminar ítem | `club_instance` | permiso efectivo + asignación activa exacta o bypass global | Admin |
| `notifications:send` | Enviar notificación directa | `global` | permiso global explícito | Admin |
| `notifications:broadcast` | Enviar notificación masiva | `global` | permiso global explícito | Admin |
| `notifications:club` | Enviar notificación a club | `global` (Stage 1) | permiso global explícito (sin resource scope adicional en esta etapa) | Admin |
| `permissions:read` | Ver RBAC | `global` | permiso global | Admin |
| `permissions:assign` | Cambiar permisos | `global` | permiso global | Admin |
| `roles:read` | Ver roles | `global` | permiso global | Admin |

## Cobertura y Límites de Stage 1

- Esta matriz refleja enforcement activo de rutas sensibles priorizadas.
- El catálogo completo de permisos vive en `PERMISSIONS-SYSTEM.md`.
- No todo permiso del catálogo implica que su módulo ya esté endurecido al 100% con metadata de recurso en esta etapa.

## Endpoints que no deben quedar en JWT-only

Las siguientes categorías no deben confiar solo en autenticación:

- administración de usuarios;
- geografía y catálogos sensibles;
- clubes e instancias;
- miembros y asignaciones de rol;
- actividades;
- finanzas;
- inventario;
- notificaciones;
- cualquier mutación compartida.

## Endpoints que sí pueden vivir con ownership

JWT-only o ownership guard dedicado sigue siendo válido solo si:

- el recurso es exclusivamente del usuario autenticado;
- no altera datos compartidos del club;
- no eleva privilegios;
- no actúa sobre información de terceros.

## Consumo por Cliente

### `sacdia-admin`

- Usa `authorization.effective.permissions` para página, acción y visibilidad operativa.
- Puede usar `authorization.grants` para matrices, explicaciones y detalle.

### `sacdia-app`

- Usa `authorization.effective.permissions` para habilitar acciones.
- Usa `authorization.effective.scope.club` para el club/instancia actual.
- Usa `authorization.grants.club_assignments` para selector de contexto.

## Referencias Relacionadas

- `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`
- `docs/01-FEATURES/auth/PERMISSIONS-SYSTEM.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
