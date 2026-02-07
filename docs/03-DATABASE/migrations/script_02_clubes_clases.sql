-- ============================================================================
-- BACKUP SCRIPT 2: CLUB TYPES Y CLASES (VERSIÓN ULTRA SIMPLE)
-- ============================================================================

-- Club Types
SELECT 'INSERT INTO club_types (ct_id, name, active, created_at, modified_at) VALUES (' ||
  ct_id || ', ' ||
  quote_literal(name) || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (ct_id) DO NOTHING;' as backup_sql
FROM club_types
ORDER BY ct_id;

-- Classes
SELECT 'INSERT INTO classes (class_id, name, description, active, club_type_id, minimum_age, created_at, modified_at, material_url) VALUES (' ||
  class_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  active || ', ' ||
  club_type_id || ', ' ||
  minimum_age || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  COALESCE(quote_literal(material_url), 'NULL') ||
  ') ON CONFLICT (class_id) DO NOTHING;' as backup_sql
FROM classes
ORDER BY class_id;

-- Class Modules
SELECT 'INSERT INTO class_modules (module_id, name, description, class_id, active, created_at, modified_at) VALUES (' ||
  module_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  class_id || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (module_id) DO NOTHING;' as backup_sql
FROM class_modules
ORDER BY module_id;

-- Class Sections
SELECT 'INSERT INTO class_sections (section_id, name, description, module_id, active, created_at, modified_at) VALUES (' ||
  section_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  module_id || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (section_id) DO NOTHING;' as backup_sql
FROM class_sections
ORDER BY section_id;

-- Club Ideals
SELECT 'INSERT INTO club_ideals (club_ideal_id, name, ideal_order, club_type_id, active, created_at, modified_at, ideal) VALUES (' ||
  club_ideal_id || ', ' ||
  quote_literal(name) || ', ' ||
  ideal_order || ', ' ||
  club_type_id || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  COALESCE(quote_literal(ideal), 'NULL') ||
  ') ON CONFLICT (club_ideal_id) DO NOTHING;' as backup_sql
FROM club_ideals
ORDER BY club_ideal_id;

-- Sequences
SELECT 'SELECT setval(''club_types_ct_id_seq'', (SELECT MAX(ct_id) FROM club_types));' as backup_sql
UNION ALL
SELECT 'SELECT setval(''classes_class_id_seq'', (SELECT MAX(class_id) FROM classes));'
UNION ALL
SELECT 'SELECT setval(''class_modules_module_id_seq'', (SELECT MAX(module_id) FROM class_modules));'
UNION ALL
SELECT 'SELECT setval(''class_sections_section_id_seq'', (SELECT MAX(section_id) FROM class_sections));'
UNION ALL
SELECT 'SELECT setval(''club_ideals_club_ideal_id_seq'', (SELECT MAX(club_ideal_id) FROM club_ideals));';
