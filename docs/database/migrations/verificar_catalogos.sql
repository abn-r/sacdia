-- ============================================================================
-- SCRIPT DE VERIFICACIÓN: Conteo de registros en catálogos
-- ============================================================================
-- Ejecuta este script para ver qué tablas tienen datos

SELECT 
  'countries' as tabla, 
  COUNT(*) as registros,
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END as estado
FROM countries

UNION ALL

SELECT 'unions', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM unions

UNION ALL

SELECT 'local_fields', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM local_fields

UNION ALL

SELECT 'districts', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM districts

UNION ALL

SELECT 'churches', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM churches

UNION ALL

SELECT 'club_types', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM club_types

UNION ALL

SELECT 'classes', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM classes

UNION ALL

SELECT 'class_modules', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM class_modules

UNION ALL

SELECT 'class_sections', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM class_sections

UNION ALL

SELECT 'honors_categories', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM honors_categories

UNION ALL

SELECT 'master_honors', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM master_honors

UNION ALL

SELECT 'honors', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM honors

UNION ALL

SELECT 'allergies', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM allergies

UNION ALL

SELECT 'diseases', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM diseases

UNION ALL

SELECT 'medicines', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM medicines

UNION ALL

SELECT 'relationship_type', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM relationship_type

UNION ALL

SELECT 'finances_categories', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM finances_categories

UNION ALL

SELECT 'permissions', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM permissions

UNION ALL

SELECT 'roles', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM roles

UNION ALL

SELECT 'role_permissions', COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '✓ Tiene datos' ELSE '✗ VACÍA' END
FROM role_permissions

ORDER BY tabla;
