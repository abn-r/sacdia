# Lista de Tareas - SACDIA App

## Módulo de Autenticación (HU-AUTH-001, 002, 003)
- [X] **Diseñar UI:** Pantallas de Registro, Inicio de Sesión, Olvidé Contraseña.
- [X] **Implementar Lógica Registro:** Función para registrar usuarios vía API (RF-AUTH-001-03).
- [X] **Implementar Lógica Inicio Sesión:** Función para autenticar con Supabase (RF-AUTH-002-02).
- [X] **Implementar Lógica Recuperar Contraseña:** Función para iniciar flujo con Supabase (RF-AUTH-003-02).
- [X] **Integrar UI y Lógica:** Conectar pantallas con Blocs/Repositorios.
- [X] **Gestión Estado Auth:** Manejar estados (autenticado, no autenticado, post-registro pendiente).
- [ ] **Mejorar Manejo Errores:** Mensajes más específicos y feedback al usuario (ej. RF-AUTH-001-04, RF-AUTH-002-05).
- [ ] **Pruebas Unitarias/Widget:** Escribir pruebas para Blocs y pantallas de autenticación.

## Módulo Post-Registro (HU-POSTREG-001)
- [X] **Diseñar UI:** Flujo Stepper con pasos definidos (Foto, Personal, Club).
- [X] **Implementar Lógica Carga Foto:** Seleccionar, recortar, comprimir y enviar a API (RF-POSTREG-001-02).
- [X] **Implementar Lógica Info Personal:** Capturar datos del formulario.
- [X] **Implementar Lógica Info Club:** Obtener catálogos (Club, Rol, Clase) y permitir selección (RF-POSTREG-001-04).
- [X] **Implementar Lógica Guardado:** Enviar datos consolidados a la API (RF-POSTREG-001-05).
- [X] **Integrar UI y Lógica:** Conectar pasos del Stepper con `PostRegisterBloc` y repositorios.
- [X] **Actualizar Estado Auth:** Notificar finalización a `AuthBloc` (RF-POSTREG-001-06).
- [ ] **Pruebas Unitarias/Widget:** Escribir pruebas para Bloc y pasos del Stepper.

## Módulo de Perfil (HU-PROFILE-001, 002, 003)
- [X] **Diseñar UI:** Pantalla principal de perfil, secciones básicas.
- [X] **Implementar Carga Datos Básicos:** Obtener y mostrar info de `UserBloc` (RF-PROFILE-001-01, 02, 03).
- [X] **Implementar Carga Clases/Roles:** Usar `UserClassesCubit`, `UserRolesCubit`.
- [X] **Implementar Carga Alergias/Enfermedades:** Usar `UserAllergiesCubit`, `UserDiseasesCubit`.
- [ ] **Diseñar/Implementar UI Edición:** Crear pantallas/formularios para editar información personal, médica, etc.
- [ ] **Implementar Lógica Actualización Perfil:** Funciones en `UserService`/`UserRepository` y Bloc/Cubit para guardar cambios.
- [ ] **Implementar Carga/UI Especialidades:** Crear Cubit, métodos de servicio y UI para mostrar especialidades (RF-PROFILE-001-04).
- [ ] **Implementar Carga/UI Contactos Emergencia:** Crear Cubit, métodos de servicio y UI (RF-PROFILE-001-05).
- [ ] **Integrar Edición Info Médica:** Conectar UI de edición con Cubits de Alergias/Enfermedades.
- [ ] **Diseñar/Implementar Pantalla Configuración:** (`profile/ConfigurationScreen`).
- [ ] **Pruebas Unitarias/Widget:** Escribir pruebas para Blocs/Cubits y pantallas de perfil.

## Módulo Home/Principal (HU-HOME-001)
- [X] **Diseñar UI:** Tablero básico, estructura de menú.
- [X] **Implementar Lógica Menú por Rol:** Mostrar opciones según rol obtenido de `UserBloc` (RF-HOME-001-01, 02).
- [ ] **Implementar Layout Principal (`main_layout`):** Usar `ShellRoute` con `MotionTabBar` para navegación persistente.
- [ ] **Conectar Selección Tipo Club:** Integrar `ClubTypeSelector` con `UserBloc` para filtrar/mostrar datos relevantes.
- [X] **Implementar Guardado de IDs de Club y Tipo por Defecto:** 
  - [X] Crear `PreferencesService` para `shared_preferences`.
  - [X] Integrar en `UserClubsCubit` para guardar `clubId`, `clubAdvId`, `clubPathfId`, `clubGmId` y `clubTypeSelect` (default 2) al cargar datos del club.
- [ ] **Definir/Implementar Contenido Tablero:** Mostrar información útil (RF-HOME-001-03).
- [ ] **Pruebas Unitarias/Widget:** Escribir pruebas para la pantalla y lógica del tablero.

## Módulo de Actividades (HU-ACTIVITIES-001) - Pendiente
- [ ] **Diseñar UI:** Pantallas para listar, ver detalle y crear/editar actividades.
- [ ] **Definir Modelo Datos:** Crear `ActivityModel`.
- [ ] **Implementar Lógica (Bloc/Cubit):** Gestionar estado de lista, detalle, creación/edición.
- [ ] **Implementar Servicio/Repositorio:** Funciones para interactuar con API (CRUD de actividades).
- [ ] **Integrar UI y Lógica:** Conectar pantallas con estado y servicios.
- [ ] **Pruebas Unitarias/Widget:** Escribir pruebas.

## Módulo de Administración Club (HU-ADMIN-001) - Pendiente
- [ ] **Diseñar UI:** Pantallas para ver lista de miembros, detalle, agregar/editar.
- [ ] **Implementar Lógica (Bloc/Cubit):** Gestionar estado de miembros.
- [ ] **Implementar Servicio/Repositorio:** Funciones para interactuar con API (CRUD de miembros del club).
- [ ] **Integrar UI y Lógica:** Conectar pantallas con estado y servicios.
- [ ] **Pruebas Unitarias/Widget:** Escribir pruebas.

## Tareas Generales/Arquitectura
- [X] **Refactorizar Inyección Dependencias:** Migrar toda la aplicación a `get_it`.
- [X] **Implementar Cambio Tema:** (RF-THEME-001)
- [X] **Mejorar Cliente API:** Implementar interceptores robustos para JWT (refresh token) y manejo global de errores 401/403.
- [X] **Persistir Configuración Inicial del Club:** Guardar IDs de club y tipo de club por defecto en SharedPreferences.
- [ ] **Implementar Pruebas:** Aumentar cobertura de pruebas Unitarias, Widget y de Integración en todos los módulos.
- [ ] **Documentación:** Mantener actualizado el Banco de Memoria y la documentación en `docs/`.

---

**Cómo usar esta lista:**
- Marca una tarea como completada cambiando `[ ]` por `[X]`.
- Si una tarea es muy grande, puedes dividirla en subtareas más pequeñas usando sangría y `- [ ]`.