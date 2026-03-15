-- ========================================
-- MIGRATION: Schema V2 - Decisiones Finales SACDIA
-- Fecha: 2026-01-29
-- ========================================

BEGIN;

-- ========================================
-- 1. RENOMBRAR CAMPO EN USERS
-- ========================================
ALTER TABLE users 
RENAME COLUMN mother_last_name TO maternal_last_name;

-- ========================================
-- 2. ACTUALIZAR USERS_PR CON TRACKING GRANULAR
-- ========================================

-- Agregar nuevos campos de tracking
ALTER TABLE users_pr
  ADD COLUMN IF NOT EXISTS profile_picture_complete BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS personal_info_complete BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS club_selection_complete BOOLEAN DEFAULT false;

-- Hacer user_id único (si no lo es ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'users_pr_user_id_key'
  ) THEN
    ALTER TABLE users_pr ADD CONSTRAINT users_pr_user_id_key UNIQUE (user_id);
  END IF;
END $$;

-- Cambiar onDelete a CASCADE
ALTER TABLE users_pr
  DROP CONSTRAINT IF EXISTS users_pr_user_id_fkey,
  ADD CONSTRAINT users_pr_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- ========================================
-- 3. ACTUALIZAR CLUB_ROLE_ASSIGNMENTS
-- ========================================

-- Agregar campo status
ALTER TABLE club_role_assignments
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'inactive'));

-- Hacer end_date opcional
ALTER TABLE club_role_assignments
  ALTER COLUMN end_date DROP NOT NULL;

-- ========================================
-- 4. CREAR TABLA RELATIONSHIP_TYPES
-- ========================================

CREATE TABLE IF NOT EXISTS relationship_types (
  relationship_type_id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ(6) DEFAULT NOW(),
  modified_at TIMESTAMPTZ(6) DEFAULT NOW()
);

-- Índice para búsquedas por nombre
CREATE INDEX IF NOT EXISTS idx_relationship_types_name 
ON relationship_types(name);

-- ========================================
-- 5. SEED DE RELATIONSHIP_TYPES
-- ========================================

INSERT INTO relationship_types (name, description) VALUES
  ('Padre', 'Padre biológico o adoptivo'),
  ('Madre', 'Madre biológica o adoptiva'),
  ('Tutor Legal', 'Tutor legal asignado'),
  ('Abuelo', 'Abuelo'),
  ('Abuela', 'Abuela'),
  ('Tío', 'Tío'),
  ('Tía', 'Tía'),
  ('Hermano', 'Hermano'),
  ('Hermana', 'Hermana'),
  ('Otro Familiar', 'Otro familiar cercano')
ON CONFLICT (name) DO NOTHING;

-- ========================================
-- 6. CREAR TABLA LEGAL_REPRESENTATIVES
-- ========================================

CREATE TABLE IF NOT EXISTS legal_representatives (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
  
  -- Opción 1: Representante es usuario registrado
  representative_user_id UUID REFERENCES users(user_id),
  
  -- Opción 2: Solo datos del representante
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

-- Índices para legal_representatives
CREATE INDEX IF NOT EXISTS idx_legal_reps_user 
ON legal_representatives(user_id);

CREATE INDEX IF NOT EXISTS idx_legal_reps_representative 
ON legal_representatives(representative_user_id);

-- ========================================
-- 7. ACTUALIZAR EMERGENCY_CONTACTS (OPCIONAL)
-- ========================================

-- Si emergency_contacts no tiene relationship_type_id, agregarlo
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'emergency_contacts' 
    AND column_name = 'relationship_type_id'
  ) THEN
    ALTER TABLE emergency_contacts
      ADD COLUMN relationship_type_id UUID REFERENCES relationship_types(relationship_type_id);
  END IF;
END $$;

-- ========================================
-- 8. TRIGGER PARA VALIDAR MÁXIMO 5 CONTACTOS
-- ========================================

CREATE OR REPLACE FUNCTION check_max_emergency_contacts()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) FROM emergency_contacts WHERE user_id = NEW.user_id) >= 5 THEN
    RAISE EXCEPTION 'User cannot have more than 5 emergency contacts';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger (drop primero si existe)
DROP TRIGGER IF EXISTS trigger_max_emergency_contacts ON emergency_contacts;
CREATE TRIGGER trigger_max_emergency_contacts
  BEFORE INSERT ON emergency_contacts
  FOR EACH ROW 
  EXECUTE FUNCTION check_max_emergency_contacts();

-- ========================================
-- 9. VERIFICACIONES FINALES
-- ========================================

-- Verificar que todas las tablas existen
DO $$
BEGIN
  ASSERT (SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users_pr')), 
    'Table users_pr does not exist';
  ASSERT (SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'relationship_types')), 
    'Table relationship_types does not exist';
  ASSERT (SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'legal_representatives')), 
    'Table legal_representatives does not exist';
  RAISE NOTICE 'All tables created successfully!';
END $$;

-- Verificar que campos existen
DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'maternal_last_name'
  )), 'Column maternal_last_name does not exist in users';
  
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users_pr' AND column_name = 'profile_picture_complete'
  )), 'Column profile_picture_complete does not exist in users_pr';
  
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'club_role_assignments' AND column_name = 'status'
  )), 'Column status does not exist in club_role_assignments';
  
  RAISE NOTICE 'All columns verified successfully!';
END $$;

COMMIT;

-- ========================================
-- MIGRATION COMPLETADA
-- ========================================
-- Todos los cambios del schema v2 han sido aplicados
-- - ✅ Renombrado maternal_last_name
-- - ✅ Agregado tracking a users_pr
-- - ✅ Agregado status a club_role_assignments
-- - ✅ Creada tabla relationship_types con seed
-- - ✅ Creada tabla legal_representatives
-- - ✅ Trigger para validar máximo 5 contactos
-- ========================================
