# Requerimientos Funcionales - SACDIA App

**Formato:** RF-[ID Historia]-[Número] - [Descripción del requerimiento]

---

**Derivados de HU-AUTH-001 (Registro):**
- **RF-AUTH-001-01:** El sistema debe permitir ingresar correo electrónico y contraseña.
- **RF-AUTH-001-02:** El sistema debe validar el formato del correo y la fortaleza de la contraseña (ej. mínimo 8 caracteres).
- **RF-AUTH-001-03:** El sistema debe enviar los datos de registro a la API de backend (NestJS).
- **RF-AUTH-001-04:** El sistema debe manejar respuestas de éxito y error de la API (ej. correo ya existe).

**Derivados de HU-AUTH-002 (Inicio de Sesión):**
- **RF-AUTH-002-01:** El sistema debe permitir ingresar correo y contraseña.
- **RF-AUTH-002-02:** El sistema debe usar Supabase Auth para verificar las credenciales.
- **RF-AUTH-002-03:** El sistema debe gestionar el token JWT recibido tras el éxito.
- **RF-AUTH-002-04:** El sistema debe redirigir al usuario al flujo post-registro o al home según corresponda.
- **RF-AUTH-002-05:** El sistema debe mostrar mensajes de error claros (ej. credenciales inválidas).

**Derivados de HU-AUTH-003 (Recuperar Contraseña):**
- **RF-AUTH-003-01:** El sistema debe permitir ingresar el correo electrónico asociado a la cuenta.
- **RF-AUTH-003-02:** El sistema debe usar Supabase Auth para iniciar el flujo de restablecimiento de contraseña.
- **RF-AUTH-003-03:** El sistema debe informar al usuario que revise su correo.

**Derivados de HU-POSTREG-001 (Perfil Inicial):**
- **RF-POSTREG-001-01:** El sistema debe presentar un flujo guiado (Stepper) con pasos para: foto, info personal, info club.
- **RF-POSTREG-001-02:** El sistema debe permitir seleccionar/capturar y recortar una foto de perfil.
- **RF-POSTREG-001-03:** El sistema debe permitir ingresar/seleccionar información personal (nombre, fecha nacimiento, etc.).
- **RF-POSTREG-001-04:** El sistema debe permitir seleccionar el club, rol y clase (obteniendo catálogos de la API).
- **RF-POSTREG-001-05:** El sistema debe enviar los datos recopilados a la API para guardar el perfil.
- **RF-POSTREG-001-06:** El sistema debe indicar el fin del proceso y actualizar el estado de autenticación.

**Derivados de HU-PROFILE-001 (Ver Perfil):**
- **RF-PROFILE-001-01:** El sistema debe obtener los datos completos del perfil del usuario autenticado desde la API.
- **RF-PROFILE-001-02:** El sistema debe mostrar la información básica, del club, rol(es), clase(s), estado bautismal/investidura.
- **RF-PROFILE-001-03:** El sistema debe mostrar la foto de perfil.
- **RF-PROFILE-001-04:** (Pendiente) El sistema debe obtener y mostrar la lista de especialidades asociadas.
- **RF-PROFILE-001-05:** (Pendiente) El sistema debe obtener y mostrar información médica y contactos de emergencia.

**Derivados de HU-HOME-001 (Ver Tablero):**
- **RF-HOME-001-01:** El sistema debe identificar el rol(es) principal(es) del usuario.
- **RF-HOME-001-02:** El sistema debe mostrar un menú de navegación (ej. BottomNavBar) con opciones acordes al rol.
- **RF-HOME-001-03:** El sistema debe mostrar información relevante en el tablero (ej. próximos eventos, resumen). (Por definir detalle)

**Derivados de HU-THEME-001 (Cambiar Tema):**
- **RF-THEME-001-01:** El sistema debe permitir al usuario seleccionar entre tema claro y oscuro.
- **RF-THEME-001-02:** El sistema debe persistir la preferencia del tema localmente (shared_preferences).
- **RF-THEME-001-03:** El sistema debe aplicar el tema seleccionado en toda la aplicación.

**(Añadir requerimientos para HU pendientes: Editar Perfil, Ver Especialidades, Gestionar Miembros, Gestionar Actividades)**