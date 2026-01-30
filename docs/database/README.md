# Database Documentation - SACDIA

Guía completa de la base de datos PostgreSQL del sistema SACDIA.

---

## 📋 Índice

1. [Schema Overview](#schema-overview)
2. [Archivos Principales](#archivos-principales)
3. [Cómo Usar Prisma](#cómo-usar-prisma)
4. [Migraciones](#migraciones)
5. [Naming Conventions](#naming-conventions)

---

## Schema Overview

La base de datos está diseñada con las siguientes características:

- **PostgreSQL 15.x** en Supabase
- **Prisma ORM** como abstracción
- **UUIDs** para todas las tablas principales
- **Soft deletes** mediante campo `active`
- **Timestamps** automáticos (`created_at`, `updated_at`)
- **Constraints** para integridad de datos

### Módulos Principales

```
📦 Database Schema
├── 👤 Users & Auth
│   ├── users
│   ├── users_pr (post-registro)
│   ├── users_roles
│   ├── legal_representatives
│   └── emergency_contacts
│
├── 🏛️ Organization
│   ├── countries
│   ├── unions
│   ├── local_fields
│   ├── districts
│   └── churches
│
├── 🏕️ Clubs
│   ├── clubs (contenedor)
│   ├── club_adventurers
│   ├── club_pathfinders
│   ├── club_master_guild
│   └── club_role_assignments
│
├── 📚 Classes & Honors
│   ├── classes
│   ├── class_modules
│   ├── class_sections
│   ├── honors
│   ├── honors_categories
│   └── master_honors
│
├── 🔐 RBAC
│   ├── roles
│   ├── permissions
│   ├── role_permissions
│   └── users_permissions
│
└── 📊 Catalogs
    ├── club_types
    ├── relationship_types
    ├── allergies
    ├── diseases
    └── ecclesiastical_years
```

---

## Archivos Principales

| Archivo | Descripción |
|---------|-------------|
| [schema.prisma](schema.prisma) | **Schema definitivo de Prisma** - Fuente de verdad |
| [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md) | Referencia completa: tablas, relaciones, naming conventions |
| [migrations/](migrations/) | Scripts SQL de migración e inicialización |
| [examples/](examples/) | Ejemplos de respuestas JSON de la API |

---

## Cómo Usar Prisma

### Instalación
```bash
cd sacdia-backend
npm install @prisma/client prisma
```

### Comandos Útiles

#### Ver/Editar datos en GUI
```bash
npx prisma studio
```

#### Generar cliente Prisma
```bash
npx prisma generate
```

#### Crear migración
```bash
npx prisma migrate dev --name descripcion_del_cambio
```

#### Aplicar migraciones a producción
```bash
npx prisma migrate deploy
```

#### Resetear base de datos (⚠️ DESARROLLO)
```bash
npx prisma migrate reset
```

#### Validar schema
```bash
npx prisma validate
```

#### Format schema
```bash
npx prisma format
```

---

## Migraciones

### Estructura de Migraciones

Los scripts SQL están en [`migrations/`](migrations/):

```
migrations/
├── README.md                        # Guía de uso
├── script_01_organizacion.sql       # Setup países/uniones/campos
├── script_02_clubes_clases.sql      # Clubes y clases progresivas
├── script_03_especialidades.sql     # Honores y categorías
├── script_04_catalogos_medicos.sql  # Alergias y enfermedades
├── script_05_roles_permisos.sql     # Sistema RBAC
└── verificar_catalogos.sql          # Queries de verificación
```

### Ejecutar Migración Manualmente

**Opción 1: Desde `psql`**
```bash
psql -U postgres -d sacdia -f migrations/script_01_organizacion.sql
```

**Opción 2: Desde Supabase Dashboard**
1. Ve a SQL Editor
2. Copia contenido del script
3. Ejecuta

**Opción 3: Desde Prisma**
```bash
npx prisma db execute --file migrations/script_01_organizacion.sql
```

### Orden de Ejecución

Ejecutar en este orden para evitar errores de FK:
1. `script_01_organizacion.sql` - Estructura organizacional
2. `script_02_clubes_clases.sql` - Clubes y clases
3. `script_03_especialidades.sql` - Honores
4. `script_04_catalogos_medicos.sql` - Catálogos médicos
5. `script_05_roles_permisos.sql` - Roles y permisos

---

## Naming Conventions

### Tablas
- ✅ **Plural**: `users`, `clubs`, `classes`
- ✅ **Snake case**: `emergency_contacts`, `club_role_assignments`
- ✅ **Descriptivo**: `legal_representatives` (no `legal_reps`)

### Campos
- ✅ **Snake case**: `paternal_last_name`, `created_at`
- ✅ **Descriptivo**: `paternal_last_name` (no `p_lastname`)
- ✅ **IDs explícitos**: `user_id`, `club_type_id` (no `uid`, `ct_id`)

### Convenciones de ID
- **Tablas principales**: `{tabla}_id` UUID (ej: `user_id`, `club_id`)
- **Tablas pivote**: `id` UUID como PK, FKs con nombres descriptivos
- **Excepciones**: Instancias de club usan INT (`club_adv_id`, `club_pathf_id`, `club_mg_id`)

**Ver detalles**: [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md#convenciones-de-naming)

---

## Relaciones Clave

### Jerarquía Organizacional
```
countries (1) ──→ (N) unions
unions (1) ──→ (N) local_fields
local_fields (1) ──→ (N) districts
districts (1) ──→ (N) churches
churches (1) ──→ (N) clubs
```

### Club Instances
```
clubs (1) ──→ (N) club_adventurers
clubs (1) ──→ (N) club_pathfinders
clubs (1) ──→ (N) club_master_guild
```

### RBAC
```
users (N) ←──→ (N) roles          [via users_roles]
users (N) ←──→ (N) permissions    [via users_permissions]
roles (N) ←──→ (N) permissions    [via role_permissions]

users (N) ──→ (N) club instances  [via club_role_assignments]
```

**Ver diagrama completo**: [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md#diagrama-de-relaciones-principales)

---

## Consultas Útiles

### Ver roles de un usuario
```sql
SELECT r.role_name, r.role_category
FROM users_roles ur
JOIN roles r ON r.id = ur.role_id
WHERE ur.user_id = 'uuid-del-usuario';
```

### Ver miembros de un club
```sql
SELECT u.name, u.paternal_last_name, r.role_name
FROM club_role_assignments cra
JOIN users u ON u.id = cra.user_id
JOIN roles r ON r.id = cra.role_id
WHERE cra.club_pathf_id = 123
  AND cra.active = true;
```

**Más queries**: [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md#queries-útiles)

---

## Próximos Pasos

1. **Explorar schema**: Abre [schema.prisma](schema.prisma)
2. **Ver relaciones**: Lee [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md)
3. **Ejecutar migraciones**: Sigue [migrations/README.md](migrations/README.md)
4. **Usar Prisma**: `npx prisma studio`

---

**Ver también**:
- [API Specification](../api/API-SPECIFICATION.md) - Cómo la API usa estos modelos
- [Architecture Decisions](../api/ARCHITECTURE-DECISIONS.md) - Por qué se tomaron ciertas decisiones
