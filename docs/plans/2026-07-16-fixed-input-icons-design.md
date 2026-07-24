# Iconos fijos en campos de SACDIA App

**Fecha:** 2026-07-16  
**Estado:** Aprobado

## Objetivo

Evitar que los iconos de entrada ocupen el espacio disponible de un campo y
mantener un punto visual y táctil constante en todos los buscadores de la app
móvil y en los demás campos que usan el mismo mecanismo.

## Evidencia y patrón de referencia

`EvidenceSectionSearchField` ya fija el slot del icono de prefijo a **48 × 48
dp** y el glifo a **20 × 20 dp**. Su widget test comprueba ambas dimensiones.

En contraste, muchos `InputDecoration.prefixIcon` se construyen directamente
sin `prefixIconConstraints`. Aunque el glifo declare un tamaño, el slot que lo
aloja puede variar con las restricciones del campo y producir una composición
inconsistente.

## Decisión

Crear un widget reutilizable para un icono HugeIcons centrado dentro de un slot
de 48 × 48 dp, y reutilizar las mismas constraints en las decoraciones de
entrada. El tamaño del glifo se conserva por pantalla cuando sea intencional;
los buscadores usarán 20 dp salvo los casos que ya usan un tamaño menor por su
densidad visual.

La corrección se aplicará a:

- los componentes base `SacTextField`, `SacDropdownField`, `CustomTextField`
  y `AuthTextField`;
- todos los buscadores que construyen `InputDecoration` directamente;
- los demás campos directos con iconos de prefijo que presentan el mismo riesgo.

Los iconos de estados vacíos, botones de acción y filas que ya tienen tamaño
explícito no se modificarán: no son slots de entrada y su tamaño comunica una
jerarquía visual distinta.

## Accesibilidad

- El área reservada del prefijo será siempre de 48 × 48 dp.
- La acción de limpiar conservará o adoptará objetivos táctiles de al menos 48
  dp.
- La solución no dependerá únicamente del color para comunicar acciones.

## Pruebas

Se escribirá primero un widget test para el componente reutilizable: debe
verificar el glifo de 20 × 20 dp y las constraints del slot de 48 × 48 dp.
Después se ejecutarán los tests del componente y el test existente de
`EvidenceSectionSearchField`, sin ejecutar builds.

## Fuera de alcance

- Cambios de backend, contratos, datos o navegación.
- Rediseño de campos que no tienen iconos de entrada.
- Alterar los iconos grandes de estados vacíos o ilustraciones intencionales.
