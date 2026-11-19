# Feature: Recursos

**Estado**: IMPLEMENTADO
**Fecha**: 2026-03-26
**Actualizado**: 2026-11-19 (sección «App móvil» y limitaciones conocidas)
**Módulo backend**: `ResourcesModule` (`src/resources/`)

---

## Descripción

El módulo de Recursos permite gestionar y distribuir materiales digitales (documentos, audios, imágenes, enlaces de video y texto) a los usuarios de la plataforma, con control de visibilidad basado en scope organizacional (DIA, unión, campo local).

El módulo incluye:
- CRUD de categorías configurables (`resource_categories`).
- CRUD de recursos con subida de archivos a Cloudflare R2 (`resources`).
- Endpoints orientados a la app móvil con visibilidad filtrada por el scope del usuario.
- Permisos RBAC independientes para recursos y categorías.

---

## Endpoints

### Admin CRUD — Recursos (`resources.controller.ts`)

| Method | Path | Permiso | Descripción |
|--------|------|---------|-------------|
| POST | `/api/v1/resources` | `resources:create` | Crear recurso con archivo adjunto (multipart/form-data, max 50 MB) |
| GET | `/api/v1/resources` | `resources:read` | Listar recursos con paginación y filtros |
| GET | `/api/v1/resources/:id` | `resources:read` | Obtener recurso por UUID con URL firmada |
| GET | `/api/v1/resources/:id/signed-url` | `resources:read` | Generar URL firmada fresca (TTL 1 hora) |
| PATCH | `/api/v1/resources/:id` | `resources:update` | Actualizar metadatos (sin reemplazar archivo) |
| DELETE | `/api/v1/resources/:id` | `resources:delete` | Soft delete (archivo en R2 no se elimina) |

### App — Recursos visibles (`resources-app.controller.ts`)

| Method | Path | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/v1/resources/me` | JWT | Recursos visibles según scope y tipo de club del usuario |
| GET | `/api/v1/resources/me/:id` | JWT | Recurso individual visible con URL firmada |
| GET | `/api/v1/resources/me/:id/signed-url` | JWT | URL firmada fresca para descarga |

> Los endpoints `/me` no requieren permiso RBAC explícito; solo autenticación JWT. La visibilidad se resuelve dinámicamente desde el contexto del usuario (union_id, local_field_id).

### Admin CRUD — Categorías (`resource-categories.controller.ts`)

| Method | Path | Permiso | Descripción |
|--------|------|---------|-------------|
| POST | `/api/v1/resource-categories` | `resource_categories:create` | Crear categoría |
| GET | `/api/v1/resource-categories` | `resource_categories:read` | Listar categorías activas |
| GET | `/api/v1/resource-categories/:id` | `resource_categories:read` | Obtener categoría por ID |
| PATCH | `/api/v1/resource-categories/:id` | `resource_categories:update` | Actualizar categoría |
| DELETE | `/api/v1/resource-categories/:id` | `resource_categories:delete` | Soft delete (falla si la categoría tiene recursos activos) |

**Total: 14 endpoints** (6 admin recursos + 3 app + 5 categorías)

---

## Tipos de Recurso

| Tipo | Descripción | Archivo requerido |
|------|-------------|-------------------|
| `document` | PDF, Word u otro documento | Si |
| `audio` | Archivo de audio (MP3, WAV, etc.) | Si |
| `image` | Imagen (JPG, PNG, etc.) | Si |
| `video_link` | Enlace externo a video (YouTube, Vimeo, etc.) | No (usa `external_url`) |
| `text` | Contenido de texto plano | No (usa `content`) |

---

## Scoping y Visibilidad

El campo `scope_level` controla quién puede ver el recurso:

| scope_level | Visible para | scope_id apunta a |
|-------------|-------------|-------------------|
| `system` | Todos los usuarios autenticados (DIA) | NULL |
| `union` | Usuarios de la unión y campos locales bajo ella | `union_id` |
| `local_field` | Usuarios del campo local específico | `local_field_id` |

La visibilidad es **cascading**: un recurso de scope `union` lo ven todos los campos locales de esa unión.

En el admin, los usuarios globales sin alcance territorial explícito y los usuarios con alcance país pueden crear recursos para `system`, `union` y `local_field`. Los usuarios con alcance unión quedan restringidos a su propia unión; los usuarios con alcance campo local quedan restringidos a su propio campo local.

El campo `club_type_id` restringe el recurso a un tipo de club específico. Cuando es `NULL`, el recurso aplica a todos los tipos de club.
En la app, ese filtro se compara contra el tipo de club de la asignación activa del usuario (`authorization.effective.scope.club.section.club_type_id`); si el usuario no tiene asignación activa, solo ve recursos sin restricción de tipo de club.

---

## Permisos RBAC

8 permisos nuevos registrados en el sistema:

| Permiso | Descripción |
|---------|-------------|
| `resources:create` | Crear recursos |
| `resources:read` | Ver recursos (admin) |
| `resources:update` | Actualizar metadatos de recursos |
| `resources:delete` | Eliminar recursos (soft delete) |
| `resource_categories:create` | Crear categorías |
| `resource_categories:read` | Ver categorías |
| `resource_categories:update` | Actualizar categorías |
| `resource_categories:delete` | Eliminar categorías (soft delete) |

---

## Storage

- **Bucket**: `RESOURCES_FILES` en Cloudflare R2.
- **Subida admin**: el admin envía archivos como `multipart/form-data` a `POST /api/v1/resources`; el backend valida permisos/scope y sube el objeto a R2. El navegador no debe hacer PUT directo a R2 para crear recursos.
- **URLs firmadas**: TTL de 1 hora. Se generan on-demand en `GET /resources/:id` y en el endpoint `/signed-url`.
- **App móvil**: ver «App móvil» más abajo.
- **Soft delete**: el archivo en R2 **no se elimina** al desactivar un recurso. Se mantiene para auditoría y posible reactivación.
- **Limite de archivo**: 50 MB por upload.

---

## Decisiones de Diseño

### 1. Categorías configurables (no enum)
Las categorías se gestionan como tabla (`resource_categories`) en lugar de un enum fijo. Esto permite que administradores del sistema agreguen categorías nuevas sin deployar código.

### 2. Visibilidad en cascada con scope_level
En lugar de una tabla de permisos por recurso, se usa un campo `scope_level` + `scope_id`. El servicio resuelve la visibilidad consultando el contexto del usuario (su `union_id`, `local_field_id`) y filtrando recursivamente. Esto simplifica las consultas y es suficiente para la jerarquía actual (DIA > Unión > Campo Local).

### 3. URLs firmadas con TTL corto
Los archivos en R2 no son públicos. Se generan URLs pre-firmadas con 1 hora de vigencia para cada acceso. Esto evita distribución no autorizada de materiales.

La creación de recursos con archivo es API-first: el cliente admin no solicita URLs prefirmadas de subida ni hace PUT directo a R2. Esto centraliza autorización, validación de alcance, límites de archivo y persistencia en el backend.

### 4. video_link como tipo nativo
En lugar de obligar a subir un archivo, el tipo `video_link` acepta una URL externa (`external_url`). Esto permite referenciar contenido en YouTube, Vimeo u otras plataformas sin duplicar el archivo.

### 5. Controladores separados admin vs app
`ResourcesController` (admin) requiere permisos RBAC explícitos. `ResourcesAppController` (app) solo requiere JWT y resuelve visibilidad por contexto. Se registra primero el controlador app para que `/resources/me` no sea capturado por el param `:id` del controlador admin.

---

## Tablas de Base de Datos

- `resource_categories` — Catálogo de categorías
- `resources` — Recursos con metadatos y referencia al archivo en R2

Ver definición completa en `docs/database/SCHEMA-REFERENCE.md` — Módulo: Resources.

---

## App móvil

**Verificado contra código**: 2026-11-19 (`development`; rediseño en sacdia-app #264, ajustes en #267 y #269). Código en `lib/features/resources/`. Ruta `/home/resources` (`RouteNames.homeResources`); no hay pantalla de detalle propia: el detalle es una hoja.

**Biblioteca (`ResourcesView`)**
- Consume `GET /resources/me` con páginas de 20 (carga la siguiente al acercarse al final) y los filtros `resource_type`, `resource_category_id` y `search`. La búsqueda se envía con 350 ms de espera.
- Cuadrícula de 2 columnas. Cada tarjeta muestra el título (nunca el nombre del archivo) y una etiqueta de tipo con icono y texto sobre una píldora translúcida con desenfoque. Las imágenes y los videos de YouTube muestran su vista previa; el resto, un icono del tipo; el texto muestra su inicio.
- Fila de tipos (`ResourceFilterBar`) y, debajo, una fila de categorías (`ResourceCategoryBar`, `resource_category_bar.dart`) con chips discretos que se combinan con el tipo y la búsqueda; tocar la categoría activa la desmarca.
- **Las categorías se derivan de los recursos cargados** (`resourceCategoryOptionsProvider`, #267): `resourceFacetProvider` pide una sola página de hasta 100 recursos (el tope del backend) y toma de ahí el `resource_category_id` y el nombre de categoría de cada uno. `GET /resource-categories` solo se usa como enriquecimiento opcional: si responde, sus categorías van primero y en el orden del servidor; si falla, se ignora. Motivo: esa ruta pide `resource_categories:read` y un director recibía 403, con lo que la barra desaparecía.
- Los conteos por categoría solo se muestran cuando todos los resultados cupieron en esa página de 100 (`ResourceFacet.isComplete`); si hay más, los chips salen sin número. Las categorías se descubren únicamente entre los primeros 100 recursos de la biblioteca sin filtros.
- Estados: esqueleto con forma de cuadrícula; sin resultados, con el texto de la búsqueda o filtro y la opción «Ver en todos los tipos» cuando hay coincidencias en otros tipos; club sin recursos, con acción de actualizar; error con reintento; *pull-to-refresh*.

**Hoja de detalle (`ResourceDetailSheet`)**: portada y título; una línea «TIPO · tamaño · fecha»; grupo etiqueta-valor con categoría, para qué club (con logo) y quién lo publicó (las filas sin dato se omiten); y un pie fijo con una acción principal y, al lado, «Descargar» y «Compartir».

| Tipo | Acción principal | Secundarias |
|---|---|---|
| `audio` | reproductor embebido (el botón grande de reproducir es la acción) | Descargar, Compartir |
| `image` | «Ver imagen» (visor a pantalla completa con zoom) | Descargar, Compartir |
| `document` PDF | «Abrir PDF» (visor interno) | Descargar, Compartir |
| `document` no PDF | «Descargar» | Compartir |
| `video_link` | «Abrir en YouTube» (o «Abrir enlace» si no es YouTube), con aviso de que sale de la app | ninguna |
| `text` | muestra el contenido en la hoja | ninguna |

**Reproductor de audio (`ResourceAudioPlayer`)**: control deslizante que se puede arrastrar (con semántica de *slider*), tiempo transcurrido y restante, botones de retroceder y adelantar 15 s (`skip = 15 s`) y reproducir/pausar grande. Buscar posición solo se habilita después de que el audio empezó y se conoce su duración. Al llegar al final, reproducir de nuevo vuelve al inicio. La búsqueda usa `seekTo` del puente nativo (`MethodChannel('sacdia/audio_player')`, `lib/core/media/sac_audio_player_controller.dart`), implementado en `ios/Runner/AppDelegate.swift` y `android/app/src/main/kotlin/com/sacdia/app/MainActivity.kt`. Verificado el 2026-11-19 en el simulador de iOS y en un emulador de Android 16: ±15 s y arrastre.

**Textos**: las cadenas `resources.*` están traducidas en es, en, fr y pt-BR (#269).

## Limitaciones conocidas

- **Imágenes sin miniatura**: las tarjetas de imagen cargan el archivo original completo mediante una URL firmada de R2 (`GET /resources/me/:id/signed-url`); el backend no genera miniaturas y `thumbnail_url` llega `null`. Una imagen de 2.5 MB tarda unos segundos en aparecer la primera vez. Es una limitación, no un fallo.
- **Imagen que no cargó en Android**: en el emulador de Android la miniatura de una imagen no cargó mientras en iOS sí, con una URL firmada HTTPS válida. No se reprodujo ni se encontró la causa; sin cambio de código.
- **Nombre de archivo con codificación rota**: se observó el 2026-11-19 un recurso cuyo `file_name` quedó guardado como `niÃ±a-levantate.png` en lugar de `niña-levantate.png`. El backend ya recupera el UTF-8 que multer decodifica como latin1 (`decodeMultipartFileName`, `src/common/utils/multipart-file-name.ts`, aplicado en `resources.service.ts`; commit `78656b95`, 2026-10-15), y ese commit no incluye migración de datos. No se confirmó si el registro observado se subió antes de esa corrección o si algún camino de subida no la aplica. La app muestra el título, no `file_name`, así que el síntoma se ve en el nombre del archivo descargado o compartido y en datos de admin.
- **Categorías de la biblioteca**: ver arriba; solo salen de los primeros 100 recursos cuando `/resource-categories` no está disponible para el rol.
- Sin portadas por clase (la entidad `Resource` no trae datos de clase) ni «Avisarme cuando haya» (no hay backend).

## Implementación por Capa

| Capa | Estado | Detalle |
|------|--------|---------|
| Backend (NestJS) | IMPLEMENTADO | `ResourcesModule`, `ResourceCategoriesController`, `ResourcesController`, `ResourcesAppController` |
| Admin (Next.js) | IMPLEMENTADO | Página CRUD categorías + página gestión de recursos |
| App (Flutter) | IMPLEMENTADO | `lib/features/resources/` (datos, dominio y presentación con Riverpod); rediseño de 2026-11 descrito en «App móvil» |
