# Matriz de Enforcement RBAC

**Status**: ACTIVE
**Fecha**: 2026-03-10
**Ambito**: backend enforced permissions

## Proposito

Esta matriz define como se traduce un permiso en enforcement real de backend y como deben consumirlo `sacdia-admin` y `sacdia-app`.

La regla principal es:

- JWT autentica;
- `PermissionsGuard` autoriza;
- el frontend nunca es barrera de seguridad.

## Tipos de Recurso

| Tipo | Descripcion | Resolucion |
|------|-------------|------------|
| `global` | Recurso administrativo o territorial | Permisos globales + scope territorial |
| `club` | Recurso de club padre | Permiso efectivo + bypass global o contexto club activo |
| `club_instance` | Recurso de instancia exacta | Permiso efectivo + asignacion activa exacta |
| `club_assignment` | Recurso de asignacion | Permiso efectivo + relacion con `assignment_id` |
| `user` | Recurso del propio usuario | Permiso global o fallback de ownership |

Nota de implementacion:

- En codigo existen recursos derivados (`activity`, `finance`, `inventory_item`, `inventory_instance`) que resuelven finalmente a validacion de `club_instance`.

## Reglas de Evaluacion

1. Para recursos globales, solo cuentan grants globales.
2. Para recursos de club, puede entrar:
   - un permiso global suficiente dentro del territorio;
   - o la asignacion activa exacta del usuario.
3. Los permisos de club salen solo de `active_assignment`.
4. No se unen todas las asignaciones del usuario para una request.
5. JWT-only solo es aceptable en self-service estricto con ownership real.

## Matriz Operativa

| Permiso | Accion | Recurso | Enforcement backend | Cliente esperado |
|---------|--------|---------|---------------------|------------------|
| `users:read` | Listar usuarios | `global` | permiso global | Admin |
| `users:read_detail` | Ver detalle de usuario | `global` o `user` | permiso global o ownership segun ruta | Admin y self-service |
| `users:update` | Editar usuario | `global` o `user` | permiso global o guard de ownership | Admin y self-service |
| `clubs:read` | Ver club | `club` | permiso global territorial o contexto club | Admin y App |
| `clubs:create` | Crear club | `global` | permiso global | Admin |
| `clubs:update` | Editar club | `club` | permiso global territorial o active assignment compatible | Admin y App |
| `clubs:delete` | Desactivar club | `club` | permiso global territorial o active assignment compatible | Admin |
| `club_instances:read` | Ver instancias | `club` | permiso global territorial o contexto club | Admin y App |
| `club_instances:create` | Crear instancia | `club` | permiso global territorial o active assignment compatible | Admin |
| `club_instances:update` | Editar instancia | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin y App |
| `club_roles:read` | Ver miembros y asignaciones | `club` | permiso global territorial o contexto club | Admin y App |
| `club_roles:assign` | Crear asignacion (`POST /clubs/:clubId/instances/:type/:instanceId/roles`) | `club` | permiso + contexto club valido + reglas complementarias (`ClubRolesGuard`) | Admin y App |
| `club_roles:assign` | Actualizar asignacion (`PATCH /club-roles/:assignmentId`) | `club_assignment` | permiso efectivo + active assignment o bypass global | Admin y App |
| `club_roles:revoke` | Revocar asignacion (`DELETE /club-roles/:assignmentId`) | `club_assignment` | permiso efectivo + active assignment o bypass global | Admin |
| `activities:read` | Ver actividades | `club` | permiso global territorial o contexto club | Admin y App |
| `activities:create` | Crear actividad | `club` | permiso efectivo + contexto valido | Admin y App |
| `activities:update` | Editar actividad | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `activities:delete` | Eliminar actividad | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin |
| `attendance:read` | Ver asistencia | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `attendance:manage` | Pasar asistencia | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `finances:read` | Ver finanzas | `club` | permiso global territorial o contexto club | Admin y App |
| `finances:create` | Crear movimiento | `club` | permiso efectivo + contexto valido | Admin y App |
| `finances:update` | Editar movimiento | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin y App |
| `finances:delete` | Eliminar movimiento | `club_instance` | permiso efectivo + instancia exacta o bypass global | Admin |
| `inventory:read` | Ver inventario | `club` | permiso global territorial o contexto club | Admin y App |
| `inventory:create` | Crear item | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin y App |
| `inventory:update` | Editar item | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin y App |
| `inventory:delete` | Eliminar item | `club_instance` | permiso efectivo + asignacion activa exacta o bypass global | Admin |
| `notifications:send` | Enviar notificacion directa | `global` | permiso global explicito | Admin |
| `notifications:broadcast` | Enviar notificacion masiva | `global` | permiso global explicito | Admin |
| `notifications:club` | Enviar notificacion a club | `global` (Stage 1) | permiso global explicito (sin resource scope adicional en esta etapa) | Admin |
| `permissions:read` | Ver RBAC | `global` | permiso global | Admin |
| `permissions:assign` | Cambiar permisos | `global` | permiso global | Admin |
| `roles:read` | Ver roles | `global` | permiso global | Admin |

## Cobertura y Limites de Stage 1

- Esta matriz refleja enforcement activo de rutas sensibles priorizadas.
- El catalogo completo de permisos vive en `PERMISSIONS-SYSTEM.md`.
- No todo permiso del catalogo implica que su modulo ya este endurecido al 100% con metadata de recurso en esta etapa.

## Recursos `user` sensibles verificados

| Superficie | Rutas verificadas | Permiso runtime | Enforcement backend | Estado |
|------------|-------------------|-----------------|---------------------|--------|
| Perfil y derivados (fuera de scope) | `GET/PATCH /users/:userId`, `GET /age`, `GET /requires-legal-representative`, `POST/DELETE /profile-picture` | `users:read_detail` o `users:update` | ownership o permiso global; metadata legacy `users:*` | Verificado |
| Salud | `GET/PUT /allergies`, `GET/PUT /diseases`, `GET/PUT /medicines`, `DELETE /allergies/:allergyId`, `DELETE /diseases/:diseaseId`, `DELETE /medicines/:medicineId` | `health:read` / `health:update` OR fallback `users:read_detail` / `users:update` | ownership o permiso global; baseline activo limitado a `allergies` + `diseases` + `medicines` | Verificado |
| Contactos de emergencia | `GET/POST/PATCH/DELETE /emergency-contacts` | `emergency_contacts:read` / `emergency_contacts:update` OR fallback `users:read_detail` / `users:update` | ownership o permiso global | Verificado |
| Representante legal | `GET/POST/PATCH/DELETE /legal-representative` | `legal_representative:read` / `legal_representative:update` OR fallback `users:read_detail` / `users:update` | ownership o permiso global | Verificado |
| Post-registro (lectura) | `GET /post-registration/status` | `post_registration:read` OR fallback `users:read_detail` | ownership o permiso global | Verificado runtime |
| Post-registro (completar) | `POST /step-1/complete`, `POST /step-2/complete`, `POST /step-3/complete` | `registration:complete` _(sin fallback)_ | ownership o permiso global dedicado; terceros quedan en modo administrativo minimo | Verificado runtime |

Notas:

- `PermissionsGuard` permite owner fallback antes de resolver permisos explicitos en recursos `user`.
- Para actores no owner, solo cuentan permisos globales; un `active_assignment` con permisos de club no abre acceso a datos `user` de terceros.
- OR transicional vigente en backend: permiso fino de familia o fallback legacy de la familia `users:*` (`users:read_detail` para lectura, `users:update` para escritura). Excepcion: `registration:complete` no tiene fallback legacy.
- `registration:complete` es un permiso global dedicado asignado a roles de campo (super_admin, admin, assistant-lf, director-lf y equivalentes union/dia por herencia). El owner siempre puede completar su propio registro sin este permiso.
- Baseline health activo verificado: `allergies` + `diseases` + `medicines`.
- `medicines` se limita a catalogo + relacion sensible `user -> medicines`; no existe vinculo runtime `medicine <-> disease` en esta fase.
- Excepcion minima vigente: `post_registration` de terceros mantiene lectura administrativa minima y completion con `registration:complete`, sin feedback sensible detallado.
- Exclusiones fuera de scope del change: perfil base, foto de perfil y derivados de edad/representante legal siguen en metadata legacy `users:*`.

## Validacion Transversal Final (Batch 3)

| Capa | Evidencia verificada | Resultado |
|------|----------------------|-----------|
| Docs auth | `AUTHORIZATION-CANONICAL-CONTRACT.md` y esta matriz usan las mismas familias finas, fallback legacy y exclusiones fuera de scope | Alineado |
| Backend | `PermissionsGuard` mantiene ownership o permiso global para recurso `user`; permisos de club no alcanzan terceros | Alineado |
| Admin | consumo canonico desde `authorization.effective.permissions` y `authorization.grants` | Alineado |
| Mobile | helpers separan `administrative completion` de acceso a datos sensibles y no tratan `users:update` como permiso sensible de lectura | Alineado |

## Endpoints que no deben quedar en JWT-only

Las siguientes categorias no deben confiar solo en autenticacion:

- administracion de usuarios;
- geografia y catalogos sensibles;
- clubes e instancias;
- miembros y asignaciones de rol;
- actividades;
- finanzas;
- inventario;
- notificaciones;
- cualquier mutacion compartida.

## Endpoints que si pueden vivir con ownership

JWT-only o ownership guard dedicado sigue siendo valido solo si:

- el recurso es exclusivamente del usuario autenticado;
- no altera datos compartidos del club;
- no eleva privilegios;
- no actua sobre informacion de terceros.

## Consumo por Cliente

### `sacdia-admin`

- Usa `authorization.effective.permissions` para pagina, accion y visibilidad operativa.
- Puede usar `authorization.grants` para matrices, explicaciones y detalle.

### `sacdia-app`

- Usa `authorization.effective.permissions` para habilitar acciones.
- Usa `authorization.effective.scope.club` para el club/instancia actual.
- Usa `authorization.grants.club_assignments` para selector de contexto.

## Referencias Relacionadas

- `docs/features/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/features/auth/PERMISSIONS-SYSTEM.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
