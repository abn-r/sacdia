# Database Migrations - SACDIA

Scripts SQL para inicialización y migración de la base de datos.

---

> [!IMPORTANT]
> Este README consolida la guía operativa principal y el contexto de backup/restore.
> La versión histórica anterior está en `docs/history/database/README_BACKUP.md`.

---

## 📋 Scripts Disponibles

| Script | Descripción | Dependencias |
|--------|-------------|--------------|
| `script_01_organizacion.sql` | Setup inicial de países, uniones, campos locales | Ninguna |
| `script_02_clubes_clases.sql` | Clubes y clases progresivas | script_01 |
| `script_03_especialidades.sql` | Honores y especialidades | script_01, script_02 |
| `script_04_catalogos_medicos.sql` | Alergias y enfermedades | Ninguna |
| `script_05_roles_permisos.sql` | Sistema RBAC (roles y permisos) | Ninguna |
| `script_06_admin_permissions.sql` | Permisos del Admin Panel (resource:action) | script_05 |
| `verificar_catalogos.sql` | Queries de verificación | Todos los anteriores |

### Scripts de Datos Semilla (Seed Data)
| Script | Descripción |
|--------|-------------|
| `countries.sql` | Lista de países |
| `unions.sql` | Uniones por país |
| `districts.sql` | Distritos por campo local |
| `local_fields.sql` | Campos locales por unión |

---

## 🚀 Cómo Ejecutar

### Orden de Ejecución Recomendado

**IMPORTANTE**: Ejecutar en este orden para evitar errores de foreign keys:

```bash
1. script_01_organizacion.sql       # Estructura organizacional básica
2. script_04_catalogos_medicos.sql  # Catálogos (sin dependencias)
3. script_05_roles_permisos.sql     # Sistema RBAC
4. script_02_clubes_clases.sql      # Clubes (depende de organizacion)
5. script_03_especialidades.sql     # Especialidades (depende de clubes)
6. verificar_catalogos.sql          # Verificación (opcional)
```

---

### Opción 1: Desde psql

```bash
# Conectarse a la base de datos
psql -U postgres -d sacdia

# Ejecutar script
\i /path/to/migrations/script_01_organizacion.sql

# O directamente
psql -U postgres -d sacdia -f migrations/script_01_organizacion.sql
```

---

### Opción 2: Desde Supabase Dashboard

1. Ir a **SQL Editor** en Supabase Dashboard
2. Copiar contenido del script
3. Ejecutar
4. Verificar resultados en **Table Editor**

---

### Opción 3: Desde Prisma

```bash
# Ejecutar un script SQL
npx prisma db execute --file migrations/script_01_organizacion.sql

# O desde el directorio específico
cd sacdia-backend
npx prisma db execute --file ../docs/03-DATABASE/migrations/script_01_organizacion.sql
```

---

### Opción 4: Script Bash Completo

Crear `/scripts/seed-database.sh`:

```bash
#!/bin/bash

DB_URL="postgresql://user:password@localhost:5432/sacdia"

echo "🌱 Seeding database..."

psql $DB_URL -f migrations/script_01_organizacion.sql
psql $DB_URL -f migrations/script_04_catalogos_medicos.sql
psql $DB_URL -f migrations/script_05_roles_permisos.sql
psql $DB_URL -f migrations/script_02_clubes_clases.sql
psql $DB_URL -f migrations/script_03_especialidades.sql

echo "✅ Database seeded successfully!"
```

Ejecutar:
```bash
chmod +x scripts/seed-database.sh
./scripts/seed-database.sh
```

---

## 🔍 Verificación

Después de ejecutar los scripts, verifica que los datos se insertaron correctamente:

```bash
# Ejecutar queries de verificación
psql -U postgres -d sacdia -f migrations/verificar_catalogos.sql
```

O desde SQL:
```sql
-- Verificar países
SELECT COUNT(*) FROM countries;

-- Verificar roles
SELECT role_name, role_category FROM roles;

-- Verificar honores
SELECT COUNT(*) FROM honors;
```

---

## ⚠️ Notas Importantes

### Re-ejecución de Scripts
La mayoría de scripts usan `INSERT` sin verificación de duplicados. Si necesitas re-ejecutar:

```sql
-- Opción 1: Limpiar tabla antes
TRUNCATE TABLE countries CASCADE;

-- Opción 2: Usar UPSERT (si el script lo soporta)
INSERT INTO countries (id, name, abbreviation)
VALUES ('uuid', 'México', 'MX')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
```

### Datos de Producción
⚠️ **NO ejecutar estos scripts en producción** si ya tienes datos reales.  
Son solo para desarrollo e inicialización de entornos nuevos.

### Backup y Restore

- Antes de cambios críticos, generar backup lógico completo de la base.
- En restauraciones parciales por tabla, usar scripts versionados y validar FKs antes de aplicar.
- Mantener pruebas de restore periódicas en entorno de staging.
- Ver guía histórica detallada: `docs/history/database/README_BACKUP.md`.

---

## 📝 Crear Nueva Migración

### Con Prisma (Recomendado)

```bash
# 1. Editar schema.prisma
# 2. Crear migración
npx prisma migrate dev --name descripcion_del_cambio

# 3. La migración se crea automáticamente en:
# sacdia-backend/prisma/migrations/YYYYMMDDHHMMSS_descripcion_del_cambio/
```

### Manualmente

1. Crear archivo: `YYYYMMDD_descripcion.sql`
2. Escribir SQL DDL:
   ```sql
   -- Migration: Add legal_representatives table
   CREATE TABLE legal_representatives (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID NOT NULL REFERENCES users(id),
     ...
   );
   ```
3. Documentar en este README
4. Ejecutar siguiendo las opciones anteriores

---

## 🔄 Rollback

Si necesitas revertir una migración:

```sql
-- Ejemplo: Eliminar tabla agregada
DROP TABLE IF EXISTS legal_representatives CASCADE;

-- Ejemplo: Eliminar columna
ALTER TABLE users DROP COLUMN IF EXISTS new_column;
```

**Mejor práctica**: Crear script `rollback_YYYYMMDD.sql` junto a cada migración.

---

## Ver También

- [Database README](../README.md) - Guía general de base de datos
- [schema.prisma](../schema.prisma) - Schema Prisma definitivo
- [SCHEMA-REFERENCE.md](../SCHEMA-REFERENCE.md) - Referencia completa

---

**Última actualización**: 2026-01-30
