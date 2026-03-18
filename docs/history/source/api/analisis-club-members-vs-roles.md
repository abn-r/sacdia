# Análisis: club_role_assignments vs club_members

**Fecha**: 29 de enero de 2026  
**Objetivo**: Determinar si necesitamos tabla `club_members` separada

---

## 🎯 Contexto

**Pregunta**: ¿La relación users-club debe estar en:
- **Opción 1**: Solo `club_role_assignments` (todos los miembros tienen rol)
- **Opción 2**: `club_members` + `club_role_assignments` (membresía separada de roles)

---

## 📊 Opción 1: Solo `club_role_assignments`

### Estructura
```sql
CREATE TABLE club_role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  role_id UUID NOT NULL REFERENCES roles(id),
  
  -- Instancia de club (solo uno de estos tiene valor)
  club_adv_id INT REFERENCES club_adventurers(id),
  club_pathf_id INT REFERENCES club_pathfinders(id),
  club_mg_id INT REFERENCES club_master_guild(id),
  
  -- Año eclesiástico
  ecclesiastical_year_id INT NOT NULL REFERENCES ecclesiastical_years(id),
  
  -- Metadata
  start_date DATE NOT NULL,
  end_date DATE,
  active BOOLEAN DEFAULT true,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('pending', 'active', 'inactive')),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT one_club_instance CHECK (
    (club_adv_id IS NOT NULL AND club_pathf_id IS NULL AND club_mg_id IS NULL) OR
    (club_adv_id IS NULL AND club_pathf_id IS NOT NULL AND club_mg_id IS NULL) OR
    (club_adv_id IS NULL AND club_pathf_id IS NULL AND club_mg_id IS NOT NULL)
  ),
  
  -- Un usuario no puede tener el mismo rol dos veces en la misma instancia y año
  CONSTRAINT unique_user_role_instance_year UNIQUE (
    user_id, role_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id
  )
);
```

### Pros ✅
1. **Simplicidad**: Una sola tabla para gestionar membresía y roles
2. **Alineado con `restructura-roles.md`**: Coincide con la arquitectura ya documentada
3. **Menos joins**: Queries más simples y rápidas
4. **Modelo claro**: "Ser miembro" = "tener rol de member"
5. **Auditoría completa**: Historial de roles incluye historial de membresía
6. **Consistencia**: No puede haber miembro sin rol ni rol sin membresía

### Contras ❌
1. **Rol "member" obligatorio**: Todos deben tener al menos este rol
2. **Queries de "solo miembros" requieren filtro**: `WHERE role.role_name = 'member'`

### Ejemplo de Queries

**Obtener todos los miembros de un club**:
```sql
SELECT u.id, u.name, u.paternal_last_name, r.role_name
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
JOIN roles r ON cra.role_id = r.id
WHERE cra.club_adv_id = 10  -- Club Aventureros específico
  AND cra.ecclesiastical_year_id = 3
  AND cra.active = true;
```

**Verificar si usuario es miembro**:
```sql
SELECT EXISTS (
  SELECT 1 FROM club_role_assignments cra
  WHERE cra.user_id = 'uuid-usuario'
    AND cra.club_adv_id = 10
    AND cra.active = true
) AS is_member;
```

**Obtener solo directores**:
```sql
SELECT u.*, cra.start_date
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
JOIN roles r ON cra.role_id = r.id
WHERE cra.club_adv_id = 10
  AND r.role_name = 'director'
  AND cra.active = true;
```

---

## 📊 Opción 2: `club_members` + `club_role_assignments`

### Estructura
```sql
-- Tabla de membresía
CREATE TABLE club_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  
  -- Instancia de club
  club_adv_id INT REFERENCES club_adventurers(id),
  club_pathf_id INT REFERENCES club_pathfinders(id),
  club_mg_id INT REFERENCES club_master_guild(id),
  
  -- Año eclesiástico
  ecclesiastical_year_id INT NOT NULL REFERENCES ecclesiastical_years(id),
  
  -- Metadata de membresía
  enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('pending', 'active', 'inactive', 'suspended')),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT one_club_instance CHECK (...),
  CONSTRAINT unique_user_club_year UNIQUE (user_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id)
);

-- Tabla de roles (referencia a club_members)
CREATE TABLE club_role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_member_id UUID NOT NULL REFERENCES club_members(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id),
  
  start_date DATE NOT NULL,
  end_date DATE,
  active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT unique_member_role UNIQUE (club_member_id, role_id)
);
```

### Pros ✅
1. **Separación clara**: Membresía != Roles
2. **Flexibilidad**: Miembro sin roles administrativos es más explícito
3. **Metadata de membresía**: Campos como `enrollment_date`, `suspension_reason` están en lugar lógico

### Contras ❌
1. **Complejidad**: Dos tablas en lugar de una
2. **Más joins**: Todas las queries requieren JOIN adicional
3. **Inconsistencia potencial**: ¿Puede haber rol sin membresía? ¿Membresía sin rol?
4. **No alineado con `restructura-roles.md`**: Requeriría reescribir documentación
5. **Performance**: Queries más lentas por joins adicionales
6. **Sincronización**: Necesitas mantener consistencia entre ambas tablas

### Ejemplo de Queries

**Obtener todos los miembros**:
```sql
SELECT u.*, cm.enrollment_date, r.role_name
FROM users u
JOIN club_members cm ON u.id = cm.user_id
LEFT JOIN club_role_assignments cra ON cm.id = cra.club_member_id
LEFT JOIN roles r ON cra.role_id = r.id
WHERE cm.club_adv_id = 10
  AND cm.status = 'active';
```

**Obtener solo directores**:
```sql
SELECT u.*, cm.enrollment_date
FROM users u
JOIN club_members cm ON u.id = cm.user_id
JOIN club_role_assignments cra ON cm.id = cra.club_member_id
JOIN roles r ON cra.role_id = r.id
WHERE cm.club_adv_id = 10
  AND r.role_name = 'director'
  AND cra.active = true;
```

---

## 🎯 Análisis Funcional

### Casos de Uso

#### Caso 1: Usuario se registra por primera vez
- **Opción 1**: Crea 1 registro en `club_role_assignments` con rol "member"
- **Opción 2**: Crea 1 registro en `club_members` + (opcionalmente) 0 registros en `club_role_assignments`

**Ganador**: Opción 1 (más simple, 1 sola inserción)

---

#### Caso 2: Usuario es promovido a Director
- **Opción 1**: Crea nuevo registro en `club_role_assignments` con rol "director" (mantiene rol "member" también)
- **Opción 2**: Crea registro en `club_role_assignments` vinculado a `club_member_id`

**Ganador**: Opción 2 (más explícito que tiene 2 roles)

Pero en **Opción 1**, también funciona bien:
```sql
-- Usuario tiene 2 registros en club_role_assignments:
-- 1. role = 'member', active = true
-- 2. role = 'director', active = true
```

---

#### Caso 3: Listar todos los miembros activos (sin importar rol)
- **Opción 1**: `SELECT ... WHERE active = true` (puede retornar duplicados si tiene varios roles, necesita DISTINCT)
- **Opción 2**: `SELECT ... FROM club_members WHERE status = 'active'`

**Ganador**: Opción 2 (más directo)

Pero en **Opción 1**, se resuelve fácil:
```sql
SELECT DISTINCT u.* 
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
WHERE cra.club_adv_id = 10 AND cra.active = true;
```

---

#### Caso 4: Usuario deja de ser miembro del club
- **Opción 1**: Marca `active = false` en TODOS sus registros de `club_role_assignments` para ese club
- **Opción 2**: Marca `status = 'inactive'` en `club_members` (CASCADE elimina roles automáticamente)

**Ganador**: Opción 2 (1 sola actualización vs múltiples)

Pero en **Opción 1**, se puede hacer con:
```sql
UPDATE club_role_assignments 
SET active = false 
WHERE user_id = 'uuid' AND club_adv_id = 10;
```

---

#### Caso 5: Historial de membresía por años eclesiásticos
- **Opción 1**: `SELECT ... GROUP BY ecclesiastical_year_id` (puede mostrar varios roles por año)
- **Opción 2**: `SELECT ... FROM club_members` (1 registro por año)

**Ganador**: Opción 2 (más limpio)

---

## 🏆 Recomendación Final

### ✅ **Opción 1: Solo `club_role_assignments`**

**Razones**:

1. **Alineación con documentación existente**: `restructura-roles.md` ya define esta arquitectura
2. **Simplicidad**: Menor complejidad = menos bugs
3. **Performance**: Menos joins = queries más rápidas
4. **Consistencia garantizada**: No puede haber desincronización entre tablas
5. **El 95% de casos de uso funcionan perfectamente**

**Casos edge a resolver**:
- Listar miembros sin duplicados → Usar DISTINCT o GROUP BY
- Dar de baja usuario → UPDATE todos sus roles de ese club

### Ajustes recomendados:

```sql
-- Agregar índices para queries comunes
CREATE INDEX idx_cra_user_club_adv ON club_role_assignments(user_id, club_adv_id) WHERE active = true;
CREATE INDEX idx_cra_user_club_pathf ON club_role_assignments(user_id, club_pathf_id) WHERE active = true;
CREATE INDEX idx_cra_user_club_mg ON club_role_assignments(user_id, club_mg_id) WHERE active = true;
CREATE INDEX idx_cra_year ON club_role_assignments(ecclesiastical_year_id);

-- Vista helper para "solo miembros activos únicos"
CREATE VIEW v_active_club_members AS
SELECT DISTINCT ON (user_id, club_adv_id, club_pathf_id, club_mg_id)
  user_id,
  club_adv_id,
  club_pathf_id,
  club_mg_id,
  ecclesiastical_year_id,
  MIN(start_date) as member_since
FROM club_role_assignments
WHERE active = true
GROUP BY user_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id;
```

---

## 📝 Decisión Final

**USAR: Opción 1 - Solo `club_role_assignments`**

**Razón principal**: Coincide con `restructura-roles.md` y es arquitectónicamente más simple sin sacrificar funcionalidad.

**Tabla final**:
```sql
CREATE TABLE club_role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  role_id UUID NOT NULL REFERENCES roles(id),
  
  -- Instancia de club (solo uno con valor)
  club_adv_id INT REFERENCES club_adventurers(id),
  club_pathf_id INT REFERENCES club_pathfinders(id),
  club_mg_id INT REFERENCES club_master_guild(id),
  
  -- ✅ Año eclesiástico (agregado)
  ecclesiastical_year_id INT NOT NULL REFERENCES ecclesiastical_years(id),
  
  -- Metadata
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  active BOOLEAN DEFAULT true,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('pending', 'active', 'inactive')),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT one_club_instance CHECK (
    (club_adv_id IS NOT NULL)::int + 
    (club_pathf_id IS NOT NULL)::int + 
    (club_mg_id IS NOT NULL)::int = 1
  ),
  
  CONSTRAINT unique_user_role_instance_year UNIQUE NULLS NOT DISTINCT (
    user_id, role_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id
  )
);

-- Índices
CREATE INDEX idx_cra_user_active ON club_role_assignments(user_id) WHERE active = true;
CREATE INDEX idx_cra_club_adv_active ON club_role_assignments(club_adv_id) WHERE active = true AND club_adv_id IS NOT NULL;
CREATE INDEX idx_cra_club_pathf_active ON club_role_assignments(club_pathf_id) WHERE active = true AND club_pathf_id IS NOT NULL;
CREATE INDEX idx_cra_club_mg_active ON club_role_assignments(club_mg_id) WHERE active = true AND club_mg_id IS NOT NULL;
CREATE INDEX idx_cra_year ON club_role_assignments(ecclesiastical_year_id);
```

---

**Generado**: 2026-01-29  
**Decisión**: ✅ Opción 1 confirmada
