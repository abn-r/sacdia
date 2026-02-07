-- ============================================================================
-- BACKUP SCRIPT 1: JERARQUÍA ORGANIZACIONAL (VERSIÓN ULTRA SIMPLE)
-- ============================================================================
-- INSTRUCCIONES:
-- 1. Ejecuta este script en Supabase SQL Editor
-- 2. Copia TODO el output (verás múltiples filas con INSERTs)
-- 3. Guárdalo en: backup_01_organizacion.sql
-- ============================================================================

-- Countries
SELECT 'INSERT INTO countries (country_id, name, abbreviation, active, created_at, modified_at) VALUES (' ||
  country_id || ', ' ||
  quote_literal(name) || ', ' ||
  quote_literal(abbreviation) || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (country_id) DO NOTHING;' as backup_sql
FROM countries
ORDER BY country_id;

-- Unions
SELECT 'INSERT INTO unions (union_id, name, abbreviation, active, country_id, created_at, modified_at) VALUES (' ||
  union_id || ', ' ||
  quote_literal(name) || ', ' ||
  quote_literal(abbreviation) || ', ' ||
  active || ', ' ||
  country_id || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (union_id) DO NOTHING;' as backup_sql
FROM unions
ORDER BY union_id;

-- Local Fields
SELECT 'INSERT INTO local_fields (local_field_id, name, abbreviation, active, union_id, created_at, modified_at) VALUES (' ||
  local_field_id || ', ' ||
  quote_literal(name) || ', ' ||
  quote_literal(abbreviation) || ', ' ||
  active || ', ' ||
  union_id || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (local_field_id) DO NOTHING;' as backup_sql
FROM local_fields
ORDER BY local_field_id;

-- Districts
SELECT 'INSERT INTO districts (district_id, name, active, local_field_id, created_at, modified_at) VALUES (' ||
  district_id || ', ' ||
  quote_literal(name) || ', ' ||
  active || ', ' ||
  local_field_id || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (district_id) DO NOTHING;' as backup_sql
FROM districts
ORDER BY district_id;

-- Churches
SELECT 'INSERT INTO churches (church_id, name, active, district_id, created_at, modified_at) VALUES (' ||
  church_id || ', ' ||
  quote_literal(name) || ', ' ||
  active || ', ' ||
  district_id || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (church_id) DO NOTHING;' as backup_sql
FROM churches
ORDER BY church_id;

-- Sequence resets
SELECT 'SELECT setval(''countries_country_id_seq'', (SELECT MAX(country_id) FROM countries));' as backup_sql
UNION ALL
SELECT 'SELECT setval(''unions_union_id_seq'', (SELECT MAX(union_id) FROM unions));'
UNION ALL
SELECT 'SELECT setval(''local_fields_local_field_id_seq'', (SELECT MAX(local_field_id) FROM local_fields));'
UNION ALL
SELECT 'SELECT setval(''districts_district_id_seq'', (SELECT MAX(district_id) FROM districts));'
UNION ALL
SELECT 'SELECT setval(''churches_church_id_seq'', (SELECT MAX(church_id) FROM churches));';
