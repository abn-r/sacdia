# Walkthrough: Activities (Actividades y Eventos de Club)

**Módulo**: Activities
**Versión API**: 2.2
**Fecha**: 4 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Activities** proporciona un sistema completo de gestión de actividades y eventos para clubes. Este módulo permite:

- Crear y gestionar actividades del club
- Registrar ubicación GPS de eventos
- Sistema de check-in/asistencia de miembros
- Categorización por tipo de actividad
- Upload de fotos y evidencias
- Filtrado por instancia de club
- Reportes de participación
- Tracking histórico de actividades

**Características principales**:
- ✅ CRUD completo de actividades
- ✅ Geolocalización con latitud/longitud
- ✅ Sistema de asistencia/check-in
- ✅ Tipos de actividad (reunión, salida, camporee, etc.)
- ✅ Upload de fotos y documentos
- ✅ Filtros por fecha, tipo, club instance
- ✅ Control de acceso basado en roles

---

## 🎯 Flujo Completo

### 1. Listar Actividades de un Club

**Endpoint**: `GET /api/v1/clubs/:clubId/activities`
**Autenticación**: Requerida
**Roles**: Cualquier miembro del club puede ver

**Query Parameters**:
- `clubTypeId`: Filtrar por tipo de club (1=ADV, 2=PATHF, 3=MG)
- `active`: Filtrar por estado (true/false)
- `activityType`: Tipo de actividad (meeting, outing, camporee, special_event, etc.)
- `startDate`: Fecha inicial (YYYY-MM-DD)
- `endDate`: Fecha final (YYYY-MM-DD)
- `page`: Número de página (default: 1)
- `limit`: Items por página (default: 20)

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/clubs/5/activities?clubTypeId=2&active=true&page=1&limit=10" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "activity_id": 1,
      "name": "Reunión Semanal de Conquistadores",
      "description": "Reunión regular del club con devocional, clases y juegos",
      "activity_type": "meeting",
      "activity_date": "2026-02-08T16:00:00.000Z",
      "end_date": "2026-02-08T19:00:00.000Z",
      "location": "Iglesia Central - Salón de Conquistadores",
      "latitude": 19.432608,
      "longitude": -99.133209,
      "club_adv_id": null,
      "club_pathf_id": 5,
      "club_mg_id": null,
      "max_participants": 50,
      "attendance_count": 38,
      "photos": [
        "https://storage.supabase.co/activities/photo1.jpg",
        "https://storage.supabase.co/activities/photo2.jpg"
      ],
      "active": true,
      "created_at": "2026-02-01T10:00:00.000Z",
      "created_by": {
        "user_id": "uuid-director",
        "name": "Juan",
        "paternal_last_name": "Pérez"
      }
    },
    {
      "activity_id": 2,
      "name": "Salida Misionera - Asilo de Ancianos",
      "description": "Visita al asilo para cantar y compartir con los abuelitos",
      "activity_type": "outing",
      "activity_date": "2026-02-15T09:00:00.000Z",
      "end_date": "2026-02-15T13:00:00.000Z",
      "location": "Asilo San José",
      "latitude": 19.423456,
      "longitude": -99.145678,
      "club_adv_id": null,
      "club_pathf_id": 5,
      "club_mg_id": null,
      "max_participants": 30,
      "attendance_count": 25,
      "photos": [],
      "active": true,
      "created_at": "2026-02-03T14:30:00.000Z"
    }
  ],
  "meta": {
    "total": 24,
    "page": 1,
    "limit": 10,
    "totalPages": 3
  }
}
```

---

### 2. Crear Nueva Actividad

**Endpoint**: `POST /api/v1/clubs/:clubId/activities`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Secretario

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/clubs/5/activities \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Campamento de Invierno 2026",
    "description": "Campamento anual de 3 días en las montañas",
    "activity_type": "camporee",
    "activity_date": "2026-03-15T08:00:00.000Z",
    "end_date": "2026-03-17T18:00:00.000Z",
    "location": "Campo Valle Verde",
    "latitude": 19.234567,
    "longitude": -99.456789,
    "club_pathf_id": 5,
    "max_participants": 60
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "activity_id": 25,
    "name": "Campamento de Invierno 2026",
    "description": "Campamento anual de 3 días en las montañas",
    "activity_type": "camporee",
    "activity_date": "2026-03-15T08:00:00.000Z",
    "end_date": "2026-03-17T18:00:00.000Z",
    "location": "Campo Valle Verde",
    "latitude": 19.234567,
    "longitude": -99.456789,
    "club_adv_id": null,
    "club_pathf_id": 5,
    "club_mg_id": null,
    "max_participants": 60,
    "attendance_count": 0,
    "photos": [],
    "active": true,
    "created_at": "2026-02-04T16:45:00.000Z",
    "created_by_user_id": "uuid-director",
    "updated_at": "2026-02-04T16:45:00.000Z"
  }
}
```

**Validaciones**:
- ✅ Nombre requerido (máximo 200 caracteres)
- ✅ Fecha de actividad requerida
- ✅ Debe especificar exactamente UNA instancia de club
- ✅ Usuario debe tener rol de Director, Subdirector o Secretario
- ✅ Tipo de actividad debe ser válido
- ✅ Coordenadas GPS opcionales pero recomendadas
- ✅ max_participants opcional (default: null = sin límite)

---

### 3. Ver Detalles de una Actividad

**Endpoint**: `GET /api/v1/activities/:activityId`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/activities/25 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "activity_id": 25,
    "name": "Campamento de Invierno 2026",
    "description": "Campamento anual de 3 días en las montañas",
    "activity_type": "camporee",
    "activity_date": "2026-03-15T08:00:00.000Z",
    "end_date": "2026-03-17T18:00:00.000Z",
    "location": "Campo Valle Verde",
    "latitude": 19.234567,
    "longitude": -99.456789,
    "club_instance": {
      "club_pathf_id": 5,
      "club_name": "Club Conquistadores Emanuel",
      "instance_type": "pathfinders"
    },
    "max_participants": 60,
    "attendance_count": 0,
    "attendance_percentage": 0,
    "photos": [],
    "documents": [],
    "active": true,
    "created_at": "2026-02-04T16:45:00.000Z",
    "created_by": {
      "user_id": "uuid-director",
      "name": "Juan",
      "paternal_last_name": "Pérez",
      "maternal_last_name": "García"
    },
    "updated_at": "2026-02-04T16:45:00.000Z"
  }
}
```

---

### 4. Actualizar Actividad

**Endpoint**: `PATCH /api/v1/activities/:activityId`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Secretario

**Request**:

```bash
curl -X PATCH http://localhost:3000/api/v1/activities/25 \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Campamento anual de 3 días en las montañas. Incluye caminata nocturna y fogata.",
    "max_participants": 50,
    "photos": [
      "https://storage.supabase.co/activities/camp2026_1.jpg",
      "https://storage.supabase.co/activities/camp2026_2.jpg"
    ]
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "activity_id": 25,
    "name": "Campamento de Invierno 2026",
    "description": "Campamento anual de 3 días en las montañas. Incluye caminata nocturna y fogata.",
    "max_participants": 50,
    "photos": [
      "https://storage.supabase.co/activities/camp2026_1.jpg",
      "https://storage.supabase.co/activities/camp2026_2.jpg"
    ],
    "updated_at": "2026-02-04T17:00:00.000Z"
  }
}
```

**Campos Actualizables**:
- name
- description
- activity_type
- activity_date
- end_date
- location
- latitude
- longitude
- max_participants
- photos (array de URLs)
- documents (array de URLs)

---

### 5. Eliminar Actividad (Soft Delete)

**Endpoint**: `DELETE /api/v1/activities/:activityId`
**Autenticación**: Requerida
**Roles**: Director únicamente

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/activities/25 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "Activity deactivated successfully",
  "data": {
    "activity_id": 25,
    "active": false,
    "deactivated_at": "2026-02-04T17:15:00.000Z"
  }
}
```

**Nota**: La actividad NO se elimina físicamente. Solo se marca como `active: false` para preservar historial.

---

### 6. Registrar Asistencia (Check-in)

**Endpoint**: `POST /api/v1/activities/:activityId/attendance`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Secretario, Consejero

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/activities/1/attendance \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid-member-123",
    "check_in_time": "2026-02-08T16:05:00.000Z",
    "notes": "Llegó con uniforme completo"
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "attendance_id": 45,
    "activity_id": 1,
    "user_id": "uuid-member-123",
    "user": {
      "name": "Carlos",
      "paternal_last_name": "Ramírez",
      "maternal_last_name": "López"
    },
    "check_in_time": "2026-02-08T16:05:00.000Z",
    "check_out_time": null,
    "attended": true,
    "notes": "Llegó con uniforme completo",
    "created_at": "2026-02-08T16:05:00.000Z"
  },
  "meta": {
    "activity_attendance_count": 39,
    "activity_max_participants": 50,
    "attendance_percentage": 78
  }
}
```

**Validaciones**:
- ✅ Usuario debe pertenecer al club
- ✅ No permitir duplicados (mismo usuario, misma actividad)
- ✅ Validar que actividad esté activa
- ✅ Si hay max_participants, validar que no se exceda
- ✅ check_in_time puede ser automático (NOW) o manual

---

### 7. Listar Asistencia de una Actividad

**Endpoint**: `GET /api/v1/activities/:activityId/attendance`
**Autenticación**: Requerida

**Query Parameters**:
- `attended`: Filtrar por asistencia (true/false)
- `page`: Número de página
- `limit`: Items por página

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/activities/1/attendance?attended=true" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "attendance_id": 45,
      "user_id": "uuid-member-123",
      "user": {
        "name": "Carlos",
        "paternal_last_name": "Ramírez",
        "maternal_last_name": "López",
        "avatar": "https://storage.supabase.co/avatars/carlos.jpg"
      },
      "check_in_time": "2026-02-08T16:05:00.000Z",
      "check_out_time": "2026-02-08T19:00:00.000Z",
      "attended": true,
      "notes": "Llegó con uniforme completo"
    },
    {
      "attendance_id": 46,
      "user_id": "uuid-member-456",
      "user": {
        "name": "María",
        "paternal_last_name": "González",
        "maternal_last_name": "Martínez",
        "avatar": "https://storage.supabase.co/avatars/maria.jpg"
      },
      "check_in_time": "2026-02-08T16:00:00.000Z",
      "check_out_time": "2026-02-08T19:05:00.000Z",
      "attended": true,
      "notes": null
    }
  ],
  "meta": {
    "total_attendance": 39,
    "total_registered": 45,
    "attendance_percentage": 86.67,
    "activity": {
      "activity_id": 1,
      "name": "Reunión Semanal de Conquistadores",
      "activity_date": "2026-02-08T16:00:00.000Z"
    }
  }
}
```

---

## 📚 Casos de Uso Detallados

### Caso de Uso 1: Planear y Ejecutar Reunión Semanal

**Escenario**: El club tiene su reunión regular cada sábado y necesita registrar asistencia.

**Flujo**:

1. **Secretario crea la actividad** al inicio de la semana:
   ```bash
   POST /api/v1/clubs/5/activities
   Body: {
     "name": "Reunión Semanal - 08 Feb 2026",
     "activity_type": "meeting",
     "activity_date": "2026-02-08T16:00:00.000Z",
     "end_date": "2026-02-08T19:00:00.000Z",
     "location": "Iglesia Central",
     "latitude": 19.432608,
     "longitude": -99.133209,
     "club_pathf_id": 5,
     "max_participants": 50
   }
   ```

2. **El día de la reunión**, consejeros hacen check-in de miembros conforme llegan:
   ```bash
   # Miembro 1 llega a las 4:00 PM
   POST /api/v1/activities/1/attendance
   Body: { "user_id": "uuid-1", "check_in_time": "2026-02-08T16:00:00.000Z" }

   # Miembro 2 llega a las 4:05 PM
   POST /api/v1/activities/1/attendance
   Body: { "user_id": "uuid-2", "check_in_time": "2026-02-08T16:05:00.000Z" }

   # ... continuar con todos los miembros
   ```

3. **Durante la reunión**, secretario verifica asistencia en tiempo real:
   ```bash
   GET /api/v1/activities/1/attendance
   ```

4. **Al finalizar**, director consulta reporte:
   ```bash
   GET /api/v1/activities/1
   # Response incluye: attendance_count, attendance_percentage
   ```

5. **Subir fotos** de la reunión (opcional):
   ```bash
   PATCH /api/v1/activities/1
   Body: {
     "photos": [
       "https://storage.supabase.co/activities/reunion-feb8-1.jpg",
       "https://storage.supabase.co/activities/reunion-feb8-2.jpg"
     ]
   }
   ```

---

### Caso de Uso 2: Organizar Salida Misionera

**Escenario**: El club planea una salida a un asilo de ancianos.

**Flujo**:

1. **Director crea la actividad** con ubicación GPS:
   ```bash
   POST /api/v1/clubs/5/activities
   Body: {
     "name": "Salida Misionera - Asilo San José",
     "description": "Visita para cantar y compartir con los abuelitos",
     "activity_type": "outing",
     "activity_date": "2026-02-15T09:00:00.000Z",
     "end_date": "2026-02-15T13:00:00.000Z",
     "location": "Asilo San José, Calle Libertad 123",
     "latitude": 19.423456,
     "longitude": -99.145678,
     "club_pathf_id": 5,
     "max_participants": 30
   }
   ```

2. **El día de la salida**, el frontend usa las coordenadas GPS para:
   - Mostrar mapa de ubicación
   - Dar indicaciones de navegación
   - Verificar que los miembros llegaron al lugar correcto

3. **Registro de asistencia** al llegar al asilo:
   ```bash
   POST /api/v1/activities/2/attendance
   Body: { "user_id": "uuid-member" }
   # check_in_time se asigna automáticamente
   ```

4. **Después de la actividad**, subdirector sube evidencias:
   ```bash
   PATCH /api/v1/activities/2
   Body: {
     "photos": [
       "https://storage.supabase.co/activities/asilo-group.jpg",
       "https://storage.supabase.co/activities/asilo-singing.jpg"
     ],
     "description": "Gran participación. Los abuelitos quedaron muy contentos."
   }
   ```

---

### Caso de Uso 3: Reportes de Participación Mensual

**Escenario**: Director necesita generar reporte mensual de participación.

**Flujo**:

1. **Obtener todas las actividades del mes**:
   ```bash
   GET /api/v1/clubs/5/activities?startDate=2026-02-01&endDate=2026-02-29&clubTypeId=2
   ```

2. **Para cada actividad**, obtener detalles de asistencia:
   ```bash
   GET /api/v1/activities/1/attendance
   GET /api/v1/activities/2/attendance
   # ... etc
   ```

3. **Frontend procesa los datos**:
   ```typescript
   const activities = response.data;

   const monthlyStats = {
     total_activities: activities.length,
     total_attendance: activities.reduce((sum, a) => sum + a.attendance_count, 0),
     average_attendance: activities.reduce((sum, a) => sum + a.attendance_count, 0) / activities.length,
     by_type: {
       meetings: activities.filter(a => a.activity_type === 'meeting').length,
       outings: activities.filter(a => a.activity_type === 'outing').length,
       camporees: activities.filter(a => a.activity_type === 'camporee').length
     }
   };
   ```

4. **Generar PDF o Excel** con el reporte:
   - Fecha, nombre, tipo, asistencia por actividad
   - Gráficos de participación
   - Miembros más activos
   - Tendencias de asistencia

---

### Caso de Uso 4: Actividad con Límite de Cupo

**Escenario**: Salida especial con transporte limitado (solo 25 lugares).

**Flujo**:

1. **Director crea actividad** con límite:
   ```bash
   POST /api/v1/clubs/5/activities
   Body: {
     "name": "Visita al Museo",
     "activity_type": "special_event",
     "activity_date": "2026-03-01T10:00:00.000Z",
     "location": "Museo de Historia Natural",
     "club_pathf_id": 5,
     "max_participants": 25
   }
   ```

2. **Frontend muestra** cupos disponibles:
   ```typescript
   const available = activity.max_participants - activity.attendance_count;
   // "Quedan 25 lugares disponibles"
   ```

3. **Miembros se registran** (por orden de llegada):
   ```bash
   POST /api/v1/activities/10/attendance
   Body: { "user_id": "uuid-member-1" }
   # Registro 1/25

   POST /api/v1/activities/10/attendance
   Body: { "user_id": "uuid-member-2" }
   # Registro 2/25
   ```

4. **Cuando se llena el cupo**:
   ```bash
   POST /api/v1/activities/10/attendance
   Body: { "user_id": "uuid-member-26" }

   # Response 400 Bad Request
   {
     "status": "error",
     "message": "Activity has reached maximum participants limit (25)"
   }
   ```

5. **Director puede aumentar cupo** si consigue más transporte:
   ```bash
   PATCH /api/v1/activities/10
   Body: { "max_participants": 30 }
   ```

---

## ⚠️ Validaciones y Errores Comunes

### Error 1: Duplicar registro de asistencia

**Código**: 409 Conflict

**Mensaje**: `"User already registered attendance for this activity"`

**Causa**: Intentar registrar asistencia del mismo usuario más de una vez en la misma actividad.

**Solución**:
- Verificar asistencia existente antes de registrar
- El frontend debe deshabilitar botón de check-in si ya está registrado

---

### Error 2: Actividad llena (cupo completo)

**Código**: 400 Bad Request

**Mensaje**: `"Activity has reached maximum participants limit"`

**Causa**: Intentar registrar asistencia cuando `attendance_count >= max_participants`.

**Solución**:
- Mostrar claramente cupos disponibles en UI
- Permitir solo a directores aumentar el límite
- Considerar lista de espera

---

### Error 3: Usuario sin permisos para crear actividad

**Código**: 403 Forbidden

**Mensaje**: `"Insufficient permissions. Required roles: director, subdirector, or secretary"`

**Causa**: Usuario con rol de "member" o "counselor" intenta crear actividad.

**Solución**:
- Solo Director, Subdirector y Secretario pueden crear actividades
- Cualquier miembro puede VER actividades
- Consejeros pueden registrar asistencia

---

### Error 4: Fecha de actividad en el pasado

**Código**: 400 Bad Request

**Mensaje**: `"Activity date cannot be in the past"`

**Causa**: Intentar crear actividad con `activity_date` anterior a hoy.

**Solución**:
- Validar fechas en frontend
- Permitir fechas pasadas solo si es para registro histórico (flag especial)
- O permitir pero mostrar advertencia

---

### Error 5: Instancia de club no especificada

**Código**: 400 Bad Request

**Mensaje**: `"Must specify exactly one club instance"`

**Causa**: No se especificó `club_adv_id`, `club_pathf_id`, ni `club_mg_id`.

**Solución**:
```json
// ❌ Incorrecto
{
  "name": "Reunión",
  "activity_date": "2026-02-15T16:00:00.000Z"
}

// ✅ Correcto
{
  "name": "Reunión",
  "activity_date": "2026-02-15T16:00:00.000Z",
  "club_pathf_id": 5
}
```

---

## 🔧 Lógica de Backend

### Validación de Creación de Actividad

```typescript
// activities.service.ts
async create(clubId: number, dto: CreateActivityDto) {
  // 1. Validar que se especificó exactamente UNA instancia de club
  const instanceCount = [
    dto.club_adv_id,
    dto.club_pathf_id,
    dto.club_mg_id
  ].filter(id => id !== null && id !== undefined).length;

  if (instanceCount !== 1) {
    throw new BadRequestException('Must specify exactly one club instance');
  }

  // 2. Validar que activity_date no esté en el pasado (opcional)
  if (new Date(dto.activity_date) < new Date()) {
    throw new BadRequestException('Activity date cannot be in the past');
  }

  // 3. Validar tipo de actividad
  const validTypes = ['meeting', 'outing', 'camporee', 'special_event', 'service'];
  if (dto.activity_type && !validTypes.includes(dto.activity_type)) {
    throw new BadRequestException('Invalid activity type');
  }

  // 4. Crear actividad
  return await this.prisma.activities.create({
    data: {
      name: dto.name,
      description: dto.description,
      activity_type: dto.activity_type || 'meeting',
      activity_date: dto.activity_date,
      end_date: dto.end_date,
      location: dto.location,
      latitude: dto.latitude,
      longitude: dto.longitude,
      club_adv_id: dto.club_adv_id,
      club_pathf_id: dto.club_pathf_id,
      club_mg_id: dto.club_mg_id,
      max_participants: dto.max_participants,
      attendance_count: 0,
      photos: [],
      active: true,
      created_by_user_id: userId
    }
  });
}
```

### Registro de Asistencia con Validaciones

```typescript
async registerAttendance(activityId: number, dto: RegisterAttendanceDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Validar que actividad existe y está activa
    const activity = await tx.activities.findUnique({
      where: { activity_id: activityId, active: true }
    });
    if (!activity) throw new NotFoundException('Activity not found');

    // 2. Validar que usuario no tiene asistencia registrada
    const existing = await tx.activity_attendance.findFirst({
      where: {
        activity_id: activityId,
        user_id: dto.user_id
      }
    });
    if (existing) {
      throw new ConflictException('User already registered attendance for this activity');
    }

    // 3. Validar límite de participantes
    if (activity.max_participants) {
      if (activity.attendance_count >= activity.max_participants) {
        throw new BadRequestException('Activity has reached maximum participants limit');
      }
    }

    // 4. Validar que usuario pertenece al club
    const isMember = await this.validateClubMembership(dto.user_id, activity);
    if (!isMember) {
      throw new ForbiddenException('User is not a member of this club');
    }

    // 5. Crear registro de asistencia
    const attendance = await tx.activity_attendance.create({
      data: {
        activity_id: activityId,
        user_id: dto.user_id,
        check_in_time: dto.check_in_time || new Date(),
        check_out_time: dto.check_out_time,
        attended: true,
        notes: dto.notes
      },
      include: {
        users: {
          select: {
            name: true,
            paternal_last_name: true,
            maternal_last_name: true
          }
        }
      }
    });

    // 6. Incrementar contador de asistencia
    await tx.activities.update({
      where: { activity_id: activityId },
      data: {
        attendance_count: { increment: 1 }
      }
    });

    return attendance;
  });
}
```

### Cálculo de Porcentaje de Asistencia

```typescript
async getActivityWithStats(activityId: number) {
  const activity = await this.prisma.activities.findUnique({
    where: { activity_id: activityId },
    include: {
      activity_attendance: {
        where: { attended: true },
        include: {
          users: {
            select: {
              name: true,
              paternal_last_name: true,
              avatar: true
            }
          }
        }
      }
    }
  });

  // Calcular porcentaje
  const totalMembers = await this.getTotalClubMembers(activity);
  const attendancePercentage = (activity.attendance_count / totalMembers) * 100;

  return {
    ...activity,
    attendance_percentage: Math.round(attendancePercentage * 100) / 100,
    total_club_members: totalMembers
  };
}
```

---

## 📊 Schema de Base de Datos (Prisma)

### Tabla: activities

```prisma
model activities {
  activity_id          Int       @id @default(autoincrement())
  name                 String    @db.VarChar(200)
  description          String?   @db.Text
  activity_type        String    @db.VarChar(50) // meeting, outing, camporee, special_event, service
  activity_date        DateTime
  end_date             DateTime?
  location             String?   @db.VarChar(255)
  latitude             Decimal?  @db.Decimal(10,8)
  longitude            Decimal?  @db.Decimal(11,8)

  // Club instance (solo UNA con valor)
  club_adv_id          Int?
  club_pathf_id        Int?
  club_mg_id           Int?

  max_participants     Int?
  attendance_count     Int       @default(0)
  photos               String[]  // Array de URLs
  documents            String[]  // Array de URLs

  active               Boolean   @default(true)
  created_by_user_id   String    @db.Uuid
  created_at           DateTime  @default(now())
  updated_at           DateTime  @updatedAt

  // Relations
  club_adventurers     club_adventurers?   @relation(fields: [club_adv_id], references: [club_adv_id])
  club_pathfinders     club_pathfinders?   @relation(fields: [club_pathf_id], references: [club_pathf_id])
  club_master_guides   club_master_guides? @relation(fields: [club_mg_id], references: [club_mg_id])
  created_by           users               @relation(fields: [created_by_user_id], references: [id])
  activity_attendance  activity_attendance[]

  @@index([club_adv_id])
  @@index([club_pathf_id])
  @@index([club_mg_id])
  @@index([activity_date])
  @@index([activity_type])
  @@map("activities")
}
```

### Tabla: activity_attendance

```prisma
model activity_attendance {
  attendance_id   Int       @id @default(autoincrement())
  activity_id     Int
  user_id         String    @db.Uuid
  check_in_time   DateTime  @default(now())
  check_out_time  DateTime?
  attended        Boolean   @default(true)
  notes           String?   @db.Text
  created_at      DateTime  @default(now())
  updated_at      DateTime  @updatedAt

  // Relations
  activities      activities @relation(fields: [activity_id], references: [activity_id], onDelete: Cascade)
  users           users      @relation(fields: [user_id], references: [id])

  @@unique([activity_id, user_id])
  @@index([activity_id])
  @@index([user_id])
  @@map("activity_attendance")
}
```

---

## 🧪 Tests E2E - Ejemplo

```typescript
// test/activities.e2e-spec.ts
describe('Activities (e2e)', () => {
  let directorToken: string;
  let memberToken: string;
  let activityId: number;

  beforeAll(async () => {
    directorToken = await getAuthToken('director@club.com');
    memberToken = await getAuthToken('member@club.com');
  });

  it('should list club activities', async () => {
    const response = await request(app.getHttpServer())
      .get('/clubs/5/activities?clubTypeId=2')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);

    expect(response.body.data).toBeInstanceOf(Array);
    expect(response.body).toHaveProperty('meta');
  });

  it('should create activity as director', async () => {
    const response = await request(app.getHttpServer())
      .post('/clubs/5/activities')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Test Activity',
        activity_type: 'meeting',
        activity_date: '2026-03-01T16:00:00.000Z',
        location: 'Test Location',
        club_pathf_id: 5
      })
      .expect(201);

    expect(response.body.data.name).toBe('Test Activity');
    activityId = response.body.data.activity_id;
  });

  it('should reject creation by regular member', async () => {
    await request(app.getHttpServer())
      .post('/clubs/5/activities')
      .set('Authorization', `Bearer ${memberToken}`)
      .send({
        name: 'Unauthorized Activity',
        activity_date: '2026-03-01T16:00:00.000Z',
        club_pathf_id: 5
      })
      .expect(403);
  });

  it('should register attendance', async () => {
    const response = await request(app.getHttpServer())
      .post(`/activities/${activityId}/attendance`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        user_id: 'uuid-member-1'
      })
      .expect(201);

    expect(response.body.data.attended).toBe(true);
    expect(response.body.meta.activity_attendance_count).toBe(1);
  });

  it('should prevent duplicate attendance', async () => {
    await request(app.getHttpServer())
      .post(`/activities/${activityId}/attendance`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        user_id: 'uuid-member-1'
      })
      .expect(409);
  });

  it('should enforce max participants limit', async () => {
    // Crear actividad con límite de 2
    const activity = await request(app.getHttpServer())
      .post('/clubs/5/activities')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Limited Activity',
        activity_date: '2026-03-05T10:00:00.000Z',
        club_pathf_id: 5,
        max_participants: 2
      });

    const limitedActivityId = activity.body.data.activity_id;

    // Registrar 2 asistencias
    await request(app.getHttpServer())
      .post(`/activities/${limitedActivityId}/attendance`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({ user_id: 'uuid-member-1' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/activities/${limitedActivityId}/attendance`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({ user_id: 'uuid-member-2' })
      .expect(201);

    // Tercera asistencia debe fallar
    await request(app.getHttpServer())
      .post(`/activities/${limitedActivityId}/attendance`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({ user_id: 'uuid-member-3' })
      .expect(400);
  });

  it('should update activity', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/activities/${activityId}`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        description: 'Updated description',
        max_participants: 30
      })
      .expect(200);

    expect(response.body.data.description).toBe('Updated description');
  });

  it('should soft delete activity', async () => {
    const response = await request(app.getHttpServer())
      .delete(`/activities/${activityId}`)
      .set('Authorization', `Bearer ${directorToken}`)
      .expect(200);

    expect(response.body.data.active).toBe(false);
  });
});
```

---

## 📝 Tipos de Actividad

### Tipos Predefinidos

```typescript
enum ActivityType {
  MEETING = 'meeting',           // Reunión regular del club
  OUTING = 'outing',             // Salida (misionera, campo, etc.)
  CAMPOREE = 'camporee',         // Campamento/Camporee
  SPECIAL_EVENT = 'special_event', // Evento especial (investidura, aniversario)
  SERVICE = 'service',           // Servicio comunitario
  TRAINING = 'training',         // Capacitación/Taller
  CEREMONY = 'ceremony'          // Ceremonia (investidura, clausura)
}
```

### Uso en Frontend

```typescript
const activityTypeLabels = {
  meeting: 'Reunión',
  outing: 'Salida',
  camporee: 'Campamento',
  special_event: 'Evento Especial',
  service: 'Servicio Comunitario',
  training: 'Capacitación',
  ceremony: 'Ceremonia'
};

const activityTypeIcons = {
  meeting: '📅',
  outing: '🚌',
  camporee: '⛺',
  special_event: '🎉',
  service: '🤝',
  training: '📚',
  ceremony: '🏆'
};
```

---

## 📍 Uso de Geolocalización

### Capturar Ubicación en Frontend

```typescript
// Obtener ubicación actual del dispositivo
navigator.geolocation.getCurrentPosition(
  (position) => {
    const latitude = position.coords.latitude;
    const longitude = position.coords.longitude;

    // Usar con reverse geocoding para obtener dirección
    fetch(`https://maps.googleapis.com/maps/api/geocode/json?latlng=${latitude},${longitude}&key=${API_KEY}`)
      .then(res => res.json())
      .then(data => {
        const location = data.results[0].formatted_address;

        // Crear actividad con ubicación
        createActivity({
          name: 'Mi Actividad',
          location: location,
          latitude: latitude,
          longitude: longitude
        });
      });
  }
);
```

### Mostrar Mapa de Actividad

```typescript
// Usando Google Maps o Mapbox
const ActivityMap = ({ activity }) => {
  return (
    <Map
      center={{ lat: activity.latitude, lng: activity.longitude }}
      zoom={15}
    >
      <Marker position={{ lat: activity.latitude, lng: activity.longitude }} />
    </Map>
  );
};
```

---

**Generado**: 4 de febrero de 2026
**Versión**: 2.2
**Módulo**: Activities
**Endpoints documentados**: 7
**Estado**: Producción
