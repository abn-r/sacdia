# Logos de clases en tarjetas de miembros

**Fecha:** 2026-07-16
**Estado:** Aprobado

## Objetivo

Mostrar el logo local de la clase progresiva en cada tarjeta de miembro, a la
izquierda del nombre de la clase.

## Alcance

- Reutilizar `AppColors.classLogoAsset`, fuente de verdad de los 15 logos de
  Aventureros, Conquistadores y Guías Mayores.
- Reemplazar el ícono genérico de escuela en `MemberCard` por un logo
  decorativo de 18 dp cuando exista un asset mapeado.
- Mantener el nombre de la clase, el estado de inscripción, el avatar, el
  cargo y las acciones actuales.
- Conservar oculta la fila de clase cuando el miembro no tenga clase.
- Mantener el ícono genérico como fallback si llega una clase no mapeada.

## Decisión de diseño

`MemberCard` resolverá el asset desde el valor existente de
`member.currentClass`. No cambia entidades, providers, backend ni la
agrupación de la lista. El logo sustituye el ícono de escuela, para no
duplicar información ni aumentar el ancho visual de la tarjeta.

## Accesibilidad y rendimiento

- El logo será decorativo; el nombre de clase seguirá siendo el texto
  accesible que identifica la información.
- Se usará `Image.asset` con un tamaño fijo de 18 × 18 dp, alineado con la
  jerarquía visual de la línea de clase.

## Pruebas

Se agregará un widget test para verificar que una tarjeta con `Amigo` muestra
`CQ-01.png` y que una clase sin asset conserva el fallback. La ausencia de
clase debe mantener la fila oculta.

## Fuera de alcance

- Crear o editar assets.
- Alterar los datos de clase, el orden de miembros o sus filtros.
- Cambiar la estructura o estilos no relacionados de la tarjeta.
