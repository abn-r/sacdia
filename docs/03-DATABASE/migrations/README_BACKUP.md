# Guía de Backup - Por Tabla Individual

## Tablas que necesitan respaldo:

✅ **Con Datos** (respaldar):
- countries: 37 registros
- unions: 24
- local_fields: 11  
- districts: 20
- churches: 1
- club_types: 3
- classes: 15
- honors_categories: 9
- master_honors: 18
- honors: 693 ⚠️ (GRANDE)
- allergies: 106
- diseases: 98
- relationship_type: 30
- finances_categories: 20
- permissions: 251 ⚠️ (GRANDE)
- roles: 19
- role_permissions: 94

❌ **Vacías** (omitir):
- class_modules
- class_sections
- medicines

## Instrucciones

Para CADA tabla, ejecuta el script correspondiente abajo en Supabase SQL Editor:

1. Copia el script de la tabla
2. Pégalo en Supabase SQL Editor  
3. Ejecuta (Run)
4. Copia TODO el resultado (columna backup_sql)
5. Pégalo en un archivo .sql con el nombre de la tabla

---

## Scripts Individuales por Tabla

### 1. Countries (37 registros)

```sql
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
```

### 2. Unions (24 registros)

```sql
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
```

### 3. Local Fields (11 registros) ✅ Ya lo tienes

### 4. Districts (20 registros) ✅ Ya lo tienes

### 5. Churches (1 registro)

```sql
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
```

### 6. Club Types (3 registros)

```sql
SELECT 'INSERT INTO club_types (ct_id, name, active, created_at, modified_at) VALUES (' ||
  ct_id || ', ' ||
  quote_literal(name) || ', ' ||
  active || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz' ||
  ') ON CONFLICT (ct_id) DO NOTHING;' as backup_sql
FROM club_types
ORDER BY ct_id;
```

### 7. Classes (15 registros)

```sql
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
```

### 8. Honors Categories (9 registros)

```sql
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
```

### 9. Master Honors (18 registros)

```sql
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
```

### 10. Honors (693 registros) ⚠️ GRANDE - Hazlo en 2 partes

**Parte 1** (primeros 350):
```sql
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
WHERE honor_id <= 350
ORDER BY honor_id;
```

**Parte 2** (restantes):
```sql
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
WHERE honor_id > 350
ORDER BY honor_id;
```

### 11. Allergies (106 registros)

```sql
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
```

### 12. Diseases (98 registros)

```sql
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
```

### 13. Relationship Type (30 registros)

```sql
SELECT 'INSERT INTO relationship_type (relationship_type_id, name, active, created_at, modified_at) VALUES (' ||
  relationship_type_id || ', ' ||
  COALESCE(quote_literal(name), 'NULL') || ', ' ||
  COALESCE(active::text, 'true') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  COALESCE(quote_literal(modified_at::text) || '::timestamptz', 'NULL') ||
  ') ON CONFLICT (relationship_type_id) DO NOTHING;' as backup_sql
FROM relationship_type
ORDER BY relationship_type_id;
```

### 14. Finances Categories (20 registros)

```sql
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
```

### 15. Permissions (251 registros) ⚠️ GRANDE - Hazlo en 2 partes

**Parte 1**:
```sql
SELECT 'INSERT INTO permissions (permission_id, permission_name, description, created_at, modified_at, active) VALUES (' ||
  quote_literal(permission_id::text) || '::uuid, ' ||
  quote_literal(permission_name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active ||
  ') ON CONFLICT (permission_id) DO NOTHING;' as backup_sql
FROM permissions
ORDER BY permission_name
LIMIT 130;
```

**Parte 2**:
```sql
SELECT 'INSERT INTO permissions (permission_id, permission_name, description, created_at, modified_at, active) VALUES (' ||
  quote_literal(permission_id::text) || '::uuid, ' ||
  quote_literal(permission_name) || ', ' ||
  COALESCE(quote_literal(description), 'NULL') || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active ||
  ') ON CONFLICT (permission_id) DO NOTHING;' as backup_sql
FROM permissions
ORDER BY permission_name
OFFSET 130;
```

### 16. Roles (19 registros)

```sql
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
```

### 17. Role Permissions (94 registros)

```sql
SELECT 'INSERT INTO role_permissions (role_permission_id, role_id, permission_id, created_at, modified_at, active) VALUES (' ||
  quote_literal(role_permission_id::text) || '::uuid, ' ||
  quote_literal(role_id::text) || '::uuid, ' ||
  quote_literal(permission_id::text) || '::uuid, ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(modified_at::text) || '::timestamptz, ' ||
  active ||
  ') ON CONFLICT (role_permission_id) DO NOTHING;' as backup_sql
FROM role_permissions;
```

---

## Sequences Reset (ejecutar al final de la restauración)

```sql
SELECT setval('countries_country_id_seq', (SELECT MAX(country_id) FROM countries));
SELECT setval('unions_union_id_seq', (SELECT MAX(union_id) FROM unions));
SELECT setval('local_fields_local_field_id_seq', (SELECT MAX(local_field_id) FROM local_fields));
SELECT setval('districts_district_id_seq', (SELECT MAX(district_id) FROM districts));
SELECT setval('churches_church_id_seq', (SELECT MAX(church_id) FROM churches));
SELECT setval('club_types_ct_id_seq', (SELECT MAX(ct_id) FROM club_types));
SELECT setval('classes_class_id_seq', (SELECT MAX(class_id) FROM classes));
SELECT setval('honors_categories_honor_category_id_seq', (SELECT MAX(honor_category_id) FROM honors_categories));
SELECT setval('master_honors_master_honor_id_seq', (SELECT MAX(master_honor_id) FROM master_honors));
SELECT setval('honors_honor_id_seq', (SELECT MAX(honor_id) FROM honors));
SELECT setval('allergies_allergy_id_seq', (SELECT MAX(allergy_id) FROM allergies));
SELECT setval('diseases_disease_id_seq', (SELECT MAX(disease_id) FROM diseases));
SELECT setval('relationship_type_relationship_type_id_seq', (SELECT MAX(relationship_type_id) FROM relationship_type));
SELECT setval('finances_categories_finance_category_id_seq', (SELECT MAX(finance_category_id) FROM finances_categories));
```

---

## Orden de Restauración (después del reset)

1. countries
2. unions  
3. local_fields
4. districts
5. churches
6. club_types
7. classes
8. honors_categories
9. master_honors
10. honors (parte 1 + parte 2)
11. allergies
12. diseases
13. relationship_type
14. finances_categories
15. permissions (parte 1 + parte 2)
16. roles
17. role_permissions
18. sequences (el script de arriba)

**Total archivos de backup**: ~20 archivos .sql
