# Pestañas y tarjetas compactas de Miembros

**Fecha:** 2026-07-17
**Estado:** Aprobado

## Objetivo

Reducir la altura del selector `Miembros` / `Solicitudes` y de las tarjetas
individuales del listado de miembros, sin alterar su ancho ni comportamiento.

## Alcance

- Reducir el control de pestañas a 44 dp de alto: pestañas de 40 dp y relleno
  interno de 2 dp.
- Reducir 4 dp la altura de cada `MemberCard`: conservar 14 dp de relleno
  horizontal y cambiar únicamente el relleno vertical de 14 a 12 dp.
- Mantener el avatar de 48 dp, textos, badge de inscripción, acciones, badge
  de solicitudes, navegación y accesibilidad existentes.

## Decisión de diseño

La barra de pestañas conservará sus dos áreas de toque completas dentro de un
contenedor de 44 dp. Los labels y el indicador activo no cambian; solo se
ajustan la altura de cada `Tab` y el padding del `TabBar`.

`MemberCard` conservará su estructura y ancho. El avatar sigue siendo el
elemento que determina la altura mínima; reducir el padding vertical mantiene
la legibilidad, evita recortar controles y acorta la tarjeta en 4 dp.

## Pruebas

- Widget test de `MembersView` para verificar pestañas de 40 dp y padding de
  2 dp.
- Extensión del widget test de `MemberCard` para comprobar 74 dp de alto
  incluyendo el borde, usando una tarjeta con avatar fallback.

## Fuera de alcance

- Cambiar el ancho del selector de pestañas.
- Modificar fuentes, colores, radios, textos, avatar o datos.
- Ajustar alturas de otras tarjetas o pantallas.
