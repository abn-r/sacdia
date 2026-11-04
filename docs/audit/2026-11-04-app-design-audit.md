# Auditoría de diseño — sacdia-app (2026-11-04)

Auditoría de código (sin capturas) de las 159 pantallas de `sacdia-app` contra `DESIGN-SYSTEM.md` v2.
Cinco revisores en paralelo por zona funcional + escaneo automático + verificación manual de los hallazgos clave.
Rama auditada: `development`.

## Estado (2026-11-04)

| Fase | Estado | PR |
|------|--------|----|
| 0 — Bugs puntuales | Hecha | abn-r/sacdia-app#230 |
| 1 — Base en `core/` (tokens de contenedor, `SacBadge`, `SacSnackBar`, fechas en el idioma de la app, `SacMoney`, ratchet) | Hecha | abn-r/sacdia-app#231 |
| 2 — Migración por feature (+ skeleton, avatar, ajustes, `SacButton.text`) | Hecha | abn-r/sacdia-app#232 |
| 3 — Accesibilidad | Cubierta en gran parte por la Fase 2 (áreas táctiles, `Semantics`, texto mínimo) | — |
| 4 — Rediseño: inicio (miembro/staff + `GET /dashboard/pending`) | Backend hecho; app pendiente de merge | abn-r/sacdia-backend#616 · Pendiente de merge (PR abn-r/sacdia-app#233) |
| 4 — Rediseño: detalle de especialidad, miembros, detalle de camporee | Pendiente | — |
| 5 — Pulido y movimiento | Pendiente | — |

Decisiones abiertas: color de marca azul del login (`loginBrandBlue*`, 3.75:1 en oscuro); textos aún fijos en español (tiempo relativo de notificaciones, encabezado de inventario, meses de la gráfica de finanzas).

## Veredicto

La **mecánica** del sistema de diseño está bien adoptada: 0 `Icons.*`, 0 `AlertDialog`/`showModalBottomSheet` crudos, radios por token, `SacFontSize` en casi todo, `SacTopBar` casi universal y paletas por feature documentadas en `*_tokens.dart`.

El problema es **semántico**: los *estados* (error, vacío, carga, estatus) y los *colores de estatus* se reinventan en cada pantalla. Dos huecos en la base (`SacColors` sin tokens de contenedor y `SacBadge` con pasteles fijos) provocan la mayoría de los errores de modo oscuro y de contraste.

> La consistencia se arregla en `core/`, no pantalla por pantalla.

## 1. Causas raíz (verificadas)

| # | Problema | Evidencia verificada | Efecto |
|---|----------|----------------------|--------|
| R1 | `SacColors` no tiene tokens de contenedor/tinte (`successContainer`, `onWarningContainer`, …) | `lib/core/theme/sac_colors.dart` solo expone `success/warning/info/error` (mismo valor en ambos modos) y `onWarning` | Cada pantalla usa `AppColors.*Light` como fondo: **168 usos en 78 archivos**. En OLED negro se ven como bloques casi blancos |
| R2 | `SacBadge` usa pasteles fijos | `lib/core/widgets/sac_badge.dart:50-76` → `secondaryLight/accentLight/errorLight` + `*Dark` | Todo badge "oficial" se rompe en modo oscuro; la variante `accent` tiene **2.97:1** de contraste en claro |
| R3 | `SacErrorState` casi no se usa; `userErrorMessage` existe pero se adopta poco | `SacErrorState` en **7** archivos de features contra **84** widgets privados `_Error*/_Empty*`. `lib/core/errors/user_error_message.dart` (ya traduce errores y nunca usa `toString()`) en **15** archivos | ~**67** sitios muestran `e.toString()` al usuario ("Exception: DioException…"). 6+ estilos distintos de pantalla de error |
| R4 | No hay un helper único para dinero ni para fechas | 5 formatos de moneda (`$1,200.00`, `$1200.00`, `1.2K`, `… MXN`, formateador manual). 22 `DateFormat`, 12 con `'es'` fijo | Montos y fechas se ven distintos según la pantalla; las fechas ignoran el selector de idioma |
| R5 | Estatus sin vocabulario común | 10+ badges propios: `insurance_status_badge`, `condition_badge`, `validation_status_badge`, `section_status_badge`, `_TransferStatusBadge`, `requirement_status_badge`… | "Pendiente" o "Validado" se ven distinto en cada módulo; varios dependen solo del color |

### Contraste medido (WCAG, texto pequeño necesita ≥ 4.5:1)

| Par | Ratio | Dónde |
|-----|-------|-------|
| `accentDark` sobre `accentLight` | **2.97** ❌ | `SacBadge.accent`, roles, inscripción, transferencias |
| `secondaryDark` sobre `secondaryLight` | **3.71** ❌ | `SacBadge.secondary`, perfil de miembro |
| `error` sobre `errorLight` | **3.95** ❌ | errores inline |
| `errorDark` sobre `errorLight` | 6.80 ✅ | `SacBadge.error` |
| Blanco sobre `secondary` (#4FBF9F) | **2.26** ❌ | 10+ snackbars de éxito con `backgroundColor: AppColors.secondary` |
| `accent` (#FBBD5E) como texto sobre blanco | **1.67** ❌ | chips de investidura, badge de Aventureros |
| `loginBrandBlueDark` sobre negro | **3.75** ❌ | links de login en modo oscuro |

## 2. Bugs concretos (arreglo de minutos)

| Severidad | Bug | Archivo |
|-----------|-----|---------|
| 🔴 | El ícono "más" del inicio es invisible en modo oscuro (`AppColors.lightText` fijo) | `lib/features/dashboard/presentation/widgets/welcome_header.dart:97` |
| 🔴 | El resultado del escáner QR usa `Colors.green/orange.shade900/red`: fuera de paleta y con mal contraste en oscuro | `lib/features/qr/presentation/views/qr_scanner_view.dart:337,370-379,408` |
| 🔴 | El detalle de actividad fuerza `SystemUiOverlayStyle.light`: iconos de la barra de estado blancos sobre blanco en el estado de error (modo claro) | `lib/features/activities/presentation/views/activity_detail_view.dart:510` |
| 🔴 | Franja de color lateral en una tarjeta (regla tuya) | `lib/features/investiture_requests/presentation/widgets/own_investiture_card.dart:194` |
| 🟡 | La gráfica de finanzas muestra un error de red como "sin datos" (sin reintento) | `lib/features/finances/presentation/widgets/finance_line_chart.dart:115` |
| 🟡 | El dashboard sin datos es un callejón sin salida (sin reintento) | `lib/features/dashboard/presentation/views/dashboard_view.dart:~118` |
| 🟡 | El perfil de miembro, en error, no tiene `onRetry` | `lib/features/members/presentation/views/member_profile_view.dart:96,1070` |
| 🟡 | Textos de 9.6 y 11.2 px por escala decimal (`0.8`) | `lib/features/enrollment/presentation/widgets/enrollment_status_card.dart:128-190` |
| 🟡 | Etiquetas de tipo de notificación en español fijo, sin `.tr()` | `lib/features/notifications/presentation/widgets/notification_type_badge.dart:70-157` |

## 3. Problemas sistémicos de UX y accesibilidad

- **Áreas táctiles < 44dp**:
  - chips de filtro de miembros (~28dp, `members_filter_bar.dart:283`);
  - stepper de cantidad (32dp, `materials/.../qty_stepper.dart:78`);
  - chevron de mes en finanzas (32dp);
  - botones del encabezado de actividades (38dp);
  - `TextButton` con `Size.zero` + `shrinkWrap` en ~10 sitios;
  - checkboxes de sección de clase (24px).
- **Semántica**: tarjetas clave (`class_card`, `honor_card`, `master_honor_badge`) sin `Semantics`. 12 archivos de actividades/camporee con 3+ acciones táctiles y cero etiquetas. Solo 11 de 33 `IconButton` en finanzas/operación tienen `tooltip`. La gráfica de finanzas no tiene alternativa en texto e ingreso/egreso se distinguen solo por color.
- **Tipografía**: `SacFontSize.micro` = 9px y `caption` = 10px se usan para metadatos esenciales (aprobador, puntos, seguro). ~900 `TextStyle(fontSize: SacFontSize.*)` armados a mano en lugar de `textTheme.*.copyWith`. Pesos inflados (en camporee: `w800` ×77, `w700` ×111).
- **Carga**: spinners de pantalla completa donde debería haber skeleton (miembros, unidades, club, transferencias, flujo de compra de materiales, especialidades). Hay 5 implementaciones de shimmer distintas.
- **Progreso**: 7+ maneras de dibujar "X de Y" (barras de 2, 3, 4 y 8px, `ProgressRing` legado, `mini_ring`), además de `SacProgressBar`/`SacProgressRing`.
- **Pantallas monolíticas**: `honor_detail_view` 3,942 líneas, `camporee_detail_view` 2,548, `enrollment_form_view` 1,744; tres pantallas médicas casi idénticas de ~1,300 líneas cada una (alergias, enfermedades, medicamentos).
- **Eficiencia del staff**: sin selección múltiple ni acciones masivas (aprobar solicitudes de ingreso una por una). "Sin miembros" y "sin resultados del filtro" muestran el mismo estado vacío.
- **Celebración desigual**: logros y especialidades celebran; completar una clase, una certificación o una sección, o validar la carpeta, no.
- **Componentes duplicados**: 6 avatares de miembro, badges de camporee duplicados entre lista y detalle, `_FilterChip` privado junto a `SacFilterChip`, 3 implementaciones de ajustes (`settings_view`, `biometric_settings_section`, `accessibility_settings_section`).

## 4. Pantallas que más necesitan rediseño

| # | Pantalla | Por qué |
|---|----------|---------|
| 1 | `honors/.../honor_detail_view.dart` | El corazón gamificado de la app: 3,942 líneas, 51 `TextStyle`, spinners crudos, sin una acción principal clara |
| 2 | `members/.../members_view.dart` + `members_filter_bar.dart` | La pantalla diaria del staff: áreas táctiles mínimas, sin acciones masivas, error crudo |
| 3 | `dashboard/.../dashboard_view.dart` + `quick_access_grid.dart` | Hasta ~21 mosaicos iguales con colores arbitrarios, sin jerarquía ni punto focal; se recortan con texto grande |
| 4 | `camporees/.../camporee_detail_view.dart` | 2,548 líneas y 9 secciones en una sola ruta; badges duplicados de la lista |
| 5 | `finances/.../finances_view.dart` + `finance_line_chart.dart` | Pantalla de dinero: error mostrado como vacío, gráfica inaccesible, etiquetas al 40% de opacidad |
| 6 | `qr/.../qr_scanner_view.dart` | Check-in en vivo con colores fuera de paleta y sin feedback háptico |
| 7 | `post_registration/.../allergies|diseases|medicines_selection_view.dart` | 3 pantallas duplicadas → 1 genérica |
| 8 | `classes/.../class_detail_with_progress_view.dart` (+ `class_detail_view.dart` legado) | Barra de progreso de 2px (muy sutil para niños); dos vistas de detalle conviviendo |

## 5. Plan recomendado (por fases)

**Fase 0 — Bugs (½ día).** Todo lo de la sección 2.

**Fase 1 — Arreglar la base (`core/`). Cada cambio se propaga solo.**
1. `SacColors`: agregar `successContainer/onSuccessContainer`, `warningContainer/onWarningContainer`, `errorContainer/onErrorContainer` e `infoContainer/onInfoContainer`, con valores por modo y contraste ≥ 4.5:1.
2. `SacBadge`: usar esos tokens y agregar variantes `success`, `warning`, `info` y `pending`/`sent`, siempre con icono opcional para no depender solo del color.
3. `SacSnackBar.success(...)` y quitar los `backgroundColor: AppColors.secondary`.
4. `SacErrorState` + `userErrorMessage` como único camino; agregar una regla al guard test que falle con `.toString()` dentro de `presentation/`.
5. `core/utils/money_format.dart` (es_MX, variantes compacta y con signo, cifras tabulares) y `SacDateFormat` con `context.locale`.
6. Componentes faltantes: `SacSkeletonBox`/`SacShimmer`, `SacMemberAvatar`, `SacButton.text` (≥ 48dp), `SacSettingsGroup`/`SacSettingsTile`.

**Fase 2 — Migración mecánica por feature.** Pasar `*Light` a tokens de contenedor, `_ErrorBody`/`_EmptyState` a `Sac*`, `CircularProgressIndicator` a `SacLoading`/skeleton, los badges propios a `SacBadge` y el progreso a `SacProgressBar`/`Ring`. Se puede trabajar por grupos de features y extender el guard test (como el de HugeIcons) para impedir que vuelva.

**Fase 3 — Accesibilidad.** Áreas táctiles ≥ 44/48dp, `Semantics` en tarjetas y controles con solo icono, metadatos esenciales ≥ 11-12px, gráfica con alternativa en texto.

**Fase 4 — Rediseño puntual** de las pantallas de la sección 4. Aquí sí conviene buscar referencias (Mobbin) para dashboard, detalle de especialidad y miembros.

**Fase 5 — Pulido y movimiento.** Celebraciones consistentes (clase, certificación, carpeta), háptica en acciones de dinero y check-in, primeros 3 lugares destacados en el leaderboard. Aquí sí tendría sentido 60fps.

## 6. Referencias internas a copiar

- **Estados**: `coordinator/` (skeletons por sección, `_SectionError` parcial, `SacErrorState` con 403) e `investiture_requests/` (`investiture_error_message.dart`, `SacEmptyState`, `showSacSheet`).
- **Color con contraste correcto**: `honors/presentation/theme/honor_category_palette.dart` (`onCategoryPaintColor`), `rankings/presentation/theme/ranking_tokens.dart` (tonos claro/oscuro) y `notifications/.../notification_type_badge.dart` (tinte sobre `surfaceVariant` según el brillo).
- **Accesibilidad y movimiento**: `activities/` (`Semantics` en fechas, `SacMotion.reduceMotionOf`) y `welcome_header.dart` (tooltips en iconos).

## 7. Notas de verificación

- `AppColors.error/success/secondary/accent/info` usados directamente (~600 usos) **no** son bug de modo oscuro: `context.sac.*` devuelve el mismo valor en ambos modos. Es solo deuda de estilo (§2.7). El bug real son las variantes `*Light`/`light*` (R1).
- Los `Color(0x…)` de los `*_tokens.dart` por feature son paletas categóricas o decorativas documentadas, válidas según el DS.
- No hace falta crear un mapeador de errores nuevo: `lib/core/errors/user_error_message.dart` ya existe; solo falta adoptarlo.
- Auditoría basada en código: los problemas de jerarquía visual están inferidos y conviene confirmarlos con capturas reales (claro/oscuro, texto al 200%).
