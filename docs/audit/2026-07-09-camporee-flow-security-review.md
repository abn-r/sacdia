# Revisión de flujo y seguridad — Camporee scoring

**Fecha:** 2026-07-09

**Tipo:** revisión estática contract-first
**Alcance:** backend de scoring en `codex/camporee-operational-scoring-backend`, admin en `origin/development@6105301`, app móvil alineada con `origin/development` y documentación activa.

## Resumen ejecutivo

La implementación ya tiene una base correcta para rúbricas, juez principal, resultado oficial único, ranking real, no-show y override trazable. Sin embargo, **todavía no es segura para liberar el flujo completo**.

Los bloqueos principales son:

1. El alta de un evento puntuable no es atómica y las rúbricas se rechazan mientras la inscripción esté abierta, aunque el negocio exige configurarlas antes del cierre.
2. No existe bloqueo por inicio/fin del camporee ni por horario del evento; un puntaje puede cargarse fuera de ventana y después se pueden cambiar o desactivar datos que alteran el ranking.
3. Hay controles de alcance incompletos en templates y IDs secundarios, lo que permite referencias cross-tenant por ID.
4. La app y el admin no completan el flujo operativo: no-show, resultado para director/subdirector, comentarios, ajuste de jueces y cierre automático/penalizaciones no están conectados.
5. El audit de dependencias reportó vulnerabilidades críticas/altas fuera del módulo de camporee que requieren triage de alcance.

## Hallazgos

### CAMP-FLOW-001 — Bloqueante — Configurar rúbricas antes del cierre es imposible y deja eventos parciales

- **Ubicación:**
  - `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:719-775`
  - `sacdia-admin/src/lib/camporee-events/actions.ts:667-695`
  - `sacdia-admin/src/lib/camporee-events/actions.ts:730-752`
- **Evidencia:** `replaceEventRubrics()` exige `club_registration_closed_at`; el admin primero crea/actualiza el evento y después ejecuta `syncRubricsFromForm()` como una segunda petición.
- **Impacto:** durante la preparación normal, la segunda petición falla. El evento ya quedó creado o modificado, el formulario muestra error y un reintento puede duplicar eventos o dejar estado parcial.
- **Corrección:** permitir configurar rúbricas durante preparación y mover evento + rúbricas a una única transacción/backend command. Bloquear cambios destructivos al iniciar el camporee o existir el primer resultado, no antes de cerrar inscripciones.
- **Mitigación temporal:** detectar el evento parcial y redirigir a edición; no elimina el problema de consistencia.

### CAMP-INTEGRITY-002 — Alta — Puntajes y estructura pueden cambiar fuera de la ventana operativa

- **Ubicación:**
  - `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:1125-1301`
  - `sacdia-backend/src/camporee-events/camporee-events.service.ts:896-1041`
  - `sacdia-backend/src/camporee-events/camporee-events.service.ts:1216-1225`
  - `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:719-775`
- **Evidencia:** `submitScore()` no consulta fecha/hora; `updateEvent()`, `deleteEvent()` y `replaceEventRubrics()` no verifican inicio del camporee, fin del evento ni existencia de resultados.
- **Impacto:** un juez puede puntuar antes o después del evento. Un operador puede cambiar máximos/rúbricas o desactivar un evento ya calificado; el leaderboard excluye eventos inactivos y el ranking cambia retroactivamente.
- **Corrección:** política de lifecycle centralizada: preparación → inscripción cerrada → en curso → finalizado. Permitir ajustes de horario/jueces según regla, pero congelar scope, máximos, rúbricas y eliminación al iniciar o al existir scoring.

### CAMP-SEC-003 — Alta — IDOR al clonar templates de otro territorio

- **Ubicación:**
  - `sacdia-backend/src/camporee-events/camporee-events.controller.ts:112-132`
  - `sacdia-backend/src/camporee-events/camporee-events.controller.ts:195-215`
  - `sacdia-backend/src/camporee-events/camporee-events.service.ts:790-808`
- **Evidencia:** el guard autoriza el camporee destino, pero `createFromTemplate()` busca cualquier template activo por `templateId` sin aplicar `buildVisibilityWhere()`/`assertTemplateVisible()`.
- **Impacto:** un usuario con permiso sobre su camporee puede adivinar un ID incremental y copiar contenido, rúbricas y reglas de un template de otro campo local o unión.
- **Corrección:** pasar el snapshot de autorización al servicio y resolver el template con la misma política usada por `getTemplate()`; responder 404 para templates fuera de alcance.
- **Falso positivo:** sólo sería aceptable si todos los templates fueran globales. El modelo y la documentación los declaran por scope.

### CAMP-SEC-004 — Alta — IDs secundarios no se validan contra el scope autorizado

- **Ubicación:**
  - `sacdia-backend/src/camporee-events/camporee-events.service.ts:230-247`
  - `sacdia-backend/src/camporee-events/camporee-events.service.ts:669-757`
  - `sacdia-backend/src/camporees/camporees.service.ts:1145-1217`
  - `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:945-1006`
- **Evidencia:** `validateLeader()` es no-op; `venue_id` no se valida contra el camporee; `enrollClub()` acepta cualquier `club_section_id` existente; la asignación de juez acepta un `camporee_club_id` suministrado aunque ya resolvió el enrollment autoritativo.
- **Impacto:** referencias cross-tenant, exposición de nombres de usuarios/sedes y contaminación de participantes, asignaciones y ranking con secciones de otro territorio.
- **Corrección:** validar toda FK secundaria contra el camporee y el alcance del actor. Derivar `camporee_club_id` desde `club_section_id`; no aceptar ambos como autoridades independientes.

### CAMP-SEC-005 — Alta — Captura manual autorizada más ampliamente que la regla de negocio

- **Ubicación:** `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:670-688`
- **Evidencia:** `canSubmitManualScore()` permite cualquier actor con `camporee_events:update`, además de `assistant-lf`, `director-lf` y admins.
- **Impacto:** un rol futuro o actual con permiso de edición de eventos podría registrar o reemplazar puntajes oficiales sin ser Campo Local.
- **Corrección:** separar `camporee_scores:submit_manual`/`camporee_scores:override` o exigir explícitamente los roles autorizados; el permiso genérico de editar eventos no debe implicar editar resultados.
- **Falso positivo:** revisar el mapping actual de permisos, pero mantener la separación evita que una futura reasignación de permisos abra scoring accidentalmente.

### CAMP-FLOW-006 — Alta — Cierre, admisión tardía y penalizaciones se contradicen

- **Ubicación:**
  - `sacdia-backend/src/camporees/camporees.service.ts:1004-1133`
  - `sacdia-backend/src/camporees/camporees.service.ts:1145-1217`
  - `sacdia-backend/src/camporees/camporee-late-approvals.service.ts:13-40`
- **Evidencia:** la fecha límite sólo convierte nuevas solicitudes en `pending_approval`; no cierra automáticamente. Si se usa el cierre explícito, el alta y también la aprobación tardía del club se bloquean. No existe configuración ni snapshot de penalización tardía.
- **Impacto:** el flujo solicitado de “cerrar por fecha y permitir excepción por Campo Local con penalización” no puede ejecutarse.
- **Corrección:** estado efectivo calculado por deadline, endpoint privilegiado de admisión tardía posterior al cierre y una regla de penalización versionada/aplicada con auditoría.

### CAMP-FLOW-007 — Alta — La app deja al juez en una tarea ya cerrada

- **Ubicación:**
  - `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:1418-1440`
  - `sacdia-app/lib/features/camporees/presentation/providers/camporees_providers.dart:743-768`
  - `sacdia-app/lib/features/camporees/presentation/views/judge_score_entry_view.dart:85-119`
- **Evidencia:** después de enviar, la app invalida la bandeja, pero el backend continúa devolviendo la asignación activa con `can_submit_score=true`. La pantalla de captura no se cierra ni deshabilita permanentemente.
- **Impacto:** el juez ve la misma tarea y puede reintentar; el segundo envío termina en conflicto backend. Esto parece pérdida de datos o error del sistema.
- **Corrección:** devolver `submission_state/can_submit_score` basado en resultado activo, retirar tareas completadas o marcarlas “calificada”, mostrar confirmación irreversible y navegar a comprobante/resultado tras éxito.

### CAMP-FLOW-008 — Alta — Funciones requeridas no están conectadas a admin/app

- **Ubicación:**
  - `sacdia-admin/src/lib/api/camporee-scoring.ts:99-107`
  - `sacdia-admin/src/components/camporee-scoring/event-score-entry-panel.tsx:148-239`
  - `sacdia-app/lib/features/camporees/domain/entities/camporee_score_submission.dart:26-41`
  - `sacdia-app/lib/features/camporees/presentation/views/judge_assignments_view.dart:16-63`
- **Evidencia:** los clientes no modelan `no_show`; no existe vista de detalle de resultado/comentarios para director/subdirector; tampoco existe el flujo “director ausente → habilitar subdirector”. La ruta móvil de juez está registrada, pero una búsqueda de call sites no encontró navegación visible hacia la bandeja.
- **Impacto:** el backend Batch 1 no es utilizable por el usuario final y el circuito de transparencia para el club queda incompleto.
- **Corrección:** agregar no-show, detalle de resultado/comentarios, presencia/representante del club y acceso descubrible por capability, no sólo por rol visual.

### CAMP-INTEGRITY-009 — Media — El total oficial puede no coincidir con la suma de los ítems

- **Ubicación:** `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:1185-1297`
- **Evidencia:** si el total bruto es menor al mínimo, `total_awarded_points` se eleva, pero los ítems se persisten con los valores originales.
- **Impacto:** auditoría y aclaraciones muestran ítems que suman distinto al resultado oficial; no queda un campo explícito de ajuste aplicado.
- **Corrección:** guardar `raw_total`, `adjustment_amount`, `adjustment_reason` y `official_total`, o definir una regla determinista para reflejar el ajuste sin alterar la evaluación original.

### CAMP-FLOW-010 — Media — Ajustes de jueces y tipos de evento quedan inconsistentes

- **Ubicación:**
  - `sacdia-admin/src/components/camporee-scoring/event-judge-assignments-panel.tsx:75-191`
  - `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:945-1009`
- **Evidencia:** el panel sólo agrega y lista; no ofrece promover, degradar o desactivar aunque existen actions. Además permite seleccionar cualquier evento y el backend no exige `scoring_enabled` al asignar.
- **Impacto:** no se pueden hacer los ajustes operativos solicitados. Una asignación a evento no puntuable queda invisible en app y puede bloquear la reapertura de inscripciones.
- **Corrección:** limitar a eventos puntuables y exponer reemplazo controlado del principal, ayudantes y desactivación con historial.

### CAMP-FLOW-011 — Media — El formulario no representa el evento general requerido

- **Ubicación:**
  - `sacdia-admin/src/components/camporee-events/event-form-page.tsx:327-718`
  - `sacdia-admin/src/lib/camporee-events/actions.ts:620-663`
  - `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/events/new/page.tsx:121-124`
- **Evidencia:** faltan requisitos, desarrollo, materiales, auxiliares, mínimo, penalizaciones y hasta cinco PDFs. `buildAgendaPayload()` hardcodea `min_points=0`, `penalties=[]` y participantes. El selector de responsable recibe `users=[]`.
- **Impacto:** datos solicitados se pierden o no se pueden capturar; el evento queda dependiente de edición técnica/API.
- **Corrección:** separar “definición del evento” de “agenda operativa” sin perder campos, y agregar archivos PDF con validación server-side de MIME real, tamaño, conteo, nombre generado y storage privado.

### CAMP-PERF-012 — Media — Fan-out de peticiones y errores silenciosos en el detalle admin

- **Ubicación:** `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/page.tsx:328-395` y equivalente de unión.
- **Evidencia:** por hasta 100 eventos se disparan listas de asignaciones, targets y rúbricas con `Promise.allSettled`; los fallos se convierten en arreglos vacíos sin alerta.
- **Impacto:** cientos de requests por carga, presión sobre API/DB y UI que confunde “falló” con “no hay datos”.
- **Corrección:** endpoint agregado de configuración/scoring o carga lazy por evento/tab; mostrar estado de error por panel.

### CAMP-FLOW-013 — Media — El redirect a Eventos no abre la pestaña Eventos

- **Ubicación:** `sacdia-admin/src/components/camporees/camporee-detail-tabs.tsx:142-197`
- **Evidencia:** las actions redirigen con `?tab=events`, pero `Tabs` usa siempre `defaultValue="info"` y no consume el query param.
- **Impacto:** después de crear/editar un evento el usuario vuelve a Información y parece que la operación no ocurrió.
- **Corrección:** derivar la pestaña inicial del search param y mantenerla en navegación.

### CAMP-SEC-014 — Media — Un juez asignado ve targets de todo el evento

- **Ubicación:** `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts:1304-1346`
- **Evidencia:** basta cualquier asignación activa en el evento para devolver todas las secciones inscritas.
- **Impacto:** exposición innecesaria de participantes y estado; aumenta el riesgo de seleccionar el club equivocado aunque el submit exacto sí se valida.
- **Corrección:** para jueces, filtrar sólo sus secciones; mantener vista completa sólo para gestores autorizados.

### CAMP-DATA-015 — Media — Fechas relacionadas sólo validan formato

- **Ubicación:** `sacdia-backend/src/camporees/camporees.service.ts:171-244` y `:435-555`
- **Evidencia:** se persisten inicio, fin, deadlines y apertura de agenda sin validar su orden relativo.
- **Impacto:** camporee con fin anterior al inicio, deadlines posteriores al evento o agenda incoherente; rompe automatización, visualización por día y reglas de cierre.
- **Corrección:** validador de dominio compartido para create/update local y unión, evaluando valores finales después del merge parcial.

### SUPPLY-SEC-016 — Crítica/Alta — Dependencias con advisories conocidos

- **Ubicación:**
  - `sacdia-admin/package.json` y `pnpm-lock.yaml`: `next@16.2.4`, `form-data@4.0.5`, `vite@7.3.3`, `ws@8.20.0`, `xlsx@0.18.5`.
  - `sacdia-backend/package.json` y `pnpm-lock.yaml`: `better-auth@1.6.13` arrastra `next@15.1.2`; `xlsx@0.18.5`, `form-data@4.0.5`.
- **Evidencia:** `pnpm audit --audit-level=high` reportó advisories críticos/altos; en admin el resumen fue 46 vulnerabilidades (`1 critical`, `24 high`, `16 moderate`, `5 low`).
- **Impacto:** potencial RCE/bypass/DoS según paquete y ruta alcanzable. No se confirmó explotabilidad desde el módulo de camporee.
- **Corrección:** triage por reachability y actualización controlada; priorizar Next admin a versión parcheada, revisar por qué Better Auth instala Next en backend y aislar/reemplazar `xlsx` si no existe parche compatible.
- **Falso positivo:** dependencias de tooling o adapters no importados pueden no ser alcanzables en producción; el advisory sigue requiriendo decisión documentada.

## Controles correctos observados

- JWT y autorización server-side protegen las rutas; la UI no es la única barrera.
- Índices parciales de PostgreSQL mantienen un único juez principal y un resultado activo por evento/sección.
- El backend vuelve a validar elegibilidad del juez, máximos por rúbrica y enrollment de la sección.
- El ranking usa resultados oficiales activos, no asistencia/inscripción.
- Las queries de leaderboard usan tagged templates de Prisma, no concatenación SQL insegura.
- No se encontraron sinks DOM XSS (`dangerouslySetInnerHTML`, `eval`, `innerHTML`) en las superficies admin de camporee inspeccionadas.

## Verificaciones ejecutadas

- Backend: 3 suites, 65 tests, todos aprobados.
- Admin: 5 archivos, 12 tests, todos aprobados.
- Admin: `tsc --noEmit` aprobado.
- App: 20 tests focalizados, todos aprobados.
- `flutter analyze lib/features/camporees`: sin issues.
- `pnpm audit --audit-level=high`: falló el gate por vulnerabilidades conocidas.
- No se ejecutaron builds.

## Límites de la revisión

- La revisión de flujo fue estática; no se realizó recorrido visual autenticado ni prueba E2E real con base de datos.
- No se aplicó la migración Batch 1 a una base de datos durante esta revisión.
- El resultado de `pnpm audit` requiere confirmar reachability y entorno de producción antes de asignar explotabilidad definitiva.
