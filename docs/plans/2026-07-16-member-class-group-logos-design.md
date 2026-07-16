# Logos de clases en grupos de miembros

**Fecha:** 2026-07-16  
**Estado:** Aprobado

## Objetivo

Mostrar el logo local de la clase a la izquierda de cada encabezado que agrupa
miembros por clase progresiva en la aplicación móvil.

## Alcance

- Reutilizar `AppColors.classLogoAsset`, que ya resuelve los 15 logos de
  Aventureros, Conquistadores y Guías Mayores.
- Mostrar un logo de 24 dp antes del nombre de la clase.
- Mantener el texto del encabezado y la insignia de conteo actuales.
- Mantener el grupo `Sin clase` sin logo.

## Decisión de diseño

Se creará un widget de presentación específico para el encabezado de grupo de
miembros. Recibirá el nombre y el conteo; resolverá el asset mediante
`AppColors.classLogoAsset` y renderizará `Image.asset` únicamente cuando exista
un mapeo.

No se cambia el provider que agrupa miembros ni se agregan datos al backend: el
nombre de clase que ya llega en cada miembro es suficiente para resolver el
logo local.

## Accesibilidad y rendimiento

- El logo será decorativo porque el texto del encabezado comunica la misma
  clase.
- Los assets se cargarán con `cacheWidth` y `cacheHeight` de 72 px para un
  tamaño visual de 24 dp en pantallas de densidad 3×.

## Pruebas

Se agregará un widget test que compruebe que una clase mapeada renderiza su
asset y que `Sin clase` no agrega una imagen.

## Fuera de alcance

- Cambiar el orden actual de grupos.
- Crear logos nuevos o modificar assets existentes.
- Cambiar las tarjetas individuales de miembros.
