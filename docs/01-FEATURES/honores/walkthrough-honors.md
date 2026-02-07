# Walkthrough: Honors (Especialidades)

**Módulo**: Honors
**Versión API**: 2.2
**Fecha**: 4 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Honors** (Especialidades) proporciona un sistema completo de gestión de especialidades para clubes de Conquistadores y Guías Mayores. Este módulo permite:

- Catálogo completo de especialidades por categorías
- Asignación de instructor por especialidad
- Sistema de requisitos y progreso
- Tracking de completitud por miembro
- Validación automática de instructor
- Certificación de especialidades completadas
- Filtrado por categoría, dificultad, tipo de club

**Características principales**:
- ✅ CRUD completo de especialidades
- ✅ Sistema de categorías (Naturaleza, Ciencia, Artes, etc.)
- ✅ Niveles de dificultad (Básico, Intermedio, Avanzado)
- ✅ Requisitos por especialidad
- ✅ Tracking de progreso individual
- ✅ Validación de instructor asignado
- ✅ Certificación al completar
- ✅ Integración con sistema de clases

---

## 🎯 Flujo Completo

### 1. Listar Categorías de Especialidades

**Endpoint**: `GET /api/v1/catalogs/honor-categories`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/catalogs/honor-categories \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "category_id": 1,
      "name": "Estudio de la Naturaleza",
      "description": "Especialidades relacionadas con flora, fauna y ecosistemas",
      "icon": "🌿",
      "active": true
    },
    {
      "category_id": 2,
      "name": "Actividades Misioneras y Comunitarias",
      "description": "Especialidades de servicio y evangelismo",
      "icon": "🤝",
      "active": true
    },
    {
      "category_id": 3,
      "name": "Artes y Habilidades Manuales",
      "description": "Especialidades artísticas y manualidades",
      "icon": "🎨",
      "active": true
    },
    {
      "category_id": 4,
      "name": "Ciencias y Salud",
      "description": "Especialidades científicas y de salud",
      "icon": "🔬",
      "active": true
    },
    {
      "category_id": 5,
      "name": "Actividades Recreativas",
      "description": "Deportes y actividades físicas",
      "icon": "⚽",
      "active": true
    },
    {
      "category_id": 6,
      "name": "Habilidades Domésticas",
      "description": "Especialidades del hogar",
      "icon": "🏠",
      "active": true
    },
    {
      "category_id": 7,
      "name": "Actividades Vocacionales",
      "description": "Especialidades profesionales y técnicas",
      "icon": "💼",
      "active": true
    },
    {
      "category_id": 8,
      "name": "Actividades Agrícolas",
      "description": "Especialidades de agricultura y ganadería",
      "icon": "🌾",
      "active": true
    }
  ]
}
```

---

### 2. Listar Especialidades Disponibles

**Endpoint**: `GET /api/v1/honors`
**Autenticación**: Requerida

**Query Parameters**:
- `categoryId`: Filtrar por categoría
- `difficulty`: Nivel de dificultad (1=Básico, 2=Intermedio, 3=Avanzado)
- `clubType`: Tipo de club (1=ADV, 2=PATHF, 3=MG)
- `search`: Buscar por nombre
- `page`: Número de página
- `limit`: Items por página

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/honors?categoryId=1&difficulty=1&limit=10" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "honor_id": 1,
      "name": "Aves",
      "description": "Estudio y observación de aves",
      "category": {
        "category_id": 1,
        "name": "Estudio de la Naturaleza",
        "icon": "🌿"
      },
      "difficulty": 1,
      "difficulty_label": "Básico",
      "club_type_id": 2,
      "club_type": "Conquistadores",
      "requirements_count": 10,
      "estimated_hours": 8,
      "instructor_required": true,
      "active": true,
      "patch_image": "https://storage.supabase.co/honors/patches/aves.jpg"
    },
    {
      "honor_id": 2,
      "name": "Flores",
      "description": "Identificación y estudio de flores",
      "category": {
        "category_id": 1,
        "name": "Estudio de la Naturaleza",
        "icon": "🌿"
      },
      "difficulty": 1,
      "difficulty_label": "Básico",
      "club_type_id": 2,
      "requirements_count": 12,
      "estimated_hours": 10,
      "instructor_required": true,
      "active": true,
      "patch_image": "https://storage.supabase.co/honors/patches/flores.jpg"
    }
  ],
  "meta": {
    "total": 150,
    "page": 1,
    "limit": 10,
    "totalPages": 15
  }
}
```

---

### 3. Ver Detalles de una Especialidad

**Endpoint**: `GET /api/v1/honors/:honorId`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/honors/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "honor_id": 1,
    "name": "Aves",
    "description": "Estudio y observación de aves. Aprende a identificar diferentes especies, sus hábitats y comportamientos.",
    "category": {
      "category_id": 1,
      "name": "Estudio de la Naturaleza"
    },
    "difficulty": 1,
    "difficulty_label": "Básico",
    "club_type_id": 2,
    "club_type": "Conquistadores",
    "estimated_hours": 8,
    "instructor_required": true,
    "requirements": [
      {
        "requirement_id": 1,
        "order": 1,
        "description": "Nombrar 10 especies de aves de tu región",
        "points": 10,
        "required": true
      },
      {
        "requirement_id": 2,
        "order": 2,
        "description": "Identificar 5 aves por su canto",
        "points": 15,
        "required": true
      },
      {
        "requirement_id": 3,
        "order": 3,
        "description": "Construir y colocar un comedero para aves",
        "points": 20,
        "required": true
      },
      {
        "requirement_id": 4,
        "order": 4,
        "description": "Observar y fotografiar al menos 15 especies diferentes",
        "points": 25,
        "required": true
      },
      {
        "requirement_id": 5,
        "order": 5,
        "description": "Crear un álbum de fotos con las aves observadas",
        "points": 30,
        "required": true
      }
    ],
    "total_points": 100,
    "active": true,
    "patch_image": "https://storage.supabase.co/honors/patches/aves.jpg",
    "created_at": "2025-01-15T00:00:00.000Z"
  }
}
```

---

### 4. Inscribir Miembro en Especialidad

**Endpoint**: `POST /api/v1/users/:userId/honors/enroll`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Instructor

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/users/uuid-member-123/honors/enroll \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "honor_id": 1,
    "instructor_user_id": "uuid-instructor-456"
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "enrollment_id": 45,
    "honor_id": 1,
    "user_id": "uuid-member-123",
    "instructor_user_id": "uuid-instructor-456",
    "enrollment_date": "2026-02-04T00:00:00.000Z",
    "completion_date": null,
    "completed": false,
    "progress_percentage": 0,
    "total_points_earned": 0,
    "active": true,
    "honor": {
      "name": "Aves",
      "difficulty": 1,
      "total_points": 100
    },
    "instructor": {
      "name": "Juan",
      "paternal_last_name": "Pérez",
      "maternal_last_name": "García"
    }
  }
}
```

**Validaciones**:
- ✅ Especialidad debe existir y estar activa
- ✅ Usuario no debe tener inscripción activa en la misma especialidad
- ✅ Instructor debe tener certificación en la especialidad (validación configurable)
- ✅ Usuario debe pertenecer al club
- ✅ Especialidad debe ser apropiada para el tipo de club del usuario

---

### 5. Listar Especialidades del Usuario

**Endpoint**: `GET /api/v1/users/:userId/honors`
**Autenticación**: Requerida

**Query Parameters**:
- `status`: Filtrar por estado (in_progress, completed)
- `categoryId`: Filtrar por categoría

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/users/uuid-member-123/honors?status=in_progress" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "enrollment_id": 45,
      "honor_id": 1,
      "honor": {
        "name": "Aves",
        "category": "Estudio de la Naturaleza",
        "difficulty": 1,
        "patch_image": "https://storage.supabase.co/honors/patches/aves.jpg"
      },
      "enrollment_date": "2026-02-04T00:00:00.000Z",
      "completion_date": null,
      "completed": false,
      "progress_percentage": 60,
      "total_points_earned": 60,
      "total_points": 100,
      "instructor": {
        "name": "Juan Pérez García"
      },
      "requirements_completed": 3,
      "total_requirements": 5,
      "active": true
    },
    {
      "enrollment_id": 46,
      "honor_id": 5,
      "honor": {
        "name": "Primeros Auxilios",
        "category": "Ciencias y Salud",
        "difficulty": 2,
        "patch_image": "https://storage.supabase.co/honors/patches/primeros-auxilios.jpg"
      },
      "enrollment_date": "2026-01-15T00:00:00.000Z",
      "completion_date": null,
      "completed": false,
      "progress_percentage": 25,
      "total_points_earned": 25,
      "total_points": 100,
      "instructor": {
        "name": "María González"
      },
      "requirements_completed": 2,
      "total_requirements": 8,
      "active": true
    }
  ]
}
```

---

### 6. Ver Progreso Detallado de una Especialidad

**Endpoint**: `GET /api/v1/users/:userId/honors/:enrollmentId/progress`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/users/uuid-member-123/honors/45/progress \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "enrollment_id": 45,
    "honor": {
      "honor_id": 1,
      "name": "Aves",
      "description": "Estudio y observación de aves",
      "category": "Estudio de la Naturaleza",
      "difficulty": 1,
      "total_points": 100
    },
    "enrollment_date": "2026-02-04T00:00:00.000Z",
    "completion_date": null,
    "completed": false,
    "progress_percentage": 60,
    "total_points_earned": 60,
    "instructor": {
      "user_id": "uuid-instructor-456",
      "name": "Juan",
      "paternal_last_name": "Pérez",
      "email": "juan.perez@example.com"
    },
    "requirements": [
      {
        "requirement_id": 1,
        "order": 1,
        "description": "Nombrar 10 especies de aves de tu región",
        "points": 10,
        "required": true,
        "completed": true,
        "completion_date": "2026-02-05T00:00:00.000Z",
        "evidences": {
          "species_list": [
            "Gorrión común", "Paloma", "Cuervo", "Colibrí",
            "Águila", "Lechuza", "Halcón", "Gaviota",
            "Perico", "Loro"
          ],
          "verified_by": "Juan Pérez"
        },
        "points_earned": 10
      },
      {
        "requirement_id": 2,
        "order": 2,
        "description": "Identificar 5 aves por su canto",
        "points": 15,
        "required": true,
        "completed": true,
        "completion_date": "2026-02-08T00:00:00.000Z",
        "evidences": {
          "audio_recordings": [
            "https://storage.supabase.co/audio/bird1.mp3",
            "https://storage.supabase.co/audio/bird2.mp3"
          ],
          "species_identified": [
            "Gorrión", "Paloma", "Cuervo", "Colibrí", "Loro"
          ]
        },
        "points_earned": 15
      },
      {
        "requirement_id": 3,
        "order": 3,
        "description": "Construir y colocar un comedero para aves",
        "points": 20,
        "required": true,
        "completed": true,
        "completion_date": "2026-02-10T00:00:00.000Z",
        "evidences": {
          "photos": [
            "https://storage.supabase.co/photos/comedero1.jpg",
            "https://storage.supabase.co/photos/comedero2.jpg"
          ],
          "location": "Jardín de casa",
          "materials_used": "Madera reciclada, clavos, pintura"
        },
        "points_earned": 20
      },
      {
        "requirement_id": 4,
        "order": 4,
        "description": "Observar y fotografiar al menos 15 especies diferentes",
        "points": 25,
        "required": true,
        "completed": true,
        "completion_date": "2026-02-15T00:00:00.000Z",
        "evidences": {
          "photo_album": "https://storage.supabase.co/albums/aves-observadas.pdf",
          "species_count": 18
        },
        "points_earned": 15
      },
      {
        "requirement_id": 5,
        "order": 5,
        "description": "Crear un álbum de fotos con las aves observadas",
        "points": 30,
        "required": true,
        "completed": false,
        "completion_date": null,
        "evidences": null,
        "points_earned": 0
      }
    ]
  }
}
```

---

### 7. Actualizar Progreso de un Requisito

**Endpoint**: `PATCH /api/v1/users/:userId/honors/:enrollmentId/requirements/:requirementId`
**Autenticación**: Requerida
**Roles**: Instructor asignado, Director, Subdirector

**Request**:

```bash
curl -X PATCH http://localhost:3000/api/v1/users/uuid-member-123/honors/45/requirements/5 \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "completed": true,
    "points_earned": 30,
    "evidences": {
      "album_url": "https://storage.supabase.co/albums/aves-album-final.pdf",
      "total_photos": 25,
      "species_documented": 18,
      "observations": "Excelente trabajo. Álbum completo con fotos de alta calidad."
    }
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "requirement_progress_id": 125,
    "enrollment_id": 45,
    "requirement_id": 5,
    "completed": true,
    "completion_date": "2026-02-20T14:30:00.000Z",
    "points_earned": 30,
    "evidences": {
      "album_url": "https://storage.supabase.co/albums/aves-album-final.pdf",
      "total_photos": 25,
      "species_documented": 18,
      "observations": "Excelente trabajo. Álbum completo con fotos de alta calidad."
    },
    "verified_by_user_id": "uuid-instructor-456",
    "enrollment_status": {
      "total_points_earned": 90,
      "progress_percentage": 90,
      "completed": false,
      "requirements_completed": 4,
      "total_requirements": 5
    }
  }
}
```

**Validaciones Backend**:

```typescript
// 1. Solo el instructor asignado puede validar requisitos
if (req.user.id !== enrollment.instructor_user_id && !isDirector(req.user)) {
  throw new ForbiddenException('Only assigned instructor can validate requirements');
}

// 2. Puntos no pueden exceder el máximo del requisito
if (dto.points_earned > requirement.points) {
  throw new BadRequestException('Points earned exceed requirement maximum');
}

// 3. Auto-completar especialidad si todos los requisitos están completos
if (allRequirementsCompleted) {
  await updateEnrollment({
    completed: true,
    completion_date: new Date(),
    progress_percentage: 100
  });
}
```

---

### 8. Certificar Especialidad Completada

**Endpoint**: `POST /api/v1/users/:userId/honors/:enrollmentId/certify`
**Autenticación**: Requerida
**Roles**: Director, Subdirector

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/users/uuid-member-123/honors/45/certify \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "certification_date": "2026-02-22T00:00:00.000Z",
    "notes": "Certificado en ceremonia de investidura"
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "enrollment_id": 45,
    "honor": {
      "name": "Aves",
      "difficulty": 1
    },
    "completed": true,
    "certified": true,
    "certification_date": "2026-02-22T00:00:00.000Z",
    "completion_date": "2026-02-20T14:30:00.000Z",
    "certificate_number": "CERT-2026-045",
    "certificate_url": "https://storage.supabase.co/certificates/cert-2026-045.pdf",
    "total_points_earned": 90,
    "progress_percentage": 90
  }
}
```

**Generación Automática de Certificado**:
- PDF con nombre del miembro
- Nombre de la especialidad
- Fecha de certificación
- Firma digital del director
- Código QR de verificación

---

## 📚 Casos de Uso Detallados

### Caso de Uso 1: Conquistador Completa su Primera Especialidad

**Escenario**: Un conquistador desea completar la especialidad de "Aves".

**Flujo**:

1. **Miembro consulta especialidades disponibles**:
   ```bash
   GET /api/v1/honors?categoryId=1&difficulty=1
   ```

2. **Selecciona "Aves" y ve los requisitos**:
   ```bash
   GET /api/v1/honors/1
   ```

3. **Director lo inscribe con instructor**:
   ```bash
   POST /api/v1/users/uuid-member/honors/enroll
   Body: {
     "honor_id": 1,
     "instructor_user_id": "uuid-instructor"
   }
   ```

4. **Miembro trabaja en requisitos** durante varias semanas.

5. **Instructor valida cada requisito** conforme se completa:
   ```bash
   PATCH /api/v1/users/uuid-member/honors/45/requirements/1
   Body: { "completed": true, "points_earned": 10, "evidences": {...} }
   ```

6. **Sistema detecta 100% completo** automáticamente.

7. **Director certifica la especialidad**:
   ```bash
   POST /api/v1/users/uuid-member/honors/45/certify
   Body: { "certification_date": "2026-02-22" }
   ```

8. **Sistema genera certificado PDF** y parche digital.

---

### Caso de Uso 2: Instructor Gestiona Múltiples Especialidades

**Escenario**: Un instructor supervisa 5 miembros en la especialidad "Primeros Auxilios".

**Flujo**:

1. **Director inscribe a 5 miembros**:
   ```bash
   POST /api/v1/users/uuid-member-1/honors/enroll
   POST /api/v1/users/uuid-member-2/honors/enroll
   # ... etc
   ```

2. **Instructor consulta sus asignaciones**:
   ```bash
   GET /api/v1/instructors/uuid-instructor/honors/assignments
   # Response: Lista de 5 enrollments activos
   ```

3. **Instructor planifica clases** grupales para requisitos teóricos.

4. **Durante la clase**, valida requisitos de todos:
   ```bash
   PATCH /api/v1/users/uuid-member-1/honors/50/requirements/1
   PATCH /api/v1/users/uuid-member-2/honors/51/requirements/1
   # ... etc
   ```

5. **Consulta progreso grupal**:
   ```bash
   GET /api/v1/instructors/uuid-instructor/honors/5/progress
   # Dashboard con progreso de cada miembro
   ```

---

### Caso de Uso 3: Reporte de Especialidades para Investidura

**Escenario**: Director necesita saber qué especialidades están listas para la investidura.

**Flujo**:

1. **Consultar especialidades completadas no certificadas**:
   ```bash
   GET /api/v1/clubs/5/honors?status=completed&certified=false
   ```

2. **Revisar cada una** para verificación final:
   ```bash
   GET /api/v1/users/uuid-member-1/honors/45/progress
   GET /api/v1/users/uuid-member-2/honors/52/progress
   ```

3. **Certificar en lote** (si endpoint disponible):
   ```bash
   POST /api/v1/clubs/5/honors/batch-certify
   Body: {
     "enrollment_ids": [45, 52, 60, 75],
     "certification_date": "2026-03-15"
   }
   ```

4. **Generar reporte de investidura**:
   - Nombre de miembro
   - Especialidades completadas
   - Fecha de certificación
   - Total de puntos

---

## ⚠️ Validaciones y Errores Comunes

### Error 1: Instructor no certificado en la especialidad

**Código**: 400 Bad Request

**Mensaje**: `"Instructor must be certified in this honor to teach it"`

**Causa**: Intentar asignar instructor que no tiene certificación en la especialidad.

**Solución**:
- Verificar que instructor tenga la especialidad completada
- O desactivar validación si el instructor tiene experiencia externa

---

### Error 2: Duplicar inscripción activa

**Código**: 409 Conflict

**Mensaje**: `"User already has an active enrollment in this honor"`

**Causa**: Intentar inscribir al usuario en una especialidad que ya está cursando.

**Solución**:
- Verificar enrollments activos antes de inscribir
- Si tiene enrollment previo completado, permitir nueva inscripción

---

### Error 3: Puntos exceden el máximo

**Código**: 400 Bad Request

**Mensaje**: `"Points earned (35) exceed requirement maximum (30)"`

**Causa**: Instructor asigna más puntos de los permitidos.

**Solución**:
- Validar en frontend antes de enviar
- Backend debe rechazar valores inválidos
- Usar exactamente los puntos del requisito o menos

---

### Error 4: Usuario no autorizado para validar

**Código**: 403 Forbidden

**Mensaje**: `"Only assigned instructor can validate requirements"`

**Causa**: Otro instructor intenta validar requisitos de una especialidad no asignada a él.

**Solución**:
- Solo el instructor asignado puede validar
- Directores pueden override esta restricción
- Subdirectores según configuración del club

---

## 🔧 Lógica de Backend

### Inscripción con Validación de Instructor

```typescript
async enrollInHonor(userId: string, dto: EnrollHonorDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Validar especialidad existe
    const honor = await tx.honors.findUnique({
      where: { honor_id: dto.honor_id, active: true }
    });
    if (!honor) throw new NotFoundException('Honor not found');

    // 2. Validar no tiene enrollment activo
    const existing = await tx.users_honors.findFirst({
      where: {
        user_id: userId,
        honor_id: dto.honor_id,
        active: true
      }
    });
    if (existing) {
      throw new ConflictException('User already enrolled in this honor');
    }

    // 3. Validar instructor (opcional según configuración)
    if (honor.instructor_required && dto.instructor_user_id) {
      const instructorCertified = await tx.users_honors.findFirst({
        where: {
          user_id: dto.instructor_user_id,
          honor_id: dto.honor_id,
          completed: true,
          certified: true
        }
      });

      if (!instructorCertified && config.REQUIRE_CERTIFIED_INSTRUCTORS) {
        throw new BadRequestException(
          'Instructor must be certified in this honor to teach it'
        );
      }
    }

    // 4. Crear enrollment
    const enrollment = await tx.users_honors.create({
      data: {
        user_id: userId,
        honor_id: dto.honor_id,
        instructor_user_id: dto.instructor_user_id,
        enrollment_date: new Date(),
        completed: false,
        progress_percentage: 0,
        total_points_earned: 0,
        active: true
      }
    });

    // 5. Crear registros de progreso para cada requisito
    const requirements = await tx.honor_requirements.findMany({
      where: { honor_id: dto.honor_id, active: true }
    });

    await Promise.all(
      requirements.map(req =>
        tx.honor_requirement_progress.create({
          data: {
            enrollment_id: enrollment.enrollment_id,
            requirement_id: req.requirement_id,
            completed: false,
            points_earned: 0
          }
        })
      )
    );

    return enrollment;
  });
}
```

### Cálculo Automático de Progreso

```typescript
async updateRequirementProgress(
  enrollmentId: number,
  requirementId: number,
  dto: UpdateRequirementProgressDto
) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Actualizar progreso del requisito
    const progress = await tx.honor_requirement_progress.upsert({
      where: { unique_enrollment_requirement },
      update: {
        completed: dto.completed,
        completion_date: dto.completed ? new Date() : null,
        points_earned: dto.points_earned,
        evidences: dto.evidences,
        verified_by_user_id: currentUserId
      },
      create: { /* ... */ }
    });

    // 2. Calcular progreso total del enrollment
    const allProgress = await tx.honor_requirement_progress.findMany({
      where: { enrollment_id: enrollmentId }
    });

    const totalPointsEarned = allProgress.reduce(
      (sum, p) => sum + (p.points_earned || 0),
      0
    );

    const allCompleted = allProgress.every(p => p.completed);

    // 3. Obtener total de puntos de la especialidad
    const enrollment = await tx.users_honors.findUnique({
      where: { enrollment_id: enrollmentId },
      include: {
        honors: {
          include: {
            honor_requirements: true
          }
        }
      }
    });

    const totalPoints = enrollment.honors.honor_requirements.reduce(
      (sum, r) => sum + r.points,
      0
    );

    const percentage = (totalPointsEarned / totalPoints) * 100;

    // 4. Actualizar enrollment
    await tx.users_honors.update({
      where: { enrollment_id: enrollmentId },
      data: {
        total_points_earned: totalPointsEarned,
        progress_percentage: Math.round(percentage * 100) / 100,
        completed: allCompleted,
        completion_date: allCompleted ? new Date() : null
      }
    });

    return {
      progress,
      enrollment_status: {
        total_points_earned: totalPointsEarned,
        progress_percentage: percentage,
        completed: allCompleted
      }
    };
  });
}
```

---

## 📊 Schema de Base de Datos (Prisma)

### Tabla: honors

```prisma
model honors {
  honor_id           Int       @id @default(autoincrement())
  name               String    @db.VarChar(150)
  description        String?   @db.Text
  honor_category_id  Int
  difficulty         Int       // 1=Básico, 2=Intermedio, 3=Avanzado
  club_type_id       Int?      // Para qué tipo de club aplica
  estimated_hours    Int?
  instructor_required Boolean  @default(true)
  patch_image        String?   @db.Text
  active             Boolean   @default(true)
  created_at         DateTime  @default(now())
  updated_at         DateTime  @updatedAt

  honor_categories   honor_categories       @relation(fields: [honor_category_id], references: [category_id])
  club_types         club_types?            @relation(fields: [club_type_id], references: [club_type_id])
  honor_requirements honor_requirements[]
  users_honors       users_honors[]

  @@index([honor_category_id])
  @@index([difficulty])
  @@index([club_type_id])
  @@map("honors")
}
```

### Tabla: honor_requirements

```prisma
model honor_requirements {
  requirement_id  Int      @id @default(autoincrement())
  honor_id        Int
  order           Int
  description     String   @db.Text
  points          Int
  required        Boolean  @default(true)
  active          Boolean  @default(true)
  created_at      DateTime @default(now())

  honors                      honors                        @relation(fields: [honor_id], references: [honor_id])
  honor_requirement_progress  honor_requirement_progress[]

  @@index([honor_id])
  @@map("honor_requirements")
}
```

### Tabla: users_honors

```prisma
model users_honors {
  enrollment_id        Int       @id @default(autoincrement())
  user_id              String    @db.Uuid
  honor_id             Int
  instructor_user_id   String?   @db.Uuid
  enrollment_date      DateTime  @default(now())
  completion_date      DateTime?
  completed            Boolean   @default(false)
  certified            Boolean   @default(false)
  certification_date   DateTime?
  certificate_number   String?   @db.VarChar(50)
  certificate_url      String?   @db.Text
  progress_percentage  Decimal   @default(0) @db.Decimal(5,2)
  total_points_earned  Int       @default(0)
  active               Boolean   @default(true)
  created_at           DateTime  @default(now())
  updated_at           DateTime  @updatedAt

  users                         users                        @relation("user_honors", fields: [user_id], references: [id])
  honors                        honors                       @relation(fields: [honor_id], references: [honor_id])
  instructor                    users?                       @relation("instructor_honors", fields: [instructor_user_id], references: [id])
  honor_requirement_progress    honor_requirement_progress[]

  @@unique([user_id, honor_id, active])
  @@index([user_id])
  @@index([honor_id])
  @@index([instructor_user_id])
  @@map("users_honors")
}
```

### Tabla: honor_requirement_progress

```prisma
model honor_requirement_progress {
  progress_id          Int       @id @default(autoincrement())
  enrollment_id        Int
  requirement_id       Int
  completed            Boolean   @default(false)
  completion_date      DateTime?
  points_earned        Int       @default(0)
  evidences            Json?
  verified_by_user_id  String?   @db.Uuid
  created_at           DateTime  @default(now())
  updated_at           DateTime  @updatedAt

  users_honors         users_honors         @relation(fields: [enrollment_id], references: [enrollment_id])
  honor_requirements   honor_requirements   @relation(fields: [requirement_id], references: [requirement_id])
  verified_by          users?               @relation(fields: [verified_by_user_id], references: [id])

  @@unique([enrollment_id, requirement_id])
  @@index([enrollment_id])
  @@index([requirement_id])
  @@map("honor_requirement_progress")
}
```

---

## 🧪 Tests E2E - Ejemplo

```typescript
// test/honors.e2e-spec.ts
describe('Honors (e2e)', () => {
  let directorToken: string;
  let instructorToken: string;
  let memberToken: string;
  let enrollmentId: number;

  beforeAll(async () => {
    directorToken = await getAuthToken('director@club.com');
    instructorToken = await getAuthToken('instructor@club.com');
    memberToken = await getAuthToken('member@club.com');
  });

  it('should list honor categories', async () => {
    const response = await request(app.getHttpServer())
      .get('/catalogs/honor-categories')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);

    expect(response.body.data).toBeInstanceOf(Array);
    expect(response.body.data[0]).toHaveProperty('category_id');
  });

  it('should list honors', async () => {
    const response = await request(app.getHttpServer())
      .get('/honors?categoryId=1')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);

    expect(response.body.data).toBeInstanceOf(Array);
    expect(response.body.data[0]).toHaveProperty('honor_id');
  });

  it('should enroll user in honor', async () => {
    const response = await request(app.getHttpServer())
      .post('/users/uuid-member/honors/enroll')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        honor_id: 1,
        instructor_user_id: 'uuid-instructor'
      })
      .expect(201);

    expect(response.body.data.honor_id).toBe(1);
    enrollmentId = response.body.data.enrollment_id;
  });

  it('should prevent duplicate enrollment', async () => {
    await request(app.getHttpServer())
      .post('/users/uuid-member/honors/enroll')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        honor_id: 1,
        instructor_user_id: 'uuid-instructor'
      })
      .expect(409);
  });

  it('should update requirement progress', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/users/uuid-member/honors/${enrollmentId}/requirements/1`)
      .set('Authorization', `Bearer ${instructorToken}`)
      .send({
        completed: true,
        points_earned: 10,
        evidences: { notes: 'Completed successfully' }
      })
      .expect(200);

    expect(response.body.data.completed).toBe(true);
    expect(response.body.data.points_earned).toBe(10);
  });

  it('should auto-complete honor when all requirements done', async () => {
    // Complete all 5 requirements
    for (let i = 1; i <= 5; i++) {
      await request(app.getHttpServer())
        .patch(`/users/uuid-member/honors/${enrollmentId}/requirements/${i}`)
        .set('Authorization', `Bearer ${instructorToken}`)
        .send({
          completed: true,
          points_earned: 20 // assuming each worth 20
        });
    }

    // Check enrollment status
    const response = await request(app.getHttpServer())
      .get(`/users/uuid-member/honors/${enrollmentId}/progress`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);

    expect(response.body.data.completed).toBe(true);
    expect(response.body.data.progress_percentage).toBe(100);
  });

  it('should certify completed honor', async () => {
    const response = await request(app.getHttpServer())
      .post(`/users/uuid-member/honors/${enrollmentId}/certify`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        certification_date: '2026-02-22'
      })
      .expect(200);

    expect(response.body.data.certified).toBe(true);
    expect(response.body.data).toHaveProperty('certificate_number');
  });
});
```

---

**Generado**: 4 de febrero de 2026
**Versión**: 2.2
**Módulo**: Honors
**Endpoints documentados**: 8
**Estado**: Producción
