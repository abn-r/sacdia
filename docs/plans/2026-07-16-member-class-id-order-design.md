# Orden de grupos de miembros por ID de clase

**Fecha:** 2026-07-16
**Estado:** Aprobado

## Objetivo

Ordenar los grupos de miembros por el identificador numérico de su clase
progresiva, no por un mapa manual de nombres.

## Alcance

- Usar `ClubMember.currentClassId`, que proviene de la proyección
  `current_class.class_id` del endpoint de miembros.
- Mantener las etiquetas, conteos, logos y tarjetas actuales.
- Mantener el grupo `Sin clase` al final.
- Ubicar una clase con nombre pero sin ID después de las clases con ID válido y
  antes de `Sin clase`.

## Decisión de diseño

Se extraerá una función pura que reciba la lista filtrada de miembros y la
etiqueta de `Sin clase`. La función agrupará por el nombre visible actual,
asociará cada grupo de clase a su `currentClassId` y devolverá el mapa en orden
ascendente de ID.

El provider `membersByClassProvider` seguirá siendo responsable de observar
los filtros y de resolver la traducción de `Sin clase`; delegará únicamente la
transformación y orden a la función pura. Se eliminará `_classOrder`, ya que
su tabla manual no incluye todos los catálogos y no es la fuente de verdad.

## Casos límite

- Si varios miembros pertenecen a la misma clase, comparten el mismo grupo y
  su ID de clase.
- Si un nombre de clase llega sin ID, el grupo conserva una posición estable
  posterior a todos los IDs válidos.
- Los miembros sin `currentClass` se agrupan en `Sin clase`, siempre al final.

## Pruebas

Se agregará una prueba unitaria de la función de agrupación con miembros en
orden de entrada arbitrario, IDs no secuenciales, una clase sin ID y un miembro
sin clase. La expectativa verificará el orden numérico ascendente y que cada
miembro permanezca en su grupo.

## Fuera de alcance

- Cambiar IDs, nombres o catálogo de clases en backend.
- Alterar el orden interno de miembros dentro de un mismo grupo.
- Modificar filtros, tarjetas, encabezados o assets.
