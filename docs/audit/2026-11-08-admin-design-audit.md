# Auditoría de diseño — SACDIA Admin

**Fecha:** 2026-11-08
**Alcance:** `sacdia-admin` en la rama `feat/camporee-event-attachments`. La rama tiene cambios sin commit en camporees y se leyeron tal cual. Se auditaron los fundamentos del design system, el shell, el home y las ~158 páginas por dominio.
**Lentes:**
- `ui-ux-pro-max`: prioridades UX, con la accesibilidad primero.
- `design-taste-frontend`: reglas de *app screens*.
- `emil-design-eng`: polish de interacción y motion.

**Método:**
- `pnpm audit:design-system`: 0 errores y 43 warnings.
- Cinco auditorías de código en paralelo, una por área.
- Verificación en navegador con la sesión `coordinator@sacdia.com`, a 1440×900 y 375×812.

Los hallazgos críticos de los subagentes se verificaron en código antes de incluirlos. Lo que no se pudo confirmar va marcado como *no verificado*.

---

## Veredicto

La base es buena. Hay tokens neutros, Geist, Hugeicons sin fugas de Lucide y foco visible en todos los primitivos. No hay ni un `transition-all` en `src/` y `prefers-reduced-motion` está bien cubierto. El home por alcance ya responde una pregunta. El DS tiene dirección escrita (§0), algo que pocos proyectos tienen.

El problema es la **ejecución desigual**. El sistema dice una cosa, `globals.css` otra y las pantallas hacen tres variantes de cada patrón. Los tres fallos de fondo son:

1. **Contraste roto en los colores semánticos.** `text-success`, `text-warning` e `text-info` usan el hex de marca como texto. Dan 2.26, 1.67 y 2.93:1 sobre blanco, con unos 135 usos. En oscuro, `text-destructive` da 3.81:1. Es el único fallo que afecta a todas las pantallas.
2. **Patrones triplicados.** Hay tres orquestadores de catálogo (12/10/1 páginas) y cinco formas de crear o editar (modal intercept, página, Dialog, Sheet, hand-rolled). Hay dos `EmptyState` y unos 28 vacíos caseros. La tabla aparece con `DataTableShell` en algunos módulos y con contenedores propios en el resto. La versión móvil solo existe en 3 módulos.
3. **Robustez de estados.** No hay ningún `error.tsx`: una excepción en cualquier página tira el shell. `loading.tsx` existe en 8 de ~158 rutas. Los errores reemplazan la página entera en vez de su bloque y casi nunca ofrecen "Reintentar".

Lo visual (KPIs en tarjetas, icon tiles, bandas de cabecera, barras de color) es secundario frente a esos tres puntos.

---

## Top 18 priorizado

| # | Sev | Hallazgo | Dónde | Fix |
|---|---|---|---|---|
| 1 | 🔴 | `--success` `#4FBF9F`, `--warning` `#FBBD5E` e `--info` `#2EA0DA` se usan como texto y fallan AA (2.26, 1.67, 2.93). Hay 69 usos de `text-success` y 61 de `text-warning`. | `src/app/globals.css:131-135`, `ui/badge.tsx:28-30`, `ui/status-badge.tsx:41-46` | Añadir tokens `--success-text`, `--warning-text` e `--info-text` oscurecidos (≥4.5:1) y migrar los usos como texto. El hex de marca queda solo para rellenos y marcas. |
| 2 | 🔴 | En oscuro, `text-destructive` `#DC2626` sobre la tarjeta `#141414` da 3.81:1, en 321 usos. | `globals.css:215` | `--destructive` oscuro a ~`#F87171`, o un `--destructive-text` aparte. |
| 3 | 🔴 | No hay ningún `error.tsx`, solo `global-error.tsx`, en inglés (`lang="en"`), sin marca y sin salida. | `src/app/global-error.tsx:17-23` | Crear `(dashboard)/error.tsx` (cliente, shell intacto, Reintentar) y reescribir `global-error` en español. |
| 4 | 🔴 | El home reemplaza **toda la página** por el error y no ofrece Reintentar. | `dashboard/page.tsx:36-48`, `operations-dashboard-error.tsx:95-117` | Error dentro del bloque que falló, con `router.refresh()`. |
| 5 | 🔴 | Clubes: "Editar" enlaza a `?tab=edit`, que no existe. La búsqueda filtra solo la página actual mientras el paginador muestra el total global. | `clubs-list-client.tsx:330, 156-160`, `clubs/[id]/tab-utils.ts:3-9` | Abrir el modal de edición (DS §6.1). Enviar `q` al servidor. |
| 6 | 🔴 | Tres orquestadores de catálogo (PhaseE 12, `*PageClient` 10, `CatalogEntityPage` 1). El DS dice que "exclusivamente" se usa `CatalogEntityPage`. | `DESIGN-SYSTEM.md:1123`, `components/catalogs/*` | Elegir uno (PhaseE es el más completo), migrar los 11 restantes y corregir el doc. |
| 7 | 🔴 | 10 catálogos con paginación hardcodeada "Anterior"/"Siguiente" fuera de i18n y búsqueda sin label ni `aria-label`. | `catalogs/*/[x]-page-client.tsx` (p. ej. `churches-page-client.tsx:260-268`) | `DataTablePagination` + `aria-label`. |
| 8 | 🔴 | No hay skip link. El `<header>` está dentro del `<main>`, así que no hay landmark `banner`. Para llegar al contenido hay que tabular por unos 40 enlaces del sidebar. | `(dashboard)/layout.tsx:69-82`, `ui/sidebar.tsx:354` | `<a href="#main">` y `<main>` solo alrededor del contenido. |
| 9 | 🔴 | La revisión de evidencias no tiene versión móvil (scroll horizontal). Lo mismo pasa en clubs, supervisión, membresía y section-rankings. | `evidence-review-table.tsx:188-228`, `clubs-list-client.tsx:248-342` | Lista de dos líneas por debajo de `md`, como en `users-table`. |
| 10 | 🔴 | En reportes/supervisión hay 6 selects solo con placeholder, sin `Label`. | `reports-supervision-client.tsx:197-302` | `Label htmlFor`. |
| 11 | 🟡 | Las etiquetas de grupo del sidebar son `#5c5c5c` al 70% sobre `#fafafa`, ≈3.3:1 (medido en navegador). | `ui/sidebar.tsx:455` | Quitar la opacidad (el `#5c5c5c` pleno da 6.4:1). |
| 12 | 🟡 | El sidebar tiene 9 grupos, unos 40 enlaces y 3 niveles en Catálogos, sin conteos en las colas de acción (el home ya los calcula). La marca no muestra el alcance (unión, campo). | `navigation/sidebar/sidebar-items.ts`, `app-sidebar.tsx:46-61` | Agrupar en unos 6 grupos, poner Catálogos y Sistema en una entrada con índice, contador solo en colas y el alcance bajo la marca. |
| 13 | 🟡 | KPIs como 4 tarjetas con barras de progreso de color (home, club, usuario, finanzas con tile de ícono). | `operations-kpi-row.tsx:22,47`, `clubs/detail/stats.tsx:24-37`, `finances-summary-cards.tsx:69,116` | Un solo contenedor dividido con `divide-x`, solo tipo y barra gris. Color solo cuando hay riesgo. |
| 14 | 🟡 | El DS contradice al código y se contradice a sí mismo: §2 en oscuro, §2.4 ring y disabled, §2.7/§8.3 contra el changelog, §12.1 con `transition-all`, §3.3 contra §3.2, §7.12 `ModuleListPage` (no existe), §16 scrollbar (no existe), 0.97 contra 0.96. | `DESIGN-SYSTEM.md` | Reescribir §2 desde `globals.css`, borrar §7.12 y §16 y consolidar el changelog en el cuerpo. |
| 15 | 🟡 | Hay 40 textos de 9 a 10.5px y unos 180 `text-[Npx]` fuera de escala. | top: `camporee-detail-info-tab.tsx`, `create-event-drawer.tsx`, `event-row.tsx` | Token `text-2xs` (11px) en `@theme` y subir todo lo que esté por debajo de 11px. |
| 16 | 🔴 | Insumos de camporee: entregar o alternar sin estado pendiente, así que un doble clic duplica la entrega. | `camporee-supplies-tab.tsx:198-239` | `loading` y guard por línea, validar el máximo restante. |
| 17 | 🔴 | Un error de carga se ve como "vacío" en el detalle del camporee, finanzas, bandejas, plantillas e inventario (`catch {}` o toast + lista vacía). | `campamentos/[id]/page.tsx:271-341`, `finances-dashboard.tsx:155,198` | Estado de error en el bloque con Reintentar. |
| 18 | 🟡 | La pestaña Eventos hace `router.push` al montar: re-render completo del servidor y entrada extra en el historial. La fila tiene una franja de color al hover. | `events-toolbar.tsx:66-83`, `event-row.tsx:147-153` | Push solo por acción del usuario, `replace` y quitar la franja. |

---

## 1. Fundamentos del design system

### 1.1 Tokens y contraste (`globals.css`)

| Par | Ratio | AA texto |
|---|---|---|
| foreground `#0A0A0A` / fondo | 19.8 | ✅ |
| muted-fg `#666` / fondo · / muted | 5.74 · 5.27 | ✅ |
| sidebar-fg `#5C5C5C` / sidebar | 6.41 | ✅ |
| etiqueta de grupo del sidebar (`/70`) / sidebar | ≈3.3 | ❌ |
| primary `#0073EA` / blanco | 4.53 | ✅ (justo) |
| **success `#4FBF9F` / blanco** | **2.26** | ❌ |
| **warning `#FBBD5E` / blanco** | **1.67** | ❌ |
| **info `#2EA0DA` / blanco** | **2.93** | ❌ |
| `brand-secondary-dark` `#2D8A70` ("texto success" en DS §2.1) | 4.22 | ❌ |
| `brand-accent-dark` `#B8862B` ("texto warning" en DS §2.1) | 3.24 | ❌ |
| destructive / blanco | 4.83 | ✅ |
| **Oscuro: destructive / card `#141414`** | **3.81** | ❌ |
| Oscuro: muted-fg / card, primary `#4C9AFF` / card | 7.13 · 6.47 | ✅ |
| border `#EBEBEB` / fondo | 1.19 | ✅ (rango 1.1–1.3) |

- La paleta de gráficos tiene 5 tonos saturados (azul, coral, verde, ámbar, morado), con riesgo de arcoíris. Casi no se usa: el uso real es `StatusBadge progress-*`, que pone el *chart color* como texto sobre un tinte del 12% y falla.
- `StatusBadge` corrige localmente el ícono con `color-mix(... black 15-25%)` (`status-badge.tsx:51-52`). Es la solución correcta, pero debe vivir en un token y no en un parche por componente.
- `--disabled-bg` y `--disabled-foreground` (DS §2.4) **no existen**. Disabled es `opacity-50` uniforme, y los placeholders deshabilitados quedan ilegibles.

### 1.2 Primitivos `ui/`

Bien resuelto:
- Alturas coherentes (`h-9`) en Input, Select, Button y Tabs.
- Radios por rol aplicados.
- Foco `ring-[3px]` en todos.
- `motion-reduce:` en button, input, switch, sheet y skeleton.

| Sev | Problema | file:line | Fix |
|---|---|---|---|
| 🟡 | Las superficies flotantes llevan `shadow-2xl` (blur de 56px) más `ring-1`, y el token ya trae anillo: doble anillo y sombra excesiva. | `dropdown-menu.tsx:48`, `popover.tsx:34`, `select.tsx:74`, `context-menu.tsx:74`, `menubar.tsx:81` | `shadow-lg` con un solo anillo |
| 🟡 | El overlay de AlertDialog usa `bg-black/80` + `backdrop-blur-xs`. Dialog usa `black/40` sin blur, así que hay dos overlays distintos y uno con glass. | `alert-dialog.tsx:41` vs `dialog.tsx:48` | Igualar a Dialog |
| 🟡 | `Table` no aplica `tabular-nums` por defecto, y las celdas numéricas se alinean a la izquierda en clubs, achievements y notificaciones. | `table.tsx:79` | `tabular-nums` en la celda y una utilidad `num` alineada a la derecha |
| 🔵 | ContextMenu sub y Sheet llevan `border` y `shadow-lg` a la vez. | `context-menu.tsx:139`, `sheet.tsx:71` | Una de las dos |
| 🔵 | Switch y Checkbox usan medidas arbitrarias (`h-[18.4px]`, `rounded-[6px]`) y Checkbox no anima el fondo. | `switch.tsx:20`, `checkbox.tsx:18` | Tokens |

### 1.3 Motion (Emil)

| Antes | Después | Por qué |
|---|---|---|
| `PRESS_SCALE = "0.97"` sin uso; Button y Select usan `active:scale-[0.96]` | Una sola constante consumida por los primitivos (0.97) | El DS dice 0.97 y el código 0.96. La constante huérfana es deuda. |
| `active:scale` en `SelectTrigger` | Solo en botones | Un campo que abre un menú no es un botón; la presión resta precisión. |
| `ease-out` genérico en Badge y Switch | `ease-[var(--ease-out-expo)]` | Una sola curva de entrada en todo el panel |
| Sidebar `ease-linear` en width | `--ease-drawer` (`cubic-bezier(0.32,0.72,0,1)`) | Lo lineal se siente mecánico |
| `NavigationMenu` `zoom-in-90` | `zoom-in-95` | Igual al resto de overlays |
| Chevron y Collapsible del sidebar con 200ms | ≤120ms o sin animación | Acción de alta frecuencia: debe sentirse instantánea |
| `animate-ping` perpetuo en el chip del hero del club | Punto estático | Movimiento sin propósito en una pantalla de trabajo |
| Overlay de AlertDialog sin duración de salida | Salida de 150ms (más rápida que la entrada) | Asimetría entrada/salida |

Bien resuelto: 0 `transition-all`, 0 `ease-in`, 0 `scale(0)`, ⌘B instantáneo, tooltips con `instant-open`, sin stagger en dashboards y regla global de reduced motion (`globals.css:338-347`).

### 1.4 Componentes compartidos

| Componente | Estado |
|---|---|
| `PageHeader` | 109 de 164 páginas. Los `<h1>` crudos son legítimos (login, heros), pero hay dos tamaños para el mismo rol: `users/detail/hero.tsx:67` (`text-[26px]`) y `clubs/detail/hero.tsx:63` (`text-3xl`). |
| `EmptyState` | 113 archivos, pero `ui/empty.tsx` está duplicado con 0 usos, y hay **28 vacíos caseros** con `border-dashed` y círculo propio. |
| `StatusBadge` vs `Badge` | 130 frente a 201 usos. `Badge default/soft` aparece usado para estados (prohibido por el DS). |
| `DataTableShell` | Solo en users, reports, periodic-reports y roles. El resto usa contenedores propios. |
| `LoadingSkeleton`, `ConfirmDialog`, `ModuleListPage` | Documentados, **no existen**. Cada pantalla arma su propio skeleton. |
| Icon tiles | Unas 34 cajas de ícono en unos 30 archivos (`catalog-crud-page.tsx:401`, `permissions-table.tsx:217`, `roles-table.tsx:562`, hub de configuración `:74`). `bg-primary/10` aparece 31 veces. |

### 1.5 Fugas

- Hex y paleta Tailwind: pocos y concentrados (achievements, `ui/chart.tsx`, dos detail pages de certificados, `materials/badge-tones.ts`, `rubrics-editor.tsx:113`, `camporee-payment-balance.tsx:576`).
- Tipografía: 8 tamaños de escala más unos 19 arbitrarios. `font-bold` solo 22 veces. `uppercase` solo en 2 sitios. Bien.
- Íconos: 0 imports reales de `lucide-react`. Excepción: `nav-main.tsx:6` toma `ChevronRight` del shim con naming Lucide, distinto al resto del sidebar.
- i18n: unos 13 aria-labels y textos en español hardcodeados (audit), además de `toLocale…("es-MX")` fijo en 10 sitios.

### 1.6 El documento `DESIGN-SYSTEM.md`

Tiene 2003 líneas y cuatro capas de changelog: Ember (abril), Scout Vibrante (junio), Crisp (octubre) y antislop (octubre). Las reglas vigentes viven en un bloque de changelog arriba y el cuerpo conserva valores viejos.

| Sección | Doc | Código |
|---|---|---|
| §2.2/2.3 oscuro | muted `#1C1C1C`, accent `#1F1F1F`, primary `#0073EA` | `#232323`, `#2A2A2A`, `#4C9AFF` |
| §2.4 | ring `color-mix 45%`, `--disabled-*` | azul pleno; disabled no existe |
| §2.7, §8.3 | íconos sobre `bg-primary/10` | changelog: `bg-muted` |
| §12.1 KPI ejemplo | `transition-all`, tile `bg-primary/10`, `font-bold` | contradice §9.2 y el changelog |
| §3.3 | "nunca tamaño arbitrario" | §3.2 lista `text-[13px]` y `text-[11px]` |
| §5.1 / §5.3 / §5.12 | `bg-primary`, Card con borde, Skeleton `rounded-xl` | `bg-primary-solid`, `shadow-card`, `rounded-md` |
| §7.12, §16 | `ModuleListPage`, `.custom-scrollbar` | no existen |
| §9.2 | press 0.97 | 0.96 |
| §20 | "iconos de lucide-react" | Hugeicons |
| §13.4 | glows `blur-3xl` en login | changelog: login sin círculos decorativos |

**Recomendación:** reescribir el doc como fuente única. Cuerpo = estado actual. Changelog breve al final. Generar las tablas de §2 desde `globals.css` para que no vuelvan a divergir.

---

## 2. Shell y navegación

| Sev | Problema | file:line | Fix |
|---|---|---|---|
| 🔴 | No hay skip link y el header queda dentro de `<main>`. | `(dashboard)/layout.tsx:69-82` | Ver Top #8 |
| 🔴 | Sidebar: 9 grupos, unos 40 enlaces, 3 niveles en Catálogos y sin "frecuentes". | `sidebar-items.ts:110-889` | Ver Top #12 |
| 🔴 | Ningún ítem del sidebar lleva contador. Solicitudes, Validaciones y Autorizaciones son colas de acción. | `sidebar-items.ts` (sin `badge:`) | Contador desde la misma fuente que la cola del home |
| 🟡 | Menú de usuario duplicado: `NavUser` (footer) y `HeaderUserMenu` (header). "Cerrar sesión" está hardcodeado en ambos. | `nav-user.tsx:74`, `header-user-menu.tsx:49` | Dejar uno solo, con i18n |
| 🟡 | No hay selector de idioma en el shell, aunque existen 4 locales. | `layout.tsx:86-89` | En el menú de usuario |
| 🟡 | **Verificado en navegador:** en `/dashboard/clubs/activities`, "Clubes" (Gestión de clubes) y "Actividades" (Campamentos) aparecen activos a la vez. El breadcrumb dice "Clubes › Actividades" y el sidebar lo agrupa en Campamentos. | `sidebar-items.ts` (`activeMatch: prefix` de clubs) | Decidir dónde vive Actividades (IA) y que `activeMatch` del padre excluya rutas con dueño propio |
| 🟡 | Los padres colapsables se pintan cerrados y abren tras hidratar, con salto en el sidebar. | `nav-main.tsx:127-135` | `useState(shouldBeOpen)` |
| 🟡 | Targets por debajo de 44px en móvil: ítems de 36px, subítems de 28px, trigger de 32px, ThemeSwitcher de 36px, avatar de 32px sin `aria-label`. | `sidebar.tsx:529,720,304`, `header-user-menu.tsx:32-37` | `size-11` por debajo de `md` |
| 🔵 | Header: buscador ⌘J a la izquierda y el resto de la barra vacía en escritorio. | captura 1440 | Aceptable; podría mostrar el alcance |

## 3. Home `/dashboard`

**Pregunta que responde:** "¿Qué necesita atención en mi alcance?". El diseño por modo (supervise/dispatch) es correcto y la tabla de brechas está ordenada y sin zebra.

| Sev | Problema | file:line | Fix |
|---|---|---|---|
| 🔴 | Un error sustituye la página completa y no hay Reintentar. | `dashboard/page.tsx:36-48` | Ver Top #4 |
| 🟡 | **Verificado:** 4 tarjetas KPI separadas, cada una con barra de color, todas a 24px. Ninguna cifra lidera. Las barras verdes de "100%" y "1/1" ponen color en el cromo. | `operations-kpi-row.tsx:22,37,47`, `operations-meter.tsx:5-9` | Un contenedor dividido. Cifra-respuesta a 30px. Barra gris y color solo bajo umbral. |
| 🟡 | Cabecera con 5 chips de metadatos (alcance, "Respuesta en caché", año eclesiástico, último mes, calculado). "Respuesta en caché" es jerga técnica para el usuario. | `operations-dashboard-chrome.tsx:69-101` | Dejar alcance y mes. `computed_at` como sello de frescura con refresh y el estado de caché en un tooltip. |
| 🟡 | **Verificado:** fila desigual. "Requiere atención" (1 fila) termina unos 40px antes que "Clubes". | `operations-home-layout.tsx:57-59` | `items-start` o equilibrar contenido |
| 🟡 | **Verificado:** "Formación por clase" tiene una sola serie con leyenda ("Guías Mayores 39") que repite el valor de la barra. | `class-enrollments-chart.tsx:38-54` | Sin leyenda con una serie, un solo tono |
| 🟡 | El skeleton usa siempre `1.6fr/1fr`, pero dispatch invierte el orden, y las tarjetas miden `h-32` frente a unos 96px reales, lo que provoca un salto de layout. | `dashboard/loading.tsx:24` | Skeleton por modo |
| 🟡 | La tabla de brechas no tiene tope y en móvil sigue siendo tabla de 3 columnas. | `operations-gap-table.tsx:42,70-97` | Top N con "Ver todo"; lista de 2 líneas en `<sm` |
| 🔵 | El título "Inicio" no dice de qué alcance se trata. | `page-header.tsx:61` | `meta.scope.name` como subtítulo o título |
| 🔵 | Pie con contadores en `text-xs` y `<details>` "Calidad de datos" sin foco estilizado. | `operations-data-quality.tsx:24` | `focus-visible:ring` |

## 4. Auth y públicas

| Sev | Problema | file:line | Fix |
|---|---|---|---|
| 🟡 | No hay enlace "¿Olvidaste tu contraseña?" en el login. | `login-form.tsx` | Enlace bajo el campo |
| 🟡 | El éxito de reset/verify no tiene CTA a login (pantalla sin salida). | `public-auth-parts.tsx:29-53` | Botón "Ir al inicio de sesión" |
| 🟡 | Los errores solo aparecen en un banner global, sin `aria-invalid` ni `aria-describedby` por campo. | `login-form.tsx:90-98` | Error junto al campo |
| 🟡 | El toggle de contraseña es un ícono de 16px sin área (<44px). Hay texto de 11px en la marca. | `login-form.tsx:147-160, 70,76` | `size-11`; 12px mínimo |
| 🔵 | El logo con `alt="SACDIA"` duplica el texto de al lado. | `login-brand-panel.tsx:12` | `alt=""` |

Bien resuelto: redirección si ya hay sesión, `role="alert"`, token sin indexar con `no-referrer`, entrada animada solo en login (baja frecuencia).

---

## 5. Pantalla a pantalla — Clubes, usuarios, evidencias, rankings, reportes

### `/dashboard/clubs`
**Pregunta:** ¿qué clubes tengo y en qué estado están?

| Sev | Problema | file:line |
|---|---|---|
| 🔴 | "Editar" apunta a `?tab=edit`, que no existe | `clubs-list-client.tsx:330` |
| 🔴 | La búsqueda filtra solo los 20 de la página | `clubs-list-client.tsx:156-160` |
| 🟡 | **Verificado:** en 375px la tabla hace scroll dentro del marco y la Iglesia queda cortada. El panel "Filtros" empuja la primera fila al 73% de la pantalla. | `clubs-list-client.tsx:176-182, 248-342` |
| 🟡 | **Verificado:** encabezados a 14px en tinta, cuando el DS pide 12px gris. "Secciones activas" (3/3) va alineado a la izquierda. "Activo" se repite en todas las filas. | `table.tsx`, `clubs-list-client.tsx` |
| 🟡 | No hay `loading.tsx`. El error muestra banner y `EmptyState` duplicados, sin reintentar. | `clubs/page.tsx:57, 74-88` |

### `/dashboard/clubs/[id]`
Hero con h1 y breadcrumbs, sin botón Volver, y pestañas en la URL. Bien.

- 🟡 4 KPI en `Card` con ícono (`stats.tsx:24-37`).
- 🟡 `window.confirm` para la sucesión de director y `<select>` nativo sin label (`succession-block.tsx:48,64`).
- 🔵 `animate-ping` perpetuo (`hero.tsx:170`).
- 🔵 Textos de 11px.

### `/dashboard/users` y `/users/[userId]`
`DataTableShell`, tarjetas móviles y `loading.tsx`. Es el **modelo a copiar** para listados.

- 🟡 Hasta 3 marcas de estado por fila, y `Badge` + `StatusBadge` mezclados (`users-table.tsx:229-265`).
- 🟡 El detalle tiene KPIs sin valor operativo y pestañas sin URL (`users/[userId]/page.tsx:211-254, 301`).
- 🔵 `es-MX` fijo.

### Evidencias y carpetas anuales
Patrón B de cola de revisión bien aplicado (aprobar/rechazar y lote).

- 🔴 Sin versión móvil (`evidence-review-table.tsx:188-228`).
- 🟡 Seis vacíos caseros con `border-dashed`.
- 🟡 Strings fijos en español.
- 🟡 `PointsAllocationBar` es una caja teñida y recorta la sobreasignación al 100%, con lo que oculta el exceso.
- 🔵 Archivos de 1.4k y 1.3k líneas (`templates-client-page.tsx`, `evaluation-client-page.tsx`).

### Rankings (`annual-folders/rankings`, `section-rankings`, `member-rankings`)
Barras al ratio real con "x/máx". Bien.

- 🟡 Top 3 con fila teñida y trofeo (decoración sobre dato, `rankings-client-page.tsx:125-129`).
- 🟡 Hay que pulsar "Buscar" para aplicar filtros. "Cargando" es texto en vez de `<Button loading>`. Buscar y Recalcular tienen el mismo peso.
- 🟡 Columna de tipo de club repetida en todas las filas.
- 🟡 `section-rankings` no tiene barra.
- 🔵 Botón "Volver" junto a breadcrumbs en breakdown (`member-rankings/[enrollmentId]/breakdown/page.tsx:64-79`, `clubs/import/page.tsx:54-61`).

### Reportes
Tiene `loading.tsx`, `DataTableShell` y tarjetas móviles.

- 🔴 Supervisión: 6 selects sin label.
- 🟡 Generar y Enviar (las acciones frecuentes) están solo en el kebab (`reports-list-client.tsx:437-450`).
- 🟡 Supervisión sin `DataTableShell` y con empty y paginación propios.
- El reporte mensual de 2 páginas no se toca.

### Solicitudes, coordinación, cierre de año
- 🟡 `EndpointErrorBanner state="missing"` sin reintentar (`requests/membership/page.tsx:39-44`, `year-end/page.tsx:41`, `coordination/page.tsx:55`).
- 🟡 Tablas con `overflow-x-auto` sin versión móvil.

### `/dashboard/clubs/activities` (verificado en navegador)
| Sev | Problema |
|---|---|
| 🔴 | Con el coordinador, el API responde "Se requiere una asignación de club activa…". La pantalla muestra **a la vez** el error crudo del backend, "0 actividades encontradas" y el calendario vacío. Son estados contradictorios, y el gate de pantalla deja entrar a un rol que el API rechaza. |
| 🟡 | Doble ítem activo en el sidebar (ver §2). |
| 🔵 | Mes formateado como "Noviembre De 2026" (capitalización por palabra). |
| 🔵 | El conteo "0" va en un pill aparte del texto. |

---

## 6. Pantalla a pantalla — Catálogos, configuración, RBAC, sistema

### Inventario de patrones
| Patrón | Páginas | Crear/editar |
|---|---|---|
| `PhaseECatalogCrudPage` | 12 (activity-types, allergies, diseases, medicines, relationship-types, inventory/finance-categories, class-modules, class-sections, classes, master-honors, camporee-event-types) | Dialog |
| `*PageClient` hand-rolled | 10 (club-types, countries, divisions, unions, districts, churches, honors, honor-categories, local-fields, club-ideals) | Dialog |
| `CatalogEntityPage` → `CatalogCrudPage` | 1 (ecclesiastical-years) | Dialog |
| configuration/roles | — | Crear con modal intercept, **editar en página** |
| configuration/achievements | — | Modal intercept (**modelo** del DS §6.1) |
| notificaciones | — | Sheet compose |

### Orquestadores
| Sev | Problema | file:line |
|---|---|---|
| 🔴 | master-honors: Dialog de `max-w-6xl` con editor de reglas, cuando la excepción §6.1.1 es solo para 1-3 campos | `phase-e-catalog-crud-page.tsx:908-920, 1475, 1522` |
| 🔴 | 10 `*PageClient`: paginación "Anterior/Siguiente" hardcodeada y búsqueda sin label | `club-types-page-client.tsx:183-195, 249-262` (+9) |
| 🔴 | `CatalogCrudPage`: banda en la cabecera de tabla (`bg-muted/40`) y tile `Package` `bg-primary/10` en cada tarjeta móvil | `catalog-crud-page.tsx:77, 401-403` |
| 🟡 | PhaseE: filtros en una caja `bg-muted/20` con título y subtítulo. `overflow-x-auto` + `min-w-max` provocan scroll horizontal en móvil | `phase-e-catalog-crud-page.tsx:1161-1168` |
| 🟡 | Columna de acciones sticky con `bg-card`: el fondo no sigue el hover. En métodos de pago, además, hay una sombra hardcodeada | `phase-e…:1406`, `payment-methods-table.tsx:104,143` |
| 🟡 | Eliminar en 10 catálogos usa `AlertDialogAction` estándar (no `destructive-solid` + `loading`) | `club-types-page-client.tsx:289` (+9) |
| 🟡 | Vacío = fila `colSpan` hardcodeada | `churches-page-client.tsx:239`, `unions-page-client.tsx:243` |

### Por pantalla
- **configuration (hub):**
  - 🟡 Tiles de ícono `size-10`.
  - 🟡 No lista audit, local-field ni investiture-settings (`configuration/page.tsx:22-78`).
- **roles/[roleId]:**
  - 🟡 Edición en página.
  - 🟡 Búsqueda sin `aria-label` (`roles-table.tsx:330, 363`).
- **permissions:**
  - 🟡 Tile `bg-primary/10` en las tarjetas móviles.
  - 🔵 Botón `p-1` (`permissions-table.tsx:215-233`).
- **matrix:**
  - 🟡 Cabecera de rol en 3 niveles con un `role_name` mono de 10px (`permissions-matrix.tsx:380-395`).
- **variables:**
  - 🟡 Sin `DataTableShell` ni paginación (`system-config-table.tsx:52`).
- **achievements:**
  - 🟡 Puntos alineados a la izquierda (`achievements-crud-page.tsx:443`).
- **notifications/history:**
  - 🟡 Contadores centrados (`notification-history-table.tsx:154-155`).
- **audit:**
  - 🟡 Sin skeleton inicial (`audit-logs-viewer.tsx:235`).
- **classes/[classId] y diálogos de clase/scoring:**
  - 🔴 Strings fijos ("Selecciona una especialidad", "Cancelar", "Ej. Uniforme").
- **rbac/user-permissions:**
  - 🔴 Placeholder fijo sin label (`user-permissions-search.tsx:123`).
- **investiture-settings:**
  - 🟡 `catch {}` silencioso: selector vacío sin explicación.
  - ✅ Es el mejor formulario del alcance: un solo Save, `loading` y skeleton.
- **system/jobs:**
  - 🟡 Error como Card de texto sin reintentar (`system/jobs/page.tsx:60-76`).

---

## 7. Pantalla a pantalla — Camporees y módulos operativos

Archivos con cambios **sin commit** en la rama actual: `camporee-leaderboard.tsx`, `camporee-score-breakdown.tsx` (nuevo), `event-attachments-section.tsx` (nuevo), `event-form-page.tsx`, `camporee-detail-tabs.tsx`, `campamentos/[id]` y `union/[id]/page.tsx`.

Patrón de fallo dominante en este bloque: **un error de carga se ve como lista vacía**. Aparece un toast pasajero, luego "sin datos", y el usuario no puede distinguir "no hay" de "falló".

### `/dashboard/campamentos` (lista)
RowActions patrón A y `flagStatusIntent` correctos.
- 🟡 Error duplicado (banner y EmptyState) sin reintentar (`campamentos/page.tsx:54-66`).
- 🟡 Tabla artesanal sin `DataTableShell` (`camporees-view.tsx:143`).
- 🔵 La carga es texto en una caja de 160px.

### `/campamentos/[id]` y `/union/[id]` (detalle)
| Sev | Problema | file:line |
|---|---|---|
| 🔴 | Unas 15 consultas **secuenciales** más un fan-out de 3×N por evento antes de pintar. `loading.tsx` genérico que no coincide con el layout | `[id]/page.tsx:208-396` |
| 🔴 | Errores tragados en eventos, plantillas, sedes, jueces, órdenes y pendientes: una falla se ve como "sin eventos" | `[id]/page.tsx:271,282,314,324,333,341` |
| 🟡 | 11 pestañas. La pestaña activa no vive en la URL. Nombres en español fijo. Dos contadores por pestaña sin etiqueta accesible | `camporee-detail-tabs.tsx:235-325` |
| 🟡 | `CamporeeInfoCard` duplica la pestaña Información. Card dentro de Card | `camporee-info-card.tsx:51-117` |
| 🔵 | `[id]` y `union/[id]` repiten unas 200 líneas de normalizadores | — |

### Pestaña Eventos (`timeline/*`)
| Sev | Problema | file:line |
|---|---|---|
| 🔴 | `EventsToolbar` hace `router.push` en un effect al montar y en cada filtro. Re-renderiza el servidor (15+ consultas) y ensucia el historial (atrás = 2 clics). **Verificado en código** | `events-toolbar.tsx:66-83` |
| 🔴 | Grid de 8 columnas de unos 1118px fijos dentro de `overflow-hidden`: se recorta por debajo de unos 1300px útiles (*verificar en navegador*) | `event-row.tsx:142` |
| 🟡 | **Franja de color lateral de 3px al hover**, que va contra la regla de no usar franjas en tarjetas o filas. **Verificado** | `event-row.tsx:147-153` |
| 🟡 | Hasta 5 marcas de color por fila. Lápiz suelto además del "⋯". `cursor-pointer` sin onClick | `event-row.tsx:143,191-298` |
| 🟡 | Los filtros están ocultos para el rol de solo lectura. Hay textos de 10-11px y plurales fijos ("1 eventos programados") | `events-timeline-view.tsx:53`, `event-day-card.tsx:140` |
| 🔵 | 4 KPI con ícono sin decisión asociada | `events-summary-kpis.tsx:22-68` |

### Formulario de evento, adjuntos y rúbricas
El formulario tiene pasos, `<Button loading>` y mapeo de error al paso. Bien.
- 🟡 Los adjuntos se suben y se borran al instante, fuera del `<form>`, así que "Cancelar" no los revierte y no se avisa (`event-attachments-section.tsx:100,119`).
- 🟡 Sin progreso por archivo.
- 🟡 Íconos sueltos abrir/eliminar.
- 🟡 Rúbricas: español fijo, `key={index}` en filas editables y estado válido/inválido solo por color (`rubrics-editor.tsx:90-123`).
- 🔵 El guard `required` sr-only no tiene dónde mostrar su error.

### Jueces y puntajes
Bloquea el guardado mientras carga el puntaje previo y avisa conflictos. Bien.
- 🟡 Capturar puntajes es sección por sección con un Select, sin lista de estado (calificada/pendiente) ni "siguiente" (`event-score-entry-panel.tsx:396-420`).
- 🟡 El input numérico fuerza `?? 0`: al borrar vuelve "0" y escribir "8" da "08" (`:475-490`).
- 🔵 El total se repite 3 veces, con anillos anidados.
- 🔵 El selector de eventos son píldoras con scroll, sin `aria-pressed`.

### Clasificación (sin commit)
El rango aparece como dato, con `tabular-nums` y un desglose con rúbricas. Bien.
- 🟡 Banda de cabecera `bg-muted/20` y `rounded-2xl ring-1` en vez del shell.
- 🟡 Empates sin tratar, sin marca de líder ni barra de proporción (`camporee-leaderboard.tsx:76-94`).
- 🔵 Ranking y matriz en la misma pestaña.

### Pagos, órdenes, pedidos e insumos
Aprobar y rechazar visibles por fila (patrón B). Bien.

| Sev | Problema | file:line |
|---|---|---|
| 🔴 | `deliver`, `toggleSlot` y `toggleProduct` no tienen estado pendiente: un doble clic **duplica entregas**. Tampoco se valida contra lo restante. **Verificado** | `camporee-supplies-tab.tsx:198-239` |
| 🔴 | "Total" parece sumar pagos rechazados y pendientes (*verificar*). Hay 8 tarjetas KPI apiladas con dos estilos | `camporee-payments-panel.tsx:93-100`, `camporee-payment-balance.tsx:545-608` |
| 🟡 | El saldo se calcula con un máximo de 100 miembros pero el esperado usa el total, así que el cuadre no cierra con más de 100 (*no verificado*) | `payments-tab:74-80` |
| 🟡 | Monto alineado a la izquierda. "Cobrado" en `emerald` crudo. No hay barra cobrado/esperado | `camporee-payment-balance.tsx:576` |
| 🟡 | "Marcar pagado" sin `loading` ni guard. Tablas HTML crudas con `<select>` nativo | `camporee-supplies-tab.tsx:307-710` |

### Bandeja de pedidos, plantillas y jueces
- 🟡 La bandeja es una cola de revisión sin aprobar/rechazar visibles. Tiene tabla cruda y error como toast + vacío (`camporee-order-review-tray.tsx:37-122`).
- 🟡 Plantillas: un 429 se silencia como lista vacía (`plantillas/page.tsx:54-56`).
- 🔵 El "sin permiso" se muestra distinto en jueces, pedidos y payment-orders.

### `/dashboard/finances`
Monto con signo, a la derecha y tabulado. Bien.
- 🔴 `catch { setSummary(null) }` y `setResult(null)`: un fallo del API se ve como "sin transacciones". **Verificado** (`finances-dashboard.tsx:155,198`).
- 🟡 KPIs con círculo de ícono teñido, gasto en rojo sin signo y `translate-y` al hover en tarjetas no interactivas (`finances-summary-cards.tsx:64-105`).
- 🟡 `Badge destructive` saturado en cada gasto: tres señales para lo mismo.
- 🟡 Sin cancelar peticiones al cambiar el mes. `limit` 500 con filtro en cliente.
- 🔵 Club y sección viven en estado local, no en la URL.

### `/dashboard/payment-orders`
- 🟡 La cola de revisión no es el filtro por defecto y no tiene conteo.
- 🟡 Tabla cruda, total sin alinear, "abrir detalle" como único botón, fecha con locale `undefined` (riesgo de hidratación) (`payment-orders-tray.tsx:32-190`).

### `/dashboard/inventory`
- 🟡 4 selects en cascada sin label.
- 🟡 Carrera sin abort y carga como texto (`inventory-view.tsx:109-325`).

### `/dashboard/materials/*`
Filtros y paginación en la URL, `DataTableShell` y `MoneyFormat`. Es el mejor módulo operativo.
- 🟡 `StatusBadge` propio con `Badge default` azul y `destructive` saturado (`materials/status-badge.tsx:13-26`).
- 🟡 El inbox es una cola sin aprobar visible.
- 🟡 El detalle añade `max-w-[1400px] px-6` sobre el padding del layout y usa `MoreVertical`.

### `/dashboard/insurance/*`
`aria-sort`, selects con `aria-label` y `StatusBadge`. Bien.
- 🟡 "Expiring" tiene 4 KPI solapados con ícono y verde para ">30 días".
- 🟡 Dos marcas por fila y sin acción (renovar/avisar).
- 🔵 Encabezado de cobertura a la derecha con la celda a la izquierda.

### `/dashboard/resources`
- 🟡 Dos badges **arcoíris** por fila (`--chart-2..5`) (`resources-crud-page.tsx:183-231`).
- 🟡 Subida nativa sin avance. El alcance pide un "ID de división" numérico crudo.
- 🔵 El archivo tiene 1540 líneas.

### Certificaciones, importaciones masivas y solicitudes institucionales
- 🟡 Varios botones primarios rellenos por fila y "Aprobar evidencia" sin confirmación (`final-review-tray.tsx:199-295`).
- 🟡 `window.open` después de un `await` lo bloquea Safari (`final-review-tray.tsx:119`, `requirement-review-detail.tsx:200`).
- 🟡 Hasta 4 badges por ítem.
- 🔵 Barra de 3 colores `aria-hidden` con solo "x/total".

### Referencias a copiar
- `investiture-requests/[requestId]` (`request-detail-client-page.tsx`): h1 con el nombre, `DataTableShell`, barra pegajosa y `loading.tsx` propio.
- `honor-instructor-proposals-queue.tsx`: skeleton con filas, error con reintento, `aria-pressed` y patrón B.

### Inconsistencias del bloque
- **Dinero con tres formateadores:** `formatMxnAmount` (`$1500.00`), `MoneyFormat`/`formatCentavos` (`$1,500.00`, `es-MX` fijo) y `useFormatCurrency` (por locale). La misma cantidad se ve de tres formas.
- **Cuatro dialectos de KPI**, ninguno como franja dividida.
- **Colas de revisión:** unas tienen acción visible (pagos de camporee, propuestas, certificados) y otras no (payment-orders, pedidos, materials).

---

## 8. Inconsistencias transversales

| Tema | Variantes encontradas |
|---|---|
| Crear / editar | Modal intercept (achievements, roles/new) · página (roles/[id]) · Dialog (23 catálogos, variables, permisos, pagos) · Sheet (notificaciones) |
| Contenedor de tabla | `DataTableShell` (users, reports, roles) · `rounded-xl border bg-card shadow-card` · Card + CardHeader · `overflow-x-auto` desnudo |
| Tabla en móvil | Tarjetas (users, reports, rankings) · scroll horizontal (clubs, evidencias, supervisión, membresía, catálogos) |
| Paginación | `DataTablePagination` · "Anterior/Siguiente" hardcodeado · ninguna |
| Vacío | `EmptyState` · `ui/empty.tsx` (0 usos) · 28 `border-dashed` caseros · fila `colSpan` |
| Error | `EndpointErrorBanner` · `Alert` inline · Card de texto · página entera · `catch {}` silencioso. Casi nunca con Reintentar |
| Carga | `loading.tsx` en 8 rutas · Suspense con skeleton propio · nada |
| Eliminar | `destructive-solid` (roles, user-permissions) · `AlertDialogAction` estándar · `window.confirm` (sucesión) |
| Filtros | `Label` visible · `aria-label` · solo placeholder · con botón "Buscar" · en caja con título |
| Overlays | Dialog `black/40` · AlertDialog `black/80` + blur |
| Detalle | Pestañas en URL (club) · sin URL (usuario). Botón "Volver" + breadcrumb en breakdown e import |
| Estados booleanos | `StatusBadge` · `Badge secondary/default/soft` |

---

## 9. Plan de remediación sugerido

Ordenado por impacto/riesgo. Un PR por fase, en `sacdia-admin`.

**Fase 1: accesibilidad y robustez (bloqueante para QA)**
1. Tokens `--*-text` para success/warning/info y `--destructive` oscuro. Migrar `text-success|warning|info`, `Badge soft-*` y `StatusBadge progress-*`.
2. `(dashboard)/error.tsx` y `global-error` en español. El error del home va dentro del bloque, con Reintentar.
3. Skip link y landmarks. Etiqueta de grupo del sidebar sin opacidad.
4. Labels y `aria-label` en todos los filtros y búsquedas. i18n de los strings fijos (incluye paginación de los 10 catálogos).
5. Bugs funcionales:
   - "Editar" de clubes
   - búsqueda de clubes en servidor
   - estado contradictorio en Actividades
   - doble entrega de insumos
   - `router.push` al montar en Eventos
6. Errores silenciados que se ven como "vacío": detalle de camporee, finanzas, bandejas, plantillas, investiture-settings y jobs.

> **Estado (2026-11-08):** las Fases 1 a 4 están integradas en `development` de `sacdia-admin` ([abn-r/sacdia-admin#292](https://github.com/abn-r/sacdia-admin/pull/292), merge `ed118d3`). Decisión: los catálogos **no** se fusionaron en PhaseE. Comparten primitivos (`CatalogTableView`, `DataTablePagination` controlada, `DataTableShell`, `EmptyState`). La reagrupación del sidebar queda pendiente como decisión de producto.
>
> **Estado Fase 1 (2026-11-08):** implementada en `sacdia-admin`, rama `fix/admin-design-phase-1` (5 commits, sin push). Typecheck limpio y 2385/2385 tests. El lint no tiene errores nuevos: los 36 que hay vienen de `development`.
>
> **Pendientes de la Fase 1:**
> - La búsqueda de clubes en servidor necesita que `GET /clubs` acepte `search` (backend). Mientras tanto, el panel avisa "Filtrando solo esta página".
> - No existe pantalla para editar clubes (`updateClubAction` no tiene uso), así que se quitó la acción rota.
> - `DataTablePagination` solo pagina por URL. Los 10 catálogos con paginación en cliente siguen con botones propios, ya traducidos.
> - Quedan textos sin traducir (toasts y títulos) en `class-honors-dialog`, `class-prerequisites-dialog` y `scoring-category-dialog`.

**Fase 2: un patrón por cosa**
1. Un solo orquestador de catálogo (PhaseE) y migración de los 11 restantes.
2. `DataTableShell` + lista móvil de 2 líneas como patrón único de listado. Aplicarlo a clubs, evidencias, supervisión, membresía, section-rankings y catálogos.
3. `EmptyState` único (borrar `ui/empty.tsx`, migrar los 28 caseros). `loading.tsx` en las rutas pesadas.
4. Crear/editar alineado a §6.1. Documentar la excepción Dialog para catálogos simples.

**Fase 3: gusto y polish**
1. KPIs en un contenedor dividido sin tiles. Barras grises con color solo en riesgo. Cifra-respuesta destacada.
2. Quitar icon tiles, bandas de cabecera, el tinte del top 3 y la caja de filtros.
3. Motion: una sola curva, `PRESS_SCALE` único, overlays iguales, sombras de popover más ligeras.
4. Escala tipográfica: `text-2xs` (11px) y eliminar lo menor a 11px.
5. Sidebar: reagrupar, contadores en colas y alcance bajo la marca.

**Fase 4: documento**
Reescribir `DESIGN-SYSTEM.md` como estado actual (cuerpo = verdad, changelog al final). Tablas de §2 generadas desde `globals.css`. Borrar §7.12 y §16. Añadir reglas nuevas al `audit:design-system`:
- `text-(success|warning|info)` como texto
- `text-[<11px]`
- `window.confirm`
- `border-dashed` fuera de `EmptyState`
- paginación hardcodeada

---

## Anexo — cobertura y límites

- **Verificado en navegador** (coordinator, 1440 y 375):
  - home
  - clubes (escritorio y móvil)
  - actividades
  - el gate de Seguros: el sidebar oculta bien "Por sección", así que no es un bug
  - el contraste real de las etiquetas del sidebar
- **No verificado en navegador:**
  - pantallas que requieren rol `admin` (catálogos, configuración, camporees)
  - modo oscuro visual (el tema va por cookie)
  - flujos `@modal`
  - impresión del reporte mensual
- **No leído a fondo:** `master-honor-rules-editor`, `class-honors-dialog`, `*-columns.tsx`, `delivery-config-form`, `evaluation-client-page`, `templates-client-page`, `monthly-report`, `periodic-reports/*`, `units/*`, `validation/*`.
- Se descartaron dos falsos positivos durante la verificación:
  - "Seguros visible sin acceso": el sidebar filtra bien.
  - "Selects vacíos en escritorio": era el timing de la captura.
