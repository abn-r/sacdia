# Camporee event honors (especialidades de preparación)

**Fecha**: 2026-08-28
**Estado**: APROBADO
**Alcance**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`
**Dominio**: [camporee-events.md](../../features/camporee-events.md) + [honores.md](../../features/honores.md)

## 1. Objetivo

Un evento de camporee puede listar una o más especialidades del catálogo `honors` como material de preparación. El panel las asigna. La app las muestra en lectura y abre el PDF (`material_url`) con `SacPdfViewer`. No inscribe al miembro. No bloquea inscripción ni puntaje.

Ejemplo: evento “Amarres” → especialidad “Nudos”.

## 2. Decisiones

1. Consulta + PDF. Sin `users_honors`. Sin gate.
2. Varias especialidades por evento (máx. 20).
3. Solo en la instancia `camporee_events`. Templates no llevan honores. Clonar desde template no copia honores.
4. Mutación vía `honor_ids[]` en `POST`/`PATCH` del evento. Sin endpoint extra.
5. Copy visible: **Especialidades de preparación**. Contratos internos usan `honor`.
6. Reusar `honors.material_url` público. No firmar URLs nuevas.

## 3. Datos

Tabla `camporee_event_honors`:

| Columna | Tipo | Notas |
| --- | --- | --- |
| `camporee_event_honor_id` | `INT PK` identity | |
| `camporee_event_id` | `INT FK camporee_events ON DELETE CASCADE` | |
| `honor_id` | `INT FK honors ON DELETE RESTRICT` | catálogo; no borrar honor si hay vínculos |
| `display_order` | `INT NOT NULL DEFAULT 0` | orden del array enviado |
| `created_at` | `TIMESTAMPTZ` | |

Constraints:

```
@@unique([camporee_event_id, honor_id])
@@index([honor_id])
@@index([camporee_event_id, display_order])
```

Replace completo: borrar filas del evento y recrear en el orden de `honor_ids`.

## 4. API

Campo opcional `honor_ids: number[]` en `CreateCamporeeEventDto` y `UpdateCamporeeEventDto`.

- `POST`: omitir = ninguna; `[]` = ninguna; `[1,2]` = esas, en ese orden.
- `PATCH`: omitir = no tocar; `[]` = vaciar; lista = reemplazar.
- Duplicados → `400 CAMPOREE_EVENT_HONOR_DUPLICATE`.
- Más de 20 → `400 CAMPOREE_EVENT_HONOR_LIMIT`.
- Id inexistente o `active=false` → `400 CAMPOREE_EVENT_HONOR_NOT_FOUND` con `honor_ids` faltantes.
- Permisos: los mismos del evento (`camporee_events:create|update|read`).

Respuesta de list/get/preview (siempre, también antes de `agenda_visible_from`):

```json
"honors": [
  {
    "honor_id": 42,
    "name": "Nudos",
    "honor_image": "https://…",
    "material_url": "https://…/nudos.pdf",
    "honors_category_id": 3,
    "category_name": "Actividades recreativas",
    "skill_level": 1,
    "active": true,
    "display_order": 0
  }
]
```

Lectura: incluir honores vinculados aunque el catálogo se haya desactivado después (el admin los quita). Escritura: solo honores activos.

`POST .../from-template` no acepta `honor_ids` en esta fase.

## 5. Admin

Formulario de evento (`EventFormPage`, local y unión):

- Sección **Especialidades de preparación**.
- Selector múltiple con búsqueda sobre el catálogo admin.
- Chips con imagen + nombre; quitar; orden = orden de selección (se puede quitar y volver a agregar).
- Hidden `honor_ids` JSON enviado en create/update agenda.
- Vacío es válido.

Lista timeline: opcional badge con conteo. El drawer mock de timeline no se cablea.

## 6. App

Detalle de evento (`_CamporeeEventDetailPage`):

- Bloque después de descripción, antes de personal.
- Tarjeta por especialidad: imagen, nombre, categoría.
- Si hay `material_url`: CTA “Ver material” → `SacPdfViewer.show`.
- Si no hay PDF: la tarjeta se muestra sin CTA.
- No navega al flujo de cursar (`honor_detail_view` de inscripción).

i18n: `es`, `en`, `pt-BR`, `fr`.

## 7. Fuera de alcance

- Templates y clonado de honores.
- Gate por `users_honors.validation_status = APPROVED`.
- Inscribir o cambiar `completion_mode` desde el evento.
- Relación `REQUIRED`/`RECOMMENDED` (todo es preparación consultiva).
- Firmado nuevo de PDFs.

## 8. Criterios de aceptación

- Admin puede asignar 0..N especialidades activas a un evento de camporee local o de unión.
- GET/preview devuelven `honors[]` con `material_url`.
- App abre el PDF en visor de solo lectura.
- PATCH sin `honor_ids` no borra la lista.
- Honor inactivo no se puede agregar; uno ya vinculado sigue visible hasta quitarlo.
- Tests backend cubren replace, omit, duplicado, límite, honor inactivo y preview sin enmascarar honores.
