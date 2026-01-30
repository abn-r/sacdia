# Auditoría de Naming Convention - Base de Datos SACDIA

**Fecha**: 29 de enero de 2026  
**Objetivo**: Estandarizar nombres de tablas y campos

---

## 📊 Análisis Actual

### Convenciones Detectadas

**Tablas**: Mix de singular y plural, snake_case
**Campos**: snake_case mayormente consistente
**IDs**: Mix de `tabla_id` y `id`

---

## ❌ Inconsistencias Críticas

### 1. Plural vs Singular

#### Tablas PLURALES (mayoría)
```
✅ users                    (plural)
✅ activities               (plural)
✅ churches                 (plural)
✅ classes                  (plural)
✅ countries                (plural)
✅ districts                (plural)
✅ clubs                    (plural)
✅ honors                   (plural)
✅ unions                   (plural)
✅ roles                    (plural)
✅ permissions              (plural)
✅ units                    (plural)
✅ medicines                (plural)
✅ diseases                 (plural)
✅ allergies                (plural)
```

#### Tablas SINGULARES (minoría)
```
❌ ecclesiastical_year      (singular) → debería: ecclesiastical_years
❌ club_master_guild        (singular) → debería: club_master_guilds
❌ relationship_type        (singular) → debería: relationship_types ✅ YA EXISTE
```

#### ⚠️ CONFLICTO DETECTADO
Existen **DOS** tablas de relaciones:
- `relationship_type` (singular, Int ID) - **ANTIGUA**
- `relationship_types` (plural, UUID ID) - **NUEVA V2**

**Decisión requerida**: Eliminar `relationship_type` antigua

---

### 2. Nombres de Tablas Compuestos

#### Inconsistencia: `club_` prefix

```
✅ club_types               (plural, tabla de referencia)
✅ club_ideals              (plural)
✅ club_inventory           (singular implícito, colección)
✅ clubs                    (plural, tabla principal)

❌ club_adventurers         (plural) → OK
❌ club_pathfinders         (plural) → OK
❌ club_master_guild        (singular) → debería: club_master_guilds
```

**Propuesta**: Todas las instancias de club deben ser plural

---

### 3. Tablas de Unión (Junction Tables)

#### Convención actual: `tabla1_tabla2s`

```
✅ users_allergies          (user + allergies)
✅ users_diseases           (user + diseases)
✅ users_classes            (user + classes)
✅ users_honors             (user + honors)
✅ users_permissions        (user + permissions)
✅ users_roles              (user + roles)
✅ users_certifications     (user + certifications)

✅ class_module_progress
✅ class_section_progress
✅ certification_module_progress
✅ certification_section_progress

✅ role_permissions         (role + permissions)

❌ assignments_folders      (folders assignments?) → debería: folder_assignments
❌ attending_clubs_camporees → debería: camporee_clubs
❌ attending_members_camporees → debería: camporee_members
```

**Propuesta**: Estandarizar a `entidad_principal_entidad_relacionada`

---

### 4. Nombres de Campos ID

#### Inconsistencias

```
✅ user_id                  (consistente)
✅ role_id                  (consistente)
✅ club_type_id             (consistente)

❌ ct_id                    (en club_types) → debería: club_type_id
❌ year_id                  (en ecclesiastical_year) → debería: ecclesiastical_year_id

VARIACIONES:
- club_adv_id               (adventurers)
- club_pathf_id             (pathfinders)
- club_mg_id                (master guild)
```

**Propuesta**: Usar nombre completo de tabla + `_id`

---

### 5. Tablas de Categorías

```
✅ finances_categories      (plural)
✅ honors_categories        (plural)
✅ inventory_categories     (plural)
✅ club_types               (plural)
```

**Consistente** ✅

---

### 6. Tablas de Progreso/Historial

```
✅ class_module_progress
✅ class_section_progress
✅ certification_module_progress
✅ certification_section_progress
✅ investiture_validation_history
✅ weekly_records
```

**Consistente** ✅

---

## ✅ Cambios Propuestos

### CRÍTICOS (Afectan funcionalidad)

#### 1. Eliminar tabla duplicada `relationship_type`
```sql
-- Esta tabla usa Int ID y conflictúa con relationship_types (UUID)
DROP TABLE relationship_type CASCADE;

-- Migrar relaciones de emergency_contacts a relationship_types
-- (requiere seed de datos)
```

#### 2. Renombrar `ecclesiastical_year` → `ecclesiastical_years`
```sql
ALTER TABLE ecclesiastical_year RENAME TO ecclesiastical_years;

-- Actualizar referencias (muchas tablas)
```

#### 3. Renombrar `club_master_guild` → `club_master_guilds`
```sql
ALTER TABLE club_master_guild RENAME TO club_master_guilds;

-- Actualizar foreign keys
```

---

### RECOMENDADOS (Mejor consistencia)

#### 4. Renombrar tabla de IDs abreviados

**`club_types.ct_id` → `club_types.club_type_id`**
```sql
ALTER TABLE club_types RENAME COLUMN ct_id TO club_type_id;

-- Actualizar ~20 foreign keys
```

---

#### 5. Renombrar tablas de junction

**`assignments_folders` → `folder_assignments`**
```sql
ALTER TABLE assignments_folders RENAME TO folder_assignments;
ALTER TABLE folder_assignments RENAME COLUMN assignment_folder_id TO folder_assignment_id;
```

**`attending_clubs_camporees` → `camporee_clubs`**
```sql
ALTER TABLE attending_clubs_camporees RENAME TO camporee_clubs;
ALTER TABLE camporee_clubs RENAME COLUMN attending_clubs_id TO camporee_club_id;
```

**`attending_members_camporees` → `camporee_members`**
```sql
ALTER TABLE attending_members_camporees RENAME TO camporee_members;
ALTER TABLE camporee_members RENAME COLUMN attending_members_id TO camporee_member_id;
```

---

#### 6. Typo en `inventory_categories`

**`inventory_categoty_id` → `inventory_category_id`**
```sql
ALTER TABLE inventory_categories 
RENAME COLUMN inventory_categoty_id TO inventory_category_id;
```

---

### OPCIONALES (Nice to have)

#### 7. Consistencia en nombres de instancias de club

Actualmente:
- `club_adv_id` (adventurers)
- `club_pathf_id` (pathfinders)  
- `club_mg_id` (master guild)

**Opción A**: Mantener abreviaciones (más corto)
**Opción B**: Nombres completos (más claro)
```
- club_adventurers_id
- club_pathfinders_id
- club_master_guilds_id
```

---

## 📋 Resumen de Cambios

### Nivel 1: CRÍTICOS (Recomiendo aplicar)

| # | Tipo | Cambio | Impacto |
|---|---|---|---|
| 1 | DROP | `relationship_type` → eliminar | Alto - Conflicto UUID/Int |
| 2 | RENAME | `ecclesiastical_year` → `ecclesiastical_years` | Alto - Muchas FKs |
| 3 | RENAME | `club_master_guild` → `club_master_guilds` | Medio - Consistencia |
| 4 | RENAME | `ct_id` → `club_type_id` | Alto - Muchas FKs |
| 5 | FIX | `inventory_categoty_id` → `inventory_category_id` | Bajo - Typo |

### Nivel 2: RECOMENDADOS (Opcional)

| # | Tipo | Cambio | Impacto |
|---|---|---|---|
| 6 | RENAME | `assignments_folders` → `folder_assignments` | Bajo - Mejor semántica |
| 7 | RENAME | `attending_clubs_camporees` → `camporee_clubs` | Bajo - Mejor semántica |
| 8 | RENAME | `attending_members_camporees` → `camporee_members` | Bajo - Mejor semántica |

### Nivel 3: DISCUTIBLE

| # | Tipo | Cambio | Razón |
|---|---|---|---|
| 9 | RENAME | `club_adv_id` → `club_adventurers_id` | Más descriptivo vs más corto |

---

## 🎯 Recomendación Final

### Aplicar AHORA (antes de datos)

✅ **Nivel 1: CRÍTICOS** (cambios 1-5)
- Eliminar `relationship_type` duplicada
- Renombrar tablas a plural
- Corregir IDs abreviados
- Fix typo

❓ **Nivel 2: RECOMENDADOS** (cambios 6-8)
- Decisión tuya, mejoran semántica pero no son críticos

❌ **Nivel 3: DISCUTIBLE** (cambio 9)
- NO recomiendo, las abreviaciones actuales funcionan

---

## 📝 Migration SQL (Nivel 1)

```sql
-- ========================================
-- MIGRATION: Estandarización de Naming
-- ========================================

BEGIN;

-- 1. Eliminar tabla duplicada relationship_type
-- ANTES: Migrar datos de emergency_contacts si es necesario
UPDATE emergency_contacts ec
SET relationship_type = (
  SELECT rt.relationship_type_id::int 
  FROM relationship_types rt 
  WHERE rt.name = (
    SELECT name FROM relationship_type 
    WHERE relationship_type_id = ec.relationship_type
  )
  LIMIT 1
)
WHERE EXISTS (SELECT 1 FROM relationship_type WHERE relationship_type_id = ec.relationship_type);

DROP TABLE IF EXISTS relationship_type CASCADE;

-- 2. Renombrar ecclesiastical_year → ecclesiastical_years
ALTER TABLE ecclesiastical_year RENAME TO ecclesiastical_years;

-- 3. Renombrar club_master_guild → club_master_guilds
ALTER TABLE club_master_guild RENAME TO club_master_guilds;

-- 4. Renombrar ct_id → club_type_id en club_types
ALTER TABLE club_types RENAME COLUMN ct_id TO club_type_id;

-- 5. Fix typo en inventory_categories
ALTER TABLE inventory_categories 
RENAME COLUMN inventory_categoty_id TO inventory_category_id;

COMMIT;
```

---

## ❓ Decisiones Requeridas

1. **¿Aplicar cambios de Nivel 1 (CRÍTICOS)?** → Recomendado: SÍ
2. **¿Aplicar cambios de Nivel 2 (RECOMENDADOS)?** → Tu decisión
3. **¿Aplicar cambios de Nivel 3 (DISCUTIBLE)?** → Recomendado: NO

---

**Generado**: 2026-01-29  
**Status**: Esperando aprobación de usuario
