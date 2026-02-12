-- ============================================================================
-- SCRIPT 06: PERMISOS DEL ADMIN PANEL - SACDIA
-- ============================================================================
-- Fecha: 2026-02-09
-- Descripción: Inserta los permisos con formato resource:action y los asigna
--              a los roles admin y super_admin.
--
-- Convención: resource:action (lowercase, colon separator)
--   - resource: snake_case, sustantivo plural
--   - action: read, create, update, delete, assign, revoke, export, manage, view
--
-- Dependencias: script_05_roles_permisos.sql (roles deben existir)
-- Re-ejecución: Seguro (usa ON CONFLICT DO NOTHING)
-- ============================================================================

BEGIN;

-- ============================================================================
-- PASO 1: Insertar todos los permisos en la tabla permissions
-- ============================================================================

INSERT INTO permissions (permission_name, description) VALUES
  -- Gestión de Usuarios
  ('users:read',              'Ver listado de usuarios'),
  ('users:read_detail',       'Ver detalle/perfil de un usuario'),
  ('users:create',            'Crear usuario manualmente'),
  ('users:update',            'Editar datos de usuario'),
  ('users:delete',            'Desactivar/eliminar usuario'),
  ('users:export',            'Exportar listado de usuarios'),

  -- Roles y Permisos
  ('roles:read',              'Ver roles del sistema'),
  ('roles:create',            'Crear roles'),
  ('roles:update',            'Editar roles'),
  ('roles:delete',            'Eliminar roles'),
  ('roles:assign',            'Asignar roles globales a usuarios'),
  ('permissions:read',        'Ver permisos del sistema'),
  ('permissions:assign',      'Asignar permisos a roles'),

  -- Clubes
  ('clubs:read',              'Ver clubes'),
  ('clubs:create',            'Crear club'),
  ('clubs:update',            'Editar club'),
  ('clubs:delete',            'Desactivar club'),
  ('club_instances:read',     'Ver instancias de club (Aventureros, Conquistadores, GM)'),
  ('club_instances:create',   'Crear instancia de club'),
  ('club_instances:update',   'Editar instancia de club'),
  ('club_instances:delete',   'Desactivar instancia de club'),
  ('club_roles:read',         'Ver asignaciones de rol de club'),
  ('club_roles:assign',       'Asignar rol de club a usuario'),
  ('club_roles:revoke',       'Revocar rol de club'),

  -- Jerarquía Geográfica
  ('countries:read',          'Ver países'),
  ('countries:create',        'Crear país'),
  ('countries:update',        'Editar país'),
  ('countries:delete',        'Eliminar país'),
  ('unions:read',             'Ver uniones'),
  ('unions:create',           'Crear unión'),
  ('unions:update',           'Editar unión'),
  ('unions:delete',           'Eliminar unión'),
  ('local_fields:read',       'Ver campos locales'),
  ('local_fields:create',     'Crear campo local'),
  ('local_fields:update',     'Editar campo local'),
  ('local_fields:delete',     'Eliminar campo local'),
  ('churches:read',           'Ver iglesias'),
  ('churches:create',         'Crear iglesia'),
  ('churches:update',         'Editar iglesia'),
  ('churches:delete',         'Eliminar iglesia'),

  -- Catálogos de Referencia
  ('catalogs:read',           'Ver catálogos (alergias, enfermedades, tipos, etc.)'),
  ('catalogs:create',         'Crear ítem de catálogo'),
  ('catalogs:update',         'Editar ítem de catálogo'),
  ('catalogs:delete',         'Eliminar ítem de catálogo'),

  -- Clases y Honores
  ('classes:read',            'Ver clases progresivas'),
  ('classes:create',          'Crear clase progresiva'),
  ('classes:update',          'Editar clase progresiva'),
  ('classes:delete',          'Eliminar clase progresiva'),
  ('honors:read',             'Ver honores/especialidades'),
  ('honors:create',           'Crear honor'),
  ('honors:update',           'Editar honor'),
  ('honors:delete',           'Eliminar honor'),
  ('honor_categories:read',   'Ver categorías de honores'),
  ('honor_categories:create', 'Crear categoría de honor'),
  ('honor_categories:update', 'Editar categoría de honor'),
  ('honor_categories:delete', 'Eliminar categoría de honor'),

  -- Actividades
  ('activities:read',         'Ver actividades'),
  ('activities:create',       'Crear actividad'),
  ('activities:update',       'Editar actividad'),
  ('activities:delete',       'Eliminar actividad'),
  ('attendance:read',         'Ver asistencia'),
  ('attendance:manage',       'Registrar/modificar asistencia'),

  -- Finanzas
  ('finances:read',           'Ver finanzas'),
  ('finances:create',         'Crear registro financiero'),
  ('finances:update',         'Editar registro financiero'),
  ('finances:delete',         'Eliminar registro financiero'),
  ('finances:export',         'Exportar datos financieros'),

  -- Inventario
  ('inventory:read',          'Ver inventario'),
  ('inventory:create',        'Crear ítem de inventario'),
  ('inventory:update',        'Editar ítem de inventario'),
  ('inventory:delete',        'Eliminar ítem de inventario'),

  -- Reportes y Dashboard
  ('reports:view',            'Ver reportes generales'),
  ('reports:export',          'Exportar reportes'),
  ('dashboard:view',          'Ver dashboard'),

  -- Sistema
  ('settings:read',           'Ver configuración del sistema'),
  ('settings:update',         'Modificar configuración del sistema'),
  ('ecclesiastical_years:read',   'Ver años eclesiásticos'),
  ('ecclesiastical_years:create', 'Crear año eclesiástico'),
  ('ecclesiastical_years:update', 'Editar año eclesiástico')

ON CONFLICT (permission_name) DO NOTHING;

-- ============================================================================
-- PASO 2: Asignar TODOS los permisos al rol super_admin
-- ============================================================================
-- Nota: El frontend ya hace bypass para super_admin en el hook usePermissions(),
-- pero tenerlos en DB garantiza consistencia si el backend también valida por DB.
-- ============================================================================

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'super_admin'
  AND p.permission_name LIKE '%:%'
  AND p.active = true
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- PASO 3: Asignar permisos al rol admin
-- ============================================================================
-- El admin tiene acceso a casi todo excepto gestión de roles/permisos y sistema.
-- ============================================================================

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'admin'
  AND p.active = true
  AND p.permission_name IN (
    -- Usuarios (lectura y edición, sin eliminar)
    'users:read',
    'users:read_detail',
    'users:update',
    'users:export',

    -- Roles (solo lectura y asignación)
    'roles:read',
    'roles:assign',
    'permissions:read',

    -- Clubes (CRUD completo)
    'clubs:read',
    'clubs:create',
    'clubs:update',
    'clubs:delete',
    'club_instances:read',
    'club_instances:create',
    'club_instances:update',
    'club_instances:delete',
    'club_roles:read',
    'club_roles:assign',
    'club_roles:revoke',

    -- Jerarquía Geográfica (CRUD completo)
    'countries:read',
    'countries:create',
    'countries:update',
    'countries:delete',
    'unions:read',
    'unions:create',
    'unions:update',
    'unions:delete',
    'local_fields:read',
    'local_fields:create',
    'local_fields:update',
    'local_fields:delete',
    'churches:read',
    'churches:create',
    'churches:update',
    'churches:delete',

    -- Catálogos (CRUD completo)
    'catalogs:read',
    'catalogs:create',
    'catalogs:update',
    'catalogs:delete',

    -- Clases y Honores (CRUD completo)
    'classes:read',
    'classes:create',
    'classes:update',
    'classes:delete',
    'honors:read',
    'honors:create',
    'honors:update',
    'honors:delete',
    'honor_categories:read',
    'honor_categories:create',
    'honor_categories:update',
    'honor_categories:delete',

    -- Actividades (CRUD completo)
    'activities:read',
    'activities:create',
    'activities:update',
    'activities:delete',
    'attendance:read',
    'attendance:manage',

    -- Finanzas (CRUD completo)
    'finances:read',
    'finances:create',
    'finances:update',
    'finances:delete',
    'finances:export',

    -- Inventario (CRUD completo)
    'inventory:read',
    'inventory:create',
    'inventory:update',
    'inventory:delete',

    -- Reportes (solo lectura y exportar)
    'reports:view',
    'reports:export',
    'dashboard:view',

    -- Sistema (solo lectura)
    'settings:read',
    'ecclesiastical_years:read'
  )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- PASO 4: Asignar permisos al rol coordinator
-- ============================================================================
-- Coordinador: lectura general + gestión de clubes y miembros de su zona.
-- ============================================================================

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'coordinator'
  AND p.active = true
  AND p.permission_name IN (
    -- Usuarios (solo lectura)
    'users:read',
    'users:read_detail',

    -- Roles (solo lectura)
    'roles:read',

    -- Clubes (lectura + asignación de roles)
    'clubs:read',
    'club_instances:read',
    'club_roles:read',
    'club_roles:assign',
    'club_roles:revoke',

    -- Jerarquía Geográfica (solo lectura)
    'countries:read',
    'unions:read',
    'local_fields:read',
    'churches:read',

    -- Catálogos (solo lectura)
    'catalogs:read',

    -- Clases y Honores (solo lectura)
    'classes:read',
    'honors:read',
    'honor_categories:read',

    -- Actividades (lectura)
    'activities:read',
    'attendance:read',

    -- Reportes (solo lectura)
    'reports:view',
    'dashboard:view'
  )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

DO $$
DECLARE
  v_total_permissions INT;
  v_super_admin_perms INT;
  v_admin_perms INT;
  v_coordinator_perms INT;
BEGIN
  SELECT COUNT(*) INTO v_total_permissions
  FROM permissions WHERE permission_name LIKE '%:%';

  SELECT COUNT(*) INTO v_super_admin_perms
  FROM role_permissions rp
  JOIN roles r ON r.role_id = rp.role_id
  WHERE r.role_name = 'super_admin';

  SELECT COUNT(*) INTO v_admin_perms
  FROM role_permissions rp
  JOIN roles r ON r.role_id = rp.role_id
  WHERE r.role_name = 'admin';

  SELECT COUNT(*) INTO v_coordinator_perms
  FROM role_permissions rp
  JOIN roles r ON r.role_id = rp.role_id
  WHERE r.role_name = 'coordinator';

  RAISE NOTICE '════════════════════════════════════════════';
  RAISE NOTICE '✅ Permisos insertados: %', v_total_permissions;
  RAISE NOTICE '🔑 super_admin: % permisos', v_super_admin_perms;
  RAISE NOTICE '🛡️  admin: % permisos', v_admin_perms;
  RAISE NOTICE '📋 coordinator: % permisos', v_coordinator_perms;
  RAISE NOTICE '════════════════════════════════════════════';
END $$;

COMMIT;
