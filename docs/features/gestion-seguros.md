# Gestion de Seguros (Insurance)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El seguro institucional es un requisito administrativo para la participacion de miembros en actividades de riesgo dentro de los clubes de Conquistadores, Aventureros y Guias Mayores. Los clubes operan en contextos donde los miembros (muchos de ellos menores de edad) realizan actividades al aire libre que implican riesgo: campamentos, caminatas, escalada, actividades acuaticas, orden cerrado, y especialmente camporees competitivos.

El sistema contempla tres tipos de seguro segun el enum `insurance_type_enum`: GENERAL_ACTIVITIES (cobertura general para reuniones y actividades regulares), CAMPOREE (cobertura especifica para participacion en camporees), y HIGH_RISK (cobertura para actividades de alto riesgo como rapel, escalada, etc.). Cada seguro documenta la poliza, aseguradora, vigencia, monto de cobertura y puede incluir evidencia documental adjunta (archivo de poliza escaneado).

La vinculacion de seguros con camporees es directa: la tabla `camporee_members` referencia `member_insurances`, lo que permite validar que un miembro tiene cobertura vigente al momento de inscribirse en un evento. El modulo forma parte de la dimension administrativa de la trayectoria del miembro dentro de la institucion.

## Que existe (verificado contra codigo)

### Backend (InsuranceModule)
- **Controller**: `src/insurance/insurance.controller.ts`
- **Service**: `src/insurance/insurance.service.ts`
- **Module**: `src/insurance/insurance.module.ts`
- **DTOs**: `src/insurance/dto/`
- **Guards**: `JwtAuthGuard` + `PermissionsGuard` en toda la superficie; `GET /api/v1/insurance/expiring` agrega `GlobalRolesGuard`
- **5 endpoints**:
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/members/insurance` — Requiere `insurance:read` y `AuthorizationResource({ type: 'club' })`
  - `GET /api/v1/insurance/expiring` — Seguros proximos a vencer; requiere rol global `admin` o `coordinator` y acepta `days_ahead` / `local_field_id`
  - `GET /api/v1/users/:memberId/insurance` — Requiere `insurance:read` y `AuthorizationResource({ type: 'active_assignment' })`
  - `POST /api/v1/users/:memberId/insurance` — Requiere `insurance:create`; crea seguro con evidencia opcional (multipart, campo `evidence`)
  - `PATCH /api/v1/insurance/:insuranceId` — Requiere `insurance:update`; actualiza seguro existente con evidencia opcional (multipart)

### Admin
- **UI funcional**: `/dashboard/insurance` y `/dashboard/insurance/expiring`
- **Capacidades verificadas**: seleccion de club/seccion, tabla de miembros con estado del seguro, alta/edicion/desactivacion de seguros, alerta de vencimientos y vista dedicada de proximos vencimientos
- **Consumo verificado**: `GET /clubs/:clubId/sections/:sectionId/members/insurance`, `POST /users/:memberId/insurance`, `PATCH /insurance/:insuranceId`, `GET /insurance/expiring`

### App Movil
- **3 screens principales**: InsuranceView, InsuranceDetailView, InsuranceFormSheet
- Consume listado/detalle/alta/actualizacion; el datasource remoto conserva `GET /insurance/expiring`, pero la alerta actual de vencimientos se deriva localmente desde la lista ya cargada
- Soporta carga de evidencia documental
- Espera campos `evidence_file_url` y `evidence_file_name` en las respuestas

### Base de datos
- `member_insurances` — Seguros por miembro con campos:
  - `insurance_id` (PK INT), `user_id` (FK UUID), `insurance_type` (ENUM), `policy_number`, `provider`, `start_date`, `end_date`, `coverage_amount` (DECIMAL), `active`, `evidence_file_url`, `evidence_file_name`
  - Auditoria: `created_by_id` (FK UUID), `modified_by_id` (FK UUID)
- Relacion con `camporee_members` via `insurance_id`

### Storage
- Evidencia de seguros se almacena en Cloudflare R2, bucket `INSURANCE_EVIDENCE`

## Requisitos funcionales

1. Debe ser posible crear un seguro para cualquier miembro activo de una seccion de club
2. El seguro debe registrar: tipo (GENERAL_ACTIVITIES, CAMPOREE, HIGH_RISK), numero de poliza, aseguradora, fechas de vigencia, monto de cobertura
3. Debe ser posible adjuntar evidencia documental (PDF, imagen) al seguro via upload multipart
4. El listado de seguros por seccion debe mostrar cada miembro con su seguro activo mas reciente
5. Los seguros deben poder actualizarse (renovar vigencia, cambiar aseguradora, actualizar evidencia)
6. La evidencia se almacena en Cloudflare R2 y se expone como URL firmada
7. El modulo debe registrar quien creo y quien modifico cada seguro (auditoria)
8. El panel admin debe permitir gestion de seguros por seccion/club y monitoreo de vencimientos proximos

## Decisiones de diseno

- **Multipart para evidencia**: La creacion y actualizacion de seguros aceptan upload multipart con campo `evidence`, no requiere un endpoint separado para archivos
- **Seguro activo mas reciente**: El listado por seccion resuelve el seguro activo vigente de cada miembro, no el historico completo
- **Tres tipos de seguro**: El enum `insurance_type_enum` distingue cobertura por contexto de uso, no por nivel de proteccion
- **Auditoria integrada**: Los campos `created_by_id` y `modified_by_id` registran el actor que gestiona el seguro, que puede ser diferente del miembro asegurado (directores gestionan seguros de sus miembros)
- **Almacenamiento R2**: La evidencia se guarda en Cloudflare R2 siguiendo el mismo patron que fotos de perfil y evidencias de honores

## Gaps y pendientes

- **Sin notificaciones de vencimiento**: No hay mecanismo para alertar cuando un seguro esta por vencer
- **Sin historial**: Solo se muestra el seguro activo mas reciente; no hay endpoint para consultar seguros historicos de un miembro
- **Validacion de camporee acotada al flujo de registro**: `camporees.service.ts` valida tipo `CAMPOREE`, titularidad, vigencia y estado activo cuando se envia `insurance_id`, pero no existe una superficie general de historial o auditoria de coberturas
- **REALITY-MATRIX desactualizada**: La Reality Matrix marcaba seguros como "SIN CANON" y sin backend module, pero el modulo `src/insurance/` existe con 5 endpoints funcionales documentados en ENDPOINTS-LIVE-REFERENCE

## Prioridad y siguiente accion

- **Prioridad**: Media — backend, admin y app cubren la operacion base; faltan alertas/notificaciones e historial
- **Siguiente accion**: Actualizar REALITY-MATRIX.md para reflejar que el InsuranceModule y la UI admin existen. Considerar notificaciones de vencimiento e historial de seguros por miembro.
