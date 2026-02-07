-- ============================================================================
-- BACKUP SCRIPT 3: ESPECIALIDADES (VERSIÓN ULTRA SIMPLE)
-- ============================================================================

-- Honors Categories
SELECT 'INSERT INTO honors_categories (honor_category_id, name, description, icon, active, created_at, modified_at) VALUES (' ||
  honor_category_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  icon || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (honor_category_id) DO NOTHING;' as backup_sql
FROM honors_categories
ORDER BY honor_category_id;

-- Master Honors
SELECT 'INSERT INTO master_honors (master_honor_id, name, master_image, active, created_at, modified_at) VALUES (' ||
  master_honor_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(master_image), 'NULL') || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (master_honor_id) DO NOTHING;' as backup_sql
FROM master_honors
ORDER BY master_honor_id;

-- Honors (CUIDADO: Esta tabla puede tener CIENTOS de registros)
SELECT 'INSERT INTO honors (honor_id, name, description, honor_image, honors_category_id, master_honors_id, material_url, club_type_id, active, approval, skill_level, year, created_at, modified_at) VALUES (' ||
  honor_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  quote_literal(honor_image) || ', ' ||
  honors_category_id || ', ' ||
  COALESCE(master_honors_id::text, 'NULL') || ', ' ||
  quote_literal(material_url) || ', ' ||
  club_type_id || ', ' ||
  active || ', ' ||
  approval || ', ' ||
  skill_level || ', ' ||
  COALESCE(quote_literal(year), 'NULL') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  COALESCE(quote_literal(modified_at::text) || '::timestamptz', 'NULL') ||
  ') ON CONFLICT (honor_id) DO NOTHING;' as backup_sql
FROM honors
ORDER BY honor_id;

-- Sequences
SELECT 'SELECT setval(''honors_categories_honor_category_id_seq'', (SELECT MAX(honor_category_id) FROM honors_categories));' as backup_sql
UNION ALL
SELECT 'SELECT setval(''master_honors_master_honor_id_seq'', (SELECT MAX(master_honor_id) FROM master_honors));'
UNION ALL
SELECT 'SELECT setval(''honors_honor_id_seq'', (SELECT MAX(honor_id) FROM honors));';
