# Relaciones entre Modelos - SACDIA API

> **Generado automáticamente desde el schema Prisma existente**

---

## Diagrama de Relaciones Principales

```
countries
    └── unions
        └── local_fields
            └── districts
                └── churches
                    └── clubs
                        ├── club_adventurers
                        ├── club_pathfinders
                        └── club_master_guild
                            └── club_role_assignments
                                └── users

users
    ├── users_roles → roles
    ├── users_permissions → permissions
    ├── users_allergies → allergies
    ├── users_diseases → diseases
    ├── users_honors → honors
    ├── users_classes → classes
    ├── emergency_contacts
    ├── enrollments → classes
    └── unit_members → units

roles
    └── role_permissions → permissions

honors
    ├── honors_categories
    └── master_honors

classes
    ├── class_modules
    │   └── class_sections
    └── club_types
```

---

## Relaciones Geográficas/Organizacionales

### countries → unions
**Tipo:** One-to-Many

**Descripción:** Un país tiene múltiples uniones

**Campos de relación:**
- En `unions`: `country_id` (foreign key)
- En `countries`: `unions[]` (relación inversa)

**Ejemplo de respuesta con relación:**
```json
{
  "country_id": 1,
  "name": "México",
  "abbreviation": "MX",
  "unions": [
    {
      "union_id": 1,
      "name": "Unión Mexicana del Norte",
      "abbreviation": "UMN"
    }
  ]
}
```

---

### unions → local_fields
**Tipo:** One-to-Many

**Descripción:** Una unión tiene múltiples campos locales

**Campos de relación:**
- En `local_fields`: `union_id` (foreign key)
- En `unions`: `local_fields[]` (relación inversa)

---

### local_fields → districts
**Tipo:** One-to-Many

**Descripción:** Un campo local tiene múltiples distritos

**Campos de relación:**
- En `districts`: `local_field_id` (foreign key)
- En `local_fields`: `districts[]` (relación inversa)

**Endpoint con relación:** `GET /c/districts/by-local-field/:localFieldId`

---

### districts → churches
**Tipo:** One-to-Many

**Descripción:** Un distrito tiene múltiples iglesias

**Campos de relación:**
- En `churches`: `district_id` (foreign key)
- En `districts`: `churches[]` (relación inversa)

---

### churches → clubs
**Tipo:** One-to-Many

**Descripción:** Una iglesia tiene múltiples clubes

**Campos de relación:**
- En `clubs`: `church_id` (foreign key)
- En `churches`: `clubs[]` (relación inversa)

**Endpoint con relación:** `GET /clubs/by-church/:churchId`

---

## Relaciones de Clubs

### clubs → club_adventurers
**Tipo:** One-to-Many

**Descripción:** Un club principal puede tener múltiples instancias de Aventureros

**Campos de relación:**
- En `club_adventurers`: `main_club_id` (foreign key)
- En `clubs`: `club_adventurers[]` (relación inversa)

**Endpoint:** `POST /clubs/:mainClubId/adventurers`

---

### clubs → club_pathfinders
**Tipo:** One-to-Many

**Descripción:** Un club principal puede tener múltiples instancias de Conquistadores

**Campos de relación:**
- En `club_pathfinders`: `main_club_id` (foreign key)
- En `clubs`: `club_pathfinders[]` (relación inversa)

**Endpoint:** `POST /clubs/:mainClubId/pathfinders`

---

### clubs → club_master_guild
**Tipo:** One-to-Many

**Descripción:** Un club principal puede tener múltiples instancias de Guías Mayores

**Campos de relación:**
- En `club_master_guild`: `main_club_id` (foreign key)
- En `clubs`: `club_master_guild[]` (relación inversa)

**Endpoint:** `POST /clubs/:mainClubId/master-guides`

---

### club_types → club_adventurers/club_pathfinders/club_master_guild
**Tipo:** One-to-Many

**Descripción:** Un tipo de club define el tipo de cada instancia

**Campos de relación:**
- En instancias: `club_type_id` (foreign key)
- En `club_types`: `club_adventurers[]`, `club_pathfinders[]`, `club_master_guild[]`

---

## Relaciones de Usuarios

### users → users_roles → roles
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Un usuario puede tener múltiples roles y un rol puede estar asignado a múltiples usuarios

**Campos de relación:**
- En `users_roles`: `user_id`, `role_id` (foreign keys)
- Constraint único: `[user_id, role_id]`

**Endpoints:**
- `GET /c/users-roles/by-user/:userId`
- `GET /c/users-roles/by-role/:roleId`
- `POST /c/users-roles/assign-roles`

---

### users → users_permissions → permissions
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Un usuario puede tener permisos directos adicionales a los de sus roles

**Campos de relación:**
- En `users_permissions`: `user_id`, `permission_id` (foreign keys)
- Constraint único: `[user_id, permission_id]`

---

### roles → role_permissions → permissions
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Un rol tiene múltiples permisos y un permiso puede estar en múltiples roles

**Campos de relación:**
- En `role_permissions`: `role_id`, `permission_id` (foreign keys)
- Constraint único: `[role_id, permission_id]`

**Endpoints:**
- `GET /c/role-permissions/by-role/:roleId`
- `POST /c/role-permissions/assign-permissions`

---

### users → users_allergies → allergies
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Un usuario puede tener múltiples alergias

**Campos de relación:**
- En `users_allergies`: `user_id`, `allergy_id` (foreign keys)
- Constraint único: `[user_id, allergy_id]`

**Endpoints:**
- `GET /users/allergies/by-user/:userId`
- `POST /users/allergies/assign-allergies`

---

### users → users_diseases → diseases
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Un usuario puede tener múltiples enfermedades registradas

**Campos de relación:**
- En `users_diseases`: `user_id`, `disease_id` (foreign keys)
- Constraint único: `[user_id, disease_id]`

**Endpoints:**
- `GET /users/diseases/by-user/:userId`
- `POST /users/diseases/assign-diseases`

---

### users → users_honors → honors
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Un usuario puede tener múltiples especialidades completadas

**Campos de relación:**
- En `users_honors`: `user_id`, `honor_id` (foreign keys)
- Campos adicionales: `certificate`, `images`, `document`, `date`, `validate`

**Endpoints:**
- `GET /users/users-honors`
- `GET /users/users-honors/:userId/by-category`

---

### users → users_classes → classes
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Un usuario puede estar inscrito en múltiples clases

**Campos de relación:**
- En `users_classes`: `user_id`, `class_id` (foreign keys)
- Constraint único: `[user_id, class_id]`
- Campos adicionales: `investiture`, `date_investiture`, `advanced`, `current_class`, `certificate`

**Endpoints:**
- `GET /users/users-classes/by-user/:userId`
- `GET /users/users-classes/by-class/:classId`

---

### users → emergency_contacts
**Tipo:** One-to-Many (dos relaciones)

**Descripción:** Un usuario puede tener múltiples contactos de emergencia

**Relaciones:**
1. `owner` → `users`: El usuario dueño de los contactos
2. `contact_user` → `users`: Referencia opcional a otro usuario registrado

**Campos de relación:**
- `owner_id`: ID del usuario dueño
- `contact_user_id`: ID opcional del contacto si es usuario registrado

**Endpoint:** `GET /users/emergency-contacts/all?userId={uuid}`

---

### users → enrollments → classes
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Inscripciones de usuarios a clases (diferente de users_classes)

**Campos de relación:**
- En `enrollments`: `user_id`, `class_id` (foreign keys)
- Constraint único: `[user_id, class_id]`
- Campos adicionales: `enrollment_date`, `investiture_status`, `advanced_status`

---

## Relaciones de Clubes y Miembros

### club_role_assignments
**Tipo:** Many-to-Many (compleja)

**Descripción:** Asignación de roles a usuarios dentro de instancias de club específicas

**Campos de relación:**
- `user_id`: Usuario asignado
- `role_id`: Rol asignado
- `club_adv_id`: Instancia de Aventureros (opcional)
- `club_pathf_id`: Instancia de Conquistadores (opcional)
- `club_mg_id`: Instancia de Guías Mayores (opcional)
- `ecclesiastical_year_id`: Año eclesiástico
- `start_date`, `end_date`: Período de la asignación

**Constraint único:** `[user_id, role_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id, start_date]`

**Endpoints:**
- `POST /clubs/assign-role`
- `POST /clubs/assign-member`
- `GET /clubs/club-role-assignments`

---

### units → unit_members → users
**Tipo:** Many-to-Many (a través de tabla pivote)

**Descripción:** Unidades (grupos pequeños dentro del club) con sus miembros

**Campos de relación:**
- En `unit_members`: `unit_id`, `user_id` (foreign keys)
- Constraint único: `user_id` (un usuario solo puede estar en una unidad)

**Relaciones adicionales en units:**
- `captain_id` → Usuario capitán
- `secretary_id` → Usuario secretario
- `advisor_id` → Usuario consejero
- `substitute_advisor_id` → Usuario consejero suplente

---

## Relaciones de Especialidades

### honors → honors_categories
**Tipo:** Many-to-One

**Descripción:** Cada especialidad pertenece a una categoría

**Campos de relación:**
- En `honors`: `honors_category_id` (foreign key)
- En `honors_categories`: `honors[]` (relación inversa)

**Endpoint:** `GET /c/honors/by-category`

---

### honors → master_honors
**Tipo:** Many-to-One (opcional)

**Descripción:** Algunas especialidades pueden pertenecer a una maestría

**Campos de relación:**
- En `honors`: `master_honors_id` (foreign key, nullable)
- En `master_honors`: `honors[]` (relación inversa)

---

### honors → club_types
**Tipo:** Many-to-One

**Descripción:** Cada especialidad está asociada a un tipo de club

**Campos de relación:**
- En `honors`: `club_type_id` (foreign key)
- En `club_types`: `honors[]` (relación inversa)

---

## Relaciones de Clases

### classes → club_types
**Tipo:** Many-to-One

**Descripción:** Cada clase pertenece a un tipo de club

**Campos de relación:**
- En `classes`: `club_type_id` (foreign key)
- En `club_types`: `classes[]` (relación inversa)

---

### classes → class_modules
**Tipo:** One-to-Many

**Descripción:** Una clase tiene múltiples módulos

**Campos de relación:**
- En `class_modules`: `class_id` (foreign key)
- En `classes`: `class_modules[]` (relación inversa)

---

### class_modules → class_sections
**Tipo:** One-to-Many

**Descripción:** Un módulo tiene múltiples secciones

**Campos de relación:**
- En `class_sections`: `module_id` (foreign key)
- En `class_modules`: `class_sections[]` (relación inversa)

---

## Relaciones de Progreso

### users → class_module_progress → classes
**Tipo:** Registro de progreso

**Descripción:** Progreso de un usuario en los módulos de una clase

**Campos:**
- `user_id`, `class_id`, `module_id`, `score`
- Constraint único: `[user_id, class_id, module_id]`

---

### users → class_section_progress → classes
**Tipo:** Registro de progreso

**Descripción:** Progreso de un usuario en las secciones de una clase

**Campos:**
- `user_id`, `class_id`, `module_id`, `section_id`, `score`, `evidences`
- Constraint único: `[user_id, class_id, module_id, section_id]`

---

## Relaciones de Camporees

### local_camporees → local_fields
**Tipo:** Many-to-One

**Descripción:** Camporees locales organizados por un campo local

---

### local_camporees → attending_clubs_camporees
**Tipo:** One-to-Many

**Descripción:** Clubes asistentes a un camporee local

---

### local_camporees → attending_members_camporees → users
**Tipo:** Registro de asistencia

**Descripción:** Miembros individuales asistentes a un camporee

---

### union_camporees → union_camporee_local_fields → local_fields
**Tipo:** Many-to-Many

**Descripción:** Campos locales participantes en un camporee de unión

---

## Relaciones de Finanzas

### finances → club_adventurers/club_pathfinders/club_master_guild
**Tipo:** Many-to-One (polimórfica)

**Descripción:** Registros financieros pueden pertenecer a cualquier instancia de club

**Campos:**
- `club_adv_id`, `club_pathf_id`, `club_mg_id` (solo uno tiene valor)

---

### finances → finances_categories
**Tipo:** Many-to-One

**Descripción:** Cada registro financiero tiene una categoría

---

### finances → users
**Tipo:** Many-to-One

**Descripción:** Cada registro financiero fue creado por un usuario

**Campo:** `created_by`

---

## Relaciones de Carpetas (Folders)

Las carpetas representan el sistema de evaluación/reportes del club.

### folders → folders_modules → folders_sections
**Tipo:** One-to-Many jerárquico

**Descripción:** Estructura jerárquica de carpetas con módulos y secciones

---

### folders → assignments_folders → users
**Tipo:** Asignación

**Descripción:** Asignación de carpetas a usuarios para evaluación

---

### folders_section_records → club instances
**Tipo:** Many-to-One (polimórfica)

**Descripción:** Registros de secciones por instancia de club

**Campos adicionales:** `points`, `pdf_file`, `evidences`
