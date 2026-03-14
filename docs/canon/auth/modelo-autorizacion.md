# Modelo de autorizacion

## Estado
ACTIVE

## Proposito
Definir el modelo canónico de autorización de SACDIA.

Este documento existe para evitar una confusión muy común: pensar que SACDIA usa `RBAC puro` cuando en realidad usa un modelo híbrido basado en roles, alcance y contexto activo.

La idea central es esta:

- los roles organizan responsabilidades;
- los permisos expresan acciones concretas;
- el scope territorial limita alcance global;
- la asignacion activa define el acceso efectivo de club;
- el backend resuelve la autorizacion final y la expone lista para consumir.

## Decision arquitectonica
SACDIA NO usa `RBAC puro` como modelo final de autorización.

SACDIA usa un modelo de `RBAC contextual`, compuesto por:

- `RBAC` para agrupar permisos por rol;
- `scope territorial` para limitar grants globales;
- `club assignments` para representar responsabilidades de club;
- `active_assignment` para definir el contexto efectivo de club por sesión;
- `effective.permissions` y `effective.scope` como salida resuelta del backend.

## Por que no alcanza RBAC puro
`RBAC puro` sirve cuando un rol por sí solo responde qué puede hacer un usuario.

En SACDIA eso no alcanza, porque el sistema necesita responder preguntas como:

- este usuario, con este rol, ¿sobre qué territorio puede operar?;
- este usuario, con varias asignaciones de club, ¿cuál está activa ahora?;
- este permiso aplica globalmente o solo dentro de un club puntual?;
- este usuario puede leer o modificar un recurso por su rol, por su contexto activo o por una condición de ownership?;
- este usuario tiene acceso a un recurso por ser admin territorial o por ser líder de un club específico?

Si el sistema intentara resolver esas preguntas con `RBAC puro`, terminaría con:

- roles inflados y poco mantenibles;
- duplicación de roles por cada combinación de contexto;
- lógica de autorización dispersa en frontend y backend;
- decisiones ambiguas cuando un usuario tiene múltiples responsabilidades simultáneas.

## Por que no conviene ABAC puro hoy
Un modelo `ABAC puro` daría flexibilidad extrema, pero hoy sería demasiado costoso para este proyecto.

Problemas de irse a ABAC puro ahora:

- mayor complejidad mental;
- reglas más difíciles de auditar y testear;
- más riesgo de inconsistencias entre clientes y backend;
- más dificultad para que el equipo y futuras IAs entiendan el sistema sin reinterpretarlo todo.

Conclusion práctica:

- `RBAC puro` es insuficiente;
- `ABAC puro` es excesivo;
- `RBAC contextual` es el punto de equilibrio correcto para SACDIA.

## Modelo mental canónico
La autorización de SACDIA debe leerse así:

1. el usuario se autentica;
2. el backend identifica sus grants globales;
3. el backend identifica sus asignaciones de club disponibles;
4. el backend determina cuál asignación de club está activa;
5. el backend calcula permisos efectivos y scope efectivo;
6. los clientes consumen esa resolución, no la reinventan.

En otras palabras:

- `grants` describe todo lo que el usuario tiene potencialmente;
- `effective` describe lo que realmente aplica en esta sesión y en este contexto.

## Piezas del modelo

### 1. Roles
Los roles representan responsabilidades agrupadas.

Ejemplos conceptuales:

- `super_admin`
- `admin`
- `assistant_admin`
- `coordinator`
- roles de club como director, secretario, consejero u otros equivalentes

Un rol no autoriza por sí solo cualquier acción sobre cualquier recurso.
Siempre debe leerse junto con su alcance real.

### 2. Permisos
Los permisos representan acciones concretas.

Convención vigente:
- `resource:action`

Ejemplos:
- `users:read`
- `users:update`
- `clubs:read`
- `club_roles:assign`

Los permisos pueden venir de:

- grants globales;
- asignación activa de club.

## 3. Scope territorial
El `scope territorial` limita el alcance de roles globales.

Niveles actuales del modelo:

- `country`
- `union`
- `local_field`

Esto significa que dos usuarios con el mismo rol global no necesariamente tienen el mismo alcance efectivo.

Ejemplo:
- dos usuarios pueden ser `admin`, pero uno operar sobre una unión completa y otro solo sobre un campo local.

## 4. Club assignments
La asignación de club es la unidad canónica del acceso contextual de club.

Una asignación vincula, como mínimo:

- usuario;
- rol;
- club;
- tipo de instancia;
- instancia específica;
- vigencia;
- estado.

Un usuario puede tener varias asignaciones de club simultáneas disponibles.

## 5. Active assignment
Aunque un usuario tenga múltiples asignaciones, solo una asignación de club aporta permisos efectivos de club en la sesión actual.

Ese concepto es `active_assignment`.

Reglas canónicas:

- el backend resuelve una asignación activa inicial;
- el usuario puede cambiarla solo a través del endpoint canónico correspondiente;
- los permisos efectivos de club salen solo de esa asignación activa;
- los clientes no deben mezclar permisos de varias asignaciones al mismo tiempo.

Este punto es CRITICO.
Sin esto, la autorización de club se vuelve ambigua y peligrosa.

## 6. Effective permissions
`effective.permissions` representa la lista final de permisos vigentes para la sesión actual.

Se calcula combinando:

- permisos globales aplicables;
- permisos de la asignación activa de club.

No representa “todo lo que el usuario podría llegar a hacer en algún contexto”.
Representa lo que puede hacer AHORA en la sesión actual.

## 7. Effective scope
`effective.scope` representa el alcance efectivo de la sesión.

Incluye:

- alcance global territorial;
- alcance de club derivado de la asignación activa.

Esto permite que el backend y los clientes hablen el mismo idioma sobre “dónde” aplica un permiso.

## Grants vs Effective
Esta diferencia no es opcional. Es estructural.

### Grants
`grants` responde:
- qué roles globales tiene el usuario;
- qué asignaciones de club tiene disponibles.

`grants` describe inventario de acceso.

### Effective
`effective` responde:
- qué permisos están vigentes en esta sesión;
- qué alcance real aplica ahora mismo.

`effective` describe autorización resuelta.

Regla canónica:
- para UX, guards de frontend y decisiones operativas rápidas, consumir `effective`;
- para vistas de administración, matrices o selectores de contexto, consumir también `grants`.

## Reglas canónicas de consumo

### Backend
- resuelve autorización en un único punto canónico;
- no delega decisión final al frontend;
- valida permisos y contexto sobre el recurso solicitado;
- puede combinar autorización con ownership cuando un recurso sea del propio usuario.

### Admin web
- usa `authorization.effective.permissions` para habilitar o bloquear acciones;
- usa `authorization.grants` para mostrar roles, asignaciones y selectores de contexto;
- no recompone permisos con joins locales ni heurísticas propias.

### App móvil
- usa `authorization.effective.permissions` para habilitar acciones;
- usa `authorization.effective.scope.club` como contexto activo de trabajo;
- no asume que todas las asignaciones de club están activas simultáneamente.

## Ownership y excepciones controladas
No toda autorización en SACDIA se reduce a roles y contexto.

Existen casos donde también aplica `ownership`, por ejemplo:

- un usuario viendo o editando ciertos datos propios;
- operaciones de perfil o preferencias personales.

Regla canónica:
- `ownership` complementa el modelo;
- no reemplaza roles, scope ni asignación activa;
- debe estar explicitado en backend cuando aplique.

## Lo que NO hay que hacer
- no hablar de SACDIA como si usara `RBAC puro`;
- no mezclar permisos de varias asignaciones de club activas a la vez;
- no resolver autorización solo desde frontend;
- no usar campos legacy como contrato nuevo;
- no crear roles nuevos para cada variación contextual que en realidad debe resolverse con scope o assignment;
- no convertir el sistema en `ABAC puro` sin una razón estructural muy fuerte.

## Tradeoffs asumidos
Este modelo elige claridad operativa por encima de flexibilidad absoluta.

Beneficios:
- más mantenible que ABAC puro;
- más expresivo que RBAC puro;
- más fácil de auditar;
- más fácil de documentar;
- más alineado con la realidad organizacional de SACDIA.

Costo:
- obliga a documentar bien contexto activo y grants;
- exige que los clientes respeten la salida canónica del backend;
- requiere disciplina para no introducir contratos paralelos legacy.

## Decision de implementacion
Toda implementación futura de auth y authorization debe respetar estas reglas:

- el backend calcula la autorización efectiva;
- `GET /auth/me` expone la resolución canónica para clientes;
- permisos de club dependen de la asignación activa;
- roles globales operan con scope territorial;
- cualquier proceso nuevo debe aclarar si trabaja sobre grants o sobre effective;
- cualquier cambio al modelo debe actualizar este documento, `runtime-auth.md` y el proceso afectado.

## Relacion con otros documentos
- `docs/canon/auth/dominio-auth.md` — define el dominio y sus invariantes;
- `docs/canon/auth/runtime-auth.md` — define el comportamiento técnico vigente;
- `docs/canon/auth/procesos-auth.md` — define cómo se ve esto en flujos concretos como login, refresh o cambio de contexto.

## Referencias activas
- `docs/canon/auth/runtime-auth.md`
- `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`
- `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `sacdia-backend/src/common/services/authorization-context.service.ts`
