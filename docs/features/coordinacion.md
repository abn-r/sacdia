# Coordinación

**Estado**: EN IMPLEMENTACIÓN

## Descripción de dominio

La coordinación es el modelo institucional mediante el cual un campo local
supervisa la validación operativa de sus clubes por zonas, secciones o
asignaciones directas.

El modelo canónico vive en `docs/canon/runtime-coordination.md`.

## Modelo funcional

Un campo local puede:

1. crear zonas de coordinación;
2. asociar distritos a esas zonas;
3. asignar un único coordinador general activo;
4. asignar coordinadores por zona y tipo/sección de club;
5. asignar coordinadores directamente a secciones específicas cuando no opere
   por zonas o exista una excepción.

La unidad final de autoridad es `club_sections`.

## Requisitos funcionales

1. Un campo local puede crear y mantener sus zonas.
2. Una zona agrupa distritos del mismo campo local.
3. Un distrito activo no debe pertenecer a más de una zona activa del mismo
   campo local.
4. Un campo local no puede tener más de un coordinador general activo.
5. Un coordinador de zona se asigna por zona + tipo/sección de club.
6. El sistema debe soportar asignaciones directas por `club_section`.
7. El sistema debe soportar usuarios multirol.
8. Si un usuario es director de una `club_section`, no puede coordinar esa misma
   `club_section`.
9. La app debe mostrar todas las funcionalidades que correspondan a los roles
   activos del usuario.
10. El alcance efectivo del coordinador debe resolverse en backend y expresarse
    como `club_section_ids`.

## Superficie esperada

### Backend

- Módulo de coordinación para zonas y asignaciones: `CoordinationModule`.
- Resolver común `coordinator_scope(user_id)` expuesto como
  `GET /api/v1/coordination/me/scope`.
- Validaciones de integridad y conflicto director/coordinador en servicio.
- Filtros por scope en SLA, evidencias e investiduras. El scope expone secciones/clubes para la superficie de clubes.

### Admin Web

- Pantalla `/dashboard/coordination` para administrar zonas y coordinadores por campo local.
- Requiere rol institucional administrativo y permiso efectivo
  `coordination:manage`; los roles de coordinador runtime no administran este
  panel.
- Creación/activación de zonas.
- Asociación de distritos a zonas.
- Asignación general, por zona + sección y directa por sección.
- La vista consume los endpoints `/api/v1/admin/coordination/*`.

### App Móvil

- Hub de coordinación visible para usuarios con rol aplicable:
  `coordinator`, `zone-coordinator` o `general-coordinator`.
- Consume `GET /api/v1/coordination/me/scope` para mostrar secciones asignadas
  y derivar clubes bajo gestión.
- SLA, evidencias e investiduras usan el scope filtrado en backend.
- La superficie de coordinación no muestra aprobaciones de camporee.
- Multirol: si el usuario también es director, las funcionalidades de director
  siguen apareciendo en la app mediante sus permisos/roles existentes.

## Decisiones de diseño

- **Scope por asignación, no por rol global**: el rol habilita acceso; la
  asignación define autoridad real.
- **`club_section` como unidad final**: permite cubrir clubes con varias
  secciones y coordinadores diferentes.
- **Zonas como agrupación de distritos**: respeta la organización real del campo
  local sin duplicar relación club/iglesia.
- **Asignación directa como fallback**: permite operar sin zonas o manejar
  excepciones finas.
- **Multirol explícito**: director y coordinador pueden coexistir salvo en la
  misma sección del mismo club.

## Gaps y pendientes

- Completar vistas de cobertura agregada por coordinador si se requiere más detalle que la lista de asignaciones.
- Evaluar si en el futuro conviene agregar un endpoint específico de clubes bajo coordinación; por ahora la app deriva clubes desde `sections` en `coordination/me/scope`.
