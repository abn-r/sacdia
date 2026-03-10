# Sistema de Permisos - SACDIA

**Status**: ACTIVE  
**Fecha**: 2026-03-08

> [!IMPORTANT]
> Este documento es el catálogo canónico de nombres de permisos y su convención.
> La semántica de autorización y enforcement vive en:
> - `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
> - `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
> - `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`

## Resumen Ejecutivo

SACDIA usa RBAC con permisos granulares.

- Los permisos se almacenan en la tabla `permissions`.
- El backend resuelve autorización por sesión en el bloque `authorization`.
- Los clientes consumen `authorization.effective.permissions` para gating de UX.

## Modelo Vigente de Autorización

### Fuente oficial por sesión

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

## Convención de Nomenclatura

### Formato: `resource:action`

```
{resource}:{action}
```

| Componente | Reglas | Ejemplos |
|------------|--------|----------|
| `resource` | snake_case, sustantivo plural | `users`, `club_instances`, `local_fields` |
| `action` | snake_case, verbo | `read`, `create`, `update`, `delete` |
| Separador | `:` | `users:create`, `clubs:read` |

### Acciones estándar

| Acción | Descripción |
|--------|-------------|
| `read` | Ver listado de recursos |
| `read_detail` | Ver detalle de un recurso específico |
| `create` | Crear nuevo recurso |
| `update` | Editar recurso existente |
| `delete` | Eliminar/desactivar recurso |
| `export` | Exportar datos |
| `assign` | Asignar relación |
| `revoke` | Revocar relación |
| `manage` | Gestionar (agrupa acciones) |
| `view` | Visualización sin CRUD |

## Catálogo de Permisos por Módulo

> [!NOTE]
> El catálogo incluye permisos existentes de negocio.
> El nivel exacto de enforcement por endpoint se valida en `RBAC-ENFORCEMENT-MATRIX.md`.

### Usuarios
| Permiso | Descripción |
|---------|-------------|
| `users:read` | Ver listado de usuarios |
| `users:read_detail` | Ver detalle/perfil de un usuario |
| `users:create` | Crear usuario manualmente |
| `users:update` | Editar datos de usuario |
| `users:delete` | Desactivar/eliminar usuario |
| `users:export` | Exportar listado de usuarios |

Notas canónicas del modelo vigente:

- sub-recursos sensibles (`allergies`, `diseases`, `emergency-contacts`, `legal-representative`, `post-registration`, `profile-picture`) NO tienen permisos dedicados hoy;
- runtime reutiliza `users:read_detail` para lecturas y `users:update` para escrituras junto con ownership sobre `userId`;
- GAP FORMAL: el catálogo actual no permite tiering fino entre perfil general, salud, datos legales y progreso de post-registro;
- opción C cerrada: post-registro sigue administrable por actores con permiso global `users:read_detail`/`users:update`, pero terceros quedan limitados a lectura y completion administrativos mínimos sin feedback sensible adicional.

### Roles y Permisos
| Permiso | Descripción |
|---------|-------------|
| `roles:read` | Ver roles |
| `roles:create` | Crear roles |
| `roles:update` | Editar roles |
| `roles:delete` | Eliminar roles |
| `roles:assign` | Asignar roles globales a usuarios |
| `permissions:read` | Ver permisos |
| `permissions:assign` | Asignar permisos a roles |

### Clubes
| Permiso | Descripción |
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

### Jerarquía Geográfica
| Permiso | Descripción |
|---------|-------------|
| `countries:read` | Ver países |
| `countries:create` | Crear país |
| `countries:update` | Editar país |
| `countries:delete` | Eliminar país |
| `unions:read` | Ver uniones |
| `unions:create` | Crear unión |
| `unions:update` | Editar unión |
| `unions:delete` | Eliminar unión |
| `local_fields:read` | Ver campos locales |
| `local_fields:create` | Crear campo local |
| `local_fields:update` | Editar campo local |
| `local_fields:delete` | Eliminar campo local |
| `churches:read` | Ver iglesias |
| `churches:create` | Crear iglesia |
| `churches:update` | Editar iglesia |
| `churches:delete` | Eliminar iglesia |

### Catálogos de Referencia
| Permiso | Descripción |
|---------|-------------|
| `catalogs:read` | Ver catálogos |
| `catalogs:create` | Crear ítem de catálogo |
| `catalogs:update` | Editar ítem de catálogo |
| `catalogs:delete` | Eliminar ítem de catálogo |

### Clases y Honores
| Permiso | Descripción |
|---------|-------------|
| `classes:read` | Ver clases progresivas |
| `classes:create` | Crear clase |
| `classes:update` | Editar clase |
| `classes:delete` | Eliminar clase |
| `honors:read` | Ver honores/especialidades |
| `honors:create` | Crear honor |
| `honors:update` | Editar honor |
| `honors:delete` | Eliminar honor |
| `honor_categories:read` | Ver categorías de honores |
| `honor_categories:create` | Crear categoría |
| `honor_categories:update` | Editar categoría |
| `honor_categories:delete` | Eliminar categoría |

### Actividades
| Permiso | Descripción |
|---------|-------------|
| `activities:read` | Ver actividades |
| `activities:create` | Crear actividad |
| `activities:update` | Editar actividad |
| `activities:delete` | Eliminar actividad |
| `attendance:read` | Ver asistencia |
| `attendance:manage` | Registrar/modificar asistencia |

### Finanzas
| Permiso | Descripción |
|---------|-------------|
| `finances:read` | Ver finanzas |
| `finances:create` | Crear registro financiero |
| `finances:update` | Editar registro financiero |
| `finances:delete` | Eliminar registro financiero |
| `finances:export` | Exportar datos financieros |

### Inventario
| Permiso | Descripción |
|---------|-------------|
| `inventory:read` | Ver inventario |
| `inventory:create` | Crear ítem |
| `inventory:update` | Editar ítem |
| `inventory:delete` | Eliminar ítem |

### Notificaciones
| Permiso | Descripción |
|---------|-------------|
| `notifications:send` | Enviar notificación directa |
| `notifications:broadcast` | Enviar notificación masiva |
| `notifications:club` | Enviar notificación a miembros de club |

### Reportes y Dashboard
| Permiso | Descripción |
|---------|-------------|
| `reports:view` | Ver reportes generales |
| `reports:export` | Exportar reportes |
| `dashboard:view` | Ver dashboard |

### Sistema
| Permiso | Descripción |
|---------|-------------|
| `settings:read` | Ver configuración del sistema |
| `settings:update` | Modificar configuración |
| `ecclesiastical_years:read` | Ver años eclesiásticos |
| `ecclesiastical_years:create` | Crear año eclesiástico |
| `ecclesiastical_years:update` | Editar año eclesiástico |

## Consumo por Cliente

### `sacdia-admin`

- Usa `authorization.effective.permissions` para habilitar páginas, acciones y mutaciones.
- Usa `authorization.grants` para matrices de roles y selectores de contexto.
- No debe reconstruir autorización desde joins locales o estructuras legacy.

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

- siguen vivos solo durante migración de clientes;
- no son contrato oficial para nuevas integraciones.

## Referencias Relacionadas

- `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
- `docs/03-DATABASE/migrations/script_06_admin_permissions.sql`

**Última actualización**: 2026-03-08 (alineación canónica RBAC)
