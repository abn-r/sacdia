# Sacdia Admin Adaptive iOS — Diseño

**Estado:** APROBADO

**Fecha:** 2026-07-12

**Alcance:** `sacdia-admin-ios`, SwiftUI, iPhone y iPad.

## Objetivo

Convertir Sacdia Admin en una experiencia nativa y adaptativa: una navegación mínima y accionable en iPhone, una composición productiva en iPad y una misma capa de dominio, repositorios, permisos y contratos REST. La referencia visual de 430×932 sirve para validar jerarquía y densidad; no se fija ningún tamaño de pantalla en código.

## Decisiones aprobadas

1. **Compacto primero:** iPhone usa `TabView` con cuatro destinos visibles: Inicio, Usuarios, Clubes y Más. Cada destino tiene su propio `NavigationStack`; el catálogo completo se descubre desde Más mediante un sheet buscable y secciones.
2. **Regular adaptativo:** iPad usa `NavigationSplitView` con sidebar, contenido y detalle cuando el espacio lo permite. El sidebar no replica el panel web: agrupa sólo destinos autorizados y prioriza el flujo actual.
3. **Lógica compartida:** `AppState`, `AppRouter`, `AdminNavigationProjection`, view-models, repositorios, permisos y modelos de dominio se conservan. Cambia la composición de navegación, no el contrato de negocio.
4. **Sin mega-refactorización:** el trabajo se entrega en slices revisables: primero contrato/auth, luego tokens y componentes, shell, pantallas, estados y validación visual.
5. **Auth contract-first:** no se habilita Release con `UnavailableAdminAuthAPI` ni repositorios `Unavailable*`. El transporte productivo se implementa sólo después de cerrar con backend, documentación y tests cómo se representa `mfa_pending`, cómo se obtiene la sesión AAL2 y cómo se resuelve `access_panel`.

## Evidencia del estado actual y límites

- `AdminShellView` (`sacdia-admin-ios/SacdiaAdmin/Features/Shell/AdminShellView.swift:36-109`) siempre parte de `NavigationSplitView`; el compact sólo oculta columnas.
- `AdminSidebarView` (`.../AdminSidebarView.swift:10-71,122-136`) define una lista extensa y anchos de 220–320pt, adecuados para regular pero no para un iPhone.
- `DashboardView` (`.../DashboardView.swift:16-40,181-201`) usa grid adaptativo de 172pt y tarjetas de 148pt; se reemplaza en compacto por una columna de estado/acciones.
- `UsersView` (`.../UsersView.swift:42-56,158-212`) mezcla filtros horizontales, tabla regular y paginación; la semántica de consulta se conserva, pero los filtros pasan a sheet en compacto.
- `ClubsView` (`.../ClubsView.swift:11-36`) concentra cinco controles en un `LazyVGrid` y limita el contenido a 1.100pt; en iPhone se convierte en lista vertical con filtros secundarios en sheet.
- `AuthRootView` (`.../AuthRootView.swift:71-103,121-161,277-289`) tiene forms genéricos y `UnavailableAdminAuthAPI`; la UI se rehace después del cierre del transporte.
- `SacdiaTokens` (`.../DesignSystem/SacdiaTokens.swift:21-53`) sólo expresa color, spacing y radius. `SacdiaChrome` (`.../DesignSystem/SacdiaChrome.swift:16-75`) expresa material/glass pero no niveles de elevación/sombra.

## Arquitectura

### Capas y responsabilidades

```text
SwiftUI composition (compact/regular)
        ↓
Presentation (AppState, routers, view-models existentes)
        ↓
Domain protocols (AdminAuthAPI, repositories existentes)
        ↓
Infrastructure (HTTP client, auth transport, Keychain)
        ↓
REST /api/v1 + backend authorization
```

- **Composición:** `AdaptiveAdminRootView` decide compacto/regular con `horizontalSizeClass` y disponibilidad real de espacio. No usa `UIScreen.main.bounds` ni asume 430pt.
- **HTTP:** un cliente aislado centraliza base URL, headers, bearer, decodificación `{ status, data }`, códigos HTTP y cancelación. No loggea tokens ni payloads sensibles.
- **Auth:** `AdminAuthHTTPAPI` implementa el protocolo actual de `AdminAuthAPI`. `AuthSession` continúa siendo autoridad de ciclo de vida, persistencia, refresh, logout y recuperación.
- **Repositorios:** implementaciones HTTP de Users/Clubs consumen los endpoints vigentes y entregan exactamente los modelos actuales a los view-models. Las implementaciones fake quedan sólo bajo `#if DEBUG`.
- **Permisos:** el backend es autoridad final. `AppState.applyEffectivePermissions` sólo proyecta navegación y no sustituye `GlobalRolesGuard`/`PermissionsGuard`.

### Navegación compacta

```text
TabView
├─ Inicio → NavigationStack(Dashboard)
├─ Usuarios → NavigationStack(Users → UserDetail)
├─ Clubes → NavigationStack(Clubs → ClubDetail)
└─ Más → NavigationStack(ModuleIndex) → sheet de módulos/filtros
```

El `TabView` sólo contiene cuatro destinos estables. El sheet de Más presenta secciones autorizadas del catálogo (`AdminNavigationProjection`), búsqueda, estado seleccionado y navegación a placeholders sin inventar capacidades. Al cambiar de size class se preservan selección y paths; una ruta no autorizada vuelve a Inicio.

### Navegación regular

```text
NavigationSplitView
├─ Sidebar: projection autorizada, agrupada y colapsable
├─ Content: lista/overview del destino
└─ Detail: NavigationStack para detalles y rutas profundas
```

La tabla de usuarios sólo aparece con ancho suficiente y Dynamic Type no accesible; iPad estrecho usa cards/lista. Sidebar y detalle respetan safe areas, edge-swipe back y el toolbar nativo.

## Cierre contractual de autenticación (P0/B2)

### Contrato verificado

Fuente primaria: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/SECURITY-GUIDE.md` y runtime `sacdia-backend/src/auth/{auth.controller.ts,mfa.controller.ts,auth.service.ts}`.

| Operación | Contrato vigente | Implicación iOS |
|---|---|---|
| `POST /api/v1/auth/login` | `{ status, data.accessToken, refreshToken, expiresAt, tokenType, user, ... }`; login rate-limited | Decodificar expiry y claims sin persistir access token; confirmar en test/documentación cómo se expone `mfa_pending`. |
| `POST /api/v1/auth/mfa/verify` | JWT AAL1 permitido; body `{ code }`; respuesta `{ verified, accessToken? }` | Reemplazar access token y validar sesión AAL2; no asumir que la respuesta ya contiene refresh/permissions. |
| `POST /api/v1/auth/refresh` | body camelCase `{ refreshToken }`; devuelve nuevos tokens; `refresh_token` legacy se rechaza | Rotación atómica en Keychain; nunca enviar snake_case. |
| `GET /api/v1/auth/me` | JWT; devuelve perfil, roles, permissions y `authorization` | Fuente de permisos/scope; confirmar campos necesarios para `AdminCurrentSession`. |
| `POST /api/v1/auth/logout` | bearer y/o `refreshToken` opcionales; best effort | Revocar remoto sin bloquear limpieza local. |

### Gate obligatorio antes de Release

El backend actual muestra `access_panel` en administración (`sacdia-backend/src/admin/admin-users.service.ts`), pero `GlobalRolesGuard` y `PermissionsGuard` autorizan por roles/permisos. Además, la documentación no fija todos los campos de `authorization` necesarios para `AdminCurrentSession`.

Antes de habilitar autenticación productiva en Release deben existir:

1. test backend/documentación que confirme la señal de MFA pendiente en login y la transición AAL1→AAL2;
2. contrato documentado/testeado para reconstruir `AdminAuthenticatedSession` después de MFA/refresh (token + `/auth/me` o respuesta explícitamente enriquecida, sin inventar endpoint);
3. enforcement backend explícito de acceso al panel (`access_panel`) **o** una compensación segura aprobada que mantenga el gate server-side. El cliente nunca usa `access_panel` como único control;
4. pruebas de deny-by-default para un usuario con rol permitido pero `access_panel=false`, y para permisos ausentes.

Si el gate no está cerrado, la app puede seguir compilando con fake DEBUG y UI de contrato, pero Release debe quedarse en `contractUnavailable`/bloqueo seguro.

## Sistema visual y componentes

### Tokens

Extender `SacdiaTokens` con:

- `Layout`: `screenMargin=16`, `sectionGap=24`, `controlHeight=48`, `minimumTouchTarget=44`, `contentMaxWidth` sólo para regular.
- `Typography`: estilos Dynamic Type (`largeTitle`, `title`, `headline`, `body`, `subheadline`, `caption`); SF Pro Rounded para títulos/hero/CTA y SF Pro Text semántico para cuerpo/datos. No usar tamaños fijos como fuente de verdad.
- `Radius`: superficies 14/18/22pt según jerarquía, siempre continuous.
- `Elevation`: niveles `none`, `card`, `floating` con `y`, `blur`, `opacity` y color semántico; en dark mode reducir opacidad y priorizar separación tonal.
- `Color`: conservar colores de marca y fondos semánticos; foregrounds con contraste WCAG AA.

### Componentes reutilizables

- `SacdiaSurface/Card`: agrupación semántica; sombra sólo cuando separa capas, nunca en cada fila.
- `SacdiaSectionHeader` y `SacdiaPrimaryAction`: jerarquía clara y CTA en zona de pulgar.
- `SacdiaFilterSheet`: filtros aplicables/cancelables con resumen de selección.
- `SacdiaStateView`: loading/skeleton, empty, error con retry y denied, con identificadores de accesibilidad.
- `SacdiaStatusBadge`, `SacdiaPagination`, `SacdiaModuleIndex` y `SacdiaModuleSheet`.
- `SacdiaChrome`: conserva reduce-transparency; material/glass se reserva a superficies apropiadas y siempre aplica la elevación tokenizada.

## Pantallas

### Inicio/Dashboard

Una columna en iPhone: saludo/identidad, estado de conexión/autorización, una acción primaria y resumen de capacidades en filas compactas. En iPad puede crecer a dos columnas sólo cuando exista espacio real. Se conserva el manifest y los identificadores de capacidades; se elimina el grid como requisito móvil.

### Usuarios

Lista vertical lazy con fila de 44pt mínimo, nombre/estado y metadata secundaria. Búsqueda en toolbar; rol/estado/scope en `SacdiaFilterSheet`; paginación conserva `page`, `totalPages`, `hasNextPage` y `hasPreviousPage` del modelo. Detalle sigue en stack con secciones y back nativo.

### Clubes

Lista vertical lazy con estado, ubicación y conteo de secciones. Estado/geografía se editan en sheet; Apply/Cancel es explícito para evitar cinco controles comprimidos. Detalle conserva resumen, ubicación y secciones.

### Auth/MFA

Formulario centrado por contenido, no por un máximo desktop arbitrario; marca, títulos Rounded, campos con labels accesibles, focus/keyboard avoidance y CTA de 48pt en safe area. MFA usa código de un solo uso, error recuperable y no deja entrar al shell con AAL1. Recovery states conservan purge/remote-logout-debt y retry.

## Estados y seguridad

- Todo screen debe cubrir loading/skeleton, empty, error+retry y denied.
- Acciones destructivas requieren confirmación y, si el contrato lo exige, reautenticación.
- Refresh rotation y logout remoto son best effort, pero la limpieza local de Keychain es obligatoria.
- Access token sólo vive en memoria; refresh token sólo en Keychain `whenUnlockedThisDeviceOnly`, no sincronizable.
- Errores HTTP se mapean a `AdminAuthAPIError`/fallas de repositorio sin exponer detalles internos.
- Requests cancelados no mutan estado de un request posterior; se preservan generaciones actuales de view-models.

## Accesibilidad, performance y plataforma

- Touch targets ≥44pt; controles primarios 48pt. Labels, hints, traits y valores para VoiceOver.
- Dynamic Type completo; a tamaños de accesibilidad se apilan hero/filters y se abandona tabla.
- Respetar `accessibilityReduceMotion` y `accessibilityReduceTransparency`; no depender de sombra, color o gesto oculto.
- Listas largas con `List`/`LazyVStack` estable, IDs del dominio, render de filas pequeño y sin trabajo de red en `body`.
- `NavigationStack` conserva edge-swipe; sheets tienen detents nativos y botón Cancelar.
- Validar iPhone 11/12, referencia 430×932, tamaños modernos, iPad portrait/landscape, claro/oscuro, Dynamic Type y Reduce Motion.

## Testing y validación

1. **Contrato/auth:** tests de decodificación de wrappers, expiración, MFA pendiente, refresh camelCase, logout best effort y gate `access_panel`.
2. **Infraestructura:** `URLProtocol`/cliente stub para HTTP status, timeout, cancelación, retry y redacción de secretos; tests de Keychain existentes se mantienen.
3. **Navegación/tokens:** tests unitarios para selección compact/regular, proyección autorizada, elevations, touch targets y Dynamic Type.
4. **View-models/repositorios:** tests de query/paginación/error para Users y Clubs sin cambiar sus protocolos públicos.
5. **UI:** journey login→MFA→Inicio, navegación tabs/sheet/detalle, estados empty/error/denied, dark mode, Accessibility XXL y Reduce Motion.
6. **Matriz visual:** capturas/manual QA en iPhone 11, iPhone 12, 430×932, un iPhone moderno y iPad portrait/landscape; revisar safe areas, teclado, sombras, contraste y scroll.

## Riesgos y límites

- **P0/B2:** si backend no cierra `mfa_pending`/AAL2/`access_panel`, no habilitar Release.
- El catálogo tiene muchas rutas; Más debe ser buscable y autorizado, no una quinta tab saturada.
- iPad y iPhone requieren dos composiciones; compartir sólo modelos, contratos y componentes evita duplicar lógica.
- `iOS 17.4` es deployment target: Liquid Glass de iOS 26 no puede ser requisito; fallback opaque/material debe verse completo.
- No se agregan endpoints, DTOs ni permisos desde iOS. Cualquier gap se documenta en `docs/api/` y se cierra con backend antes de consumo.
- 430×932 es evidencia visual, no un `frame` hardcodeado.

## Criterio de aceptación del diseño

- iPhone puede llegar a Usuarios/Clubs/Detalle con una mano y sin abrir un sidebar.
- iPad conserva split/sidebar/detalle sin comprimir el panel web.
- Auth productiva sólo aparece cuando el gate contractual está cerrado; fake permanece DEBUG.
- Todas las pantallas comparten tokens, estados y reglas de accesibilidad/performance.
- La validación visual cubre la matriz solicitada y no encuentra clipping, controles <44pt ni sombras inconsistentes.
