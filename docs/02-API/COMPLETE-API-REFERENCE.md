<!-- CANONICAL-API-NOTE -->
> [!WARNING]
> Este documento puede incluir rutas históricas/propuestas o ejemplos desactualizados.
> Para consumo de agentes (App + Panel), usar como contrato canónico:
> [ENDPOINTS-LIVE-REFERENCE.md](./ENDPOINTS-LIVE-REFERENCE.md)

# 📚 Complete SACDIA API Reference

> [!IMPORTANT]
> **Base URL**: All endpoints use the prefix `/api/v1`  
> Example: `GET /api/v1/auth/me` (not `/auth/me`)

## Table of Contents

- [Authentication](#authentication)
- [Users](#users)
- [Catalogs](#catalogs)
- [Clubs](#clubs)
- [Classes](#classes)
- [Honors](#honors)
- [Activities](#activities)
- [Finances](#finances)
- [Notifications](#notifications)
- [Emergency Contacts](#emergency-contacts)
- [Legal Representatives](#legal-representatives)
- [Post-Registration](#post-registration)
- [Admin Users (Scope-Based Access)](#admin-users-scope-based-access)
- [RBAC (Roles & Permissions)](#rbac-roles--permissions)

---

## 🔑 Authentication

### POST `/api/v1/auth/register`

**Description**: Register a new user  
**Authentication**: None  
**Request Body**:

```json
{
  "name": "Juan",
  "paternal_last_name": "García",
  "maternal_last_name": "López",
  "email": "juan.garcia@example.com",
  "password": "Password123!"
}
```

**Requirements**:

- Password: min 8 characters, must include uppercase, lowercase, number, and special character (@$!%\*?&)

**Response** (201):

```json
{
  "message": "Usuario registrado exitosamente",
  "user": {
    "id": "uuid",
    "email": "juan.garcia@example.com",
    "name": "Juan",
    "paternal_last_name": "García",
    "maternal_last_name": "López"
  }
}
```

---

### POST `/api/v1/auth/login`

**Description**: User login  
**Authentication**: None  
**Request Body**:

```json
{
  "email": "juan.garcia@example.com",
  "password": "Password123!"
}
```

**Response** (200):

```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 3600,
  "user": {
    "id": "uuid",
    "email": "juan.garcia@example.com",
    "name": "Juan",
    "picture_url": null,
    "post_registration_completed": false
  }
}
```

---

### POST `/api/v1/auth/refresh`

**Description**: Refresh access token  
**Authentication**: None  
**Request Body**:

```json
{
  "refresh_token": "eyJhbGc..."
}
```

**Response** (200):

```json
{
  "access_token": "eyJhbGc...",
  "expires_in": 3600
}
```

---

### POST `/api/v1/auth/logout`

**Description**: Logout user (invalidates refresh token)  
**Authentication**: JWT Bearer Token  
**Request Body**:

```json
{
  "refresh_token": "eyJhbGc..."
}
```

**Response** (200):

```json
{
  "message": "Sesión cerrada exitosamente"
}
```

---

### GET `/api/v1/auth/me`

**Description**: Get current user profile  
**Authentication**: JWT Bearer Token

**Response** (200):

```json
{
  "id": "uuid",
  "email": "juan.garcia@example.com",
  "name": "Juan",
  "paternal_last_name": "García",
  "maternal_last_name": "López",
  "picture_url": "https://...",
  "gender": "M",
  "birthday": "2000-01-15",
  "baptism": true,
  "baptism_date": "2015-06-20",
  "blood": "A_POSITIVE",
  "post_registration_completed": true,
  "created_at": "2024-01-01T00:00:00Z"
}
```

---

### POST `/api/v1/auth/request-password-reset`

**Description**: Request password reset email  
**Authentication**: None  
**Request Body**:

```json
{
  "email": "juan.garcia@example.com"
}
```

**Response** (200):

```json
{
  "message": "Si el correo existe, se ha enviado un enlace de recuperación"
}
```

---

### POST `/api/v1/auth/reset-password`

**Description**: Reset password with token  
**Authentication**: None  
**Request Body**:

```json
{
  "token": "reset_token_here",
  "new_password": "NewPassword123!"
}
```

**Response** (200):

```json
{
  "message": "Contraseña actualizada exitosamente"
}
```

---

## 👤 Users

### GET `/api/v1/users/:userId`

**Description**: Get user profile by ID  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "id": "uuid",
  "email": "juan.garcia@example.com",
  "name": "Juan",
  "paternal_last_name": "García",
  "maternal_last_name": "López",
  "picture_url": "https://...",
  "gender": "M",
  "birthday": "2000-01-15",
  "baptism": true,
  "baptism_date": "2015-06-20",
  "blood": "A_POSITIVE"
}
```

---

### PATCH `/api/v1/users/:userId`

**Description**: Update user profile  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Request Body** (all fields optional):

```json
{
  "gender": "M",
  "birthday": "2000-01-15",
  "baptism": true,
  "baptism_date": "2015-06-20",
  "blood": "A_POSITIVE"
}
```

**Response** (200):

```json
{
  "message": "Perfil actualizado exitosamente",
  "user": {
    /* updated user object */
  }
}
```

---

### POST `/api/v1/users/:userId/picture`

**Description**: Upload profile picture  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Request**:

- Content-Type: `multipart/form-data`
- Field: `file` (image file)

**Response** (200):

```json
{
  "picture_url": "https://storage.../profile.jpg"
}
```

---

### DELETE `/api/v1/users/:userId/picture`

**Description**: Remove profile picture  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "message": "Foto eliminada exitosamente"
}
```

---

### GET `/api/v1/users/:userId/age`

**Description**: Calculate user's age from birthday  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "age": 24,
  "birthday": "2000-01-15"
}
```

---

### GET `/api/v1/users/:userId/needs-legal-representative`

**Description**: Check if user needs legal representative (under 18)  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "needs_legal_representative": true,
  "age": 16
}
```

---

## 📖 Catalogs

All catalog endpoints are **public** (no authentication required).

### GET `/api/v1/catalogs/club-types`

**Description**: List club types

**Response** (200):

```json
[
  {
    "club_type_id": 1,
    "name": "Aventureros",
    "description": "6-9 años"
  },
  {
    "club_type_id": 2,
    "name": "Conquistadores",
    "description": "10-15 años"
  },
  {
    "club_type_id": 3,
    "name": "Guías Mayores",
    "description": "16+ años"
  }
]
```

---

### GET `/api/v1/catalogs/countries`

**Description**: List countries

**Response** (200):

```json
[
  {
    "country_id": 1,
    "name": "México",
    "code": "MX"
  }
]
```

---

### GET `/api/v1/catalogs/unions`

**Description**: List unions (optionally by country)  
**Query Parameters**:

- `countryId` (number, optional): Filter by country

**Response** (200):

```json
[
  {
    "union_id": 1,
    "name": "Unión Mexicana del Norte",
    "country_id": 1
  }
]
```

---

### GET `/api/v1/catalogs/local-fields`

**Description**: List local fields (optionally by union)  
**Query Parameters**:

- `unionId` (number, optional): Filter by union

**Response** (200):

```json
[
  {
    "local_field_id": 1,
    "name": "Norte de México",
    "union_id": 1
  }
]
```

---

### GET `/api/v1/catalogs/districts`

**Description**: List districts (optionally by field)  
**Query Parameters**:

- `localFieldId` (number, optional): Filter by local field

**Response** (200):

```json
[
  {
    "district_id": 1,
    "name": "Distrito 1",
    "local_field_id": 1
  }
]
```

---

### GET `/api/v1/catalogs/churches`

**Description**: List churches (optionally by district)  
**Query Parameters**:

- `districtId` (number, optional): Filter by district

**Response** (200):

```json
[
  {
    "church_id": 1,
    "name": "Iglesia Central",
    "district_id": 1
  }
]
```

---

### GET `/api/v1/catalogs/roles`

**Description**: List club roles  
**Query Parameters**:

- `clubTypeId` (number, optional): Filter by club type

**Response** (200):

```json
[
  {
    "role_id": 1,
    "name": "director",
    "display_name": "Director",
    "club_type_id": 2
  },
  {
    "role_id": 2,
    "name": "member",
    "display_name": "Miembro",
    "club_type_id": 2
  }
]
```

---

### GET `/api/v1/catalogs/ecclesiastical-years`

**Description**: List ecclesiastical years  
**Query Parameters**:

- `active` (boolean, optional): Filter by active status

**Response** (200):

```json
[
  {
    "ecclesiastical_year_id": 1,
    "name": "2024",
    "start_date": "2024-01-01",
    "end_date": "2024-12-31",
    "active": true
  }
]
```

---

## 🏛️ Clubs

### GET `/api/v1/clubs`

**Description**: List all clubs  
**Authentication**: JWT Bearer Token  
**Query Parameters**:

- `page` (number, optional, default: 1): Page number
- `limit` (number, optional, default: 10, max: 100): Items per page
- `clubTypeId` (number, optional): Filter by club type
- `localFieldId` (number, optional): Filter by local field

**Response** (200):

```json
{
  "data": [
    {
      "club_id": 1,
      "name": "Club Central",
      "description": "...",
      "local_field_id": 1,
      "district_id": 1,
      "church_id": 1,
      "address": "Calle Principal 123",
      "coordinates": { "lat": 19.4326, "lng": -99.1332 },
      "active": true
    }
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "limit": 10,
    "totalPages": 5
  }
}
```

---

### POST `/api/v1/clubs`

**Description**: Create new club  
**Authentication**: JWT Bearer Token (admin)  
**Request Body**:

```json
{
  "name": "Club Central",
  "description": "Descripción del club",
  "local_field_id": 1,
  "district_id": 1,
  "church_id": 1,
  "address": "Calle Principal 123",
  "coordinates": { "lat": 19.4326, "lng": -99.1332 }
}
```

**Response** (201):

```json
{
  "club_id": 1,
  "name": "Club Central",
  "active": true
}
```

---

### GET `/api/v1/clubs/:clubId`

**Description**: Get club details  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `clubId` (number): Club ID

**Response** (200):

```json
{
  "club_id": 1,
  "name": "Club Central",
  "description": "...",
  "instances": [
    {
      "adventurers_id": 1,
      "club_type_id": 1,
      "name": "Aventureros Central",
      "active": true
    },
    {
      "pathfinders_id": 1,
      "club_type_id": 2,
      "name": "Conquistadores Central",
      "active": true
    }
  ]
}
```

---

### PATCH `/api/v1/clubs/:clubId`

**Description**: Update club  
**Authentication**: JWT Bearer Token (admin)  
**URL Parameters**:

- `clubId` (number): Club ID

**Request Body** (all fields optional):

```json
{
  "name": "Club Actualizado",
  "description": "Nueva descripción",
  "address": "Nueva dirección",
  "coordinates": { "lat": 19.4326, "lng": -99.1332 },
  "active": true
}
```

**Response** (200):

```json
{
  "message": "Club actualizado exitosamente",
  "club": {
    /* updated club */
  }
}
```

---

### DELETE `/api/v1/clubs/:clubId`

**Description**: Deactivate club (soft delete)  
**Authentication**: JWT Bearer Token (admin)  
**URL Parameters**:

- `clubId` (number): Club ID

**Response** (200):

```json
{
  "message": "Club desactivado exitosamente"
}
```

---

### GET `/api/v1/clubs/:clubId/instances`

**Description**: Get club instances (Aventureros, Conquistadores, GM)  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `clubId` (number): Club ID

**Response** (200):

```json
[
  {
    "instance_id": 1,
    "instance_type": "adventurers",
    "club_type_id": 1,
    "name": "Aventureros Central",
    "active": true,
    "members_count": 25
  }
]
```

---

### POST `/api/v1/clubs/:clubId/instances`

**Description**: Create club instance  
**Authentication**: JWT Bearer Token (admin)  
**URL Parameters**:

- `clubId` (number): Club ID

**Request Body**:

```json
{
  "club_type_id": 2,
  "name": "Conquistadores Central"
}
```

**Response** (201):

```json
{
  "instance_id": 1,
  "instance_type": "pathfinders",
  "club_type_id": 2,
  "name": "Conquistadores Central"
}
```

---

### PATCH `/api/v1/clubs/:clubId/instances/:instanceType/:instanceId`

**Description**: Update club instance  
**Authentication**: JWT Bearer Token (admin)  
**URL Parameters**:

- `clubId` (number): Club ID
- `instanceType` (string): `adventurers`, `pathfinders`, or `master_guilds`
- `instanceId` (number): Instance ID

**Request Body**:

```json
{
  "name": "Nuevo nombre",
  "active": true
}
```

**Response** (200):

```json
{
  "message": "Instancia actualizada",
  "instance": {
    /* updated instance */
  }
}
```

---

### GET `/api/v1/clubs/:clubId/instances/:instanceType/:instanceId/members`

**Description**: Get instance members  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `clubId` (number): Club ID
- `instanceType` (string): Instance type
- `instanceId` (number): Instance ID

**Query Parameters**:

- `yearId` (number, optional): Filter by ecclesiastical year
- `active` (boolean, optional): Filter by active status

**Response** (200):

```json
[
  {
    "user_id": "uuid",
    "name": "Juan García López",
    "picture_url": "https://...",
    "role": "member",
    "role_display_name": "Miembro",
    "start_date": "2024-01-01",
    "active": true
  }
]
```

---

### POST `/api/v1/clubs/:clubId/instances/:instanceType/:instanceId/members`

**Description**: Add member to instance  
**Authentication**: JWT Bearer Token (director, subdirector, secretary)  
**URL Parameters**:

- `clubId` (number): Club ID
- `instanceType` (string): Instance type
- `instanceId` (number): Instance ID

**Request Body**:

```json
{
  "user_id": "uuid",
  "role_id": 2,
  "ecclesiastical_year_id": 1
}
```

**Response** (201):

```json
{
  "message": "Miembro agregado exitosamente",
  "assignment": {
    /* role assignment */
  }
}
```

---

### PATCH `/api/v1/clubs/:clubId/instances/:instanceType/:instanceId/members/:userId/role`

**Description**: Update member role  
**Authentication**: JWT Bearer Token (director, subdirector)  
**URL Parameters**:

- `clubId` (number): Club ID
- `instanceType` (string): Instance type
- `instanceId` (number): Instance ID
- `userId` (string, UUID): User ID

**Request Body**:

```json
{
  "role_id": 1
}
```

**Response** (200):

```json
{
  "message": "Rol actualizado exitosamente"
}
```

---

### DELETE `/api/v1/clubs/:clubId/instances/:instanceType/:instanceId/members/:userId`

**Description**: Remove member from instance  
**Authentication**: JWT Bearer Token (director, subdirector)  
**URL Parameters**:

- `clubId` (number): Club ID
- `instanceType` (string): Instance type
- `instanceId` (number): Instance ID
- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "message": "Miembro eliminado exitosamente"
}
```

---

## 📚 Classes

### GET `/api/v1/classes`

**Description**: List available classes  
**Authentication**: None (public)  
**Query Parameters**:

- `clubTypeId` (number, optional): Filter by club type (1=Aventureros, 2=Conquistadores, 3=GM)
- `page` (number, optional, default: 1): Page number
- `limit` (number, optional, default: 10, max: 100): Items per page

**Response** (200):

```json
{
  "data": [
    {
      "class_id": 1,
      "name": "Amigo",
      "description": "Primera clase de Conquistadores",
      "club_type_id": 2,
      "display_order": 1,
      "active": true
    }
  ],
  "meta": {
    "total": 15,
    "page": 1,
    "limit": 10,
    "totalPages": 2
  }
}
```

---

### GET `/api/v1/classes/:classId`

**Description**: Get class details with modules and sections  
**Authentication**: None (public)  
**URL Parameters**:

- `classId` (number): Class ID

**Response** (200):

```json
{
  "class_id": 1,
  "name": "Amigo",
  "description": "...",
  "club_type_id": 2,
  "modules": [
    {
      "module_id": 1,
      "title": "Descubrimiento Espiritual",
      "display_order": 1,
      "sections": [
        {
          "section_id": 1,
          "title": "Memorizar y explicar el voto",
          "description": "...",
          "display_order": 1
        }
      ]
    }
  ]
}
```

---

### GET `/api/v1/classes/:classId/modules`

**Description**: Get class modules  
**Authentication**: None (public)  
**URL Parameters**:

- `classId` (number): Class ID

**Response** (200):

```json
[
  {
    "module_id": 1,
    "title": "Descubrimiento Espiritual",
    "display_order": 1,
    "sections_count": 5
  }
]
```

---

### GET `/api/v1/users/:userId/classes`

**Description**: Get user enrollments  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Query Parameters**:

- `yearId` (number, optional): Filter by ecclesiastical year

**Response** (200):

```json
[
  {
    "class_id": 1,
    "class_name": "Amigo",
    "ecclesiastical_year_id": 1,
    "year_name": "2024",
    "enrollment_date": "2024-01-15",
    "completed": false,
    "progress_percentage": 35
  }
]
```

---

### POST `/api/v1/users/:userId/classes/enroll`

**Description**: Enroll user in class  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Request Body**:

```json
{
  "class_id": 1,
  "ecclesiastical_year_id": 1
}
```

**Response** (201):

```json
{
  "message": "Inscripción creada exitosamente",
  "enrollment": {
    /* enrollment details */
  }
}
```

---

### GET `/api/v1/users/:userId/classes/:classId/progress`

**Description**: Get user progress in class  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `classId` (number): Class ID

**Response** (200):

```json
{
  "class_id": 1,
  "class_name": "Amigo",
  "progress_percentage": 35,
  "modules": [
    {
      "module_id": 1,
      "title": "Descubrimiento Espiritual",
      "sections": [
        {
          "section_id": 1,
          "title": "Memorizar el voto",
          "score": 100,
          "completed": true,
          "evidences": ["https://..."]
        }
      ]
    }
  ]
}
```

---

### PATCH `/api/v1/users/:userId/classes/:classId/progress`

**Description**: Update section progress  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `classId` (number): Class ID

**Request Body**:

```json
{
  "module_id": 1,
  "section_id": 1,
  "score": 100,
  "evidences": ["https://storage.../evidence1.jpg"]
}
```

**Response** (200):

```json
{
  "message": "Progreso actualizado",
  "section_progress": {
    /* updated progress */
  }
}
```

---

## 🏅 Honors

### GET `/api/v1/honors`

**Description**: List available honors  
**Authentication**: None (public)  
**Query Parameters**:

- `categoryId` (number, optional): Filter by category
- `clubTypeId` (number, optional): Filter by club type
- `skillLevel` (number, optional): Filter by skill level (1=Básico, 2=Avanzado, 3=Máster)
- `page` (number, optional): Page number
- `limit` (number, optional, max: 100): Items per page

**Response** (200):

```json
{
  "data": [
    {
      "honor_id": 1,
      "name": "Nudos",
      "category_id": 1,
      "category_name": "Habilidades",
      "skill_level": 1,
      "club_type_id": 2,
      "description": "...",
      "active": true
    }
  ],
  "meta": {
    "total": 200,
    "page": 1,
    "limit": 10,
    "totalPages": 20
  }
}
```

---

### GET `/api/v1/honors/categories`

**Description**: List honor categories  
**Authentication**: None (public)

**Response** (200):

```json
[
  {
    "category_id": 1,
    "name": "Habilidades Prácticas"
  },
  {
    "category_id": 2,
    "name": "Naturaleza"
  }
]
```

---

### GET `/api/v1/honors/:honorId`

**Description**: Get honor details  
**Authentication**: None (public)  
**URL Parameters**:

- `honorId` (number): Honor ID

**Response** (200):

```json
{
  "honor_id": 1,
  "name": "Nudos",
  "description": "...",
  "category_id": 1,
  "skill_level": 1,
  "club_type_id": 2,
  "requirements": "...",
  "active": true
}
```

---

### GET `/api/v1/users/:userId/honors`

**Description**: Get user honors  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Query Parameters**:

- `validated` (boolean, optional): Filter by validation status

**Response** (200):

```json
[
  {
    "honor_id": 1,
    "honor_name": "Nudos",
    "start_date": "2024-01-15",
    "completion_date": "2024-03-20",
    "validated": true,
    "validation_date": "2024-03-22",
    "evidences": ["https://..."],
    "certificate_url": "https://..."
  }
]
```

---

### GET `/api/v1/users/:userId/honors/stats`

**Description**: Get user honor statistics  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "total_honors": 15,
  "validated_honors": 10,
  "in_progress": 5,
  "by_category": {
    "Habilidades Prácticas": 5,
    "Naturaleza": 3,
    "Ciencia": 2
  },
  "by_skill_level": {
    "Básico": 8,
    "Avanzado": 5,
    "Máster": 2
  }
}
```

---

### POST `/api/v1/users/:userId/honors/:honorId`

**Description**: Start working on honor  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `honorId` (number): Honor ID

**Request Body**:

```json
{
  "ecclesiastical_year_id": 1
}
```

**Response** (201):

```json
{
  "message": "Honor iniciado exitosamente",
  "user_honor": {
    /* honor details */
  }
}
```

---

### PATCH `/api/v1/users/:userId/honors/:honorId`

**Description**: Update honor progress  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `honorId` (number): Honor ID

**Request Body** (all fields optional):

```json
{
  "evidences": ["https://storage.../evidence1.jpg"],
  "validated": true,
  "certificate_url": "https://storage.../certificate.pdf"
}
```

**Response** (200):

```json
{
  "message": "Honor actualizado",
  "user_honor": {
    /* updated honor */
  }
}
```

---

### DELETE `/api/v1/users/:userId/honors/:honorId`

**Description**: Abandon honor (deactivate)  
**Authentication**: JWT Bearer Token (owner or admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `honorId` (number): Honor ID

**Response** (200):

```json
{
  "message": "Honor abandonado exitosamente"
}
```

---

## 📅 Activities

### GET `/api/v1/clubs/:clubId/activities`

**Description**: List club activities  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `clubId` (number): Club ID

**Query Parameters**:

- `clubTypeId` (number, optional): Filter by club type
- `active` (boolean, optional): Filter by active status
- `activityType` (number, optional): Filter by activity type
- `page` (number, optional): Page number
- `limit` (number, optional, max: 100): Items per page

**Response** (200):

```json
{
  "data": [
    {
      "activity_id": 1,
      "title": "Campamento de Invierno",
      "description": "...",
      "activity_type": 1,
      "start_date": "2024-02-15T08:00:00Z",
      "end_date": "2024-02-17T18:00:00Z",
      "location": "Campamento El Pinar",
      "club_type_id": 2,
      "active": true,
      "created_by": "uuid"
    }
  ],
  "meta": {
    "total": 25,
    "page": 1,
    "limit": 10
  }
}
```

---

### POST `/api/v1/clubs/:clubId/activities`

**Description**: Create activity  
**Authentication**: JWT Bearer Token (director, subdirector, secretary, counselor)  
**URL Parameters**:

- `clubId` (number): Club ID

**Request Body**:

```json
{
  "title": "Campamento de Invierno",
  "description": "Actividad de campamento para conquistadores",
  "activity_type": 1,
  "start_date": "2024-02-15T08:00:00Z",
  "end_date": "2024-02-17T18:00:00Z",
  "location": "Campamento El Pinar",
  "instance_type": "pathfinders",
  "instance_id": 1
}
```

**Response** (201):

```json
{
  "activity_id": 1,
  "title": "Campamento de Invierno",
  "message": "Actividad creada exitosamente"
}
```

---

### GET `/api/v1/activities/:activityId`

**Description**: Get activity details  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `activityId` (number): Activity ID

**Response** (200):

```json
{
  "activity_id": 1,
  "title": "Campamento de Invierno",
  "description": "...",
  "activity_type": 1,
  "start_date": "2024-02-15T08:00:00Z",
  "end_date": "2024-02-17T18:00:00Z",
  "location": "Campamento El Pinar",
  "club_type_id": 2,
  "attendance_count": 35
}
```

---

### PATCH `/api/v1/activities/:activityId`

**Description**: Update activity  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `activityId` (number): Activity ID

**Request Body** (all fields optional):

```json
{
  "title": "Nuevo título",
  "description": "Nueva descripción",
  "start_date": "2024-02-16T08:00:00Z",
  "end_date": "2024-02-18T18:00:00Z",
  "location": "Nueva ubicación",
  "active": true
}
```

**Response** (200):

```json
{
  "message": "Actividad actualizada",
  "activity": {
    /* updated activity */
  }
}
```

---

### DELETE `/api/v1/activities/:activityId`

**Description**: Deactivate activity  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `activityId` (number): Activity ID

**Response** (200):

```json
{
  "message": "Actividad desactivada"
}
```

---

### POST `/api/v1/activities/:activityId/attendance`

**Description**: Record attendance  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `activityId` (number): Activity ID

**Request Body**:

```json
{
  "user_ids": ["uuid1", "uuid2", "uuid3"]
}
```

**Response** (201):

```json
{
  "message": "Asistencia registrada",
  "recorded_count": 3
}
```

---

### GET `/api/v1/activities/:activityId/attendance`

**Description**: Get activity attendance  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `activityId` (number): Activity ID

**Response** (200):

```json
[
  {
    "user_id": "uuid",
    "name": "Juan García López",
    "picture_url": "https://...",
    "attended_at": "2024-02-15T10:30:00Z"
  }
]
```

---

## 💰 Finances

### GET `/api/v1/finances/categories`

**Description**: List financial categories  
**Authentication**: JWT Bearer Token  
**Query Parameters**:

- `type` (number, optional): 0=Income, 1=Expenses

**Response** (200):

```json
[
  {
    "category_id": 1,
    "name": "Cuotas",
    "type": 0,
    "description": "Ingresos por cuotas de miembros"
  },
  {
    "category_id": 2,
    "name": "Material",
    "type": 1,
    "description": "Gastos en material"
  }
]
```

---

### GET `/api/v1/clubs/:clubId/finances`

**Description**: List club financial movements  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `clubId` (number): Club ID

**Query Parameters**:

- `year` (number, optional): Filter by year
- `month` (number, optional): Filter by month (1-12)
- `clubTypeId` (number, optional): Filter by club type
- `categoryId` (number, optional): Filter by category
- `page` (number, optional): Page number
- `limit` (number, optional, max: 100): Items per page

**Response** (200):

```json
{
  "data": [
    {
      "finance_id": 1,
      "description": "Cuota mensual enero",
      "amount": 150.0,
      "transaction_date": "2024-01-15",
      "category_id": 1,
      "category_name": "Cuotas",
      "type": 0,
      "club_type_id": 2,
      "created_by": "uuid"
    }
  ],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 10
  }
}
```

---

### GET `/api/v1/clubs/:clubId/finances/summary`

**Description**: Get financial summary  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `clubId` (number): Club ID

**Query Parameters**:

- `year` (number, optional): Filter by year
- `month` (number, optional): Filter by month

**Response** (200):

```json
{
  "total_income": 5000.0,
  "total_expenses": 3200.0,
  "balance": 1800.0,
  "by_category": [
    {
      "category_name": "Cuotas",
      "total": 3000.0,
      "type": 0
    },
    {
      "category_name": "Material",
      "total": 1500.0,
      "type": 1
    }
  ]
}
```

---

### POST `/api/v1/clubs/:clubId/finances`

**Description**: Create financial movement  
**Authentication**: JWT Bearer Token (director, subdirector, treasurer)  
**URL Parameters**:

- `clubId` (number): Club ID

**Request Body**:

```json
{
  "description": "Cuota mensual enero",
  "amount": 150.0,
  "transaction_date": "2024-01-15",
  "category_id": 1,
  "instance_type": "pathfinders",
  "instance_id": 1
}
```

**Response** (201):

```json
{
  "finance_id": 1,
  "message": "Movimiento creado exitosamente"
}
```

---

### GET `/api/v1/finances/:financeId`

**Description**: Get financial movement details  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `financeId` (number): Finance ID

**Response** (200):

```json
{
  "finance_id": 1,
  "description": "Cuota mensual enero",
  "amount": 150.0,
  "transaction_date": "2024-01-15",
  "category_id": 1,
  "category_name": "Cuotas",
  "type": 0,
  "club_type_id": 2
}
```

---

### PATCH `/api/v1/finances/:financeId`

**Description**: Update financial movement  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `financeId` (number): Finance ID

**Request Body** (all fields optional):

```json
{
  "description": "Nueva descripción",
  "amount": 200.0,
  "transaction_date": "2024-01-20",
  "category_id": 2
}
```

**Response** (200):

```json
{
  "message": "Movimiento actualizado",
  "finance": {
    /* updated finance */
  }
}
```

---

### DELETE `/api/v1/finances/:financeId`

**Description**: Deactivate financial movement  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `financeId` (number): Finance ID

**Response** (200):

```json
{
  "message": "Movimiento desactivado"
}
```

---

## 🔔 Notifications

### POST `/api/v1/notifications/send`

**Description**: Send notification to specific user  
**Authentication**: JWT Bearer Token  
**Request Body**:

```json
{
  "userId": "uuid",
  "title": "Nuevo mensaje",
  "body": "Tienes una nueva actividad programada",
  "data": {
    "activity_id": "1",
    "type": "activity"
  }
}
```

**Response** (200):

```json
{
  "message": "Notificación enviada",
  "sent_count": 1
}
```

---

### POST `/api/v1/notifications/broadcast`

**Description**: Send notification to all users  
**Authentication**: JWT Bearer Token (`admin` | `super_admin`)  
**Request Body**:

```json
{
  "title": "Anuncio importante",
  "body": "Reunión general este sábado",
  "data": {
    "type": "announcement"
  }
}
```

**Response** (200):

```json
{
  "message": "Notificación enviada a todos los usuarios",
  "sent_count": 250
}
```

---

### POST `/api/v1/notifications/club/:instanceType/:instanceId`

**Description**: Send notification to club members  
**Authentication**: JWT Bearer Token (`admin` | `super_admin`)  
**URL Parameters**:

- `instanceType` (string): `adventurers`, `pathfinders`, or `master_guilds`
- `instanceId` (number): Instance ID

**Request Body**:

```json
{
  "title": "Reunión de club",
  "body": "Reunión este sábado a las 10 AM",
  "data": {
    "type": "club_announcement"
  }
}
```

**Response** (200):

```json
{
  "message": "Notificación enviada a miembros del club",
  "sent_count": 35
}
```

---

### POST `/api/v1/fcm-tokens`

**Description**: Register FCM token for push notifications  
**Authentication**: JWT Bearer Token  
**Request Body**:

```json
{
  "token": "fcm_token_here",
  "device_type": "iOS",
  "device_name": "iPhone 13"
}
```

**Response** (201):

```json
{
  "message": "Token registrado exitosamente"
}
```

---

### DELETE `/api/v1/fcm-tokens/:token`

**Description**: Unregister FCM token  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `token` (string): FCM token to remove

**Response** (200):

```json
{
  "message": "Token eliminado exitosamente"
}
```

---

### GET `/api/v1/fcm-tokens`

**Description**: Get current authenticated user FCM tokens  
**Authentication**: JWT Bearer Token  

**Response** (200):

```json
[
  {
    "token": "fcm_token_here",
    "device_type": "iOS",
    "device_name": "iPhone 13",
    "last_used": "2024-01-20T10:30:00Z"
  }
]
```

---

### GET `/api/v1/fcm-tokens/user/:userId`

**Description**: Get user's FCM tokens  
**Authentication**: JWT Bearer Token (owner/admin)  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
[
  {
    "token": "fcm_token_here",
    "device_type": "iOS",
    "device_name": "iPhone 13",
    "last_used": "2024-01-20T10:30:00Z"
  }
]
```

---

## 🚨 Emergency Contacts

### GET `/api/v1/users/:userId/emergency-contacts`

**Description**: List user's emergency contacts  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
[
  {
    "contact_id": 1,
    "name": "María García",
    "relationship": "Madre",
    "phone": "+52 555 1234567",
    "email": "maria.garcia@example.com",
    "is_primary": true
  }
]
```

---

### POST `/api/v1/users/:userId/emergency-contacts`

**Description**: Create emergency contact (max 5)  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Request Body**:

```json
{
  "name": "María García",
  "relationship": "Madre",
  "phone": "+52 555 1234567",
  "email": "maria.garcia@example.com",
  "is_primary": true
}
```

**Response** (201):

```json
{
  "contact_id": 1,
  "message": "Contacto creado exitosamente"
}
```

---

### GET `/api/v1/users/:userId/emergency-contacts/:contactId`

**Description**: Get emergency contact details  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `contactId` (number): Contact ID

**Response** (200):

```json
{
  "contact_id": 1,
  "name": "María García",
  "relationship": "Madre",
  "phone": "+52 555 1234567",
  "email": "maria.garcia@example.com",
  "is_primary": true
}
```

---

### PATCH `/api/v1/users/:userId/emergency-contacts/:contactId`

**Description**: Update emergency contact  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `contactId` (number): Contact ID

**Request Body** (all fields optional):

```json
{
  "name": "María García López",
  "phone": "+52 555 9876543",
  "email": "maria.lopez@example.com",
  "is_primary": false
}
```

**Response** (200):

```json
{
  "message": "Contacto actualizado",
  "contact": {
    /* updated contact */
  }
}
```

---

### DELETE `/api/v1/users/:userId/emergency-contacts/:contactId`

**Description**: Remove emergency contact (soft delete)  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID
- `contactId` (number): Contact ID

**Response** (200):

```json
{
  "message": "Contacto eliminado"
}
```

---

## 👨‍👩‍👧 Legal Representatives

### GET `/api/v1/users/:userId/legal-representative`

**Description**: Get user's legal representative  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "representative_id": 1,
  "name": "Carlos García",
  "relationship": "Padre",
  "phone": "+52 555 1234567",
  "email": "carlos.garcia@example.com",
  "id_document": "RFC123456789",
  "address": "Calle Principal 123"
}
```

---

### POST `/api/v1/users/:userId/legal-representative`

**Description**: Register legal representative (only for users under 18)  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Request Body**:

```json
{
  "name": "Carlos García",
  "relationship": "Padre",
  "phone": "+52 555 1234567",
  "email": "carlos.garcia@example.com",
  "id_document": "RFC123456789",
  "address": "Calle Principal 123"
}
```

**Response** (201):

```json
{
  "representative_id": 1,
  "message": "Representante registrado exitosamente"
}
```

---

### PATCH `/api/v1/users/:userId/legal-representative`

**Description**: Update legal representative  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Request Body** (all fields optional):

```json
{
  "name": "Carlos García López",
  "phone": "+52 555 9876543",
  "email": "carlos.lopez@example.com"
}
```

**Response** (200):

```json
{
  "message": "Representante actualizado",
  "representative": {
    /* updated representative */
  }
}
```

---

### DELETE `/api/v1/users/:userId/legal-representative`

**Description**: Remove legal representative  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "message": "Representante eliminado"
}
```

---

## 📝 Post-Registration

The post-registration flow has 3 steps that must be completed in order after initial user registration.

### GET `/api/v1/users/:userId/post-registration/status`

**Description**: Get post-registration status  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "step_1_completed": true,
  "step_2_completed": false,
  "step_3_completed": false,
  "post_registration_completed": false,
  "current_step": 2
}
```

---

### POST `/api/v1/users/:userId/post-registration/step-1/complete`

**Description**: Complete Step 1 - Profile Picture  
**Validation**: User must have uploaded a profile picture  
**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "message": "Paso 1 completado",
  "step_1_completed": true,
  "next_step": 2
}
```

**Error** (400):

```json
{
  "statusCode": 400,
  "message": "Usuario no tiene foto de perfil"
}
```

---

### POST `/api/v1/users/:userId/post-registration/step-2/complete`

**Description**: Complete Step 2 - Personal Information  
**Validation**: Requires:

- Gender
- Birthday
- Baptism status
- At least 1 emergency contact
- Legal representative (if user is under 18)

**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Response** (200):

```json
{
  "message": "Paso 2 completado",
  "step_2_completed": true,
  "next_step": 3
}
```

**Error** (400):

```json
{
  "statusCode": 400,
  "message": "Faltan datos requeridos: género, cumpleaños"
}
```

---

### POST `/api/v1/users/:userId/post-registration/step-3/complete`

**Description**: Complete Step 3 - Club Selection  
**Transaction**: This endpoint performs multiple operations:

1. Updates user's country/union/field
2. Assigns "member" role to user in selected club
3. Enrolls user in appropriate class for their age
4. Marks post-registration as completed

**Authentication**: JWT Bearer Token  
**URL Parameters**:

- `userId` (string, UUID): User ID

**Request Body**:

```json
{
  "club_id": 1,
  "instance_type": "pathfinders",
  "instance_id": 1
}
```

**Response** (200):

```json
{
  "message": "POST-REGISTRO COMPLETO ✅",
  "user": {
    "post_registration_completed": true,
    "country_id": 1,
    "union_id": 1,
    "local_field_id": 1
  },
  "club_assignment": {
    "club_id": 1,
    "club_name": "Club Central",
    "role": "member"
  },
  "class_enrollment": {
    "class_id": 1,
    "class_name": "Amigo"
  }
}
```

**Error** (400):

```json
{
  "statusCode": 400,
  "message": "Club no encontrado o inactivo"
}
```

---

## 📊 Pagination

Endpoints that support pagination use the following query parameters:

- `page` (number, optional, default: 1): Page number (1-indexed)
- `limit` (number, optional, default: 10, max: 100): Items per page

**Pagination Response Format**:

```json
{
  "data": [
    /* array of items */
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

## 🔒 Authentication

Most endpoints require authentication using JWT Bearer tokens.

**Header Format**:

```
Authorization: Bearer eyJhbGc...
```

**Token Acquisition**:

1. Login via `POST /api/v1/auth/login`
2. Receive `access_token` and `refresh_token`
3. Use `access_token` in Authorization header
4. Refresh token via `POST /api/v1/auth/refresh` when expired

**Token Expiration**:

- Access Token: 1 hour
- Refresh Token: 7 days

---

## ⚠️ Error Responses

All endpoints follow a standard error response format:

```json
{
  "statusCode": 400,
  "message": "Error description",
  "error": "Bad Request"
}
```

**Common HTTP Status Codes**:

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `500` - Internal Server Error

---

## 📝 Data Types

### Blood Types

```typescript
enum blood_type {
  A_POSITIVE
  A_NEGATIVE
  B_POSITIVE
  B_NEGATIVE
  AB_POSITIVE
  AB_NEGATIVE
  O_POSITIVE
  O_NEGATIVE
}
```

### Club Types

- `1` - Aventureros (6-9 years)
- `2` - Conquistadores (10-15 years)
- `3` - Guías Mayores (16+ years)

### Instance Types

- `adventurers` - Aventureros instance
- `pathfinders` - Conquistadores instance
- `master_guilds` - Guías Mayores instance

### Skill Levels (Honors)

- `1` - Básico
- `2` - Avanzado
- `3` - Máster

### Financial Types

- `0` - Income (Ingresos)
- `1` - Expenses (Egresos)

---


## 🧭 Admin Users (Scope-Based Access)

> **Prefix**: `/api/v1/admin`  
> **Authentication**: JWT Bearer Token  
> **Guard**: `GlobalRolesGuard` — requiere rol global

### GET `/api/v1/admin/users`

**Description**: List administrative users with scope enforcement by actor role  
**Roles required**: `super_admin`, `admin`, `coordinator`

**Query Params** (optional):

- `search` (string): Full-text search by name/email
- `role` (string): Filter by global role
- `active` (boolean): Filter active/inactive users
- `unionId` (number): Union filter (applies inside actor scope)
- `localFieldId` (number): Local field filter (applies inside actor scope)
- `page` (number, default `1`)
- `limit` (number, default `20`)

**Scope behavior**:

- `super_admin` → **ALL**
- `admin` → **UNION** when `union_id` exists; otherwise **LOCAL_FIELD** when `local_field_id` exists
- `coordinator` → **LOCAL_FIELD** (requires `local_field_id`)

**Response** (200):

```json
{
  "status": "success",
  "data": {
    "items": [],
    "meta": {
      "page": 1,
      "limit": 20,
      "total": 0,
      "totalPages": 0,
      "scope": {
        "type": "UNION",
        "unionId": 7,
        "localFieldId": null
      }
    }
  }
}
```

**Error cases**:

- `403 Forbidden` when actor role exists but has no valid scope configuration

---

### GET `/api/v1/admin/users/:userId`

**Description**: Get user detail only if target is inside actor scope  
**Roles required**: `super_admin`, `admin`, `coordinator`

**Path Params**:

- `userId` (string, UUID): Target user ID

**Response** (200):

```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "email": "user@example.com",
    "name": "Juan",
    "union_id": 7,
    "local_field_id": 11,
    "global_roles": ["member"],
    "profile": {
      "complete": true
    }
  }
}
```

**Error cases**:

- `404 Not Found` when target user is outside actor scope

---

## � RBAC (Roles & Permissions)

> **Prefix**: `/api/v1/admin/rbac`  
> **Authentication**: JWT Bearer Token  
> **Guard**: `GlobalRolesGuard` — requiere roles globales específicos

### GET `/api/v1/admin/rbac/permissions`

**Description**: Listar todos los permisos del sistema  
**Roles requeridos**: `super_admin`, `admin`

**Response** (200):

```json
{
  "status": "success",
  "data": [
    {
      "permission_id": "uuid",
      "permission_name": "users:read",
      "description": "Ver listado de usuarios",
      "active": true,
      "created_at": "2026-02-09T00:00:00Z",
      "modified_at": "2026-02-09T00:00:00Z"
    }
  ]
}
```

---

### GET `/api/v1/admin/rbac/permissions/:id`

**Description**: Obtener un permiso por ID  
**Roles requeridos**: `super_admin`, `admin`

**Response** (200): Objeto permiso individual

---

### POST `/api/v1/admin/rbac/permissions`

**Description**: Crear un nuevo permiso  
**Roles requeridos**: `super_admin`

**Request Body**:

```json
{
  "permission_name": "users:read",
  "description": "Ver listado de usuarios"
}
```

**Validación**:
- `permission_name`: obligatorio, formato `resource:action` (regex: `/^[a-z_]+:[a-z_]+$/`), max 255 chars, único
- `description`: opcional

**Response** (201): Objeto permiso creado

---

### PATCH `/api/v1/admin/rbac/permissions/:id`

**Description**: Actualizar un permiso  
**Roles requeridos**: `super_admin`

**Request Body** (todos opcionales):

```json
{
  "permission_name": "users:read_detail",
  "description": "Ver detalle de un usuario",
  "active": true
}
```

---

### DELETE `/api/v1/admin/rbac/permissions/:id`

**Description**: Desactivar un permiso (soft delete)  
**Roles requeridos**: `super_admin`

**Response** (200):

```json
{
  "success": true,
  "message": "Permiso desactivado"
}
```

---

### GET `/api/v1/admin/rbac/roles`

**Description**: Listar todos los roles activos con sus permisos asignados  
**Roles requeridos**: `super_admin`, `admin`

**Response** (200):

```json
{
  "status": "success",
  "data": [
    {
      "role_id": "uuid",
      "role_name": "admin",
      "role_category": "GLOBAL",
      "description": "Administrador del sistema",
      "active": true,
      "role_permissions": [
        {
          "role_permission_id": "uuid",
          "role_id": "uuid",
          "permission_id": "uuid",
          "active": true,
          "permissions": {
            "permission_id": "uuid",
            "permission_name": "users:read",
            "description": "Ver listado de usuarios"
          }
        }
      ]
    }
  ]
}
```

---

### GET `/api/v1/admin/rbac/roles/:id`

**Description**: Obtener un rol con sus permisos  
**Roles requeridos**: `super_admin`, `admin`

---

### PUT `/api/v1/admin/rbac/roles/:id/permissions`

**Description**: Sincronizar permisos de un rol (reemplaza la lista completa)  
**Roles requeridos**: `super_admin`

**Request Body**:

```json
{
  "permission_ids": ["uuid-1", "uuid-2", "uuid-3"]
}
```

**Comportamiento**:
- Permisos que estaban activos pero no están en la lista → se desactivan
- Permisos nuevos en la lista → se crean o reactivan
- Operación atómica de sincronización

**Response** (200):

```json
{
  "success": true,
  "added": 3,
  "removed": 1
}
```

---

### DELETE `/api/v1/admin/rbac/roles/:id/permissions/:permissionId`

**Description**: Remover un permiso específico de un rol  
**Roles requeridos**: `super_admin`

**Response** (200):

```json
{
  "success": true,
  "message": "Permiso removido del rol"
}
```

---

## � Common Patterns

### UUID Format

All user IDs use UUID v4 format:

```
xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx
```

### Date Format

Dates use ISO 8601 format:

```
YYYY-MM-DD (for dates)
YYYY-MM-DDTHH:mm:ssZ (for timestamps)
```

### Role-Based Access

Some endpoints require specific club roles:

- `director` - Full club permissions
- `subdirector` - Most administrative permissions
- `secretary` - Can add members, create activities
- `counselor` - Can create activities
- `treasurer` - Can manage finances
- `member` - Basic member access

---

**Last Updated**: 2026-02-18  
**API Version**: v1
