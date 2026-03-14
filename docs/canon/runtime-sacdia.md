# Runtime vigente

## Estado

DRAFT

## Propósito

Este documento describe la verdad operativa actual de SACDIA en su estado implementado y verificable. Su función es separar con claridad lo que hoy existe en runtime de lo que sigue siendo aspiración, transición o material histórico.

Este documento no redefine el dominio ni la identidad del sistema. Su lectura siempre está subordinada a `docs/canon/dominio-sacdia.md`, `docs/canon/identidad-sacdia.md` y `docs/canon/gobernanza-canon.md`.

## Naturaleza del documento

El runtime vigente registra comportamiento operativo, contratos activos, restricciones observables y límites actuales del sistema. No es una bitácora de cambios ni un roadmap. Tampoco debe presentar como vigente aquello que no haya sido verificado contra runtime, código o contratos activos confiables.

## Estado de madurez de este documento

Este documento nace en estado `DRAFT` porque todavía requiere una verificación sistemática contra los módulos runtime del workspace. Su contenido actual fija el marco de lectura y consolida solo verdades operativas ya respaldadas por documentación activa consultada durante esta etapa.

## Principio rector

Solo debe describirse como vigente aquello que el sistema realmente sostiene en runtime o que pueda respaldarse de forma confiable con contratos activos. Toda capacidad parcial, en transición o pendiente debe marcarse explícitamente como tal.

## Componentes activos del sistema

En el estado actual del workspace, SACDIA opera mediante estos componentes principales:

- `sacdia-backend/` como backend principal de reglas y contratos;
- `sacdia-admin/` como panel administrativo web;
- `sacdia-app/` como app móvil;
- base de datos relacional documentada en `docs/03-DATABASE/`;
- documentación operativa y contractual en `docs/02-API/` y `docs/03-DATABASE/`.

## Hechos operativos ya respaldados

### Jerarquía organizacional modelada

La estructura organizacional actual del sistema incluye país, unión, campo local, distrito, iglesia y club. Esta cadena está respaldada por `docs/03-DATABASE/SCHEMA-REFERENCE.md` y por permisos geográficos documentados en `docs/01-FEATURES/auth/PERMISSIONS-SYSTEM.md`.

### Clubes con unidades operativas por tipo

El runtime actual representa la operación por tipo de club mediante `instances` y tablas separadas por tipo. Esta realidad está respaldada por `docs/03-DATABASE/SCHEMA-REFERENCE.md`, `docs/03-DATABASE/schema.prisma` y endpoints activos bajo `/api/v1/clubs/:clubId/instances` documentados en `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`.

En el estado actual del sistema, `instance` no es solo naming interno de persistencia; también funciona como naming contractual público en backend y clientes. En el canon, ese concepto se interpreta como `Sección de club`.

### Año eclesiástico como soporte temporal operativo

El runtime actual usa `ecclesiastical_year_id` en estructuras clave como asignaciones de rol de club. Esto respalda que la operación temporal del sistema ya se apoya en una periodización institucional explícita.

### Auth y permisos granulares activos

La documentación operativa actual respalda autenticación JWT, permisos granulares y superficies de autorización por contexto. La existencia de este sistema está respaldada tanto por documentación activa como por implementación backend verificada.

La alineación total de todos los clientes con el contrato canónico y con los contratos backend vigentes sigue siendo parcial y requiere verificación adicional.

### Operación sobre clubes e instancias

El runtime documentado expone capacidades activas para consultar clubes, obtener instancias, crear instancias, actualizar instancias, listar miembros por instancia y asignar roles en instancias. Estas superficies están documentadas en `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`.

### Procesos formativos activos

El sistema actual documenta clases progresivas, progreso por secciones y actualización de avance por usuario en rutas activas. La semántica final de estas rutas sigue subordinada al dominio, pero su existencia operativa está respaldada por `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`, `docs/03-DATABASE/SCHEMA-REFERENCE.md` y verificación de código backend.

La existencia de endpoints y tablas está verificada. Las reglas completas de elegibilidad, validación y bloqueo todavía requieren verificación adicional en código para declararse como verdad runtime cerrada.

### Fuente de verdad formativa actual

El estado formativo del sistema hoy no vive en una sola estructura. Existen dos niveles con semántica distinta:

- `enrollments` representa cada cursado anual de una clase dentro de un año eclesiástico y debe leerse como fuente primaria del ciclo operativo anual;
- `users_classes` representa la trayectoria consolidada por clase del miembro a lo largo del tiempo y debe leerse como proyección histórica consolidada.

En el estado actual del runtime, esta frontera todavía no está ejecutada de forma consistente. Post-registro y lectura administrativa siguen usando `users_classes`, mientras el módulo de clases y parte de la lógica de certificaciones usan `enrollments`.

## Capas de lectura del runtime

El runtime de SACDIA debe leerse por capas:

- acceso y autenticación;
- autorización y alcance institucional;
- operación sobre clubes, secciones y miembros;
- procesos formativos y validaciones;
- persistencia y trazabilidad;
- exposición de contratos para clientes e integraciones.

## Categorías de estado runtime

Toda capacidad descrita en este documento debe ubicarse en una de estas categorías:

- `vigente`: verificada y operativa;
- `parcial`: existente, pero con límites relevantes;
- `en transición`: convive con naming, contrato o comportamiento legacy;
- `pendiente`: definida como intención, pero no asumible como activa.

## Reglas documentales del runtime

- no usar lenguaje aspiracional como si fuera vigente;
- no inferir soporte actual desde documentos históricos;
- no dejar que naming técnico redefina el dominio;
- no ocultar limitaciones o deuda operativa relevante;
- no presentar como verificado lo que todavía no fue contrastado con código o contratos activos confiables.

## Mapeo mínimo con el canon

- `Miembro` aparece hoy principalmente como `user` en runtime;
- `Sección de club` aparece hoy como `instance` y tablas separadas por tipo; ese naming no es solo interno, también existe en rutas, payloads y modelos cliente;
- `Periodo operativo` se expresa hoy principalmente mediante `ecclesiastical_year_id`;
- `enrollments` representa hoy el ciclo anual operativo de clases, aunque su semántica de validación sigue parcialmente implementada;
- `users_classes` representa hoy la trayectoria consolidada por clase, aunque todavía se usa en algunos flujos como si fuera fuente operativa primaria;
- parte de la relación entre participación y responsabilidad aparece hoy en `club_role_assignments`.

Estas representaciones técnicas describen el estado actual del runtime, pero no sustituyen el lenguaje canónico del sistema.

## Pendientes para completar este documento

Antes de declararlo `ACTIVE`, este documento debe verificarse contra:

- controladores y guards del backend;
- contratos efectivamente consumidos por admin y app;
- modelado real de autorización contextual;
- puntos donde runtime, documentación activa y dominio todavía no estén alineados en naming o semántica.
- diferencias reales entre contratos backend y consumo actual en `sacdia-admin/` y `sacdia-app/`.
- alineación definitiva entre `users_classes` y `enrollments` para que la frontera entre trayectoria consolidada y ciclo anual operativo deje de estar solo declarada y pase a ser consistente en runtime.

## Cierre

El runtime vigente de SACDIA no existe para hacer quedar bien al sistema, sino para describirlo con precisión operativa. Su valor depende de distinguir con honestidad qué existe hoy, qué está parcial, qué está en transición y qué todavía no debe asumirse como verdadero.
