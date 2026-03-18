# Verificación y Actualización de schema.prisma

**Fecha**: 29 de enero de 2026  
**Schema Analizado**: `/docs/database/schema.prisma`

---

## ✅ Estado Actual vs Requerido

### 1. ✅ Tabla `roles` - **COMPLETO**
- ✅ Tiene campo `role_category` (enum)
- ✅ Enum `role_category` definido (línea 1165)

### 2. ✅ Tabla `club_role_assignments` - **CASI COMPLETO**
- ✅ Tiene `ecclesiastical_year_id` (línea 321)
- ✅ Tiene relaciones correctas
- ✅ Tiene índices
- ❌ **FALTA**: Campo `status` con valores ('pending', 'active', 'inactive')

### 3. ❌ Tabla `users` - **REQUIERE CAMBIOS**
**Actual** (línea 785):
```prisma
mother_last_name  String? @db.VarChar(50)
```

**Requerido**:
```prisma
maternal_last_name  String? @db.VarChar(50)
```

### 4. ❌ Tabla `users_pr` - **INCOMPLETA**
**Actual** (línea 838):
```prisma
model users_pr {
  user_pr_id     Int       @id @default(autoincrement())
  user_id        String    @db.Uuid
  complete       Boolean   @default(false)
  date_completed DateTime? @db.Timestamptz(6)
  created_at     DateTime  @default(now()) @db.Timestamptz(6)
  modified_at    DateTime  @default(now()) @updatedAt @db.Timestamptz(6)
  users          users     @relation(fields: [user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
}
```

**FALTA tracking granular**:
- `profile_picture_complete`
- `personal_info_complete`
- `club_selection_complete`

### 5. ❌ Tabla `legal_representatives` - **NO EXISTE**

Debe crearse completamente.

---

## 📝 Cambios Requeridos

### Cambio 1: Renombrar campo en `users`

**Línea 785**:
```prisma
// ANTES
mother_last_name             String?                          @db.VarChar(50)

// DESPUÉS
maternal_last_name           String?                          @db.VarChar(50)
```

---

### Cambio 2: Actualizar `users_pr` con tracking

**Línea 838 - Reemplazar completo**:
```prisma
model users_pr {
  user_pr_id                 Int       @id @default(autoincrement())
  user_id                    String    @unique @db.Uuid  // ✅ Cambiar a unique
  
  // Tracking granular
  complete                   Boolean   @default(false)
  profile_picture_complete   Boolean   @default(false)  // ✅ NUEVO
  personal_info_complete     Boolean   @default(false)  // ✅ NUEVO
  club_selection_complete    Boolean   @default(false)  // ✅ NUEVO
  
  date_completed             DateTime? @db.Timestamptz(6)
  created_at                 DateTime  @default(now()) @db.Timestamptz(6)
  modified_at                DateTime  @default(now()) @updatedAt @db.Timestamptz(6)
  
  users                      users     @relation(fields: [user_id], references: [user_id], onDelete: Cascade, onUpdate: NoAction)
}
```

---

### Cambio 3: Agregar campo `status` a `club_role_assignments`

**Línea 314 - Agregar en línea 324**:
```prisma
model club_role_assignments {
  assignment_id          String              @id @default(dbgenerated("extensions.uuid_generate_v4()")) @db.Uuid
  user_id                String              @db.Uuid
  role_id                String              @db.Uuid
  club_adv_id            Int?
  club_pathf_id          Int?
  club_mg_id             Int?
  ecclesiastical_year_id Int
  start_date             DateTime            @db.Date
  end_date               DateTime?           @db.Date  // ✅ Cambiar a opcional
  active                 Boolean             @default(true)
  status                 String?             @default("active") @db.VarChar(20)  // ✅ NUEVO
  created_at             DateTime            @default(now()) @db.Timestamptz(6)
  modified_at            DateTime            @default(now()) @updatedAt @db.Timestamptz(6)
  
  // ... resto igual
}
```

---

### Cambio 4: Crear tabla `legal_representatives`

**Agregar DESPUÉS de la tabla `users_pr` (línea ~846)**:
```prisma
model legal_representatives {
  id                     String    @id @default(dbgenerated("extensions.uuid_generate_v4()")) @db.Uuid
  user_id                String    @unique @db.Uuid  // Máximo 1 por usuario
  
  // Opción 1: Representante es usuario registrado
  representative_user_id String?   @db.Uuid
  
  // Opción 2: Solo datos del representante
  name                   String?   @db.VarChar(100)
  paternal_last_name     String?   @db.VarChar(100)
  maternal_last_name     String?   @db.VarChar(100)
  phone                  String?   @db.VarChar(20)
  
  // Tipo de relación
  relationship_type_id   String?   @db.Uuid
  
  created_at             DateTime  @default(now()) @db.Timestamptz(6)
  modified_at            DateTime  @default(now()) @updatedAt @db.Timestamptz(6)
  
  // Relaciones
  users                  users     @relation("user_legal_rep", fields: [user_id], references: [user_id], onDelete: Cascade, onUpdate: NoAction)
  representative_user    users?    @relation("representative", fields: [representative_user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  relationship_types     relationship_types? @relation(fields: [relationship_type_id], references: [relationship_type_id], onDelete: NoAction, onUpdate: NoAction)
  
  @@index([user_id], map: "idx_legal_reps_user")
}
```

---

### Cambio 5: Actualizar modelo `users` con relaciones

**En modelo `users` (línea 827), AGREGAR**:
```prisma
model users {
  // ... campos existentes ...
  
  // AGREGAR al final de relaciones (antes de closing bracket):
  legal_representative      legal_representatives?  @relation("user_legal_rep")
  as_legal_representative   legal_representatives[] @relation("representative")
}
```

---

### Cambio 6: Crear tabla `relationship_types` (si no existe)

```prisma
model relationship_types {
  relationship_type_id   String                  @id @default(dbgenerated("extensions.uuid_generate_v4()")) @db.Uuid
  name                   String                  @unique @db.VarChar(50)
  description            String?
  active                 Boolean                 @default(true)
  created_at             DateTime                @default(now()) @db.Timestamptz(6)
  modified_at            DateTime                @default(now()) @updatedAt @db.Timestamptz(6)
  
  legal_representatives  legal_representatives[]
  emergency_contacts     emergency_contacts[]  // Si emergency_contacts usa relationship_type
}
```

---

## 🔄 Migration SQL

### Migration: `update_schema_for_v2`

```sql
-- ========================================
-- MIGRATION: Schema V2 - Decisiones Finales
-- ========================================

BEGIN;

-- 1. Renombrar campo en users
ALTER TABLE users 
RENAME COLUMN mother_last_name TO maternal_last_name;

-- 2. Actualizar users_pr con tracking granular
ALTER TABLE users_pr
  ADD COLUMN profile_picture_complete BOOLEAN DEFAULT false,
  ADD COLUMN personal_info_complete BOOLEAN DEFAULT false,
  ADD COLUMN club_selection_complete BOOLEAN DEFAULT false;

-- Hacer user_id único
ALTER TABLE users_pr
  DROP CONSTRAINT IF EXISTS users_pr_user_id_key,
  ADD CONSTRAINT users_pr_user_id_key UNIQUE (user_id);

-- 3. Agregar campo status a club_role_assignments
ALTER TABLE club_role_assignments
  ADD COLUMN status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'inactive'));

-- Hacer end_date opcional (si no lo es)
ALTER TABLE club_role_assignments
  ALTER COLUMN end_date DROP NOT NULL;

-- 4. Crear tabla relationship_types (si no existe)
CREATE TABLE IF NOT EXISTS relationship_types (
  relationship_type_id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ(6) DEFAULT NOW(),
  modified_at TIMESTAMPTZ(6) DEFAULT NOW()
);

-- 5. Crear tabla legal_representatives
CREATE TABLE legal_representatives (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
  
  -- Opción 1: Usuario registrado
  representative_user_id UUID REFERENCES users(user_id),
  
  -- Opción 2: Solo datos
  name VARCHAR(100),
  paternal_last_name VARCHAR(100),
  maternal_last_name VARCHAR(100),
  phone VARCHAR(20),
  
  -- Tipo de relación
  relationship_type_id UUID REFERENCES relationship_types(relationship_type_id),
  
  created_at TIMESTAMPTZ(6) DEFAULT NOW(),
  modified_at TIMESTAMPTZ(6) DEFAULT NOW(),
  
  -- Constraint: Debe tener O usuario registrado O datos completos
  CONSTRAINT representative_data_check CHECK (
    (representative_user_id IS NOT NULL) OR 
    (name IS NOT NULL AND paternal_last_name IS NOT NULL AND phone IS NOT NULL)
  )
);

-- Índices
CREATE INDEX idx_legal_reps_user ON legal_representatives(user_id);
CREATE INDEX idx_legal_reps_representative ON legal_representatives(representative_user_id);

-- 6. Seed de relationship_types (si tabla nueva)
INSERT INTO relationship_types (name, description) VALUES
  ('Padre', 'Padre biológico o adoptivo'),
  ('Madre', 'Madre biológica o adoptiva'),
  ('Tutor Legal', 'Tutor legal asignado'),
  ('Abuelo/a', 'Abuelo o abuela'),
  ('Tío/a', 'Tío o tía'),
  ('Otro', 'Otra relación familiar')
ON CONFLICT (name) DO NOTHING;

COMMIT;
```

---

## 📊 Resumen de Cambios

| # | Tabla | Cambio | Tipo |
|---|---|---|---|
| 1 | `users` | `mother_last_name` → `maternal_last_name` | Renombrar |
| 2 | `users_pr` | Agregar 3 campos de tracking | Agregar columnas |
| 3 | `users_pr` | Hacer `user_id` único | Constraint |
| 4 | `club_role_assignments` | Agregar campo `status` | Agregar columna |
| 5 | `club_role_assignments` | `end_date` opcional | Modificar columna |
| 6 | - | Crear `relationship_types` | Nueva tabla |
| 7 | - | Crear `legal_representatives` | Nueva tabla |

---

## ✅ Checklist de Aplicación

### Prisma Schema
- [ ] Actualizar `users` con `maternal_last_name`
- [ ] Agregar campos tracking a `users_pr`
- [ ] Agregar campo `status` a `club_role_assignments`
- [ ] Crear modelo `relationship_types`
- [ ] Crear modelo `legal_representatives`
- [ ] Actualizar relaciones en `users`

### Migration
- [ ] Crear archivo de migración SQL
- [ ] Aplicar en entorno de desarrollo
- [ ] Verificar integridad de datos
- [ ] Aplicar en producción

### Testing
- [ ] Probar creación de representante legal
- [ ] Probar tracking de post-registro
- [ ] Verificar queries de `club_role_assignments` con status

---

## 🚀 Aplicar Cambios

### Opción 1: Migration Manual (SQL)
```bash
# Ejecutar migration SQL directamente en Supabase
psql $DATABASE_URL < migrations/update_schema_v2.sql
```

### Opción 2: Prisma Migrate (Recomendado)
```bash
# 1. Actualizar schema.prisma con los cambios
# 2. Crear migration
npx prisma migrate dev --name update_schema_v2

# 3. Generar cliente
npx prisma generate
```

---

## 📝 Próximos Pasos

1. **Aplicar cambios al schema.prisma** (línea por línea)
2. **Ejecutar migration**
3. **Actualizar seed de roles** con `role_category`
4. **Actualizar DTOs en NestJS**
5. **Tests de integración**

---

**Generado**: 2026-01-29  
**Status**: Listo para aplicar  
**Prioridad**: ALTA - Cambios requeridos antes de iniciar backend
