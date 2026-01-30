-- ============================================================================
-- BACKUP SCRIPT 5: ROLES Y PERMISOS (VERSIÓN ULTRA SIMPLE)
-- ============================================================================

-- Permissions
SELECT 'INSERT INTO permissions (permission_id, permission_name, description, created_at, modified_at, active) VALUES (' ||
  quote_literal(permission_id::text) || '::uuid, ' ||
  quote_literal(permission_name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active ||
  ') ON CONFLICT (permission_id) DO NOTHING;' as backup_sql
FROM permissions
ORDER BY permission_name;

-- Roles
SELECT 'INSERT INTO roles (role_id, role_name, created_at, modified_at, active, role_category) VALUES (' ||
  quote_literal(role_id::text) || '::uuid, ' ||
  quote_literal(role_name) || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active || ', ' ||
  quote_literal(role_category::text) || '::role_category' ||
  ') ON CONFLICT (role_id) DO NOTHING;' as backup_sql
FROM roles
ORDER BY role_name;

-- Role Permissions
SELECT 'INSERT INTO role_permissions (role_permission_id,role_id, permission_id, created_at, modified_at, active) VALUES (' ||
  quote_literal(role_permission_id::text) || '::uuid, ' ||
  quote_literal(role_id::text) || '::uuid, ' ||
  quote_literal(permission_id::text) || '::uuid, ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active ||
  ') ON CONFLICT (role_permission_id) DO NOTHING;' as backup_sql
FROM role_permissions;
