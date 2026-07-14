# Inscripción de sección a Camporí — Diseño

**Estado:** APROBADO

**Fecha:** 2026-07-13
**Alcance:** `sacdia-backend`, `sacdia-app`, contratos API y documentación de Camporees

## Objetivo

Dar al director de club un momento explícito y seguro para inscribir su sección activa a un Camporí antes de registrar participantes, sin exponer identificadores internos y conservando trazabilidad del actor.

## Problema verificado

El backend ya expone inscripción de secciones mediante `POST /api/v1/camporees/:camporeeId/clubs` y persiste `camporee_clubs.registered_by`. La app también contiene `CamporeeEnrollClubView`, su ruta, providers y datasource. Sin embargo:

1. ninguna pantalla navega a esa vista;
2. la vista exige escribir manualmente `club_section_id`;
3. el detalle permite registrar personas antes de inscribir la sección;
4. el permiso `attendance:manage` pertenece a varios cargos, no sólo al director;
5. el guard autoriza por territorio del Camporí, pero no demuestra que la sección enviada pertenezca al actor;
6. `camporee_members` no conserva relación con la inscripción de sección que originó la participación.

El problema no es solamente de descubribilidad. Es una brecha de secuencia, ownership y auditoría.

## Decisiones aprobadas

1. La inscripción corresponde únicamente a la sección activa del director.
2. Sólo el rol `director` puede ejecutar la inscripción contextual desde la app.
3. El backend deriva sección y club desde `active_assignment`; el cliente no envía `club_section_id`.
4. La inscripción registra obligatoriamente al usuario que realizó la acción.
5. No se pueden registrar participantes hasta que la inscripción de sección esté `registered` o `approved`.
6. Cada participante queda vinculado a la inscripción de sección para preservar trazabilidad histórica.
7. El endpoint genérico actual queda reservado a organizadores territoriales y deja de ser el contrato del flujo móvil.
8. La experiencia usa componentes y tokens existentes de SACDIA; no introduce una estética paralela ni dependencias visuales nuevas.

## Arquitectura contractual

### Contrato contextual

Crear dos endpoints locales para la sección activa del usuario:

```text
GET  /api/v1/camporees/:camporeeId/section-registration
POST /api/v1/camporees/:camporeeId/section-registration
```

El `POST` no recibe body. El backend obtiene del snapshot de autorización:

```text
actor_user_id
active_assignment_id
role_name
club_id
club_section_id
club_type_id
local_field_id
```

El `GET` devuelve un read model contextual estable:

```ts
type CamporeeSectionRegistrationState = {
  camporeeId: number;
  clubId: number;
  clubName: string;
  clubSectionId: number;
  sectionName: string;
  clubTypeId: number;
  clubTypeName: string;
  status:
    | 'not_enrolled'
    | 'registered'
    | 'pending_approval'
    | 'approved'
    | 'rejected'
    | 'cancelled';
  disposition:
    | 'not_open_yet'
    | 'open'
    | 'late_approval_required'
    | 'manually_frozen';
  canEnroll: boolean;
  blockingReason: string | null;
  enrollmentId: number | null;
  registeredAt: string | null;
  registeredBy: {
    userId: string;
    displayName: string;
  } | null;
};
```

Los nombres finales de campos deberán seguir el casing del contrato API vigente. La app transforma el DTO a una entidad de dominio tipada.

### Autorización

Crear una capacidad específica, por ejemplo:

```text
camporees:register_active_section
```

Se asigna exclusivamente al rol de club `director`. No se reutiliza `attendance:manage` porque ese permiso también corresponde a subdirector, secretario y tesorero.

El servicio verifica nuevamente, como defensa en profundidad:

1. existe un `active_assignment` vigente;
2. el rol activo es `director`;
3. la sección pertenece al club y campo local resueltos en el snapshot;
4. el Camporí pertenece al mismo campo local;
5. el tipo de club de la sección está incluido en el Camporí;
6. la disposición temporal permite inscripción normal o tardía;
7. no existe otra inscripción activa para la misma sección y Camporí.

El actor siempre se toma de `req.user.sub`. Ningún campo de auditoría se acepta desde el cliente.

### Idempotencia

El `POST` será idempotente por la clave lógica:

```text
(camporee_id, club_section_id, active)
```

Una repetición causada por doble toque o reintento de red devuelve la inscripción activa existente, sin crear otra fila. La base debe reforzar esta propiedad con un índice único parcial para inscripciones activas locales y su equivalente para Camporees de Unión cuando ese flujo se adopte.

## Modelo de datos

### `camporee_clubs`

Conservar:

- `club_section_id` como sección inscrita;
- `club_id` como snapshot del club;
- `registered_by` como actor autenticado;
- `created_at` como fecha de inscripción;
- `status` para inscripción normal, tardía y revisión.

Agregar o endurecer:

- `registered_by` requerido para nuevas inscripciones contextuales;
- índice único parcial por Camporí y sección cuando `active = true`;
- índices de consulta por `camporee_id`, `club_section_id`, `status` y `active`.

No es necesario reescribir registros históricos sin actor. La restricción puede aplicarse mediante contrato y validación, conservando nullable el campo si los históricos no permiten backfill confiable.

### `camporee_members`

Agregar `camporee_club_id` nullable durante la migración, con FK a `camporee_clubs` y `ON DELETE NO ACTION`. Las nuevas inscripciones de participantes lo requieren. Los históricos permanecen sin vínculo cuando no sea posible inferirlo de forma inequívoca.

El vínculo evita depender de la asignación actual del usuario cuando cambie de sección en el futuro.

## Secuencia de negocio

```text
Director abre detalle del Camporí
  -> app consulta estado contextual de su sección
  -> backend resuelve active_assignment
  -> app muestra disponibilidad y estado

Si puede inscribir:
  -> director abre confirmación
  -> app envía POST sin body
  -> backend valida rol, ownership, elegibilidad y ventana
  -> backend crea o devuelve camporee_clubs
  -> app refresca estado y detalle

Después:
  registered/approved -> habilita participantes
  pending_approval    -> bloquea participantes hasta aprobación
  rejected/cancelled  -> muestra motivo y posible recuperación
```

## Registro de participantes

El contrato existente de registro de miembros debe endurecerse. Antes de crear `camporee_members`, el backend:

1. resuelve la sección activa del director;
2. exige una inscripción `camporee_clubs` activa con estado `registered` o `approved`;
3. verifica que el usuario objetivo pertenece actualmente a esa sección;
4. persiste `camporee_club_id` en el registro del participante;
5. rechaza usuarios de otra sección aunque pertenezcan al mismo campo local.

La app mantiene el selector limitado a miembros de la sección activa, pero esa restricción visual nunca sustituye la validación del servidor.

## Experiencia móvil

### Ubicación

En `CamporeeDetailView`, antes de la sección de participantes, mostrar el bloque:

```text
Participación de tu sección
Club: <nombre>
Sección: <tipo/nombre>
Estado: <estado contextual>
```

Cuando la inscripción está disponible y el usuario es director, mostrar una acción inferior segura para el pulgar:

```text
Inscribir mi sección
```

No se mostrará ningún campo para IDs.

### Confirmación

La acción abre una hoja modal adaptativa con:

- nombre del Camporí;
- club y sección activa;
- costo;
- fecha límite;
- aviso de inscripción tardía cuando corresponda;
- texto “Registrarás esta inscripción como director”;
- botón primario “Confirmar inscripción”.

La hoja respeta safe areas, escalado de texto y objetivos táctiles mínimos de 48dp. La confirmación se deshabilita durante la petición para evitar múltiples envíos.

### Estados

| Estado | Presentación | Acción |
|---|---|---|
| Loading | Skeleton con altura estable | Ninguna |
| `not_open_yet` | Fecha de apertura | Deshabilitada |
| `not_enrolled` + `open` | Inscripción disponible | Confirmar inscripción |
| `not_enrolled` + tardía | Advertencia y revisión requerida | Solicitar inscripción |
| `pending_approval` | Estado pendiente y explicación | Ninguna |
| `registered`/`approved` | Actor y fecha | Gestionar participantes |
| `rejected` | Motivo de rechazo | Reintentar sólo si negocio lo permite |
| `cancelled`/cerrada | Explicación del cierre | Ninguna |
| Error de red | Mensaje inline y reintento | Reintentar |

Otros cargos pueden consultar el estado, pero verán el texto “El director de la sección debe realizar la inscripción” en lugar del CTA.

### Participantes

La sección de participantes deja de mostrar una acción siempre disponible:

- `registered` o `approved`: muestra “Inscribir participantes”;
- `pending_approval`: muestra el bloqueo pendiente;
- sin inscripción: explica que primero debe inscribirse la sección;
- usuario sin rol director: estado de sólo lectura según permisos vigentes.

### Accesibilidad y movimiento

- contraste WCAG 2.2 AA;
- objetivos táctiles de 48dp;
- `Semantics` para estado, actor y acciones;
- estado comunicado por texto e iconografía, nunca sólo por color;
- soporte para texto escalado sin truncar datos críticos;
- transiciones de 150–250ms usando opacidad/transform;
- feedback háptico breve al confirmar;
- sin animaciones perpetuas ni efectos costosos.

## Estado offline

El último read model puede mostrarse desde caché como información. La mutación requiere conexión:

- botón deshabilitado sin red;
- mensaje explícito “Necesitas conexión para inscribir tu sección”;
- reintento manual;
- nunca mostrar éxito optimista antes de la confirmación del backend.

## Errores de dominio

Agregar códigos estables para que la app no dependa de texto:

```text
CAMPOREE_ACTIVE_SECTION_REQUIRED
CAMPOREE_DIRECTOR_ROLE_REQUIRED
CAMPOREE_SECTION_NOT_ELIGIBLE
CAMPOREE_SECTION_ALREADY_REGISTERED
CAMPOREE_SECTION_REGISTRATION_NOT_OPEN
CAMPOREE_SECTION_REGISTRATION_PENDING
CAMPOREE_SECTION_REGISTRATION_REQUIRED
CAMPOREE_MEMBER_OUTSIDE_ACTIVE_SECTION
```

Usar `403` para autorización/ownership, `404` para recursos inexistentes, `409` para conflictos de estado y `422` para invariantes de negocio no satisfechas.

## Pruebas

### Backend

- controlador exige la nueva capacidad;
- director con asignación activa puede consultar e inscribir su sección;
- otros cargos reciben `403` al mutar;
- el body no puede elegir otra sección;
- sección de otro campo o tipo no incluido se rechaza;
- doble solicitud devuelve la misma inscripción;
- inscripción tardía queda `pending_approval`;
- participantes se bloquean antes de inscripción/aprobación;
- usuario objetivo de otra sección se rechaza;
- `registered_by` y `camporee_club_id` quedan persistidos;
- migración conserva históricos sin inferencias inseguras.

### App Flutter

- skeleton, error y reintento del estado contextual;
- CTA visible sólo para director elegible;
- otros cargos ven estado de sólo lectura;
- confirmación muestra club/sección resueltos;
- loading deshabilita doble toque;
- éxito refresca estado, detalle y participantes;
- `pending_approval` bloquea participantes;
- `registered`/`approved` habilita participantes;
- textos y controles toleran escalado y targets táctiles mínimos.

## Documentación sincronizada

El cambio debe actualizar en la misma entrega:

- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`;
- `docs/api/FRONTEND-INTEGRATION-GUIDE.md`;
- `docs/database/SCHEMA-REFERENCE.md`;
- `docs/database/schema.prisma`;
- `docs/features/camporees.md`;
- mirrors locales del backend cuando correspondan.

## Despliegue

1. aplicar migración en development;
2. ejecutar pruebas backend y Flutter sin build;
3. validar flujo en dispositivo con hot reload;
4. aplicar migración en staging y ejecutar smoke test;
5. aplicar en production después de evidencia positiva de staging.

La migración debe desplegarse antes que la versión backend que requiera `camporee_club_id` para nuevas inscripciones.

## No objetivos

- Inscribir automáticamente todas las secciones del mismo club.
- Permitir a subdirector, secretario o tesorero ejecutar la inscripción.
- Rediseñar todo el módulo Camporees.
- Cambiar la administración territorial de aprobaciones tardías.
- Añadir animaciones decorativas o dependencias visuales nuevas.

## Criterios de aceptación

1. Un director puede inscribir únicamente su sección activa sin escribir IDs.
2. La base registra actor, fecha, club y sección.
3. Otro cargo o una sección manipulada no puede crear la inscripción.
4. La app comunica claramente todos los estados del flujo.
5. No se pueden registrar participantes antes de inscripción/aprobación.
6. Cada nuevo participante queda vinculado a la inscripción de sección.
7. Los contratos, schema y documentación quedan sincronizados.
