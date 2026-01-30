# Queries SQL - club_role_assignments

**Fecha**: 29 de enero de 2026  
**Propósito**: Catálogo de queries comunes para gestión de membresía y roles de club

---

## 📋 Estructura de Tabla

```sql
CREATE TABLE club_role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  role_id UUID NOT NULL REFERENCES roles(id),
  
  -- Instancia de club (solo una con valor)
  club_adv_id INT REFERENCES club_adventurers(id),
  club_pathf_id INT REFERENCES club_pathfinders(id),
  club_mg_id INT REFERENCES club_master_guild(id),
  
  -- Año eclesiástico
  ecclesiastical_year_id INT NOT NULL REFERENCES ecclesiastical_years(id),
  
  -- Metadata
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  active BOOLEAN DEFAULT true,
  status VARCHAR(20) DEFAULT 'active',
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## 1️⃣ Queries de Membresía

### 1.1 Listar todos los miembros activos de un club (sin duplicados)

```sql
-- Aventureros
SELECT DISTINCT u.id, u.name, u.paternal_last_name, u.maternal_last_name, u.email
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
WHERE cra.club_adv_id = :clubAdvId
  AND cra.active = true
  AND cra.ecclesiastical_year_id = :currentYearId;
```

```sql
-- Conquistadores
SELECT DISTINCT u.id, u.name, u.paternal_last_name, u.maternal_last_name, u.email
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
WHERE cra.club_pathf_id = :clubPathfId
  AND cra.active = true
  AND cra.ecclesiastical_year_id = :currentYearId;
```

```sql
-- Guías Mayores
SELECT DISTINCT u.id, u.name, u.paternal_last_name, u.maternal_last_name, u.email
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
WHERE cra.club_mg_id = :clubMgId
  AND cra.active = true
  AND cra.ecclesiastical_year_id = :currentYearId;
```

---

### 1.2 Verificar si un usuario es miembro de un club

```sql
SELECT EXISTS (
  SELECT 1 FROM club_role_assignments
  WHERE user_id = :userId
    AND club_adv_id = :clubAdvId  -- O club_pathf_id o club_mg_id
    AND active = true
    AND ecclesiastical_year_id = :currentYearId
) AS is_member;
```

---

### 1.3 Contar miembros activos por club

```sql
SELECT 
  COUNT(DISTINCT user_id) AS total_members
FROM club_role_assignments
WHERE club_adv_id = :clubAdvId
  AND active = true
  AND ecclesiastical_year_id = :currentYearId;
```

---

## 2️⃣ Queries de Roles

### 2.1 Obtener todos los roles de un usuario en un club

```sql
SELECT 
  r.role_name,
  r.role_category,
  cra.start_date,
  cra.end_date,
  cra.status
FROM club_role_assignments cra
JOIN roles r ON cra.role_id = r.id
WHERE cra.user_id = :userId
  AND cra.club_adv_id = :clubAdvId
  AND cra.active = true
  AND cra.ecclesiastical_year_id = :currentYearId;
```

---

### 2.2 Obtener solo directores de un club

```sql
SELECT 
  u.id, 
  u.name, 
  u.paternal_last_name, 
  u.maternal_last_name,
  cra.start_date
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
JOIN roles r ON cra.role_id = r.id
WHERE cra.club_adv_id = :clubAdvId
  AND r.role_name = 'director'
  AND r.role_category = 'CLUB'
  AND cra.active = true
  AND cra.ecclesiastical_year_id = :currentYearId;
```

---

### 2.3 Verificar si usuario tiene rol específico en club

```sql
SELECT EXISTS (
  SELECT 1 
  FROM club_role_assignments cra
  JOIN roles r ON cra.role_id = r.id
  WHERE cra.user_id = :userId
    AND cra.club_adv_id = :clubAdvId
    AND r.role_name = :roleName
    AND cra.active = true
    AND cra.ecclesiastical_year_id = :currentYearId
) AS has_role;
```

---

## 3️⃣ Queries por Año Eclesiástico

### 3.1 Listar miembros de un año específico

```sql
SELECT DISTINCT 
  u.id, 
  u.name, 
  u.paternal_last_name,
  ey.start_date AS year_start,
  ey.end_date AS year_end
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
JOIN ecclesiastical_years ey ON cra.ecclesiastical_year_id = ey.id
WHERE cra.club_adv_id = :clubAdvId
  AND cra.ecclesiastical_year_id = :yearId
  AND cra.active = true;
```

---

### 3.2 Comparar membresía entre dos años

```sql
-- Miembros que estuvieron en 2023 pero NO en 2024
SELECT DISTINCT u.id, u.name, u.paternal_last_name
FROM users u
JOIN club_role_assignments cra2023 ON u.id = cra2023.user_id
WHERE cra2023.club_adv_id = :clubAdvId
  AND cra2023.ecclesiastical_year_id = :year2023Id
  AND NOT EXISTS (
    SELECT 1 FROM club_role_assignments cra2024
    WHERE cra2024.user_id = u.id
      AND cra2024.club_adv_id = :clubAdvId
      AND cra2024.ecclesiastical_year_id = :year2024Id
  );
```

---

### 3.3 Obtener historial de años de un usuario

```sql
SELECT 
  ey.start_date,
  ey.end_date,
  COALESCE(ca.name, cp.name, cmg.name) AS club_name,
  STRING_AGG(DISTINCT r.role_name, ', ') AS roles
FROM club_role_assignments cra
JOIN ecclesiastical_years ey ON cra.ecclesiastical_year_id = ey.id
JOIN roles r ON cra.role_id = r.id
LEFT JOIN club_adventurers ca ON cra.club_adv_id = ca.id
LEFT JOIN club_pathfinders cp ON cra.club_pathf_id = cp.id
LEFT JOIN club_master_guild cmg ON cra.club_mg_id = cmg.id
WHERE cra.user_id = :userId
GROUP BY ey.start_date, ey.end_date, ca.name, cp.name, cmg.name
ORDER BY ey.start_date DESC;
```

---

## 4️⃣ Queries de Administración

### 4.1 Asignar nuevo rol a usuario (mantiene roles existentes)

```sql
INSERT INTO club_role_assignments (
  user_id, 
  role_id, 
  club_adv_id, 
  ecclesiastical_year_id,
  start_date,
  active,
  status
) VALUES (
  :userId,
  (SELECT id FROM roles WHERE role_name = 'secretary' AND role_category = 'CLUB'),
  :clubAdvId,
  :currentYearId,
  CURRENT_DATE,
  true,
  'active'
)
ON CONFLICT (user_id, role_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id)
DO UPDATE SET 
  active = true,
  updated_at = NOW();
```

---

### 4.2 Remover rol de usuario (mantiene otros roles)

```sql
UPDATE club_role_assignments
SET 
  active = false,
  end_date = CURRENT_DATE,
  updated_at = NOW()
WHERE user_id = :userId
  AND role_id = (SELECT id FROM roles WHERE role_name = :roleName)
  AND club_adv_id = :clubAdvId
  AND ecclesiastical_year_id = :currentYearId;
```

---

### 4.3 Dar de baja a usuario del club (desactiva TODOS sus roles)

```sql
UPDATE club_role_assignments
SET 
  active = false,
  end_date = CURRENT_DATE,
  status = 'inactive',
  updated_at = NOW()
WHERE user_id = :userId
  AND club_adv_id = :clubAdvId
  AND ecclesiastical_year_id = :currentYearId
  AND active = true;
```

---

### 4.4 Transferir usuario de un club a otro (mismo tipo)

```sql
-- Paso 1: Desactivar en club anterior
UPDATE club_role_assignments
SET active = false, end_date = CURRENT_DATE
WHERE user_id = :userId
  AND club_adv_id = :oldClubAdvId
  AND active = true;

-- Paso 2: Crear en club nuevo
INSERT INTO club_role_assignments (
  user_id, role_id, club_adv_id, ecclesiastical_year_id, start_date
) VALUES (
  :userId,
  (SELECT id FROM roles WHERE role_name = 'member' AND role_category = 'CLUB'),
  :newClubAdvId,
  :currentYearId,
  CURRENT_DATE
);
```

---

## 5️⃣ Queries de Estadísticas

### 5.1 Distribución de roles en un club

```sql
SELECT 
  r.role_name,
  COUNT(DISTINCT cra.user_id) AS user_count
FROM club_role_assignments cra
JOIN roles r ON cra.role_id = r.id
WHERE cra.club_adv_id = :clubAdvId
  AND cra.active = true
  AND cra.ecclesiastical_year_id = :currentYearId
GROUP BY r.role_name
ORDER BY user_count DESC;
```

---

### 5.2 Miembros con múltiples roles

```sql
SELECT 
  u.id,
  u.name,
  u.paternal_last_name,
  STRING_AGG(r.role_name, ', ') AS roles,
  COUNT(*) AS role_count
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
JOIN roles r ON cra.role_id = r.id
WHERE cra.club_adv_id = :clubAdvId
  AND cra.active = true
  AND cra.ecclesiastical_year_id = :currentYearId
GROUP BY u.id, u.name, u.paternal_last_name
HAVING COUNT(*) > 1
ORDER BY role_count DESC;
```

---

### 5.3 Tiempo promedio de membresía

```sql
SELECT 
  AVG(COALESCE(end_date, CURRENT_DATE) - start_date) AS avg_membership_days
FROM club_role_assignments
WHERE club_adv_id = :clubAdvId;
```

---

## 6️⃣ Vistas Útiles

### 6.1 Vista: Miembros activos únicos

```sql
CREATE OR REPLACE VIEW v_active_club_members AS
SELECT DISTINCT ON (user_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id)
  cra.user_id,
  cra.club_adv_id,
  cra.club_pathf_id,
  cra.club_mg_id,
  cra.ecclesiastical_year_id,
  MIN(cra.start_date) OVER (
    PARTITION BY cra.user_id, cra.club_adv_id, cra.club_pathf_id, cra.club_mg_id, cra.ecclesiastical_year_id
  ) AS member_since,
  u.name,
  u.paternal_last_name,
  u.maternal_last_name,
  u.email
FROM club_role_assignments cra
JOIN users u ON cra.user_id = u.id
WHERE cra.active = true;

-- Uso:
SELECT * FROM v_active_club_members 
WHERE club_adv_id = :clubAdvId 
  AND ecclesiastical_year_id = :currentYearId;
```

---

### 6.2 Vista: Usuarios con sus roles

```sql
CREATE OR REPLACE VIEW v_user_club_roles AS
SELECT 
  u.id AS user_id,
  u.name,
  u.paternal_last_name,
  u.maternal_last_name,
  cra.club_adv_id,
  cra.club_pathf_id,
  cra.club_mg_id,
  cra.ecclesiastical_year_id,
  r.role_name,
  r.role_category,
  cra.start_date,
  cra.end_date,
  cra.active,
  cra.status
FROM users u
JOIN club_role_assignments cra ON u.id = cra.user_id
JOIN roles r ON cra.role_id = r.id;

-- Uso:
SELECT * FROM v_user_club_roles
WHERE user_id = :userId AND active = true;
```

---

## 7️⃣ Índices Recomendados

```sql
-- Índice principal por usuario
CREATE INDEX idx_cra_user_active 
ON club_role_assignments(user_id) 
WHERE active = true;

-- Índices por tipo de club
CREATE INDEX idx_cra_club_adv_active 
ON club_role_assignments(club_adv_id) 
WHERE active = true AND club_adv_id IS NOT NULL;

CREATE INDEX idx_cra_club_pathf_active 
ON club_role_assignments(club_pathf_id) 
WHERE active = true AND club_pathf_id IS NOT NULL;

CREATE INDEX idx_cra_club_mg_active 
ON club_role_assignments(club_mg_id) 
WHERE active = true AND club_mg_id IS NOT NULL;

-- Índice por año eclesiástico
CREATE INDEX idx_cra_year 
ON club_role_assignments(ecclesiastical_year_id);

-- Índice compuesto para queries comunes
CREATE INDEX idx_cra_user_club_year 
ON club_role_assignments(user_id, club_adv_id, ecclesiastical_year_id) 
WHERE active = true;

CREATE INDEX idx_cra_club_year 
ON club_role_assignments(club_adv_id, ecclesiastical_year_id) 
WHERE active = true;
```

---

## 8️⃣ Queries de Prisma (NestJS)

### 8.1 Listar miembros activos

```typescript
const members = await prisma.users.findMany({
  where: {
    club_role_assignments: {
      some: {
        club_adv_id: clubAdvId,
        ecclesiastical_year_id: currentYearId,
        active: true
      }
    }
  },
  select: {
    id: true,
    name: true,
    paternal_last_name: true,
    maternal_last_name: true,
    email: true
  }
});
```

---

### 8.2 Obtener roles de usuario en club

```typescript
const userRoles = await prisma.club_role_assignments.findMany({
  where: {
    user_id: userId,
    club_adv_id: clubAdvId,
    ecclesiastical_year_id: currentYearId,
    active: true
  },
  include: {
    roles: {
      select: {
        role_name: true,
        role_category: true
      }
    }
  }
});
```

---

### 8.3 Verificar si usuario tiene rol específico

```typescript
const hasRole = await prisma.club_role_assignments.count({
  where: {
    user_id: userId,
    club_adv_id: clubAdvId,
    ecclesiastical_year_id: currentYearId,
    active: true,
    roles: {
      role_name: roleName,
      role_category: 'CLUB'
    }
  }
}) > 0;
```

---

### 8.4 Asignar rol a usuario

```typescript
await prisma.club_role_assignments.create({
  data: {
    user_id: userId,
    role_id: roleId,
    club_adv_id: clubAdvId,
    ecclesiastical_year_id: currentYearId,
    start_date: new Date(),
    active: true,
    status: 'active'
  }
});
```

---

## 📊 Uso en Endpoints

### GET /api/v1/clubs/:clubId/members
```sql
-- Query usado internamente
SELECT DISTINCT ... FROM v_active_club_members
WHERE club_adv_id = :clubAdvId 
  AND ecclesiastical_year_id = :currentYearId
ORDER BY name, paternal_last_name;
```

### GET /api/v1/users/:userId/clubs
```sql
-- Obtener todos los clubes del usuario
SELECT DISTINCT 
  COALESCE(ca.id, cp.id, cmg.id) AS club_instance_id,
  COALESCE(ca.name, cp.name, cmg.name) AS club_name,
  ey.start_date AS year_start
FROM club_role_assignments cra
LEFT JOIN club_adventurers ca ON cra.club_adv_id = ca.id
LEFT JOIN club_pathfinders cp ON cra.club_pathf_id = cp.id
LEFT JOIN club_master_guild cmg ON cra.club_mg_id = cmg.id
JOIN ecclesiastical_years ey ON cra.ecclesiastical_year_id = ey.id
WHERE cra.user_id = :userId AND cra.active = true;
```

---

**Generado**: 2026-01-29  
**Propósito**: Referencia rápida para queries de membresía y roles
