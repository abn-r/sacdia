# Rediseño de acceso de usuario y membresía pendiente

**Estado:** DRAFT  
**Fecha:** 2026-05-22  
**Repos impactados:** `sacdia-backend`, `sacdia-admin`, `sacdia-app`, `docs`

## Problema

El panel admin muestra acciones globales de **Aprobar/Rechazar usuario**, pero el runtime verificado no usa `users.approval_status` como gate real de acceso. Los usuarios pueden operar según roles, permisos, `access_app`, `access_panel`, post-registro y asignaciones activas a club/sección.

Además, una aprobación global manual no escala para una población esperada de 16k+ personas. La operación real que sí necesita revisión humana es la pertenencia a club/sección.

## Decisión de diseño

SACDIA debe reemplazar la aprobación global manual de usuarios por un modelo de **revisión por excepción**.

La membresía a club/sección debe ser el gate operativo principal:

- `club_role_assignments.status = pending`: solicitud enviada, todavía sin acceso operativo al club.
- `club_role_assignments.status = active`: miembro aceptado; habilita contexto activo y features del club.
- `club_role_assignments.status = rejected`: solicitud rechazada; mostrar motivo y permitir reintento según regla.
- `club_role_assignments.status = expired`: solicitud vencida; permitir nueva solicitud.

## Modelo conceptual

### 1. Usuario dentro del sistema

Puede:

- iniciar sesión;
- completar perfil/post-registro;
- solicitar unirse a club/sección;
- ver el estado de su solicitud;
- acceder a su perfil y gestionar su información personal;
- usar funcionalidades personales no dependientes de club activo, incluyendo carga masiva/staging de especialidades y clases.

No necesita aprobación global manual para existir en SACDIA.

### 2. Miembro pendiente

Puede ver:

- pantalla de estado de solicitud;
- club, sección, rol solicitado y fecha;
- estado `Pendiente`;
- instrucciones de espera;
- opción de cancelar la solicitud;
- perfil propio y edición de información personal;
- datos de club/sección como “Pendiente de aprobación”;
- carga masiva/staging de especialidades y clases mientras queda pendiente de validación operativa.

No debe ver features operativas del club:

- clases asignadas;
- evidencias;
- inventario;
- reportes;
- datos internos de miembros;
- actividades privadas;
- funciones de coordinación.

### 3. Miembro aceptado

Cuando la solicitud pasa a `active`:

- se habilita el contexto activo;
- se resuelven permisos de club/sección;
- se desbloquean features operativas según rol.

### 4. Revisión por excepción

La administración global debe revisar casos anómalos, no todos los usuarios:

- nombre y fecha de nacimiento idénticos a otro usuario;
- falta de tutor legal cuando el usuario es menor de edad;
- nombres ofensivos;
- conflicto de identidad;
- comportamiento sospechoso;
- bloqueo manual por seguridad;
- conflictos de club/sección no resueltos por el flujo normal.

## Reglas cerradas para membresía pendiente

- Un usuario solo puede tener **una solicitud pendiente** de membresía a club/sección.
- Si cancela su solicitud pendiente, se reinicia el flujo de post-registro desde la selección de club/sección.
- Una nueva solicitud debe notificar a los responsables operativos de la sección/club:
  - director;
  - subdirector;
  - secretario;
  - secretario tesorero.
- Mientras la solicitud esté pendiente, el usuario conserva acceso al perfil y a gestión de información personal.
- Mientras la solicitud esté pendiente, la app debe mostrar el club/sección solicitado como `Pendiente de aprobación`.
- La carga masiva de especialidades y clases puede estar disponible para el usuario pendiente como captura/staging personal, pero no debe desbloquear permisos operativos de club hasta que la membresía esté activa.

## Cambios esperados

### Backend

- No tratar `approval_status` como gate global de acceso.
- Formalizar `club_role_assignments.status` como fuente de verdad para acceso operativo a club/sección.
- Asegurar que permisos y contexto activo ignoren solicitudes `pending`, `rejected` y `expired`.
- Mantener o rediseñar `approval_status` solo si se convierte en estado de revisión por excepción.

### Admin

- Quitar o degradar los botones globales “Aprobar/Rechazar” del hero de detalle de usuario.
- Reemplazarlos por una sección de “Revisión administrativa” solo cuando exista una bandera de riesgo.
- Mantener gestión de `access_app` y `access_panel` como controles explícitos de acceso por superficie.
- La aprobación de membresía debe vivir en solicitudes de membresía, no en detalle global de usuario.

### App móvil

- Agregar estado explícito para usuario sin membresía activa.
- Mostrar pantalla de solicitud pendiente cuando exista `club_role_assignments.status = pending`.
- Mostrar club/sección solicitado como `Pendiente de aprobación`.
- Permitir cancelar la solicitud pendiente y volver a selección de club/sección.
- Permitir acceso a perfil, gestión de información personal y carga masiva/staging de especialidades y clases.
- Bloquear navegación a features de club mientras no haya asignación activa.
- Mostrar motivo y reintento cuando la solicitud esté rechazada o vencida.

### Documentación

- Actualizar `docs/features/auth.md` para remover la aprobación global como gate general.
- Actualizar `docs/features/membership-requests.md` para declarar el estado pendiente como parte del flujo de usuario móvil.
- Alinear permisos/documentación del endpoint admin si se conserva.

## Regla de producto propuesta

> Un usuario puede existir y autenticarse en SACDIA sin aprobación global manual.  
> Las funcionalidades operativas de club/sección requieren una membresía activa.  
> La administración global revisa excepciones, no altas masivas.

## Preguntas abiertas

- ¿La carga masiva/staging de especialidades y clases para usuarios pendientes queda visible para el director antes de aprobar la membresía?
- ¿La cancelación de solicitud conserva historial visible para administradores o solo auditoría interna?
