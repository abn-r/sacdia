# Análisis de Consistencia de Documentación - SACDIA

**Fecha**: 28 de enero de 2026  
**Objetivo**: Verificar consistencia entre todos los documentos clave del proyecto

---

## 📋 Documentos Analizados

1. ✅ `docs/procesos-sacdia.md` - Procesos de negocio
2. ✅ `docs/restapi/restrucura-roles.md` - Sistema de roles y permisos
3. ✅ `.specs/_steering/product.md` - Visión del producto
4. ✅ `.specs/_steering/tech.md` - Stack tecnológico
5. ✅ `.specs/_steering/structure.md` - Estructura del proyecto
6. ✅ `.specs/_steering/coding-standards.md` - Estándares de código
7. ✅ `.specs/_steering/data-guidelines.md` - Guías de datos
8. ✅ `docs/database/relations.md` - Relaciones de BD
9. ✅ `docs/restapi/analisis-completo-api.md` - Análisis API actual
10. ✅ `docs/restapi/reestructuracion-endpoints-versionado.md` - Propuesta de versionado

---

## 🔍 Hallazgos Críticos

### 1. Sistema de Roles - DISCREPANCIA IMPORTANTE

#### En `restrucura-roles.md`:
```typescript
- Roles tienen campo `role_category`: 'GLOBAL' | 'CLUB'
- Roles globales en tabla: users_roles
- Roles de club en tabla: club_role_assignments
- Cada asignación de club vincula a:
  - club_adv_id (Aventureros)
  - club_pathf_id (Conquistadores)  
  - club_mg_id (Guías Mayores)
  - ecclesiastical_year (año eclesiástico)
```

#### En `procesos-sacdia.md`:
```
- No menciona `role_category`
- Solo menciona tabla `users_roles` como relación user-rol
- No detalla club_role_assignments
- No menciona años eclesiásticos en post-registro
```

#### En mis documentos generados:
```typescript
- Sí incluí sistema RBAC básico
- NO incluí role_category (GLOBAL vs CLUB)
- NO incluí club_role_assignments detallado
- NO incluí ecclesiastical_year en el flujo
```

**ACCIÓN REQUERIDA**: Actualizar documentos técnicos para incluir sistema completo de roles.

---

### 2. Post-Registro - Proceso 3 (Selección de Club)

#### En `procesos-sacdia.md`:
```
Paso 2: Selección de "tipo de club" dentro del club
  - Al seleccionar un club, se consultan tipos (aventureros, conquistadores, GM)
  - Se auto-selecciona según edad del usuario
  Paso 6: Se consultan clases relacionadas al tipo de club
  
Almacenamiento (Paso 8):
  1. País, unión, campo local → tabla users
  2. Relación con club → "tablas correspondientes"
  3. Inscripción en clase → users_classes
  4. users_pr.complete = true
```

#### En `restrucura-roles.md`:
```json
{
  "club_adventurers": {
    "club_adv_id": 10
  },
  "club_pathfinders": null,
  "club_master_guild": null
}
```

**Clarificación necesaria**:
- ¿El club es un contenedor (`clubs`) y tiene 3 instancias posibles?
- ¿Cómo se relaciona `users` con las instancias de club?
- ¿Existe tabla `club_members` o la relación está en `club_role_assignments`?

#### En mis documentos:
```typescript
// Asumí creación directa en club_role_assignments
await tx.club_role_assignments.create({
  data: {
    user_id: userId,
    role_id: memberRole.id,
    [dto.clubType + '_id']: dto.clubInstanceId,  // ✅ Esto coincide con restrucura-roles
    start_date: new Date(),
    is_active: true,
    status: 'pending',
  },
});
```

**STATUS**: ✅ Parcialmente correcto, pero falta incluir `ecclesiastical_year_id`

---

### 3. Tabla de Usuarios - Campos

#### En `procesos-sacdia.md` (Proceso 2 - Información Personal):
```
Campos a almacenar en tabla users:
- gender (genero)
- birthdate (fecha de nacimiento)
- is_baptized (booleano)
- baptism_date (fecha de bautismo, opcional)
- country_id
- union_id
- local_field_id
```

#### En mis documentos:
```typescript
// ✅ Incluí todos estos campos
PATCH /api/v1/users/:userId
{
  gender: 'M' | 'F';
  birthdate: string;
  is_baptized: boolean;
  baptism_date?: string;
}
```

**STATUS**: ✅ Consistente

---

### 4. Fotografía de Perfil - Storage

#### En `procesos-sacdia.md`:
```
Bucket: profile-pictures
Nombre archivo: photo-{uuid del usuario}.{extensión}
```

#### En `tech.md`:
```
Storage: Supabase Storage
```

#### En mis documentos:
```typescript
const fileName = `photo-${userId}.${file.mimetype.split('/')[1]}`;
await this.supabase.storage
  .from('profile-pictures')
  .upload(fileName, file.buffer, { upsert: true });
```

**STATUS**: ✅ Consistente

---

### 5. Validación de Emails - Formato

#### En `data-guidelines.md`:
```typescript
email: z.string().email().max(255)
```

#### En `coding-standards.md`:
```typescript
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
```

#### En mis documentos:
```typescript
@IsEmail()
email: string;
```

**STATUS**: ✅ Consistente (class-validator usa validación estándar)

---

### 6. Contactos de Emergencia - Límite

#### En `procesos-sacdia.md`:
```
Validación: Se espera que el usuario pueda agregar hasta 5 contactos de emergencia.
Esto se debe de validar en el backend.
```

#### En mis documentos:
```typescript
// ❌ NO incluí validación de máximo 5 contactos
```

**ACCIÓN REQUERIDA**: Agregar validación de límite.

---

### 7. Representante Legal para Menores

#### En `procesos-sacdia.md`:
```
Si el usuario es menor de edad, se debe de agregar un "representante legal"
(padre, madre, tutor) y se almacene en una tabla aún por definir.
```

#### En mis documentos:
```typescript
// ❌ NO incluí representante legal
```

**ACCIÓN REQUERIDA**: Definir tabla y flujo para representantes legales.

---

### 8. Nombre de Campos - Inconsistencias

#### En `procesos-sacdia.md`:
```
- Apellido paterno
- Apellido materno
```

#### En `restrucura-roles.md`:
```json
{
  "paternal_last_name": "Pérez",
  "mother_last_name": "Gómez"
}
```

#### ¿Cuál usar en el código?
- `p_lastname` y `m_lastname` (abreviado)
- `paternal_last_name` y `maternal_last_name` (completo)
- `paternal_last_name` and `mother_last_name` (mixto - actual en restrucura-roles)

**ACCIÓN REQUERIDA**: Estandarizar nombres de campos.

---

### 9. Edad del Usuario - Validación

#### En `procesos-sacdia.md`:
```
Edad mínima: 3 años
Edad máxima: 99 años
```

#### En mis documentos:
```typescript
@IsDateString()
@Validate(AgeValidator, { min: 3, max: 99 })
birthdate: string;
```

**STATUS**: ✅ Consistente

---

### 10. Tabla `users_pr` - Tracking de Pasos

#### En `procesos-sacdia.md`:
```
- Paso 1: Fotografía → marcar completado
- Paso 2: Info Personal → marcar completado  
- Paso 3: Selección Club → marcar complete = true
```

#### ¿Campos necesarios en `users_pr`?
```typescript
interface UsersPr {
  user_id: string;
  complete: boolean;
  
  // ¿Necesitamos estos campos?
  profile_picture_complete?: boolean;
  personal_info_complete?: boolean;
  club_selection_complete?: boolean;
}
```

**ACCIÓN REQUERIDA**: Confirmar estructura de `users_pr`.

---

## 📊 Resumen de Discrepancias

### Críticas (Requieren acción inmediata)

1. ⚠️ **Sistema de roles**: Falta `role_category`, `club_role_assignments` completo, y `ecclesiastical_year`
2. ⚠️ **Representante legal**: No implementado, tabla no definida
3. ⚠️ **Límite de contactos**: Validación de máximo 5 no implementada
4. ⚠️ **Tracking de pasos post-registro**: Campos adicionales en `users_pr` no confirmados

### Moderadas (Definir estándar)

5. ⚠️ **Nombres de campos**: Inconsistencia entre `p_lastname`/`paternal_last_name`
6. ⚠️ **Relación users-club**: Clarificar si es `club_role_assignments` o tabla separada

### Menores (Ya resueltas o consistentes)

7. ✅ Fotografía de perfil
8. ✅ Validación de edad
9. ✅ Validación de emails
10. ✅ Campos personales básicos

---

## ✅ Documentos Consistentes

Los siguientes aspectos están bien alineados:

- **Stack tecnológico**: NestJS, Prisma, Supabase, Flutter
- **Estructura de proyecto**: Monorepo backend+admin, repo separado mobile
- **Autenticación**: Supabase Auth con JWT
- **Estándares de código**: TypeScript, ESLint, Prettier
- **Validación**: Zod para frontend, class-validator para backend
- **Storage**: Supabase Storage para archivos

---

## 🎯 Acciones Recomendadas

### Inmediatas

1. **Actualizar `especificacion-tecnica-nueva-api.md`**:
   - Incluir categorías de roles (GLOBAL vs CLUB)
   - Agregar tabla `club_role_assignments` detallada
   - Incluir `ecclesiastical_year` en asignaciones

2. **Actualizar `mapeo-procesos-endpoints.md`**:
   - Corregir Proceso 3 de post-registro para incluir `ecclesiastical_year_id`
   - Agregar validación de máximo 5 contactos de emergencia
   - Documentar flujo de representante legal (pendiente de definición)

3. **Crear documento de estandarización**:
   - Definir nombres de campo definitivos (`p_lastname` vs `paternal_last_name`)
   - Confirmar estructura exacta de `users_pr`
   - Documentar relación users-club-instances

### Mediano Plazo

4. **Definir tabla de representantes legales**:
   - Nombre: `legal_representatives` o `guardians`
   - Campos: `user_id`, `guardian_type`, `name`, `relationship_type_id`
   - Validación: Solo para menores de 18 años

5. **Crear documento de glosario**:
   - Términos en español e inglés
   - Nombres de tablas
   - Nombres de campos
   - Convenciones de nomenclatura

---

## 📝 Preguntas para el Usuario

1. **Nombres de campos**: ¿Prefieres `p_lastname` (abreviado) o `paternal_last_name` (descriptivo)?

2. **users_pr**: ¿Necesitamos campos individuales para tracking (`profile_picture_complete`, etc.) o solo `complete: boolean`?

3. **Representante legal**: ¿Crear tabla nueva o agregar campos a `users`?

4. **club_role_assignments**: ¿Todos los miembros tienen un rol de club o existe membresía sin rol?

5. **ecclesiastical_year**: ¿Se selecciona en post-registro o se asigna automáticamente el año actual?

---

**Generado**: 2026-01-28  
**Status**: Pendiente de revisión y decisiones
