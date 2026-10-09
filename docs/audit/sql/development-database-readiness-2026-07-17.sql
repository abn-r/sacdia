-- SACDIA development database readiness audit
-- Snapshot target: DATABASE_URL (credentials are intentionally not embedded).
-- Generated and executed on 2026-07-17 using read-only transactions.
-- Run from sacdia-backend with: psql "$DATABASE_URL" -X -f <this-file>

-- 1) Exact row counts for every public base table.
\pset format unaligned
\pset fieldsep '|'
\pset tuples_only on
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;
SELECT format(
  'SELECT %L AS table_name, count(*)::bigint AS exact_count FROM %I.%I;',
  table_name,
  table_schema,
  table_name
)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name
\gexec
ROLLBACK;

-- 2) Readiness, configuration, hierarchy, RBAC and operational checks.
\pset format unaligned
\pset fieldsep '|'
\pset tuples_only on
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;

\echo 'SECTION|DATABASE_SNAPSHOT'
SELECT 'snapshot', current_database(), current_setting('server_version'), current_setting('TimeZone'), now()::text;
SELECT 'migrations', count(*)::text,
       count(*) FILTER (WHERE finished_at IS NOT NULL)::text,
       count(*) FILTER (WHERE finished_at IS NULL AND rolled_back_at IS NULL)::text,
       max(finished_at)::text
FROM _prisma_migrations;
SELECT 'latest_migration', migration_name, finished_at::text, applied_steps_count::text
FROM _prisma_migrations
WHERE finished_at IS NOT NULL
ORDER BY finished_at DESC
LIMIT 1;

\echo 'SECTION|RBAC_SUMMARY'
SELECT 'permissions', count(*)::text,
       count(*) FILTER (WHERE active)::text,
       count(*) FILTER (WHERE NOT active)::text
FROM permissions;
SELECT 'roles', count(*)::text,
       count(*) FILTER (WHERE active)::text,
       count(*) FILTER (WHERE NOT active)::text,
       count(*) FILTER (WHERE role_category::text = 'GLOBAL')::text,
       count(*) FILTER (WHERE role_category::text = 'CLUB')::text
FROM roles;
SELECT 'role_permission_mappings', count(*)::text,
       count(*) FILTER (WHERE active)::text,
       count(*) FILTER (WHERE NOT active)::text
FROM role_permissions;
SELECT 'permissions_without_active_role', count(*)::text,
       coalesce(string_agg(permission_name, ', ' ORDER BY permission_name), '')
FROM permissions p
WHERE p.active
  AND NOT EXISTS (
    SELECT 1
    FROM role_permissions rp
    JOIN roles r ON r.role_id = rp.role_id
    WHERE rp.permission_id = p.permission_id
      AND rp.active
      AND r.active
  );

\echo 'SECTION|RBAC_ROLES'
SELECT 'role', r.role_name, r.role_category::text, r.active::text,
       count(rp.role_permission_id) FILTER (WHERE rp.active)::text,
       count(rp.role_permission_id) FILTER (WHERE NOT rp.active)::text,
       coalesce(rsl.max_per_section::text, '')
FROM roles r
LEFT JOIN role_permissions rp ON rp.role_id = r.role_id
LEFT JOIN role_slot_limits rsl ON rsl.role_id = r.role_id
GROUP BY r.role_id, r.role_name, r.role_category, r.active, rsl.max_per_section
ORDER BY r.role_category, r.role_name;

WITH expected(role_name, role_category) AS (
  VALUES
    ('user','GLOBAL'),('coordinator','GLOBAL'),('zone-coordinator','GLOBAL'),
    ('general-coordinator','GLOBAL'),('assistant-lf','GLOBAL'),('pastor','GLOBAL'),
    ('director-lf','GLOBAL'),('assistant-union','GLOBAL'),('director-union','GLOBAL'),
    ('assistant-dia','GLOBAL'),('director-dia','GLOBAL'),('admin','GLOBAL'),
    ('super-admin','GLOBAL'),
    ('member','CLUB'),('counselor','CLUB'),('instructor','CLUB'),
    ('secretary','CLUB'),('treasurer','CLUB'),('secretary-treasurer','CLUB'),
    ('deputy-director','CLUB'),('director','CLUB')
)
SELECT 'missing_expected_role', e.role_name, e.role_category
FROM expected e
LEFT JOIN roles r ON r.role_name = e.role_name AND r.role_category::text = e.role_category
WHERE r.role_id IS NULL
ORDER BY e.role_category, e.role_name;

WITH expected(role_name, role_category) AS (
  VALUES
    ('user','GLOBAL'),('coordinator','GLOBAL'),('zone-coordinator','GLOBAL'),
    ('general-coordinator','GLOBAL'),('assistant-lf','GLOBAL'),('pastor','GLOBAL'),
    ('director-lf','GLOBAL'),('assistant-union','GLOBAL'),('director-union','GLOBAL'),
    ('assistant-dia','GLOBAL'),('director-dia','GLOBAL'),('admin','GLOBAL'),
    ('super-admin','GLOBAL'),
    ('member','CLUB'),('counselor','CLUB'),('instructor','CLUB'),
    ('secretary','CLUB'),('treasurer','CLUB'),('secretary-treasurer','CLUB'),
    ('deputy-director','CLUB'),('director','CLUB')
)
SELECT 'unexpected_role', r.role_name, r.role_category::text
FROM roles r
LEFT JOIN expected e ON e.role_name = r.role_name AND e.role_category = r.role_category::text
WHERE e.role_name IS NULL
ORDER BY r.role_category, r.role_name;

SELECT 'assistant_admin_runtime_role',
       count(*)::text,
       count(*) FILTER (WHERE active)::text
FROM roles
WHERE role_name = 'assistant-admin';

SELECT 'super_admin_permission_coverage',
       count(*) FILTER (WHERE p.active)::text,
       count(*) FILTER (WHERE p.active AND rp.role_permission_id IS NOT NULL AND rp.active)::text,
       count(*) FILTER (WHERE p.active AND (rp.role_permission_id IS NULL OR NOT rp.active))::text
FROM permissions p
LEFT JOIN roles r ON r.role_name = 'super-admin' AND r.active
LEFT JOIN role_permissions rp ON rp.role_id = r.role_id AND rp.permission_id = p.permission_id;

SELECT 'admin_non_delete_permission_coverage',
       count(*) FILTER (WHERE p.active AND p.permission_name NOT LIKE '%:delete')::text,
       count(*) FILTER (WHERE p.active AND p.permission_name NOT LIKE '%:delete' AND rp.role_permission_id IS NOT NULL AND rp.active)::text,
       count(*) FILTER (WHERE p.active AND p.permission_name NOT LIKE '%:delete' AND (rp.role_permission_id IS NULL OR NOT rp.active))::text,
       count(*) FILTER (WHERE p.active AND p.permission_name LIKE '%:delete' AND rp.role_permission_id IS NOT NULL AND rp.active)::text
FROM permissions p
LEFT JOIN roles r ON r.role_name = 'admin' AND r.active
LEFT JOIN role_permissions rp ON rp.role_id = r.role_id AND rp.permission_id = p.permission_id;

\echo 'SECTION|ROLE_SLOT_LIMITS'
SELECT 'slot_limit', r.role_name, r.role_category::text, rsl.max_per_section::text
FROM role_slot_limits rsl
JOIN roles r ON r.role_id = rsl.role_id
ORDER BY r.role_name;

\echo 'SECTION|SYSTEM_CONFIG'
SELECT 'config', config_key, config_value, config_type, updated_at::text
FROM system_config
ORDER BY config_key;

WITH expected(config_key) AS (
  VALUES
    ('investiture.min_approval_percentage'),
    ('investiture.min_monthly_reports'),
    ('reports.auto_generate_day'),
    ('reports.auto_generate_enabled'),
    ('reports.reminders_enabled'),
    ('reports.quarterly_auto_generate_enabled'),
    ('reports.annual_auto_generate_enabled'),
    ('ranking.finance_closing_deadline_day'),
    ('ranking.recalculation_enabled'),
    ('ranking.activities_registered_target'),
    ('member_ranking.recalculation_enabled'),
    ('member_ranking.member_visibility'),
    ('member_ranking.top_n'),
    ('membership.pending_timeout_days'),
    ('notifications.category_settings'),
    ('scoring.category_max_points_cap')
)
SELECT 'missing_runtime_config', e.config_key
FROM expected e
LEFT JOIN system_config sc ON sc.config_key = e.config_key
WHERE sc.config_key IS NULL
ORDER BY e.config_key;

\echo 'SECTION|MASTER_CATALOG_SUMMARY'
SELECT 'catalog','club_types',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM club_types
UNION ALL SELECT 'catalog','classes',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM classes
UNION ALL SELECT 'catalog','class_modules',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM class_modules
UNION ALL SELECT 'catalog','class_sections',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM class_sections
UNION ALL SELECT 'catalog','relationship_types',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM relationship_types
UNION ALL SELECT 'catalog','activity_types',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM activity_types
UNION ALL SELECT 'catalog','finances_categories',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM finances_categories
UNION ALL SELECT 'catalog','inventory_categories',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM inventory_categories
UNION ALL SELECT 'catalog','allergies',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM allergies
UNION ALL SELECT 'catalog','diseases',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM diseases
UNION ALL SELECT 'catalog','medicines',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM medicines
UNION ALL SELECT 'catalog','honors_categories',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM honors_categories
UNION ALL SELECT 'catalog','honors',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM honors
UNION ALL SELECT 'catalog','honor_club_types',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM honor_club_types
UNION ALL SELECT 'catalog','honor_requirements',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM honor_requirements
UNION ALL SELECT 'catalog','master_honors',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM master_honors
UNION ALL SELECT 'catalog','camporee_event_types',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM camporee_event_types
UNION ALL SELECT 'catalog','material_categories',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM material_categories
UNION ALL SELECT 'catalog','club_ideals',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM club_ideals
UNION ALL SELECT 'catalog','award_categories',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM award_categories
ORDER BY 2;

\echo 'SECTION|CLUB_TYPES'
SELECT 'club_type', club_type_id::text, name, active::text FROM club_types ORDER BY club_type_id;

\echo 'SECTION|CLASS_CATALOG'
SELECT 'class', c.class_id::text, c.name, ct.name, c.active::text,
       c.minimum_age::text, c.display_order::text,
       count(DISTINCT cm.module_id)::text,
       count(DISTINCT cs.section_id)::text,
       count(DISTINCT cs.section_id) FILTER (WHERE cs.active)::text
FROM classes c
JOIN club_types ct ON ct.club_type_id = c.club_type_id
LEFT JOIN class_modules cm ON cm.class_id = c.class_id
LEFT JOIN class_sections cs ON cs.module_id = cm.module_id
GROUP BY c.class_id, c.name, ct.name, c.active, c.minimum_age, c.display_order
ORDER BY c.club_type_id, c.display_order, c.class_id;

SELECT 'class_catalog_inconsistency',
       count(*) FILTER (WHERE c.active AND NOT ct.active)::text,
       count(*) FILTER (WHERE cm.active AND NOT c.active)::text,
       count(*) FILTER (WHERE cs.active AND NOT cm.active)::text,
       count(*) FILTER (WHERE c.min_duration_years > c.max_duration_years)::text,
       count(*) FILTER (WHERE c.minimum_age < 0)::text
FROM classes c
JOIN club_types ct ON ct.club_type_id = c.club_type_id
LEFT JOIN class_modules cm ON cm.class_id = c.class_id
LEFT JOIN class_sections cs ON cs.module_id = cm.module_id;

SELECT 'class_section_scope_conflicts', count(*)::text
FROM class_sections
WHERE (owner_division_id IS NOT NULL)::int
    + (owner_union_id IS NOT NULL)::int
    + (owner_local_field_id IS NOT NULL)::int > 1;

\echo 'SECTION|FINANCE_CATEGORIES'
SELECT 'finance_type_summary', type::text, count(*)::text,
       count(*) FILTER (WHERE active)::text,
       string_agg(name, ', ' ORDER BY name)
FROM finances_categories
GROUP BY type
ORDER BY type;
SELECT 'invalid_finance_category_type', count(*)::text,
       coalesce(string_agg(finance_category_id::text || ':' || name || '=' || type::text, ', '), '')
FROM finances_categories
WHERE type NOT IN (0,1);

\echo 'SECTION|RELATIONSHIP_TYPES'
SELECT 'relationship_type', name, active::text FROM relationship_types ORDER BY name;

\echo 'SECTION|HEALTH_CATALOG_QUALITY'
SELECT 'normalized_duplicates','allergies', count(*)::text
FROM (SELECT lower(btrim(name)) FROM allergies GROUP BY lower(btrim(name)) HAVING count(*) > 1) x
UNION ALL
SELECT 'normalized_duplicates','diseases', count(*)::text
FROM (SELECT lower(btrim(name)) FROM diseases GROUP BY lower(btrim(name)) HAVING count(*) > 1) x
UNION ALL
SELECT 'normalized_duplicates','medicines', count(*)::text
FROM (SELECT lower(btrim(name)) FROM medicines GROUP BY lower(btrim(name)) HAVING count(*) > 1) x;
SELECT 'blank_names','allergies',count(*)::text FROM allergies WHERE btrim(name) = ''
UNION ALL SELECT 'blank_names','diseases',count(*)::text FROM diseases WHERE btrim(name) = ''
UNION ALL SELECT 'blank_names','medicines',count(*)::text FROM medicines WHERE btrim(name) = '';

\echo 'SECTION|HONORS_QUALITY'
SELECT 'honors_summary', count(*)::text,
       count(*) FILTER (WHERE active)::text,
       count(*) FILTER (WHERE btrim(name) = '')::text,
       count(*) FILTER (WHERE btrim(honor_image) = '')::text,
       count(*) FILTER (WHERE btrim(material_url) = '')::text,
       count(*) FILTER (WHERE code IS NULL OR btrim(code) = '')::text
FROM honors;
SELECT 'honors_without_active_requirements', count(*)::text
FROM honors h
WHERE h.active AND NOT EXISTS (
  SELECT 1 FROM honor_requirements hr WHERE hr.honor_id = h.honor_id AND hr.active
);
SELECT 'honors_without_active_club_type_mapping', count(*)::text
FROM honors h
WHERE h.active AND NOT EXISTS (
  SELECT 1 FROM honor_club_types hct WHERE hct.honor_id = h.honor_id AND hct.active
);
SELECT 'legacy_vs_mapping_mismatch', count(*)::text
FROM honors h
WHERE NOT EXISTS (
  SELECT 1 FROM honor_club_types hct
  WHERE hct.honor_id = h.honor_id
    AND hct.club_type_id = h.club_type_id
    AND hct.active
);
SELECT 'requirement_quality',
       count(*) FILTER (WHERE active AND btrim(requirement_text) = '')::text,
       count(*) FILTER (WHERE parent_id = requirement_id)::text,
       count(*) FILTER (WHERE is_choice_group AND (choice_min IS NULL OR choice_min < 1))::text,
       count(*) FILTER (WHERE NOT is_choice_group AND choice_min IS NOT NULL)::text,
       count(*) FILTER (WHERE needs_review)::text
FROM honor_requirements;
SELECT 'master_honor_definition_coverage',
       (SELECT count(*) FROM master_honors)::text,
       (SELECT count(*) FROM master_honors WHERE active)::text,
       (SELECT count(*) FROM master_honor_requirement_groups)::text,
       (SELECT count(*) FROM master_honor_requirement_options)::text,
       (SELECT count(*) FROM master_honor_divisions)::text;

\echo 'SECTION|INSTITUTIONAL_HIERARCHY_SUMMARY'
SELECT 'hierarchy','divisions',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM divisions
UNION ALL SELECT 'hierarchy','countries',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM countries
UNION ALL SELECT 'hierarchy','unions',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM unions
UNION ALL SELECT 'hierarchy','local_fields',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM local_fields
UNION ALL SELECT 'hierarchy','districts',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM districts
UNION ALL SELECT 'hierarchy','churches',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM churches
UNION ALL SELECT 'hierarchy','clubs',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM clubs
UNION ALL SELECT 'hierarchy','club_sections',count(*)::text,count(*) FILTER (WHERE active)::text,count(*) FILTER (WHERE NOT active)::text FROM club_sections
ORDER BY 2;

\echo 'SECTION|DIVISIONS'
SELECT 'division', division_id::text, code, name, abbreviation, active::text FROM divisions ORDER BY division_id;

\echo 'SECTION|UNIONS'
SELECT 'union', u.union_id::text, u.name, u.abbreviation, u.active::text,
       c.name, c.active::text, d.name, d.active::text,
       count(lf.local_field_id)::text,
       count(lf.local_field_id) FILTER (WHERE lf.active)::text
FROM unions u
JOIN countries c ON c.country_id = u.country_id
JOIN divisions d ON d.division_id = u.division_id
LEFT JOIN local_fields lf ON lf.union_id = u.union_id
GROUP BY u.union_id, u.name, u.abbreviation, u.active, c.name, c.active, d.name, d.active
ORDER BY u.name;

\echo 'SECTION|LOCAL_FIELDS'
SELECT 'local_field', lf.local_field_id::text, lf.name, lf.abbreviation, lf.active::text,
       u.name, u.active::text,
       count(d.districlub_type_id)::text,
       count(d.districlub_type_id) FILTER (WHERE d.active)::text
FROM local_fields lf
JOIN unions u ON u.union_id = lf.union_id
LEFT JOIN districts d ON d.local_field_id = lf.local_field_id
GROUP BY lf.local_field_id, lf.name, lf.abbreviation, lf.active, u.name, u.active
ORDER BY lf.name;

\echo 'SECTION|DISTRICTS_AND_CHURCHES'
SELECT 'district', d.districlub_type_id::text, d.name, d.active::text,
       lf.name, lf.active::text,
       count(c.church_id)::text,
       count(c.church_id) FILTER (WHERE c.active)::text
FROM districts d
JOIN local_fields lf ON lf.local_field_id = d.local_field_id
LEFT JOIN churches c ON c.districlub_type_id = d.districlub_type_id
GROUP BY d.districlub_type_id, d.name, d.active, lf.name, lf.active
ORDER BY lf.name, d.name;

SELECT 'church', c.church_id::text, c.name, c.active::text,
       d.name, d.active::text, lf.name, lf.active::text
FROM churches c
JOIN districts d ON d.districlub_type_id = c.districlub_type_id
JOIN local_fields lf ON lf.local_field_id = d.local_field_id
ORDER BY c.name;

\echo 'SECTION|HIERARCHY_INCONSISTENCIES'
SELECT 'active_union_with_inactive_parent', count(*)::text
FROM unions u JOIN countries c ON c.country_id=u.country_id JOIN divisions d ON d.division_id=u.division_id
WHERE u.active AND (NOT c.active OR NOT d.active)
UNION ALL
SELECT 'active_local_field_with_inactive_union', count(*)::text
FROM local_fields lf JOIN unions u ON u.union_id=lf.union_id
WHERE lf.active AND NOT u.active
UNION ALL
SELECT 'active_district_with_inactive_local_field', count(*)::text
FROM districts d JOIN local_fields lf ON lf.local_field_id=d.local_field_id
WHERE d.active AND NOT lf.active
UNION ALL
SELECT 'active_church_with_inactive_district', count(*)::text
FROM churches c JOIN districts d ON d.districlub_type_id=c.districlub_type_id
WHERE c.active AND NOT d.active
UNION ALL
SELECT 'country_spans_multiple_active_divisions', count(*)::text
FROM (
  SELECT country_id
  FROM unions
  WHERE active
  GROUP BY country_id
  HAVING count(DISTINCT division_id) > 1
) x;

SELECT 'normalized_duplicates','countries',count(*)::text FROM (SELECT lower(btrim(name)) FROM countries GROUP BY lower(btrim(name)) HAVING count(*)>1) x
UNION ALL SELECT 'normalized_duplicates','unions',count(*)::text FROM (SELECT lower(btrim(name)) FROM unions GROUP BY lower(btrim(name)) HAVING count(*)>1) x
UNION ALL SELECT 'normalized_duplicates','local_fields',count(*)::text FROM (SELECT lower(btrim(name)) FROM local_fields GROUP BY lower(btrim(name)) HAVING count(*)>1) x
UNION ALL SELECT 'normalized_duplicates','districts_within_local_field',count(*)::text FROM (SELECT local_field_id,lower(btrim(name)) FROM districts GROUP BY local_field_id,lower(btrim(name)) HAVING count(*)>1) x
UNION ALL SELECT 'normalized_duplicates','churches_within_district',count(*)::text FROM (SELECT districlub_type_id,lower(btrim(name)) FROM churches GROUP BY districlub_type_id,lower(btrim(name)) HAVING count(*)>1) x;

SELECT 'history_coverage',
       (SELECT count(*) FROM unions)::text,
       (SELECT count(DISTINCT union_id) FROM union_division_history)::text,
       (SELECT count(*) FROM local_fields)::text,
       (SELECT count(DISTINCT local_field_id) FROM local_field_union_history)::text,
       (SELECT count(*) FROM districts)::text,
       (SELECT count(DISTINCT districlub_type_id) FROM district_local_field_history)::text,
       (SELECT count(*) FROM churches)::text,
       (SELECT count(DISTINCT church_id) FROM church_district_history)::text;

\echo 'SECTION|ECCLESIASTICAL_YEARS'
SELECT 'year', year_id::text, start_date::text, end_date::text, active::text,
       (current_date BETWEEN start_date AND end_date)::text
FROM ecclesiastical_years
ORDER BY start_date;
SELECT 'year_summary', count(*)::text,
       count(*) FILTER (WHERE active)::text,
       count(*) FILTER (WHERE current_date BETWEEN start_date AND end_date)::text,
       count(*) FILTER (WHERE start_date > end_date)::text
FROM ecclesiastical_years;
SELECT 'overlapping_year_pairs', count(*)::text
FROM ecclesiastical_years a
JOIN ecclesiastical_years b ON a.year_id < b.year_id
 AND daterange(a.start_date, a.end_date, '[]') && daterange(b.start_date, b.end_date, '[]');

\echo 'SECTION|RANKING_AND_SCORING_CONFIG'
SELECT 'enrollment_ranking_weight', coalesce(club_type_id::text,''), coalesce(ecclesiastical_year_id::text,''),
       class_pct::text, investiture_pct::text, camporee_pct::text,
       (class_pct + investiture_pct + camporee_pct)::text, is_default::text
FROM enrollment_ranking_weights
ORDER BY is_default DESC, club_type_id NULLS FIRST;
SELECT 'ranking_weight_config', coalesce(club_type_id::text,''), folder_weight::text,
       finance_weight::text, camporee_weight::text, evidence_weight::text,
       (folder_weight + finance_weight + camporee_weight + evidence_weight)::text
FROM ranking_weight_configs
ORDER BY club_type_id NULLS FIRST;
SELECT 'scoring_category', scoring_category_id::text, name, max_points::text,
       scoring_mode::text, origin_level::text, origin_id::text, active::text
FROM scoring_categories
ORDER BY scoring_category_id;

\echo 'SECTION|OPERATIONAL_READINESS_COUNTS'
SELECT 'operation','users',count(*)::text FROM users
UNION ALL SELECT 'operation','active_users',count(*)::text FROM users WHERE active
UNION ALL SELECT 'operation','panel_users',count(*)::text FROM users WHERE active AND access_panel
UNION ALL SELECT 'operation','app_users',count(*)::text FROM users WHERE active AND access_app
UNION ALL SELECT 'operation','user_global_roles',count(*)::text FROM users_roles
UNION ALL SELECT 'operation','ecclesiastical_years',count(*)::text FROM ecclesiastical_years
UNION ALL SELECT 'operation','clubs',count(*)::text FROM clubs
UNION ALL SELECT 'operation','club_sections',count(*)::text FROM club_sections
UNION ALL SELECT 'operation','club_enrollments',count(*)::text FROM club_enrollments
UNION ALL SELECT 'operation','club_role_assignments',count(*)::text FROM club_role_assignments
UNION ALL SELECT 'operation','member_enrollments',count(*)::text FROM enrollments
UNION ALL SELECT 'operation','units',count(*)::text FROM units
UNION ALL SELECT 'operation','class_counselor_assignments',count(*)::text FROM class_counselor_assignments
UNION ALL SELECT 'operation','folder_templates',count(*)::text FROM folder_templates
UNION ALL SELECT 'operation','annual_folders',count(*)::text FROM annual_folders
UNION ALL SELECT 'operation','annual_ranking_configs',count(*)::text FROM annual_ranking_configs
UNION ALL SELECT 'operation','investiture_config',count(*)::text FROM investiture_config
UNION ALL SELECT 'operation','activities',count(*)::text FROM activities
UNION ALL SELECT 'operation','finances',count(*)::text FROM finances
UNION ALL SELECT 'operation','inventory_items',count(*)::text FROM club_inventory
UNION ALL SELECT 'operation','member_insurances',count(*)::text FROM member_insurances
UNION ALL SELECT 'operation','monthly_reports',count(*)::text FROM monthly_reports
UNION ALL SELECT 'operation','camporee_event_templates',count(*)::text FROM camporee_event_templates
UNION ALL SELECT 'operation','camporee_venues',count(*)::text FROM camporee_venues
UNION ALL SELECT 'operation','material_products',count(*)::text FROM material_products
UNION ALL SELECT 'operation','material_config',count(*)::text FROM material_config
UNION ALL SELECT 'operation','resource_categories',count(*)::text FROM resource_categories
UNION ALL SELECT 'operation','resources',count(*)::text FROM resources
ORDER BY 2;

ROLLBACK;

-- 3) General data-quality drill-down.
\pset format unaligned
\pset fieldsep '|'
\pset tuples_only on
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;

\echo 'SCORING_DUPLICATES'
SELECT origin_level::text, origin_id::text, lower(btrim(name)), count(*)::text,
       string_agg(scoring_category_id::text, ',' ORDER BY scoring_category_id)
FROM scoring_categories
WHERE active
GROUP BY origin_level, origin_id, lower(btrim(name))
HAVING count(*) > 1;
SELECT scoring_category_id::text, name, origin_level::text, origin_id::text,
       max_points::text, scoring_mode::text, active::text,
       created_at::text, modified_at::text
FROM scoring_categories
ORDER BY scoring_category_id;

\echo 'TEXT_QUALITY'
SELECT 'country_name', country_id::text, name FROM countries WHERE name <> btrim(name)
UNION ALL SELECT 'union_name', union_id::text, name FROM unions WHERE name <> btrim(name)
UNION ALL SELECT 'local_field_name', local_field_id::text, name FROM local_fields WHERE name <> btrim(name)
UNION ALL SELECT 'district_name', districlub_type_id::text, name FROM districts WHERE name <> btrim(name)
UNION ALL SELECT 'church_name', church_id::text, name FROM churches WHERE name <> btrim(name)
UNION ALL SELECT 'class_name', class_id::text, name FROM classes WHERE name <> btrim(name)
UNION ALL SELECT 'honor_name', honor_id::text, name FROM honors WHERE name <> btrim(name)
ORDER BY 1,2;

\echo 'ACTIVE_DISTRICTS_WITHOUT_ACTIVE_CHURCH'
SELECT d.districlub_type_id::text, d.name
FROM districts d
WHERE d.active
  AND NOT EXISTS (
    SELECT 1 FROM churches c
    WHERE c.districlub_type_id=d.districlub_type_id AND c.active
  )
ORDER BY d.name;

\echo 'ACTIVE_CLASSES_WITHOUT_ACTIVE_MODULES'
SELECT c.class_id::text, c.name, ct.name
FROM classes c
JOIN club_types ct ON ct.club_type_id=c.club_type_id
WHERE c.active
  AND NOT EXISTS (
    SELECT 1 FROM class_modules cm WHERE cm.class_id=c.class_id AND cm.active
  )
ORDER BY c.class_id;

\echo 'HONORS_WITHOUT_REQUIREMENTS_BY_CATEGORY_AND_CLUB_TYPE'
SELECT hc.name, ct.name, count(*)::text
FROM honors h
JOIN honors_categories hc ON hc.honor_category_id=h.honors_category_id
JOIN club_types ct ON ct.club_type_id=h.club_type_id
WHERE h.active
  AND NOT EXISTS (
    SELECT 1 FROM honor_requirements hr WHERE hr.honor_id=h.honor_id AND hr.active
  )
GROUP BY hc.name,ct.name
ORDER BY count(*) DESC,hc.name,ct.name;
SELECT 'sample', h.honor_id::text, h.name, hc.name, ct.name
FROM honors h
JOIN honors_categories hc ON hc.honor_category_id=h.honors_category_id
JOIN club_types ct ON ct.club_type_id=h.club_type_id
WHERE h.active
  AND NOT EXISTS (
    SELECT 1 FROM honor_requirements hr WHERE hr.honor_id=h.honor_id AND hr.active
  )
ORDER BY h.honor_id
LIMIT 30;

\echo 'MASTER_HONORS_WITHOUT_RULE_GROUPS'
SELECT mh.master_honor_id::text, mh.name, mh.applicability_scope::text, mh.active::text
FROM master_honors mh
WHERE mh.active
  AND NOT EXISTS (
    SELECT 1 FROM master_honor_requirement_groups g
    WHERE g.master_honor_id=mh.master_honor_id
  )
ORDER BY mh.name;

\echo 'HISTORY_CURRENT_RELATION_CONSISTENCY'
SELECT 'union_current_history_missing_or_multiple', count(*)::text
FROM unions u
WHERE (SELECT count(*) FROM union_division_history h WHERE h.union_id=u.union_id AND h.valid_to IS NULL) <> 1
UNION ALL
SELECT 'union_current_parent_mismatch', count(*)::text
FROM unions u
JOIN union_division_history h ON h.union_id=u.union_id AND h.valid_to IS NULL
WHERE h.division_id<>u.division_id
UNION ALL
SELECT 'local_field_current_history_missing_or_multiple', count(*)::text
FROM local_fields lf
WHERE (SELECT count(*) FROM local_field_union_history h WHERE h.local_field_id=lf.local_field_id AND h.valid_to IS NULL) <> 1
UNION ALL
SELECT 'local_field_current_parent_mismatch', count(*)::text
FROM local_fields lf
JOIN local_field_union_history h ON h.local_field_id=lf.local_field_id AND h.valid_to IS NULL
WHERE h.union_id<>lf.union_id
UNION ALL
SELECT 'district_current_history_missing_or_multiple', count(*)::text
FROM districts d
WHERE (SELECT count(*) FROM district_local_field_history h WHERE h.districlub_type_id=d.districlub_type_id AND h.valid_to IS NULL) <> 1
UNION ALL
SELECT 'district_current_parent_mismatch', count(*)::text
FROM districts d
JOIN district_local_field_history h ON h.districlub_type_id=d.districlub_type_id AND h.valid_to IS NULL
WHERE h.local_field_id<>d.local_field_id
UNION ALL
SELECT 'church_current_history_missing_or_multiple', count(*)::text
FROM churches c
WHERE (SELECT count(*) FROM church_district_history h WHERE h.church_id=c.church_id AND h.valid_to IS NULL) <> 1
UNION ALL
SELECT 'church_current_parent_mismatch', count(*)::text
FROM churches c
JOIN church_district_history h ON h.church_id=c.church_id AND h.valid_to IS NULL
WHERE h.districlub_type_id<>c.districlub_type_id;

\echo 'AWARD_CATEGORY_QUALITY'
SELECT award_category_id::text,name,coalesce(club_type_id::text,''),min_points::text,
       coalesce(max_points::text,''),coalesce(min_composite_pct::text,''),
       coalesce(max_composite_pct::text,''),scope,tier::text,is_legacy::text,active::text
FROM award_categories
ORDER BY scope,club_type_id NULLS FIRST,"order";

\echo 'MATERIAL_CATEGORIES'
SELECT slug,label,sort_order::text,active::text FROM material_categories ORDER BY sort_order;

ROLLBACK;

-- 4) Development operational readiness drill-down.
\pset format unaligned
\pset fieldsep '|'
\pset tuples_only on
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;

\echo 'SECTION|USER_READINESS'
SELECT 'users_by_state', active::text, approval_status::text,
       coalesce(access_app,false)::text, coalesce(access_panel,false)::text,
       count(*)::text
FROM users
GROUP BY active,approval_status,coalesce(access_app,false),coalesce(access_panel,false)
ORDER BY active DESC,approval_status,coalesce(access_panel,false) DESC;

SELECT 'account_coverage',
       (SELECT count(*) FROM users)::text,
       (SELECT count(*) FROM accounts)::text,
       (SELECT count(*) FROM users u WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.user_id=u.user_id))::text,
       (SELECT count(*) FROM accounts a WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id=a.user_id))::text;

SELECT 'post_registration',
       count(*)::text,
       count(*) FILTER (WHERE complete)::text,
       count(*) FILTER (WHERE profile_picture_complete)::text,
       count(*) FILTER (WHERE personal_info_complete)::text,
       count(*) FILTER (WHERE club_selection_complete)::text,
       count(*) FILTER (WHERE active_club_assignment_id IS NOT NULL)::text
FROM users_pr;

SELECT 'users_missing_post_registration_row', count(*)::text
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM users_pr up WHERE up.user_id=u.user_id);

SELECT 'invalid_active_assignment_pointer', count(*)::text
FROM users_pr up
LEFT JOIN club_role_assignments cra ON cra.assignment_id=up.active_club_assignment_id
WHERE up.active_club_assignment_id IS NOT NULL
  AND (cra.assignment_id IS NULL OR cra.user_id<>up.user_id OR NOT cra.active);

SELECT 'global_role', r.role_name,
       count(*) FILTER (WHERE ur.active)::text,
       count(*) FILTER (WHERE NOT ur.active)::text
FROM users_roles ur
JOIN roles r ON r.role_id=ur.role_id
GROUP BY r.role_name
ORDER BY r.role_name;

SELECT 'panel_user_without_active_global_role', count(*)::text
FROM users u
WHERE u.active AND coalesce(u.access_panel,false)
  AND NOT EXISTS (
    SELECT 1 FROM users_roles ur JOIN roles r ON r.role_id=ur.role_id
    WHERE ur.user_id=u.user_id AND ur.active AND r.active AND r.role_category::text='GLOBAL'
  );

SELECT 'territorial_role_scope_issue', r.role_name, count(*)::text
FROM users_roles ur
JOIN roles r ON r.role_id=ur.role_id
JOIN users u ON u.user_id=ur.user_id
WHERE ur.active AND r.active AND (
  (r.role_name IN ('director-lf','assistant-lf') AND u.local_field_id IS NULL)
  OR (r.role_name IN ('director-union','assistant-union') AND u.union_id IS NULL)
  OR (r.role_name IN ('director-dia','assistant-dia') AND u.union_id IS NULL AND u.local_field_id IS NULL)
)
GROUP BY r.role_name
ORDER BY r.role_name;

SELECT 'active_users_without_any_active_role', count(*)::text
FROM users u
WHERE u.active
  AND NOT EXISTS (SELECT 1 FROM users_roles ur WHERE ur.user_id=u.user_id AND ur.active)
  AND NOT EXISTS (SELECT 1 FROM club_role_assignments cra WHERE cra.user_id=u.user_id AND cra.active);

\echo 'SECTION|CLUB_AND_SECTION_READINESS'
SELECT 'club', c.club_id::text, c.name, c.active::text,
       lf.name, d.name, ch.name,
       count(cs.club_section_id)::text,
       count(cs.club_section_id) FILTER (WHERE cs.active)::text
FROM clubs c
JOIN local_fields lf ON lf.local_field_id=c.local_field_id
JOIN districts d ON d.districlub_type_id=c.districlub_type_id
JOIN churches ch ON ch.church_id=c.church_id
LEFT JOIN club_sections cs ON cs.main_club_id=c.club_id
GROUP BY c.club_id,c.name,c.active,lf.name,d.name,ch.name
ORDER BY c.club_id;

SELECT 'club_hierarchy_mismatch', count(*)::text
FROM clubs c
JOIN districts d ON d.districlub_type_id=c.districlub_type_id
JOIN churches ch ON ch.church_id=c.church_id
WHERE d.local_field_id<>c.local_field_id OR ch.districlub_type_id<>c.districlub_type_id;

SELECT 'section', cs.club_section_id::text, coalesce(cs.name,''), ct.name,
       cs.active::text, c.name,
       count(DISTINCT cra.user_id) FILTER (WHERE cra.active)::text,
       count(DISTINCT e.user_id) FILTER (WHERE e.active AND e.ecclesiastical_year_id=ey.year_id)::text,
       count(DISTINCT u.unit_id) FILTER (WHERE u.active)::text
FROM club_sections cs
JOIN club_types ct ON ct.club_type_id=cs.club_type_id
JOIN clubs c ON c.club_id=cs.main_club_id
LEFT JOIN club_role_assignments cra ON cra.club_section_id=cs.club_section_id
LEFT JOIN ecclesiastical_years ey ON current_date BETWEEN ey.start_date AND ey.end_date
LEFT JOIN enrollments e ON e.user_id=cra.user_id AND e.ecclesiastical_year_id=ey.year_id
LEFT JOIN units u ON u.club_section_id=cs.club_section_id
GROUP BY cs.club_section_id,cs.name,ct.name,cs.active,c.club_id,c.name
ORDER BY c.club_id,cs.club_type_id;

SELECT 'active_sections_without_current_enrollment', count(*)::text
FROM club_sections cs
JOIN clubs c ON c.club_id=cs.main_club_id
WHERE cs.active AND c.active
  AND NOT EXISTS (
    SELECT 1
    FROM club_enrollments ce
    JOIN ecclesiastical_years ey ON ey.year_id=ce.ecclesiastical_year_id
    WHERE ce.club_section_id=cs.club_section_id
      AND current_date BETWEEN ey.start_date AND ey.end_date
      AND ce.status='active'
  );

\echo 'SECTION|CLUB_ROLE_ASSIGNMENTS'
SELECT 'assignment_state', coalesce(cra.status,'<null>'), cra.active::text,
       (current_date BETWEEN cra.start_date AND coalesce(cra.end_date,current_date))::text,
       count(*)::text
FROM club_role_assignments cra
GROUP BY coalesce(cra.status,'<null>'),cra.active,
         (current_date BETWEEN cra.start_date AND coalesce(cra.end_date,current_date))
ORDER BY 1,2,3;

SELECT 'club_role', r.role_name,
       count(*)::text,
       count(*) FILTER (WHERE cra.active AND coalesce(cra.status,'active')='active')::text,
       count(DISTINCT cra.user_id) FILTER (WHERE cra.active AND coalesce(cra.status,'active')='active')::text
FROM club_role_assignments cra
JOIN roles r ON r.role_id=cra.role_id
GROUP BY r.role_name
ORDER BY r.role_name;

SELECT 'active_assignment_invalid_context',
       count(*) FILTER (WHERE r.role_category::text<>'CLUB')::text,
       count(*) FILTER (WHERE cs.club_section_id IS NULL OR NOT cs.active)::text,
       count(*) FILTER (WHERE NOT u.active)::text,
       count(*) FILTER (WHERE NOT ey.active OR NOT (current_date BETWEEN ey.start_date AND ey.end_date))::text
FROM club_role_assignments cra
JOIN roles r ON r.role_id=cra.role_id
JOIN users u ON u.user_id=cra.user_id
JOIN ecclesiastical_years ey ON ey.year_id=cra.ecclesiastical_year_id
LEFT JOIN club_sections cs ON cs.club_section_id=cra.club_section_id
WHERE cra.active AND coalesce(cra.status,'active')='active';

SELECT 'role_slot_violation', cs.club_section_id::text, r.role_name,
       count(DISTINCT cra.user_id)::text, rsl.max_per_section::text
FROM club_role_assignments cra
JOIN role_slot_limits rsl ON rsl.role_id=cra.role_id
JOIN roles r ON r.role_id=cra.role_id
JOIN club_sections cs ON cs.club_section_id=cra.club_section_id
JOIN ecclesiastical_years ey ON ey.year_id=cra.ecclesiastical_year_id
WHERE cra.active AND coalesce(cra.status,'active')='active'
  AND current_date BETWEEN ey.start_date AND ey.end_date
  AND current_date BETWEEN cra.start_date AND coalesce(cra.end_date,current_date)
GROUP BY cs.club_section_id,r.role_name,rsl.max_per_section
HAVING count(DISTINCT cra.user_id)>rsl.max_per_section
ORDER BY cs.club_section_id,r.role_name;

\echo 'SECTION|MEMBER_AND_CLASS_COVERAGE'
WITH current_year AS (
  SELECT year_id FROM ecclesiastical_years
  WHERE current_date BETWEEN start_date AND end_date
  ORDER BY start_date DESC LIMIT 1
), active_people AS (
  SELECT DISTINCT cra.user_id
  FROM club_role_assignments cra,current_year cy
  WHERE cra.ecclesiastical_year_id=cy.year_id
    AND cra.active AND coalesce(cra.status,'active')='active'
)
SELECT 'active_assigned_people', count(*)::text,
       count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM enrollments e,current_year cy
         WHERE e.user_id=ap.user_id AND e.ecclesiastical_year_id=cy.year_id AND e.active
       ))::text,
       count(*) FILTER (WHERE NOT EXISTS (
         SELECT 1 FROM enrollments e,current_year cy
         WHERE e.user_id=ap.user_id AND e.ecclesiastical_year_id=cy.year_id AND e.active
       ))::text
FROM active_people ap;

SELECT 'enrollment_state', investiture_status::text, active::text,
       submitted_for_validation::text, count(*)::text
FROM enrollments
GROUP BY investiture_status,active,submitted_for_validation
ORDER BY investiture_status,active DESC,submitted_for_validation;

SELECT 'active_enrollment_invalid_context',
       count(*) FILTER (WHERE NOT u.active)::text,
       count(*) FILTER (WHERE NOT c.active)::text,
       count(*) FILTER (WHERE NOT ey.active OR NOT (current_date BETWEEN ey.start_date AND ey.end_date))::text
FROM enrollments e
JOIN users u ON u.user_id=e.user_id
JOIN classes c ON c.class_id=e.class_id
JOIN ecclesiastical_years ey ON ey.year_id=e.ecclesiastical_year_id
WHERE e.active;

\echo 'SECTION|ANNUAL_OPERATION'
SELECT 'club_enrollment', ce.club_section_id::text, ct.name, ce.status,
       ey.start_date::text,ey.end_date::text,
       (ce.director_id IS NOT NULL)::text,
       ((ce.secretary_id IS NOT NULL) OR (ce.secretary_treasurer_id IS NOT NULL))::text,
       ((ce.treasurer_id IS NOT NULL) OR (ce.secretary_treasurer_id IS NOT NULL))::text,
       (af.annual_folder_id IS NOT NULL)::text,
       coalesce(af.status,'')
FROM club_enrollments ce
JOIN club_sections cs ON cs.club_section_id=ce.club_section_id
JOIN club_types ct ON ct.club_type_id=cs.club_type_id
JOIN ecclesiastical_years ey ON ey.year_id=ce.ecclesiastical_year_id
LEFT JOIN annual_folders af ON af.club_enrollment_id=ce.club_enrollment_id
ORDER BY ce.club_section_id;

SELECT 'active_club_enrollment_without_folder', count(*)::text
FROM club_enrollments ce
WHERE ce.status='active'
  AND NOT EXISTS (SELECT 1 FROM annual_folders af WHERE af.club_enrollment_id=ce.club_enrollment_id);

SELECT 'folder_template', ft.name, ct.name, ft.status::text, ft.active::text,
       ey.start_date::text,ey.end_date::text,
       coalesce(u.name,''),coalesce(lf.name,''),
       count(fts.section_id)::text,
       ft.minimum_points::text,
       coalesce(ft.closing_date::text,'')
FROM folder_templates ft
JOIN club_types ct ON ct.club_type_id=ft.club_type_id
JOIN ecclesiastical_years ey ON ey.year_id=ft.ecclesiastical_year_id
LEFT JOIN unions u ON u.union_id=ft.owner_union_id
LEFT JOIN local_fields lf ON lf.local_field_id=ft.owner_local_field_id
LEFT JOIN folder_template_sections fts ON fts.folder_template_id=ft.folder_template_id
GROUP BY ft.folder_template_id,ft.name,ct.name,ft.status,ft.active,ey.start_date,ey.end_date,u.name,lf.name,ft.minimum_points,ft.closing_date
ORDER BY ft.name;

SELECT 'active_section_type_without_published_template', ct.name, count(*)::text
FROM club_sections cs
JOIN club_types ct ON ct.club_type_id=cs.club_type_id
JOIN clubs c ON c.club_id=cs.main_club_id
JOIN districts d ON d.districlub_type_id=c.districlub_type_id
JOIN local_fields lf ON lf.local_field_id=c.local_field_id
JOIN unions un ON un.union_id=lf.union_id
JOIN ecclesiastical_years ey ON current_date BETWEEN ey.start_date AND ey.end_date
WHERE cs.active AND c.active
  AND NOT EXISTS (
    SELECT 1 FROM folder_templates ft
    WHERE ft.club_type_id=cs.club_type_id
      AND ft.ecclesiastical_year_id=ey.year_id
      AND ft.active AND ft.status::text='PUBLISHED'
      AND (ft.owner_local_field_id=lf.local_field_id OR ft.owner_union_id=un.union_id)
  )
GROUP BY ct.name
ORDER BY ct.name;

SELECT 'annual_ranking_config', ct.name,
       coalesce(un.name,''),coalesce(lf.name,''),arc.active::text,
       arc.max_points::text,
       (SELECT count(*) FROM annual_ranking_axis_configs ax WHERE ax.annual_ranking_config_id=arc.annual_ranking_config_id AND ax.active)::text,
       coalesce((SELECT sum(ax.max_points) FROM annual_ranking_axis_configs ax WHERE ax.annual_ranking_config_id=arc.annual_ranking_config_id AND ax.active),0)::text,
       (SELECT count(*) FROM annual_ranking_component_configs cp WHERE cp.annual_ranking_config_id=arc.annual_ranking_config_id AND cp.active)::text,
       coalesce((SELECT sum(cp.max_points) FROM annual_ranking_component_configs cp WHERE cp.annual_ranking_config_id=arc.annual_ranking_config_id AND cp.active),0)::text
FROM annual_ranking_configs arc
JOIN club_types ct ON ct.club_type_id=arc.club_type_id
LEFT JOIN unions un ON un.union_id=arc.union_id
LEFT JOIN local_fields lf ON lf.local_field_id=arc.local_field_id
ORDER BY ct.name,un.name,lf.name;

SELECT 'investiture_config', lf.name, ey.start_date::text,ey.end_date::text,
       ic.submission_deadline::text,ic.investiture_date::text,ic.active::text,
       (ic.submission_deadline BETWEEN ey.start_date AND ey.end_date)::text,
       (ic.investiture_date BETWEEN ey.start_date AND ey.end_date)::text,
       (ic.submission_deadline<=ic.investiture_date)::text
FROM investiture_config ic
JOIN local_fields lf ON lf.local_field_id=ic.local_field_id
JOIN ecclesiastical_years ey ON ey.year_id=ic.ecclesiastical_year_id
ORDER BY lf.name,ey.start_date;

\echo 'SECTION|HONOR_APPLICABILITY_CONSISTENCY'
SELECT 'legacy_to_mapping', legacy.name, mapped.name, count(*)::text
FROM honors h
JOIN club_types legacy ON legacy.club_type_id=h.club_type_id
JOIN honor_club_types hct ON hct.honor_id=h.honor_id AND hct.active
JOIN club_types mapped ON mapped.club_type_id=hct.club_type_id
GROUP BY legacy.name,mapped.name
ORDER BY legacy.name,mapped.name;

SELECT 'honor_mapping_cardinality', mapping_count::text, count(*)::text
FROM (
  SELECT h.honor_id,count(hct.honor_club_type_id) FILTER (WHERE hct.active) mapping_count
  FROM honors h LEFT JOIN honor_club_types hct ON hct.honor_id=h.honor_id
  WHERE h.active
  GROUP BY h.honor_id
) x
GROUP BY mapping_count
ORDER BY mapping_count;

SELECT 'catalog_action_applicability_conflict', count(DISTINCT h.honor_id)::text
FROM honors h
JOIN honor_club_types hct ON hct.honor_id=h.honor_id AND hct.active
WHERE h.active AND h.club_type_id<>hct.club_type_id;

SELECT 'master_honor_rule_quality',
       count(*) FILTER (WHERE mh.active AND NOT EXISTS (
         SELECT 1 FROM master_honor_requirement_groups g WHERE g.master_honor_id=mh.master_honor_id
       ))::text,
       count(*) FILTER (WHERE mh.active AND mh.applicability_scope::text='SELECTED_DIVISIONS' AND NOT EXISTS (
         SELECT 1 FROM master_honor_divisions md WHERE md.master_honor_id=mh.master_honor_id
       ))::text
FROM master_honors mh;

SELECT 'master_group_invalid',
       count(*) FILTER (WHERE minimum_required<=0)::text,
       count(*) FILTER (WHERE group_type::text='CATEGORY_COUNT' AND honors_category_id IS NULL)::text,
       count(*) FILTER (WHERE group_type::text='EXPLICIT_OPTIONS' AND honors_category_id IS NOT NULL)::text,
       count(*) FILTER (WHERE group_type::text='EXPLICIT_OPTIONS' AND minimum_required>(
         SELECT count(*) FROM master_honor_requirement_options o WHERE o.group_id=g.group_id
       ))::text
FROM master_honor_requirement_groups g;

SELECT 'master_options_without_honors', count(*)::text
FROM master_honor_requirement_options o
WHERE NOT EXISTS (
  SELECT 1 FROM master_honor_requirement_option_honors oh WHERE oh.option_id=o.option_id
);

\echo 'SECTION|DATABASE_HYGIENE'
SELECT 'unowned_public_table', table_name
FROM information_schema.tables t
WHERE table_schema='public' AND table_type='BASE TABLE'
  AND table_name='playing_with_neon';

ROLLBACK;

-- 5) Development anomaly details.
\pset format unaligned
\pset fieldsep '|'
\pset tuples_only on
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;

\echo 'USER_ROLE_CATEGORY_DRIFT'
SELECT r.role_category::text,r.role_name,count(*)::text
FROM users_roles ur JOIN roles r ON r.role_id=ur.role_id
WHERE ur.active
GROUP BY r.role_category,r.role_name
ORDER BY r.role_category,r.role_name;
SELECT 'club_roles_in_users_roles',count(*)::text
FROM users_roles ur JOIN roles r ON r.role_id=ur.role_id
WHERE ur.active AND r.role_category::text='CLUB';
SELECT 'panel_without_global_club_roles',r.role_name,count(DISTINCT u.user_id)::text
FROM users u
JOIN club_role_assignments cra ON cra.user_id=u.user_id AND cra.active
JOIN roles r ON r.role_id=cra.role_id
WHERE u.active AND coalesce(u.access_panel,false)
  AND NOT EXISTS (
    SELECT 1 FROM users_roles ur2 JOIN roles r2 ON r2.role_id=ur2.role_id
    WHERE ur2.user_id=u.user_id AND ur2.active AND r2.role_category::text='GLOBAL'
  )
GROUP BY r.role_name
ORDER BY r.role_name;

\echo 'ROLE_SLOT_TRIGGER'
SELECT tgname,tgenabled::text
FROM pg_trigger
WHERE tgrelid='club_role_assignments'::regclass AND NOT tgisinternal
ORDER BY tgname;

\echo 'ROLE_SLOT_VIOLATION_DETAILS'
SELECT cs.club_section_id::text,ct.name,r.role_name,
       count(DISTINCT cra.user_id)::text,
       min(cra.start_date)::text,max(cra.start_date)::text,
       count(*) FILTER (WHERE cra.end_date IS NULL)::text
FROM club_role_assignments cra
JOIN club_sections cs ON cs.club_section_id=cra.club_section_id
JOIN club_types ct ON ct.club_type_id=cs.club_type_id
JOIN roles r ON r.role_id=cra.role_id
JOIN role_slot_limits rsl ON rsl.role_id=r.role_id
JOIN ecclesiastical_years ey ON ey.year_id=cra.ecclesiastical_year_id
WHERE cra.active AND coalesce(cra.status,'active')='active'
  AND current_date BETWEEN ey.start_date AND ey.end_date
  AND current_date BETWEEN cra.start_date AND coalesce(cra.end_date,current_date)
GROUP BY cs.club_section_id,ct.name,r.role_name,rsl.max_per_section
HAVING count(DISTINCT cra.user_id)>rsl.max_per_section
ORDER BY cs.club_section_id,r.role_name;

\echo 'ACTIVE_ASSIGNED_WITHOUT_CLASS_BY_ROLE'
WITH current_year AS (
  SELECT year_id FROM ecclesiastical_years
  WHERE current_date BETWEEN start_date AND end_date
  ORDER BY start_date DESC LIMIT 1
), no_class AS (
  SELECT DISTINCT cra.user_id
  FROM club_role_assignments cra,current_year cy
  WHERE cra.ecclesiastical_year_id=cy.year_id
    AND cra.active AND coalesce(cra.status,'active')='active'
    AND NOT EXISTS (
      SELECT 1 FROM enrollments e
      WHERE e.user_id=cra.user_id AND e.ecclesiastical_year_id=cy.year_id AND e.active
    )
)
SELECT r.role_name,count(DISTINCT cra.user_id)::text
FROM no_class nc
JOIN club_role_assignments cra ON cra.user_id=nc.user_id AND cra.active
JOIN roles r ON r.role_id=cra.role_id
JOIN current_year cy ON cy.year_id=cra.ecclesiastical_year_id
GROUP BY r.role_name
ORDER BY r.role_name;

\echo 'ACTIVE_ENROLLMENTS_IN_INACTIVE_CLASSES'
SELECT c.class_id::text,c.name,ct.name,count(*)::text
FROM enrollments e
JOIN classes c ON c.class_id=e.class_id
JOIN club_types ct ON ct.club_type_id=c.club_type_id
WHERE e.active AND NOT c.active
GROUP BY c.class_id,c.name,ct.name
ORDER BY c.class_id;

\echo 'ACTIVE_CLUB_INVALID_PARENT'
SELECT c.club_id::text,c.name,
       d.name,d.active::text,ch.name,ch.active::text,lf.name,lf.active::text,
       (d.local_field_id=c.local_field_id)::text,
       (ch.districlub_type_id=c.districlub_type_id)::text
FROM clubs c
JOIN districts d ON d.districlub_type_id=c.districlub_type_id
JOIN churches ch ON ch.church_id=c.church_id
JOIN local_fields lf ON lf.local_field_id=c.local_field_id
WHERE c.active AND (
  NOT d.active OR NOT ch.active OR NOT lf.active
  OR d.local_field_id<>c.local_field_id
  OR ch.districlub_type_id<>c.districlub_type_id
)
ORDER BY c.club_id;

\echo 'RANKING_TEMPLATE_COVERAGE_BY_ACTIVE_TYPE'
WITH current_year AS (
  SELECT year_id FROM ecclesiastical_years
  WHERE current_date BETWEEN start_date AND end_date
  ORDER BY start_date DESC LIMIT 1
), active_types AS (
  SELECT DISTINCT cs.club_type_id,c.local_field_id,lf.union_id
  FROM club_sections cs
  JOIN clubs c ON c.club_id=cs.main_club_id
  JOIN local_fields lf ON lf.local_field_id=c.local_field_id
  WHERE cs.active AND c.active
)
SELECT ct.name,
       EXISTS (
         SELECT 1 FROM folder_templates ft,current_year cy
         WHERE ft.club_type_id=at.club_type_id AND ft.ecclesiastical_year_id=cy.year_id
           AND ft.active AND ft.status::text='PUBLISHED'
           AND (ft.owner_local_field_id=at.local_field_id OR ft.owner_union_id=at.union_id)
       )::text,
       EXISTS (
         SELECT 1 FROM annual_ranking_configs arc,current_year cy
         WHERE arc.club_type_id=at.club_type_id AND arc.ecclesiastical_year_id=cy.year_id
           AND arc.active
           AND (arc.local_field_id=at.local_field_id OR arc.union_id=at.union_id)
       )::text
FROM active_types at JOIN club_types ct ON ct.club_type_id=at.club_type_id
ORDER BY ct.club_type_id;

\echo 'MIGRATION_ROLLBACKS'
SELECT migration_name,rolled_back_at::text,applied_steps_count::text
FROM _prisma_migrations
WHERE rolled_back_at IS NOT NULL
ORDER BY started_at;

ROLLBACK;
