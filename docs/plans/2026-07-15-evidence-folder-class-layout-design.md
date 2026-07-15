# Rediseño de Carpeta Anual de Evidencias

**Fecha:** 2026-07-15  
**Estado:** Aprobado

## Objetivo

Rediseñar la pantalla móvil de Carpeta Anual de Evidencias para que use la misma jerarquía visual que el detalle de progreso de Clase, sin cambiar contratos, estados ni reglas del dominio `annual-folders`.

## Alcance

- Mantener el app bar, navegación, refresh, estados de carga/error/sin carpeta y banners operativos actuales.
- Reemplazar el resumen actual por un hero de avance equivalente al de Clase.
- Mostrar los estados de las secciones en pills horizontales.
- Incorporar búsqueda local por nombre y descripción.
- Agrupar las secciones en una lista compacta con jerarquía equivalente a módulos y requisitos.
- Conservar carga, navegación, envío a validación y trazabilidad.
- No modificar backend, DTOs, entidades de dominio ni endpoints.

## Decisión de diseño

La pantalla de Evidencias tendrá componentes propios construidos con los mismos tokens y patrones visuales de Clase. No se extraerán los widgets privados de `ClassDetailWithProgressView`, porque ambos dominios tienen estados, acciones y densidad de información diferentes.

Esto evita dos problemas:

1. Acoplar Evidencias a decisiones internas de Classes.
2. Copiar widgets completos y permitir que ambas pantallas diverjan silenciosamente.

La consistencia se obtiene mediante composición, jerarquía, espaciado, tipografía y colores semánticos compartidos.

## Estructura visual

### App bar y banners

El app bar conserva el título `Carpeta Anual de Evidencias` y el botón de regreso. Los banners de carpeta cerrada o en evaluación permanecen visibles y mantienen sus reglas actuales.

### Hero de avance

El hero usa una superficie blanca con borde semántico suave y contiene:

- eyebrow con el nombre de la carpeta y la palabra `AVANCE`;
- porcentaje global grande, calculado con `completionRatio`;
- relación de puntos obtenidos y máximos;
- aro de progreso con icono de carpeta;
- estado operativo de la carpeta como texto y color semántico.

El porcentaje y los puntos continúan usando los valores server-authoritative disponibles en `EvidenceFolder`.

### Pills de estado

Una fila horizontal desplazable mostrará conteos para:

- validadas;
- preaprobadas;
- enviadas;
- rechazadas;
- pendientes.

`PREAPPROVED_LF` se mantiene separado de `SUBMITTED` para no perder información del flujo institucional.

### Búsqueda

El buscador filtra localmente por nombre y descripción de sección. Debe incluir:

- indicador visual de foco;
- acción de limpiar con objetivo táctil mínimo;
- estado vacío específico cuando no hay coincidencias;
- restauración inmediata de la lista al limpiar la consulta.

### Lista compacta de secciones

La lista se presenta bajo el label `SECCIONES DE EVIDENCIA` dentro de una tarjeta agrupada. Cada fila contiene:

- indicador circular de avance o estado;
- nombre y descripción;
- estado textual y semántico;
- puntos obtenidos/máximos;
- archivos cargados/máximos;
- chevron de navegación;
- trazabilidad resumida cuando exista;
- acción de envío cuando `folder.isOpen && section.canSubmit`.

La fila completa continúa abriendo `EvidenceSectionDetailView`. La acción de envío debe evitar propagar el toque hacia la navegación.

## Datos y comportamiento

No se agrega estado remoto nuevo. La búsqueda se administra localmente en `_FolderBodyState`; los conteos se derivan de `folder.sections`. El backend sigue siendo la única fuente de verdad para estados y puntajes.

La clasificación usa exactamente `EvidenceSectionStatus`:

- `pending`
- `submitted`
- `preapprovedLf`
- `validated`
- `rejected`

## Accesibilidad

- Objetivos táctiles mínimos de 48 dp.
- Etiquetas semánticas para porcentaje, estado, puntos y acciones.
- Estados comunicados mediante texto e iconos, no solo color.
- Compatibilidad con escalado de texto sin cortar información crítica.
- Contraste equivalente o superior a WCAG 2.2 AA.

## Pruebas

Se agregarán widget tests que verifiquen:

- renderizado del hero con porcentaje y puntos;
- conteos de todos los estados;
- filtrado por nombre y descripción;
- estado sin resultados y limpieza de búsqueda;
- navegación al detalle al tocar una sección;
- disponibilidad y ejecución de la acción de envío;
- representación de carpeta cerrada o en evaluación.

## Fuera de alcance

- Cambios a `EvidenceSectionDetailView`.
- Nuevos endpoints o campos de respuesta.
- Modificaciones a reglas de permisos o evaluación.
- Rediseño de otras superficies de evidencias.
