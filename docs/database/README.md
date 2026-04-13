# Database Documentation - SACDIA

**Estado**: ACTIVE

Guía operativa de la base de datos PostgreSQL del sistema SACDIA.

> [!IMPORTANT]
> La fuente de verdad estructural efectiva del runtime es `sacdia-backend/prisma/schema.prisma`.
> `docs/database/schema.prisma` queda como espejo documental pendiente de resincronización mientras exista drift entre ambos archivos.
> `docs/database/SCHEMA-REFERENCE.md` es referencia humana subordinada y no debe usarse para arbitrar diferencias estructurales.

---

## 📋 Índice

1. [Schema Overview](#schema-overview)
2. [Archivos Principales](#archivos-principales)
3. [Cómo Usar Prisma](#cómo-usar-prisma)
4. [Migraciones](#migraciones)
5. [Naming Conventions](#naming-conventions)

---

## Schema Overview

La base de datos está diseñada con las siguientes características verificadas para este baseline:

- **PostgreSQL** como motor relacional operativo
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
│   ├── club_sections (secciones por tipo)
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
    ├── medicines
    └── ecclesiastical_years
```

---

## Archivos Principales

| Archivo | Descripción |
|---------|-------------|
| `sacdia-backend/prisma/schema.prisma` | **Schema efectivo del runtime** - fuente de verdad estructural mientras exista drift documental |
| [schema.prisma](schema.prisma) | Espejo documental del schema Prisma; requiere resincronización si difiere del backend |
| [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md) | Referencia humana subordinada: tablas, relaciones y naming conventions |
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
- **Excepciones**: Secciones de club usan INT (`club_section_id`)

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

### Club Sections
```
clubs (1) ──→ (N) club_sections (diferenciadas por club_type_id)
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

### Ver miembros de una sección de club
```sql
SELECT u.name, u.paternal_last_name, r.role_name
FROM club_role_assignments cra
JOIN users u ON u.id = cra.user_id
JOIN roles r ON r.id = cra.role_id
WHERE cra.club_section_id = 123
  AND cra.active = true;
```

**Más queries**: [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md#queries-útiles)

---

## Próximos Pasos

1. **Explorar schema vigente**: Abre `sacdia-backend/prisma/schema.prisma`
2. **Ver relaciones**: Lee [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md)
3. **Ejecutar migraciones**: Sigue [migrations/README.md](migrations/README.md)
4. **Usar Prisma**: `npx prisma studio`

---

**Ver también**:
- [API Specification](../02-API/API-SPECIFICATION.md) - Cómo la API usa estos modelos
- [Architecture Decisions](../02-API/ARCHITECTURE-DECISIONS.md) - Por qué se tomaron ciertas decisiones
