# Sistema de Permisos - SACDIA

**Status**: ACTIVE
**Fecha**: 2026-03-10

> [!IMPORTANT]
> Este documento es el catalogo canonico de nombres de permisos y su convencion.
> La semantica de autorizacion y enforcement vive en:
> - `docs/features/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
> - `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`

## Resumen Ejecutivo

SACDIA usa RBAC con permisos granulares.

- Los permisos se almacenan en la tabla `permissions`.
- El backend resuelve autorizacion por sesion en el bloque `authorization`.
- Los clientes consumen `authorization.effective.permissions` para gating de UX.

## Modelo Vigente de Autorizacion

### Fuente oficial por sesion

`GET /auth/me` entrega:

- `authorization.grants`
- `authorization.active_assignment`
- `authorization.effective`

Regla:

- `authorization.effective.permissions` es la fuente operativa para habilitar acciones en cliente.
- El arreglo plano legacy `permissions` no es fuente oficial para consumidores nuevos.

### Enforcement en backend

- JWT autentica identidad.
- `PermissionsGuard` autoriza por permiso + recurso.
- Metadata de recurso (`@AuthorizationResource(...)`) define estrategia de scope.
- Frontend no es barrera de seguridad.

## Convencion de Nomenclatura

### Formato: `resource:action`

```
{resource}:{action}
```

| Componente | Reglas | Ejemplos |
|------------|--------|----------|
| `resource` | snake_case, sustantivo plural | `users`, `club_instances`, `local_fields` |
| `action` | snake_case, verbo | `read`, `create`, `update`, `delete` |
| Separador | `:` | `users:create`, `clubs:read` |

### Acciones estandar

| Accion | Descripcion |
|--------|-------------|
| `read` | Ver listado de recursos |
| `read_detail` | Ver detalle de un recurso especifico |
| `create` | Crear nuevo recurso |
| `update` | Editar recurso existente |
| `delete` | Eliminar/desactivar recurso |
| `export` | Exportar datos |
| `assign` | Asignar relacion |
| `revoke` | Revocar relacion |
| `manage` | Gestionar (agrupa acciones) |
| `view` | Visualizacion sin CRUD |

## Catalogo de Permisos por Modulo

> [!NOTE]
> El catalogo incluye permisos existentes de negocio.
> El nivel exacto de enforcement por endpoint se valida en `RBAC-ENFORCEMENT-MATRIX.md`.

### Usuarios
| Permiso | Descripcion |
|---------|-------------|
| `users:read` | Ver listado de usuarios |
| `users:read_detail` | Ver detalle/perfil de un usuario |
| `users:create` | Crear usuario manualmente |
| `users:update` | Editar datos de usuario |
| `users:delete` | Desactivar/eliminar usuario |
| `users:export` | Exportar listado de usuarios |
| `health:read` | Ver sub-recursos sensibles de salud del usuario |
| `health:update` | Editar sub-recursos sensibles de salud del usuario |
| `emergency_contacts:read` | Ver contactos de emergencia del usuario |
| `emergency_contacts:update` | Editar contactos de emergencia del usuario |
| `legal_representative:read` | Ver representante legal del usuario |
| `legal_representative:update` | Editar representante legal del usuario |
| `post_registration:read` | Ver estado administrativo de post-registro |
| `post_registration:update` | Completar o editar pasos administrativos de post-registro |

Notas canonicas del modelo vigente:

- las familias sensibles del change son `health`, `emergency_contacts`, `legal_representative` y `post_registration`;
- OR transicional vigente: para terceros, lectura fina acepta `family:read` o el legado de la familia `users:*` (`users:read_detail`); escritura fina acepta `family:update` o el legado `users:update`;
- exclusiones fuera de scope: `GET/PATCH /users/:userId`, `POST/DELETE /users/:userId/profile-picture`, `GET /users/:userId/age` y `GET /users/:userId/requires-legal-representative` siguen en metadata legacy `users:*`;
- excepcion minima vigente: terceros pueden consultar `post_registration/status` y completar `step-{1,2,3}` solo en modo administrativo minimo, sin feedback sensible adicional.

### Roles y Permisos
| Permiso | Descripcion |
|---------|-------------|
| `roles:read` | Ver roles |
| `roles:create` | Crear roles |
| `roles:update` | Editar roles |
| `roles:delete` | Eliminar roles |
| `roles:assign` | Asignar roles globales a usuarios |
| `permissions:read` | Ver permisos |
| `permissions:assign` | Asignar permisos a roles |

### Clubes
| Permiso | Descripcion |
|---------|-------------|
| `clubs:read` | Ver clubes |
| `clubs:create` | Crear club |
| `clubs:update` | Editar club |
| `clubs:delete` | Desactivar club |
| `club_instances:read` | Ver instancias de club |
| `club_instances:create` | Crear instancia de club |
| `club_instances:update` | Editar instancia |
| `club_instances:delete` | Desactivar instancia |
| `club_roles:read` | Ver asignaciones de rol de club |
| `club_roles:assign` | Asignar rol de club a usuario |
| `club_roles:revoke` | Revocar rol de club |

### Jerarquia Geografica
| Permiso | Descripcion |
|---------|-------------|
| `countries:read` | Ver paises |
| `countries:create` | Crear pais |
| `countries:update` | Editar pais |
| `countries:delete` | Eliminar pais |
| `unions:read` | Ver uniones |
| `unions:create` | Crear union |
| `unions:update` | Editar union |
| `unions:delete` | Eliminar union |
| `local_fields:read` | Ver campos locales |
| `local_fields:create` | Crear campo local |
| `local_fields:update` | Editar campo local |
| `local_fields:delete` | Eliminar campo local |
| `churches:read` | Ver iglesias |
| `churches:create` | Crear iglesia |
| `churches:update` | Editar iglesia |
| `churches:delete` | Eliminar iglesia |

### Catalogos de Referencia
| Permiso | Descripcion |
|---------|-------------|
| `catalogs:read` | Ver catalogos |
| `catalogs:create` | Crear item de catalogo |
| `catalogs:update` | Editar item de catalogo |
| `catalogs:delete` | Eliminar item de catalogo |

### Clases y Honores
| Permiso | Descripcion |
|---------|-------------|
| `classes:read` | Ver clases progresivas |
| `classes:create` | Crear clase |
| `classes:update` | Editar clase |
| `classes:delete` | Eliminar clase |
| `honors:read` | Ver honores/especialidades |
| `honors:create` | Crear honor |
| `honors:update` | Editar honor |
| `honors:delete` | Eliminar honor |
| `honor_categories:read` | Ver categorias de honores |
| `honor_categories:create` | Crear categoria |
| `honor_categories:update` | Editar categoria |
| `honor_categories:delete` | Eliminar categoria |

### Actividades
| Permiso | Descripcion |
|---------|-------------|
| `activities:read` | Ver actividades |
| `activities:create` | Crear actividad |
| `activities:update` | Editar actividad |
| `activities:delete` | Eliminar actividad |
| `attendance:read` | Ver asistencia |
| `attendance:manage` | Registrar/modificar asistencia |

### Finanzas
| Permiso | Descripcion |
|---------|-------------|
| `finances:read` | Ver finanzas |
| `finances:create` | Crear registro financiero |
| `finances:update` | Editar registro financiero |
| `finances:delete` | Eliminar registro financiero |
| `finances:export` | Exportar datos financieros |

### Inventario
| Permiso | Descripcion |
|---------|-------------|
| `inventory:read` | Ver inventario |
| `inventory:create` | Crear item |
| `inventory:update` | Editar item |
| `inventory:delete` | Eliminar item |

### Notificaciones
| Permiso | Descripcion |
|---------|-------------|
| `notifications:send` | Enviar notificacion directa |
| `notifications:broadcast` | Enviar notificacion masiva |
| `notifications:club` | Enviar notificacion a miembros de club |

### Reportes y Dashboard
| Permiso | Descripcion |
|---------|-------------|
| `reports:view` | Ver reportes generales |
| `reports:export` | Exportar reportes |
| `dashboard:view` | Ver dashboard |

### Sistema
| Permiso | Descripcion |
|---------|-------------|
| `settings:read` | Ver configuracion del sistema |
| `settings:update` | Modificar configuracion |
| `ecclesiastical_years:read` | Ver anos eclesiasticos |
| `ecclesiastical_years:create` | Crear ano eclesiastico |
| `ecclesiastical_years:update` | Editar ano eclesiastico |

## Consumo por Cliente

### `sacdia-admin`

- Usa `authorization.effective.permissions` para habilitar paginas, acciones y mutaciones.
- Usa `authorization.grants` para matrices de roles y selectores de contexto.
- No debe reconstruir autorizacion desde joins locales o estructuras legacy.

### `sacdia-app`

- Usa `authorization.effective.permissions` para habilitar acciones.
- Usa `authorization.effective.scope.club` como contexto activo.
- Usa `authorization.grants.club_assignments` para selector de contexto.
- No debe tomar decisiones RBAC de club desde `metadata.roles` o `metadata.club`.

## Compatibilidad Legacy (Temporal)

Los campos legacy siguen disponibles de forma transitoria:

- `roles`
- `permissions`
- `club`
- `club_context`

Regla:

- siguen vivos solo durante migracion de clientes;
- no son contrato oficial para nuevas integraciones.

## Referencias Relacionadas

- `docs/features/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
- `docs/database/migrations/script_06_admin_permissions.sql`

**Ultima actualizacion**: 2026-03-10 (familias sensibles + fallback transicional)
