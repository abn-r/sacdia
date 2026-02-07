-- ============================================================================
-- BACKUP SCRIPT 4: CATÁLOGOS MÉDICOS Y OTROS (VERSIÓN ULTRA SIMPLE)
-- ============================================================================

-- Allergies
SELECT 'INSERT INTO allergies (allergy_id, name, description, created_at, modified_at, active) VALUES (' ||
  allergy_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active ||
  ') ON CONFLICT (allergy_id) DO NOTHING;' as backup_sql
FROM allergies
ORDER BY allergy_id;

-- Diseases
SELECT 'INSERT INTO diseases (disease_id, name, description, created_at, modified_at, active) VALUES (' ||
  disease_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active ||
  ') ON CONFLICT (disease_id) DO NOTHING;' as backup_sql
FROM diseases
ORDER BY disease_id;

-- Medicines
SELECT 'INSERT INTO medicines (medicine_id, name, description, active, created_at, modified_at) VALUES (' ||
  medicine_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  COALESCE(active::text, 'true') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  COALESCE(quote_literal(modified_at::text) || '::timestamptz', 'NULL') ||
  ') ON CONFLICT (medicine_id) DO NOTHING;' as backup_sql
FROM medicines
ORDER BY medicine_id;

-- Relationship Types
SELECT 'INSERT INTO relationship_type (relationship_type_id, name, active, created_at, modified_at) VALUES (' ||
  relationship_type_id || ', ' ||
  COALESCE(quote_literal(name), 'NULL') || ', ' ||
  COALESCE(active::text, 'true') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  COALESCE(quote_literal(modified_at::text) || '::timestamptz', 'NULL') ||
  ') ON CONFLICT (relationship_type_id) DO NOTHING;' as backup_sql
FROM relationship_type
ORDER BY relationship_type_id;

-- Finances Categories
SELECT 'INSERT INTO finances_categories (finance_category_id, name, description, icon, type, active, created_at, modified_at) VALUES (' ||
  finance_category_id || ', ' ||
  quote_literal(name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  COALESCE(icon::text, '0') || ', ' ||
  type || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (finance_category_id) DO NOTHING;' as backup_sql
FROM finances_categories
ORDER BY finance_category_id;

-- Sequences
SELECT 'SELECT setval(''allergies_allergy_id_seq'', (SELECT MAX(allergy_id) FROM allergies));' as backup_sql
UNION ALL
SELECT 'SELECT setval(''diseases_disease_id_seq'', (SELECT MAX(disease_id) FROM diseases));'
UNION ALL
SELECT 'SELECT setval(''medicines_medicine_id_seq'', (SELECT MAX(medicine_id) FROM medicines));'
UNION ALL
SELECT 'SELECT setval(''relationship_type_relationship_type_id_seq'', (SELECT MAX(relationship_type_id) FROM relationship_type));'
UNION ALL
SELECT 'SELECT setval(''finances_categories_finance_category_id_seq'', (SELECT MAX(finance_category_id) FROM finances_categories));';
