# Camporees

**Estado**: PARCIAL

## Descripcion de dominio

Los camporees son eventos institucionales centrales en la vida de los clubes de Conquistadores y Aventureros. Son campamentos competitivos organizados a nivel de campo local (camporees locales) o de union (camporees de union) donde los clubes participan en actividades de evaluacion: orden cerrado, nudos, primeros auxilios, cocina al aire libre, orientacion, campismo, conocimiento biblico y otras disciplinas. Los camporees representan la culminacion del trabajo formativo del club durante un periodo.

El modelo de datos contempla dos niveles de camporees: locales (`local_camporees`) organizados por el campo local, y de union (`union_camporees`) que agrupan clubes de todo el territorio de la union. Los camporees de union pueden referenciar campos locales participantes (`union_camporee_local_fields`). Cada camporee admite inscripcion de clubes (`camporee_clubs`) y registro de miembros individuales (`camporee_members`).

La inscripcion de miembros en camporees tiene implicaciones directas con el modulo de seguros: para participar en un camporee, los miembros generalmente requieren un seguro activo de tipo CAMPOREE o GENERAL_ACTIVITIES. Esta relacion esta modelada en la tabla `camporee_members` que referencia `member_insurances`.

## Que existe (verificado contra codigo)

### Backend (CamporeesModule)
- **Controller**: `src/camporees/camporees.controller.ts`
- **Service**: `src/camporees/camporees.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **8 endpoints**:
  - `GET /api/v1/camporees` — Listar camporees
  - `POST /api/v1/camporees` — Crear camporee (roles: director, subdirector)
  - `GET /api/v1/camporees/:camporeeId` — Obtener camporee por ID
  - `PATCH /api/v1/camporees/:camporeeId` — Actualizar camporee (roles: director, subdirector)
  - `DELETE /api/v1/camporees/:camporeeId` — Desactivar camporee (roles: director)
  - `POST /api/v1/camporees/:camporeeId/register` — Registrar miembro en camporee
  - `GET /api/v1/camporees/:camporeeId/members` — Listar miembros del camporee
  - `DELETE /api/v1/camporees/:camporeeId/members/:userId` — Remover miembro del camporee (roles: director, subdirector)

### Admin
- **1 pagina read-only**: Lista de camporees via `ModuleListPage` consumiendo `GET /camporees`
- El codigo en `lib/camporees/actions.ts` y `lib/api/camporees.ts` tiene funciones de CRUD y gestion de miembros implementadas pero la UI solo muestra el listado

### App Movil
- **No implementado** — No hay screens de camporees en la app movil

### Base de datos
- `local_camporees` — Camporees a nivel de campo local
- `union_camporees` — Camporees a nivel de union
- `union_camporee_local_fields` — Campos locales participantes en camporees de union
- `camporee_clubs` — Clubs inscritos en camporees
- `camporee_members` — Miembros inscritos en camporees (referencia `member_insurances`)

## Requisitos funcionales

1. Directores y subdirectores deben poder crear y gestionar camporees
2. Los camporees deben tener nombre, fechas, ubicacion, tipo (local/union) y descripcion
3. El sistema debe permitir inscribir miembros individualmente en un camporee
4. Debe ser posible listar los miembros inscritos en cada camporee
5. El registro de miembros debe validar requisitos (seguro activo, membresia vigente)
6. Los camporees deben poder desactivarse (soft delete) sin perder datos historicos
7. El panel admin debe permitir CRUD completo de camporees con gestion de miembros
8. La app movil debe permitir a los miembros ver camporees disponibles e inscribirse

## Decisiones de diseno

- **Dos niveles de camporees**: El modelo distingue camporees locales y de union con tablas separadas, permitiendo diferente estructura organizativa
- **Inscripcion individual**: Los miembros se registran individualmente, no como club completo, permitiendo control granular de participacion
- **Vinculacion con seguros**: `camporee_members` referencia `member_insurances` para validar que el participante tiene cobertura vigente
- **Autorizacion estricta**: Solo director puede eliminar camporees; director y subdirector pueden crearlos y gestionarlos

## Gaps y pendientes

- **App no tiene screens**: El modulo de camporees no esta implementado en la app movil
- **Admin read-only**: La UI del admin solo muestra listado; las funciones de CRUD y gestion de miembros estan codificadas pero no expuestas en la interfaz
- **Sin evaluaciones**: No hay modelo para registrar evaluaciones o puntajes de los clubes/miembros durante el camporee
- **Sin documentacion de modelo**: Las 5 tablas de camporees no estan documentadas en SCHEMA-REFERENCE.md
- **Sin validacion de seguro**: Aunque el modelo vincula miembros con seguros, no esta claro si el endpoint de registro valida efectivamente que el miembro tenga seguro vigente
- **Sin logistica**: No hay modelo para gestionar logistica del camporee (comida, transporte, alojamiento)

## Prioridad y siguiente accion

- **Prioridad**: Media-alta — canon reconoce camporees como capacidad operativa; falta app y admin funcional
- **Siguiente accion**: Implementar CRUD completo en admin aprovechando las funciones ya codificadas en `actions.ts`/`api/camporees.ts`. Luego agregar screens en la app movil.
