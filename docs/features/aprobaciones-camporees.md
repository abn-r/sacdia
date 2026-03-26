# Aprobaciones de Camporees

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las aprobaciones de camporees son el proceso mediante el cual un coordinador o administrador revisa y aprueba (o rechaza) las inscripciones de clubes, miembros y pagos en camporees locales y de union. Este flujo garantiza que solo participantes elegibles y con documentacion completa asistan a los eventos institucionales.

El proceso abarca tres tipos de aprobaciones: (1) inscripcion del club al camporee, (2) inscripcion individual de cada miembro con validacion de seguro y elegibilidad, y (3) registro de pagos asociados. Para camporees de union, las inscripciones pasan por un flujo de routing que involucra al campo local antes de llegar a la union.

## Que existe (verificado contra codigo)

### Backend (CamporeesModule — approval extensions)
- Reutiliza el CamporeesModule existente con endpoints de aprobacion adicionales
- Soporte para aprobaciones de club, miembro y pago
- Routing de union: inscripciones de campo local se enrutan a la union para aprobacion final
- Guards: JwtAuthGuard, GlobalRolesGuard (admin, coordinator)

### Admin (sacdia-admin)
- **UI de aprobaciones**: Pagina dedicada con tabs para clubes, miembros y pagos pendientes
- **Pending badges**: Indicadores visuales de cantidad de aprobaciones pendientes en navegacion
- **Union routing**: Flujo diferenciado para camporees de union con aprobacion en cascada
- **Member status tracking**: Vista del estado de cada miembro inscrito (pendiente, aprobado, rechazado)
- **Dialogs de accion**: Aprobar/rechazar con campo de comentarios obligatorio en rechazo

### Base de datos
- Reutiliza tablas existentes: `camporee_clubs`, `camporee_members`
- Campos de aprobacion en tablas de inscripcion (status, approved_by, approved_at, rejection_reason)

## Requisitos funcionales

1. Coordinadores y admins deben poder ver inscripciones pendientes de aprobacion
2. Debe soportar aprobacion/rechazo de clubes, miembros y pagos de forma independiente
3. El rechazo debe requerir una razon obligatoria
4. Para camporees de union, las inscripciones deben pasar por el campo local antes de la union
5. Debe existir un indicador visual de aprobaciones pendientes en la navegacion del admin
6. El estado de cada miembro debe ser rastreable en tiempo real

## Decisiones de diseno

- **Reutilizacion de modulo**: Se extiende CamporeesModule existente en lugar de crear modulo separado
- **Union routing**: Cascada campo local -> union para camporees de union, garantizando validacion en ambos niveles
- **Pending badges**: Contadores en sidebar para visibilidad inmediata de trabajo pendiente

## Gaps y pendientes

- Sin notificaciones push a clubes cuando su inscripcion es aprobada/rechazada
- Sin reportes de tasas de aprobacion por campo local

## Estado de implementacion

- Backend: Endpoints de aprobacion integrados en CamporeesModule
- Admin: UI completa con pending badges, union routing y member status tracking
