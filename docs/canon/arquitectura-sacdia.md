# Arquitectura del sistema

## Estado

ACTIVE
<!-- VERIFICADO contra código 2026-03-14: las cinco capas descritas (dominio, backend, admin web, app móvil, datos) están materializadas en el código. Las responsabilidades por módulo son consistentes con la implementación. No se detectó drift estructural en claims arquitectónicos. -->

## Propósito

Este documento describe cómo SACDIA materializa su dominio en componentes técnicos con responsabilidades diferenciadas. Su función es traducir el modelo del dominio a una organización técnica coherente para backend, panel administrativo, app móvil, datos e integraciones.

Este documento no redefine conceptos del negocio. La semántica del sistema sigue mandando desde `docs/canon/dominio-sacdia.md`.

## Criterio rector

La arquitectura de SACDIA debe seguir al dominio. Los módulos técnicos existen para sostener trayectoria, secciones, vinculaciones, periodos operativos, procesos formativos, validaciones y autoridad institucional.

## Vista general

SACDIA se entiende como un sistema compuesto por cinco capas principales:

- dominio: lenguaje, reglas y semántica institucional;
- backend: lógica de negocio, seguridad, autorización y contratos operativos;
- admin web: operación administrativa, supervisión y gestión institucional;
- app móvil: interacción contextual y operación situada;
- datos: persistencia, integridad y trazabilidad histórica.

Estas capas cooperan para sostener la trayectoria institucional de miembros y clubes. Ninguna debe redefinir por su cuenta el significado del sistema.

## Responsabilidades por módulo

### Dominio

El dominio fija el lenguaje del sistema, sus relaciones conceptuales y sus reglas de interpretación. Define qué debe preservarse como trayectoria, qué requiere validación y cómo se entiende la operación por secciones.

### Backend

El backend concentra la lógica operativa del sistema. Implementa reglas del dominio, coordina procesos, aplica seguridad, resuelve autorización contextual y expone contratos para los clientes.

El backend actúa como punto principal de orquestación. Debe proteger integridad de trayectoria, consistencia de vinculaciones, cargos, periodos, procesos y validaciones.

### Admin web

El admin web soporta gestión, supervisión, revisión y consulta institucional. Está orientado a operación estructurada, control, visibilidad y capacidad administrativa sobre clubes, secciones, vinculaciones, cargos, procesos y reportes.

### App móvil

La app móvil acerca el sistema a la operación cotidiana y a la consulta contextual. Está orientada a interacción situada, accesibilidad operativa y continuidad de uso para actores que no necesitan toda la profundidad administrativa del panel.

### Datos

La capa de datos conserva memoria estructural, integridad relacional y trazabilidad histórica. Su función es representar el dominio y soportar la operación del backend, no redefinir conceptos del negocio.

## Límites de responsabilidad

- el dominio manda en significado;
- el backend manda en aplicación de reglas y contratos operativos;
- el admin web y la app móvil representan y operan sobre el sistema, pero no crean semántica nueva;
- la capa de datos persiste e integra, pero no impone lenguaje conceptual;
- las integraciones externas deben adaptarse al sistema, no rediseñar su núcleo semántico.

## Puntos de verdad

La verdad del sistema se distribuye así:

- la verdad conceptual vive en `docs/canon/dominio-sacdia.md`;
- la verdad de propósito y frontera vive en `docs/canon/identidad-sacdia.md`;
- la verdad documental y de precedencia vive en `docs/canon/gobernanza-canon.md`;
- la verdad operativa de negocio se ejecuta principalmente en backend;
- la verdad de interacción se representa en admin web y app móvil;
- la verdad histórica y estructural persiste en datos.

## Relaciones entre módulos

- admin web y app móvil dependen del backend para reglas, seguridad y contratos;
- el backend depende de datos para persistencia e integridad;
- datos soporta al backend, pero no define por sí solo el dominio;
- documentación canónica condiciona cómo se entienden las piezas anteriores;
- decisiones arquitectónicas deben mantenerse alineadas con dominio, identidad y gobernanza.

## Capacidades que la arquitectura debe sostener

La arquitectura de SACDIA debe sostener, como mínimo:

- continuidad de trayectoria;
- operación por secciones;
- gestión de vinculaciones y cargos;
- periodización institucional de la operación;
- procesos formativos estructurados;
- validaciones con autoridad contextual;
- trazabilidad histórica e institucional.

Si una pieza técnica no contribuye a sostener alguna de estas capacidades, no pertenece al corazón de la arquitectura.

## Tensiones arquitectónicas

La arquitectura debe manejar de manera explícita estas tensiones:

- simplificación de interfaz versus precisión semántica;
- flexibilidad operativa versus integridad institucional;
- historial completo versus vistas del estado actual;
- centralización de reglas en backend versus necesidades de experiencia en cliente;
- consolidación a nivel club versus origen operativo en sección.

Estas tensiones no se resuelven negándolas, sino aclarando dónde vive cada responsabilidad.

## Proyección sobre la solución actual

En el estado actual del workspace, SACDIA se expresa en:

- `sacdia-backend/` como backend principal de reglas y contratos;
- `sacdia-admin/` como panel administrativo web;
- `sacdia-app/` como app móvil;
- `docs/` como capa documental canónica y operativa;
- base de datos relacional como soporte de persistencia y trazabilidad.

> Los conteos concretos de módulos, endpoints, pantallas o modelos no viven en este documento canónico. Para métricas actualizadas consultar `docs/audit/REALITY-MATRIX.md` y `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Canon describe organización técnica, no tamaño.

La estructura concreta de carpetas o repositorios debe leerse como implementación de esta arquitectura, no como la arquitectura misma.

## Reglas de alineación

- ningún módulo técnico debe introducir vocabulario contradictorio con el dominio;
- toda simplificación de interfaz debe preservar trazabilidad al concepto canónico;
- la autorización técnica debe reflejar contexto, jerarquía y proceso, no solo rol plano;
- los datos históricos no pueden sacrificarse por conveniencia de vistas actuales;
- las decisiones de arquitectura deben justificarse por valor institucional y coherencia del sistema.

## Cierre

La arquitectura de SACDIA existe para convertir un dominio institucional complejo en un sistema operativo coherente. Su función no es exhibir stack ni estructura de carpetas, sino sostener con claridad técnica la trayectoria institucional de miembros y clubes a través de secciones, periodos, procesos, validaciones y niveles de autoridad.
