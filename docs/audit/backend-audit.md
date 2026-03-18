# Backend Audit — SACDIA
Fecha: 2026-03-14
Fuente: sacdia-backend/ (NestJS + Prisma)
Metodo: Scan automatico de codigo fuente

## Resumen
- Endpoints: 198
- Modelos: 72
- Modulos: 22
- Integraciones externas: 6

---

## Endpoints

Prefijo global: `/api/v1`

| # | Method | Route | Controller | Service | Auth Guard | Description |
|---|--------|-------|------------|---------|------------|-------------|
| 1 | GET | `/` | AppController | AppService | Ninguno | Hello world / root |
| 2 | GET | `/health` | HealthController | PrismaService | Ninguno | Health check API status |
| 3 | POST | `/auth/register` | AuthController | AuthService | Ninguno | Registrar nuevo usuario |
| 4 | POST | `/auth/login` | AuthController | AuthService | Ninguno | Iniciar sesion |
| 5 | POST | `/auth/refresh` | AuthController | AuthService | Ninguno | Refrescar sesion con refresh token |
| 6 | POST | `/auth/logout` | AuthController | AuthService | Ninguno | Cerrar sesion (best effort) |
| 7 | POST | `/auth/password/reset-request` | AuthController | AuthService | Ninguno | Solicitar recuperacion de contrasena |
| 8 | GET | `/auth/me` | AuthController | AuthService | JwtAuthGuard | Obtener perfil del usuario autenticado |
| 9 | PATCH | `/auth/me/context` | AuthController | AuthService | JwtAuthGuard | Cambiar contexto activo de club |
| 10 | GET | `/auth/profile/completion-status` | AuthController | AuthService | JwtAuthGuard | Estado del post-registro |
| 11 | GET | `/auth/sessions` | SessionsController | SessionManagementService | JwtAuthGuard (controller) | Listar sesiones activas |
| 12 | DELETE | `/auth/sessions/:sessionId` | SessionsController | SessionManagementService | JwtAuthGuard (controller) | Cerrar sesion especifica |
| 13 | DELETE | `/auth/sessions` | SessionsController | TokenBlacklistService | JwtAuthGuard (controller) | Cerrar todas las sesiones |
| 14 | POST | `/auth/oauth/google` | OAuthController | OAuthService | Ninguno | Iniciar OAuth con Google |
| 15 | POST | `/auth/oauth/apple` | OAuthController | OAuthService | Ninguno | Iniciar OAuth con Apple |
| 16 | GET | `/auth/oauth/callback` | OAuthController | OAuthService | Ninguno | Manejar callback de OAuth |
| 17 | GET | `/auth/oauth/providers` | OAuthController | OAuthService | JwtAuthGuard | Obtener providers conectados |
| 18 | DELETE | `/auth/oauth/:provider` | OAuthController | OAuthService | JwtAuthGuard | Desconectar provider |
| 19 | POST | `/auth/mfa/enroll` | MfaController | MfaService | JwtAuthGuard (controller) | Iniciar enrolamiento 2FA |
| 20 | POST | `/auth/mfa/verify` | MfaController | MfaService | JwtAuthGuard (controller) | Verificar y activar 2FA |
| 21 | GET | `/auth/mfa/factors` | MfaController | MfaService | JwtAuthGuard (controller) | Listar factores MFA |
| 22 | DELETE | `/auth/mfa/unenroll` | MfaController | MfaService | JwtAuthGuard (controller) | Deshabilitar 2FA |
| 23 | GET | `/auth/mfa/status` | MfaController | MfaService | JwtAuthGuard (controller) | Estado de 2FA |
| 24 | GET | `/users/:userId` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Obtener usuario por ID |
| 25 | GET | `/users/:userId/allergies` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Obtener alergias del usuario |
| 26 | GET | `/users/:userId/diseases` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Obtener enfermedades del usuario |
| 27 | GET | `/users/:userId/medicines` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Obtener medicamentos del usuario |
| 28 | PATCH | `/users/:userId` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Actualizar informacion personal |
| 29 | PUT | `/users/:userId/allergies` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Guardar alergias del usuario |
| 30 | PUT | `/users/:userId/diseases` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Guardar enfermedades del usuario |
| 31 | PUT | `/users/:userId/medicines` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Guardar medicamentos del usuario |
| 32 | DELETE | `/users/:userId/allergies/:allergyId` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Eliminar alergia (soft delete) |
| 33 | DELETE | `/users/:userId/diseases/:diseaseId` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Eliminar enfermedad (soft delete) |
| 34 | DELETE | `/users/:userId/medicines/:medicineId` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Eliminar medicamento (soft delete) |
| 35 | POST | `/users/:userId/profile-picture` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Subir foto de perfil |
| 36 | DELETE | `/users/:userId/profile-picture` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Eliminar foto de perfil |
| 37 | GET | `/users/:userId/age` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Calcular edad del usuario |
| 38 | GET | `/users/:userId/requires-legal-representative` | UsersController | UsersService | JwtAuthGuard, PermissionsGuard | Verificar si requiere representante legal |
| 39 | GET | `/clubs` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard | Listar clubs |
| 40 | GET | `/clubs/:clubId` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard | Obtener club por ID |
| 41 | POST | `/clubs` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard | Crear nuevo club |
| 42 | PATCH | `/clubs/:clubId` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard, ClubRolesGuard | Actualizar club |
| 43 | DELETE | `/clubs/:clubId` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard, ClubRolesGuard | Desactivar club |
| 44 | GET | `/clubs/:clubId/instances` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard | Obtener instancias del club |
| 45 | GET | `/clubs/:clubId/instances/:type` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard | Obtener instancia por tipo |
| 46 | POST | `/clubs/:clubId/instances` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard, ClubRolesGuard | Crear instancia de club |
| 47 | PATCH | `/clubs/:clubId/instances/:type/:instanceId` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard, ClubRolesGuard | Actualizar instancia |
| 48 | GET | `/clubs/:clubId/instances/:type/:instanceId/members` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard | Listar miembros de instancia |
| 49 | POST | `/clubs/:clubId/instances/:type/:instanceId/roles` | ClubsController | ClubsService | JwtAuthGuard, PermissionsGuard | Asignar rol a miembro |
| 50 | PATCH | `/club-roles/:assignmentId` | ClubRolesController | ClubsService | JwtAuthGuard, PermissionsGuard | Actualizar asignacion de rol |
| 51 | DELETE | `/club-roles/:assignmentId` | ClubRolesController | ClubsService | JwtAuthGuard, PermissionsGuard | Remover rol de miembro |
| 52 | GET | `/honors` | HonorsController | HonorsService | OptionalJwtAuthGuard | Listar honores |
| 53 | GET | `/honors/categories` | HonorsController | HonorsService | OptionalJwtAuthGuard | Listar categorias de honores |
| 54 | GET | `/honors/grouped-by-category` | HonorsController | HonorsService | OptionalJwtAuthGuard | Honores agrupados por categoria |
| 55 | GET | `/honors/:honorId` | HonorsController | HonorsService | OptionalJwtAuthGuard | Obtener honor por ID |
| 56 | GET | `/users/:userId/honors` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Obtener honores del usuario |
| 57 | GET | `/users/:userId/honors/stats` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Estadisticas de honores del usuario |
| 58 | POST | `/users/:userId/honors` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Registrar honor con datos iniciales |
| 59 | POST | `/users/:userId/honors/bulk` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Registrar honores masivos |
| 60 | POST | `/users/:userId/honors/:honorId/files` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Subir evidencias del honor |
| 61 | POST | `/users/:userId/honors/:honorId` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Iniciar un honor |
| 62 | PATCH | `/users/:userId/honors/:honorId` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Actualizar progreso de honor |
| 63 | DELETE | `/users/:userId/honors/:honorId` | UserHonorsController | HonorsService | JwtAuthGuard, OwnerOrAdminGuard | Abandonar honor |
| 64 | GET | `/clubs/:clubId/activities` | ActivitiesController | ActivitiesService | JwtAuthGuard, PermissionsGuard | Listar actividades del club |
| 65 | POST | `/clubs/:clubId/activities` | ActivitiesController | ActivitiesService | JwtAuthGuard, PermissionsGuard, ClubRolesGuard | Crear actividad |
| 66 | GET | `/activities/:activityId` | ActivitiesController | ActivitiesService | JwtAuthGuard, PermissionsGuard | Obtener actividad por ID |
| 67 | PATCH | `/activities/:activityId` | ActivitiesController | ActivitiesService | JwtAuthGuard, PermissionsGuard | Actualizar actividad |
| 68 | DELETE | `/activities/:activityId` | ActivitiesController | ActivitiesService | JwtAuthGuard, PermissionsGuard | Desactivar actividad |
| 69 | POST | `/activities/:activityId/attendance` | ActivitiesController | ActivitiesService | JwtAuthGuard, PermissionsGuard | Registrar asistencia |
| 70 | GET | `/activities/:activityId/attendance` | ActivitiesController | ActivitiesService | JwtAuthGuard, PermissionsGuard | Obtener asistencia |
| 71 | GET | `/finances/categories` | FinancesController | FinancesService | JwtAuthGuard, PermissionsGuard | Listar categorias financieras |
| 72 | GET | `/clubs/:clubId/finances` | FinancesController | FinancesService | JwtAuthGuard, PermissionsGuard | Listar movimientos financieros |
| 73 | GET | `/clubs/:clubId/finances/summary` | FinancesController | FinancesService | JwtAuthGuard, PermissionsGuard | Resumen financiero del club |
| 74 | POST | `/clubs/:clubId/finances` | FinancesController | FinancesService | JwtAuthGuard, PermissionsGuard, ClubRolesGuard | Crear movimiento financiero |
| 75 | GET | `/finances/:financeId` | FinancesController | FinancesService | JwtAuthGuard, PermissionsGuard | Obtener movimiento por ID |
| 76 | PATCH | `/finances/:financeId` | FinancesController | FinancesService | JwtAuthGuard, PermissionsGuard | Actualizar movimiento |
| 77 | DELETE | `/finances/:financeId` | FinancesController | FinancesService | JwtAuthGuard, PermissionsGuard | Desactivar movimiento |
| 78 | GET | `/admin/rbac/permissions` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Listar todos los permisos |
| 79 | GET | `/admin/rbac/permissions/:id` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Obtener permiso por ID |
| 80 | POST | `/admin/rbac/permissions` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Crear permiso |
| 81 | PATCH | `/admin/rbac/permissions/:id` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Actualizar permiso |
| 82 | DELETE | `/admin/rbac/permissions/:id` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Desactivar permiso |
| 83 | GET | `/admin/rbac/roles` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Listar roles con permisos |
| 84 | GET | `/admin/rbac/roles/:id` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Obtener rol con permisos |
| 85 | POST | `/admin/rbac/roles/:id/permissions` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Asignar permisos a rol |
| 86 | PUT | `/admin/rbac/roles/:id/permissions` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Sincronizar permisos de rol |
| 87 | DELETE | `/admin/rbac/roles/:id/permissions/:permissionId` | RbacController | RbacService | JwtAuthGuard, PermissionsGuard | Remover permiso de rol |
| 88 | POST | `/notifications/send` | NotificationsController | NotificationsService | JwtAuthGuard, PermissionsGuard | Enviar notificacion a usuario |
| 89 | POST | `/notifications/broadcast` | NotificationsController | NotificationsService | JwtAuthGuard, PermissionsGuard | Enviar notificacion a todos |
| 90 | POST | `/notifications/club/:instanceType/:instanceId` | NotificationsController | NotificationsService | JwtAuthGuard, PermissionsGuard | Enviar notificacion a club |
| 91 | POST | `/fcm-tokens` | FcmTokensController | FcmTokensService | JwtAuthGuard | Registrar token FCM |
| 92 | DELETE | `/fcm-tokens/:token` | FcmTokensController | FcmTokensService | JwtAuthGuard | Desregistrar token FCM |
| 93 | GET | `/fcm-tokens` | FcmTokensController | FcmTokensService | JwtAuthGuard | Obtener tokens FCM del usuario |
| 94 | GET | `/fcm-tokens/user/:userId` | FcmTokensController | FcmTokensService | JwtAuthGuard, OwnerOrAdminGuard | Obtener tokens FCM por userId |
| 95 | GET | `/camporees` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Listar camporees |
| 96 | GET | `/camporees/:camporeeId` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Obtener camporee por ID |
| 97 | POST | `/camporees` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Crear camporee |
| 98 | PATCH | `/camporees/:camporeeId` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Actualizar camporee |
| 99 | DELETE | `/camporees/:camporeeId` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Desactivar camporee |
| 100 | POST | `/camporees/:camporeeId/register` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Registrar miembro en camporee |
| 101 | GET | `/camporees/:camporeeId/members` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Listar miembros del camporee |
| 102 | DELETE | `/camporees/:camporeeId/members/:userId` | CamporeesController | CamporeesService | JwtAuthGuard, PermissionsGuard | Remover miembro del camporee |
| 103 | POST | `/users/:userId/emergency-contacts` | EmergencyContactsController | EmergencyContactsService | JwtAuthGuard, PermissionsGuard | Crear contacto de emergencia |
| 104 | GET | `/users/:userId/emergency-contacts` | EmergencyContactsController | EmergencyContactsService | JwtAuthGuard, PermissionsGuard | Listar contactos de emergencia |
| 105 | GET | `/users/:userId/emergency-contacts/:contactId` | EmergencyContactsController | EmergencyContactsService | JwtAuthGuard, PermissionsGuard | Obtener contacto especifico |
| 106 | PATCH | `/users/:userId/emergency-contacts/:contactId` | EmergencyContactsController | EmergencyContactsService | JwtAuthGuard, PermissionsGuard | Actualizar contacto |
| 107 | DELETE | `/users/:userId/emergency-contacts/:contactId` | EmergencyContactsController | EmergencyContactsService | JwtAuthGuard, PermissionsGuard | Eliminar contacto (soft delete) |
| 108 | POST | `/users/:userId/legal-representative` | LegalRepresentativesController | LegalRepresentativesService | JwtAuthGuard, PermissionsGuard | Registrar representante legal |
| 109 | GET | `/users/:userId/legal-representative` | LegalRepresentativesController | LegalRepresentativesService | JwtAuthGuard, PermissionsGuard | Obtener representante legal |
| 110 | PATCH | `/users/:userId/legal-representative` | LegalRepresentativesController | LegalRepresentativesService | JwtAuthGuard, PermissionsGuard | Actualizar representante legal |
| 111 | DELETE | `/users/:userId/legal-representative` | LegalRepresentativesController | LegalRepresentativesService | JwtAuthGuard, PermissionsGuard | Eliminar representante legal |
| 112 | GET | `/users/:userId/post-registration/status` | PostRegistrationController | PostRegistrationService | JwtAuthGuard, PermissionsGuard | Estado del post-registro |
| 113 | POST | `/users/:userId/post-registration/step-1/complete` | PostRegistrationController | PostRegistrationService | JwtAuthGuard, PermissionsGuard | Completar paso 1: foto |
| 114 | POST | `/users/:userId/post-registration/step-2/complete` | PostRegistrationController | PostRegistrationService | JwtAuthGuard, PermissionsGuard | Completar paso 2: info personal |
| 115 | POST | `/users/:userId/post-registration/step-3/complete` | PostRegistrationController | PostRegistrationService | JwtAuthGuard, PermissionsGuard | Completar paso 3: club |
| 116 | GET | `/catalogs/club-types` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Tipos de club |
| 117 | GET | `/catalogs/activity-types` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Tipos de actividad |
| 118 | GET | `/catalogs/relationship-types` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Tipos de relacion |
| 119 | GET | `/catalogs/countries` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Paises |
| 120 | GET | `/catalogs/unions` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Uniones |
| 121 | GET | `/catalogs/local-fields` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Campos locales |
| 122 | GET | `/catalogs/districts` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Distritos |
| 123 | GET | `/catalogs/churches` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Iglesias |
| 124 | GET | `/catalogs/roles` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Roles disponibles |
| 125 | GET | `/catalogs/ecclesiastical-years` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Anos eclesiasticos |
| 126 | GET | `/catalogs/ecclesiastical-years/current` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Ano eclesiastico actual |
| 127 | GET | `/catalogs/club-ideals` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Ideales de club |
| 128 | GET | `/catalogs/allergies` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Catalogo de alergias |
| 129 | GET | `/catalogs/diseases` | CatalogsController | CatalogsService | OptionalJwtAuthGuard | Catalogo de enfermedades |
| 130 | GET | `/certifications/certifications` | CertificationsController | CertificationsService | JwtAuthGuard, PermissionsGuard | Listar certificaciones |
| 131 | GET | `/certifications/certifications/:id` | CertificationsController | CertificationsService | JwtAuthGuard, PermissionsGuard | Detalle de certificacion |
| 132 | POST | `/certifications/users/:userId/certifications/enroll` | CertificationsController | CertificationsService | JwtAuthGuard, PermissionsGuard | Inscribirse en certificacion |
| 133 | GET | `/certifications/users/:userId/certifications` | CertificationsController | CertificationsService | JwtAuthGuard, PermissionsGuard | Listar certificaciones del usuario |
| 134 | GET | `/certifications/users/:userId/certifications/:certificationId/progress` | CertificationsController | CertificationsService | JwtAuthGuard, PermissionsGuard | Progreso de certificacion |
| 135 | PATCH | `/certifications/users/:userId/certifications/:certificationId/progress` | CertificationsController | CertificationsService | JwtAuthGuard, PermissionsGuard | Actualizar progreso certificacion |
| 136 | DELETE | `/certifications/users/:userId/certifications/:certificationId` | CertificationsController | CertificationsService | JwtAuthGuard, PermissionsGuard | Abandonar certificacion |
| 137 | GET | `/inventory/clubs/:clubId/inventory` | InventoryController | InventoryService | JwtAuthGuard, PermissionsGuard | Listar items inventario club |
| 138 | GET | `/inventory/inventory/:id` | InventoryController | InventoryService | JwtAuthGuard, PermissionsGuard | Detalle de item inventario |
| 139 | POST | `/inventory/clubs/:clubId/inventory` | InventoryController | InventoryService | JwtAuthGuard, PermissionsGuard | Agregar item inventario |
| 140 | PATCH | `/inventory/inventory/:id` | InventoryController | InventoryService | JwtAuthGuard, PermissionsGuard | Actualizar item inventario |
| 141 | DELETE | `/inventory/inventory/:id` | InventoryController | InventoryService | JwtAuthGuard, PermissionsGuard | Eliminar item inventario |
| 142 | GET | `/inventory/catalogs/inventory-categories` | InventoryController | InventoryService | JwtAuthGuard, PermissionsGuard | Categorias de inventario |
| 143 | GET | `/folders/folders` | FoldersController | FoldersService | JwtAuthGuard, PermissionsGuard | Listar templates de carpetas |
| 144 | GET | `/folders/folders/:id` | FoldersController | FoldersService | JwtAuthGuard, PermissionsGuard | Detalle de template carpeta |
| 145 | POST | `/folders/users/:userId/folders/:folderId/enroll` | FoldersController | FoldersService | JwtAuthGuard, PermissionsGuard | Inscribirse en carpeta |
| 146 | GET | `/folders/users/:userId/folders` | FoldersController | FoldersService | JwtAuthGuard, PermissionsGuard | Listar carpetas del usuario |
| 147 | GET | `/folders/users/:userId/folders/:folderId/progress` | FoldersController | FoldersService | JwtAuthGuard, PermissionsGuard | Progreso de carpeta |
| 148 | PATCH | `/folders/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId` | FoldersController | FoldersService | JwtAuthGuard, PermissionsGuard | Actualizar progreso seccion carpeta |
| 149 | DELETE | `/folders/users/:userId/folders/:folderId` | FoldersController | FoldersService | JwtAuthGuard, PermissionsGuard | Abandonar carpeta |
| 150 | GET | `/admin/relationship-types` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Listar tipos de relacion (admin) |
| 151 | POST | `/admin/relationship-types` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Crear tipo de relacion |
| 152 | PATCH | `/admin/relationship-types/:relationshipTypeId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Actualizar tipo de relacion |
| 153 | DELETE | `/admin/relationship-types/:relationshipTypeId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Eliminar tipo de relacion |
| 154 | GET | `/admin/allergies` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Listar alergias (admin) |
| 155 | POST | `/admin/allergies` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Crear alergia |
| 156 | PATCH | `/admin/allergies/:allergyId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Actualizar alergia |
| 157 | DELETE | `/admin/allergies/:allergyId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Eliminar alergia |
| 158 | GET | `/admin/diseases` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Listar enfermedades (admin) |
| 159 | POST | `/admin/diseases` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Crear enfermedad |
| 160 | PATCH | `/admin/diseases/:diseaseId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Actualizar enfermedad |
| 161 | DELETE | `/admin/diseases/:diseaseId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Eliminar enfermedad |
| 162 | GET | `/admin/medicines` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Listar medicamentos (admin) |
| 163 | POST | `/admin/medicines` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Crear medicamento |
| 164 | PATCH | `/admin/medicines/:medicineId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Actualizar medicamento |
| 165 | DELETE | `/admin/medicines/:medicineId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Eliminar medicamento |
| 166 | GET | `/admin/ecclesiastical-years` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Listar anos eclesiasticos (admin) |
| 167 | POST | `/admin/ecclesiastical-years` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Crear ano eclesiastico |
| 168 | PATCH | `/admin/ecclesiastical-years/:yearId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Actualizar ano eclesiastico |
| 169 | DELETE | `/admin/ecclesiastical-years/:yearId` | AdminReferenceController | AdminReferenceService | JwtAuthGuard, PermissionsGuard | Eliminar ano eclesiastico |
| 170 | GET | `/admin/countries` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Listar paises (admin) |
| 171 | POST | `/admin/countries` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Crear pais |
| 172 | PATCH | `/admin/countries/:countryId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Actualizar pais |
| 173 | DELETE | `/admin/countries/:countryId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Eliminar pais |
| 174 | GET | `/admin/unions` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Listar uniones (admin) |
| 175 | POST | `/admin/unions` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Crear union |
| 176 | PATCH | `/admin/unions/:unionId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Actualizar union |
| 177 | DELETE | `/admin/unions/:unionId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Eliminar union |
| 178 | GET | `/admin/local-fields` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Listar campos locales (admin) |
| 179 | POST | `/admin/local-fields` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Crear campo local |
| 180 | PATCH | `/admin/local-fields/:localFieldId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Actualizar campo local |
| 181 | DELETE | `/admin/local-fields/:localFieldId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Eliminar campo local |
| 182 | GET | `/admin/districts` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Listar distritos (admin) |
| 183 | POST | `/admin/districts` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Crear distrito |
| 184 | PATCH | `/admin/districts/:districtId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Actualizar distrito |
| 185 | DELETE | `/admin/districts/:districtId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Eliminar distrito |
| 186 | GET | `/admin/churches` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Listar iglesias (admin) |
| 187 | POST | `/admin/churches` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Crear iglesia |
| 188 | PATCH | `/admin/churches/:churchId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Actualizar iglesia |
| 189 | DELETE | `/admin/churches/:churchId` | AdminGeographyController | AdminGeographyService | JwtAuthGuard, PermissionsGuard | Eliminar iglesia |
| 190 | GET | `/admin/users` | AdminUsersController | AdminUsersService | JwtAuthGuard, PermissionsGuard | Listar usuarios (admin con alcance) |
| 191 | GET | `/admin/users/:userId` | AdminUsersController | AdminUsersService | JwtAuthGuard, PermissionsGuard | Detalle de usuario (admin) |
| 192 | GET | `/classes` | ClassesController | ClassesService | OptionalJwtAuthGuard | Listar clases |
| 193 | GET | `/classes/:classId` | ClassesController | ClassesService | OptionalJwtAuthGuard | Obtener clase por ID |
| 194 | GET | `/classes/:classId/modules` | ClassesController | ClassesService | OptionalJwtAuthGuard | Modulos de una clase |
| 195 | GET | `/users/:userId/classes` | UserClassesController | ClassesService | JwtAuthGuard, PermissionsGuard | Inscripciones del usuario |
| 196 | POST | `/users/:userId/classes/enroll` | UserClassesController | ClassesService | JwtAuthGuard, PermissionsGuard | Inscribir en clase |
| 197 | GET | `/users/:userId/classes/:classId/progress` | UserClassesController | ClassesService | JwtAuthGuard, PermissionsGuard | Progreso en clase |
| 198 | PATCH | `/users/:userId/classes/:classId/progress` | UserClassesController | ClassesService | JwtAuthGuard, PermissionsGuard | Actualizar progreso en clase |

### Verificacion de conteo

Decoradores `@Get|@Post|@Put|@Delete|@Patch` encontrados por grep: **198 ocurrencias** en 25 archivos.
Filas en tabla: **198**. MATCH CONFIRMADO.

---

## Modelos de Datos

Schema: `prisma/schema.prisma`

| # | Model | Fields Count | Key Relations | Enums Used |
|---|-------|-------------|---------------|------------|
| 1 | activities | 20 | club_adventurers, club_master_guilds, club_pathfinders, activity_types, club_types, users | - |
| 2 | activity_types | 6 | activities[] | - |
| 3 | activity_instances | 7 | activities, club_adventurers, club_pathfinders, club_master_guilds | - |
| 4 | folder_assignments | 12 | folders, users | - |
| 5 | camporee_clubs | 10 | local_camporees, club_adventurers, club_master_guilds, club_pathfinders, local_fields | - |
| 6 | camporee_members | 11 | local_camporees, local_fields, users, member_insurances | - |
| 7 | churches | 5 | districts, clubs[] | - |
| 8 | class_module_progress | 8 | classes, enrollments, users | - |
| 9 | class_modules | 7 | classes, class_sections[] | - |
| 10 | class_section_progress | 10 | classes, enrollments, users | - |
| 11 | class_sections | 6 | class_modules | - |
| 12 | classes | 10 | club_types, enrollments[], users_classes[], class_modules[], class_module_progress[], class_section_progress[] | - |
| 13 | club_ideals | 7 | club_types | - |
| 14 | club_inventory | 10 | club_adventurers, club_master_guilds, club_pathfinders, inventory_categories | - |
| 15 | club_types | 5 | activities[], classes[], club_adventurers[], club_ideals[], club_master_guilds[], club_pathfinders[], finances[], folders[], honors[], units[] | - |
| 16 | clubs | 10 | club_adventurers[], club_master_guilds[], club_pathfinders[], churches, districts, local_fields | - |
| 17 | club_adventurers | 10 | club_types, clubs, activities[], club_inventory[], club_role_assignments[], finances[], units[] | - |
| 18 | club_pathfinders | 10 | club_types, clubs, activities[], club_inventory[], club_role_assignments[], finances[], units[] | - |
| 19 | club_master_guilds | 10 | club_types, clubs, activities[], club_inventory[], club_role_assignments[], finances[], units[] | - |
| 20 | club_role_assignments | 12 | club_adventurers, club_master_guilds, club_pathfinders, ecclesiastical_years, roles, users | - |
| 21 | countries | 5 | unions[], users[] | - |
| 22 | districts | 5 | churches[], clubs[], local_fields | - |
| 23 | ecclesiastical_years | 5 | club_role_assignments[], folders[], local_camporees[], union_camporees[], enrollments[], investiture_configs[] | - |
| 24 | enrollments | 17 | classes, ecclesiastical_years, users, investiture_validation_history[], class_module_progress[], class_section_progress[] | investiture_status_enum |
| 25 | error_logs | 4 | - | - |
| 26 | finances | 12 | club_adventurers, club_master_guilds, club_pathfinders, club_types, users, finances_categories | - |
| 27 | finances_categories | 6 | finances[] | - |
| 28 | folders | 11 | club_types, ecclesiastical_years, folder_assignments[], folders_modules[] | - |
| 29 | folders_modules | 9 | folders, folders_sections[] | - |
| 30 | folders_modules_records | 10 | club_adventurers, club_master_guilds, club_pathfinders, folders, folders_modules | - |
| 31 | folders_section_records | 12 | club_adventurers, club_master_guilds, club_pathfinders, folders, folders_modules, folders_sections | - |
| 32 | folders_sections | 8 | folders_modules, folders_section_records[] | - |
| 33 | honors | 13 | club_types, honors_categories, master_honors, users_honors[] | - |
| 34 | honors_categories | 6 | honors[] | - |
| 35 | inventory_categories | 5 | club_inventory[] | - |
| 36 | local_camporees | 14 | ecclesiastical_years, local_fields, camporee_clubs[], camporee_members[] | - |
| 37 | local_fields | 7 | unions, clubs[], districts[], local_camporees[], users[] | - |
| 38 | master_honors | 5 | honors[] | - |
| 39 | permissions | 6 | role_permissions[], users_permissions[] | - |
| 40 | role_permissions | 5 | permissions, roles | - |
| 41 | roles | 5 | club_role_assignments[], role_permissions[], users_roles[] | role_category |
| 42 | union_camporee_local_fields | 4 | local_fields, union_camporees | - |
| 43 | union_camporees | 12 | unions, ecclesiastical_years, union_camporee_local_fields[] | - |
| 44 | unions | 6 | countries, local_fields[], union_camporees[], users[] | - |
| 45 | unit_members | 5 | units, users | - |
| 46 | units | 10 | club_adventurers, club_master_guilds, club_pathfinders, club_types, users (x4), unit_members[] | - |
| 47 | users | 26 | countries, local_fields, unions, activities[], enrollments[], club_role_assignments[], users_classes[], users_honors[], users_allergies[], users_diseases[], users_medicines[], users_roles[], users_permissions[] | blood_type |
| 48 | user_fcm_tokens | 7 | users | - |
| 49 | users_pr | 8 | users | - |
| 50 | users_classes | 9 | classes, users | - |
| 51 | certifications | 7 | certification_modules[], users_certifications[] | - |
| 52 | certification_modules | 6 | certifications, certification_sections[] | - |
| 53 | certification_sections | 6 | certification_modules | - |
| 54 | users_certifications | 8 | certifications, users | - |
| 55 | certification_module_progress | 9 | certifications, users | - |
| 56 | certification_section_progress | 11 | certifications, users | - |
| 57 | member_insurances | 9 | users, camporee_members[] | insurance_type_enum |
| 58 | investiture_validation_history | 5 | enrollments, users | investiture_action_enum |
| 59 | investiture_config | 7 | local_fields, ecclesiastical_years | - |
| 60 | diseases | 5 | users_diseases[] | - |
| 61 | allergies | 5 | users_allergies[] | - |
| 62 | emergency_contacts | 9 | users (x2), relationship_types | - |
| 63 | weekly_records | 7 | users | - |
| 64 | users_allergies | 5 | allergies, users | - |
| 65 | users_diseases | 5 | diseases, users | - |
| 66 | users_medicines | 5 | medicines, users | - |
| 67 | users_honors | 9 | honors, users | - |
| 68 | users_permissions | 5 | permissions, users | - |
| 69 | users_roles | 5 | roles, users | - |
| 70 | medicines | 5 | users_medicines[] | - |
| 71 | relationship_types | 5 | emergency_contacts[], legal_representatives[] | - |
| 72 | legal_representatives | 9 | users (x2), relationship_types | - |

### Enums

| Enum | Values |
|------|--------|
| blood_type | A+, A-, B+, B-, AB+, AB-, O+, O- |
| gender | Masculino, Femenino |
| role_category | GLOBAL, CLUB |
| investiture_status_enum | IN_PROGRESS, SUBMITTED_FOR_VALIDATION, APPROVED, REJECTED, INVESTIDO |
| investiture_action_enum | SUBMITTED, APPROVED, REJECTED, REINVESTITURE_REQUESTED |
| insurance_type_enum | GENERAL_ACTIVITIES, CAMPOREE, HIGH_RISK |
| evidence_validation_enum | PENDING, VALIDATED, REJECTED |

### Verificacion de conteo

Declaraciones `model` en schema.prisma: **72**.
Filas en tabla: **72**. MATCH CONFIRMADO.

---

## Modulos NestJS

| # | Module | Controllers | Services | Imports | Exports |
|---|--------|-------------|----------|---------|---------|
| 1 | AppModule | AppController, HealthController | AppService, ThrottlerGuard (global) | ConfigModule, LoggerModule, ThrottlerModule, PrismaModule, CommonModule, AuthModule, UsersModule, EmergencyContactsModule, LegalRepresentativesModule, PostRegistrationModule, CatalogsModule, ClubsModule, ClassesModule, HonorsModule, ActivitiesModule, FinancesModule, CamporeesModule, NotificationsModule, CertificationsModule, FoldersModule, InventoryModule, RbacModule, AdminModule | - |
| 2 | CommonModule (Global) | - | TokenBlacklistService, SessionManagementService, MfaService, AuthorizationContextService, IpWhitelistGuard, PermissionsGuard, R2FileStorageService | CacheModule | CacheModule, TokenBlacklistService, SessionManagementService, MfaService, AuthorizationContextService, IpWhitelistGuard, PermissionsGuard, FILE_STORAGE_SERVICE |
| 3 | PrismaModule (Global) | - | PrismaService | - | PrismaService |
| 4 | FirebaseAdminModule | - | - | - | - |
| 5 | AuthModule | AuthController, MfaController, SessionsController, OAuthController | AuthService, OAuthService, JwtStrategy, SupabaseService, AuthorizationContextService | PassportModule, JwtModule | AuthService, OAuthService, JwtStrategy, PassportModule, AuthorizationContextService |
| 6 | UsersModule | UsersController | UsersService | - | UsersService |
| 7 | EmergencyContactsModule | EmergencyContactsController | EmergencyContactsService | - | - |
| 8 | LegalRepresentativesModule | LegalRepresentativesController | LegalRepresentativesService | UsersModule | LegalRepresentativesService |
| 9 | PostRegistrationModule | PostRegistrationController | PostRegistrationService | UsersModule, LegalRepresentativesModule | PostRegistrationService |
| 10 | CatalogsModule | CatalogsController | CatalogsService | PrismaModule | CatalogsService |
| 11 | ClubsModule | ClubsController, ClubRolesController | ClubsService, ClubRolesGuard | PrismaModule | ClubsService |
| 12 | ClassesModule | ClassesController, UserClassesController | ClassesService | PrismaModule | ClassesService |
| 13 | HonorsModule | HonorsController, UserHonorsController | HonorsService | PrismaModule | HonorsService |
| 14 | ActivitiesModule | ActivitiesController | ActivitiesService, ClubRolesGuard | PrismaModule | ActivitiesService |
| 15 | FinancesModule | FinancesController | FinancesService, ClubRolesGuard | PrismaModule | FinancesService |
| 16 | CamporeesModule | CamporeesController | CamporeesService, ClubRolesGuard | PrismaModule | CamporeesService |
| 17 | NotificationsModule | NotificationsController, FcmTokensController | NotificationsService, FcmTokensService | PrismaModule, FirebaseAdminModule | NotificationsService, FcmTokensService |
| 18 | CertificationsModule | CertificationsController | CertificationsService | PrismaModule | CertificationsService |
| 19 | FoldersModule | FoldersController | FoldersService | PrismaModule | FoldersService |
| 20 | InventoryModule | InventoryController | InventoryService | PrismaModule | InventoryService |
| 21 | RbacModule | RbacController | RbacService | PrismaModule | RbacService |
| 22 | AdminModule | AdminGeographyController, AdminReferenceController, AdminUsersController | AdminGeographyService, AdminReferenceService, AdminUsersService | PrismaModule | - |

---

## Infraestructura Compartida

Ubicacion: `src/common/`

### Guards

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Guard | JwtAuthGuard | `common/guards/jwt-auth.guard.ts` | AuthController, SessionsController, OAuthController, MfaController, UsersController, ClubsController, ClubRolesController, ActivitiesController, FinancesController, RbacController, NotificationsController, FcmTokensController, CamporeesController, EmergencyContactsController, LegalRepresentativesController, PostRegistrationController, CertificationsController, InventoryController, FoldersController, AdminReferenceController, AdminGeographyController, AdminUsersController, UserHonorsController, UserClassesController |
| Guard | OptionalJwtAuthGuard | `common/guards/optional-jwt-auth.guard.ts` | HonorsController, CatalogsController, ClassesController |
| Guard | PermissionsGuard | `common/guards/permissions.guard.ts` | UsersController, ClubsController, ClubRolesController, ActivitiesController, FinancesController, RbacController, NotificationsController, CamporeesController, EmergencyContactsController, LegalRepresentativesController, PostRegistrationController, CertificationsController, InventoryController, FoldersController, AdminReferenceController, AdminGeographyController, AdminUsersController, UserClassesController |
| Guard | ClubRolesGuard | `common/guards/club-roles.guard.ts` | ClubsController, ActivitiesController, FinancesController, CamporeesController |
| Guard | GlobalRolesGuard | `common/guards/global-roles.guard.ts` | (Disponible, no usado directamente en controllers escaneados) |
| Guard | OwnerOrAdminGuard | `common/guards/owner-or-admin.guard.ts` | UserHonorsController, FcmTokensController |
| Guard | IpWhitelistGuard | `common/guards/ip-whitelist.guard.ts` | (Registrado en CommonModule, no usado directamente en controllers) |

### Decorators

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Decorator | @CurrentUser | `common/decorators/current-user.decorator.ts` | AuthController |
| Decorator | @GetUser | `common/decorators/get-user.decorator.ts` | (Disponible) |
| Decorator | @ClubRoles | `common/decorators/club-roles.decorator.ts` | ClubsController, ActivitiesController, FinancesController |
| Decorator | @GlobalRoles | `common/decorators/global-roles.decorator.ts` | (Disponible) |
| Decorator | @RequirePermissions | `common/decorators/permissions.decorator.ts` | UsersController, ClubsController, ActivitiesController, FinancesController, RbacController, NotificationsController, CamporeesController, CertificationsController, InventoryController, FoldersController, AdminReferenceController, AdminGeographyController, AdminUsersController, UserClassesController |
| Decorator | @AuthorizationResource | `common/decorators/authorization-resource.decorator.ts` | UsersController, ClubsController, ClubRolesController, ActivitiesController, FinancesController, CamporeesController, CertificationsController, InventoryController, FoldersController, UserClassesController |
| Decorator | @SensitiveUserSubresource | `common/decorators/sensitive-user-subresource.decorator.ts` | UsersController, EmergencyContactsController, LegalRepresentativesController, PostRegistrationController |

### Services

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Service | TokenBlacklistService | `common/services/token-blacklist.service.ts` | SessionsController, CommonModule (exported) |
| Service | SessionManagementService | `common/services/session-management.service.ts` | SessionsController, CommonModule (exported) |
| Service | MfaService | `common/services/mfa.service.ts` | MfaController, CommonModule (exported) |
| Service | AuthorizationContextService | `common/services/authorization-context.service.ts` | AuthModule, CommonModule (exported) |
| Service | R2FileStorageService | `common/services/r2-file-storage.service.ts` | CommonModule (via FILE_STORAGE_SERVICE token) |
| Service | SupabaseService | `common/supabase.service.ts` | AuthModule |

### Pipes

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Pipe | SanitizePipe | `common/pipes/sanitize.pipe.ts` | Global (main.ts) |

### Filters

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Filter | AllExceptionsFilter | `common/filters/all-exceptions.filter.ts` | Global (main.ts) |
| Filter | HttpExceptionFilter | `common/filters/http-exception.filter.ts` | Global (main.ts) |

### Interceptors

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Interceptor | AuditInterceptor | `common/interceptors/audit.interceptor.ts` | Global (main.ts) |
| Interceptor | SentryInterceptor | `common/interceptors/sentry.interceptor.ts` | Global (main.ts, condicional a SENTRY_DSN) |

### DTOs

| Type | Name | Location | Used By |
|------|------|----------|---------|
| DTO | PaginationDto | `common/dto/pagination.dto.ts` | ClubsController, HonorsController, ActivitiesController, FinancesController, CamporeesController, CertificationsController, FoldersController, ClassesController |

### Policies

| Type | Name | Location | Used By |
|------|------|----------|---------|
| Policy | sensitive-user-subresource-policy | `common/guards/sensitive-user-subresource-policy.ts` | PermissionsGuard (via @SensitiveUserSubresource decorator) |

---

## Integraciones Externas

| # | Service | Package/SDK | Config Location | Used In Modules | Active |
|---|---------|-------------|----------------|-----------------|--------|
| 1 | Supabase Auth | `@supabase/supabase-js` | ENV: SUPABASE_URL, SUPABASE_KEY, SUPABASE_JWT_SECRET | AuthModule (SupabaseService), CommonModule (MfaService) | Si |
| 2 | Firebase Admin (FCM) | `firebase-admin` | ENV: FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 / FIREBASE_PROJECT_ID + FIREBASE_PRIVATE_KEY + FIREBASE_CLIENT_EMAIL | NotificationsModule (FirebaseAdminModule), HealthController | Si (condicional) |
| 3 | Sentry | `@sentry/node` | ENV: SENTRY_DSN | main.ts (global), SentryInterceptor | Si (condicional) |
| 4 | Redis (Upstash) | `redis` + `cache-manager-redis-yet` | ENV: REDIS_URL | CommonModule (CacheModule) - fallback a in-memory | Si (condicional) |
| 5 | Cloudflare R2 (S3-compatible) | `@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner` | ENV vars (R2 config) | CommonModule (R2FileStorageService) | Si |
| 6 | NestJS Cache Manager | `@nestjs/cache-manager` + `cache-manager` | CommonModule (CacheModule.registerAsync) | HealthController, TokenBlacklistService, SessionManagementService | Si |

### Middleware/Seguridad Global (main.ts)

| Feature | Package | Config |
|---------|---------|--------|
| Security Headers | `helmet` | CSP en produccion, deshabilitado en dev |
| Compression | `compression` | Habilitado global |
| Rate Limiting | `@nestjs/throttler` | 3/1s, 20/10s, 100/60s |
| Logging | `nestjs-pino` + `pino-pretty` | JSON en prod, pretty en dev |
| Validation | `class-validator` + `class-transformer` | whitelist, transform, forbidNonWhitelisted |
| API Versioning | NestJS built-in URI | `/api/v1` default |
| Swagger | `@nestjs/swagger` | Version 2.2.0, disponible en `/api` |
