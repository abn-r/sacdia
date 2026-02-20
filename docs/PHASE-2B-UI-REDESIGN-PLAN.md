# SACDIA App - Plan de Rediseño UI & Features Pendientes

> **Fecha de creación**: 16 de febrero de 2026
> **Última actualización**: 18 de febrero de 2026 (sesión final)
> **Basado en**: Brainstorming session - estilo "Scout Vibrante" (Duolingo + Apple Health)
> **Estado**: ✅ REDISEÑO UI COMPLETO (Fases A-I terminadas, migración HugeIcons completada)

---

## Resumen Ejecutivo

Rediseño completo de la UI de SACDIA App con estilo minimalista + gamificado, fondos blancos, acentos de color vibrantes, y micro-interacciones. Además, implementar las features faltantes de la Microfase 10 (offline, notifications, testing, polish).

**Estilo visual**: Mezcla de Duolingo (gamificación, colores vibrantes, progreso como protagonista) con Apple Health/Fitness (cards redondeadas, tipografía limpia, mucho espacio en blanco).

---

## Parte 1: Sistema de Diseño "Scout Vibrante"

### 1.1 Paleta de Colores

#### Colores Principales

| Rol | Nombre | Hex | Uso |
|-----|--------|-----|-----|
| Primary | Deep Indigo | `#4F46E5` | Botones principales, AppBar, enlaces, navegación |
| Primary Light | Indigo 100 | `#E0E7FF` | Badges, chips, fondos de selección, hover |
| Primary Dark | Indigo 800 | `#3730A3` | Texto énfasis, estados pressed |
| Secondary | Emerald | `#10B981` | Éxito, completado, progreso, naturaleza |
| Secondary Light | Emerald 100 | `#D1FAE5` | Badge completado, fondo success |
| Secondary Dark | Emerald 800 | `#065F46` | Texto success |
| Accent | Amber | `#F59E0B` | Estrellas, logros, recompensas, en-progreso |
| Accent Light | Amber 100 | `#FEF3C7` | Badge en-progreso |
| Accent Dark | Amber 800 | `#92400E` | Texto warning |
| Error | Rose | `#F43F5E` | Errores, destructivo, alertas |
| Error Light | Rose 100 | `#FFE4E6` | Badge error |

#### Fondos y Superficies

| Superficie | Hex | Uso |
|------------|-----|-----|
| Background | `#FFFFFF` | Fondo principal de todas las pantallas |
| Surface | `#FFFFFF` | Cards, modales, bottom sheets |
| Surface Variant | `#F8FAFC` | Secciones alternas, fondos secundarios |
| Border | `#E2E8F0` | Bordes de cards, dividers |
| Border Light | `#F1F5F9` | Bordes muy sutiles, separadores internos |

#### Texto

| Tipo | Hex | Uso |
|------|-----|-----|
| Primary | `#0F172A` | Títulos, texto principal |
| Secondary | `#64748B` | Subtítulos, descripciones |
| Tertiary | `#94A3B8` | Placeholders, hints, metadata |
| On Primary | `#FFFFFF` | Texto sobre fondos de color |

#### Colores de Clases (se mantienen - son tradición scout)

| Clase | Hex | Club |
|-------|-----|------|
| Corderitos | `#70C1DC` | Aventureros |
| Castores | `#3D7734` | Aventureros |
| Abejitas | `#F5D631` | Aventureros |
| Rayitos de Sol | `#DB563F` | Aventureros |
| Constructores | `#284376` | Aventureros |
| Manos Ayudadoras | `#8B2E38` | Aventureros |
| Amigo | `#2EA0DA` | Conquistadores |
| Compañero | `#F06151` | Conquistadores |
| Explorador | `#4FBF9F` | Conquistadores |
| Orientador | `#9FB9B1` | Conquistadores |
| Viajero | `#AE69BA` | Conquistadores |
| Guía | `#FBBD5E` | Conquistadores |
| Guía Mayor | `#023682` | Guías Mayores |

#### Dark Mode

| Superficie | Hex |
|------------|-----|
| Background | `#0F172A` (Slate 900) |
| Surface | `#1E293B` (Slate 800) |
| Surface Variant | `#334155` (Slate 700) |
| Border | `#475569` (Slate 600) |
| Text Primary | `#F8FAFC` |
| Text Secondary | `#94A3B8` |

### 1.2 Tipografía

Usar la fuente del sistema (San Francisco en iOS, Roboto en Android) para rendimiento nativo.

| Estilo | Tamaño | Peso | Uso |
|--------|--------|------|-----|
| Display | 28px | Bold (700) | Headers de pantalla principal |
| Title | 20px | SemiBold (600) | Títulos de sección |
| Subtitle | 16px | Medium (500) | Títulos de cards |
| Body | 14px | Regular (400) | Contenido general |
| Caption | 12px | Regular (400) | Metadata, timestamps |
| Overline | 10px | Medium (500) | Labels pequeños, badges |

### 1.3 Componentes

#### Cards
- Border radius: 16px
- Border: 1px solid `#E2E8F0`
- Background: `#FFFFFF`
- Padding interno: 16px
- Sin shadow pesada, máximo `boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]`

#### Botones
- **Primario**: radius 12px, fondo `#4F46E5`, texto blanco, height 48px
- **Secundario**: radius 12px, border `#4F46E5`, fondo transparente, texto indigo
- **Ghost**: sin border, texto indigo, hover con fondo `#E0E7FF`
- **Destructivo**: radius 12px, fondo `#F43F5E`, texto blanco

#### Progress Ring (estilo Apple Health)
- Circular, grosor 8px
- Track: `#F1F5F9`
- Fill: gradiente de `#4F46E5` a `#10B981`
- Texto porcentaje centrado, bold

#### Badges/Chips
- Border radius: 20px (pill)
- Padding: 4px 12px
- Variantes por color:
  - Default: fondo `#E0E7FF`, texto `#3730A3`
  - Success: fondo `#D1FAE5`, texto `#065F46`
  - Warning: fondo `#FEF3C7`, texto `#92400E`
  - Error: fondo `#FFE4E6`, texto `#9F1239`

#### Input Fields
- Border radius: 12px
- Border: 1px solid `#E2E8F0`, focus: `#4F46E5`
- Height: 48px
- Padding: 16px horizontal
- Label flotante estilo Material 3

#### Bottom Navigation
- Fondo blanco, border-top 1px `#E2E8F0`
- 4 tabs: Dashboard, Clases, Honores, Perfil
- Ícono + label
- Activo: `#4F46E5` con indicador dot encima del ícono
- Inactivo: `#94A3B8`

---

## Parte 2: Diseño de Pantallas

### 2.1 Flujo de Autenticación

#### Login Screen
- Fondo: blanco puro
- Logo SACDIA centrado arriba (compacto, 80px)
- Título: "Bienvenido de vuelta" (Display, `#0F172A`)
- Subtítulo: "Inicia sesión para continuar" (Body, `#64748B`)
- Campo email con icono Mail, border sutil, radius 12px
- Campo password con toggle de visibilidad
- Link "¿Olvidaste tu contraseña?" alineado derecha, indigo
- Botón "Iniciar Sesión" full width, indigo, height 48px
- Divider con "o continúa con" centrado
- Row de botones OAuth (Google + Apple) outlined con iconos
- Link inferior: "¿No tienes cuenta? **Regístrate**" (bold en indigo)

#### Register Screen
- Mismo estilo limpio sobre blanco
- Campos: Nombre, Apellido paterno, Apellido materno, Email, Password
- Indicador de fortaleza de password:
  - Barra de 4 segmentos: rojo → amber → emerald
  - Texto descriptivo: "Débil" / "Media" / "Fuerte" / "Muy fuerte"
- Checkbox de aceptar términos
- Botón "Crear Cuenta" full width, indigo
- Link inferior: "¿Ya tienes cuenta? **Inicia Sesión**"

#### Forgot Password Screen
- Título: "Recuperar contraseña"
- Subtítulo: "Te enviaremos un enlace a tu correo"
- Campo email
- Botón "Enviar enlace"
- Pantalla de confirmación con icono de email e instrucciones

### 2.2 Flujo de Post-Registro (3 Pasos)

#### Stepper Visual (fijo arriba)
- 3 círculos (32px) conectados por línea horizontal
- Completado: fondo emerald + ícono check blanco
- Activo: fondo indigo + número blanco
- Pendiente: border `#E2E8F0` + número gris
- Labels debajo: "Foto", "Datos", "Club"

#### Paso 1: Foto de Perfil
- Título: "¡Ponle cara a tu aventura!" (Display)
- Subtítulo: "Sube una foto para que te reconozcan en tu club" (Body, gris)
- Área central: Círculo 120px con borde punteado indigo
  - Si no hay foto: ícono de cámara grande
  - Si hay foto: preview con overlay de edición
- Dos cards debajo:
  - "Tomar foto" (ícono cámara, indigo)
  - "Elegir de galería" (ícono imagen, indigo)
- Footer fijo:
  - Link "Omitir por ahora" (ghost, gris)
  - Botón "Continuar" (primario, se habilita con foto o skip)

#### Paso 2: Información Personal
- Título: "Cuéntanos sobre ti" (Display)
- Subtítulo: "Esta información ayuda a tu club a cuidarte mejor"
- **Sub-sección 1: Datos básicos** (siempre visible)
  - Selector de género (2 chips: Masculino / Femenino)
  - Date picker para fecha de nacimiento (estilo calendario)
  - Toggle "¿Estás bautizado?" → si sí, date picker de bautismo
- **Sub-sección 2: Contactos de emergencia** (expansible)
  - Header con contador: "Contactos de emergencia (1/5)"
  - Lista de contactos existentes (card compacto con delete)
  - Botón "+ Agregar contacto" (outlined, indigo)
  - Modal para agregar: nombre, relación (dropdown), teléfono
- **Sub-sección 3: Información médica** (expansible)
  - "Alergias" → chip selector searchable
  - "Condiciones médicas" → chip selector searchable
- Indicador: "2 de 3 secciones completadas" (progress linear)
- Footer: "Atrás" + "Continuar"

#### Paso 3: Encuentra tu Club
- Título: "Encuentra tu club" (Display)
- Subtítulo: "Selecciona la organización a la que perteneces"
- Dropdowns en cascada con animación:
  1. País (pre-cargado)
  2. Unión (depende de país)
  3. Campo Local (depende de unión)
  4. Club (depende de campo local)
- Cuando un dropdown tiene solo 1 opción: auto-seleccionar y deshabilitar
- **Card de preview** (aparece al seleccionar club):
  - Nombre del club, ubicación
  - Tipos disponibles (badges de color: Aventureros/Conquistadores/GM)
  - Recomendación de tipo por edad: chip emerald "Recomendado para tu edad"
  - Selector de clase: chip con color de clase
  - Mensaje: "Tu inscripción está sujeta a aprobación del director"
- **Card resumen final:**
  - "Te unirás a **[Club]** como **[Tipo]** en la clase **[Clase]**"
  - Ícono de rocket
- Botón: "¡Comenzar mi aventura!" (emerald, full width, con ícono rocket)

### 2.3 Dashboard Principal

#### AppBar
- Fondo blanco, elevation 0
- Izquierda: Texto "SACDIA" en indigo bold
- Derecha: Avatar circular 36px del usuario (tap → perfil)
- Notificación badge (dot rojo si hay notificaciones)

#### Greeting Section
- "¡Buenos días, [Nombre]!" (Title, `#0F172A`)
- Saludo contextual: mañana/tarde/noche

#### Club Info Card
- Card compacto con:
  - Nombre del club
  - Badge del tipo (color del tipo de club)
  - Rol del usuario (chip sutil)

#### Progreso de Clase (PROTAGONISTA - estilo Apple Health)
- Card grande, full width
- Progress ring grande (120px) centrado
  - Porcentaje en el centro (Display bold)
  - Gradiente indigo → emerald
- Nombre de la clase (Title)
- "X de Y módulos completados" (Caption)
- Tap → navega a detalle de clase

#### Quick Stats Row
- 3 mini cards en fila horizontal:
  - **Honores**: ícono estrella (amber), número bold
  - **Actividades**: ícono calendario (indigo), número
  - **Asistencia**: ícono check (emerald), porcentaje

#### Próximas Actividades
- Header: "Próximas actividades" + "Ver todas >"
- Lista vertical de 3 cards compactos:
  - Badge de fecha (indigo): día y mes
  - Título de la actividad
  - Hora y ubicación (Caption)
  - Chip de tipo de actividad

### 2.4 Clases (estilo Google Classroom)

#### Lista de Clases
- AppBar: "Mis Clases" + filtro por año eclesiástico
- Cards horizontales, cada uno:
  - Barra lateral izquierda (4px) con color de la clase
  - Nombre de la clase (Subtitle)
  - Tipo de club (Caption)
  - Progress bar lineal (track `#F1F5F9`, fill indigo→emerald)
  - "X% completado" (Caption, indigo)
- La clase actual: border destacado indigo, badge "Clase actual"

#### Detalle de Clase
- Header: fondo con color de la clase (gradient sutil)
  - Nombre de la clase (Display, blanco)
  - Progress ring grande (blanco sobre color)
  - "X de Y módulos" (blanco)
- Body (fondo blanco):
  - Lista de módulos como ExpansionTile:
    - Ícono de módulo + Nombre (Subtitle)
    - Mini progress bar a la derecha
    - Badge "X/Y" secciones
    - Al expandir: lista de secciones
      - Checkbox circular
      - Completado: check emerald + texto tachado sutil
      - Pendiente: checkbox vacío + texto normal
      - Tap en sección → detalle/evidencia

### 2.5 Honores / Especialidades

#### Catálogo
- Filtro horizontal: chips scrollables por categoría (con color)
- Filtro de nivel: chips (Básico / Intermedio / Avanzado)
- Grid 2 columnas:
  - Card cuadrado:
    - Ícono/imagen del honor centrado
    - Nombre (Caption, bold)
    - Nivel (badge pequeño)
    - Estado: chip de color según estado

#### Detalle de Honor
- Header con imagen/ícono grande
- Nombre, categoría, nivel, descripción
- Requisitos como checklist
- Botón "Iniciar este honor" (indigo) o "En progreso" (amber)

#### Mis Honores
- Tabs: "En progreso" / "Completados"
- En progreso: cards con progress bar
- Completados: cards con badge dorado (amber)

### 2.6 Actividades

#### Lista
- Filtro por tipo (chips horizontales)
- Cards con:
  - Badge de fecha grande (indigo, esquina izquierda): día + mes abreviado
  - Tipo de actividad (chip con color)
  - Título (Subtitle)
  - Hora + Ubicación (Caption)
  - Estado de asistencia:
    - "Confirmar asistencia" (botón outlined)
    - "Confirmado" (chip emerald)
    - "No asistirá" (chip rose)

#### Detalle de Actividad
- Fecha y hora destacados
- Mapa/ubicación
- Descripción completa
- Lista de asistentes (avatares)
- Botón de confirmar/cancelar asistencia

### 2.7 Perfil y Settings

#### Perfil
- Avatar grande centrado (100px) con botón de edición (overlay)
- Nombre completo (Title)
- Email (Caption, gris)
- Card de club: nombre, tipo, rol, clase actual
- Secciones expandibles:
  - "Información personal" (datos básicos)
  - "Contactos de emergencia" (lista)
  - "Información médica" (alergias, enfermedades)
- Botón "Editar perfil" (outlined, indigo)

#### Settings
- Lista con iconos a la izquierda:
  - Tema: Claro / Oscuro / Sistema (segmented control)
  - Notificaciones (toggle)
  - Idioma (español por defecto)
  - Privacidad
  - Acerca de SACDIA
  - Versión de la app (Caption, gris)
- Separador
- "Cerrar sesión" (texto rose/rojo, ícono logout)

---

## Parte 3: Plan de Implementación

### Fase A: Sistema de Diseño Base (Theme + Componentes)

> Prioridad: ALTA - Todo lo demás depende de esto

- [x] **A.1** Actualizar `app_colors.dart` con nueva paleta "Scout Vibrante" ✅
- [x] **A.2** Actualizar `app_theme.dart` con nuevo ThemeData (light + dark) ✅
- [x] **A.3** Crear componentes reutilizables:
  - [x] A.3.1 `SacButton` (primary, secondary, ghost, destructive, success) ✅
  - [x] A.3.2 `SacCard` (radius 16, border sutil, acento lateral) ✅
  - [x] A.3.3 `SacBadge` (primary, secondary, accent, error, neutral) ✅
  - [x] A.3.4 `SacProgressRing` (circular con gradiente Apple Health) ✅
  - [x] A.3.5 `SacProgressBar` (lineal con gradiente, animado) ✅
  - [x] A.3.6 `SacTextField` (radius 12, label flotante, password toggle) ✅
  - [ ] A.3.7 `SacExpansionTile` (estilizado) - se hará en Fase E
  - [ ] A.3.8 `SacBottomNavBar` (4 tabs con dot indicator) - se hará en Fase I
- [x] **A.4** Definir constantes de spacing, radius, elevación (en AppTheme) ✅
- [x] **A.5** Crear barrel file `sac_widgets.dart` para exports ✅

### Fase B: Rediseño Auth (Login + Registro)

- [x] **B.1** Rediseñar `LoginScreen` con nuevo estilo ✅
- [x] **B.2** Rediseñar `RegisterScreen` con indicador de fortaleza de password ✅
- [x] **B.3** Rediseñar `ForgotPasswordScreen` ✅
- [x] **B.4** Crear/actualizar `SplashScreen` con branding actualizado ✅

### Fase C: Rediseño Post-Registro

- [x] **C.1** Crear nuevo `StepperWidget` visual (3 pasos con estados) ✅
- [x] **C.2** Rediseñar Paso 1: Foto de perfil ✅
- [x] **C.3** Rediseñar Paso 2: Información personal (sub-secciones colapsables) ✅
- [x] **C.4** Rediseñar Paso 3: Selección de club (card de preview + resumen) ✅

### Fase D: Rediseño Dashboard

- [x] **D.1** Nuevo AppBar (blanco, "SACDIA", avatar)
- [x] **D.2** Greeting section + Club info card
- [x] **D.3** Progress ring grande de clase (estilo Apple Health)
- [x] **D.4** Quick stats row (3 mini cards)
- [x] **D.5** Próximas actividades (lista compacta)

### Fase E: Rediseño Clases

- [x] **E.1** Lista de clases con barra de color lateral + progress bar
- [x] **E.2** Detalle de clase con header colorido + expansion tiles

### Fase F: Rediseño Honores

- [x] **F.1** Catálogo con filtros de chips + grid
- [x] **F.2** Detalle de honor rediseñado
- [x] **F.3** "Mis Honores" con tabs y badges

### Fase G: Rediseño Actividades

- [x] **G.1** Lista de actividades con badges de fecha + chips de tipo ✅
- [x] **G.2** Detalle de actividad rediseñado ✅

### Fase H: Rediseño Perfil y Settings

- [x] **H.1** Pantalla de perfil con secciones expandibles ✅
- [x] **H.2** Settings con segmented control de tema ✅

### Fase I: Bottom Navigation + Home

- [x] **I.1** Rediseñar bottom nav con HugeIcons rounded ✅
- [x] **I.2** Rediseñar home_view con greeting, notificaciones y quick actions ✅
- [x] **I.3** Dashboard cards y recent activity list con nuevo estilo ✅

### Fase EXTRA: Cleanup + Migración de Iconos

- [x] **X.1** Eliminar TODOS los colores hardcoded (AppColors.sac*, Colors.grey, Colors.red, etc.) ✅
- [x] **X.2** Migrar TODOS los Material Icons (`Icons.xxx`) a HugeIcons (`HugeIcons.strokeRoundedXxx`) ✅
- [x] **X.3** Actualizar widgets core (SacButton, SacBadge, SacTextField, CustomButton) para aceptar iconos dinámicos ✅
- [x] **X.4** Crear utilidad `icon_helper.dart` con `buildIcon()` para soporte dual IconData/HugeIcons ✅
- [x] **X.5** Flutter analyze: 0 errores, 0 warnings ✅

### Fase J: Features Faltantes (Microfase 10)

- [ ] **J.1** Push Notifications (Firebase Cloud Messaging)
  - [ ] J.1.1 Configurar Firebase en iOS y Android
  - [ ] J.1.2 Implementar registro de FCM token
  - [ ] J.1.3 Manejar notificaciones foreground/background
- [ ] **J.2** Offline Mode
  - [ ] J.2.1 Implementar caché local con Hive/Drift
  - [ ] J.2.2 Indicador de estado offline
  - [ ] J.2.3 Cola de operaciones pendientes
  - [ ] J.2.4 Sincronización al reconectar
- [ ] **J.3** Animaciones y Micro-interacciones
  - [ ] J.3.1 Transiciones entre pantallas
  - [ ] J.3.2 Animación de progreso al completar secciones
  - [ ] J.3.3 Skeleton loading screens
  - [ ] J.3.4 Pull-to-refresh con animación
- [ ] **J.4** Testing
  - [ ] J.4.1 Unit tests para use cases
  - [ ] J.4.2 Widget tests para componentes
  - [ ] J.4.3 Integration tests para flujos principales
- [ ] **J.5** Performance
  - [ ] J.5.1 Lazy loading de imágenes
  - [ ] J.5.2 Optimización de builds
  - [ ] J.5.3 Resolver los 89 hints del analyzer

---

## Parte 4: Tracking de Progreso

### Estado General

| Fase | Descripción | Items | Completados | Estado |
|------|-------------|-------|-------------|--------|
| A | Design System Base | 13 | 11 | ✅ Casi completa |
| B | Auth (Login/Register) | 4 | 4 | ✅ Completa |
| C | Post-Registro | 4 | 4 | ✅ Completa |
| D | Dashboard | 5 | 5 | ✅ Completa |
| E | Clases | 2 | 2 | ✅ Completa |
| F | Honores | 3 | 3 | ✅ Completa |
| G | Actividades | 2 | 2 | ✅ Completa |
| H | Perfil/Settings | 2 | 2 | ✅ Completa |
| I | Bottom Nav + Home | 3 | 3 | ✅ Completa |
| X | Cleanup + HugeIcons | 5 | 5 | ✅ Completa |
| J | Features Microfase 10 | 14 | 0 | ⏳ Pendiente |
| **TOTAL** | | **57** | **41** | **72%** |

### Sesiones de Trabajo

| # | Fecha | Fases Completadas | Notas |
|---|-------|-------------------|-------|
| 1 | 2026-02-16 | A (11/13) | Theme, paleta, 6 componentes Sac*, barrel file. Falta: SacExpansionTile (Fase E), SacBottomNavBar (Fase I) |
| 2 | 2026-02-16 | B (4/4) | LoginView, RegisterView (con password strength indicator), ForgotPasswordView (con success state), SplashView (fade+scale animation, indigo branding) |
| 3 | 2026-02-17 | C (4/4) | StepIndicator (indigo/emerald animated), BottomNavButtons (SacButton + skip), PostRegistrationShell (no AppBar, badge counter), PhotoStepView (dashed circle, SacCard actions), PersonalInfoStepView (gender chips, SacCard sections, progress bar), ClubSelectionStepView (section headers with icons) |
| 4 | 2026-02-17 | D (5/5) | WelcomeHeader (contextual greeting, avatar), ClubInfoCard (SacCard+accentColor, SacBadge), CurrentClassCard (SacProgressRing 140px), QuickStatsCard (3 mini SacCards amber/indigo/emerald), UpcomingActivitiesCard (date badges, dividers), DashboardView (SacButton error state) |
| 5 | 2026-02-17 | E (2/2) | ClassCard (SacCard+accentBar, SacProgressBar, isCurrent badge), ClassesListView (inline header, no AppBar), ClassDetailView (SliverAppBar gradient indigo, SacProgressRing white-on-color), ClassModulesView (indigo AppBar, floating SnackBars), ModuleExpansionTile (SacCard, mini progress bar, emerald complete), SectionCheckbox (circular AnimatedContainer, emerald check) |
| 6 | 2026-02-17 | F (3/3) | HonorCategoryCard (SacCard, amber iconBox 52px), HonorCard (SacCard, SacBadge.warning nivel), HonorProgressCard (SacBadge status, emoji_events/pending icons, DateFormat), HonorsCatalogView (SliverGrid 2cols, inline header, back nav), HonorDetailView (SliverAppBar amber gradient, requirements SacCard, SacButton enroll), MyHonorsView (TabBar pill-style, 3 stat mini SacCards, TabBarView in_progress/completed) |
| 7 | 2026-02-17 | G (2/2) | ActivitiesListView (filter chips horizontal, date badges indigo, SacCard+accentColor por tipo), ActivityDetailView (SliverAppBar con tipo icon, ActivityInfoRow icon boxes), ActivityCard (SacCard, SacBadge tipo/estado), AttendanceButton (animated emerald). 3 warnings fixed (unnecessary_cast, unused_import, unused_element) |
| 8 | 2026-02-17 | H (2/2) | ProfileView (avatar 100px con camera overlay, info_section con SacCard, SacBadge roles), SettingsView (RadioListTile theme, Switch notifications, setting_tile con iconBox), EditProfileView (SacTextField con prefixIcon, SacButton.primary save) |
| 9 | 2026-02-17 | I (3/3) | HomeView (greeting contextual, notification/logout icon buttons, quick actions SacCard), DashboardCard (SacCard con icon+arrow), RecentActivityList (timeline con icon boxes), router.dart bottom nav actualizado con iconos rounded |
| 10 | 2026-02-18 | X (5/5) | **Cleanup total**: eliminados TODOS colores hardcoded (AppColors.sac*, Colors.grey[*], Colors.red/green/blue/orange) de ~10 archivos. **Migración HugeIcons**: 57 archivos migrados de Material Icons a `hugeicons: ^1.1.5`. Creado `icon_helper.dart` con `buildIcon()`. Widgets core (SacButton, SacBadge, SacTextField, CustomButton) actualizados a `dynamic icon`. 0 errores, 0 warnings en flutter analyze |

---

## Parte 5: Notas Técnicas

### Dependencias Agregadas
- `hugeicons: ^1.1.5` - Librería de iconos (reemplaza Material Icons en toda la app)
- `flutter_svg: ^2.2.0` - Requerido por hugeicons

### Dependencias Pendientes (Fase J)
- `shimmer` - Para skeleton loading
- `lottie` - Para micro-animaciones (opcional)
- `firebase_messaging` - Push notifications
- `firebase_core` - Firebase base
- `hive_flutter` o `drift` - Offline cache

### Archivos Principales a Modificar
- `lib/core/theme/app_colors.dart` - Nueva paleta
- `lib/core/theme/app_theme.dart` - Nuevo ThemeData
- `lib/core/widgets/` - Nuevos componentes reutilizables
- Todos los archivos en `lib/features/*/presentation/views/` - Rediseño de pantallas
- `lib/core/config/router.dart` - Ajustes de navegación

### Convenciones
- Prefijo `Sac` para todos los componentes custom del design system
- Colores SIEMPRE referenciados desde `AppColors`, nunca hardcoded
- Usar `Theme.of(context)` para adaptarse a dark mode
- Spacing desde `AppConstants` (paddingXS, paddingS, paddingM, paddingL, paddingXL)
- **Iconos**: Usar `HugeIcons.strokeRoundedXxx` exclusivamente (no Material Icons)
  - Widget: `HugeIcon(icon: HugeIcons.strokeRoundedXxx, size: N, color: C)`
  - En params dinámicos: usar `buildIcon()` de `core/utils/icon_helper.dart`
  - Widgets con param `icon` aceptan `dynamic` (IconData o HugeIcons)
  - Import: `import 'package:hugeicons/hugeicons.dart';`
  - HugeIcon NO soporta `const` (los datos son `List<List<dynamic>>`)
