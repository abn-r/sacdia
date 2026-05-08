# Trazabilidad Backend → Tablas de Base de Datos

**Propósito:** Documento de referencia que mapea cada servicio NestJS del backend SACDIA con las tablas de PostgreSQL (modelos Prisma) que lee o escribe. Permite responder rápidamente "¿quién toca `club_role_assignments`?" o "¿qué tablas modifica el módulo de investidura?".

**Fecha de generación:** 2026-04-14

**Cómo mantenerlo actualizado:**
- Cuando se agrega un nuevo servicio: agregar subsección en Sección B y actualizar Sección C.
- Cuando se agrega un nuevo modelo Prisma: agregar fila en Sección A y verificar si Sección D ya no aplica.
- Referencia de esquema completa: [`docs/database/SCHEMA-REFERENCE.md`](../database/SCHEMA-REFERENCE.md)
- Referencia de endpoints: [`docs/api/ENDPOINTS-LIVE-REFERENCE.md`](../api/ENDPOINTS-LIVE-REFERENCE.md)

---

## Sección A — Referencia de Tablas (Modelos Prisma)

Los modelos sin `@@map` usan el nombre del modelo como nombre físico de tabla.

### Dominio: Auth / Sesiones

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `session` | `sessions` | Auth | Sesiones activas de Better Auth. Vincula `user_id` con un token de sesión con expiración. | `users` |
| `account` | `accounts` | Auth | Cuentas OAuth / credenciales vinculadas a un usuario (Google, Apple, email+password). | `users` |
| `verification` | `verifications` | Auth | Tokens temporales de verificación de email y recuperación de contraseña. | — |

### Dominio: Usuarios

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `users` | `users` | Usuarios | Perfil central de cada persona registrada en SACDIA. Incluye datos personales, estado de aprobación y flags de acceso. | `countries`, `local_fields`, `unions` (y decenas de tablas hijas) |
| `users_pr` | `users_pr` | Usuarios | Estado de completitud del proceso de post-registro (pasos: foto, info personal, selección de club). | `users` |
| `users_allergies` | `users_allergies` | Usuarios | Relación N:M entre usuarios y alergias conocidas. | `users`, `allergies` |
| `users_diseases` | `users_diseases` | Usuarios | Relación N:M entre usuarios y enfermedades registradas. | `users`, `diseases` |
| `users_medicines` | `users_medicines` | Usuarios | Relación N:M entre usuarios y medicamentos en uso. | `users`, `medicines` |
| `emergency_contacts` | `emergency_contacts` | Usuarios | Contactos de emergencia de un miembro; puede ser interno (otro usuario) o externo. | `users`, `relationship_types` |
| `legal_representatives` | `legal_representatives` | Usuarios | Representante legal de un miembro menor de edad (puede ser otro usuario registrado). | `users`, `relationship_types` |

### Dominio: Catálogos / Datos de referencia

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `allergies` | `allergies` | Catálogos | Catálogo de alergias disponibles para asignar a usuarios. | `users_allergies` |
| `diseases` | `diseases` | Catálogos | Catálogo de enfermedades disponibles. | `users_diseases` |
| `medicines` | `medicines` | Catálogos | Catálogo de medicamentos disponibles. | `users_medicines` |
| `relationship_types` | `relationship_types` | Catálogos | Tipos de relación (padre, madre, tutor, etc.) para contactos de emergencia y representantes legales. | `emergency_contacts`, `legal_representatives` |
| `club_types` | `club_types` | Catálogos | Tipos de club (Conquistadores, Aventureros, Guías Mayores). Pivote central de casi todos los módulos. | Decenas de tablas |
| `activity_types` | `activity_types` | Catálogos | Tipos de actividad (campamento, reunión, culto, etc.). | `activities` |
| `club_ideals` | `club_ideals` | Catálogos | Ideales de club por tipo; texto para mostrar en UI. | `club_types` |
| `system_config` | `system_config` | Catálogos | Parámetros de configuración global del sistema en forma clave-valor (ej: deadlines de membresía). | — |

### Dominio: Geografía

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `countries` | `countries` | Geografía | Países disponibles en SACDIA. | `unions`, `users` |
| `unions` | `unions` | Geografía | Uniones eclesiásticas, agrupan campos locales dentro de un país. | `local_fields`, `countries` |
| `local_fields` | `local_fields` | Geografía | Campos locales (nivel más granular de la jerarquía eclesiástica). | `unions`, `districts`, `clubs` |
| `districts` | `districts` | Geografía | Distritos dentro de un campo local; contienen iglesias. | `local_fields`, `churches` |
| `churches` | `churches` | Geografía | Iglesias locales vinculadas a distritos y clubs. | `districts`, `clubs` |

### Dominio: Clubs

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `clubs` | `clubs` | Clubs | Club físico (ej: "Club Conquistadores Central"). Puede tener varias secciones. | `churches`, `local_fields`, `districts` |
| `club_sections` | `club_sections` | Clubs | Instancia de un tipo de club dentro de un club físico (ej: sección Aventureros del Club Central). Nodo central de la mayoría de operaciones. | `clubs`, `club_types` |
| `club_enrollments` | `club_enrollments` | Clubs | Matrícula anual del club para un año eclesiástico. Habilita carpetas anuales y reportes. | `club_sections`, `ecclesiastical_years` |
| `club_role_assignments` | `club_role_assignments` | Clubs | Asignaciones de roles a usuarios dentro de una sección para un año eclesiástico (director, secretario, miembro, etc.). | `users`, `roles`, `club_sections`, `ecclesiastical_years` |
| `club_transfer_requests` | `club_transfer_requests` | Clubs | Solicitudes de transferencia de un miembro de una sección a otra. | `users`, `club_sections` |
| `role_assignment_requests` | `role_assignment_requests` | Clubs | Solicitudes de asignación de rol (pendiente de aprobación). | `club_sections`, `users`, `roles` |
| `ecclesiastical_years` | `ecclesiastical_years` | Clubs | Años eclesiásticos (ciclos anuales). Pivote temporal de la mayoría de entidades. | `club_role_assignments`, `enrollments`, `folders`, etc. |

### Dominio: RBAC

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `roles` | `roles` | RBAC | Roles del sistema (GLOBAL o CLUB). | `role_permissions`, `users_roles`, `club_role_assignments` |
| `permissions` | `permissions` | RBAC | Permisos atómicos del sistema. | `role_permissions`, `users_permissions` |
| `role_permissions` | `role_permissions` | RBAC | Relación N:M entre roles y permisos. | `roles`, `permissions` |
| `users_roles` | `users_roles` | RBAC | Roles globales asignados directamente a usuarios (ej: `super_admin`). | `users`, `roles` |
| `users_permissions` | `users_permissions` | RBAC | Permisos directos asignados a usuarios (overrides individuales). | `users`, `permissions` |
| `role_slot_limits` | `role_slot_limits` | RBAC | Límite máximo de usuarios por rol por sección (ej: máx. 1 director). | `roles` |

### Dominio: Clases / Investidura

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `classes` | `classes` | Clases | Clases de inversión disponibles por tipo de club (ej: Conquistador 1er año). | `club_types`, `class_modules` |
| `class_modules` | `class_modules` | Clases | Módulos de una clase. | `classes`, `class_sections` |
| `class_sections` | `class_sections` | Clases | Secciones dentro de un módulo de clase. | `class_modules` |
| `enrollments` | `enrollments` | Clases | Inscripción de un usuario en una clase para un año eclesiástico. Seguimiento de estado de investidura. | `users`, `classes`, `ecclesiastical_years` |
| `class_module_progress` | `class_module_progress` | Clases | Progreso por módulo del usuario en su clase. | `users`, `classes`, `enrollments` |
| `class_section_progress` | `class_section_progress` | Clases | Progreso por sección (nota, evidencias, estado de validación). | `users`, `classes`, `enrollments` |
| `investiture_validation_history` | `investiture_validation_history` | Clases | Historial de acciones de validación de investidura (quién aprobó, rechazó, etc.). | `enrollments`, `users` |
| `investiture_config` | `investiture_config` | Clases | Configuración de fecha límite e investidura por campo local y año eclesiástico. | `local_fields`, `ecclesiastical_years` |

### Dominio: Honores

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `honors` | `honors` | Honores | Catálogo de honores disponibles (con imagen, categoría, nivel de habilidad). | `honors_categories`, `club_types`, `master_honors` |
| `honors_categories` | `honors_categories` | Honores | Categorías de honores (artesanías, deportes, naturaleza, etc.). | `honors` |
| `master_honors` | `master_honors` | Honores | Honores maestros (agrupadores de honores relacionados). | `honors` |
| `users_honors` | `users_honors` | Honores | Honores asignados a un usuario con estado de validación. | `users`, `honors` |
| `honor_requirements` | `honor_requirements` | Honores | Requisitos jerárquicos de un honor (con sub-ítems y grupos de elección). | `honors`, self-ref |
| `user_honor_requirement_progress` | `user_honor_requirement_progress` | Honores | Progreso del usuario en cada requisito de un honor. | `users_honors`, `honor_requirements` |
| `requirement_evidence` | `requirement_evidence` | Honores | Evidencias (imagen, archivo, link) adjuntadas a un progreso de requisito. | `user_honor_requirement_progress` |

### Dominio: Actividades

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `activities` | `activities` | Actividades | Actividades programadas de un club (reuniones, campamentos, cultos). | `club_types`, `activity_types`, `club_sections` |
| `activity_instances` | `activity_instances` | Actividades | Instancias de actividades conjuntas (una por sección participante). | `activities`, `club_sections` |

### Dominio: Carpetas / Evidencias

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `folders` | `folders` | Carpetas | Carpetas de trabajo (tipo Grúa) por tipo de club y año eclesiástico. | `club_types`, `ecclesiastical_years` |
| `folders_modules` | `folders_modules` | Carpetas | Módulos dentro de una carpeta. | `folders` |
| `folders_sections` | `folders_sections` | Carpetas | Secciones dentro de un módulo de carpeta. | `folders_modules` |
| `folder_assignments` | `folder_assignments` | Carpetas | Asignación de una carpeta a un usuario o sección con seguimiento de progreso. | `folders`, `users`, `club_sections` |
| `folders_modules_records` | `folders_modules_records` | Carpetas | Registro de puntos por módulo para una sección. | `folders`, `folders_modules`, `club_sections` |
| `folders_section_records` | `folders_section_records` | Carpetas | Registro por sección con estado de validación, puntos y evidencias. | `folders`, `folders_modules`, `folders_sections`, `club_sections` |
| `evidence_files` | `evidence_files` | Carpetas | Archivos de evidencia adjuntados a registros de sección o progreso de clase o honores. | `folders_section_records`, `class_section_progress`, `users_honors` |

### Dominio: Carpetas Anuales (Annual Folders)

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `folder_templates` | `folder_templates` | Carpetas Anuales | Plantilla de carpeta anual por tipo de club y año eclesiástico. | `club_types`, `ecclesiastical_years` |
| `folder_template_sections` | `folder_template_sections` | Carpetas Anuales | Secciones de una plantilla (con puntaje máximo y mínimo). | `folder_templates` |
| `annual_folders` | `annual_folders` | Carpetas Anuales | Carpeta anual de un club (instancia de una plantilla para una matrícula). | `club_enrollments`, `folder_templates` |
| `annual_folder_evidences` | `annual_folder_evidences` | Carpetas Anuales | Evidencias subidas a una sección de la carpeta anual. | `annual_folders`, `folder_template_sections`, `users` |
| `annual_folder_section_evaluations` | `annual_folder_section_evaluations` | Carpetas Anuales | Evaluación (puntaje) de una sección por un evaluador autorizado. | `annual_folders`, `folder_template_sections`, `users` |
| `annual_folder_section_submissions` | `annual_folder_section_submissions` | Carpetas Anuales | Registro de envío por sección (antes de enviar la carpeta completa). | `annual_folders`, `folder_template_sections`, `users` |
| `award_categories` | `award_categories` | Carpetas Anuales | Categorías de premios (Oro, Plata, etc.) con rangos de puntaje. | `club_types`, `club_annual_rankings` |
| `club_annual_rankings` | `club_annual_rankings` | Carpetas Anuales | Ranking anual de un club por categoría de premio y año eclesiástico. | `club_enrollments`, `award_categories`, `ecclesiastical_years` |

### Dominio: Finances

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `finances` | `finances` | Finanzas | Movimientos financieros (ingresos/egresos) de una sección por mes/año. | `club_sections`, `club_types`, `finances_categories`, `users` |
| `finances_categories` | `finances_categories` | Finanzas | Categorías de movimientos financieros (cuotas, donaciones, gastos, etc.). | `finances` |
| `FinancePeriodClosing` | `finance_period_closings` | Finanzas | Cierre de período financiero mensual para un club (snapshot con totales). | `clubs` |

### Dominio: Camporees

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `local_camporees` | `local_camporees` | Camporees | Camporees organizados a nivel de campo local. | `local_fields`, `ecclesiastical_years` |
| `union_camporees` | `union_camporees` | Camporees | Camporees a nivel de unión (pueden abarcar varios campos). | `unions`, `ecclesiastical_years` |
| `union_camporee_local_fields` | `union_camporee_local_fields` | Camporees | Campos locales participantes en un camporee de unión (tabla join). | `union_camporees`, `local_fields` |
| `camporee_clubs` | `camporee_clubs` | Camporees | Registro de participación de una sección de club en un camporee. | `local_camporees`, `union_camporees`, `club_sections` |
| `camporee_members` | `camporee_members` | Camporees | Registro de participación de un miembro individual en un camporee. | `users`, `local_camporees`, `union_camporees`, `member_insurances` |
| `camporee_payments` | `camporee_payments` | Camporees | Pagos de inscripción registrados para un miembro de camporee. | `camporee_members`, `users` |
| `member_insurances` | `member_insurances` | Camporees | Pólizas de seguro de un miembro (general, camporee, alto riesgo). | `users` |

### Dominio: Notificaciones

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `user_fcm_tokens` | `user_fcm_tokens` | Notificaciones | Tokens FCM de dispositivos de usuarios para push notifications. | `users` |
| `notification_logs` | `notification_logs` | Notificaciones | Log de notificaciones enviadas (con conteos de éxito/fallo). | `users` (sender), `notification_deliveries` |
| `notification_deliveries` | `notification_deliveries` | Notificaciones | Entrega individual de una notificación a un usuario con timestamp de lectura. | `notification_logs`, `users` |
| `notification_preferences` | `notification_preferences` | Notificaciones | Preferencias de notificación del usuario por categoría (opt-in/out). | `users` |

### Dominio: Unidades / Puntuación

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `units` | `units` | Unidades | Unidades (escuadrones) dentro de una sección, con roles de capitán/secretario/asesor. | `club_sections`, `club_types`, `users` (x4) |
| `unit_members` | `unit_members` | Unidades | Membresía de un usuario en una unidad. | `units`, `users` |
| `weekly_records` | `weekly_records` | Unidades | Registro semanal de asistencia, puntualidad y puntos de un miembro. | `users` |
| `weekly_record_scores` | `weekly_record_scores` | Unidades | Detalle de puntaje por categoría para un registro semanal. | `weekly_records`, `scoring_categories` |
| `scoring_categories` | `scoring_categories` | Unidades | Categorías de puntuación (definidas por división/unión/campo local). | `weekly_record_scores` |
| `member_of_month` | `member_of_month` | Unidades | Miembro del mes calculado por sección con total de puntos. | `club_sections`, `users` |

### Dominio: Certifications

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `certifications` | `certifications` | Certificaciones | Certificaciones disponibles (ej: Primeros Auxilios, Guía Mayor). | `certification_modules` |
| `certification_modules` | `certification_modules` | Certificaciones | Módulos de una certificación. | `certifications`, `certification_sections` |
| `certification_sections` | `certification_sections` | Certificaciones | Secciones dentro de un módulo de certificación. | `certification_modules` |
| `users_certifications` | `users_certifications` | Certificaciones | Inscripción de un usuario en una certificación. | `users`, `certifications` |
| `certification_module_progress` | `certification_module_progress` | Certificaciones | Progreso por módulo de certificación. | `users`, `certifications` |
| `certification_section_progress` | `certification_section_progress` | Certificaciones | Progreso por sección de certificación. | `users`, `certifications` |

### Dominio: Reportes Mensuales

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `monthly_reports` | `monthly_reports` | Reportes | Reporte mensual de un club para un año/mes (con snapshot de datos). | `club_enrollments`, `users` (submitter) |
| `monthly_report_manual_data` | `monthly_report_manual_data` | Reportes | Datos manuales complementarios del reporte mensual (reuniones, biblias, etc.). | `monthly_reports` |

### Dominio: Recursos

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `resource_categories` | `resource_categories` | Recursos | Categorías de recursos descargables (manuales, guías, etc.). | `resources` |
| `resources` | `resources` | Recursos | Recursos descargables (archivos en R2 o URLs externas) con scoping por sección/campo/unión. | `resource_categories`, `club_types`, `users` |

### Dominio: Achievements (Logros)

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `achievement_categories` | `achievement_categories` | Logros | Categorías de logros (Participación, Honores, Clases, etc.). | `achievements` |
| `achievements` | `achievements` | Logros | Definición de un logro con criterios JSON, tipo, alcance y tier. | `achievement_categories`, `club_types`, `user_achievements` |
| `user_achievements` | `user_achievements` | Logros | Progreso y estado de un logro para un usuario. | `users`, `achievements`, `ecclesiastical_years` |
| `achievement_event_log` | `achievement_event_log` | Logros | Log de eventos de usuario que disparan evaluación de logros. | `users` |

### Dominio: Auditoría

| Modelo Prisma | Tabla física | Dominio | Propósito | Relaciones clave |
|---|---|---|---|---|
| `validation_logs` | `validation_logs` | Auditoría | Log genérico de acciones de validación (quién validó qué entidad). | `users` (x2) |
| `error_logs` ⚠️ **DEPRECATED** | `error_logs` | Auditoría | **DEPRECADO (2026-04-14)** — Ningún servicio lee/escribe. Candidato a eliminar en próxima migración. | — |
| `inventory_history` | `inventory_history` | Auditoría | Historial de cambios en ítems de inventario. | `club_inventory`, `users` |

---

## Sección B — Servicios → Tablas

### auth

#### `auth/auth.service.ts` (`AuthService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users` (findUnique), `users_pr` (findUnique), `club_role_assignments` (findFirst), `verification` (findFirst) |
| **Writes** | `users_pr` (upsert), `users` (update — email_verified), `verification` (create, delete via $transaction) |
| **Transactions** | `$transaction` en verificación de email (actualiza `users` + elimina `verification`) |

#### `auth/oauth.service.ts` (`OAuthService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users` (findUnique), `users_pr` (findUnique), `account` (findMany x2) |
| **Writes** | `account` (deleteMany) |
| **Transactions** | `$transaction` en desvinculación de cuenta OAuth |

---

### better-auth

#### `better-auth/better-auth.service.ts` (`BetterAuthService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users` (findUnique x4), `account` (findFirst x3), `session` (findFirst), `verification` (findFirst x2) |
| **Writes** | `session` (create, deleteMany), `users` (create), `account` (create, update), `verification` (create, deleteMany x2) |
| **Raw SQL** | `$queryRaw` — consulta de refresh tokens en `accounts` para rotación de tokens OAuth |

---

### users

#### `users/users.service.ts` (`UsersService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users` (findUnique x5), `countries` (findFirst), `unions` (findFirst, findUnique), `local_fields` (findFirst, findUnique), `allergies` (findMany), `diseases` (findMany), `medicines` (findMany), `users_allergies` (findMany), `users_diseases` (findMany), `users_medicines` (findMany) |
| **Writes** | `users` (update x4), `users_allergies` (updateMany), `users_diseases` (updateMany), `users_medicines` (updateMany) |
| **Transactions** | `$transaction` en actualización masiva de alergias/enfermedades/medicamentos (3 transacciones separadas) |

---

### post-registration

#### `post-registration/post-registration.service.ts` (`PostRegistrationService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users_pr` (findUnique), `users` (findUnique x3), `emergency_contacts` (count) |
| **Writes** | `users_pr` (update x2) |
| **Transactions** | `$transaction` en completar paso de información personal |

---

### clubs

#### `clubs/clubs.service.ts` (`ClubsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `clubs` (findMany, findUnique, count), `club_sections` (findMany, findUnique), `club_types` (findUnique), `club_role_assignments` (findMany, count, findFirst x2), `roles` (findUnique x2, findFirst x2, findMany), `ecclesiastical_years` (findFirst), `role_slot_limits` (findUnique) |
| **Writes** | `clubs` (create, update x2), `club_sections` (create, update), `club_role_assignments` (create, update x2) |

---

### club-enrollments

#### `club-enrollments/club-enrollments.service.ts` (`ClubEnrollmentsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_sections` (findUnique), `club_enrollments` (findUnique x3, findMany) |
| **Writes** | `club_enrollments` (create via $transaction, update) |
| **Transactions** | `$transaction` en creación de matrícula (puede crear `annual_folders` simultáneamente) |

---

### rbac

#### `rbac/rbac.service.ts` (`RbacService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `permissions` (findMany, findUnique, findFirst x2), `roles` (findMany, findUnique x2, findFirst), `role_permissions` (findFirst, findMany), `users_permissions` (findMany, findFirst), `users_roles` (findMany, findFirst x2), `users` (findUnique x2) |
| **Writes** | `permissions` (create, update x2), `role_permissions` (create, update, updateMany), `users_permissions` (create, update), `users_roles` (create, update x2) |

---

### catalogs

#### `catalogs/catalogs.service.ts` (`CatalogsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_types` (findMany), `activity_types` (findMany), `relationship_types` (findMany), `countries` (findMany), `unions` (findMany), `local_fields` (findMany), `districts` (findMany), `churches` (findMany), `roles` (findMany), `ecclesiastical_years` (findMany, findFirst), `club_ideals` (findMany), `allergies` (findMany), `diseases` (findMany), `medicines` (findMany) |
| **Writes** | Ninguna — servicio de solo lectura |

#### `catalogs/catalog-cache.service.ts` (`CatalogCacheService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | Ninguna directa — orquesta llamadas a `CatalogsService` |
| **Writes** | Ninguna — gestiona caché Redis |

---

### activities

#### `activities/activities.service.ts` (`ActivitiesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `activities` (findMany, count, findUnique x4), `clubs` (findUnique x3), `club_sections` (findUnique, findMany), `users` (findMany) |
| **Writes** | `activities` (create x2, update x5), `activity_instances` (updateMany x3, upsert) |
| **Transactions** | `$transaction` array para actualizar `activity_instances` + `activities` al mismo tiempo |

#### `activities/activities-reminder.service.ts` (`ActivitiesReminderService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `system_config` (findUnique), `activities` (findMany) |
| **Writes** | `activities` (update — flag `reminder_sent`) |

---

### honors

#### `honors/honors.service.ts` (`HonorsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `honors` (findMany x3, count, findUnique), `honors_categories` (findMany), `users_honors` (findMany x2, findFirst x3, count x5) |
| **Writes** | `users_honors` (update x3, create x3) |
| **Transactions** | `$transaction` en reasignación de honores de usuario |

#### `honors/honor-requirements.service.ts` (`HonorRequirementsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `honors` (findUnique x2), `honor_requirements` (findMany x3, findUnique x2), `users_honors` (findFirst x4), `user_honor_requirement_progress` (findMany), `requirement_evidence` (count x2, findMany, findFirst) |
| **Writes** | `user_honor_requirement_progress` (upsert x3), `requirement_evidence` (create x2, update) |
| **Transactions** | `$transaction` en completado masivo de requisitos de un honor |

---

### admin

#### `admin/admin-users.service.ts` (`AdminUsersService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users` (findMany, count, findFirst, findUnique), `enrollments` (findMany), `ecclesiastical_years` (findFirst) |
| **Writes** | `users` (update x2) |

#### `admin/admin-auth.service.ts` (`AdminAuthService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `session` (findMany, findFirst), `users` (findUnique) |
| **Writes** | `session` (delete, deleteMany), `verification` (deleteMany) |

#### `admin/admin-geography.service.ts` (`AdminGeographyService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `countries` (findMany, findFirst x2, findUnique), `unions` (count, findMany, findFirst x2, findUnique), `local_fields` (count, findMany, findFirst x2, findUnique), `districts` (count, findMany, findFirst, findUnique), `churches` (count, findMany, findFirst, findUnique) |
| **Writes** | `countries` (create, update x2), `unions` (create, update x2), `local_fields` (create, update x2), `districts` (create, update x2), `churches` (create, update x2) |

#### `admin/admin-reference.service.ts` (`AdminReferenceService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `activity_types` (findMany, findUnique, findFirst x2), `relationship_types` (findMany, findUnique, findFirst x2), `allergies` (findMany, findUnique, findFirst x2), `diseases` (findMany, findUnique, findFirst x2), `medicines` (findMany, findUnique, findFirst x2), `ecclesiastical_years` (findMany, findUnique), `club_ideals` (findMany), `honors_categories` (findMany, count, findUniqueOrThrow, findUnique, findFirst), `honors` (count), `club_role_assignments` (count), `legal_representatives` (count), `users_allergies` (count), `users_diseases` (count), `users_medicines` (count) |
| **Writes** | `activity_types` (create, update x2), `relationship_types` (create, update x2), `allergies` (create, update x2), `diseases` (create, update x2), `medicines` (create, update x2), `ecclesiastical_years` (update x2 — activate/deactivate), `honors_categories` (create, update x2) |
| **Transactions** | `$transaction` en creación de año eclesiástico (activa nuevo, desactiva anterior) |

#### `admin/admin-honors.service.ts` (`AdminHonorsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `honors` (findUnique x2), `honor_requirements` (findMany x2, count, findUnique x2) |
| **Writes** | `honor_requirements` (update, updateMany) |
| **Transactions** | `$transaction` en reordenación de requisitos y operaciones en bloque sobre `honor_requirements` |

---

### classes

#### `classes/classes.service.ts` (`ClassesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `enrollments` (findUnique x2, findMany x2), `ecclesiastical_years` (findFirst), `classes` (findMany, count, findUnique), `class_section_progress` (groupBy, findMany x2, findFirst x2), `class_sections` (groupBy, findFirst), `class_modules` (findMany) |
| **Writes** | `class_section_progress` (create, update), `enrollments` (create via $transaction) |
| **Transactions** | `$transaction` en creación de inscripción (puede crear registros de progreso iniciales); `$transaction` en actualización de progreso de sección |

---

### investiture

#### `investiture/investiture.service.ts` (`InvestitureService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `enrollments` (findUnique x3, findFirst x4, findMany x4), `club_role_assignments` (findFirst x2), `investiture_validation_history` (findFirst, findMany), `users` (findUnique), `investiture_config` (findFirst x3, findUnique, findMany) |
| **Writes** | `enrollments` (update, multiple via $transaction), `investiture_validation_history` (create, multiple via $transaction), `investiture_config` (create, update x2) |
| **Transactions** | 10+ `$transaction` — flujo de aprobación multi-etapa (club → coordinador → campo → director → investido) |

---

### honors (validación)

#### `validation/validation.service.ts` (`ValidationService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `enrollments` (findUnique x2, findMany x2), `users_honors` (findUnique x2, findMany, aggregate x2), `club_role_assignments` (findFirst x2), `validation_logs` (findMany), `system_config` (findUnique) |
| **Writes** | `enrollments`, `users_honors`, `validation_logs`, `evidence_files` (todos vía `$transaction`) |
| **Transactions** | 4× `$transaction` — validación de clase (approve/reject), validación de honor (approve/reject) |

---

### certifications

#### `certifications/certifications.service.ts` (`CertificationsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `certifications` (findMany, count, findUnique x2), `users_certifications` (findFirst x2, findMany), `enrollments` (findFirst), `certification_module_progress` (count, findMany), `certification_section_progress` (findMany) |
| **Writes** | `users_certifications` (create, update) |
| **Transactions** | `$transaction` en actualización de sección con recalculación de progreso |

---

### finances

#### `finances/finances.service.ts` (`FinancesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `finances_categories` (findMany), `clubs` (findUnique x3), `finances` (findMany x3, count x2, findUnique), `club_sections` (findUnique x2) |
| **Writes** | `finances` (create, update x2) |

#### `finances/finance-period.service.ts` (`FinancePeriodService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `financePeriodClosing` (findUnique x2), `club_sections` (findMany), `finances` (findMany), `clubs` (findMany) |
| **Writes** | `financePeriodClosing` (create) — `@@map("finance_period_closings")` |

---

### camporees

#### `camporees/camporees.service.ts` (`CamporeeService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `local_camporees` (findMany, count, findUnique), `union_camporees` (findMany, count, findUnique), `ecclesiastical_years` (findFirst x2), `local_fields` (findUnique, findMany), `unions` (findUnique), `camporee_members` (findMany x4, findFirst x4), `camporee_clubs` (findMany x3, findFirst x3), `camporee_payments` (findMany x4, findUnique) |
| **Writes** | `local_camporees` (create, update x2), `union_camporees` (create, update), `camporee_members` (update x3), `camporee_clubs` (update x3), `camporee_payments` (update) |
| **Transactions** | 8× `$transaction` — registro/aprobación/rechazo de clubs y miembros en camporees (local y unión) |

#### `camporees/camporee-late-approvals.service.ts` (`CamporeeLatApprovalService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `camporee_clubs` (findMany x2), `camporee_members` (findMany x2), `camporee_payments` (findMany x2) |
| **Writes** | `camporee_clubs`, `camporee_members`, `camporee_payments` (todos vía $transaction) |
| **Transactions** | 13× `$transaction` — aprobaciones tardías de registros de camporee |

---

### notifications

#### `notifications/notifications.service.ts` (`NotificationsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `notification_logs` (findMany, count), `notification_deliveries` (findMany, count, findFirst), `user_fcm_tokens` (findMany x4), `users` (findMany x2), `club_role_assignments` (findMany x2), `users_roles` (findMany) |
| **Writes** | `notification_deliveries` (update, updateMany), `user_fcm_tokens` (updateMany — invalida tokens expirados) |
| **Transactions** | 5× `$transaction` — escritura atómica de `notification_logs` + `notification_deliveries` al enviar |

#### `notifications/fcm-tokens.service.ts` (`FcmTokensService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `user_fcm_tokens` (findFirst x2, findUnique, findMany) |
| **Writes** | `user_fcm_tokens` (update x2, create, updateMany x2, deleteMany) |

#### `notifications/notification-preferences.service.ts` (`NotificationPreferencesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `notification_preferences` (findMany x2, findUnique) |
| **Writes** | `notification_preferences` (upsert) |

---

### folders

#### `folders/folders.service.ts` (`FoldersService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `folders` (findMany, count, findUnique x2), `folder_assignments` (findFirst x2, findMany), `users` (findUnique), `folders_modules_records` (findMany), `folders_section_records` (findMany) |
| **Writes** | `folder_assignments` (create, update) |
| **Transactions** | `$transaction` en asignación de carpeta con creación de registros iniciales |

#### `folders/evidence-folder.service.ts` (`EvidenceFolderService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | Verificar archivo — no hay llamadas directas a Prisma registradas |
| **Writes** | — |

---

### annual-folders

#### `annual-folders/annual-folders.service.ts` (`AnnualFoldersService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `folder_templates` (findUnique x4), `club_types` (findUnique x2), `ecclesiastical_years` (findUnique x2), `folder_template_sections` (create vía $transaction, findUnique x2, findFirst x2), `annual_folders` (findUnique x5), `club_enrollments` (findUnique), `annual_folder_evidences` (create, findUnique x3, count), `annual_folder_section_submissions` (findUnique, upsert), `annual_folder_section_evaluations` (findUnique) |
| **Writes** | `folder_templates` (create), `folder_template_sections` (create, update, delete), `annual_folders` (create, update x2), `annual_folder_evidences` (create, update x2, delete), `annual_folder_section_submissions` (upsert) |

#### `annual-folders/evaluation.service.ts` (`EvaluationService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `annual_folders` (findUnique x2), `annual_folder_section_evaluations` (findMany) |
| **Writes** | `annual_folder_section_evaluations` (upsert vía $transaction), `annual_folders` (update vía $transaction) |
| **Transactions** | 2× `$transaction` — evaluación de sección y cierre de carpeta |

#### `annual-folders/rankings.service.ts` (`RankingsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `annual_folders` (findMany), `award_categories` (findMany), `club_annual_rankings` (findMany x2), `club_enrollments` (findUnique), `ecclesiastical_years` (findUnique, findFirst) |
| **Writes** | `club_annual_rankings` (upsert x N vía $transaction) |
| **Transactions** | `$transaction` en recálculo masivo de rankings |

#### `annual-folders/award-categories.service.ts` (`AwardCategoriesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_types` (findUnique x2), `award_categories` (findMany, findUnique) |
| **Writes** | `award_categories` (create, update x2) |

---

### monthly-reports

#### `monthly-reports/monthly-reports.service.ts` (`MonthlyReportsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `monthly_reports` (findUnique x4, findMany, count), `club_enrollments` (findUnique x2), `monthly_report_manual_data` (implícito en update/create), `club_role_assignments` (count, findMany x2), `users_honors` (findMany), `activities` (findMany), `finances` (findMany) |
| **Writes** | `monthly_reports` (create, update x2), `monthly_report_manual_data` (update, create) |

#### `monthly-reports/monthly-reports-cron.service.ts` (`MonthlyReportsCronService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `system_config` (findUnique x2), `club_enrollments` (findMany) |
| **Writes** | `monthly_reports` (create implícito vía `MonthlyReportsService`) |

#### `monthly-reports/monthly-reports-pdf.service.ts` (`MonthlyReportsPdfService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `monthly_reports` (findUnique) |
| **Writes** | — |

---

### units

#### `units/units.service.ts` (`UnitsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `clubs` (findUnique x2), `club_sections` (findUnique), `units` (findMany, findFirst), `users` (findUnique), `unit_members` (findFirst x3), `weekly_records` (findMany, findUnique), `unit_members` (findFirst — re-check) |
| **Writes** | `units` (create, update x2), `unit_members` (update, create), `weekly_records` (create/update vía $transaction), `weekly_record_scores` (updateMany vía $transaction) |
| **Transactions** | `$transaction` en creación/actualización de registro semanal con scores |

---

### scoring-categories

#### `scoring-categories/scoring-categories.service.ts` (`ScoringCategoriesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `scoring_categories` (findMany x3, findUnique x4), `club_role_assignments` (findFirst x2), `local_fields` (findUnique x2) |
| **Writes** | `scoring_categories` (create x3, update x4) |

---

### member-of-month

#### `member-of-month/member-of-month.service.ts` (`MemberOfMonthService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `member_of_month` (findMany x2), `club_sections` (findUnique x2), `club_role_assignments` (findMany, findFirst), `users` (findMany) |
| **Writes** | `member_of_month` (updateMany vía $transaction) |
| **Raw SQL** | `$queryRaw` x3 — cálculo de ranking de miembro del mes con agregaciones complejas sobre `weekly_records` |
| **Transactions** | `$transaction` en guardado de miembro del mes |

#### `member-of-month/member-of-month-cron.service.ts` (`MemberOfMonthCronService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_sections` (findMany) |
| **Writes** | Delega a `MemberOfMonthService` |

---

### inventory

#### `inventory/inventory.service.ts` (`InventoryService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_inventory` (findMany, findUnique x3), `inventory_categories` (findMany x2, findUnique x3), `club_sections` (findUnique), `inventory_history` (findMany) |
| **Writes** | `club_inventory` (create, update x2), `inventory_history` (createMany) |

---

### insurance

#### `insurance/insurance.service.ts` (`InsuranceService`, línea 1)

> No se encontraron llamadas directas a Prisma. Posible orquestador puro o servicio con implementación pendiente.

---

### emergency-contacts

#### `emergency-contacts/emergency-contacts.service.ts` (`EmergencyContactsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `relationship_types` (findUnique), `emergency_contacts` (count, findFirst x3, findMany) |
| **Writes** | `emergency_contacts` (create, updateMany x2, update x2) |

---

### legal-representatives

#### `legal-representatives/legal-representatives.service.ts` (`LegalRepresentativesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `legal_representatives` (findUnique x3), `users` (findUnique x3), `relationship_types` (findUnique x2) |
| **Writes** | `legal_representatives` (create, update, delete) |

---

### requests

#### `requests/requests.service.ts` (`RequestsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_role_assignments` (findFirst, count), `club_sections` (findUnique x2), `club_transfer_requests` (findFirst, findUnique x2, findMany), `role_assignment_requests` (findFirst, findUnique x2, count, findMany), `users` (findUnique), `roles` (findUnique x2), `role_slot_limits` (findUnique) |
| **Writes** | `club_transfer_requests` (create, update x2), `role_assignment_requests` (create, update x2), `club_role_assignments` (create vía $transaction) |
| **Transactions** | 2× `$transaction` — aprobación de transfer + aprobación de asignación de rol |

---

### membership-requests

#### `membership-requests/membership-requests.service.ts` (`MembershipRequestsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_role_assignments` (findMany, findFirst x2), `system_config` (findUnique) |
| **Writes** | `club_role_assignments` (update x2, updateMany) |

#### `membership-requests/membership-requests-cron.service.ts` (`MembershipRequestsCronService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | Delega a `MembershipRequestsService` |
| **Writes** | Delega a `MembershipRequestsService` |

---

### evidence-review

#### `evidence-review/evidence-review.service.ts` (`EvidenceReviewService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `folders_section_records` (findMany, findUnique x3), `class_section_progress` (findMany, findUnique x3), `users_honors` (findMany, findUnique x3), `validation_logs` (findMany) |
| **Writes** | `folders_section_records`, `class_section_progress`, `users_honors`, `validation_logs`, `evidence_files` (todos vía $transaction) |
| **Transactions** | 6× `$transaction` — approve/reject para cada tipo de evidencia (folders, clases, honores) |

---

### resources

#### `resources/resources.service.ts` (`ResourcesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `resource_categories` (findUnique), `resources` (findMany x2, count x2, findUnique x3) |
| **Writes** | `resources` (create, update x2) |
| **Transactions** | 2× `$transaction` array — paginación atómica (findMany + count) |

#### `resources/resource-categories.service.ts` (`ResourceCategoriesService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `resource_categories` (findMany, findUnique), `resources` (count) |
| **Writes** | `resource_categories` (create, update x2) |

---

### achievements

#### `achievements/achievements.service.ts` (`AchievementsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `achievements` (findMany x2, count, findUnique), `user_achievements` (findMany x2, findFirst), `achievement_categories` (findMany) |
| **Writes** | `achievement_event_log` (create) |

#### `achievements/admin/admin-achievements.service.ts` (`AdminAchievementsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `achievement_categories` (findMany, findUnique, count), `achievements` (count x3, findUnique x4), `user_achievements` (findMany, count x2, groupBy x2), `users` (findMany) |
| **Writes** | `achievement_categories` (create, update x2), `achievements` (create, update x3) |
| **Raw SQL** | `$queryRaw` x2 — estadísticas de desbloqueos por tier y por categoría (Prisma groupBy no soporta joins de relación) |

---

### analytics

#### `analytics/analytics.service.ts` (`AnalyticsService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_sections` (findMany), `enrollments` (groupBy, count x2), `class_section_progress` (count), `users_honors` (count), `camporee_clubs` (count), `camporee_members` (count), `camporee_payments` (count), `investiture_validation_history` (count x2) |
| **Writes** | — Solo lectura |
| **Raw SQL** | `$queryRaw` x5 — SLA de investidura (tiempos por etapa), throughput de validaciones; consultas complejas con agregaciones temporales |

---

### dashboard

#### `dashboard/dashboard.service.ts` (`DashboardService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users` (findUnique), `enrollments` (findFirst), `users_honors` (findMany), `users_pr` (findUnique), `club_role_assignments` (findFirst x2), `class_section_progress` (count), `class_sections` (count), `activities` (findMany) |
| **Writes** | — Solo lectura |

---

### system-config

#### `system-config/system-config.service.ts` (`SystemConfigService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `system_config` (findMany, findUnique x2) |
| **Writes** | `system_config` (update) |

---

### year-end

#### `year-end/year-end.service.ts` (`YearEndService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `club_enrollments` (findMany x2), `monthly_reports` (findMany, count), `annual_folders` (count), `ecclesiastical_years` (findUnique) |
| **Writes** | `club_enrollments` (update — campo `status` vía $transaction), `monthly_reports` (update vía $transaction) |
| **Transactions** | `$transaction` en cierre de año (marca enrollments y reportes como cerrados) |

---

### common (servicios de infraestructura)

#### `common/services/authorization-context.service.ts` (`AuthorizationContextService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | `users` (findUnique), `clubs` (findUnique) |
| **Writes** | — |

#### `common/services/cleanup.service.ts` (`CleanupService`, línea 1)

| Operación | Tablas |
|---|---|
| **Reads** | — |
| **Writes** | `session` (deleteMany), `verification` (deleteMany) — limpieza periódica de tokens expirados |

#### `common/services/session-management.service.ts` · `distributed-lock.service.ts` · `token-blacklist.service.ts` · `mfa.service.ts` · `file-storage.service.ts` · `r2-file-storage.service.ts`

> Ninguno hace llamadas directas a Prisma. Son servicios de infraestructura (Redis, JWT, R2/Cloudflare).

---

### app / prisma

#### `app.service.ts` (`AppService`, línea 1)

> Sin llamadas a Prisma. Health check puro.

#### `prisma/prisma.service.ts` (`PrismaService`, línea 1)

> Extiende `PrismaClient`. No contiene lógica de negocio ni queries propias.

---

## Sección C — Índice Inverso: Tabla → Servicios

| Tabla | Servicios que leen | Servicios que escriben |
|---|---|---|
| `users` | `auth.service`, `oauth.service`, `better-auth.service`, `users.service`, `post-registration.service`, `admin-users.service`, `admin-auth.service`, `legal-representatives.service`, `rbac.service`, `authorization-context.service`, `investiture.service`, `validation.service`, `dashboard.service`, `folders.service`, `achievements/admin`, `notifications.service` | `better-auth.service` (create), `auth.service` (update), `users.service` (update) |
| `users_pr` | `auth.service`, `oauth.service`, `post-registration.service`, `dashboard.service` | `auth.service` (upsert), `post-registration.service` (update) |
| `session` | `admin-auth.service`, `better-auth.service` | `better-auth.service` (create, deleteMany), `admin-auth.service` (delete, deleteMany), `cleanup.service` (deleteMany) |
| `account` | `oauth.service`, `better-auth.service` | `better-auth.service` (create, update), `oauth.service` (deleteMany) |
| `verification` | `auth.service`, `better-auth.service` | `auth.service` (create, delete), `better-auth.service` (create, deleteMany), `admin-auth.service` (deleteMany), `cleanup.service` (deleteMany) |
| `club_role_assignments` | `clubs.service`, `auth.service`, `investiture.service`, `validation.service`, `notifications.service`, `dashboard.service`, `membership-requests.service`, `requests.service`, `scoring-categories.service`, `member-of-month.service`, `monthly-reports.service`, `admin-reference.service`, `notifications.processor` | `clubs.service` (create, update), `membership-requests.service` (update, updateMany), `requests.service` (create vía tx) |
| `club_sections` | `clubs.service`, `activities.service`, `finances.service`, `finance-period.service`, `inventory.service`, `units.service`, `requests.service`, `member-of-month.service`, `analytics.service`, `camporees.service` | `clubs.service` (create, update) |
| `clubs` | `clubs.service`, `activities.service`, `finances.service`, `finance-period.service`, `units.service`, `authorization-context.service` | `clubs.service` (create, update) |
| `club_types` | `catalogs.service`, `annual-folders.service`, `award-categories.service` | — |
| `ecclesiastical_years` | `classes.service`, `camporees.service`, `investiture.service`, `admin-reference.service`, `catalogs.service`, `annual-folders.service`, `rankings.service`, `year-end.service`, `club-enrollments.service` | `admin-reference.service` (update — activate/deactivate) |
| `club_enrollments` | `club-enrollments.service`, `annual-folders.service`, `monthly-reports.service`, `monthly-reports-cron.service`, `rankings.service`, `year-end.service` | `club-enrollments.service` (create, update), `year-end.service` (update vía tx) |
| `enrollments` | `classes.service`, `investiture.service`, `validation.service`, `admin-users.service`, `certifications.service`, `analytics.service`, `dashboard.service` | `classes.service` (create vía tx), `investiture.service` (update vía tx) |
| `class_section_progress` | `classes.service`, `evidence-review.service`, `dashboard.service`, `analytics.service` | `classes.service` (create, update), `evidence-review.service` (update vía tx), `validation.service` (vía tx) |
| `class_module_progress` | — | `classes.service` (create vía tx implícito) |
| `class_sections` | `classes.service`, `dashboard.service` | — |
| `class_modules` | `classes.service` | — |
| `classes` | `classes.service` | — |
| `investiture_validation_history` | `investiture.service`, `analytics.service` | `investiture.service` (create vía tx) |
| `investiture_config` | `investiture.service` | `investiture.service` (create, update) |
| `honors` | `honors.service`, `admin-honors.service`, `admin-reference.service`, `catalogs.service` (vía join) | — |
| `honors_categories` | `honors.service`, `admin-reference.service` | `admin-reference.service` (create, update) |
| `master_honors` | — | — |
| `users_honors` | `honors.service`, `honor-requirements.service`, `validation.service`, `evidence-review.service`, `dashboard.service`, `monthly-reports.service`, `analytics.service` | `honors.service` (create, update), `validation.service` (update vía tx), `evidence-review.service` (update vía tx) |
| `honor_requirements` | `honors.service` (indirecto), `honor-requirements.service`, `admin-honors.service` | `admin-honors.service` (update, updateMany), `honor-requirements.service` (implícito vía progress) |
| `user_honor_requirement_progress` | `honor-requirements.service` | `honor-requirements.service` (upsert vía tx) |
| `requirement_evidence` | `honor-requirements.service` | `honor-requirements.service` (create, update) |
| `activities` | `activities.service`, `activities-reminder.service`, `dashboard.service`, `monthly-reports.service` | `activities.service` (create, update), `activities-reminder.service` (update — reminder_sent) |
| `activity_instances` | — | `activities.service` (updateMany, upsert) |
| `activity_types` | `admin-reference.service`, `catalogs.service` | `admin-reference.service` (create, update) |
| `folders` | `folders.service` | — |
| `folders_modules` | — | — |
| `folders_sections` | — | — |
| `folder_assignments` | `folders.service` | `folders.service` (create, update) |
| `folders_modules_records` | `folders.service` | — |
| `folders_section_records` | `folders.service`, `evidence-review.service` | `evidence-review.service` (update vía tx), `validation.service` (vía tx) |
| `evidence_files` | — | `validation.service` (vía tx), `evidence-review.service` (vía tx) |
| `folder_templates` | `annual-folders.service` | `annual-folders.service` (create) |
| `folder_template_sections` | `annual-folders.service` | `annual-folders.service` (create, update, delete) |
| `annual_folders` | `annual-folders.service`, `evaluation.service`, `rankings.service`, `year-end.service` | `annual-folders.service` (create, update), `evaluation.service` (update vía tx), `year-end.service` (implícito) |
| `annual_folder_evidences` | `annual-folders.service` | `annual-folders.service` (create, update, delete) |
| `annual_folder_section_evaluations` | `annual-folders.service`, `evaluation.service` | `evaluation.service` (upsert vía tx) |
| `annual_folder_section_submissions` | `annual-folders.service` | `annual-folders.service` (upsert) |
| `award_categories` | `annual-folders.service`, `award-categories.service`, `rankings.service` | `award-categories.service` (create, update) |
| `club_annual_rankings` | `rankings.service` | `rankings.service` (upsert vía tx) |
| `finances` | `finances.service`, `finance-period.service`, `monthly-reports.service` | `finances.service` (create, update) |
| `finances_categories` | `finances.service` | — |
| `FinancePeriodClosing` (`finance_period_closings`) | `finance-period.service` | `finance-period.service` (create) |
| `local_camporees` | `camporees.service` | `camporees.service` (create, update) |
| `union_camporees` | `camporees.service` | `camporees.service` (create, update) |
| `union_camporee_local_fields` | — | `camporees.service` (vía tx implícito) |
| `camporee_clubs` | `camporees.service`, `camporee-late-approvals.service`, `analytics.service` | `camporees.service` (update), `camporee-late-approvals.service` (vía tx) |
| `camporee_members` | `camporees.service`, `camporee-late-approvals.service`, `analytics.service` | `camporees.service` (update), `camporee-late-approvals.service` (vía tx) |
| `camporee_payments` | `camporees.service`, `camporee-late-approvals.service`, `analytics.service` | `camporees.service` (update), `camporee-late-approvals.service` (vía tx) |
| `member_insurances` | — | — |
| `notification_logs` | `notifications.service` | `notifications.service` (vía tx) |
| `notification_deliveries` | `notifications.service` | `notifications.service` (update, updateMany, vía tx) |
| `notification_preferences` | `notification-preferences.service` | `notification-preferences.service` (upsert) |
| `user_fcm_tokens` | `notifications.service`, `fcm-tokens.service`, `notifications.processor` | `fcm-tokens.service` (update, create, updateMany, deleteMany), `notifications.service` (updateMany — invalida tokens) |
| `units` | `units.service` | `units.service` (create, update) |
| `unit_members` | `units.service` | `units.service` (update, create) |
| `weekly_records` | `units.service` | `units.service` (create/update vía tx) |
| `weekly_record_scores` | — | `units.service` (updateMany vía tx) |
| `scoring_categories` | `scoring-categories.service` | `scoring-categories.service` (create, update) |
| `member_of_month` | `member-of-month.service` | `member-of-month.service` (updateMany vía tx) |
| `certifications` | `certifications.service` | — |
| `certification_modules` | — | — |
| `certification_sections` | — | — |
| `users_certifications` | `certifications.service` | `certifications.service` (create, update) |
| `certification_module_progress` | `certifications.service` | — |
| `certification_section_progress` | `certifications.service` | — |
| `monthly_reports` | `monthly-reports.service`, `monthly-reports-pdf.service`, `year-end.service` | `monthly-reports.service` (create, update), `year-end.service` (update vía tx) |
| `monthly_report_manual_data` | `monthly-reports.service` | `monthly-reports.service` (create, update) |
| `club_transfer_requests` | `requests.service` | `requests.service` (create, update) |
| `role_assignment_requests` | `requests.service` | `requests.service` (create, update) |
| `validation_logs` | `validation.service`, `evidence-review.service` | `validation.service` (vía tx), `evidence-review.service` (vía tx) |
| `resource_categories` | `resource-categories.service`, `resources.service` | `resource-categories.service` (create, update) |
| `resources` | `resources.service`, `resource-categories.service` (count) | `resources.service` (create, update) |
| `achievement_categories` | `achievements.service`, `admin-achievements.service` | `admin-achievements.service` (create, update) |
| `achievements` | `achievements.service`, `admin-achievements.service`, `achievements.processor` | `admin-achievements.service` (create, update) |
| `user_achievements` | `achievements.service`, `admin-achievements.service`, `achievements.processor` | `achievements.processor` (create, update) |
| `achievement_event_log` | `achievements.service` (handlers), `achievements.processor` | `achievements.service` (create) |
| `system_config` | `system-config.service`, `activities-reminder.service`, `membership-requests.service`, `monthly-reports-cron.service`, `validation.service` | `system-config.service` (update) |
| `allergies` | `users.service`, `admin-reference.service`, `catalogs.service` | `admin-reference.service` (create, update) |
| `diseases` | `users.service`, `admin-reference.service`, `catalogs.service` | `admin-reference.service` (create, update) |
| `medicines` | `users.service`, `admin-reference.service`, `catalogs.service` | `admin-reference.service` (create, update) |
| `users_allergies` | `users.service`, `admin-reference.service` (count) | `users.service` (updateMany) |
| `users_diseases` | `users.service`, `admin-reference.service` (count) | `users.service` (updateMany) |
| `users_medicines` | `users.service`, `admin-reference.service` (count) | `users.service` (updateMany) |
| `emergency_contacts` | `emergency-contacts.service`, `post-registration.service` (count) | `emergency-contacts.service` (create, update, updateMany) |
| `legal_representatives` | `legal-representatives.service`, `admin-reference.service` (count) | `legal-representatives.service` (create, update, delete) |
| `relationship_types` | `emergency-contacts.service`, `legal-representatives.service`, `admin-reference.service`, `catalogs.service` | `admin-reference.service` (create, update) |
| `countries` | `users.service`, `admin-geography.service`, `catalogs.service` | `admin-geography.service` (create, update) |
| `unions` | `users.service`, `admin-geography.service`, `catalogs.service`, `camporees.service` | `admin-geography.service` (create, update) |
| `local_fields` | `users.service`, `admin-geography.service`, `catalogs.service`, `camporees.service`, `scoring-categories.service`, `investiture.service` | `admin-geography.service` (create, update) |
| `districts` | `admin-geography.service`, `catalogs.service` | `admin-geography.service` (create, update) |
| `churches` | `admin-geography.service`, `catalogs.service` | `admin-geography.service` (create, update) |
| `clubs` | `clubs.service`, `activities.service`, `finances.service`, `units.service`, `authorization-context.service`, `admin-geography.service` (vía churches) | `clubs.service` (create, update) |
| `roles` | `clubs.service`, `rbac.service`, `requests.service`, `catalogs.service` | `rbac.service` (create implícito) |
| `permissions` | `rbac.service` | `rbac.service` (create, update) |
| `role_permissions` | `rbac.service` | `rbac.service` (create, update, updateMany) |
| `users_roles` | `rbac.service`, `notifications.service`, `notifications.processor` | `rbac.service` (create, update) |
| `users_permissions` | `rbac.service` | `rbac.service` (create, update) |
| `role_slot_limits` | `clubs.service`, `requests.service` | — |
| `club_ideals` | `admin-reference.service`, `catalogs.service` | — |
| `inventory_categories` | `inventory.service` | — |
| `club_inventory` | `inventory.service` | `inventory.service` (create, update) |
| `inventory_history` | `inventory.service` | `inventory.service` (createMany) |
| `error_logs` ⚠️ **DEPRECATED** | — | — |

---

## Sección D — Gaps y Observaciones

### Servicios sin acceso directo a la DB (orquestadores / infraestructura)

| Servicio | Rol |
|---|---|
| `app.service.ts` | Health check puro |
| `insurance/insurance.service.ts` | Sin implementación de Prisma detectada — posible stub |
| `catalogs/catalog-cache.service.ts` | Orquesta `CatalogsService` + Redis; sin Prisma directo |
| `common/services/distributed-lock.service.ts` | Redis solamente |
| `common/services/token-blacklist.service.ts` | Redis solamente |
| `common/services/mfa.service.ts` | Lógica TOTP; sin Prisma |
| `common/services/file-storage.service.ts` | Abstracción de storage; sin Prisma |
| `common/services/r2-file-storage.service.ts` | Cloudflare R2; sin Prisma |
| `common/services/session-management.service.ts` | Gestión de sesiones Redis; sin Prisma |
| `membership-requests/membership-requests-cron.service.ts` | Cron que delega a `MembershipRequestsService` |
| `member-of-month/member-of-month-cron.service.ts` | Cron que delega a `MemberOfMonthService` |
| `monthly-reports/monthly-reports-cron.service.ts` | Cron que delega a `MonthlyReportsService` (Prisma solo en config check) |
| `monthly-reports/monthly-reports-pdf.service.ts` | Solo lee `monthly_reports`; genera PDF sin escrituras |
| `folders/evidence-folder.service.ts` | Sin llamadas Prisma detectadas |

### Tablas con cero referencias de servicio (posible código inactivo o solo manejado vía migraciones)

| Tabla | Observación |
|---|---|
| `error_logs` ⚠️ **DEPRECATED (2026-04-14)** | Marcado como DEPRECADO. Ningún servicio escribe en ella, ningún controller la expone, y no hay triggers conocidos poblándola. **Acción pendiente**: crear migración Prisma para eliminar la tabla en la próxima ventana de schema changes. Por ahora se mantiene físicamente para no romper backups históricos. |
| `master_honors` | Originally flagged as orphan, corrected 2026-04-14 — `honors.service.ts:187` carga via `include: { master_honors: { select: { name: true } } }`. Modelo HAS SERVICE (vía include). |
| `club_ideals` | Originally flagged as orphan, corrected 2026-04-14 — leída directamente vía `this.prisma.club_ideals.findMany()` en `catalogs.service.ts:328` y `admin-reference.service.ts:599`. Endpoints expuestos: `GET /catalogs/club-ideals` y `GET /admin/club-ideals`. HAS SERVICE. |
| `inventory_categories` | Originally flagged as orphan, corrected 2026-04-14 — leída directamente con múltiples `findMany`/`findUnique` en `inventory.service.ts` (líneas 33, 93, 125, 198, 273, 412). Endpoint expuesto: `GET /catalogs/inventory-categories`. HAS SERVICE. |
| `certification_modules` | Originally flagged as orphan, corrected 2026-04-14 — accedida directamente vía `tx.certification_modules.findMany()` en `certifications.service.ts:496` y también vía include. Endpoints expuestos via `GET /certifications`, `GET /certifications/:id`, y progreso. HAS SERVICE. |
| `certification_sections` | Originally flagged as orphan, corrected 2026-04-14 — accedida directamente vía `tx.certification_sections.findFirst()` (línea 399) y `tx.certification_sections.findMany()` (línea 448) en `certifications.service.ts`. HAS SERVICE. |

### Observaciones sorprendentes

1. **`analytics.service.ts` usa 5 `$queryRaw`** para calcular SLA de investidura y throughput de validaciones. Son las consultas más complejas del sistema. Cualquier cambio en las tablas `enrollments`, `investiture_validation_history` o `class_section_progress` debe verificar compatibilidad con esas queries.

2. **`camporee-late-approvals.service.ts` tiene 13 `$transaction`** — el número más alto de transacciones por servicio. Toda la lógica de aprobación tardía de camporees está serializada en transacciones atómicas, lo cual es correcto pero requiere atención en timeouts.

3. **`notifications.service.ts` lee `club_role_assignments` y `users_roles`** — un servicio de notificaciones haciendo queries de RBAC. Esto es cross-domain: el módulo de notificaciones necesita conocer la estructura de roles para saber a quién mandar notificaciones por sección. No es un error, pero es un acoplamiento a documentar.

4. **`member_of_month.service.ts` usa `$queryRaw`** para el cálculo de ranking acumulado por sección (agrega `weekly_records` con joins complejos). Si el schema de `weekly_records` o `weekly_record_scores` cambia, estas queries rawSQL deben actualizarse manualmente.

5. **`validation.service.ts` es un hub de validación cross-domain**: toca `enrollments`, `users_honors` y `folders_section_records` en el mismo servicio con transacciones. Es el punto de mayor acoplamiento estructural del sistema.
