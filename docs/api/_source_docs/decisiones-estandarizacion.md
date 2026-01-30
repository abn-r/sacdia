# Decisiones de Estandarización - SACDIA

**Fecha**: 29 de enero de 2026  
**Status**: Aprobado por usuario

---

## 1. Nombres de Campos

### ✅ DECISIÓN FINAL

Usar nombres **descriptivos completos** en inglés:

```typescript
// ✅ USAR (Descriptivo)
interface User {
  id: string;
  email: string;
  name: string;
  paternal_last_name: string;  // ← Descriptivo
  maternal_last_name: string;  // ← Descriptivo (cambio de mother_last_name)
  gender: 'M' | 'F';
  birthdate: string;
  is_baptized: boolean;
  baptism_date?: string;
}

// ❌ NO USAR (Abreviado)
interface User {
  p_lastname: string;  // Muy corto
  m_lastname: string;  // No claro
}
```

**Impacto**:
- ✅ Actualizar schema Prisma
- ✅ Actualizar DTOs en NestJS
- ✅ Actualizar modelos en Flutter
- ✅ Actualizar documentación

---

## 2. Tabla `users_pr` - Tracking de Post-Registro

### ✅ DECISIÓN FINAL: Opción B - Tracking Individual

**Estructura confirmada**:
```sql
CREATE TABLE users_pr (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  complete BOOLEAN DEFAULT false,
  profile_picture_complete BOOLEAN DEFAULT false,
  personal_info_complete BOOLEAN DEFAULT false,
  club_selection_complete BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Ventajas**:
- ✅ App puede retomar exactamente donde se quedó el usuario
- ✅ Métricas de abandono por paso
- ✅ Mejor UX (no repetir pasos ya completados)
- ✅ Validación granular del progreso

**Flujo**:
1. Paso 1 completo → `profile_picture_complete = true`
2. Paso 2 completo → `personal_info_complete = true`
3. Paso 3 completo → `club_selection_complete = true` AND `complete = true`

---

## 3. Representante Legal para Menores

### ✅ DECISIÓN FINAL

**Crear nueva tabla**: `legal_representatives`

```sql
CREATE TABLE legal_representatives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Opción 1: Representante es usuario registrado
  representative_user_id UUID REFERENCES users(id),
  
  -- Opción 2: Solo datos del representante (si no es usuario)
  name VARCHAR(100),
  paternal_last_name VARCHAR(100),
  maternal_last_name VARCHAR(100),
  phone VARCHAR(20),
  
  -- Tipo de relación
  relationship_type_id UUID REFERENCES relationship_types(id),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT one_representative_per_user UNIQUE(user_id),
  CONSTRAINT representative_data_check CHECK (
    (representative_user_id IS NOT NULL) OR 
    (name IS NOT NULL AND paternal_last_name IS NOT NULL AND phone IS NOT NULL)
  )
);
```

**Reglas de negocio**:
1. ✅ Máximo 1 representante por usuario
2. ✅ Puede ser usuario registrado (`representative_user_id`) o datos simples
3. ✅ Modificable a futuro
4. ✅ Solo requerido para menores de 18 años (validar en backend)

**Endpoints**:
```typescript
POST   /api/v1/users/:userId/legal-representative
GET    /api/v1/users/:userId/legal-representative
PATCH  /api/v1/users/:userId/legal-representative
DELETE /api/v1/users/:userId/legal-representative
```

---

## 4. Año Eclesiástico (Ecclesiastical Year)

### ✅ DECISIÓN FINAL

**Auto-asignar** año eclesiástico actual al usuario.

**Implementación**:
```typescript
// En post-registro, Paso 3: Selección de club
async completeClubSelection(userId: string, dto: CompleteClubSelectionDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Obtener año eclesiástico actual
    const currentYear = await tx.ecclesiastical_years.findFirst({
      where: {
        start_date: { lte: new Date() },
        end_date: { gte: new Date() }
      }
    });
    
    if (!currentYear) {
      throw new Error('No active ecclesiastical year found');
    }
    
    // 2. Asignar rol de miembro con año actual
    await tx.club_role_assignments.create({
      data: {
        user_id: userId,
        role_id: memberRole.id,
        [dto.clubType + '_id']: dto.clubInstanceId,
        ecclesiastical_year_id: currentYear.id,  // ← Auto-asignado
        start_date: new Date(),
        active: true,
        status: 'pending'
      }
    });
  });
}
```

**Reglas**:
- ✅ Usuario **NUNCA** selecciona año eclesiástico
- ✅ Sistema auto-asigna el año actual
- ✅ Admin panel puede cambiar años en el futuro

---

## 5. Sistema de Membresía y Roles

### ✅ DECISIÓN FINAL

**Todos los miembros tienen rol** en `club_role_assignments`.

**Flujo de registro**:
```typescript
// En registro (PROCESO 2)
await tx.users_roles.create({
  data: {
    user_id: userId,
    role_id: 'uuid-del-rol-user',  // Rol GLOBAL: "user"
  }
});

// En post-registro - Paso 3 (PROCESO 3 del post-registro)
await tx.club_role_assignments.create({
  data: {
    user_id: userId,
    role_id: 'uuid-del-rol-member',  // Rol CLUB: "member"
    club_adv_id: clubInstanceId,  // O club_pathf_id o club_mg_id
    ecclesiastical_year_id: currentYear.id,
    start_date: new Date(),
    active: true,
    status: 'pending'  // Pendiente de aprobación por director
  }
});
```

**Roles de sistema**:

### Roles Globales (tabla: `users_roles`)
```typescript
- super_admin  // Acceso total
- admin        // Admin de campo local
- coordinator  // Coordinador
- user         // Usuario estándar (asignado en registro)
```

### Roles de Club (tabla: `club_role_assignments`)
```typescript
- director      // Director del club
- subdirector   // Subdirector
- secretary     // Secretario
- treasurer     // Tesorero
- counselor     // Consejero
- member        // Miembro regular (asignado en post-registro)
```

**Tabla `roles` tiene campo `role_category`**:
```sql
CREATE TABLE roles (
  id UUID PRIMARY KEY,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  role_category VARCHAR(10) NOT NULL CHECK (role_category IN ('GLOBAL', 'CLUB')),
  description TEXT,
  active BOOLEAN DEFAULT true
);
```

---

## 📊 Resumen de Cambios Requeridos

### Documentos a actualizar

1. ✅ **especificacion-tecnica-nueva-api.md**
   - Cambiar nombres de campos (p_lastname → paternal_last_name)
   - Agregar tabla `legal_representatives`
   - Incluir `role_category` en roles
   - Auto-asignación de `ecclesiastical_year_id`

2. ✅ **mapeo-procesos-endpoints.md**
   - Actualizar DTOs con nombres descriptivos
   - Agregar endpoints de representante legal
   - Incluir validación edad < 18 para representante
   - Agregar `ecclesiastical_year_id` en Proceso 3

3. ✅ **Nuevo**: `schema-legal-representatives.sql`
   - Crear migration para tabla nueva

4. ✅ **Completado**: Estructura final de `users_pr` confirmada (Opción B)

---

## ✅ Checklist de Implementación

### Base de Datos
- [ ] Actualizar `schema.prisma` con `paternal_last_name`/`maternal_last_name`
- [ ] Crear tabla `legal_representatives`
- [ ] Confirmar estructura de `users_pr`
- [ ] Agregar `role_category` a tabla `roles`
- [ ] Crear migration

### Backend (NestJS)
- [ ] Actualizar DTOs (RegisterDto, UpdateUserDto)
- [ ] Crear módulo `LegalRepresentativesModule`
- [ ] Auto-asignar `ecclesiastical_year_id` en post-registro
- [ ] Validar edad < 18 para requerir representante legal
- [ ] Actualizar RolesGuard para verificar `role_category`

### Frontend (Flutter)
- [ ] Actualizar modelos (`User`, `LegalRepresentative`)
- [ ] Agregar pantalla de representante legal en post-registro
- [ ] Validar edad y mostrar form condicionalmente

### Documentación
- [ ] Actualizar todos los documentos con decisiones
- [ ] Crear guía de migración de datos (si hay API existente)

---

**Generado**: 2026-01-29  
**Actualizado por**: Usuario  
**Status**: ✅ Todas las decisiones confirmadas - Listo para implementación
