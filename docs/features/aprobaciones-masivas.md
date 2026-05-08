# Aprobaciones Masivas de Investiduras

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las aprobaciones masivas permiten a coordinadores y administradores procesar hasta 200 validaciones de investidura en una sola operacion. Esto resuelve el cuello de botella operativo que se genera al final del ano eclesiastico cuando decenas de clubes envian sus enrollments a validacion simultaneamente.

El flujo soporta tres acciones masivas: aprobacion de coordinador (`coordinator-approve`), aprobacion de campo (`field-approve`) e investidura (`invest`). Tambien soporta rechazo masivo con comentarios obligatorios. El sistema maneja exitos parciales: si algunas operaciones fallan, las exitosas se confirman y las fallidas se reportan individualmente.

## Que existe (verificado contra codigo)

### Backend (InvestitureModule — bulk extensions)
- **2 endpoints nuevos**:
  - `POST /api/v1/investiture/enrollments/bulk-approve` — Aprobacion masiva (coordinator-approve, field-approve, invest)
  - `POST /api/v1/investiture/enrollments/bulk-reject` — Rechazo masivo con comentarios obligatorios
- Limite de 200 enrollments por operacion
- Proteccion contra race conditions via transacciones de base de datos
- Respuesta con detalle de exitos y fallos parciales
- Guards: JwtAuthGuard, GlobalRolesGuard (admin, coordinator)

### Admin (sacdia-admin)
- **Checkboxes en tabla de investiduras**: Seleccion multiple con select-all por pagina
- **Floating action bar**: Barra de acciones que aparece al seleccionar enrollments con conteo de seleccionados
- **Role-aware selection**: Las acciones disponibles dependen del rol del usuario y del estado de los enrollments seleccionados
- **Partial success handling**: Notificaciones detallando cuantos se procesaron exitosamente y cuales fallaron
- **Componente**: `src/components/investiture/bulk-action-bar.tsx`

### Base de datos
- Sin cambios de schema — reutiliza tablas existentes de investidura
- Transacciones atomicas para garantizar consistencia en operaciones masivas

## Requisitos funcionales

1. Coordinadores deben poder seleccionar multiples enrollments y aplicar acciones masivas
2. El limite maximo de seleccion es 200 enrollments por operacion
3. Las acciones masivas deben respetar las mismas reglas de transicion de estado que las individuales
4. Si algunas operaciones fallan, las exitosas deben confirmarse (partial success)
5. El rechazo masivo debe requerir comentarios obligatorios
6. La UI debe mostrar claramente cuantos items estan seleccionados y que acciones estan disponibles
7. Debe haber proteccion contra race conditions (dos coordinadores procesando los mismos enrollments)

## Decisiones de diseno

- **Extension de modulo existente**: Se agregan endpoints al InvestitureModule existente
- **Limite de 200**: Balance entre eficiencia operativa y carga de servidor/base de datos
- **Partial success**: Se procesan todos los posibles en una transaccion, reportando fallos individuales
- **Floating action bar**: Pattern de UX que aparece solo con seleccion activa, evitando cluttering de la interfaz
- **Race condition protection**: Transacciones con SELECT FOR UPDATE para evitar procesamiento duplicado

## Gaps y pendientes

- Sin undo/rollback de operaciones masivas
- Sin historial agrupado de operaciones masivas (cada enrollment tiene su historial individual)

## Estado de implementacion

- Backend: 2 endpoints bulk con proteccion de race conditions y partial success
- Admin: Checkboxes, floating action bar, role-aware selection
