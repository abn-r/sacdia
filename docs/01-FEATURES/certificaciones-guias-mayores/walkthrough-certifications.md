# Walkthrough: Certifications (Certificaciones para Guías Mayores)

**Módulo**: Certifications
**Versión API**: 2.2
**Fecha**: 3 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Certifications** proporciona un sistema de certificaciones especializado exclusivamente para **Guías Mayores investidos**. Este módulo permite:

- Inscripción en múltiples certificaciones simultáneamente
- Sistema de progreso por módulos y secciones
- Validación automática de elegibilidad (solo GM investidos)
- Tracking de completion_status
- Estructura similar al módulo de Classes

**Diferencias clave con Classes**:
- ✅ Solo para Guías Mayores investidos
- ✅ Permite múltiples inscripciones paralelas (sin restricción de una sola clase activa)
- ✅ No requiere aprobación de director para inscripción

---

## 🎯 Flujo Completo

### 1. Verificar Elegibilidad del Usuario

Antes de permitir la inscripción, el frontend debe verificar que el usuario es un Guía Mayor investido.

**Endpoint**: `GET /api/v1/users/:userId/classes`

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/users/uuid-123/classes \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "enrollment_id": 1,
      "class_id": 10,
      "class": {
        "class_id": 10,
        "name": "Guía Mayor",
        "club_type_id": 3
      },
      "current_class": true,
      "investiture": true,  // ✅ CRÍTICO: Debe ser true
      "enrollment_date": "2025-03-15T00:00:00.000Z"
    }
  ]
}
```

**Validación Frontend**:
```typescript
const isEligible = userClasses.some(
  c => c.class.name === 'Guía Mayor' && c.investiture === true
);
```

---

### 2. Listar Certificaciones Disponibles

**Endpoint**: `GET /api/v1/certifications`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/certifications \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "certification_id": 1,
      "name": "Instructor de Aventureros",
      "description": "Certificación para instruir clubs de Aventureros",
      "duration_hours": 40,
      "modules_count": 5,
      "active": true
    },
    {
      "certification_id": 2,
      "name": "Instructor de Conquistadores",
      "description": "Certificación para instruir clubs de Conquistadores",
      "duration_hours": 60,
      "modules_count": 6,
      "active": true
    },
    {
      "certification_id": 3,
      "name": "Tesorero de Club",
      "description": "Certificación para gestión financiera de clubes",
      "duration_hours": 20,
      "modules_count": 3,
      "active": true
    }
  ]
}
```

---

### 3. Ver Detalles de una Certificación

**Endpoint**: `GET /api/v1/certifications/:id`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/certifications/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "certification_id": 1,
    "name": "Instructor de Aventureros",
    "description": "Certificación para instruir clubs de Aventureros",
    "duration_hours": 40,
    "active": true,
    "modules": [
      {
        "module_id": 1,
        "name": "Filosofía del Club de Aventureros",
        "description": "Historia y propósito del ministerio",
        "order": 1,
        "sections": [
          {
            "section_id": 1,
            "name": "Historia de los Aventureros",
            "description": "Origen y evolución",
            "order": 1,
            "requirements": "Estudiar material y completar cuestionario"
          },
          {
            "section_id": 2,
            "name": "Estructura organizacional",
            "description": "Roles y responsabilidades",
            "order": 2,
            "requirements": "Identificar roles en un club modelo"
          }
        ]
      },
      {
        "module_id": 2,
        "name": "Desarrollo Infantil",
        "description": "Psicología del niño de 6-9 años",
        "order": 2,
        "sections": [
          {
            "section_id": 3,
            "name": "Etapas de desarrollo",
            "description": "Características por edad",
            "order": 1
          }
        ]
      }
    ]
  }
}
```

---

### 4. Inscribirse en una Certificación

**Endpoint**: `POST /api/v1/users/:userId/certifications/enroll`
**Autenticación**: Requerida
**Validación**: Solo GM investidos

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/users/uuid-123/certifications/enroll \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "certification_id": 1
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "enrollment_id": 1,
    "user_id": "uuid-123",
    "certification_id": 1,
    "enrollment_date": "2026-02-03T10:00:00.000Z",
    "completion_status": false,
    "completion_date": null,
    "active": true,
    "certification": {
      "name": "Instructor de Aventureros",
      "duration_hours": 40
    }
  }
}
```

**Error - Usuario no elegible** (403 Forbidden):

```json
{
  "statusCode": 403,
  "message": "Only invested Guías Mayores can enroll in certifications",
  "error": "Forbidden"
}
```

---

### 5. Listar Mis Certificaciones

**Endpoint**: `GET /api/v1/users/:userId/certifications`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/users/uuid-123/certifications \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "enrollment_id": 1,
      "certification_id": 1,
      "certification": {
        "name": "Instructor de Aventureros",
        "duration_hours": 40
      },
      "enrollment_date": "2026-02-03T10:00:00.000Z",
      "completion_status": false,
      "progress_percentage": 35.5,
      "modules_completed": 1,
      "modules_total": 5,
      "active": true
    },
    {
      "enrollment_id": 2,
      "certification_id": 2,
      "certification": {
        "name": "Instructor de Conquistadores",
        "duration_hours": 60
      },
      "enrollment_date": "2026-02-05T14:30:00.000Z",
      "completion_status": false,
      "progress_percentage": 10.0,
      "modules_completed": 0,
      "modules_total": 6,
      "active": true
    }
  ]
}
```

---

### 6. Ver Progreso de una Certificación

**Endpoint**: `GET /api/v1/users/:userId/certifications/:certificationId/progress`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/users/uuid-123/certifications/1/progress \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "enrollment_id": 1,
    "certification_id": 1,
    "certification_name": "Instructor de Aventureros",
    "progress_percentage": 35.5,
    "completion_status": false,
    "enrollment_date": "2026-02-03T10:00:00.000Z",
    "modules": [
      {
        "module_id": 1,
        "name": "Filosofía del Club de Aventureros",
        "completed": true,
        "completion_date": "2026-02-10T16:00:00.000Z",
        "sections": [
          {
            "section_id": 1,
            "name": "Historia de los Aventureros",
            "completed": true,
            "completion_date": "2026-02-08T10:00:00.000Z"
          },
          {
            "section_id": 2,
            "name": "Estructura organizacional",
            "completed": true,
            "completion_date": "2026-02-10T16:00:00.000Z"
          }
        ]
      },
      {
        "module_id": 2,
        "name": "Desarrollo Infantil",
        "completed": false,
        "sections": [
          {
            "section_id": 3,
            "name": "Etapas de desarrollo",
            "completed": false
          }
        ]
      }
    ]
  }
}
```

---

### 7. Actualizar Progreso de una Sección

**Endpoint**: `PATCH /api/v1/users/:userId/certifications/:certificationId/progress`
**Autenticación**: Requerida

**Request Body**:

```json
{
  "module_id": 2,
  "section_id": 3,
  "completed": true
}
```

**Request**:

```bash
curl -X PATCH http://localhost:3000/api/v1/users/uuid-123/certifications/1/progress \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 2,
    "section_id": 3,
    "completed": true
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "section_progress_id": 5,
    "module_id": 2,
    "section_id": 3,
    "completed": true,
    "completion_date": "2026-02-11T09:30:00.000Z",
    "module_progress": {
      "module_id": 2,
      "completed": true,
      "completion_date": "2026-02-11T09:30:00.000Z"
    },
    "certification_progress": {
      "progress_percentage": 55.0,
      "completion_status": false
    }
  }
}
```

**Auto-completado**:
- ✅ Si todas las secciones de un módulo están completas → módulo se marca como completo
- ✅ Si todos los módulos están completos → certificación se marca como completa

---

### 8. Abandonar una Certificación

**Endpoint**: `DELETE /api/v1/users/:userId/certifications/:certificationId`
**Autenticación**: Requerida

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/users/uuid-123/certifications/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "Certification enrollment deleted successfully"
}
```

---

## 💡 Casos de Uso

### Caso 1: Guía Mayor se Certifica como Instructor

**Escenario**: Un Guía Mayor investido quiere certificarse para ser instructor de Aventureros.

**Flujo**:

1. **Verificar elegibilidad** (Frontend)
   ```bash
   GET /api/v1/users/:userId/classes
   # Validar: investiture = true en clase "Guía Mayor"
   ```

2. **Ver certificaciones disponibles**
   ```bash
   GET /api/v1/certifications
   ```

3. **Ver detalles de certificación**
   ```bash
   GET /api/v1/certifications/1
   # Ver módulos, secciones y requisitos
   ```

4. **Inscribirse**
   ```bash
   POST /api/v1/users/:userId/certifications/enroll
   Body: { certification_id: 1 }
   ```

5. **Ir completando secciones**
   ```bash
   PATCH /api/v1/users/:userId/certifications/1/progress
   Body: { module_id: 1, section_id: 1, completed: true }
   ```

6. **Consultar progreso**
   ```bash
   GET /api/v1/users/:userId/certifications/1/progress
   # Ver porcentaje de avance
   ```

---

### Caso 2: Múltiples Certificaciones Paralelas

**Escenario**: Un Guía Mayor quiere tomar 2 certificaciones al mismo tiempo.

**Flujo**:

1. **Inscribirse en primera certificación**
   ```bash
   POST /api/v1/users/:userId/certifications/enroll
   Body: { certification_id: 1 }  # Instructor de Aventureros
   # ✅ Éxito
   ```

2. **Inscribirse en segunda certificación** (sin esperar a completar la primera)
   ```bash
   POST /api/v1/users/:userId/certifications/enroll
   Body: { certification_id: 2 }  # Instructor de Conquistadores
   # ✅ Éxito - A diferencia de Classes, esto está permitido
   ```

3. **Ver todas mis certificaciones activas**
   ```bash
   GET /api/v1/users/:userId/certifications
   # Response: 2 certificaciones activas
   ```

4. **Trabajar en ambas simultáneamente**
   - Actualizar progreso de certificación 1
   - Actualizar progreso de certificación 2
   - Sin restricciones de una sola activa

---

### Caso 3: Usuario No Investido Intenta Inscribirse

**Escenario**: Un Conquistador intenta inscribirse en una certificación.

**Flujo**:

1. **Intentar inscribirse**
   ```bash
   POST /api/v1/users/:userId/certifications/enroll
   Body: { certification_id: 1 }
   ```

2. **Backend valida elegibilidad**
   ```typescript
   const enrollment = await prisma.users_classes.findFirst({
     where: {
       user_id: userId,
       classes: { name: 'Guía Mayor' },
       investiture: true
     }
   });

   if (!enrollment) {
     throw new ForbiddenException('Only invested Guías Mayores...');
   }
   ```

3. **Response error** (403 Forbidden)
   ```json
   {
     "statusCode": 403,
     "message": "Only invested Guías Mayores can enroll in certifications"
   }
   ```

---

## 🔒 Validaciones y Errores

### Error 1: Usuario No Elegible

**Causa**: Usuario no es Guía Mayor investido.

**Response** (403 Forbidden):

```json
{
  "statusCode": 403,
  "message": "Only invested Guías Mayores can enroll in certifications",
  "error": "Forbidden"
}
```

**Solución**:
1. Completar clase de Guía Mayor
2. Obtener investidura
3. Intentar inscripción nuevamente

---

### Error 2: Certificación No Encontrada

**Causa**: El `certification_id` no existe o está inactiva.

**Response** (404 Not Found):

```json
{
  "statusCode": 404,
  "message": "Certification not found",
  "error": "Not Found"
}
```

**Solución**: Verificar que el ID es correcto y la certificación está activa.

---

### Error 3: Ya Inscrito en Esta Certificación

**Causa**: Usuario ya tiene una inscripción activa en esta certificación.

**Response** (409 Conflict):

```json
{
  "statusCode": 409,
  "message": "User already enrolled in this certification",
  "error": "Conflict"
}
```

**Solución**: Ver progreso de la inscripción existente en lugar de crear una nueva.

---

### Error 4: Sección Inválida

**Causa**: El `section_id` no pertenece al módulo o certificación indicados.

**Response** (400 Bad Request):

```json
{
  "statusCode": 400,
  "message": "Invalid module or section for this certification",
  "error": "Bad Request"
}
```

**Solución**: Verificar que el `module_id` y `section_id` son correctos.

---

## 🔑 Validaciones del Backend

### Al Inscribirse

```typescript
async enroll(userId: string, dto: EnrollCertificationDto) {
  // 1. Validar elegibilidad (GM investido)
  await this.validateEligibility(userId);

  // 2. NO validar inscripciones previas (permitir múltiples)
  // Classes tiene: if (existingEnrollment) throw ConflictException
  // Certifications NO tiene esa validación

  // 3. Crear enrollment
  return await this.prisma.users_certifications.create({
    data: {
      user_id: userId,
      certification_id: dto.certification_id,
      enrollment_date: new Date(),
      completion_status: false,
      active: true
    }
  });
}

async validateEligibility(userId: string): Promise<boolean> {
  const enrollment = await this.prisma.users_classes.findFirst({
    where: {
      user_id: userId,
      classes: { name: 'Guía Mayor' },
      investiture: true  // CRÍTICO
    }
  });

  if (!enrollment) {
    throw new ForbiddenException(
      'Only invested Guías Mayores can enroll in certifications'
    );
  }

  return true;
}
```

### Al Actualizar Progreso

```typescript
async updateProgress(userId: string, certificationId: number, dto: UpdateProgressDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Marcar sección como completa
    const sectionProgress = await tx.certification_section_progress.upsert({
      where: {
        user_id_section_id: { user_id: userId, section_id: dto.section_id }
      },
      create: {
        user_id: userId,
        section_id: dto.section_id,
        completed: dto.completed,
        completion_date: dto.completed ? new Date() : null
      },
      update: {
        completed: dto.completed,
        completion_date: dto.completed ? new Date() : null
      }
    });

    // 2. Verificar si módulo está completo
    const allSections = await tx.certification_sections.findMany({
      where: { module_id: dto.module_id }
    });

    const completedSections = await tx.certification_section_progress.count({
      where: {
        user_id: userId,
        section_id: { in: allSections.map(s => s.section_id) },
        completed: true
      }
    });

    if (completedSections === allSections.length) {
      // Marcar módulo como completo
      await tx.certification_module_progress.upsert({
        where: {
          user_id_module_id: { user_id: userId, module_id: dto.module_id }
        },
        create: {
          user_id: userId,
          module_id: dto.module_id,
          completed: true,
          completion_date: new Date()
        },
        update: {
          completed: true,
          completion_date: new Date()
        }
      });
    }

    // 3. Verificar si certificación está completa
    const allModules = await tx.certification_modules.findMany({
      where: { certification_id: certificationId }
    });

    const completedModules = await tx.certification_module_progress.count({
      where: {
        user_id: userId,
        module_id: { in: allModules.map(m => m.module_id) },
        completed: true
      }
    });

    if (completedModules === allModules.length) {
      // Marcar certificación como completa
      await tx.users_certifications.update({
        where: {
          user_id_certification_id: { user_id: userId, certification_id: certificationId }
        },
        data: {
          completion_status: true,
          completion_date: new Date()
        }
      });
    }

    return sectionProgress;
  });
}
```

---

## 📊 Modelos de Base de Datos

### Tabla: `certifications`

```prisma
model certifications {
  certification_id  Int       @id @default(autoincrement())
  name              String
  description       String?
  duration_hours    Int?
  active            Boolean   @default(true)
  created_at        DateTime  @default(now())
  updated_at        DateTime  @updatedAt

  certification_modules        certification_modules[]
  users_certifications         users_certifications[]
}
```

### Tabla: `users_certifications`

```prisma
model users_certifications {
  enrollment_id      Int       @id @default(autoincrement())
  user_id            String    @db.Uuid
  certification_id   Int
  enrollment_date    DateTime  @default(now())
  completion_status  Boolean   @default(false)
  completion_date    DateTime?
  active             Boolean   @default(true)

  users              users @relation(fields: [user_id], references: [id])
  certifications     certifications @relation(fields: [certification_id], references: [certification_id])

  @@unique([user_id, certification_id])
  @@index([user_id])
}
```

### Tabla: `certification_modules`

```prisma
model certification_modules {
  module_id         Int       @id @default(autoincrement())
  certification_id  Int
  name              String
  description       String?
  order             Int

  certifications              certifications @relation(fields: [certification_id], references: [certification_id])
  certification_sections      certification_sections[]
  certification_module_progress certification_module_progress[]
}
```

### Tabla: `certification_sections`

```prisma
model certification_sections {
  section_id    Int       @id @default(autoincrement())
  module_id     Int
  name          String
  description   String?
  requirements  String?
  order         Int

  certification_modules          certification_modules @relation(fields: [module_id], references: [module_id])
  certification_section_progress certification_section_progress[]
}
```

---

## 🧪 Testing

### Test E2E: `certifications.e2e-spec.ts`

```typescript
describe('Certifications API (e2e)', () => {
  let investedGmToken: string;
  let nonInvestedToken: string;

  it('POST /users/:userId/certifications/enroll - should allow invested GM', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/users/${investedGmId}/certifications/enroll`)
      .set('Authorization', `Bearer ${investedGmToken}`)
      .send({ certification_id: 1 })
      .expect(201);

    expect(response.body.data.certification_id).toBe(1);
  });

  it('POST /users/:userId/certifications/enroll - should reject non-invested', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/users/${nonInvestedId}/certifications/enroll`)
      .set('Authorization', `Bearer ${nonInvestedToken}`)
      .send({ certification_id: 1 })
      .expect(403);
  });

  it('POST /users/:userId/certifications/enroll - should allow multiple enrollments', async () => {
    // Primera certificación
    await request(app.getHttpServer())
      .post(`/api/v1/users/${investedGmId}/certifications/enroll`)
      .set('Authorization', `Bearer ${investedGmToken}`)
      .send({ certification_id: 1 })
      .expect(201);

    // Segunda certificación (sin esperar a completar la primera)
    await request(app.getHttpServer())
      .post(`/api/v1/users/${investedGmId}/certifications/enroll`)
      .set('Authorization', `Bearer ${investedGmToken}`)
      .send({ certification_id: 2 })
      .expect(201); // ✅ No debe fallar
  });

  it('PATCH /users/:userId/certifications/:id/progress - should update section', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/api/v1/users/${investedGmId}/certifications/1/progress`)
      .set('Authorization', `Bearer ${investedGmToken}`)
      .send({
        module_id: 1,
        section_id: 1,
        completed: true
      })
      .expect(200);

    expect(response.body.data.completed).toBe(true);
  });
});
```

---

## 📝 Notas Importantes

1. **Validación de Elegibilidad**: El backend valida automáticamente que el usuario sea GM investido en cada inscripción.

2. **Múltiples Certificaciones**: A diferencia del módulo de Classes, las certificaciones permiten múltiples inscripciones activas simultáneamente.

3. **Auto-completado en Cascada**:
   - Todas las secciones completas → Módulo completo
   - Todos los módulos completos → Certificación completa

4. **Soft Deletes**: Las inscripciones usan `active = false` en lugar de eliminación física.

5. **Estructura Similar a Classes**: El código puede ser copiado de Classes con adaptaciones menores.

6. **Sin Restricción de Director**: Los usuarios pueden inscribirse directamente sin aprobación.

---

**Documento creado**: 2026-02-03
**Versión**: 1.0
**Autor**: Sistema SACDIA
