# Plan de Desarrollo - Fase 2: App Movil Flutter

**Fecha**: 6 de febrero de 2026
**Duracion estimada**: 6 semanas (ajustable por microfase)
**Estado**: PLANIFICACION
**Prerequisito**: Fase 1 (Backend API) COMPLETADA - 105+ endpoints, 17 modulos

---

## Resumen de Alineacion

La Fase 2 se alinea al 100% con la documentacion existente:

- **Roadmap** (`docs/03-IMPLEMENTATION-ROADMAP.md`): Define Sprint 9-14 para la app movil
- **Procesos** (`docs/02-PROCESSES.md`): Documenta flujos detallados de Auth, Post-Registro (3 pasos) y Seleccion de Club
- **Endpoints** (`docs/02-API/ENDPOINTS-REFERENCE.md`): 105+ endpoints listos para consumir
- **Integracion** (`docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`): Ejemplos de codigo Flutter para cada modulo
- **Tech Stack** (`docs/00-STEERING/tech.md`): Flutter 3.x + Riverpod + Dio + Clean Architecture
- **Producto** (`docs/00-STEERING/product.md`): 20 features MVP definidas con business logic

### Estado Actual de la App

La app ya tiene implementado (49 archivos Dart):

- Clean Architecture con capas domain/data/presentation
- Riverpod para state management
- Dio HTTP client con interceptores (auth, error, logger)
- Supabase Auth (login/register basico)
- Secure Storage + Shared Preferences
- Sistema de temas (light/dark)
- GoRouter para navegacion
- 2 features: Auth (login/register) y Home (dashboard basico)

---

## Arquitectura de Referencia

```
lib/
  core/                         # Ya implementado
    auth/                       # Supabase auth
    constants/                  # Constantes
    config/                     # Configuracion
    errors/                     # Excepciones y failures
    network/                    # Dio client + interceptors
    storage/                    # Local + secure storage
    theme/                      # App theme
    usecases/                   # Base usecase
    utils/                      # Extensions, validators
    widgets/                    # Widgets reutilizables

  features/                     # Por implementar/completar
    auth/                       # Ya existe (completar OAuth + password reset)
    post_registration/          # NUEVO - Onboarding 3 pasos
    profile/                    # NUEVO - Perfil de usuario
    club/                       # NUEVO - Info del club
    classes/                    # NUEVO - Clases progresivas
    honors/                     # NUEVO - Especialidades
    activities/                 # NUEVO - Actividades del club
    dashboard/                  # NUEVO - Dashboard principal

  providers/                    # Ya implementado
    dio_provider.dart
    storage_provider.dart
    supabase_provider.dart

  shared/                       # NUEVO
    widgets/                    # Widgets compartidos entre features
    models/                     # Modelos compartidos (User, Club, etc.)
```

---

## MICROFASE 1: Completar Auth + Infraestructura Base (Semana 1)

### Objetivo
Completar el modulo de autenticacion con todas las funcionalidades documentadas y preparar la infraestructura compartida.

### 1.1 Completar Flujo de Autenticacion

**Archivos a crear/modificar**:

```
lib/features/auth/
  data/
    datasources/auth_remote_data_source.dart    # Modificar: agregar OAuth, password reset
    models/user_model.dart                       # Modificar: alinear con API response
  domain/
    usecases/
      sign_in_with_google.dart                   # NUEVO
      sign_in_with_apple.dart                    # NUEVO
      reset_password_request.dart                # NUEVO
      reset_password.dart                        # NUEVO
      check_session.dart                         # NUEVO
  presentation/
    views/
      forgot_password_view.dart                  # NUEVO
      splash_view.dart                           # NUEVO
    providers/
      auth_providers.dart                        # Modificar: agregar nuevos providers
```

**Endpoints a consumir**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/auth/login` | POST | Login con email/password |
| `/auth/register` | POST | Registro con nombre, apellidos, email, password |
| `/auth/logout` | POST | Cerrar sesion |
| `/auth/password/reset-request` | POST | Solicitar recovery email |
| `/auth/password/reset` | POST | Confirmar nueva password |
| `/auth/me` | GET | Obtener usuario actual con roles |
| `/auth/profile/completion-status` | GET | Verificar estado post-registro |
| `/auth/oauth/google` | POST | Iniciar OAuth con Google |
| `/auth/oauth/apple` | POST | Iniciar OAuth con Apple |

**Validaciones** (de `docs/02-PROCESSES.md`):
- Al login exitoso, verificar si `needsPostRegistration: true` para redirigir
- Almacenar token y UUID en secure storage
- Si no se puede usar secure storage, omitir almacenamiento por seguridad
- Al cerrar sesion, limpiar secure storage completamente

### 1.2 Splash Screen con Verificacion de Sesion

**Logica** (de `docs/02-PROCESSES.md` - Proceso 1):
1. App inicia -> verificar si existe sesion en Supabase
2. Si sesion existe -> verificar `/auth/profile/completion-status`
   - Si `complete: false` -> redirigir a post-registro (al paso pendiente)
   - Si `complete: true` -> redirigir a dashboard
3. Si sesion no existe -> mostrar login

### 1.3 Infraestructura Compartida

**Archivos a crear**:

```
lib/shared/
  widgets/
    app_scaffold.dart                 # Scaffold base con configuracion comun
    loading_overlay.dart              # Overlay de carga reutilizable
    error_widget.dart                 # Widget de error estandarizado
    empty_state_widget.dart           # Estado vacio
  models/
    api_response.dart                 # Modelo generico de respuesta API
    paginated_response.dart           # Modelo para respuestas paginadas
```

**Configurar GoRouter completo**:

```
lib/core/config/
  router.dart                         # Modificar: rutas completas de la app
  route_names.dart                    # NUEVO: constantes de rutas
```

**Rutas necesarias**:

```
/                       -> Splash (verificacion de sesion)
/login                  -> Login
/register               -> Registro
/forgot-password        -> Recuperar password
/post-registration      -> Onboarding (3 pasos)
/home                   -> Dashboard (con bottom nav)
  /home/dashboard       -> Tab dashboard
  /home/classes         -> Tab clases
  /home/activities      -> Tab actividades
  /home/profile         -> Tab perfil
/club                   -> Detalle de club
/class/:id              -> Detalle de clase
/honor/:id              -> Detalle de honor
```

### Entregable Microfase 1
- Login, registro, OAuth (Google/Apple), recuperar password funcionando
- Splash con verificacion de sesion y redireccion inteligente
- Infraestructura compartida lista (widgets, modelos, router)
- Navegacion completa configurada

---

## MICROFASE 2: Post-Registro - Paso 1 Fotografia (Semana 2, parte 1)

### Objetivo
Implementar el onboarding de post-registro: paso 1 (fotografia de perfil).

### 2.1 Estructura del Feature

```
lib/features/post_registration/
  data/
    datasources/
      post_registration_remote_data_source.dart    # Llamadas a API
    models/
      completion_status_model.dart                  # Estado de completitud
    repositories/
      post_registration_repository_impl.dart
  domain/
    entities/
      completion_status.dart                        # Entity
    repositories/
      post_registration_repository.dart             # Interface
    usecases/
      get_completion_status.dart
      upload_profile_picture.dart
      delete_profile_picture.dart
  presentation/
    providers/
      post_registration_providers.dart
      photo_step_providers.dart
    views/
      post_registration_shell.dart                  # Shell con indicadores + botones
      photo_step_view.dart                          # Paso 1
    widgets/
      step_indicator.dart                           # Indicador de progreso
      bottom_navigation_buttons.dart                # Regresar/Continuar (anclados abajo)
      profile_photo_picker.dart                     # Selector de foto
```

### 2.2 Shell del Post-Registro

**De `docs/02-PROCESSES.md`**:
- Seccion fija en la parte inferior con botones `Regresar` y `Continuar`
- `Regresar` NO se muestra en el primer paso
- `Continuar` NO se muestra si el proceso termino
- `Continuar` se bloquea hasta completar el paso actual
- Indicadores de progreso en la parte superior (3 pasos)

### 2.3 Paso 1: Fotografia de Perfil

**Endpoints**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/auth/profile/completion-status` | GET | Verificar que paso completar |
| `/users/:userId/post-registration/photo-status` | GET | Estado de la foto |
| `/users/:userId/profile-picture` | POST | Subir foto (multipart) |
| `/users/:userId/profile-picture` | DELETE | Eliminar foto |

**Flujo** (de `docs/02-PROCESSES.md` - Post-Registro Proceso 1):
1. Verificar si el usuario ya completo este paso -> si ya completo, saltar al paso 2
2. Bloquear boton `Continuar`
3. Mostrar opcion "Elegir fotografia de perfil"
4. Mostrar opciones: "Tomar fotografia" / "Seleccionar fotografia"
5. Si toma foto -> abrir camara (solicitar permiso)
6. Si selecciona foto -> abrir galeria (solicitar permiso)
7. En ambos casos -> mostrar `image_cropper`:
   - Comprimir imagen al 70%
   - Recortar en formato cuadrado
8. Mostrar "Confirmar imagen" -> subir al backend
   - Bucket: `profile-pictures`
   - Nombre: `photo-{uuid}.{ext}`
9. Si exitoso -> desbloquear `Continuar` + notificar backend que paso 1 esta completo
10. Si error -> mostrar mensaje, reiniciar proceso

**Dependencias Flutter necesarias**:

```yaml
# Agregar a pubspec.yaml
dependencies:
  image_picker: ^1.0.7        # Seleccion de imagen (camara/galeria)
  image_cropper: ^5.0.1       # Recorte cuadrado + compresion
  permission_handler: ^11.3.0  # Permisos de camara y galeria
```

### Entregable Microfase 2
- Shell de post-registro con indicadores y botones fijos
- Paso 1 completo: camara, galeria, cropper, upload
- Persistencia de progreso (si se sale de la app, no repite pasos completados)

---

## MICROFASE 3: Post-Registro - Paso 2 Info Personal (Semana 2, parte 2 + Semana 3, parte 1)

### Objetivo
Implementar paso 2 del post-registro: informacion personal, contactos de emergencia, representante legal, alergias y enfermedades.

### 3.1 Archivos Nuevos

```
lib/features/post_registration/
  data/
    datasources/
      personal_info_remote_data_source.dart
    models/
      emergency_contact_model.dart
      legal_representative_model.dart
      allergy_model.dart
      disease_model.dart
      relationship_type_model.dart
  domain/
    entities/
      emergency_contact.dart
      legal_representative.dart
    usecases/
      update_personal_info.dart
      get_emergency_contacts.dart
      add_emergency_contact.dart
      update_emergency_contact.dart
      delete_emergency_contact.dart
      get_relationship_types.dart
      check_legal_representative_required.dart
      create_legal_representative.dart
      get_allergies_catalog.dart
      save_user_allergies.dart
      get_diseases_catalog.dart
      save_user_diseases.dart
      complete_step_2.dart
  presentation/
    providers/
      personal_info_providers.dart
    views/
      personal_info_step_view.dart                 # Paso 2 principal
      emergency_contacts_view.dart                 # Pantalla emergente contactos
      add_edit_contact_view.dart                   # Formulario contacto
      allergies_selection_view.dart                 # Seleccion alergias
      diseases_selection_view.dart                  # Seleccion enfermedades
      legal_representative_view.dart                # Formulario rep. legal (condicional)
    widgets/
      contact_card.dart                             # Tarjeta de contacto
      searchable_selection_list.dart                # Lista con buscador
```

### 3.2 Formulario de Informacion Personal

**Endpoints**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/users/:userId` | PATCH | Actualizar genero, birthdate, bautismo |
| `/users/:userId/emergency-contacts` | GET | Listar contactos |
| `/users/:userId/emergency-contacts` | POST | Crear contacto |
| `/emergency-contacts/:contactId` | PATCH | Editar contacto |
| `/emergency-contacts/:contactId` | DELETE | Eliminar contacto |
| `/users/:userId/requires-legal-representative` | GET | Verificar si requiere rep. legal |
| `/users/:userId/legal-representative` | POST | Crear rep. legal |
| `/users/:userId/legal-representative` | GET | Obtener rep. legal |
| `/users/:userId/legal-representative` | PATCH | Editar rep. legal |
| `/users/:userId/allergies` | GET/POST | Alergias del usuario |
| `/users/:userId/diseases` | GET/POST | Enfermedades del usuario |
| `/users/:userId/post-registration/complete-step-2` | POST | Completar paso 2 |

**Campos del formulario** (de `docs/02-PROCESSES.md` - Proceso 2):

1. **Genero**: Solo 'Masculino' o 'Femenino'
2. **Fecha de nacimiento**: Minimo 3 anios, maximo 99 anios (validacion frontend)
3. **Bautismo**: Booleano
   - Si `true` -> mostrar campo "Fecha de bautismo"
4. **Contactos de emergencia** (maximo 5):
   - Boton para abrir pantalla emergente
   - Lista de contactos existentes con opciones Editar/Eliminar
   - Formulario: nombre, tipo de relacion (dropdown), telefono
   - Confirmacion antes de eliminar
5. **Representante legal** (condicional si edad < 18):
   - Tipo: padre, madre, tutor
   - Nombre, apellidos, telefono
6. **Enfermedades**: Lista con opcion "Ninguna" + buscador
   - Seleccion multiple
   - "Ninguna" deselecciona todo lo demas
7. **Alergias**: Lista con opcion "Ninguna" + buscador
   - Seleccion multiple
   - "Ninguna" deselecciona todo lo demas

**Validaciones** (de `docs/02-PROCESSES.md`):
- Formato fechas: `YYYY-MM-DD`
- Maximo 5 contactos de emergencia (validado backend tambien)
- No duplicar contactos ya relacionados
- Contactos eliminados: borrado logico con dialogo de confirmacion
- `Continuar` solo se desbloquea cuando todos los campos obligatorios estan completos

### Entregable Microfase 3
- Formulario de informacion personal completo
- CRUD de contactos de emergencia con validaciones
- Representante legal condicional (menores de 18)
- Seleccion de alergias y enfermedades con buscador
- Persistencia de progreso del paso 2

---

## MICROFASE 4: Post-Registro - Paso 3 Seleccion de Club (Semana 3, parte 2)

### Objetivo
Implementar paso 3 del post-registro: cascading dropdowns para seleccion de club.

### 4.1 Archivos Nuevos

```
lib/features/post_registration/
  data/
    datasources/
      club_selection_remote_data_source.dart
    models/
      country_model.dart
      union_model.dart
      local_field_model.dart
      club_model.dart
      club_instance_model.dart
      class_model.dart
  domain/
    usecases/
      get_countries.dart
      get_unions_by_country.dart
      get_local_fields_by_union.dart
      get_clubs_by_local_field.dart
      get_club_instances.dart
      get_classes_by_club_type.dart
      complete_step_3.dart
  presentation/
    providers/
      club_selection_providers.dart
    views/
      club_selection_step_view.dart
    widgets/
      cascading_dropdown.dart                      # Dropdown con auto-seleccion
      club_type_selector.dart                      # Selector de tipo de club
      class_recommendation.dart                    # Mensaje de recomendacion por edad
```

### 4.2 Logica de Cascading Dropdowns

**Endpoints**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/catalogs/countries` | GET | Listado de paises |
| `/catalogs/unions?countryId=` | GET | Uniones por pais |
| `/catalogs/local-fields?unionId=` | GET | Campos locales por union |
| `/catalogs/local-fields/:localFieldId/clubs` | GET | Clubs por campo local |
| `/clubs/:clubId/instances` | GET | Instancias del club (tipos) |
| `/catalogs/classes?clubTypeId=` | GET | Clases por tipo de club |
| `/users/:userId/post-registration/complete-step-3` | POST | Completar paso 3 |

**Flujo** (de `docs/02-PROCESSES.md` - Proceso 3):

1. **Pais**: Consultar listado
   - Si solo 1 resultado -> auto-seleccionar y deshabilitar
   - Si multiples -> usuario selecciona
2. **Union**: Consultar por pais seleccionado
   - Misma logica de auto-seleccion si solo 1
3. **Campo Local**: Consultar por union seleccionada
   - Misma logica de auto-seleccion si solo 1
4. **Club**: Consultar por campo local seleccionado
   - Misma logica
5. **Tipo de Club**: Consultar instancias del club
   - Pre-seleccionar segun edad:
     - 4-9 anios -> Aventureros
     - 10-15 anios -> Conquistadores
     - 16+ anios -> Guias Mayores
   - Mostrar mensaje recomendando tipo de club segun edad
   - Aclarar que aprobacion esta sujeta a directivos
6. **Clase**: Consultar clases del tipo de club
   - Recomendar clase segun edad
7. Al completar -> enviar datos al backend (transaccion):
   - Actualizar pais, union, campo local en users
   - Crear club_role_assignments con rol "member" + anio eclesiastico
   - Inscribir en clase (users_classes)
   - Marcar users_pr.complete = true
8. Si exitoso -> redirigir al dashboard
9. Si error -> permanecer en pantalla

### Entregable Microfase 4
- Cascading dropdowns con auto-seleccion inteligente
- Recomendacion de tipo de club y clase por edad
- Envio transaccional del paso 3
- Redireccion al dashboard tras completar post-registro

---

## MICROFASE 5: Dashboard + Navegacion Principal (Semana 4)

### Objetivo
Implementar el dashboard principal y la navegacion con bottom bar.

### 5.1 Archivos Nuevos

```
lib/features/dashboard/
  data/
    datasources/
      dashboard_remote_data_source.dart
    models/
      dashboard_summary_model.dart
    repositories/
      dashboard_repository_impl.dart
  domain/
    entities/
      dashboard_summary.dart
    repositories/
      dashboard_repository.dart
    usecases/
      get_dashboard_data.dart
  presentation/
    providers/
      dashboard_providers.dart
    views/
      main_shell_view.dart                         # Shell con bottom nav
      dashboard_view.dart                          # Tab principal
    widgets/
      welcome_header.dart                          # Saludo + foto de perfil
      club_info_card.dart                          # Tarjeta info del club
      current_class_card.dart                      # Clase actual + progreso
      upcoming_activities_card.dart                 # Proximas actividades
      quick_stats_card.dart                        # Estadisticas rapidas
```

### 5.2 Dashboard Principal

**Endpoints a consumir**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/auth/me` | GET | Datos del usuario + roles |
| `/users/:userId/classes` | GET | Clases inscritas |
| `/clubs/:clubId/activities` | GET | Actividades del club |
| `/users/:userId/honors/stats` | GET | Estadisticas de honores |

**Componentes del Dashboard**:

1. **Header de bienvenida**: Foto de perfil + nombre + saludo segun hora del dia
2. **Tarjeta de Club**: Nombre del club, tipo, rol del usuario
3. **Clase Actual**: Nombre de la clase, progreso (% completado)
4. **Proximas Actividades**: Lista de las 3 proximas actividades del club
5. **Estadisticas Rapidas**: Honores completados, asistencias, etc.

### 5.3 Bottom Navigation Bar

**Tabs**:

| Tab | Icono | Vista | Descripcion |
|-----|-------|-------|-------------|
| Inicio | home | DashboardView | Dashboard principal |
| Clases | school | ClassesListView | Clases + progreso |
| Actividades | event | ActivitiesListView | Actividades del club |
| Perfil | person | ProfileView | Perfil y configuracion |

### 5.4 Push Notifications (FCM)

**Configurar en esta microfase**:

```
lib/core/
  notifications/
    fcm_service.dart                               # Servicio FCM
    notification_handler.dart                      # Manejo de notificaciones
```

**Endpoints**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/users/:userId/fcm-tokens` | POST | Registrar token FCM |
| `/users/:userId/fcm-tokens` | GET | Listar tokens |
| `/fcm-tokens/:tokenId` | DELETE | Eliminar token |

**Dependencias**:

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_messaging: ^15.2.1
  flutter_local_notifications: ^18.0.1
```

### Entregable Microfase 5
- Dashboard con informacion real del usuario, club y progreso
- Bottom navigation con 4 tabs
- Push notifications configuradas y registrando token FCM
- Shell principal de la app

---

## MICROFASE 6: Perfil de Usuario + Configuracion (Semana 4, parte 2)

### Objetivo
Implementar la vista de perfil del usuario con edicion y configuracion.

### 6.1 Archivos Nuevos

```
lib/features/profile/
  data/
    datasources/
      profile_remote_data_source.dart
    models/
      user_detail_model.dart
    repositories/
      profile_repository_impl.dart
  domain/
    entities/
      user_detail.dart
    repositories/
      profile_repository.dart
    usecases/
      get_user_profile.dart
      update_user_profile.dart
      update_profile_picture.dart
      get_club_info.dart
  presentation/
    providers/
      profile_providers.dart
    views/
      profile_view.dart                            # Vista principal del perfil
      edit_profile_view.dart                       # Edicion de datos personales
      club_detail_view.dart                        # Detalle del club
      settings_view.dart                           # Configuraciones
    widgets/
      profile_header.dart                          # Foto + nombre + rol
      info_section.dart                            # Seccion de informacion
      setting_tile.dart                            # Tile de configuracion
```

### 6.2 Secciones del Perfil

**Datos visibles**:
- Foto de perfil (editable)
- Nombre completo
- Email
- Genero, fecha de nacimiento
- Club actual + tipo + rol
- Clase actual
- Estado de bautismo

**Configuracion**:
- Cambiar foto de perfil
- Editar informacion personal
- Cambiar tema (light/dark) - ya implementado parcialmente
- Cerrar sesion
- Version de la app

### Entregable Microfase 6
- Vista de perfil completa con datos del usuario
- Edicion de perfil (foto, datos personales)
- Vista de configuracion con cerrar sesion
- Detalle del club con info basica

---

## MICROFASE 7: Clases Progresivas + Progreso (Semana 5, parte 1)

### Objetivo
Implementar listado de clases, detalle de clase y tracking de progreso.

### 7.1 Archivos Nuevos

```
lib/features/classes/
  data/
    datasources/
      classes_remote_data_source.dart
    models/
      class_model.dart
      class_module_model.dart
      class_section_model.dart
      class_progress_model.dart
    repositories/
      classes_repository_impl.dart
  domain/
    entities/
      progressive_class.dart
      class_module.dart
      class_section.dart
      class_progress.dart
    repositories/
      classes_repository.dart
    usecases/
      get_user_classes.dart
      get_class_detail.dart
      get_class_modules.dart
      get_class_progress.dart
      update_class_progress.dart
  presentation/
    providers/
      classes_providers.dart
    views/
      classes_list_view.dart                       # Tab de clases
      class_detail_view.dart                       # Detalle de clase
      class_modules_view.dart                      # Modulos de la clase
      section_detail_view.dart                     # Detalle de seccion
    widgets/
      class_card.dart                              # Tarjeta de clase
      module_expansion_tile.dart                   # Tile expandible de modulo
      section_checkbox.dart                        # Checkbox de seccion
      progress_ring.dart                           # Anillo de progreso
```

### 7.2 Funcionalidad

**Endpoints**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/classes` | GET | Catalogo de clases (query: clubTypeId) |
| `/classes/:classId` | GET | Detalle de clase |
| `/classes/:classId/modules` | GET | Modulos de la clase |
| `/users/:userId/classes` | GET | Clases del usuario |
| `/users/:userId/classes/:classId/progress` | GET | Progreso |
| `/users/:userId/classes/:classId/progress` | PATCH | Actualizar progreso |

**Vistas**:

1. **Lista de Clases**: Tarjetas con nombre, progreso %, estado
2. **Detalle de Clase**: Info general + lista de modulos
3. **Modulos**: Tiles expandibles con secciones
4. **Secciones**: Checkboxes con tracking de completitud

### Entregable Microfase 7
- Lista de clases inscritas con progreso visual
- Detalle de clase con modulos y secciones
- Actualizacion de progreso
- Anillo de progreso y visual feedback

---

## MICROFASE 8: Honores / Especialidades (Semana 5, parte 2)

### Objetivo
Implementar catalogo de honores, inscripcion y tracking de progreso.

### 8.1 Archivos Nuevos

```
lib/features/honors/
  data/
    datasources/
      honors_remote_data_source.dart
    models/
      honor_model.dart
      honor_category_model.dart
      user_honor_model.dart
    repositories/
      honors_repository_impl.dart
  domain/
    entities/
      honor.dart
      honor_category.dart
      user_honor.dart
    repositories/
      honors_repository.dart
    usecases/
      get_honor_categories.dart
      get_honors.dart
      get_honor_detail.dart
      get_user_honors.dart
      get_user_honors_stats.dart
      start_honor.dart
      update_honor_progress.dart
      abandon_honor.dart
  presentation/
    providers/
      honors_providers.dart
    views/
      honors_catalog_view.dart                     # Catalogo por categorias
      honor_detail_view.dart                       # Detalle del honor
      my_honors_view.dart                          # Mis honores
    widgets/
      honor_category_card.dart
      honor_card.dart
      honor_progress_card.dart
      honor_requirements_list.dart
```

### 8.2 Funcionalidad

**Endpoints**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/honors/categories` | GET | Categorias de honores |
| `/honors` | GET | Listado (query: categoryId, clubTypeId, skillLevel) |
| `/honors/:honorId` | GET | Detalle del honor |
| `/users/:userId/honors` | GET | Honores del usuario |
| `/users/:userId/honors/stats` | GET | Estadisticas |
| `/users/:userId/honors/:honorId` | POST | Iniciar honor |
| `/users/:userId/honors/:honorId` | PATCH | Actualizar progreso |
| `/users/:userId/honors/:honorId` | DELETE | Abandonar honor |

**Vistas**:
1. **Catalogo**: Grid de categorias -> lista de honores por categoria
2. **Detalle**: Info, requisitos, boton de inscripcion
3. **Mis Honores**: Lista de honores en progreso + completados + stats

### Entregable Microfase 8
- Catalogo de honores navegable por categorias
- Detalle de honor con requisitos
- Inscripcion y tracking de progreso
- Vista "Mis Honores" con estadisticas

---

## MICROFASE 9: Actividades del Club (Semana 6, parte 1)

### Objetivo
Implementar listado de actividades, detalle y registro de asistencia.

### 9.1 Archivos Nuevos

```
lib/features/activities/
  data/
    datasources/
      activities_remote_data_source.dart
    models/
      activity_model.dart
      attendance_model.dart
    repositories/
      activities_repository_impl.dart
  domain/
    entities/
      activity.dart
      attendance.dart
    repositories/
      activities_repository.dart
    usecases/
      get_club_activities.dart
      get_activity_detail.dart
      register_attendance.dart
      get_activity_attendance.dart
  presentation/
    providers/
      activities_providers.dart
    views/
      activities_list_view.dart                    # Tab de actividades
      activity_detail_view.dart                    # Detalle de actividad
    widgets/
      activity_card.dart                           # Tarjeta de actividad
      attendance_button.dart                       # Boton de asistencia
      activity_info_row.dart                       # Fila de informacion
```

### 9.2 Funcionalidad

**Endpoints**:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/clubs/:clubId/activities` | GET | Actividades del club (filtros) |
| `/activities/:activityId` | GET | Detalle |
| `/activities/:activityId/attendance` | POST | Registrar asistencia |
| `/activities/:activityId/attendance` | GET | Lista de asistencia |

**Vistas**:
1. **Lista**: Actividades ordenadas por fecha, filtro por tipo
2. **Detalle**: Fecha, hora, ubicacion, descripcion, asistencia
3. **Asistencia**: Boton para registrar/confirmar asistencia propia

### Entregable Microfase 9
- Lista de actividades del club con filtros
- Detalle de actividad con toda la informacion
- Registro de asistencia del usuario

---

## MICROFASE 10: Offline Mode + Pulido Final (Semana 6, parte 2)

### Objetivo
Implementar cache offline basico, pulido visual y preparacion para release.

### 10.1 Cache Offline

```
lib/core/
  cache/
    cache_manager.dart                             # Gestor de cache
    cache_interceptor.dart                         # Interceptor Dio para cache
```

**Estrategia**:
- Cache de datos criticos: perfil de usuario, clases, club info
- Usar SharedPreferences para datos ligeros
- Mostrar datos cacheados cuando no hay conexion
- Indicador visual de modo offline
- Sincronizar al recuperar conexion

**Dependencia**:

```yaml
dependencies:
  connectivity_plus: ^6.1.4     # Ya instalado - detectar conectividad
```

### 10.2 Pulido Visual

- Animaciones de transicion entre pantallas
- Estados de carga consistentes (shimmer/skeleton)
- Manejo de errores consistente en toda la app
- Empty states para listas vacias
- Pull-to-refresh en listas principales

### 10.3 Testing

```
test/
  features/
    auth/
      data/datasources/auth_remote_data_source_test.dart
      domain/usecases/sign_in_test.dart
      presentation/providers/auth_providers_test.dart
    post_registration/
      ...
    dashboard/
      ...
  core/
    network/dio_client_test.dart
```

**Tipos de test**:
- Unit tests para usecases y repositories
- Widget tests para vistas principales
- Integration tests para flujos criticos (auth, post-registro)

### 10.4 Build y Verificacion

```bash
# Verificar analisis
flutter analyze

# Ejecutar tests
flutter test

# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Entregable Microfase 10
- Cache offline basico funcionando
- UI pulida con animaciones y estados de carga
- Tests unitarios y de widget para flujos criticos
- Builds de APK e IPA exitosos
- App lista para testing en dispositivos reales

---

## Resumen de Microfases

| # | Microfase | Semana | Endpoints | Archivos Nuevos |
|---|-----------|--------|-----------|-----------------|
| 1 | Auth Completo + Infraestructura | S1 | 9 | ~15 |
| 2 | Post-Registro Paso 1 (Foto) | S2.1 | 4 | ~12 |
| 3 | Post-Registro Paso 2 (Info Personal) | S2.2-S3.1 | 12 | ~25 |
| 4 | Post-Registro Paso 3 (Seleccion Club) | S3.2 | 7 | ~15 |
| 5 | Dashboard + Bottom Nav + FCM | S4.1 | 7 | ~15 |
| 6 | Perfil + Configuracion | S4.2 | 4 | ~12 |
| 7 | Clases Progresivas | S5.1 | 6 | ~18 |
| 8 | Honores / Especialidades | S5.2 | 8 | ~18 |
| 9 | Actividades del Club | S6.1 | 4 | ~12 |
| 10 | Offline + Pulido + Testing | S6.2 | 0 | ~10 |

**Total**: ~61 endpoints consumidos, ~152 archivos nuevos estimados

---

## Dependencias a Agregar (pubspec.yaml)

```yaml
# Ya instaladas (no agregar):
# flutter_riverpod, dio, supabase_flutter, go_router,
# flutter_secure_storage, shared_preferences, dartz,
# equatable, intl, logger, connectivity_plus, cached_network_image

# Agregar para Fase 2:
dependencies:
  image_picker: ^1.0.7           # Microfase 2 - Seleccion de foto
  image_cropper: ^5.0.1          # Microfase 2 - Recorte cuadrado
  permission_handler: ^11.3.0    # Microfase 2 - Permisos camara/galeria
  firebase_core: ^3.8.1          # Microfase 5 - FCM
  firebase_messaging: ^15.2.1    # Microfase 5 - Push notifications
  flutter_local_notifications: ^18.0.1  # Microfase 5 - Notificaciones locales
  shimmer: ^3.0.0                # Microfase 10 - Skeleton loading
```

---

## Criterios de Completitud (de `docs/03-IMPLEMENTATION-ROADMAP.md`)

- [ ] Login, registro, post-registro completos
- [ ] Dashboard funcional
- [ ] Offline mode basico
- [ ] Build de APK/IPA exitoso
- [ ] Testeado en Android + iOS

---

## Evidencia de Fuentes Consultadas

| Documento | Ruta | Uso |
|-----------|------|-----|
| Implementation Roadmap | `docs/03-IMPLEMENTATION-ROADMAP.md` | Sprint structure, Phase 2 criteria |
| Business Processes | `docs/02-PROCESSES.md` | Auth flows, Post-registration steps (detailed) |
| System Overview | `docs/01-OVERVIEW.md` | Architecture, modules, RBAC, hierarchy |
| Product Vision | `docs/00-STEERING/product.md` | MVP features, user personas, business logic |
| Tech Stack | `docs/00-STEERING/tech.md` | Flutter architecture, Riverpod, Dio |
| Coding Standards | `docs/00-STEERING/coding-standards.md` | SOLID, async patterns, error handling |
| Project Structure | `docs/00-STEERING/structure.md` | Clean Architecture layers |
| Endpoints Reference | `docs/02-API/ENDPOINTS-REFERENCE.md` | All 105+ endpoints detail |
| Frontend Integration | `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md` | Flutter code examples |
| API Specification | `docs/02-API/API-SPECIFICATION.md` | DTOs, validation, response formats |
| Database Schema | `docs/03-DATABASE/schema.prisma` | 87 models, relationships |
| Existing Flutter App | `sacdia-app/lib/` | Current 49 files, architecture review |
| Flutter CLAUDE.md | `sacdia-app/CLAUDE.md` | Commands, architecture pattern |

---

**Creado**: 2026-02-06
**Autor**: Claude (Planning Review)
**Estado**: PENDIENTE APROBACION
**Proxima accion**: Aprobacion del plan -> Iniciar Microfase 1
