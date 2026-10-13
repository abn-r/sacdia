# Carga por certificado: rediseño de la experiencia (app)

> **Estado de implementación (2026-10-13).** Los ocho slices de la app están mergeados en `development` de `sacdia-app`. El texto de abajo es el diseño original; donde el código difiere, manda el código.
>
> | Slice | PR (sacdia-app) | Qué entró |
> |---|---|---|
> | base | #161 | Galería y loader de tres puntos en la subida |
> | S1. Errores y copy | #162 | Mapa de errores compartido y copy |
> | S2. Subida reintentable y espera | #163 | Subida con progreso y espera de lectura con sondeo de `ocr_state` |
> | S3. Visor de comprobante | #164 | Visor que abre el archivo y la página de la fila |
> | S4. Revisión | #165 | Revisión con grupos, dock y estados de lectura; parseo de nombres de catálogo, instructor y `ocr_error_code` |
> | S5. Editor y selectores | #166 | Selectores de especialidad y de clase desde el catálogo, con rango de fechas |
> | cancelar | #167 | Cancelar o abandonar durante la subida borra el borrador (`DELETE /certificate-bulk-imports/:batchId`) |
> | S6. Instructor en la carga | #168 | Selector de instructor y campo opcional en la fila de especialidad |
> | S7. Instructor y fecha en «Mis especialidades» | #169 | `completed_at` e instructor antes de enviar a revisión |
> | S8. Proponer instructor | #170 | Propuesta de instructor sobre una especialidad aprobada |
>
> Dependencias de backend y admin (todas mergeadas): B1 #473, B2 #474, B3 #476, B4 #475, B5 #479, B9 #480, B11 #478; admin B6 #228, B7 #227, B10 #229. Resumen completo y correcciones al diseño en `2026-10-09-certificate-import-instructor-data-model.md`.
>
> Diferencias conocidas con este documento:
>
> - La sección 6.4 decía que «Mis especialidades» no tendría selector de fecha. S7 sí pide la fecha de finalización (`completed_at`, migración M5 del backend), porque el diseño de datos la incorporó el 2026-10-12.
> - El backend no exige `completed_at` al enviar a revisión mientras `REQUIRE_HONOR_COMPLETED_AT_ON_SUBMIT` sea `false`. La app lo pide siempre; el backend lo exigirá cuando S7 sea la versión mínima.
> - Las propuestas de instructor se **retiran** (`WITHDRAWN`); el texto «Cancelar propuesta» de 6.5 es solo copy de la app y llama a `DELETE .../instructor-proposal`.
> - Migraciones por rama de Neon: `development` tiene M1, M2, M5 y M4; `staging` y `production`, ninguna (dato del responsable, no verificado desde el repositorio). Ver `docs/deployment/DEPLOYMENT-GUIDE.md` §0.5.

**Fecha:** 2026-10-09 (actualizado el 2026-10-10 y el 2026-10-12 con las decisiones del usuario)
**Estado:** Diseño con las decisiones del usuario incorporadas (D1 a D13). Sin código. No quedan preguntas abiertas (ver "Decisiones tomadas" y la sección 10).
**Alcance:** `sacdia-app`, flujo del miembro en `lib/features/certificate_import/` (carga, subida, lectura OCR, revisión, edición de filas, visor de comprobante, envío, confirmación y correcciones) y el detalle de una especialidad en `lib/features/honors/` (solo el instructor: captura antes de enviar a revisión, sección 6.4, y propuesta de instructor sobre una especialidad ya aprobada, sección 6.5).
**Base leída:** `origin/development` en `07a7088b`, que ya incluye el PR #161 (galería y loader de tres puntos, commit `4590a693`). El worktree `/tmp/sacdia-app-upload-ux` apunta al mismo commit del PR.
**Documento hermano:** `2026-10-09-certificate-import-instructor-data-model.md` (modelo de datos y API, "B"). Define los endpoints, los campos y las migraciones que este documento consume. Aquí se citan sus slices como **B1 a B10** y sus dos PRs de seguridad previos como **SEC-1** y **SEC-2** (D13); los slices de la app son **S1 a S8** (sección 11).
**Fuera de alcance:** el diseño del backend y del admin (documento hermano) y la corrección de otros hallazgos del flujo normal de especialidades que no sean el instructor.

## Decisiones tomadas

Todas son decisiones del usuario. Reemplazan las propuestas y las preguntas abiertas P1 a P5 de la versión anterior.

| # | Fecha | Decisión | Efecto en este documento |
|---|---|---|---|
| D1 | 2026-10-09 | El instructor es **opcional** para marcar una especialidad como lista. | 6.1, 4.5 (el dock no cuenta el instructor) |
| D2 | 2026-10-09 | El buscador de instructores solo devuelve usuarios activos, aprobados y mayores de edad **del mismo Campo Local** que el miembro (no la unión, "de momento"). No exige Guía Mayor. Solo muestra **nombre y foto**. Los instructores de otros campos se cargan como **nombre libre**. | 4.7c, 6.1, 6.4 (sin club ni tipo de club en los resultados) |
| D3 | 2026-10-09 | El backend expone `ocr_state` (`pending`, `running`, `done`, `empty`, `failed`) en las respuestas del lote, derivado del job de OCR. | 3, 4.3, 4.5 (estados F y G), 8 |
| D4 | 2026-10-09 | La API expone `page_count` del archivo y `source_page` por fila (la página donde el OCR leyó la fila). El visor abre directo en esa página, en la app y en el admin. | 4.5, 4.8, 6 |
| D5 | 2026-10-09 | Umbral de confianza de fecha: **0.8**. Por debajo, la fila muestra "Revisa la fecha". | 4.5, 6 |
| D6 | 2026-10-09 | Fecha mínima válida **1960-01-01** y ninguna fecha futura, para la fecha completada de la especialidad y la de investidura de la clase. Se valida en el formulario y en el backend. | 6.1, 6.2, 6.3, 8 |
| D7 | 2026-10-09 | Si la especialidad ya estaba aprobada con otro instructor, se conserva el existente y se marca `instructor_conflict` en el backend. El revisor del Campo Local lo ve. | Sin pantalla del miembro (solo backend y admin) |
| D8 | 2026-10-10 | v1 sin notificación ni confirmación del instructor. | 6.1 y 6.4 (texto de ayuda del campo: el instructor no recibe aviso), 8 |
| D9 | 2026-10-10 | El conteo de especialidades enseñadas incluye **ambos flujos**. El formulario de "Mis especialidades" también pide el instructor opcional, con el **mismo componente selector**. El selector no depende de un `batchId`. | 4.7c, 6.4, 7, 11 (S7) |
| D10 | 2026-10-12 | En el flujo normal de "Mis especialidades", el instructor (opcional) se captura en `HonorEvidenceView`, antes de "Enviar a revisión". Se guarda con `PATCH /users/:userId/honors/:honorId` y solo se puede editar en `IN_PROGRESS` o `REJECTED`. | 6.4, 10, 11 (S7) |
| D11 | 2026-10-12 | En una especialidad **ya aprobada**, el miembro puede proponer **solo el instructor** y el Campo Local lo aprueba o rechaza. El resto de los datos queda congelado. | 6.5, 5 (M26), 7.2, 8, 10 (R12), 11 (S8) |
| D12 | 2026-10-12 | `certificate_bulk_import_items` guarda `source_file_id` junto con `source_page` (misma migración M2). El lote acepta hasta 10 archivos. El visor abre el archivo y la página correctos; si falta el dato, abre el primer archivo en la página 1. | 4.5, 4.8, 10 (R9), 11 (S3) |
| D13 | 2026-10-12 | Dos PRs de seguridad aparte, previos al rediseño: **SEC-1** (`fix/honors-create-mutability-guard`) y **SEC-2** (`fix/honors-abandon-restart-guard`, apilado sobre SEC-1). Son prerrequisito de B5 y de B9, y por tanto de S7 y S8. | 10, 11 |

Consecuencias derivadas:

- El selector de instructor llama a `GET /instructor-candidates?q=` (alcance: Campo Local del usuario autenticado), no a una ruta del lote. Por eso el componente puede vivir en `core/widgets` y usarse desde los dos features.
- La Revisión y el visor ya no necesitan heurísticas de tiempo ni de ancho de archivo: leen `ocr_state`, `page_count` y `source_page`.
- Quedan **6 slices de app, más S7 (D9) y S8 (D11)**, con dependencias explícitas de los slices B del documento hermano (sección 11). Ningún slice de la app requiere migración; las migraciones son de backend (B2 con M1, B4 con M2 y B9 con M4).
- La propuesta de instructor sobre una especialidad aprobada (D11) **no reutiliza** el `PATCH` ni el alta: la app llama a un endpoint propio (`POST /users/:userId/honors/:honorId/instructor-proposal`) y lee el estado de la propuesta en el bloque `instructor_proposal` de la lista de especialidades (6.5).
- Con D12 el visor recibe el **archivo** y la página de la fila (`source_file_id` y `source_page`), no solo la página. La Carga de la app sigue subiendo un archivo por lote; el lote acepta hasta 10 por la API (`CERTIFICATE_IMPORT_MAX_FILES`), y el visor ya resuelve el archivo correcto (4.8).
- D13 no cambia ninguna pantalla: protege que una especialidad aprobada o en revisión no se pueda reescribir, reiniciar ni abandonar por las vías de alta y abandono, y por eso se despliega antes de S7 y S8.

---

## 0. Resumen

1. Todo el flujo vive en **tres pantallas y dos hojas**: Carga (con la espera integrada), Revisión y Estado. Las hojas son el Editor de fila y los Selectores. Además hay un **visor de comprobante** a pantalla completa. Se retira la vista `processing`, que está obsoleta.
2. La espera, que hoy es el loader de tres puntos del PR #161, se queda en el dock inferior. Se le agregan un indicador de tres pasos (Subir, Leer y Revisar), una barra con el avance real de la subida, el botón "Cancelar" mientras se sube y la salida "Seguir sin esperar" si la lectura tarda.
3. Cada error tiene **un mensaje y una salida**: PDF con más de 5 páginas, protegido o dañado, cola llena (`PDF_BUSY`, que reintenta el mismo `confirm` sin crear otro lote), sin conexión, lectura no disponible o sin resultados. La lectura se sigue con `ocr_state` (`pending`, `running`, `done`, `empty`, `failed`), no con heurísticas de tiempo (D3).
4. La Revisión se ordena alrededor del **comprobante**: una tarjeta con miniatura y número de páginas (`page_count`) que abre el visor, el resumen en una frase, avisos que solo aparecen cuando aplican y filas agrupadas en Especialidades y Clases. "Ver en tu comprobante" abre el visor en la página donde se leyó la fila (`source_page`, D4).
5. La fila muestra lo que **falta** ("Falta la fecha") en lugar de "FALTA DATO". Nunca muestra un ID de catálogo ni "% OCR". Si la confianza de la fecha es menor que 0.8, muestra "Revisa la fecha" (D5).
6. El editor separa **lo que leyó el sistema** (cita de solo lectura con la etiqueta "Leído en tu comprobante") de **lo que eligió el miembro** (selectores del catálogo).
7. Para una especialidad se piden categoría (filtro opcional), especialidad (selector buscable), fecha (selector de fecha, entre 1960-01-01 y hoy) e instructor **opcional**, que puede ser un usuario de su Campo Local o un nombre escrito en el mismo buscador. Para una clase se piden tipo de club (chips con logo), clase (lista corta) y fecha de investidura (mismo rango).
8. El aviso "Amigo y Explorador…" deja la cabecera. Pasa a ser una ayuda **dentro del formulario de clase** y solo aparece si la clase elegida tiene clases anteriores en su tipo de club.
9. El motion usa **solo los tokens de `SacMotion`**, que ya coinciden con las curvas de Emil, y no hace falta crear tokens. Cada animación tiene un propósito, dura 300 ms o menos y tiene variante para Reduced Motion.
10. El formulario de **"Mis especialidades"** (flujo normal) pide el mismo instructor opcional con el mismo componente, en `HonorEvidenceView` y antes de "Enviar a revisión". Se guarda con `PATCH` y solo se edita en curso o rechazada (sección 6.4, D9 y D10).
11. En una especialidad **ya aprobada** el miembro puede **proponer solo el instructor**. La tarjeta pasa a "Instructor en revisión" hasta que el Campo Local apruebe o rechace; nada más de la especialidad se puede tocar (sección 6.5, D11).
12. El visor abre cada fila en **su archivo y su página** (`source_file_id` y `source_page`); si falta el dato, abre el primer archivo en la página 1 (sección 4.8, D12).
13. Se proponen 8 slices (S1 a S8), empezando por los errores, el visor y el copy. Esos tres no dependen de la API nueva. La sección 11 fija el orden y las dependencias con los slices de backend y admin del documento hermano, y con los dos PRs de seguridad previos (D13).

---

## 1. Principios aplicados

| Principio | Fuente | Traducción a Flutter en este flujo |
| --- | --- | --- |
| ¿Debe animarse? La decisión depende de la frecuencia | emil-design-eng y animate, paso 1 | El flujo es **raro** para el miembro (pocas cargas al año), pero **dentro** de una sesión de revisión editar filas es frecuente. La entrada de resultados admite un stagger porque ocurre una vez. Cambiar de filtro, abrir una fila o escribir en el buscador **no** se anima, o se anima de forma casi imperceptible. |
| Nombrar el propósito antes de animar | animate, paso 2 | Cada fila de la tabla de motion (sección 5) declara su propósito: retroalimentación, coherencia espacial, indicación de estado o evitar un cambio brusco. Lo que no tiene propósito no se anima. |
| La herramienta más barata que sirva | animate, paso 3 | Primero animaciones implícitas (`AnimatedOpacity`, `AnimatedSize`, `AnimatedSwitcher` mediante `SacStateSwap`, `TweenAnimationBuilder` mediante `SacTweenedBar`). Después rutas existentes (`SacFadeThroughRoute`, `_sharedAxisBuild`) y `showSacSheet`. `AnimationController` solo en `StaggeredListItem`, que ya existe. Ningún paquete nuevo. |
| Animar solo transform y opacity | emil, rendimiento | Equivalentes en Flutter: `FadeTransition`, `ScaleTransition` y `SlideTransition`, que no relayoutean. `AnimatedSize` (que sí relayoutea) se tolera solo para expandir o contraer, con la misma excepción que el skill concede al acordeón. |
| No partir de `scale(0)` | emil y animate | Las entradas parten de `SacMotion.enterScale` (0.96) junto con opacidad 0. |
| ease-out al entrar o salir, ease-in-out al moverse en pantalla, nunca ease-in | emil y animate, paso 5 | `SacMotion.easeOut = Cubic(0.23, 1, 0.32, 1)`, `SacMotion.easeInOut = Cubic(0.77, 0, 0.175, 1)` y `SacMotion.drawer = Cubic(0.32, 0.72, 0, 1)` ya son **exactamente** las curvas del skill. Se usan tal cual. Prohibido `Curves.easeIn`. |
| UI por debajo de 300 ms | emil, duración | Tokens `press` 140, `reducedFade` 160, `switcher` 180, `standard` 200, `modal`/`routeEnter` 240, `routeExit` 200. Ninguna animación de este diseño pasa de 240 ms. |
| Salida más rápida que la entrada | emil, timing asimétrico | Hojas: entran en `modal` (240) y salen en `routeExit` (200), como ya hace `showSacSheet`. Avisos: entran en `standard` y salen en `reducedFade`. |
| Interrumpible: transiciones, no keyframes | emil, Sonner | `AnimatedSwitcher` y las animaciones implícitas retoman desde el valor actual. Ningún `AnimationController.repeat()` salvo el loader de puntos. |
| Retroalimentación al presionar | emil, botones | Todo lo que se puede tocar pasa por `SacPressable`, `SacButton` o `SacCard(onTap)`, que ya escalan a 0.97 en 140 ms con ease-out. Las filas, los chips y la miniatura del comprobante también. |
| Coherencia espacial y origen | emil, origen | La miniatura del comprobante usa `Hero` hacia el visor: la imagen sale de donde se tocó. Los selectores son hojas que suben desde abajo, igual que el resto de la app. |
| Stagger corto y decorativo | emil, stagger | `StaggeredListItem(animate: true)` con 40 ms por ítem y tope en el índice 5, **solo** en la primera aparición de resultados. Nunca bloquea los toques. |
| Reduced Motion es "menos", no "nada" | emil y animate, paso 7 | `SacMotion.reduceMotionOf(context)` se conserva: los fundidos (160 ms) se mantienen y se eliminan los desplazamientos, las escalas, el `Hero` y el stagger. `SacLoading` ya muestra tres puntos estáticos. |
| Rendimiento percibido | emil | La subida muestra el avance real (`onProgress` ya existe en el data source y no está conectado). Si la lectura se alarga, el texto cambia en vez de quedarse congelado. |
| Los detalles invisibles se acumulan | emil, filosofía | Precarga de la búsqueda con el nombre leído, foco automático, teclado que no tapa el botón, los últimos instructores elegidos en la sesión aparecen primero y errores que no cierran la hoja. |

---

## 2. Hallazgos del código que contradicen el feedback o el contrato

Todas las referencias son a `origin/development`.

| # | Hallazgo | Evidencia | Consecuencia en el diseño |
| --- | --- | --- | --- |
| H1 | "Ver comprobante" no muestra el archivo. Abre `certificateImportProof` con `item: _items.first`. Esa ruta pinta `CertificateImportProofCard` (insignia "Registro importado"). Si no hay filas, muestra `proof.missing` ("Detalle no disponible…"). Si hay filas, la única salida es "Abrir comprobante sellado", que llama a `launchUrl` y abre una app externa. | `certificate_import_review_view.dart` (botón `view_proof`) y `router.dart` (ruta `certificateImportProof`) | Visor propio (sección 4.8). La tarjeta "Registro importado" queda solo para el historial de registros aplicados. |
| H2 | `independent_hint` se muestra siempre en la cabecera de la revisión. | `review_view`, texto fijo | Se mueve al formulario de clase y se muestra condicionado (sección 6.2). |
| H3 | El español usa "Honor": `item.honor = "HONOR"`, `editor.honor = "Honor"` y `processing.running_body = "Extraemos honores…"`. | `es.json` | Copy nuevo (sección 8). |
| H4 | El editor pide "ID catálogo" numérico y la fila muestra "Catálogo: {id}". | `item_editor_sheet.dart` y `item_card.dart` (`catalog_meta`) | Selectores de catálogo. El ID nunca se muestra. |
| H5 | `CERTIFICATE_IMPORT_PDF_BUSY` no está en el set `pdfCodes` del repositorio. El `message` se pasa tal cual y `_uploadErrorMessage` cae en `default`, así que **el usuario ve el código crudo**. Además, reintentar ejecuta de nuevo `uploadLocalProof`, que **crea otro lote**. El contrato dice que se reintente el mismo `confirm`. | `certificate_import_repository_impl.dart` (`_batch`) y `remote_data_source.uploadLocalProof` | Estado "Hay mucha demanda" con un reintento que conserva `batchId` y `fileId` (sección 4.4). Requiere separar las etapas en la capa de datos. |
| H6 | El fallo de OCR se descarta (`ocr.fold((_) async {}, …)`). Los fallos del worker (`OCR_UNAVAILABLE`, `OCR_QUOTA` y `OCR_FAILED`) no llegan al lote: `OCR_PROCESSED` es un evento y no un estado público. Tras 6 consultas de 2 s, la app **no puede distinguir** entre "sin resultados", "falló" y "sigue leyendo", y la revisión dice "Encontramos 0 especialidades y 0 clases". | `upload_view` (`onSubmitProofs`) y `ENDPOINTS-LIVE-REFERENCE.md` §process-ocr | Resuelto con `ocr_state` en la respuesta del lote (D3, B3): la app distingue `pending`, `running`, `done`, `empty` y `failed` y deja de adivinar con un tiempo fijo (secciones 4.3 y 4.5). |
| H7 | Sin conexión: `networkInfo` se inyecta en el repositorio y no se usa en este flujo. El texto de `DioException.message`, que está en inglés y es técnico, puede llegar a la UI. `load_error` interpola `'$error'` crudo. | `repository_impl` y las rutas de revisión y estado | Mapeo de errores a mensajes propios. Nunca se pinta `$error`. |
| H8 | El editor guarda sin `try/catch`: si falla, el botón queda girando. La fecha se escribe como `AAAA-MM-DD` y se lee con `DateTime.tryParse`, sin selector ni mensajes de validación. | `item_editor_sheet.dart` (`_save`) | Errores dentro de la hoja, selector de fecha y validación por campo. |
| H9 | "Quitar" borra sin confirmar y sin manejar errores. "Enviar a revisión" deja escapar la excepción sin mostrar mensaje. | `review_view` (`_removeItem` y `_submit`) | Confirmación con `SacDialog` y errores visibles. |
| H10 | En Estado, "Corregir y reenviar" reenvía **los mismos datos** sin abrir el editor. | `status_view` (`onResubmitItem`) | Abre el editor con el motivo del rechazo y reenvía al guardar. |
| H11 | La vista `processing` está obsoleta: dice que el OCR "no está autorizado en este cliente". `upload.hint` y `hero_body` dicen "completa a mano", aunque el OCR ya funciona. | `processing_view.dart` y `es.json` | Se retira la ruta. Copy nuevo. |
| H12 | Las cargas de las rutas de revisión y estado y el paso activo usan `CircularProgressIndicator`, no `SacLoading`. | `review_view`, `status_view` y `processing_view` | Se usa `SacLoading`. |
| H13 | La frase de resumen siempre nombra los dos tipos ("3 especialidades y 0 clases"). La insignia de confianza muestra "87% OCR". | `review_view` e `item_card` | Frase solo con los tipos que tienen filas. La confianza se traduce en avisos por campo. |
| H14 | Las especialidades de Aventureros **no** tienen categorías (`isAdventurerHonorClubType` oculta los chips en el catálogo). | `honors_catalog_view.dart` | La categoría es opcional y se oculta cuando no aplica (sección 6.1). |
| H15 | "Instructor" es también el nombre de una clase (Guía Mayor Instructor, GM-03), así que hay riesgo de ambigüedad en el copy. | `domain.classes` y `review.institutional` | Etiqueta: "Instructor o instructora". |
| H16 (menor) | `StaggeredListItem.slideOffset` dice "pixels", pero se aplica como fracción (`8/100` del alto del hijo). `HonorCategoryChip` usa `Curves.easeInOut` durante 200 ms fuera de los tokens. | `staggered_list_animation.dart` y `honor_category_chip.dart` | Al reutilizarlos, revisar a mano el desplazamiento real. No bloquea este diseño. |

---

## 3. Mapa del flujo

```
[Perfil / Evidencias]
        │  (entrada; el router tiene TODO(certificate-import-entrypoint))
        ▼
┌──────────────────── CARGA ─────────────────────┐
│ A. Vacío ──"Agregar comprobante"──► Hoja origen │
│      ▲            (Tomar foto / Galería / Archivo)
│      │ validación local falla (formato, >10 MB) │
│      └─────────── error inline ◄────────────────┤
│ B. Seleccionado (miniatura + nombre + tamaño)   │
│      │ "Leer comprobante"                        │
│ C. Subiendo (dock: puntos + barra % + Cancelar) │
│      ├─ sin conexión ─────────► C1 Sin conexión  │──"Reintentar" (mismo archivo)
│      ├─ PDF >5 / protegido / dañado ► C2 Error PDF ─"Elegir otro archivo"
│      ├─ 429 PDF_BUSY ─────────► C3 Mucha demanda │──"Reintentar" (mismo confirm, mismo lote)
│      ▼ confirm OK                                │
│ D. Leyendo (dock: puntos + "Leyendo…")           │
│      ├─ process-ocr 400 OCR_UNAVAILABLE ──┐      │  (al encolar)
│      ├─ ocr_state pending|running >8 s: "Sigue leyendo…" + "Seguir sin esperar"
│      ▼ ocr_state done|empty|failed         │      │
└──────┼─────────────────────────────────────┼─────┘
       ▼                                     ▼
┌──────────────────── REVISIÓN ─────────────────────┐
│ E. Con resultados · ocr_state=done (stagger la 1.ª vez)
│ F. Vacío útil, según ocr_state:                    │
│      empty → "No encontramos…" · failed → "No pudimos leer…"
│      pending|running → "Seguimos leyendo…" (se actualiza solo)
│      400 OCR_UNAVAILABLE al encolar → "Lectura no disponible ahora" 
│ G. Error de carga del lote (reintentar)           │
│   ├─ toca fila / "Agregar" ─► Hoja EDITOR ─► Hoja SELECTOR (especialidad · categoría · instructor)
│   ├─ toca comprobante ─────► VISOR (imagen con zoom · PDF paginado ≤5; desde la fila, abre en su source_file_id y source_page)
│   ├─ "Completar N filas" ──► abre el editor de la primera incompleta
│   └─ "Enviar a revisión" ──► Diálogo de confirmación ─► H. Enviando (botón en carga)
└───────────────────────────┬───────────────────────┘
                            ▼ submit OK  (submit error → banner en dock, se queda)
┌──────────────────── ESTADO ───────────────────────┐
│ I. Confirmación (recién enviado): "Lo enviamos a tu Campo Local"
│ J. En revisión (visitas posteriores)               │
│ K. Correcciones pendientes ─ "Corregir y reenviar" ─► Hoja EDITOR (con motivo) ─► reenvío
└───────────────────────────────────────────────────┘
```

**Flujo normal (fuera del mapa anterior).** "Mis especialidades" → `HonorEvidenceView` → tarjeta "Instructor o instructora" (opcional, 6.4, D10) → "Enviar a revisión". No pasa por Carga, Revisión ni Estado.

**Especialidad ya aprobada (D11, 6.5).** "Mis especialidades" → `HonorEvidenceView` en modo de solo lectura → tarjeta "Instructor o instructora" con la acción "Proponer instructor" → selector (4.7c) → confirmación → "Instructor en revisión" → el Campo Local aprueba (el instructor propuesto pasa a ser el vigente) o rechaza (la tarjeta muestra el motivo y se puede proponer a otra persona). No pasa por Carga, Revisión ni Estado.

### Estados reales que existen hoy y su destino

| Fuente actual | Hoy | Rediseño |
| --- | --- | --- |
| `upload.unsupported_type` | Texto rojo bajo las tarjetas | C0: aviso inline en la tarjeta de selección (sección 4.1) |
| `upload.too_large` | Texto rojo | C0 con el copy corregido ("10 MB") |
| `PDF_TOO_MANY_PAGES` / `PDF_ENCRYPTED` / `PDF_INVALID` | Texto rojo; el archivo sigue seleccionado | C2: tarjeta de error con la acción "Elegir otro archivo" |
| `PDF_BUSY` (429) | **Código crudo** | C3 (nuevo) |
| `DioException` de red | `error.message` en inglés o "Error de red" | C1 (nuevo) |
| `OCR_UNAVAILABLE` al encolar (400 de `process-ocr`) | Descartado | F, variante "La lectura automática no está disponible ahora" |
| `ocr_state = failed` (fallo del worker tras los reintentos) | Revisión con "0 y 0" | F, variante "No pudimos leer tu comprobante", con "Reintentar lectura" |
| `ocr_state = empty` (el OCR terminó sin filas) | Revisión con "0 y 0" | F, variante "No encontramos especialidades ni clases" |
| `ocr_state = pending` o `running` al entrar a la Revisión | Revisión con "0 y 0" | F, variante "Seguimos leyendo tu comprobante" (se actualiza sola) |
| `review.load_error` / `status.load_error` | `$error` crudo | G: `SacEmptyState` con "Reintentar" |
| `review.empty_filter` | Tarjeta con texto | Se mantiene, con un enlace "Ver todas" |
| Rechazo con `period_pending` | Texto rojo en la fila | K: motivo en la fila y en el editor |

---

## 4. Diseño pantalla por pantalla

Estilo base que **no se toca**: `SacTopBar(frosted: true)` con `SacFrostedVeil`, `context.sac` para los colores, `SacCard` con radio de 16, dock inferior con `c.background` y borde superior `c.border`, `SacButton.primary` en el dock, iconos HugeIcons, márgenes horizontales de 16 a 18 y cabecera de hoja `SacSheetHeader`.

### 4.1 Carga (estados A y B)

```
┌ SacTopBar (frosted) ─ ← Carga por certificado ───────┐
│                                                       │
│ ┌ SacCard surfaceVariant (hero actual, sin cambios) ┐ │
│ │      [CMP-01] [CMP-02]  ✦                          │ │
│ │  Carga tu comprobante                               │ │  displaySmall w700
│ │  Leemos tu certificado y te proponemos las          │ │  bodyMedium secondary
│ │  especialidades y clases. Tú las revisas antes de   │ │
│ │  enviarlas a tu Campo Local.                        │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌ SacCard ───────────────────────────────────────────┐ │
│ │ ✓ PDF de hasta 5 páginas o foto JPEG, PNG o WebP.  │ │  (hint corto)
│ │   Máximo 10 MB. Un comprobante por carga.          │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌ SacCard (B: seleccionado) ─────────────────────────┐ │
│ │ ┌────┐ Comprobante listo                    Cambiar│ │
│ │ │mini│ certificado-2024.pdf                         │ │
│ │ └────┘ PDF · 2,4 MB                                 │ │
│ └─────────────────────────────────────────────────────┘ │
├─ dock ─────────────────────────────────────────────────┤
│ [■ Leer comprobante                                  ] │  primary (A: deshabilitado)
│ [  Agregar comprobante                               ] │  outline (B: se oculta; "Cambiar" vive en la tarjeta)
└────────────────────────────────────────────────────────┘
```

- **Jerarquía.** Cuando hay un archivo, el foco pasa a la tarjeta B. En A el botón principal es "Agregar comprobante": en lugar de dos botones con uno deshabilitado, el dock tiene **una sola acción principal por estado**. A: `primary` "Agregar comprobante". B: `primary` "Leer comprobante" y "Cambiar" como `ghost` dentro de la tarjeta.
- **Miniatura.** Si es imagen, `Image.file` recortada a 48×60 con radio `radiusXS`. Si es PDF, el icono `strokeRoundedPdf01` sobre `surfaceVariant`. No se renderiza el PDF aquí, por costo. Al tocarla se abre el visor en modo local (sección 4.8) para comprobar que la foto se ve bien **antes** de subirla. Así se evitan lecturas fallidas por fotos borrosas.
- **Error de validación local (C0).** La tarjeta B cambia a la variante de error: borde `c.error`, icono `strokeRoundedAlert02`, título "No podemos usar este archivo", el motivo en el cuerpo y el botón `ghost` "Elegir otro". Se reemplaza el texto rojo suelto de hoy.
- **Componentes reutilizados:** `SacCard`, `SacButton`, `SacPressable`, `_UploadHero` (sin cambios), `showSacSheet` y `SacSheetHeader` para el origen (se mantiene igual que en el PR #161).
- **Accesibilidad.** La tarjeta B lleva `Semantics(label: "Comprobante listo: certificado-2024.pdf, PDF, 2,4 MB")`. "Cambiar" tiene un objetivo táctil de al menos 44×44. El error se anuncia con `liveRegion`.

### 4.2 Hoja de origen

Sin cambios de estructura (PR #161): "Tomar foto", "Elegir de la galería" y "Elegir archivo". Hay dos ajustes:
- Subtítulo de la cámara: "Apoya el documento en una superficie plana y con buena luz". El consejo reduce las lecturas fallidas.
- Subtítulo de galería: "Fotos JPEG, PNG o WebP". Se quita "de tu carrete", que es un calco.

### 4.3 Subida y lectura (estados C y D)

La espera **se queda en la misma pantalla**, como en el PR #161, porque es lo que da continuidad. El panel `_UploadProgressPanel` del dock crece así:

```
├─ dock ────────────────────────────────────────────────┤
│  ①──────②──────③                                      │  _ImportSteps: Subir · Leer · Revisar
│  Subir   Leer   Revisar                                │  (paso activo = accent; hecho = check success)
│ ┌───────────────────────────────────────────────────┐ │
│ │  ••• Subiendo tu comprobante… 64 %                 │ │  SacLoadingSmall + texto (live region)
│ │  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬░░░░░░░░░░░░             │ │  SacTweenedBar (solo en subida)
│ └───────────────────────────────────────────────────┘ │
│ [  Cancelar                                         ] │  ghost; solo en subida
└────────────────────────────────────────────────────────┘
```

- **Subiendo.** Muestra el porcentaje real a partir de `onProgress`. "Cancelar" usa el `CancelToken` que ya existe y vuelve a B sin error.
- **Leyendo.** El paso ② se activa, la barra se oculta porque Vision no reporta avance (una barra falsa engañaría) y se quita "Cancelar": la lectura sigue en el servidor y cancelar no tendría efecto.
- **Cómo se decide cuándo termina la espera (D3).** Tras `process-ocr`, la app consulta el lote cada 2 s y lee `ocr_state`. Espera hasta que sea `done`, `empty` o `failed`, y entonces navega a la Revisión, que muestra el estado F correspondiente. Ya no hay un corte fijo de 12 s que confunda "sigue leyendo" con "sin resultados". Un tope de seguridad de 60 s (constante del feature) lleva a la Revisión con el estado "Seguimos leyendo".
- **Lectura larga (más de 8 s en `pending` o `running`).** El texto cambia a "Sigue leyendo… los PDF de varias páginas tardan un poco más". Aparece el `ghost` "Seguir sin esperar", que lleva a la Revisión en el estado "Seguimos leyendo". Los umbrales de 8 s y de 60 s son constantes del feature, no tokens de motion.
- **Éxito.** El paso ③ se marca y se navega a la Revisión. No hay pantalla intermedia.
- **El cuerpo se bloquea** mientras tanto: la tarjeta B baja a opacidad 0.6 y "Cambiar" se deshabilita. Se usa `AbsorbPointer` para que no se pueda cambiar el archivo a mitad de la subida.
- **Accesibilidad.** El panel mantiene `Semantics(liveRegion: true)` del PR #161. El porcentaje se anuncia solo en saltos de 25 % para no saturar al lector de pantalla. Los pasos usan `Semantics(label: "Paso 2 de 3, Leer, en curso")`.

### 4.4 Errores de subida y lectura (C1, C2, C3 y la variante de F)

Todos usan la **misma pieza**: una tarjeta de estado en el cuerpo (`_ImportStatusCard`, que extiende el patrón de `SacCard` con icono, título, cuerpo y acción) y el dock con la acción principal. Así nunca hay más de una salida principal.

| Estado | Icono y color | Título | Cuerpo | Acción principal (dock) | Secundaria |
| --- | --- | --- | --- | --- | --- |
| C1 Sin conexión | `strokeRoundedWifiDisconnected01`, `c.textSecondary` | No hay conexión | Revisa tu conexión a internet. Tu archivo sigue aquí, no tienes que elegirlo de nuevo. | Reintentar | Cambiar archivo |
| C2a PDF con más de 5 páginas | `strokeRoundedFileRemove`, `c.error` | El PDF tiene más de 5 páginas | Divide el documento o guarda solo las páginas del certificado (hasta 5) y vuelve a subirlo. | Elegir otro archivo | — |
| C2b PDF protegido | igual | El PDF está protegido | Quita la contraseña o la protección del archivo y vuelve a subirlo. | Elegir otro archivo | — |
| C2c PDF dañado | igual | No pudimos abrir el PDF | Vuelve a guardarlo como PDF desde la app donde lo tienes y súbelo otra vez. | Elegir otro archivo | — |
| C3 `PDF_BUSY` (429) | `strokeRoundedHourglass`, `c.info` | Hay mucha demanda en este momento | Estamos revisando otros archivos. Espera unos segundos y vuelve a intentarlo. | Reintentar (conserva el lote y el archivo; solo repite `confirm`) | Cambiar archivo |
| F′ `OCR_UNAVAILABLE` al encolar (400) o `ocr_state = failed` | — | Se resuelven en la Revisión (4.5, estado F, variantes "no disponible" y "no pudimos leer") | | | |
| Error inesperado | `strokeRoundedAlert02`, `c.error` | Algo salió mal | No pudimos subir tu comprobante. Inténtalo de nuevo. | Reintentar | Cambiar archivo |

- **C3 sin reintento automático**, porque el contrato pide no reintentar el POST de forma automática. Para cuidar la espera, el botón "Reintentar" queda deshabilitado **3 s** con el texto "Reintentar en 3…" y luego se habilita. Es una cuenta regresiva de texto, no una animación.
- **Nunca se pinta** el código, `$error` ni `DioException.message`.

### 4.5 Revisión (estados E, F y G)

```
┌ SacTopBar ─ ← Revisa los datos ──────────────────────┐
│ ┌ SacCard (comprobante) ─────────────────────────────┐ │
│ │ ┌─────┐ Tu comprobante                    Ver  ›   │ │  toda la tarjeta es tocable
│ │ │ mini│ certificado-2024.pdf                       │ │  Hero(tag: proof-{fileId})
│ │ └─────┘ PDF · 3 páginas                            │ │
│ └─────────────────────────────────────────────────────┘ │
│ Encontramos                                             │  bodyMedium secondary
│ 3 especialidades y 1 clase                              │  displaySmall w700
│ Revisa cada una y corrige lo que haga falta.            │  bodySmall secondary
│ ┌ aviso (solo si aplica) ────────────────────────────┐ │  GM-01 / institucional / periodo
│ │ ⓘ Si se aprueba Guía Mayor, reemplaza tu …         │ │
│ └─────────────────────────────────────────────────────┘ │
│ (Todas 4) (Listas 3) (Por completar 1)                  │  SacFilterChip quiet, count
│                                                         │
│ ESPECIALIDADES · 3                                      │  label 11 w700 tertiary
│ ┌ fila ───────────────────────────────────────────────┐ │
│ │ [badge] Natación Principiante I        ● Lista       │ │
│ │         Actividades recreativas                      │ │
│ │         12/03/2023 · Ana Gómez                       │ │
│ └──────────────────────────────────────────────────────┘ │
│ ┌ fila incompleta ────────────────────────────────────┐ │
│ │ [?]     Primeros auxilios básicos     ● Falta la fecha│ │
│ │         Leído: «Primeros Auxilos basico»             │ │
│ └──────────────────────────────────────────────────────┘ │
│ CLASES · 1                                              │
│ ┌ fila ───────────────────────────────────────────────┐ │
│ │ [logo] Explorador                      ● Lista       │ │
│ │        Conquistadores · investidura 20/11/2022       │ │
│ └──────────────────────────────────────────────────────┘ │
│ [ + Agregar especialidad o clase ]                      │  outline, al final de la lista
├─ dock ─────────────────────────────────────────────────┤
│ 3 de 4 listas  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬░░░░░░░             │  SacTweenedBar 4px
│ [■ Completar 1 fila                                  ] │  ⇄ "Enviar a revisión" (SacStateSwap)
└────────────────────────────────────────────────────────┘
```

**Decisiones**

- **Comprobante arriba.** Es la fuente de verdad del miembro y del revisor. Reemplaza el `TextButton` de hoy. Los metadatos salen de `CertificateImportFile.type` y `name`. Para un PDF, "3 páginas" sale de `files[].page_count` (D4). Si es `null` (archivo anterior a la migración), la línea dice "PDF" sin número. Una imagen dice "Foto". Si el lote trae más de un archivo (la API acepta hasta 10, D12), la tarjeta muestra el primero y añade "+{n} archivos"; cada fila abre su propio archivo en el visor (4.8).
- **Frase de resumen.** Se construye solo con los tipos que tienen filas:
  - "3 especialidades y 1 clase"
  - "2 especialidades"
  - "1 clase"
  - Con 0 filas se pasa al estado F.
- **Aviso "Amigo y Explorador".** Desaparece de aquí (H2) y vive en el formulario de clase (6.2).
- **Avisos GM y periodo.** Se mantienen condicionados, como hoy, con `_InfoNotice` más un icono `strokeRoundedInformationCircle` en `c.info`.
- **Filtros.** Se usa `SacFilterChip` en variante `quiet` con `count`, en lugar de `SacButton` pequeño. "Falta dato" pasa a ser "Por completar". Si todas las filas están listas, el chip "Por completar" se oculta.
- **Agrupación por tipo.** Cada grupo tiene encabezado con conteo. Dentro del grupo se conserva el orden del OCR, que sigue el orden del documento.
- **Fila (`CertificateImportItemCard` rediseñada)**
  - Toda la tarjeta es tocable (`SacCard(onTap)`) y abre el editor. Se eliminan los botones "Corregir" y "Quitar" de cada fila: "Quitar" vive en el editor (6.3). Esto reduce el ruido visual de N×2 botones.
  - A la izquierda va un *leading* de 40×40: `HonorBadgeImage` si hay especialidad elegida; logo del club (`ClubType.logoAsset`) si es una clase; icono `strokeRoundedHelpCircle` sobre `surfaceVariant` si todavía no hay selección del catálogo.
  - Título: el nombre del catálogo si ya hay selección, o el nombre leído si no la hay.
  - Segunda línea: la categoría (especialidad) o el tipo de club (clase). Si el nombre leído difiere del nombre del catálogo, se muestra "Leído: «…»" en `textTertiary`. Así el miembro ve la corrección.
  - Tercera línea: fecha más instructor (especialidad) o "investidura dd/mm/aaaa" (clase).
  - El estado va arriba a la derecha con `SacBadge`, en mayúscula inicial y no en mayúsculas sostenidas:
    - "Lista" (`success`).
    - "Falta la fecha", "Falta elegir la especialidad", "Falta elegir la clase" o, si falta más de un dato, "Faltan 2 datos" (`warning`).
    - "Rechazada" (`error`).
  - **Confianza.** Se quita "87% OCR". Si `fieldConfidence['date']` es **menor que 0.8** (D5), aparece "Revisa la fecha" con un punto `c.warning` en la tercera línea. Si la fecha llegó vacía porque el OCR leyó un año fuera de 1960 a hoy (D6), la fila dice "Falta la fecha" y el editor muestra "Revisa la fecha" junto a la cita. Ese aviso no bloquea el envío. El umbral vive en una constante de la app (`kDateReviewThreshold = 0.8`); no se aplica al nombre.
- **Dock.** Muestra el progreso "3 de 4 listas" con `SacTweenedBar`. El botón **siempre lleva a algo**:
  - Si faltan filas, dice "Completar 1 fila" (o "Completar N filas"). Hace scroll hasta la primera fila incompleta y abre su editor.
  - Cuando todo está listo, el texto cambia a "Enviar a revisión" mediante `SacStateSwap`.
  - Así se reemplaza el botón deshabilitado y mudo de hoy.
- **Envío.** `SacDialog.show`:
  - Título: "¿Enviar a revisión?"
  - Cuerpo: "Tu Campo Local revisará 3 especialidades y 1 clase. Mientras tanto no podrás editarlas."
  - Botones: "Enviar" y "Cancelar".
  - Durante el envío, el botón pasa a `isLoading`.
  - Si hay error, aparece un banner de error **sobre** el botón dentro del dock: "No pudimos enviarlo. Revisa tu conexión e inténtalo de nuevo". El banner es una pieza de error con fondo `c.error` al 8 % y texto `c.error`, y la pantalla no cambia.

**Estado F: vacío útil, según `ocr_state`.** Con `SacEmptyState`. El estado ya no se adivina (H6 queda resuelto con D3): el mensaje depende de `ocr_state` y de si hay filas.

| Situación | Icono | Título | Cuerpo | Acción principal | Secundaria |
| --- | --- | --- | --- | --- | --- |
| `empty` | `strokeRoundedDocumentValidation` | No encontramos especialidades ni clases | Puede pasar si la foto salió borrosa o el texto está escrito a mano. Puedes agregarlas tú mismo mirando tu comprobante. | Agregar especialidad o clase | Ver comprobante |
| `failed` | `strokeRoundedAlert02`, `c.error` | No pudimos leer tu comprobante | Algo falló al leerlo. Puedes volver a intentarlo o agregarlas tú mismo mirando tu comprobante. | Reintentar lectura (repite `process-ocr`; B3 libera el job fallido) | Agregar especialidad o clase |
| `pending` o `running` | `SacLoading` | Seguimos leyendo tu comprobante | Los PDF de varias páginas tardan un poco más. Aquí verás lo que encontremos. | Agregar especialidad o clase | Ver comprobante |
| `OCR_UNAVAILABLE` al encolar (400) | `strokeRoundedWifiDisconnected01` | La lectura automática no está disponible ahora | Puedes agregar tus especialidades y clases tú mismo mirando tu comprobante. | Agregar especialidad o clase | Ver comprobante |
| `ocr_state = null` (lote creado a mano) | — | No hay filas todavía | Agrega tus especialidades y clases mirando tu comprobante. | Agregar especialidad o clase | Ver comprobante |

- La tarjeta del comprobante sigue arriba.
- **Actualización sola.** Con `pending` o `running` la pantalla consulta el lote cada 3 s (cancelado al salir) y pasa sola a la lista (`done`) o a la variante que corresponda. También se invalida al volver a la app (`didChangeAppLifecycleState` resumed) y con *pull-to-refresh*. Ya no hace falta la línea "Si la lectura termina…" de la versión anterior.
- Con `done` y todas las filas quitadas por el miembro, se muestra el vacío de `empty`, sin la nota de lectura.
- El dock no muestra "Enviar a revisión" mientras no haya filas.

**Estado G: error al cargar el lote.**
- Componente: `SacEmptyState`.
- Título: "No pudimos cargar tu comprobante".
- Cuerpo: "Revisa tu conexión e inténtalo de nuevo".
- Acción: "Reintentar".

**Carga del lote.** `SacLoading` centrado. Desaparece el `CircularProgressIndicator` (H12).

### 4.6 Editor de fila

Ver la sección 6.

### 4.7 Selectores (hojas)

Los tres selectores comparten un **esqueleto** (`CertificateImportPickerSheet`):

- `showSacSheet(isScrollControlled: true, useSafeArea: true)` con una altura máxima del 92 % de la pantalla.
- `SacSheetHeader(title, showClose: true)`.
- Campo de búsqueda fijo arriba, con `autofocus`, *debounce* de 300 ms (como `HonorsCatalogView`) y botón para limpiar.
- Una fila opcional de filtros.
- La lista de resultados.
- Cuatro estados: cargando (`SacLoading`), vacío, error con "Reintentar" y sin conexión.

**a) Especialidad**
- La búsqueda se precarga con el **nombre leído**, así que los resultados aparecen sin escribir.
- La fila de filtros usa `HonorCategoryChip` y empieza con "Todas", que es lo predeterminado. Si la fila ya tiene categoría, esa categoría queda seleccionada. Se oculta si el catálogo no usa categorías (H14).
- Cada resultado tiene 56 px de alto: `HonorBadgeImage` de 36, el nombre y, debajo, la categoría.
- Elegir un resultado cierra la hoja y **fija también la categoría**.
- Sin resultados: "No encontramos «primeros auxilos» en Salud". Botón: "Buscar en todas las categorías".

**b) Categoría.** Hoja simple sin búsqueda (hay pocas categorías), con un punto de color de `honor_category_palette` y el nombre. Al cambiar de categoría, si la especialidad elegida no pertenece a la nueva, se limpia y aparece un aviso inline: "Elige una especialidad de Salud".

**c) Instructor** (`InstructorPicker`, componente **compartido** con "Mis especialidades", sección 6.4). Buscador de usuarios **de tu Campo Local** con **salida de texto libre**:
```
┌ Instructor o instructora ─────────────────── ✕ ┐
│ [🔍 Ana Gó|                                 ⊗] │
│ Personas de tu Campo Local                      │  (texto de apoyo bajo el campo)
│ RECIENTES                                       │  (si la búsqueda está vacía: últimos 3 elegidos en esta sesión)
│ ─────────────────────────────────────────────── │
│ (◯) Ana Gómez                                   │  SacProfileImage 36, solo nombre
│ (◯) Ana Góngora                                 │
│ ─────────────────────────────────────────────── │
│ ✎  Usar «Ana Gó» como nombre                    │  siempre visible si hay ≥ 3 caracteres
│    Para instructores de otro Campo Local o      │
│    que no están en SACDIA                       │
└─────────────────────────────────────────────────┘
```
- **API (D2, D9)**: `GET /instructor-candidates?q=`. No recibe `batchId`, así que el mismo componente sirve a la carga por certificado y a "Mis especialidades". El backend limita los resultados al Campo Local del usuario autenticado, a personas activas, aprobadas y mayores de edad, sin exigir que sean Guía Mayor.
- La búsqueda empieza a partir de 3 caracteres, con *debounce* de 300 ms. Por debajo se muestran los recientes y el texto "Escribe al menos 3 letras".
- **Recientes**: los últimos 3 instructores elegidos **en esta sesión**, en memoria. No se guardan en disco, porque el alcance depende del Campo Local y de datos de otras personas. Si alguno ya no es elegible, el backend responde `HONOR_INSTRUCTOR_INVALID` al guardar y el campo muestra "Esta persona ya no está disponible. Elige a otra o escribe su nombre".
- La fila "Usar como nombre" está **siempre** al final, no solo cuando no hay resultados. Así el miembro no tiene que esperar a que falle la búsqueda. El texto aclara que es para instructores de **otro Campo Local** o que no están en SACDIA (D2).
- **Privacidad (D2)**: cada resultado muestra **solo nombre y foto**. No se muestra club, tipo de club, correo ni teléfono, y la API tampoco los devuelve. Los homónimos se distinguen solo por foto; si genera confusión, se evalúa agregar el nombre del club. Si el usuario no tiene Campo Local, la búsqueda devuelve vacío y el campo se limita al nombre libre, con el texto "Escribe el nombre completo".
- **Sin conexión o error de búsqueda**: la lista muestra "No pudimos buscar. Revisa tu conexión" con "Reintentar", y la fila "Usar como nombre" sigue disponible.

### 4.8 Visor de comprobante

Es una ruta a pantalla completa, `fullscreenDialog`, con fondo negro y la barra de estado clara, igual que `SacImageViewer`. Se abre desde:
1. la tarjeta del comprobante en la Revisión;
2. "Ver en tu comprobante" en el editor, que abre en el archivo y la página de la fila (`source_file_id` y `source_page`, D4 y D12);
3. la miniatura local en Carga (antes de subir);
4. el estado F.

**Apertura en el archivo y la página de la fila (D4 y D12).** El visor recibe `fileId` e `initialPage` (base 1). Los resuelve una función pura, `resolveProofTarget(item, files)`, que usan la Revisión, el editor y las pruebas:
- **Archivo.** Si `item.sourceFileId` existe y aparece en `files[]`, se abre ese archivo. Si es `null` (fila manual, fila anterior a M2 o archivo que ya no está) o no aparece en `files[]`, se abre el **primer archivo** del lote, en el orden en que llega `files[]` (el de subida).
- **Página.** Solo se usa `source_page` cuando el archivo salió de `source_file_id`. Si el archivo es el de respaldo, `initialPage = 1`: la página de una fila es relativa a **su** archivo y no tiene sentido en otro.
  - Desde el editor de una fila con `source_file_id` y `source_page`, `initialPage = source_page`. El botón dice "Ver en tu comprobante · pág. 2".
  - Desde la tarjeta del comprobante, desde la Carga y desde el estado F, el archivo es el primero y `initialPage = 1`.
  - Si `source_page` es `null`, menor que 1 o mayor que el `page_count` de **ese** archivo, se abre en la página 1 y el botón dice solo "Ver en tu comprobante".
- Para un PDF, `PDFView(defaultPage: initialPage - 1)`. Una imagen tiene una sola página, así que se ignora `initialPage` y no se muestran los controles de página.
- El total "de 5" sale del `page_count` del archivo abierto; si es `null`, el visor lo toma de `PDFViewController.getPageCount()` al cargar.
- **Varios archivos.** La Carga de la app sube un archivo por lote, pero la API acepta hasta 10 (`CERTIFICATE_IMPORT_MAX_FILES`). Si el lote trae más de uno, el menú ⋯ del visor agrega "Cambiar de archivo" (una hoja con la lista de nombres), y la barra superior muestra el nombre del archivo abierto. Con un solo archivo ese elemento no aparece.

```
┌ ✕   Tu comprobante        ⋯ ┐   SacTopBar transparente, foreground blanco
│                              │
│      ┌──────────────────┐    │   Imagen: PhotoView (pinch, doble toque 2×)
│      │                  │    │   PDF: PDFView horizontal, pageSnap, una página por vista
│      │   (página 2)     │    │
│      │                  │    │
│      └──────────────────┘    │
│                              │
│   ‹      Página 2 de 5     › │   barra inferior: botones 44×44 + texto (solo PDF > 1 página)
│          • ▬ • • •           │   indicador de página (patrón de SacImageViewer)
└──────────────────────────────┘
```

- **Origen de los datos**
  - Si existe la ruta local del archivo recién subido (se pasa en `extra` desde la Carga), se usa **sin red**.
  - Si no, se pide la URL firmada con `signedCertificateImportDownloadProvider`, que ya existe y valida `https`.
  - Las imágenes se pintan con `Image.network` sin caché persistente: la URL firmada caduca, así que no hay que guardarla en `CachedNetworkImage` con la URL como clave.
  - Un PDF se descarga a un archivo temporal, igual que en `SacPdfViewer`, y se borra al cerrar el visor.
- **PDF paginado.** `PDFView(swipeHorizontal: true, pageSnap: true, pageFling: true, autoSpacing: false)`. Las flechas ‹ › llaman a `PDFViewController.setPage`, son la alternativa accesible al gesto y se deshabilitan en la primera y la última página. El texto "Página 2 de 5" se anuncia como `liveRegion`. Como el máximo es de 5 páginas, no hace falta una tira de miniaturas.
- **Imagen.** `PhotoView` con `minScale: contained` y `maxScale: covered * 3`. El doble toque alterna entre 1× y 2×.
- **Menú ⋯.** Contiene "Abrir en otra app" (el `launchUrl` actual, como salida de respaldo) y, solo si el lote tiene más de un archivo, "Cambiar de archivo" (D12). **No** incluye "Descargar" ni "Compartir" en esta versión, porque el comprobante es un documento sellado y personal (ver riesgos).
- **Estados**
  - Cargando: `SacLoading(color: Colors.white)` con el texto "Abriendo tu comprobante…".
  - Error o enlace vencido: icono `strokeRoundedImageNotFound01` en `Colors.white54` y el texto "No pudimos abrir tu comprobante". El botón "Reintentar" pide **una URL firmada nueva**.
  - Archivo sin confirmar (`FILE_NOT_CONFIRMED`): "Tu comprobante todavía se está procesando". Botón: "Reintentar".
- **Reutilización.** Se extrae de `SacImageViewer` y `SacPdfViewer` la parte visual, en lugar de llamarlos tal cual. Hoy `SacImageViewer` descarga y comparte, y `SacPdfViewer` es vertical. La propuesta es agregar a `SacPdfViewer` un parámetro `horizontalPaged` y a `SacImageViewer` un parámetro `allowShare`, en vez de crear visores paralelos (sección 7).
- **Accesibilidad.** Título semántico "Comprobante, página 2 de 5". El botón ✕ tiene `tooltip` "Cerrar". El contraste es blanco sobre negro. La imagen lleva `Semantics(image: true, label: "Imagen de tu comprobante")`.

### 4.9 Confirmación (estado I)

Se muestra en `CertificateImportStatusView` cuando se llega con `extra: justSubmitted`. No es una pantalla nueva.

```
┌ SacTopBar ─ ← Estado del envío ──────────────────────┐
│        ( ✓ )                                          │  círculo 64, success @12% + check success
│   Lo enviamos a tu Campo Local                        │  headlineSmall w700, centrado
│   Te avisaremos cuando revisen tus especialidades     │  bodyMedium secondary
│   y clases.                                           │
│ ┌ SacCard ───────────────────────────────────────────┐ │
│ │ 3 especialidades · 1 clase       ● En revisión      │ │
│ │ Natación Principiante I                             │ │  lista compacta (máx. 5 + "y 2 más")
│ │ Primeros auxilios básicos …                         │ │
│ └─────────────────────────────────────────────────────┘ │
├─ dock ─────────────────────────────────────────────────┤
│ [■ Listo                                            ] │  vuelve al origen (perfil)
└────────────────────────────────────────────────────────┘
```

- No hay confeti. `celebration_overlay` existe, pero enviar no es lograr nada: el logro es la aprobación. Basta con una entrada sutil del check (sección 5).
- El botón atrás de este estado lleva al perfil, **no** a la Revisión, porque el lote enviado ya no se puede editar. Hoy el `fallbackLocation` apunta a la Revisión.

### 4.10 En revisión y correcciones (estados J y K)

- **J.** La tarjeta de cabecera actual se conserva y los conteos pasan a chips: `SacBadge.success` "2 aprobadas", `SacBadge.error` "1 rechazada" y `neutral` "1 pendiente". Se oculta el chip que tiene conteo 0.
- **K.** La fila rechazada muestra el motivo en `c.error` con la etiqueta "Motivo:". "Corregir y reenviar" **abre el editor** (H10) con un aviso fijo arriba que repite el motivo. Al guardar, el texto del botón es "Guardar y reenviar". En lugar de "pendiente de periodo administrativo" se muestra: "Esta clase se podrá registrar cuando se abra el periodo administrativo".

---

## 5. Especificación de motion

Todas las animaciones usan `SacMotion`. **No se crean tokens.** Las constantes que no son de motion, como el umbral de 8 s o el bloqueo de 3 s, viven en el feature.

| # | Interacción | Frecuencia y propósito | Qué y propiedad | Duración y curva | Interrupción | Reduced Motion |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | Presionar botones, filas, chips o la miniatura | Frecuente; retroalimentación | `scale` 0.97 (`SacPressable`, `SacButton`, `SacCard(onTap)`) | `press` 140, `easeOut` | Implícita: vuelve desde el valor actual | Sin escala (ya implementado) |
| M2 | Abrir o cerrar la hoja de origen, el editor o un selector | Ocasional; coherencia espacial | `translateY` de la hoja (`showSacSheet`) | Entrada `modal` 240 y salida `routeExit` 200, `drawer` | Arrastre nativo de `BottomSheet` | `AnimationStyle.noAnimation` (ya implementado). Se recomienda cambiarlo por un fundido `reducedFade`, ver R4 |
| M3 | Pasar de A a B (aparece la tarjeta del archivo seleccionado) | Raro; evitar un cambio brusco | `FadeTransition` + `ScaleTransition` desde 0.96, con `SacStateSwap` y clave `proof.localPath` | `switcher` 180, `easeOut` | `AnimatedSwitcher` retoma | Solo fundido `reducedFade` 160 |
| M4 | Cambio de texto "Subiendo…" → "Leyendo…" → "Sigue leyendo…" | Raro; indicación de estado | Opacidad del texto (`AnimatedSwitcher` con clave del mensaje). El loader **no** se reinicia | `switcher` 180, `easeOut` | Retoma | Fundido 160 |
| M5 | Barra de subida | Constante; progreso | `SacTweenedBar` (`TweenAnimationBuilder`) | `standard` 200 por paso, `easeOut` (ya implementado). **No** se usa `linear` porque los saltos de `onProgress` son irregulares: ease-out suaviza cada salto, y en conjunto la barra se ve lineal | Retarget desde el valor mostrado | Salta al valor (ya implementado) |
| M6 | Paso ① ② ③ que pasa a "hecho" | Raro; indicación de estado | Cambio de icono círculo → check con `SacStateSwap`, y color con `AnimatedContainer` | `switcher` 180, `easeOut` | Retoma | Fundido 160 |
| M7 | Puntos del loader | Mientras se espera | `LoadingAnimationWidget.waveDots` (sin cambios) | Ritmo de la librería | — | Tres puntos estáticos (ya implementado en `SacLoading`) |
| M8 | Tarjeta de error C1, C2 o C3 que reemplaza a B | Raro; indicación de estado | `SacStateSwap` (fundido + escala 0.96 → 1) | `switcher` 180, `easeOut` | Retoma | Fundido 160 |
| M9 | Navegación Carga → Revisión → Estado | Raro; coherencia espacial | `_sharedAxisBuild`, sin cambios | `routeEnter` 240 y `routeExit` 200, `easeOut` | Ruta | Fundido (ya implementado) |
| M10 | Primera aparición de filas en la Revisión | **Una vez por lote**; evitar un cambio brusco y mostrar que "llegaron resultados" | `StaggeredListItem(animate: true)`: opacidad + `SlideTransition` | `standard` 200, `easeOut`, `stagger` 40, tope en el índice 5 (≤ 400 ms en total). Ver la nota de H16: ajustar `slideOffset` para que sean unos 8 px reales | No bloquea toques. Si el usuario hace scroll, los ítems siguen animándose (no hay estado que dependa de ellos) | Sin animación (ya implementado). **No** se repite al volver del editor ni al filtrar: se usa una bandera `_entered` |
| M11 | Cambio de filtro | Frecuente; **no se anima** | Cambio instantáneo de la lista | — | — | — |
| M12 | Una fila cambia de estado al guardar ("Falta la fecha" → "Lista") | Frecuente dentro de la sesión; indicación de estado | `SacStateSwap` en la insignia y en el *leading* (aparece la imagen de la especialidad). El resto de la tarjeta no se mueve | `switcher` 180, `easeOut` | Retoma | Fundido 160 |
| M13 | Quitar una fila | Ocasional; evitar un cambio brusco | `SliverAnimatedList.removeItem` con `SizeTransition` (sizeFactor) + `FadeTransition` | `standard` 200, `easeOut` | La lista retoma | Fundido `reducedFade` 160 con `sizeFactor` fijo en 1, de modo que el hueco se cierra de golpe al terminar el fundido |
| M14 | Agregar una fila | Ocasional; coherencia espacial (dónde quedó) | `SliverAnimatedList.insertItem`: `SizeTransition` + fundido, y luego `Scrollable.ensureVisible` | `standard` 200, `easeOut`; el scroll usa `easeInOut` 240 | Retoma | Fundido 160 y salto de scroll sin animación |
| M15 | Botón del dock "Completar N filas" ⇄ "Enviar a revisión" | Ocasional; indicación de estado | `SacStateSwap` dentro de `SacButton` (ya lo usa para la carga) | `switcher` 180, `easeOut` | Retoma | Fundido 160 |
| M16 | "Completar N filas" lleva a la primera incompleta | Ocasional; coherencia espacial | `ScrollController.animateTo` hasta la fila y después se abre el editor | 240 (`modal`), `easeInOut` porque es movimiento en pantalla | Si el usuario toca durante el scroll, se cancela | `jumpTo` y luego el editor |
| M17 | Aparece un aviso inline en el editor (GM-01, institucional, "puedes acreditar…", error de campo) | Ocasional; evitar un cambio brusco | `AnimatedSize` del contenedor + `AnimatedOpacity` del aviso | Entrada `standard` 200 y salida `reducedFade` 160 (asimétrico), `easeOut` | Implícita | Solo opacidad 160; el tamaño cambia sin animación (`AnimatedSize` con `Duration.zero`) |
| M18 | Elegir especialidad o instructor: el campo del selector pasa de vacío a lleno | Frecuente; indicación de estado | `SacStateSwap` en el contenido del campo | `switcher` 180, `easeOut` | Retoma | Fundido 160 |
| M19 | Escribir en los buscadores y mostrar resultados | Muy frecuente; **no se anima** | Los resultados se reemplazan sin transición. El loader solo aparece si la respuesta tarda más de 300 ms, para evitar parpadeos | — | — | — |
| M20 | Miniatura → visor (imagen) | Ocasional; coherencia espacial | `Hero(tag: 'certificate-proof-{fileId}')` sobre la miniatura y la imagen + ruta `SacFadeThroughRoute(fullscreenDialog)` | Ruta `routeEnter` 240 / `routeExit` 200, `easeOut`. El `Hero` usa la duración de la ruta | Nativa del `Hero` | `HeroMode(enabled: false)` y fundido `reducedFade` (ya implementado en la ruta) |
| M21 | Miniatura → visor (PDF) | Ocasional | Sin `Hero`: la miniatura es un icono y no una página, así que el viaje sería falso. Solo fundido de la ruta | 240/200, `easeOut` | — | Fundido 160 |
| M22 | Cambio de página del PDF | Frecuente dentro del visor | El *snap* nativo de `PDFView`; con las flechas, `setPage` sin transición propia | Nativo | Gesto nativo | Igual. Animación nativa que no se puede controlar, se acepta |
| M23 | Indicador de página (puntos) | Frecuente dentro del visor; indicación de estado | `AnimatedContainer` del ancho del punto activo (patrón de `SacImageViewer`). **Cambio:** pasar de `180ms` literal a `SacMotion.switcher` con `SacMotion.easeInOut`, porque es un *morph* en pantalla | 180, `easeInOut` | Implícita | Sin animación de ancho; solo cambia el color |
| M24 | Check de confirmación (I) | Raro; está dentro del presupuesto de deleite | Círculo y check: `ScaleTransition` de 0.96 a 1 + fundido | `modal` 240, `easeOut`, 80 ms de retraso respecto a la ruta | No aplica | Solo fundido 160 |
| M25 | Banner de error en el dock (fallo al enviar o al guardar) | Raro; indicación de estado | `AnimatedSize` + fundido (como M17) | 200 / 160, `easeOut` | Implícita | Solo fundido |
| M26 | La tarjeta de instructor de una especialidad aprobada cambia de estado (sin propuesta → "Instructor en revisión" → rechazada o con instructor nuevo) (6.5) | Raro; indicación de estado | `SacStateSwap` sobre el contenido de la tarjeta (fundido + escala 0.96 → 1). El alto de la tarjeta cambia con `AnimatedSize` | `switcher` 180, `easeOut` | Retoma | Fundido 160 y alto sin animación |

Notas de consistencia:
- Nada pasa de 240 ms, salvo el stagger total de M10. Ninguna animación usa `Curves.easeIn` ni `Curves.easeInOut` de Material.
- No hay animaciones atadas a gestos que no sean nativas, así que no hacen falta *springs*. Si en el futuro la hoja del editor se descarta arrastrando con velocidad, el comportamiento nativo de `BottomSheet` ya cubre el umbral por velocidad.
- Para revisar a mano: el par tamaño/opacidad de M13 y M14 (el skill advierte que no hay fórmula) y el `slideOffset` real de M10. Hay que probarlos con `timeDilation = 3` y en un dispositivo físico.

---

## 6. Formulario de fila (editor)

Es una hoja con `showSacSheet(isScrollControlled: true, useSafeArea: true)`, una altura máxima del 92 % y el teclado respetado con `viewInsets`. La estructura es fija:

```
┌ ─── (grabber) ───────────────────────────────────┐
│ Corregir especialidad                          ✕ │  SacSheetHeader (showClose)
│ [ Especialidad ][  Clase  ]                      │  solo al AGREGAR o si el tipo es dudoso
├──────────────────────────────────────────────────┤
│ ┌ Leído en tu comprobante ───────────────────────┐│  bloque de cita: surfaceVariant, radio 12
│ │ ❝ Primeros Auxilos basico ❞                     ││  bodyLarge, texto tal cual
│ │ Ver en tu comprobante ›        Corregir texto   ││  dos ghosts pequeños, ≥44 px de alto
│ └────────────────────────────────────────────────┘│
│  … campos (6.1 o 6.2) …                           │
├──────────────────────────────────────────────────┤
│ Falta: fecha                                      │  (si incompleto) bodySmall warning-ink
│ [■ Guardar                                      ] │  primary
│ [  Quitar de la lista                           ] │  ghost destructivo (solo al corregir)
└──────────────────────────────────────────────────┘
```

**Leído frente a elegido**
- El **nombre leído** es una cita (comillas angulares, fondo `surfaceVariant` e icono `strokeRoundedQuoteUp` en `textTertiary`). Se ve como "lo que dice el papel", nunca como un campo vacío por completar.
  - "Corregir texto" convierte la cita en un `SacTextField` (M17) para corregir un error de lectura. Rara vez se necesita, porque lo importante es la selección del catálogo.
  - En una fila **agregada a mano** no hay cita. El campo es "Nombre como aparece en tu comprobante (opcional)". Si queda vacío, al guardar toma el nombre del catálogo elegido. Así se cumple la regla de completitud actual (`detectedName` no vacío) sin pedirle al miembro un dato redundante.
- La **selección del catálogo** es un campo selector (`SacPickerField`, sección 7). Vacío dice "Elige la especialidad". Lleno muestra la imagen, el nombre y la categoría, más un chevron ›.
  - Si el OCR propuso una coincidencia (`honorId` o `classId` presentes), el campo llega lleno y con el sello "Sugerida", en `SacBadge` neutral, hasta que el miembro la confirme o la cambie. El sello no bloquea nada: comunica que la propuso el sistema.
- **Fecha.** `ActivityDatePickerField`, el mismo que usan las hojas de investidura, abre `showDatePicker` con `locale`, con `firstDate = 1960-01-01` y `lastDate = hoy` (D6). Las dos constantes viven en un solo archivo de `core` (`kMinCertificateDate`) y se prueban contra el backend.
  - Si viene de `detectedDate`, se precarga con el sello "Leída".
  - Si `fieldConfidence['date']` es **menor que 0.8** (D5), aparece la ayuda "Revisa la fecha" en `warning` bajo el campo, y la fila de la lista dice lo mismo (4.5).
  - Si el OCR leyó una fecha fuera de rango, el backend la devuelve vacía (`completed_at` nulo) y el campo llega sin precargar, con la ayuda "Revisa la fecha. Lo que leímos no es una fecha válida" y la cita visible arriba.

**Tipo (especialidad o clase).** Al agregar se muestran dos `SacFilterChip` en variante `filled` (radio segmentado). Al corregir, el tipo se muestra fijo. Si el OCR lo marcó como `unknown`, aparece el selector. Si la fila es una especialidad, hay un enlace pequeño "¿Es una clase?" para el caso raro de una lectura equivocada. Al cambiar el tipo se limpian los selectores (M17), pero **se conservan** la cita y la fecha.

### 6.1 Especialidad

| Campo | Componente | Obligatorio | Validación y estados |
| --- | --- | --- | --- |
| Leído en tu comprobante | Bloque de cita (o texto opcional si es manual) | No (se autocompleta) | Máximo 120 caracteres al corregir |
| Categoría | `SacPickerField` → hoja de categorías | No: es un **filtro**. Se llena sola al elegir la especialidad | Se oculta si el catálogo del tipo de club no usa categorías (H14) |
| Especialidad | `SacPickerField` → selector buscable (4.7a) | **Sí** | Error: "Elige la especialidad". Si la categoría cambia y deja de coincidir: "Elige una especialidad de {categoría}" |
| Fecha en que la completaste | `ActivityDatePickerField` | **Sí** | `firstDate` = 1960-01-01 y `lastDate` = hoy (D6). Errores: "Elige la fecha"; "La fecha no puede ser anterior a 1960"; "La fecha no puede ser futura" |
| Instructor o instructora | `SacPickerField` → `InstructorPicker` (4.7c) | **No** (D1). No cuenta en "Falta…", en el dock ni en "Completar N filas" | Usuario: `SacProfileImage` de 28 y el nombre, con check `success` y debajo "Persona de tu Campo Local". Texto libre: icono `strokeRoundedUserEdit01`, el nombre y debajo "Nombre escrito · no verificado". Vacío dice "Agregar instructor (opcional)". Acción "Quitar" en `ghost`. Texto de ayuda bajo el campo: "Tu Campo Local revisa este dato. No avisamos a la persona." (D8) |

### 6.2 Clase

| Campo | Componente | Obligatorio | Validación y estados |
| --- | --- | --- | --- |
| Leído en tu comprobante | Bloque de cita | No | Igual que en la especialidad |
| Tipo de club | Tres `SacFilterChip` con `logoAsset` (Conquistadores, Aventureros, Guías Mayores) | **Sí** | Se precarga desde `classAssetCode` o desde la clase sugerida. Al cambiarlo se limpia la clase |
| Clase | Lista de opciones (radio) de las clases del tipo de club, con el punto de acento de `SacAccent` por clase. No necesita buscador porque son pocas | **Sí**. El backend necesita `class_id`, que nunca se muestra | Error: "Elige la clase". Estado cargando: tres filas *skeleton* estáticas |
| Fecha de investidura | `ActivityDatePickerField` | **Sí** | Misma regla que la especialidad (D6): entre 1960-01-01 y hoy, con los mismos mensajes. Un OCR que lea un año fuera de rango llega sin fecha |

**Aviso de orden, contextual (H2).** Aparece debajo de la clase **solo** si la clase elegida no es la primera de su tipo de club según el orden del catálogo. Por ejemplo, con Explorador: "Puedes acreditar Explorador aunque no tengas Compañero registrado." Nombra la clase **anterior inmediata** y no una lista. Si se elige Amigo, el aviso no aparece. Entra con M17.

**Avisos GM, contextuales.** Si se elige GM-01: "Si se aprueba, reemplaza tu inscripción actual de Guía Mayor". Si se elige GM-02 o GM-03: "Esta clase pasa por una revisión institucional. Aprobarla no crea una inscripción". Los textos actuales se mantienen, en tono más directo.

### 6.3 Guardar, errores y quitar

- **"Guardar" siempre está habilitado.**
  - Con la fila completa, se guarda como `markAsReady: true`.
  - Con la fila incompleta, se guarda como borrador de la fila (`markAsReady: false`), igual que hoy. La línea "Falta: fecha" sobre el botón avisa antes de guardar, y la fila queda "Falta la fecha" en la lista.
  - Así el miembro puede avanzar sin quedar bloqueado.
- Al guardar con datos inválidos, por ejemplo una fecha futura o anterior a 1960, la hoja hace scroll al primer campo con error (M16, a escala) y anuncia el error con `SemanticsService.announce`. La validación local usa el mismo rango que el backend (D6); si el backend igualmente responde `CERTIFICATE_IMPORT_DATE_TOO_OLD` o `CERTIFICATE_IMPORT_DATE_IN_FUTURE`, el error se muestra en el campo de fecha, no en el banner general.
- **Errores de instructor del backend.** `HONOR_INSTRUCTOR_INVALID` (la persona ya no es elegible) y `HONOR_INSTRUCTOR_SELF` se muestran en el campo de instructor: "Esta persona no está disponible. Elige a otra o escribe su nombre" y "No puedes ser tu propio instructor". La hoja no se cierra.
- **Error de red al guardar.** La hoja **no se cierra**. Aparece el banner M25: "No pudimos guardar. Revisa tu conexión e inténtalo de nuevo". El botón vuelve a su estado normal (corrige H8).
- **Quitar de la lista.** `SacDialog.show(confirmIsDestructive: true)`:
  - Título: "¿Quitar esta especialidad?" (o "esta clase").
  - Cuerpo: "No se enviará a revisión. Puedes volver a agregarla después."
  - Botones: "Quitar" y "Cancelar".
  - Al confirmar se cierra la hoja y la fila sale con M13. Si la API falla, la fila **vuelve** y aparece `SacSnackBar`: "No pudimos quitarla. Inténtalo de nuevo" (corrige H9).
- **Descartar cambios.** Si se cierra la hoja con cambios sin guardar, aparece `SacDialog`:
  - Título: "¿Descartar los cambios?"
  - Botones: "Descartar" y "Seguir editando".

### 6.4 Formulario de "Mis especialidades" (flujo normal, D9 y D10)

El instructor opcional también se captura cuando el miembro trabaja una especialidad por el flujo normal, no solo por la carga por certificado. Así el conteo de "especialidades enseñadas" cubre los dos caminos. Por D10, el lugar es `HonorEvidenceView`, antes de "Enviar a revisión", y no el momento de inscribirse (al inscribirse todavía no se enseñó nada).

**Cómo es hoy** (`origin/development`, `lib/features/honors`):
- "Mis especialidades" (`my_honors_view.dart`) lista las especialidades del miembro. Tocar una tarjeta abre `HonorEvidenceView` (`honor_evidence_view.dart`).
- Esa vista reúne las evidencias y es el **único punto de envío a revisión** (`_submitForReview` → `POST /validation/submit` con `entityType: honor`).
- La inscripción ocurre antes, en `honor_detail_view.dart` (`POST /users/:userId/honors/:honorId`, sin cuerpo).
- No existe ningún campo de instructor ni ningún selector de fecha en el flujo. `RegisterUserHonorParams` y `HonorRegistrationNotifier` existen, pero ninguna vista los usa.

**Qué se agrega**
- Una tarjeta **"Instructor o instructora"** en `HonorEvidenceView`, encima del botón "Enviar a revisión". Es opcional, no bloquea el envío y usa el mismo `InstructorPicker` (4.7c) y la misma presentación del campo (6.1): usuario de tu Campo Local o nombre escrito, con "Quitar".
- Texto de ayuda: "Tu Campo Local revisa este dato. No avisamos a la persona." (D8). Sin esta tarjeta no hay forma de que el flujo normal alimente el conteo.
- **Cuándo se guarda**: al elegir, con `PATCH /users/:userId/honors/:honorId` y `{ instructorUserId }` o `{ instructorName }` (camelCase, como el resto de este endpoint). `null` quita el instructor. El guardado es inmediato, con `SacStateSwap` en el campo (M18); si falla, el campo vuelve al valor anterior y aparece `SacSnackBar`: "No pudimos guardar el instructor. Inténtalo de nuevo".
- **Cuándo se puede editar (D10)**: solo mientras la especialidad está en curso (`IN_PROGRESS`) o fue rechazada (`REJECTED`). Es una regla del backend (`assertHonorIsMutable`), no solo de la app.
  - En revisión (`PENDING_REVIEW`) la tarjeta se muestra **de solo lectura** (sin "Quitar" ni selector), con el instructor declarado. Si no hay, dice "Sin instructor registrado".
  - En una especialidad aprobada (`APPROVED`) el `PATCH` sigue bloqueado. La tarjeta no se edita en sitio: ofrece la **propuesta de instructor** de la sección 6.5 (D11).
- **Especialidades ya aprobadas antes de esta funcionalidad**: quedan sin instructor, pero ya no es un callejón sin salida. El miembro puede proponerlo con el flujo de 6.5.
- **Fecha**: este flujo no tiene selector de fecha (la fecha de inicio es "hoy", la fija el backend). Por eso D6 se aplica aquí solo en el backend (DTO) y no agrega un campo nuevo a la app. Si más adelante se agrega un selector de fecha de finalización, usa `kMinCertificateDate` y las mismas reglas.
- **Errores**: `HONOR_INSTRUCTOR_INVALID`, `HONOR_INSTRUCTOR_SELF` y `VALIDATION_HONOR_INVALID_STATUS` (si la especialidad cambió de estado en otro dispositivo) se muestran en la tarjeta con los textos de 6.3 y del campo "no disponible".
- **Motion**: el mismo conjunto que 6.1 (M17 para avisos inline, M18 para vacío a lleno). Sin animaciones nuevas.
- **Accesibilidad**: `Semantics(label: "Instructor: Ana Gómez, persona de tu Campo Local")` o "…, nombre escrito, no verificado". Objetivos táctiles de al menos 44×44.

**Compartir el componente**
- `InstructorPicker` y `InstructorField` (la presentación de usuario o nombre libre) viven en `core/widgets/` (o en un feature compartido `instructor_selection`), **no** dentro de `certificate_import`. Reciben un valor (`InstructorSelection`: ninguno, usuario o nombre) y un callback, y no saben de lotes ni de especialidades.
- El estado de búsqueda (`instructorCandidatesProvider(query)`) también es compartido: *debounce* de 300 ms, mínimo de 3 caracteres y recientes en memoria por sesión.
- Cada feature mapea `InstructorSelection` a su propio payload: `instructor_user_id`/`instructor_name` (snake_case) en la carga por certificado e `instructorUserId`/`instructorName` (camelCase) en `/users/:userId/honors`.
- Se agrega a `UserHonor` y `UserHonorModel` el campo `instructor` (kind, userId, displayName, photoUrl), leído del bloque `instructor` que devuelve el backend (documento hermano, §4.8).

### 6.5 Especialidad ya aprobada: proponer el instructor (D11)

Una especialidad aprobada está congelada: fecha, evidencias y modo de trabajo no se tocan. D11 abre **una sola excepción**: el miembro puede **proponer** el instructor, y el Campo Local decide. La propuesta nunca cambia el instructor vigente hasta que se aprueba.

**Dónde se ve y se propone.** En el detalle de la especialidad aprobada, que es `HonorEvidenceView` (todas las tarjetas de "Mis especialidades", también las validadas, abren esa vista). La tarjeta "Instructor o instructora" ya existe por 6.4; en una especialidad aprobada cambia de estado según la propuesta. No hay pantalla nueva ni ningún otro control editable.

| Estado de la tarjeta | Cuándo | Qué muestra | Acciones |
| --- | --- | --- | --- |
| Sin instructor | Aprobada, sin instructor vigente y sin propuesta | "Sin instructor registrado" | `ghost` "Proponer instructor" |
| Con instructor | Aprobada, con instructor vigente y sin propuesta | El instructor con la presentación de 6.1 (sin "Quitar") | `ghost` "Proponer otro instructor" |
| **Instructor en revisión** | Hay una propuesta `PENDING` | Insignia `SacBadge` neutral con icono de reloj, "Instructor en revisión". Debajo, la persona propuesta (foto y nombre, o el nombre escrito con "no verificado"). Texto: "Tu Campo Local revisará esta propuesta. Mientras tanto se mantiene {instructor vigente}." o, si no hay vigente, "…se mantiene sin instructor." | `ghost` "Cancelar propuesta" |
| Propuesta rechazada | Última propuesta `REJECTED` y no hay una nueva | Aviso con `c.error` al 8 %: "Tu Campo Local rechazó la propuesta" y "Motivo: {motivo}". Debajo, el instructor vigente (o "Sin instructor registrado") | `ghost` "Proponer otro instructor" |
| Propuesta aprobada | La propuesta pasó a `APPROVED` | No hay estado aparte: la persona propuesta es ahora el instructor vigente (estado "Con instructor") | — |

**Flujo de la propuesta**
1. "Proponer instructor" abre el mismo `InstructorPicker` de 4.7c (alcance, privacidad y salida de texto libre sin cambios: D2).
2. Al elegir, **no se guarda en el acto** como en 6.4. Aparece `SacDialog.show`:
   - Título: "¿Proponer a {nombre}?"
   - Cuerpo: "Tu Campo Local revisará la propuesta. El resto de los datos de la especialidad no cambia."
   - Botones: "Proponer" y "Cancelar".
   La confirmación existe porque esta acción abre una revisión de otra persona; elegir en 6.4 solo edita un borrador.
3. "Proponer" llama a `POST /users/:userId/honors/:honorId/instructor-proposal` con `{ instructorUserId }` o `{ instructorName }` (camelCase). Si ya había una propuesta pendiente, la nueva **la reemplaza** (el backend marca la anterior como cancelada).
4. "Cancelar propuesta" llama a `DELETE …/instructor-proposal`, con `SacDialog` ("¿Cancelar la propuesta?" / "Se mantiene {instructor vigente}." / "Cancelar propuesta" y "Volver").
5. El estado se lee del bloque `instructor_proposal` que trae cada fila de `GET /users/:userId/honors` (`status`, `kind`, `display_name`, `photo_url` solo en respuestas de una fila, `rejection_reason` y `created_at`). `UserHonor` agrega `instructorProposal`.
6. Tras proponer o cancelar se invalida `userHonorsProvider`. No hay notificación de la decisión en v1 (en la línea de D8): el estado se actualiza al abrir la pantalla, con *pull-to-refresh* y al volver a la app (`didChangeAppLifecycleState` resumed).

**Errores** (dentro de la tarjeta, sin cerrar el selector; texto de 6.3 cuando ya existe):
- `HONOR_INSTRUCTOR_INVALID`: "Esta persona no está disponible. Elige a otra o escribe su nombre".
- `HONOR_INSTRUCTOR_SELF`: "No puedes ser tu propio instructor".
- `HONOR_INSTRUCTOR_UNCHANGED`: "Esa persona ya es tu instructor".
- `HONOR_INSTRUCTOR_PROPOSAL_NOT_APPROVED`: la especialidad cambió de estado en otro dispositivo; se invalida la lista y la tarjeta vuelve al estado que corresponda.
- Red u otro error: banner M25, "No pudimos enviar la propuesta. Inténtalo de nuevo".

**Compatibilidad hacia atrás.** Si la respuesta no trae la clave `instructor_proposal` (backend sin B9), la app **no muestra** "Proponer instructor" y deja la tarjeta como en 6.4 (solo lectura). `instructor_proposal: null` significa "sin propuesta" y sí habilita la acción (R12).

**Motion.** El cambio entre estados de la tarjeta usa `SacStateSwap` (M26). El resto reutiliza M17, M18 y M25. Sin tokens nuevos.

**Accesibilidad.** La tarjeta en revisión lleva `Semantics(liveRegion: true, label: "Instructor en revisión: Ana Gómez, persona de tu Campo Local. Se mantiene Juan López.")`. Los botones `ghost` miden al menos 44×44. El motivo del rechazo se anuncia junto con el aviso.

**Qué no hace.** No edita fecha, evidencias, requisitos ni modo de trabajo. No reutiliza el `PATCH` de 6.4 (que sigue bloqueado para aprobadas) ni el alta. No avisa a la persona propuesta (D8).

---

## 7. Componentes

### 7.1 Se reutilizan

| Componente | Uso |
| --- | --- |
| `SacTopBar(frosted)` + `SacFrostedVeil` | Todas las pantallas |
| `SacCard` (+ `onTap`), `SacBadge` (`success`, `warning`, `error`, `neutral`), `SacButton` (`primary`, `outline`, `ghost`, `destructive`) | Tarjetas, estados y acciones |
| `SacFilterChip` (`quiet` con `count`; `filled` con `logoAsset`) | Filtros de la Revisión, tipo de fila y tipo de club |
| `HonorCategoryChip`, `honor_category_palette`, `HonorBadgeImage`, `honorCategoriesProvider` | Selector de especialidad y fila |
| `ClubType` / `clubTypeFromName` / `logoAsset`, acentos de clase de `SacAccent` | Formulario de clase y fila |
| `SacProfileImage` | Instructor |
| `showSacSheet`, `SacSheetHeader`, `SacSheetGrabber` | Hojas |
| `SacDialog.show` | Enviar, quitar y descartar |
| `SacEmptyState` | Estados F y G y búsquedas vacías |
| `SacSnackBar` | Errores al quitar |
| `SacLoading` / `SacLoadingSmall` | Todas las esperas (reemplaza a `CircularProgressIndicator`) |
| `SacTweenedBar` | Subida y progreso del dock |
| `SacStateSwap`, `StaggeredListItem`, `SacPressable` | Motion (sección 5) |
| `ActivityDatePickerField` | Fechas |
| `_UploadProgressPanel` (PR #161) | Base del panel de espera, que se amplía |
| `_UploadHero`, `_ProofSourceTile`, `_showProofSourceSheet` (PR #161) | Sin cambios de estructura |
| `SacImageViewer` / `SacPdfViewer` | Base del visor (con los parámetros nuevos de 7.2) |

### 7.2 Componentes nuevos o extensiones

| Nuevo / extensión | Dónde | Por qué |
| --- | --- | --- |
| `SacPickerField` | `core/widgets/` (se **promueve** `ActivityPickerField`, sin duplicarlo; la versión de activities pasa a ser un alias) | Campo que abre un selector con estados vacío, lleno, cargando y error. Lo usan 4 campos del editor, más el instructor de "Mis especialidades" (6.4), y ya existe un equivalente en activities |
| `SacPdfViewer(horizontalPaged: true, initialPage:, pageCount:)` + controles ‹ › + indicador | Extensión de `core/widgets/sac_pdf_viewer.dart` | El PDF paginado de hasta 5 páginas que abre en la página de la fila (D4). Hoy el visor es vertical |
| `SacImageViewer(allowShare: false, heroTag:, localPath:)` | Extensión de `core/widgets/sac_image_viewer.dart` | Comprobante sin compartir, con `Hero` y archivo local |
| `CertificateProofViewer(initialPage:)` | Feature: decide entre imagen y PDF, resuelve archivo local o URL firmada, valida `initialPage` contra `page_count` y maneja los estados | Orquestador delgado |
| `CertificateProofSummaryCard` | Feature: miniatura + metadatos (`page_count`) + "Ver" | Revisión, estado F y confirmación |
| `ImportStatusCard` | Feature: icono, título, cuerpo y acción para C0 a C3 | Una pieza para todos los errores de carga |
| `ImportSteps` | Feature: tres pasos en el dock | Indicación de estado durante la espera |
| `DetectedTextQuote` | Feature: bloque "Leído en tu comprobante" | Separa lo leído de lo elegido |
| `CertificateImportPickerSheet` + `HonorPicker`, `HonorCategoryPicker` | Feature (el esqueleto podría subir a core si se repite) | Selectores del editor |
| `InstructorPicker`, `InstructorField`, `InstructorSelection` y `instructorCandidatesProvider` | **`core/widgets/`** (o feature compartido), no dentro de `certificate_import` (D9) | El mismo selector en la carga por certificado y en "Mis especialidades". Sin dependencia de lotes |
| `InstructorProposalCard`, `InstructorProposal` (entidad) y `instructorProposalActionsNotifier` (proponer y cancelar) | Feature `honors` (usa `InstructorPicker` de `core/widgets/`) | Los estados de la tarjeta de 6.5 sobre una especialidad aprobada (D11). Invalida `userHonorsProvider` y no toca `updateUserHonor` |
| `resolveProofTarget(item, files)` | Feature `certificate_import` (función pura) | Resuelve archivo y página del visor con el respaldo "primer archivo, página 1" (4.8, D12) |
| `OcrState` (enum `pending/running/done/empty/failed`) y su seguimiento en el repositorio | Feature, capa de dominio y datos | Reemplaza el sondeo fijo de 6 consultas (D3). Lo usan Carga y Revisión (4.3 y 4.5) |
| `kMinCertificateDate` (1960-01-01) y `kDateReviewThreshold` (0.8) | `core/` (la fecha) y feature (el umbral) | Constantes únicas que usan editor, fila y pruebas (D5, D6) |
| `ClassPickerList` | Feature: radios por tipo de club | Formulario de clase |
| `CertificateImportErrorMapper` | Feature (presentación): `Failure` → título, cuerpo y acción | Termina con los códigos crudos (H5, H7) |
| Capa de datos: subida por etapas con `batchId` y `fileId` reintentables; código `PDF_BUSY` en `pdfCodes`; mapeo de los `OCR_*` | Repositorio y data source | Necesario para C3 y F (no es UI, pero la UI depende de esto) |
| Se retira | `certificate_import_processing_view.dart` y su ruta | Obsoleta (H11) |

---

## 8. Copy (español neutro con tuteo, como el resto de la app)

| Clave | Hoy | Propuesta |
| --- | --- | --- |
| `upload.hint` | "…máximo 10 MiB. Un documento por carga. Puedes acreditar clases en cualquier orden… Completa los datos a mano antes de enviar." | "PDF de hasta 5 páginas o foto JPEG, PNG o WebP. Máximo 10 MB. Un comprobante por carga." |
| `upload.hero_body` | "Subimos el archivo… Luego completas el expediente a mano…" | "Leemos tu certificado y te proponemos las especialidades y clases. Tú las revisas antes de enviarlas a tu Campo Local." |
| `upload.submit` | "Subir comprobante" | "Leer comprobante" |
| `upload.too_large` | "…supera los 10 MiB. Elige uno más liviano." | "El archivo pesa más de 10 MB. Elige uno más liviano o toma la foto de nuevo." |
| `upload.reading_slow` (nueva) | — | "Sigue leyendo… los PDF de varias páginas tardan un poco más." |
| `upload.skip_wait` (nueva) | — | "Seguir sin esperar" |
| `upload.pdf_busy_*` (nuevas) | (código crudo) | Título: "Hay mucha demanda en este momento". Cuerpo: "Estamos revisando otros archivos. Espera unos segundos y vuelve a intentarlo." |
| `upload.offline_*` (nuevas) | "Error de red" o texto de Dio | Título: "No hay conexión". Cuerpo: "Revisa tu conexión a internet. Tu archivo sigue aquí." |
| `processing.*` | "Extraemos honores…" | Se retira con la vista |
| `review.independent_hint` | Fijo en la cabecera | Se elimina. La reemplaza `editor.class_order_hint`: "Puedes acreditar {clase} aunque no tengas {anterior} registrado." |
| `review.filter_missing` | "Falta dato {count}" | "Por completar {count}" |
| `review.add_row` | "Agregar fila" | "Agregar especialidad o clase" |
| `review.empty_*` (nuevas), una variante por `ocr_state` (4.5) | — | `empty`: "No encontramos especialidades ni clases" / "Puede pasar si la foto salió borrosa o el texto está escrito a mano. Puedes agregarlas tú mismo mirando tu comprobante." · `failed`: "No pudimos leer tu comprobante" / "Algo falló al leerlo. Puedes volver a intentarlo o agregarlas tú mismo mirando tu comprobante." · `pending`/`running`: "Seguimos leyendo tu comprobante" / "Los PDF de varias páginas tardan un poco más. Aquí verás lo que encontremos." · no disponible: "La lectura automática no está disponible ahora" / "Puedes agregar tus especialidades y clases tú mismo mirando tu comprobante." |
| `review.retry_read` (nueva) | — | "Reintentar lectura" |
| `item.review_date` (nueva) | — | "Revisa la fecha" |
| `viewer.page_of`, `viewer.open_at_page` (nuevas) | — | "Página {n} de {total}" · "Ver en tu comprobante · pág. {n}" |
| `proof.pages` (nueva) | — | "{n} página" / "{n} páginas" (solo cuando `page_count` no es `null`); "PDF" y "Foto" si no hay número |
| `review.load_error` | "No pudimos cargar el lote: {error}" | "No pudimos cargar tu comprobante. Revisa tu conexión e inténtalo de nuevo." (sin `{error}`) |
| `review.complete_n` (nueva) | — | "Completar {count} fila" / "Completar {count} filas" |
| `review.submit_confirm_*` (nuevas) | — | Título: "¿Enviar a revisión?". Cuerpo: "Tu Campo Local revisará {resumen}. Mientras tanto no podrás editarlas." |
| `item.honor` | "HONOR" | "Especialidad" |
| `item.class` | "CLASE" | "Clase" |
| `item.ready` / `missing` / `rejected` | "LISTO" / "FALTA DATO" / "RECHAZADO" | "Lista" / "Falta {dato}" o "Faltan {n} datos" / "Rechazada" |
| `item.catalog_meta` | "Catálogo: {id} · {date}" | Se elimina |
| `item.read_as` (nueva) | — | "Leído: «{text}»" |
| `editor.honor` | "Honor" | "Especialidad" |
| `editor.catalog_id` | "ID catálogo" | Se elimina |
| `editor.name` | "Nombre detectado" | Bloque "Leído en tu comprobante". En filas manuales: "Nombre como aparece en tu comprobante (opcional)" |
| `editor.completed_at` / `date_hint` | "Fecha completada" / "AAAA-MM-DD" | "Fecha en que la completaste" (especialidad) / "Fecha de investidura" (clase). Sin pista de formato |
| `editor.date_*` (nuevas, D6) | — | "Elige la fecha" · "La fecha no puede ser anterior a 1960" · "La fecha no puede ser futura" · "Revisa la fecha. Lo que leímos no es una fecha válida" |
| `editor.instructor_*` (nuevas) | — | "Instructor o instructora", "Agregar instructor (opcional)", "Buscar por nombre", "Personas de tu Campo Local", "Escribe al menos 3 letras", "Usar «{name}» como nombre", "Para instructores de otro Campo Local o que no están en SACDIA", "Persona de tu Campo Local", "Nombre escrito · no verificado", "Tu Campo Local revisa este dato. No avisamos a la persona.", "Esta persona no está disponible. Elige a otra o escribe su nombre", "No puedes ser tu propio instructor", "No pudimos buscar. Revisa tu conexión" |
| `honors.evidence.instructor_*` (nuevas, D9 y D10) | — | Las mismas claves del campo de instructor, más "No pudimos guardar el instructor. Inténtalo de nuevo" y "Sin instructor registrado" (solo lectura en revisión). Mismo texto en es/en/pt-BR/fr, reusando las claves de `editor.instructor_*` del componente compartido |
| `honors.evidence.instructor_proposal_*` (nuevas, D11) | — | "Proponer instructor" · "Proponer otro instructor" · "Instructor en revisión" · "Tu Campo Local revisará esta propuesta. Mientras tanto se mantiene {instructor}." · "…se mantiene sin instructor." · "Cancelar propuesta" · "Tu Campo Local rechazó la propuesta" · "Motivo: {motivo}" · "¿Proponer a {nombre}?" · "Tu Campo Local revisará la propuesta. El resto de los datos de la especialidad no cambia." · "Proponer" · "¿Cancelar la propuesta?" · "Se mantiene {instructor}." · "Volver" · "Esa persona ya es tu instructor" · "No pudimos enviar la propuesta. Inténtalo de nuevo" · "No pudimos cancelar la propuesta. Inténtalo de nuevo" |
| `proof.more_files` y `viewer.change_file` (nuevas, D12) | — | "+{n} archivos" · "Cambiar de archivo" (solo si el lote tiene más de un archivo) |
| `editor.save` | "Guardar corrección" | "Guardar" / "Guardar y reenviar" (en corrección) |
| `proof.title` | "Registro importado" (en el visor) | "Tu comprobante". "Registro importado" queda solo para el historial |
| `proof.open` | "Abrir comprobante sellado" | Menú: "Abrir en otra app" |
| `status.in_review_body` (recién enviado) | "Tu Campo Local está revisando este envío." | Título: "Lo enviamos a tu Campo Local". Cuerpo: "Te avisaremos cuando revisen tus especialidades y clases." |
| `status.counts` | "Aprobadas: … · Rechazadas: … · Pendientes: …" | Chips "{n} aprobadas", "{n} rechazadas" y "{n} pendientes" (se ocultan los que están en 0) |

**Regla del español.** "Especialidad" y "Especialidades" siempre. "Honor" solo existe en `en.json`. Hay que revisar también `fr.json` y `pt-BR.json` con sus equivalentes ("Spécialité" y "Especialidade").

---

## 9. Accesibilidad (lista de verificación)

- **Objetivos táctiles.** Todos miden al menos 44×44 (`SacFilterChip.hitExtent`, `IconButton` y los botones `ghost` pequeños con `minHeight: 44`).
- **Semantics**
  - Filas: `Semantics(button: true, label: "Especialidad Natación Principiante I, lista, 12 de marzo de 2023, instructora Ana Gómez")`.
  - Insignias: se excluyen de la lectura separada para evitar duplicados.
- **Live regions.** Panel de espera, error del dock, página del visor y avisos M17.
- **Errores de campo.** Se anuncian con `SemanticsService.announce` y se asocian al campo mediante el `errorText` de `SacTextField` y `SacPickerField`.
- **Contraste.** `c.success` (#4FBF9F) y `c.warning` (#FBBD5E) **no** se usan como color de texto sobre `surface`. Las insignias usan las variantes del componente (`SacBadge.success` y `warning`), que pintan el texto con su tinta oscura. Los avisos de "Falta…" usan `AppColors.accentDark` (`onWarning`).
- **Color no es el único indicador.** Las insignias de estado llevan texto y la fila incompleta también muestra qué falta.
- **Texto grande.** Con escala de 2.0, las hojas hacen scroll (`isScrollControlled` + `SingleChildScrollView`), el dock pasa los botones a columna y las filas no truncan el nombre de la especialidad (máximo 2 líneas y luego elipsis con `Semantics` completo).
- **Reduced Motion.** Ver la sección 5. Cada fila de la tabla tiene su variante. Se prueba con `MediaQuery(disableAnimations: true)` en los tests de widgets, como ya hacen `*_motion_test.dart`.
- **Lector de pantalla en el visor.** Las flechas ‹ › son la alternativa al deslizamiento.
- **Teclado.** El buscador hace `autofocus`. `TextInputAction.search` cierra el teclado y no envía nada.

---

## 10. Riesgos y preguntas abiertas

### Preguntas abiertas: ninguna

Las cinco preguntas de la versión original (P1 a P5) quedaron resueltas por las decisiones D1 a D6 y D9. Los dos puntos de producto que había dejado la versión del 2026-10-10 también se cerraron el 2026-10-12:

- **Dónde se pide el instructor en "Mis especialidades"**: en `HonorEvidenceView`, antes de "Enviar a revisión" (D10, 6.4).
- **Especialidades ya aprobadas sin instructor**: el miembro puede proponerlo y el Campo Local lo aprueba o rechaza (D11, 6.5).

No hay preguntas pendientes sobre el diseño de pantallas ni sobre las dependencias.

### Riesgos

- **R1.** El reintento de `PDF_BUSY` sobre el mismo `confirm` requiere partir `uploadLocalProof` en etapas. Hasta entonces, cada reintento deja un lote borrador huérfano (H5).
- **R2.** Las URLs firmadas caducan mientras el visor está abierto o en caché. El diseño evita la caché persistente y vuelve a pedir la URL en "Reintentar".
- **R3.** El selector de especialidad depende de que `GET /honors` admita `search` en el servidor (B1). Si B1 no está desplegado, se filtra en el cliente con el *debounce* (el catálogo tiene cientos de especialidades y es manejable).
- **R4.** `showSacSheet` con Reduced Motion usa `AnimationStyle.noAnimation`, que es "cero" y no "menos". Los skills piden conservar el fundido. El ajuste vale para toda la app, así que se aplica con cuidado y fuera de este feature si el equipo lo prefiere.
- **R5.** Compartir o descargar el comprobante queda fuera de esta versión por privacidad. Si el usuario lo pide, se habilita con `allowShare: true`.
- **R6. Compatibilidad hacia atrás con el backend.** La app debe tolerar la ausencia de los campos nuevos mientras los slices B no estén desplegados: la **ausencia de la clave** `ocr_state` (backend sin B3) se trata como "sin dato": se conserva el sondeo fijo de 6 consultas y, si no hay filas, se muestra la variante `empty` del estado F. Distinto es el valor `null` explícito, que significa que nunca se pidió OCR para ese lote, `page_count`, `source_page` y `source_file_id` ausentes o `null` se tratan como "sin dato" (el visor abre el primer archivo en la página 1 y la tarjeta dice "PDF"). Así S1 a S4 pueden salir antes que B3 y B4.
- **R7. El buscador de instructores es un directorio del Campo Local** (D2, D9). Ya no está atado a un lote propio. Mitigaciones del backend: solo nombre y foto, mínimo de 3 letras, 10 resultados, límite de 30 por minuto. En la app: sin recientes en disco, sin caché de resultados entre sesiones y sin mostrar datos que la API no devuelve.
- **R8. Conteo parcial.** Los instructores de otros Campos Locales se cargan como nombre libre y no suman al conteo de ningún usuario (D2). Si el volumen es alto, el siguiente paso es ampliar el alcance a la unión (decisión del usuario "de momento").
- **R9. Un lote con varios archivos (resuelto por D12).** `source_page` es relativo a un archivo, y ahora la fila guarda cuál (`source_file_id`, documento hermano §2.2). La Carga de la app sigue subiendo un solo comprobante por lote, pero la API acepta hasta 10. El visor usa `resolveProofTarget` (4.8): abre el archivo de la fila y, si el dato falta o el archivo ya no está, el primero en la página 1. El riesgo residual es que una fila anterior a M2 o creada a mano abra el primer archivo aunque la información esté en otro; el menú "Cambiar de archivo" cubre ese caso.
- **R10. Reintento de lectura tras `failed`.** El job fallido conserva su identificador durante una hora y puede impedir que "Reintentar lectura" encole de nuevo. El backend lo corrige en B3. Hasta entonces, el botón no debe ofrecerse (el estado F `failed` muestra solo "Agregar especialidad o clase").
- **R11. Fecha mínima 1960.** Un certificado legítimo anterior a 1960 no se puede registrar (D6). La app lo explica en el error ("La fecha no puede ser anterior a 1960"); no hay excepción en v1.
- **R12. Propuesta de instructor sobre una especialidad aprobada (D11).**
  - *Compatibilidad*: la ausencia de la clave `instructor_proposal` (backend sin B9) oculta la acción "Proponer instructor"; `null` explícito significa "sin propuesta" y la muestra (misma lógica que R6).
  - *Sin aviso de la decisión*: la app no recibe una notificación cuando el Campo Local decide (en la línea de D8). El miembro ve el resultado al abrir la pantalla o al refrescar. Si resulta poco, el siguiente paso es una notificación al miembro, no al instructor.
  - *Carrera entre dispositivos*: si la propuesta se aprobó o se canceló desde otro lado, `HONOR_INSTRUCTOR_PROPOSAL_NOT_PENDING` o `…_NOT_APPROVED` invalidan la lista y la tarjeta se redibuja; no hay que mostrar el código.
  - *Ruido para el revisor*: una sola propuesta pendiente por especialidad (reemplazar cancela la anterior) y límite de tasa en el backend.
- **R13. Prerrequisitos de seguridad (D13).** S7 y S8 no deben salir hasta que SEC-1 y SEC-2 estén desplegados. Sin ellos, una especialidad aprobada o en revisión se puede reescribir con el alta (`POST /users/:userId/honors` y `/bulk`), y abandonar y volver a iniciar una especialidad aprobada la reinicia a "en curso" y borra su instructor. Eso invalidaría la garantía de 6.5 de que lo único que cambia en una aprobada es el instructor aprobado por el Campo Local. No cambia ninguna pantalla.

---

## 11. Plan de implementación por slices (sin código)

Cada slice se puede revisar por separado (menos de 400 líneas cuando sea posible) e incluye tests de widgets, con una variante en `disableAnimations: true` cuando hay motion. Los slices de la app son **S1 a S8**. Los de backend y admin son **B1 a B10** y los dos PRs de seguridad previos son **SEC-1** y **SEC-2**; todos están descritos en el documento hermano (`2026-10-09-certificate-import-instructor-data-model.md`, §7.3), que es la fuente del contenido de cada uno.

**Ningún slice de la app requiere migración.** Las migraciones son de backend y se aplican a mano por `psql` en Neon (dev → staging → prod) **antes** de desplegar el código que las usa: **B2** (M1, columnas de instructor), **B4** (M2, `page_count`, `source_page` y `source_file_id`), **B8** (M3, opcional) y **B9** (M4, tabla de propuestas de instructor). B1, B3, B5, B6, B7, B10, SEC-1 y SEC-2 no tocan la base. B5 usa las columnas de M1 y por eso exige que M1 esté aplicada en el entorno.

**Prerrequisitos de seguridad (D13).** SEC-1 (`fix/honors-create-mutability-guard`) y SEC-2 (`fix/honors-abandon-restart-guard`, apilado sobre SEC-1) se despliegan **antes** de B5 y B9, y por tanto antes de S7 y S8. No tienen migración ni cambian ninguna pantalla.

### Slices de la app

| Slice | Contenido | Depende de (app) | Depende de (backend/admin) | Cierra |
| --- | --- | --- | --- | --- |
| **S1. Errores y copy** | `CertificateImportErrorMapper`. `PDF_BUSY` en `pdfCodes`. Mapeo de red y de `OCR_*`. Se elimina `{error}` crudo. `ImportStatusCard` (C0 a C3). Copy de la sección 8 en los 4 idiomas (Especialidad en lugar de Honor, se quitan "ID catálogo", "% OCR" y "MiB"). Resumen sin "0 clases". Se retira la vista `processing`. Se usa `SacLoading` en las cargas | — | — | H3, H5 (mensaje), H7, H11, H12, H13 y feedback 3 |
| **S2. Subida reintentable y espera** | Subida por etapas que conserva `batchId` y `fileId`, y reintento de `confirm`. Se conecta `onProgress` con `SacTweenedBar`. `CancelToken`. `ImportSteps`. Seguimiento de `ocr_state` en la espera (sondeo cada 2 s, "Sigue leyendo" a los 8 s, tope de 60 s) y "Seguir sin esperar". Motion M3 a M8 | S1 | **B3** para `ocr_state` (sin B3 se conserva el sondeo fijo, R6). La subida por etapas no necesita backend nuevo | H5 (lote huérfano), H6 (parte de espera) y feedback 5 |
| **S3. Visor de comprobante** | Extensiones de `SacPdfViewer` (horizontal, paginado, flechas, `initialPage`) y de `SacImageViewer` (`allowShare`, `heroTag`, local). `CertificateProofViewer` con `fileId` e `initialPage`. `resolveProofTarget` (archivo y página de la fila, con respaldo al primer archivo en la página 1) y "Cambiar de archivo" si el lote tiene más de uno (D12). `CertificateProofSummaryCard` en la Revisión y en la Carga. Motion M20 a M23. La ruta `certificateImportProof` deja de usarse para "Ver comprobante" | S1 | **B4** para `page_count`, `source_page` y `source_file_id` (sin B4 abre el primer archivo en la página 1 y dice "PDF", R6) | H1, D12 y feedback 2 |
| **S4. Revisión** | Cabecera nueva, filtros `SacFilterChip`, agrupación, fila rediseñada (insignias "Falta…", "Leído: «…»", "Revisa la fecha" con umbral 0.8), estados F por `ocr_state` y G, dock con "Completar N" y "Enviar", confirmación de envío y su error, `SliverAnimatedList`. Motion M10 a M16 y M25 | S1, S3 | **B1** (la fila necesita `honor.name`, `category`, `class.name`; hoy la respuesta del miembro solo trae ids). **B3** (estados F exactos y actualización sola). **B4** (número de páginas) | H2 (en la cabecera), H6 (estado F), H9, H13 y feedback 1 |
| **S5. Editor y selectores** | `SacPickerField` (promovido), `DetectedTextQuote`, formularios de especialidad y de clase, selector de especialidad y categoría, `ClassPickerList`, aviso contextual de orden y avisos GM, selector de fecha con rango 1960 a hoy (`kMinCertificateDate`), errores dentro de la hoja, quitar con confirmación y descartar cambios, "Ver en tu comprobante · pág. N" (en el archivo de la fila). Motion M17 y M18 | S4 | **B1** (`GET /honors?search=`, `GET /certificate-bulk-imports/catalog/classes`, validación de fechas en el DTO). **B4** para abrir en el archivo y la página | H2 (contextual), H4, H8, H14, D5, D6 y feedback 1 y 4 (sin instructor) |
| **S6. Instructor en la carga por certificado, confirmación y correcciones** | `InstructorPicker`, `InstructorField`, `InstructorSelection` y `instructorCandidatesProvider` en `core/widgets/` (4.7c). El campo opcional en el formulario de especialidad. Confirmación I (M24). Estado J con chips. Corrección K a través del editor | S5 | **B1** (`GET /instructor-candidates?q=`). **B2** (campos `instructor_*` en la API del lote, con **M1 aplicada**) | H10, H15, D1, D2, D8 y feedback 4 (instructor) |
| **S7. Instructor en "Mis especialidades"** | Tarjeta "Instructor o instructora" en `HonorEvidenceView`, encima de "Enviar a revisión", con el componente de S6 (6.4, D10). `UserHonor.instructor`. `updateUserHonor` con `instructorUserId`/`instructorName`. Editable solo en `IN_PROGRESS` y `REJECTED`; de solo lectura en `PENDING_REVIEW`; en `APPROVED` se queda en solo lectura hasta S8. Claves de i18n compartidas | S6 | **B1**. **B5** (campos de instructor en `/users/:userId/honors` y validación de fechas, con **M1 aplicada**). **SEC-1 y SEC-2** desplegados (D13) | D9 y D10 |
| **S8. Proponer instructor en una especialidad aprobada** | `InstructorProposalCard` y sus cinco estados en `HonorEvidenceView` (6.5), `InstructorProposal` en `UserHonor`, `instructorProposalActionsNotifier` (proponer con confirmación, cancelar), errores de la propuesta, ocultar la acción si falta la clave `instructor_proposal` (R12), claves de i18n `honors.evidence.instructor_proposal_*` en los 4 idiomas, motion M26 | S7 | **B9** (endpoints de propuesta y bloque `instructor_proposal`, con **M4 aplicada**). **B10** (admin) para que haya quien resuelva las propuestas. **SEC-1 y SEC-2** desplegados (D13) | D11 |

### Orden global (backend, app y admin)

```
Backend/Admin             App
────────────────          ─────────────────────────────────────────────
SEC-1 → SEC-2 (sin migr.; prerrequisito de B5 y B9)
                          S1 (sin dependencias)
B1  (sin migr.)       ──► S2 (subida) ∥ S3 (visor)      ← S2 y S3 pueden salir antes que B3/B4 (R6)
B3  (sin migr.)       ──► S2 ya lee ocr_state · S4 estados F
B2  (MIGR. M1)        ──► S4 (revisión; nombres de B1) → S5 (editor; B1) → S6 (instructor; B1 + B2)
B4  (MIGR. M2)        ──► S3/S4/S5 abren en el archivo y la página de la fila
B5  (usa M1; SEC-1/2) ──► S7 (Mis especialidades; B1 + B5)
B9  (MIGR. M4; B5)    ──► S8 (proponer instructor en aprobadas)
B6 admin (B2 + B4)     B7 admin (B5)     B10 admin (B9)     B8 OCR instructor (opcional, MIGR. M3)
```

Orden sugerido, de punta a punta:

1. **SEC-1 y SEC-2**, en ese orden (SEC-2 apila sobre SEC-1). Son PRs chicos y no bloquean S1 a S6; solo bloquean B5 y B9.
2. **S1**, en paralelo con **B1** y **B3** (ninguno tiene migración ni depende de otro).
3. **S2 y S3** en paralelo (si B3 y B4 aún no están, funcionan con el respaldo de R6).
4. **B2 + aplicar M1** en Neon dev → staging → prod, y **B4 + aplicar M2** (migraciones independientes).
5. **S4 → S5**. S5 necesita B1 ya desplegado; S4 también para los nombres de las filas.
6. **S6**, cuando B1 y B2 (con M1 aplicada) estén desplegados.
7. **B5** (usa M1; requiere SEC-1 y SEC-2), y después **S7**.
8. **B9 + aplicar M4** (requiere B5 y SEC-1/SEC-2), junto con **B10** (admin), y después **S8**. S8 no se publica sin B10: una propuesta que nadie puede resolver es un callejón sin salida.
9. **B6** (admin, carga por certificado) cuando B2 y B4 estén desplegados; **B7** (admin, revisión de evidencias) cuando B5 lo esté.
10. **B8** (opcional) al final.

S1 a S3 no esperan al backend. S4 a S8 sí: cada uno declara arriba qué B y qué migración necesita.
