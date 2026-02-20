<!-- CANONICAL-API-NOTE -->
> [!WARNING]
> Este documento puede incluir rutas históricas/propuestas o ejemplos desactualizados.
> Para consumo de agentes (App + Panel), usar como contrato canónico:
> [ENDPOINTS-LIVE-REFERENCE.md](./ENDPOINTS-LIVE-REFERENCE.md)

# 📚 Referencia de API - SACDIA

Este documento detalla los endpoints disponibles en la API REST, organizados por módulo.

> [!IMPORTANT]
> **Base URL**: Todos los endpoints usan el prefijo `/api/v1`  
> Ejemplo: `GET /api/v1/auth/me` (no `/auth/me`)

## 🔑 Autenticación y Seguridad

Todas las peticiones protegidas requieren el header:
`Authorization: Bearer <TOKEN_DE_SUPABASE>`

**Códigos de Estado Comunes:**

- `200 OK`: Éxito
- `201 Created`: Recurso creado
- `400 Bad Request`: Error de validación o datos faltantes
- `401 Unauthorized`: Token inválido o faltante
- `403 Forbidden`: Token válido pero sin permisos (Roles)
- `404 Not Found`: Recurso no encontrado

---

## 🛡️ Auth Module

### Login

`POST /auth/login`

- **Auth**: Pública
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "Password123!"
  }
  ```
- **Respuesta**: Token de acceso y refresh token.

### Registro

`POST /auth/register`

- **Auth**: Pública
- **Body**:
  ```json
  {
    "name": "Juan",
    "paternal_last_name": "Pérez",
    "maternal_last_name": "López",
    "email": "juan.perez@example.com",
    "password": "Password123!"
  }
  ```

### Perfil Actual

`GET /auth/me`

- **Auth**: Requiere Token
- **Descripción**: Obtiene los datos del usuario logueado y sus roles.

### Request Password Reset

`POST /auth/password/reset-request`

- **Body**:
  ```json
  { "email": "user@example.com" }
  ```

---

## 👤 Users Module

### Get User Profile

`GET /users/:userId`

- **Auth**: Dueño o Admin
- **Descripción**: Obtiene perfil completo.

### Update User

`PATCH /users/:userId`

- **Body** (Parcial):
  ```json
  {
    "gender": "M",
    "birthday": "2000-01-01",
    "phone": "+525512345678"
  }
  ```

### Upload Profile Picture

`POST /users/:userId/profile-picture`

- **Form-Data**:
  - `file`: (Archivo de imagen)

### Post-Registration Status

`GET /users/:userId/post-registration/status`

- **Descripción**: Verifica qué pasos del onboarding faltan.

---

## 📚 Catalogs Module

### Paginación

La mayoría de estos endpoints soportan `?page=1&limit=20`.

### Get Countries

`GET /catalogs/countries`

### Get Unions

`GET /catalogs/unions`

- **Params**: `?country_id=1`

### Get Local Fields (Campos)

`GET /catalogs/local-fields`

- **Params**: `?union_id=1`

### Get Club Types

`GET /catalogs/club-types`

- **Descripción**: Devuelve IDs para Aventureros, Conquistadores, Guías Mayores.

---

## ⛺ Clubs Module

### Get All Clubs

`GET /clubs`

- **Params**: `?page=1&limit=10&search=Orion`

### Get Club Details

`GET /clubs/:clubId`

### Create Club

`POST /clubs`

- **Auth**: Admin/Coordinador
- **Body**:
  ```json
  {
    "name": "Club Orion",
    "local_field_id": 1,
    "districlub_type_id": 1,
    "church_id": 1,
    "address": "Calle...",
    "coordinates": { "lat": 19.432, "lng": -99.133 }
  }
  ```

### Get Club Instances

`GET /clubs/:clubId/instances`

- **Descripción**: Devuelve las instancias activas (ej. Club de Conquistadores y Club de Aventureros de la misma iglesia).

---

## 🎓 Classes Module

### Get Available Classes

`GET /classes`

- **Descripción**: Lista clases progresivas (Abeja Laboriosa, Amigo, etc.).

### Enroll User in Class

`POST /users/:userId/classes/enroll`

- **Body**:
  ```json
  {
    "class_id": 1,
    "ecclesiastical_year_id": 2026
  }
  ```

### Update Progress

`PATCH /users/:userId/classes/:classId/progress`

- **Body**:
  ```json
  {
    "module_id": 10,
    "section_id": 5,
    "score": 100,
    "evidences": { "url": "..." }
  }
  ```

---

## 🏅 Honors Module

### Get Honors List

`GET /honors`

- **Params**: `?search=Nudos&category_id=2`

### Get User Honors

`GET /users/:userId/honors`

- **Descripción**: Honores ganados por el usuario.

### Register Honor for User

`POST /users/:userId/honors/:honorId`

- **Body**:
  ```json
  {
    "date": "2026-02-01"
  }
  ```

---

## 🎭 Activities Module

### Get Club Activities

`GET /clubs/:clubId/activities`

### Create Activity

`POST /clubs/:clubId/activities`

- **Body**:
  ```json
  {
    "title": "Campamento de Verano",
    "description": "...",
    "date_start": "2026-07-15T08:00:00Z",
    "date_end": "2026-07-20T12:00:00Z",
    "location": "Bosque...",
    "type": "camp",
    "price": 500
  }
  ```

### Register Attendance

`POST /activities/:activityId/attendance`

- **Body**:
  ```json
  {
    "user_ids": ["uuid-1", "uuid-2"],
    "status": "present"
  }
  ```

---

## 💰 Finances Module

### Get Club Finances

`GET /clubs/:clubId/finances`

- **Params**: `?type=income` (o `expense`)

### Create Transaction

`POST /clubs/:clubId/finances`

- **Body**:
  ```json
  {
    "amount": 150.0,
    "type": "income",
    "category_id": 3,
    "description": "Cuota mensual - Juan Perez",
    "date": "2026-02-03"
  }
  ```

### Finance Summary

`GET /clubs/:clubId/finances/summary`

- **Descripción**: Balance total, ingresos vs egresos.

---

## 🆘 Emergency Contacts

### Add Contact

`POST /users/:userId/emergency-contacts`

- **Body**:
  ```json
  {
    "name": "María López",
    "phone": "+52...",
    "relationship_type": 1,
    "primary": true
  }
  ```

---

## 🧭 Admin Users (Scope por Rol)

### List Admin Users

`GET /admin/users`

- **Auth**: JWT
- **Roles**: `super_admin`, `admin`, `coordinator`
- **Query**: `search`, `role`, `active`, `unionId`, `localFieldId`, `page`, `limit`
- **Alcance de datos**:
  - `super_admin` → **ALL**
  - `admin` → **UNION** (si tiene `union_id`); si no, **LOCAL_FIELD** (si tiene `local_field_id`)
  - `coordinator` → **LOCAL_FIELD** (requiere `local_field_id`)
- **Errores esperados**: `403` si el rol está mal configurado para su scope

### Get Admin User Detail

`GET /admin/users/:userId`

- **Auth**: JWT
- **Roles**: `super_admin`, `admin`, `coordinator`
- **Descripción**: Retorna detalle de usuario sólo si pertenece al alcance del actor
- **Errores esperados**: `404` si el usuario objetivo está fuera de scope

