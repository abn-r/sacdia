# Schema Reference - SACDIA Database

Referencia completa del schema de base de datos PostgreSQL de SACDIA.

---

## Diagrama ER Principal

```mermaid
graph TB
    subgraph "Jerarquía Organizacional"
        COUNTRIES[countries]
        UNIONS[unions]
        LF[local_fields]
        DISTRICTS[districts]
        CHURCHES[churches]
        
        COUNTRIES --> UNIONS
        UNIONS --> LF
        LF --> DISTRICTS
        DISTRICTS --> CHURCHES
    end
    
    subgraph "Clubs"
        CLUBS[clubs]
        ADV[club_adventurers]
        PATH[club_pathfinders]
        MG[club_master_guild]
        
        CHURCHES --> CLUBS
        CLUBS --> ADV
        CLUBS --> PATH
        CLUBS --> MG
    end
    
    subgraph "Users & Auth"
        USERS[users]
        USERS_PR[users_pr]
        LEGAL_REP[legal_representatives]
        EMERG[emergency_contacts]
        
        USERS --> USERS_PR
        USERS --> LEGAL_REP
        USERS --> EMERG
    end
    
    subgraph "RBAC"
        ROLES[roles]
        PERMS[permissions]
        USERS_ROLES[users_roles]
        ROLE_PERMS[role_permissions]
        CLUB_ROLES[club_role_assignments]
        
        USERS --> USERS_ROLES
        USERS_ROLES --> ROLES
        ROLES --> ROLE_PERMS
        ROLE_PERMS --> PERMS
        
        USERS --> CLUB_ROLES
        CLUB_ROLES --> ROLES
        CLUB_ROLES --> ADV
        CLUB_ROLES --> PATH
        CLUB_ROLES --> MG
    end
    
    subgraph "Classes & Honors"
        CLASSES[classes]
        HONORS[honors]
        USERS_CLASSES[users_classes]
        USERS_HONORS[users_honors]
        
        USERS --> USERS_CLASSES
        USERS_CLASSES --> CLASSES
        USERS --> USERS_HONORS
        USERS_HONORS --> HONORS
    end
```

---

## Tablas Principales

### 📦 Módulo: Users & Authentication

#### Tabla: `users`
**Descripción**: Tabla principal de usuarios del sistema

**Campos**:
| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | UUID | ID único (mismo que Supabase Auth) | PK |
| `email` | VARCHAR(255) | Email del usuario | UNIQUE, NOT NULL |
| `name` | VARCHAR(100) | Nombre | NOT NULL |
| `paternal_last_name` | VARCHAR(100) | Apellido paterno | NOT NULL |
| `maternal_last_name` | VARCHAR(100) | Apellido materno | NOT NULL |
| `gender` | CHAR(1) | Género (M/F) | CHECK IN ('M','F') |
| `birthdate` | DATE | Fecha de nacimiento | - |
| `is_baptized` | BOOLEAN | ¿Está bautizado? | - |
| `baptism_date` | DATE | Fecha de bautismo | - |
| `country_id` | UUID | País | FK → countries |
| `union_id` | UUID | Unión | FK → unions |
| `local_field_id` | UUID | Campo local | FK → local_fields |
| `avatar` | TEXT | URL de foto de perfil | - |
| `active` | BOOLEAN | Usuario activo | DEFAULT true |
| `created_at` | TIMESTAMP | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Última actualización | DEFAULT NOW() |

**Relaciones**:
- One-to-One: `users_pr`, `legal_representatives`
- One-to-Many: `emergency_contacts`, `club_role_assignments`, `users_classes`, `users_honors`
- Many-to-Many: `roles` (via `users_roles`), `allergies` (via `users_allergies`), `diseases` (via `users_diseases`), `medicines` (via `users_medicines`)

**Naming Convention**: ✅ Cumple - Nombres descriptivos (`paternal_last_name` vs `p_lastname`)

---

#### Tabla: `users_pr`
**Descripción**: Tracking de post-registro (onboarding)

**Campos**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `user_id` | UUID | Usuario | PK, FK → users |
| `complete` | BOOLEAN | Post-registro completo | DEFAULT false |
| `profile_picture_complete` | BOOLEAN | Paso 1: Foto | DEFAULT false |
| `personal_info_complete` | BOOLEAN | Paso 2: Info personal | DEFAULT false |
| `club_selection_complete` | BOOLEAN | Paso 3: Club | DEFAULT false |
| `created_at` | TIMESTAMP | Fecha creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Última actualización | DEFAULT NOW() |

**Flujo**:
1. Registro → Crea registro con todo en `false`
2. Paso 1 → `profile_picture_complete = true`
3. Paso 2 → `personal_info_complete = true`
4. Paso 3 → `club_selection_complete = true` AND `complete = true`

---

#### Tabla: `legal_representatives`
**Descripción**: Representantes legales para menores de 18 años

**Campos**:
| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | UUID | ID único | PK |
| `user_id` | UUID | Usuario menor | FK → users, UNIQUE |
| `representative_user_id` | UUID | Usuario representante (si está registrado) | FK → users, NULL |
| `name` | VARCHAR(100) | Nombre (si no es usuario) | NULL |
| `paternal_last_name` | VARCHAR(100) | Apellido paterno | NULL |
| `maternal_last_name` | VARCHAR(100) | Apellido materno | NULL |
| `phone` | VARCHAR(20) | Teléfono | NULL |
| `relationship_type_id` | UUID | Tipo de relación | FK → relationship_types |

**Constraint CHECK**:
```sql
-- Debe tener O un usuario registrado O datos manuales
(representative_user_id IS NOT NULL) OR 
(name IS NOT NULL AND paternal_last_name IS NOT NULL AND phone IS NOT NULL)
```

---

#### Tabla: `emergency_contacts`
**Descripción**: Contactos de emergencia (máximo 5 por usuario)

**Campos**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | ID único | PK |
| `user_id` | UUID | Usuario | FK → users |
| `name` | VARCHAR(100) | Nombre del contacto | NOT NULL |
| `phone` | VARCHAR(20) | Teléfono | NOT NULL |
| `relationship_type_id` | UUID | Relación (padre, madre, etc.) | FK → relationship_types |

**Validación**: Trigger limita a máximo 5 contactos por usuario

---

### 🌍 Módulo: Jerarquía Organizacional

La jerarquía geográfica sigue este patrón:

```
Country → Union → Local Field → District → Church → Club
```

#### Tabla: `countries`
**Campos**: `id` (UUID), `name`, `abbreviation`, `active`, timestamps

#### Tabla: `unions`
**Campos**: `id` (UUID), `country_id` (FK), `name`, `abbreviation`, `active`, timestamps  
**Relación**: Many-to-One con `countries`

#### Tabla: `local_fields`
**Campos**: `id` (UUID), `union_id` (FK), `name`, `abbreviation`, `active`, timestamps  
**Relación**: Many-to-One con `unions`

#### Tabla: `districts`
**Campos**: `id` (UUID), `local_field_id` (FK), `name`, `active`, timestamps  
**Relación**: Many-to-One con `local_fields`

#### Tabla: `churches`
**Campos**: `id` (UUID), `district_id` (FK), `name`, `address`, `active`, timestamps  
**Relación**: Many-to-One con `districts`

---

### 🏕️ Módulo: Clubs

#### Tabla: `clubs`
**Descripción**: Club contenedor (una iglesia tiene 1 club principal)

**Campos**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | ID único | PK |
| `church_id` | UUID | Iglesia | FK → churches |
| `name` | VARCHAR(100) | Nombre del club | NOT NULL |
| `active` | BOOLEAN | Club activo | DEFAULT true |

**Relación**: Un club puede tener múltiples instancias por tipo

---

#### Tablas: `club_adventurers`, `club_pathfinders`, `club_master_guild`
**Descripción**: Instancias específicas de club por tipo

**Campos comunes**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INT | ID único | PK, AUTO_INCREMENT |
| `main_club_id` | UUID | Club contenedor | FK → clubs |
| `club_type_id` | UUID | Tipo de club | FK → club_types |
| `name` | VARCHAR(100) | Nombre de la instancia | - |
| `active` | BOOLEAN | Instancia activa | DEFAULT true |

**Naming Convention**: ✅ Se recomienda plural (`club_master_guilds`), pendiente de aplicar

---

#### Tabla: `club_role_assignments`
**Descripción**: Asignación de roles a usuarios en instancias específicas de club

**Campos**:
| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | UUID | ID único | PK |
| `user_id` | UUID | Usuario | FK → users |
| `role_id` | UUID | Rol (debe ser `role_category = 'CLUB'`) | FK → roles |
| `club_adv_id` | INT | Instancia Aventureros | FK → club_adventurers, NULL |
| `club_pathf_id` | INT | Instancia Conquistadores | FK → club_pathfinders, NULL |
| `club_mg_id` | INT | Instancia Guías Mayores | FK → club_master_guild, NULL |
| `ecclesiastical_year_id` | INT | Año eclesiástico | FK → ecclesiastical_years |
| `start_date` | DATE | Fecha inicio | DEFAULT CURRENT_DATE |
| `end_date` | DATE | Fecha fin | NULL |
| `active` | BOOLEAN | Asignación activa | DEFAULT true |
| `status` | VARCHAR(20) | Estado (pending/active/inactive) | CHECK |

**Constraint CHECK**: Solo UNO de los 3 club IDs puede tener valor:
```sql
(club_adv_id IS NOT NULL)::int + 
(club_pathf_id IS NOT NULL)::int + 
(club_mg_id IS NOT NULL)::int = 1
```

**Constraint UNIQUE**:
```sql
UNIQUE NULLS NOT DISTINCT (
  user_id, role_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id
)
```

---

### 🔐 Módulo: RBAC (Roles y Permisos)

#### Tabla: `roles`
**Descripción**: Roles del sistema (globales y de club)

**Campos**:
| Campo | Tipo | Descripción | Valores |
|-------|------|-------------|----------|
| `id` | UUID | ID único | PK |
| `role_name` | VARCHAR(50) | Nombre del rol | UNIQUE |
| `role_category` | VARCHAR(10) | Categoría | 'GLOBAL' o 'CLUB' |
| `description` | TEXT | Descripción | - |
| `active` | BOOLEAN | Rol activo | DEFAULT true |

**Roles Globales** (`role_category = 'GLOBAL'`):
- `super_admin`, `admin`, `coordinator`, `user`

**Roles de Club** (`role_category = 'CLUB'`):
- `director`, `subdirector`, `secretary`, `treasurer`, `counselor`, `member`

---

#### Tabla: `permissions`
**Campos**: `id` (UUID), `permission_name` (ej: `CREATE:USERS`), `description`, `active`

#### Tabla: `role_permissions`
**Descripción**: Tabla pivote Many-to-Many entre `roles` y `permissions`

#### Tabla: `users_roles`
**Descripción**: Asignación de roles GLOBALES a usuarios  
**Campos**: `id`, `user_id`, `role_id`, `assigned_at`

---

### 📚 Módulo: Classes & Honors

#### Tabla: `classes`
**Descripción**: Clases progresivas (Amigo, Compañero, Explorador, etc.)

**Campos**: `id` (UUID), `name`, `club_type_id`, `order`, `active`

#### Tabla: `honors`
**Descripción**: Especialidades

**Campos**: `id` (UUID), `name`, `honors_category_id`, `club_type_id`, `difficulty`, `active`

#### Tabla: `users_classes`
**Descripción**: Inscripción de usuarios a clases

**Campos**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | ID único |
| `user_id` | UUID | Usuario |
| `class_id` | UUID | Clase |
| `current_class` | BOOLEAN | ¿Es su clase actual? |
| `investiture` | BOOLEAN | Investido |
| `date_investiture` | DATE | Fecha de investidura |
| `certificate` | TEXT | URL del certificado |

---

## Convenciones de Naming

### ✅ Estándares Aplicados

#### Tablas
- **Plural**: `users`, `clubs`, `classes`, `permissions`
- **Snake case**: `emergency_contacts`, `club_role_assignments`
- **Descriptivo**: `legal_representatives` (no `legal_reps`)

#### Campos
- **Snake case**: `paternal_last_name`, `created_at`
- **Descriptivo**: `paternal_last_name` (no `p_lastname`)
- **IDs explícitos**: `user_id`, `club_type_id` (no `uid`, `ct_id`)

#### IDs
- **Tablas principales**: `{tabla}_id` UUID
- **Tablas pivote**: `id` UUID como PK, FKs descriptivos
- **Instancias de club**: INT (`club_adv_id`, `club_pathf_id`, `club_mg_id`)

---

### ⚠️ Inconsistencias Detectadas (Pendientes)

| Tabla/Campo | Actual | Debería ser | Prioridad |
|-------------|--------|-------------|-----------|
| `ecclesiastical_year` | Singular | `ecclesiastical_years` | ALTA |
| `club_master_guild` | Singular | `club_master_guilds` | MEDIA |
| `club_types.ct_id` | Abreviado | `club_type_id` | ALTA |
| `inventory_categories.inventory_categoty_id` | Typo | `inventory_category_id` | ALTA |

**Ver detalles completos**: Ver documentos originales en carpeta raíz de database/

---

## Queries Útiles

### Obtener roles de un usuario (globales y de club)

```sql
-- Roles globales
SELECT r.role_name, r.role_category
FROM users_roles ur
JOIN roles r ON r.id = ur.role_id
WHERE ur.user_id = 'uuid-del-usuario';

-- Roles de club
SELECT 
  r.role_name,
  CASE 
    WHEN cra.club_adv_id IS NOT NULL THEN 'Aventureros'
    WHEN cra.club_pathf_id IS NOT NULL THEN 'Conquistadores'
    WHEN cra.club_mg_id IS NOT NULL THEN 'Guías Mayores'
  END AS club_type,
  ey.name AS year
FROM club_role_assignments cra
JOIN roles r ON r.id = cra.role_id
JOIN ecclesiastical_years ey ON ey.id = cra.ecclesiastical_year_id
WHERE cra.user_id = 'uuid-del-usuario'
  AND cra.active = true;
```

### Obtener miembros activos de un club

```sql
SELECT 
  u.name,
  u.paternal_last_name,
  u.maternal_last_name,
  r.role_name,
  cra.start_date
FROM club_role_assignments cra
JOIN users u ON u.id = cra.user_id
JOIN roles r ON r.id = cra.role_id
WHERE cra.club_pathf_id = 123  -- ID de instancia
  AND cra.active = true
ORDER BY 
  CASE r.role_name
    WHEN 'director' THEN 1
    WHEN 'subdirector' THEN 2
    WHEN 'secretary' THEN 3
    ELSE 4
  END;
```

### Verificar año eclesiástico actual

```sql
SELECT id, name, start_date, end_date
FROM ecclesiastical_years
WHERE start_date <= CURRENT_DATE
  AND end_date >= CURRENT_DATE;
```

### Contar usuarios por tipo de club

```sql
SELECT 
  CASE 
    WHEN cra.club_adv_id IS NOT NULL THEN 'Aventureros'
    WHEN cra.club_pathf_id IS NOT NULL THEN 'Conquistadores'
    WHEN cra.club_mg_id IS NOT NULL THEN 'Guías Mayores'
  END AS club_type,
  COUNT(DISTINCT cra.user_id) AS member_count
FROM club_role_assignments cra
WHERE cra.active = true
GROUP BY club_type;
```

---

## Índices Recomendados

```sql
-- Performance en búsquedas de usuarios
CREATE INDEX idx_users_email ON users(email) WHERE active = true;
CREATE INDEX idx_users_location ON users(country_id, union_id, local_field_id);

-- Performance en club_role_assignments
CREATE INDEX idx_cra_user ON club_role_assignments(user_id) WHERE active = true;
CREATE INDEX idx_cra_clubs ON club_role_assignments(club_adv_id, club_pathf_id, club_mg_id);
CREATE INDEX idx_cra_year ON club_role_assignments(ecclesiastical_year_id);

-- Performance en jerarquía organizacional
CREATE INDEX idx_unions_country ON unions(country_id) WHERE active = true;
CREATE INDEX idx_lf_union ON local_fields(union_id) WHERE active = true;
CREATE INDEX idx_districts_lf ON districts(local_field_id) WHERE active = true;
CREATE INDEX idx_churches_district ON churches(district_id) WHERE active = true;
```

---

## Ver También

- [schema.prisma](schema.prisma) - Schema Prisma definitivo
- [migrations/](migrations/) - Scripts SQL de migración  
- [README.md](README.md) - Guía de base de datos
- [../02-API/API-SPECIFICATION.md](../02-API/API-SPECIFICATION.md) - Cómo la API usa estos modelos

---

**Última actualización**: 2026-01-30  
**Fuentes**: `relations.md`, `auditoria-naming-bd.md`, `verificacion-schema-prisma.md`
