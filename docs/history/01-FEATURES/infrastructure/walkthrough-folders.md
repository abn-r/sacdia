# Walkthrough: Folders/Portfolios (Carpetas de Evidencias)

**Módulo**: Folders/Portfolios
**Versión API**: 2.2
**Fecha**: 4 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Folders** (Carpetas/Portfolios) proporciona un sistema de gestión de evidencias para miembros del club. Este módulo permite:

- Templates de carpetas con estructura de módulos y secciones
- Sistema de puntos por sección completada
- Tracking de progreso individual por carpeta
- Almacenamiento de evidencias (JSON)
- Cálculo automático de porcentaje de avance
- Asociación con año eclesiástico y tipo de club

**Características principales**:
- ✅ Templates reutilizables de carpetas
- ✅ Sistema de puntos (máximo y mínimo requerido)
- ✅ Progreso por módulos y secciones
- ✅ Evidencias en formato JSON flexible
- ✅ Restricción por tipo de club y año eclesiástico

---

## 🎯 Flujo Completo

### 1. Listar Templates de Carpetas Disponibles

**Endpoint**: `GET /api/v1/folders`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/folders \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "folder_id": 1,
      "name": "Carpeta de Amigo",
      "description": "Carpeta de evidencias para la clase de Amigo",
      "club_type": 2,
      "ecclesiastical_year_id": 1,
      "max_points": 100,
      "minimum_points": 80,
      "active": true,
      "modules_count": 4
    },
    {
      "folder_id": 2,
      "name": "Carpeta de Compañero",
      "description": "Carpeta de evidencias para la clase de Compañero",
      "club_type": 2,
      "max_points": 120,
      "minimum_points": 96,
      "active": true,
      "modules_count": 5
    }
  ]
}
```

---

### 2. Ver Detalles de un Template de Carpeta

**Endpoint**: `GET /api/v1/folders/:id`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/folders/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "folder_id": 1,
    "name": "Carpeta de Amigo",
    "description": "Carpeta de evidencias para la clase de Amigo",
    "club_type": 2,
    "ecclesiastical_year_id": 1,
    "max_points": 100,
    "minimum_points": 80,
    "active": true,
    "modules": [
      {
        "module_id": 1,
        "name": "Descubrimiento Espiritual",
        "description": "Requisitos espirituales de la clase",
        "order": 1,
        "max_points": 25,
        "sections": [
          {
            "section_id": 1,
            "name": "Memorización de Textos Bíblicos",
            "description": "Memorizar 3 textos bíblicos relacionados con la clase",
            "order": 1,
            "points": 10,
            "required": true
          },
          {
            "section_id": 2,
            "name": "Estudio del Voto y Ley",
            "description": "Estudiar y explicar el voto y la ley del conquistador",
            "order": 2,
            "points": 15,
            "required": true
          }
        ]
      },
      {
        "module_id": 2,
        "name": "Servicio a la Comunidad",
        "description": "Actividades de servicio comunitario",
        "order": 2,
        "max_points": 30,
        "sections": [
          {
            "section_id": 3,
            "name": "Proyecto de Servicio",
            "description": "Participar en al menos 2 proyectos comunitarios",
            "order": 1,
            "points": 20,
            "required": true
          },
          {
            "section_id": 4,
            "name": "Ayuda a Adulto Mayor",
            "description": "Ayudar a un adulto mayor en tareas del hogar",
            "order": 2,
            "points": 10,
            "required": false
          }
        ]
      }
    ]
  }
}
```

---

### 3. Inscribirse en una Carpeta (Enrollment)

**Endpoint**: `POST /api/v1/users/:userId/folders/:folderId/enroll`
**Autenticación**: Requerida

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/users/uuid-123/folders/1/enroll \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "assignment_id": 1,
    "folder_id": 1,
    "user_id": "uuid-123",
    "club_adv_id": null,
    "club_pathf_id": 5,
    "club_mg_id": null,
    "assigned_date": "2026-02-04T00:00:00.000Z",
    "completion_date": null,
    "status": "IN_PROGRESS",
    "total_points": 0,
    "progress_percentage": 0,
    "active": true
  }
}
```

**Errores Comunes**:

- **409 Conflict**: Ya tiene una inscripción activa en esta carpeta
- **404 Not Found**: Carpeta no encontrada
- **400 Bad Request**: Usuario no pertenece a un club del tipo requerido

---

### 4. Ver Carpetas Asignadas del Usuario

**Endpoint**: `GET /api/v1/users/:userId/folders`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/users/uuid-123/folders \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "assignment_id": 1,
      "folder_id": 1,
      "folder": {
        "name": "Carpeta de Amigo",
        "description": "Carpeta de evidencias para la clase de Amigo",
        "max_points": 100,
        "minimum_points": 80
      },
      "status": "IN_PROGRESS",
      "total_points": 45,
      "progress_percentage": 45,
      "assigned_date": "2026-02-04T00:00:00.000Z",
      "completion_date": null,
      "active": true
    },
    {
      "assignment_id": 2,
      "folder_id": 3,
      "folder": {
        "name": "Carpeta de Explorador",
        "description": "Carpeta de evidencias para la clase de Explorador",
        "max_points": 150,
        "minimum_points": 120
      },
      "status": "COMPLETED",
      "total_points": 150,
      "progress_percentage": 100,
      "assigned_date": "2025-05-10T00:00:00.000Z",
      "completion_date": "2025-11-20T00:00:00.000Z",
      "active": true
    }
  ]
}
```

---

### 5. Ver Progreso Detallado de una Carpeta

**Endpoint**: `GET /api/v1/users/:userId/folders/:folderId/progress`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/users/uuid-123/folders/1/progress \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "folder_id": 1,
    "folder_name": "Carpeta de Amigo",
    "status": "IN_PROGRESS",
    "progress_percentage": 45,
    "total_points": 45,
    "max_points": 100,
    "minimum_points": 80,
    "assigned_date": "2026-02-04T00:00:00.000Z",
    "completion_date": null,
    "modules": [
      {
        "module_id": 1,
        "name": "Descubrimiento Espiritual",
        "max_points": 25,
        "earned_points": 25,
        "progress_percentage": 100,
        "completed": true,
        "sections": [
          {
            "section_id": 1,
            "name": "Memorización de Textos Bíblicos",
            "points": 10,
            "earned_points": 10,
            "completed": true,
            "completion_date": "2026-02-05T10:30:00.000Z",
            "evidences": {
              "texts": ["Juan 3:16", "Salmos 23:1", "Proverbios 3:5-6"],
              "recitation_date": "2026-02-05",
              "verified_by": "Director Juan Pérez"
            }
          },
          {
            "section_id": 2,
            "name": "Estudio del Voto y Ley",
            "points": 15,
            "earned_points": 15,
            "completed": true,
            "completion_date": "2026-02-06T14:20:00.000Z",
            "evidences": {
              "explanation_video": "https://storage.supabase.co/videos/voto-ley.mp4",
              "written_summary": "El voto del conquistador es...",
              "verified_by": "Director Juan Pérez"
            }
          }
        ]
      },
      {
        "module_id": 2,
        "name": "Servicio a la Comunidad",
        "max_points": 30,
        "earned_points": 20,
        "progress_percentage": 66.67,
        "completed": false,
        "sections": [
          {
            "section_id": 3,
            "name": "Proyecto de Servicio",
            "points": 20,
            "earned_points": 20,
            "completed": true,
            "completion_date": "2026-02-08T16:00:00.000Z",
            "evidences": {
              "projects": [
                {
                  "name": "Limpieza de Parque Central",
                  "date": "2026-01-15",
                  "photos": ["url1.jpg", "url2.jpg"]
                },
                {
                  "name": "Visita a Hogar de Ancianos",
                  "date": "2026-01-22",
                  "photos": ["url3.jpg"]
                }
              ]
            }
          },
          {
            "section_id": 4,
            "name": "Ayuda a Adulto Mayor",
            "points": 10,
            "earned_points": 0,
            "completed": false,
            "completion_date": null,
            "evidences": null
          }
        ]
      }
    ]
  }
}
```

---

### 6. Actualizar Progreso de una Sección

**Endpoint**: `PATCH /api/v1/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Instructor (según configuración del club)

**Request**:

```bash
curl -X PATCH http://localhost:3000/api/v1/users/uuid-123/folders/1/modules/2/sections/4 \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "points": 10,
    "evidences": {
      "elderly_name": "Sra. María González",
      "tasks_performed": ["Compras en supermercado", "Limpieza de jardín"],
      "date": "2026-02-10",
      "photos": ["https://storage.supabase.co/photos/evidence1.jpg"],
      "verified_by": "Director Juan Pérez"
    }
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "section_record_id": 4,
    "folder_id": 1,
    "module_id": 2,
    "section_id": 4,
    "user_id": "uuid-123",
    "points": 10,
    "completed": true,
    "completion_date": "2026-02-10T18:30:00.000Z",
    "evidences": {
      "elderly_name": "Sra. María González",
      "tasks_performed": ["Compras en supermercado", "Limpieza de jardín"],
      "date": "2026-02-10",
      "photos": ["https://storage.supabase.co/photos/evidence1.jpg"],
      "verified_by": "Director Juan Pérez"
    },
    "folder_progress": {
      "total_points": 55,
      "progress_percentage": 55,
      "status": "IN_PROGRESS"
    }
  }
}
```

**Validaciones Backend**:

```typescript
// 1. Validar que los puntos no excedan el máximo de la sección
if (dto.points > section.points) {
  throw new BadRequestException('Points exceed section maximum');
}

// 2. Validar que la carpeta esté activa
if (!assignment.active) {
  throw new BadRequestException('Folder assignment is not active');
}

// 3. Auto-completar módulo si todas las secciones están completas
const moduleComplete = allSectionsCompleted(moduleId);
if (moduleComplete) {
  await updateModuleRecord({ completed: true });
}

// 4. Auto-completar carpeta si total_points >= minimum_points
if (totalPoints >= folder.minimum_points) {
  await updateAssignment({
    status: 'COMPLETED',
    completion_date: new Date()
  });
}
```

---

### 7. Retirar/Desactivar Carpeta

**Endpoint**: `DELETE /api/v1/users/:userId/folders/:folderId`
**Autenticación**: Requerida
**Roles**: Director, Subdirector

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/users/uuid-123/folders/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "Folder assignment deactivated successfully",
  "data": {
    "assignment_id": 1,
    "active": false,
    "status": "WITHDRAWN"
  }
}
```

---

## 📚 Casos de Uso Detallados

### Caso de Uso 1: Conquistador Completa su Carpeta de Clase

**Escenario**: Un conquistador de la clase "Amigo" debe completar su carpeta para poder invertirse.

**Flujo**:

1. **El usuario consulta sus carpetas asignadas**:
   ```bash
   GET /api/v1/users/uuid-123/folders
   ```

2. **Director asigna la carpeta** (si no existe):
   ```bash
   POST /api/v1/users/uuid-123/folders/1/enroll
   ```

3. **Usuario/Instructor actualiza progreso** conforme completa secciones:
   ```bash
   # Sección 1: Memorización de textos
   PATCH /api/v1/users/uuid-123/folders/1/modules/1/sections/1
   Body: { "points": 10, "evidences": { "texts": [...] } }

   # Sección 2: Estudio del voto
   PATCH /api/v1/users/uuid-123/folders/1/modules/1/sections/2
   Body: { "points": 15, "evidences": { "explanation_video": "..." } }
   ```

4. **Sistema calcula automáticamente**:
   - Total de puntos acumulados
   - Porcentaje de progreso
   - Módulos completados
   - Estado de la carpeta (completa si total_points >= minimum_points)

5. **Usuario verifica su progreso**:
   ```bash
   GET /api/v1/users/uuid-123/folders/1/progress
   ```

6. **Cuando total_points = 100** (o >= 80 mínimo):
   - Status cambia automáticamente a `COMPLETED`
   - Se registra `completion_date`
   - Usuario cumple requisito para investidura

---

### Caso de Uso 2: Director Crea Template de Carpeta Personalizada

**Escenario**: Un club quiere crear una carpeta personalizada para un proyecto especial.

**Flujo**:

1. **Crear template de carpeta** (solo Admin o Director autorizado):
   ```bash
   POST /api/v1/folders
   Body: {
     "name": "Proyecto Campamento de Invierno 2026",
     "description": "Evidencias del campamento de invierno",
     "club_type": 2,
     "ecclesiastical_year_id": 5,
     "max_points": 80,
     "minimum_points": 60
   }
   ```

2. **Crear módulos** para la carpeta:
   ```bash
   POST /api/v1/folders/5/modules
   Body: {
     "name": "Preparación Pre-Campamento",
     "description": "Actividades previas al evento",
     "order": 1,
     "max_points": 20
   }
   ```

3. **Crear secciones** dentro del módulo:
   ```bash
   POST /api/v1/folders/5/modules/10/sections
   Body: {
     "name": "Lista de Equipo",
     "description": "Preparar y revisar equipo personal",
     "order": 1,
     "points": 10,
     "required": true
   }
   ```

4. **Asignar carpeta** a todos los miembros del club:
   ```bash
   # Por cada miembro
   POST /api/v1/users/{userId}/folders/5/enroll
   ```

---

### Caso de Uso 3: Verificación de Evidencias

**Escenario**: Un instructor necesita verificar las evidencias subidas por un miembro.

**Flujo**:

1. **Ver progreso del miembro**:
   ```bash
   GET /api/v1/users/uuid-456/folders/1/progress
   ```

2. **Revisar evidencias de una sección**:
   - El response incluye el objeto `evidences` con fotos, videos, documentos, etc.
   - Formato flexible JSON permite cualquier estructura

3. **Si evidencia es aceptable**, no se requiere acción adicional

4. **Si evidencia es insuficiente**, puede:
   - Reducir los puntos otorgados:
     ```bash
     PATCH /api/v1/users/uuid-456/folders/1/modules/2/sections/3
     Body: { "points": 5 }  # En lugar de 10
     ```
   - O marcar como incompleta:
     ```bash
     PATCH /api/v1/users/uuid-456/folders/1/modules/2/sections/3
     Body: { "points": 0, "evidences": null }
     ```

---

## ⚠️ Validaciones y Errores Comunes

### Error 1: Usuario ya tiene carpeta activa del mismo tipo

**Código**: 409 Conflict

**Causa**: Intentar inscribir al usuario en una carpeta cuando ya tiene una asignación activa del mismo folder_id.

**Solución**:
- Verificar carpetas actuales antes de inscribir: `GET /api/v1/users/:userId/folders`
- Si existe y está incompleta, continuar con esa carpeta
- Si existe y está completa, permitir nueva inscripción desactivando la anterior

---

### Error 2: Puntos exceden el máximo de la sección

**Código**: 400 Bad Request

**Mensaje**: `"Points exceed section maximum"`

**Causa**: Intentar asignar más puntos de los permitidos en la sección.

**Solución**:
- Verificar `section.points` antes de actualizar
- Asignar exactamente los puntos configurados o menos

---

### Error 3: Usuario no pertenece al club type correcto

**Código**: 400 Bad Request

**Mensaje**: `"User's club type doesn't match folder requirement"`

**Causa**: Carpeta requiere `club_type: 2` (Conquistadores) pero usuario pertenece a club tipo 1 (Aventureros).

**Solución**:
- Verificar `club_type` del usuario antes de asignar carpeta
- Filtrar templates de carpetas según el tipo de club del usuario

---

### Error 4: Carpeta ya completada

**Código**: 400 Bad Request

**Mensaje**: `"Cannot update completed folder"`

**Causa**: Intentar modificar progreso de una carpeta con status `COMPLETED`.

**Solución**:
- Solo permitir edición si `status === 'IN_PROGRESS'`
- Si es necesario reabrir, cambiar status a `IN_PROGRESS` primero

---

## 🔧 Lógica de Backend

### Validación de Asignación de Carpeta

```typescript
// folders.service.ts
async enrollUser(userId: string, folderId: number) {
  // 1. Validar que carpeta existe y está activa
  const folder = await this.prisma.folders.findUnique({
    where: { folder_id: folderId, active: true }
  });
  if (!folder) throw new NotFoundException('Folder not found');

  // 2. Validar que usuario no tiene asignación activa de esta carpeta
  const existing = await this.prisma.folder_assignments.findFirst({
    where: {
      user_id: userId,
      folder_id: folderId,
      active: true
    }
  });
  if (existing) throw new ConflictException('Already enrolled in this folder');

  // 3. Obtener club instance del usuario
  const userClub = await this.getUserClubInstance(userId);

  // 4. Validar club_type coincide
  if (folder.club_type && folder.club_type !== userClub.club_type_id) {
    throw new BadRequestException("User's club type doesn't match folder requirement");
  }

  // 5. Crear asignación
  return await this.prisma.folder_assignments.create({
    data: {
      user_id: userId,
      folder_id: folderId,
      club_adv_id: userClub.club_adv_id,
      club_pathf_id: userClub.club_pathf_id,
      club_mg_id: userClub.club_mg_id,
      assigned_date: new Date(),
      status: 'IN_PROGRESS',
      total_points: 0,
      progress_percentage: 0,
      active: true
    }
  });
}
```

### Cálculo de Progreso Automático

```typescript
async updateSectionProgress(dto: UpdateSectionProgressDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Actualizar o crear section record
    const sectionRecord = await tx.folders_section_records.upsert({
      where: { unique_composite_key },
      update: {
        points: dto.points,
        evidences: dto.evidences,
        completed: true,
        completion_date: new Date()
      },
      create: { /* ... */ }
    });

    // 2. Obtener todos los section records de este folder
    const allSectionRecords = await tx.folders_section_records.findMany({
      where: { folder_id: folderId, /* filtros de club instance */ }
    });

    // 3. Calcular total de puntos
    const totalPoints = allSectionRecords.reduce((sum, r) => sum + (r.points || 0), 0);

    // 4. Obtener folder para max_points y minimum_points
    const folder = await tx.folders.findUnique({
      where: { folder_id: folderId }
    });

    // 5. Calcular porcentaje
    const percentage = (totalPoints / folder.max_points) * 100;

    // 6. Determinar status
    const status = totalPoints >= folder.minimum_points ? 'COMPLETED' : 'IN_PROGRESS';

    // 7. Actualizar assignment
    await tx.folder_assignments.update({
      where: { assignment_id: assignmentId },
      data: {
        total_points: totalPoints,
        progress_percentage: percentage,
        status: status,
        completion_date: status === 'COMPLETED' ? new Date() : null
      }
    });

    return { sectionRecord, totalPoints, percentage, status };
  });
}
```

---

## 📊 Schema de Base de Datos (Prisma)

### Tabla: folders

```prisma
model folders {
  folder_id              Int      @id @default(autoincrement())
  name                   String   @db.VarChar(150)
  description            String?  @db.Text
  club_type              Int?     // FK a club_types (1=ADV, 2=PATHF, 3=MG)
  ecclesiastical_year_id Int?     // FK a ecclesiastical_years
  max_points             Int?
  minimum_points         Int?
  active                 Boolean  @default(true)
  created_at             DateTime @default(now())
  updated_at             DateTime @updatedAt

  folders_modules        folders_modules[]
  folder_assignments     folder_assignments[]

  @@map("folders")
}
```

### Tabla: folders_modules

```prisma
model folders_modules {
  module_id   Int      @id @default(autoincrement())
  folder_id   Int
  name        String   @db.VarChar(200)
  description String?  @db.Text
  order       Int
  max_points  Int?
  active      Boolean  @default(true)

  folders          folders            @relation(fields: [folder_id], references: [folder_id])
  folders_sections folders_sections[]

  @@map("folders_modules")
}
```

### Tabla: folders_sections

```prisma
model folders_sections {
  section_id  Int      @id @default(autoincrement())
  module_id   Int
  name        String   @db.VarChar(200)
  description String?  @db.Text
  order       Int
  points      Int
  required    Boolean  @default(true)
  active      Boolean  @default(true)

  folders_modules         folders_modules           @relation(fields: [module_id], references: [module_id])
  folders_section_records folders_section_records[]

  @@map("folders_sections")
}
```

### Tabla: folder_assignments

```prisma
model folder_assignments {
  assignment_id        Int       @id @default(autoincrement())
  folder_id            Int
  user_id              String    @db.Uuid
  club_adv_id          Int?
  club_pathf_id        Int?
  club_mg_id           Int?
  assigned_date        DateTime  @default(now())
  completion_date      DateTime?
  status               String    @db.VarChar(20) // IN_PROGRESS | COMPLETED | WITHDRAWN
  total_points         Int       @default(0)
  progress_percentage  Decimal   @default(0) @db.Decimal(5,2)
  active               Boolean   @default(true)

  folders folders @relation(fields: [folder_id], references: [folder_id])
  users   users   @relation(fields: [user_id], references: [id])

  @@map("folder_assignments")
}
```

### Tabla: folders_section_records

```prisma
model folders_section_records {
  record_id       Int       @id @default(autoincrement())
  folder_id       Int
  module_id       Int
  section_id      Int
  user_id         String    @db.Uuid
  club_adv_id     Int?
  club_pathf_id   Int?
  club_mg_id      Int?
  points          Int       @default(0)
  evidences       Json?     // Flexible JSON for photos, videos, docs, etc.
  completed       Boolean   @default(false)
  completion_date DateTime?
  created_at      DateTime  @default(now())
  updated_at      DateTime  @updatedAt

  folders_sections folders_sections @relation(fields: [section_id], references: [section_id])

  @@unique([section_id, user_id, club_adv_id, club_pathf_id, club_mg_id])
  @@map("folders_section_records")
}
```

---

## 🧪 Tests E2E - Ejemplo

```typescript
// test/folders.e2e-spec.ts
describe('Folders (e2e)', () => {
  it('should enroll user in a folder', async () => {
    const response = await request(app.getHttpServer())
      .post(`/users/${userId}/folders/1/enroll`)
      .set('Authorization', `Bearer ${token}`)
      .expect(201);

    expect(response.body.data).toHaveProperty('assignment_id');
    expect(response.body.data.status).toBe('IN_PROGRESS');
    expect(response.body.data.total_points).toBe(0);
  });

  it('should update section progress and recalculate total', async () => {
    // Inscribir
    await request(app.getHttpServer())
      .post(`/users/${userId}/folders/1/enroll`)
      .set('Authorization', `Bearer ${token}`);

    // Actualizar sección 1 (10 puntos)
    const response1 = await request(app.getHttpServer())
      .patch(`/users/${userId}/folders/1/modules/1/sections/1`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        points: 10,
        evidences: { test: 'evidence1' }
      })
      .expect(200);

    expect(response1.body.data.folder_progress.total_points).toBe(10);

    // Actualizar sección 2 (15 puntos)
    const response2 = await request(app.getHttpServer())
      .patch(`/users/${userId}/folders/1/modules/1/sections/2`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        points: 15,
        evidences: { test: 'evidence2' }
      })
      .expect(200);

    expect(response2.body.data.folder_progress.total_points).toBe(25);
  });

  it('should auto-complete folder when reaching minimum points', async () => {
    // Folder con max_points=100, minimum_points=80
    await request(app.getHttpServer())
      .post(`/users/${userId}/folders/1/enroll`)
      .set('Authorization', `Bearer ${token}`);

    // Completar secciones hasta llegar a 80 puntos
    // ... (omitido por brevedad)

    // Última actualización que llega a 80
    const response = await request(app.getHttpServer())
      .patch(`/users/${userId}/folders/1/modules/4/sections/10`)
      .set('Authorization', `Bearer ${token}`)
      .send({ points: 10 })
      .expect(200);

    expect(response.body.data.folder_progress.total_points).toBe(80);
    expect(response.body.data.folder_progress.status).toBe('COMPLETED');
    expect(response.body.data.folder_progress).toHaveProperty('completion_date');
  });

  it('should prevent enrolling twice in same folder', async () => {
    await request(app.getHttpServer())
      .post(`/users/${userId}/folders/1/enroll`)
      .set('Authorization', `Bearer ${token}`)
      .expect(201);

    await request(app.getHttpServer())
      .post(`/users/${userId}/folders/1/enroll`)
      .set('Authorization', `Bearer ${token}`)
      .expect(409); // Conflict
  });
});
```

---

## 📝 Notas Importantes

### Diferencias con Módulo de Classes

| Característica | Classes | Folders |
|----------------|---------|---------|
| Estructura | Clase → Módulos → Secciones | Carpeta → Módulos → Secciones |
| Sistema de puntos | Progreso por porcentaje | Sistema de puntos con máximo/mínimo |
| Evidencias | No tiene campo evidencias | JSON flexible para evidencias |
| Múltiples inscripciones | Solo 1 clase activa | Múltiples carpetas simultáneas |
| Aprobación | Requiere aprobación de director | Asignación directa |
| Propósito | Progreso en clases progresivas | Tracking de evidencias/logros |

### Estructura Flexible de Evidencias

El campo `evidences` es de tipo JSON, lo que permite almacenar cualquier estructura:

```typescript
// Ejemplo 1: Evidencia simple
{
  "photo_url": "https://storage.supabase.co/photo1.jpg",
  "verified_by": "Director Juan"
}

// Ejemplo 2: Evidencia compleja
{
  "activities": [
    {
      "name": "Limpieza de parque",
      "date": "2026-01-15",
      "participants": 12,
      "photos": ["url1.jpg", "url2.jpg"],
      "duration_hours": 3
    }
  ],
  "verified_by": "Subdirector María",
  "verification_date": "2026-01-16"
}

// Ejemplo 3: Evidencia multimedia
{
  "video_url": "https://storage.supabase.co/video.mp4",
  "transcript": "Explicación del voto del conquistador...",
  "questions_answered": ["P1", "P2", "P3"],
  "score": 95,
  "evaluator": "Instructor Pedro"
}
```

---

**Generado**: 4 de febrero de 2026
**Versión**: 2.2
**Módulo**: Folders/Portfolios
**Endpoints documentados**: 7
**Estado**: Producción
