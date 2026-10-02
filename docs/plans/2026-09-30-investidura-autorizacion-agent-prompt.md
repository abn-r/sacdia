# Prompt para el agente implementador — investidura por autorización

Implementa el plan completo de investidura por autorización de SACDIA, no únicamente la validación de certificados:

`/Users/abner/Documents/development/sacdia/docs/plans/2026-09-28-investidura-autorizacion.md`

Lee la versión local completa, incluidas las reglas IA-01 a IA-56, la fase 0B y las exclusiones. El plan tiene acuerdos hasta el 2026-09-30 y todavía no equivale a una implementación. Entrega código, pruebas, documentación y evidencia para que otro agente revise tu trabajo. No te limites a reformular el plan.

## 1. Preparación y límites

- Trabaja desde `/Users/abner/Documents/development/sacdia`. Lee su `AGENTS.md`, la lectura mínima que exige y los adaptadores `AGENTS.md`/`CLAUDE.md` de cada repositorio afectado. Consulta Engram y usa Graft antes de explorar código, conforme a las instrucciones del workspace.
- Registra ruta, rama, SHA inicial y cambios preexistentes de cada repositorio afectado, incluido el repositorio de documentación. No reviertas ni atribuyas a tu trabajo cambios de otras personas/agentes. La versión local del plan puede contener acuerdos todavía no commiteados: consérvalos y no los pierdas al usar otro checkout.
- Verifica el código actual: los hallazgos del plan son antecedentes, no permiso para asumir que todo sigue igual. Si algo ya está implementado, compruébalo y evita duplicarlo.
- Sigue un orden contract-first: contratos backend, permisos, errores y consistencia de datos antes de integrar app y panel. Desglosa el trabajo en bloques pequeños y verificables siguiendo las fases del plan.
- Usa las skills de ejecución de planes, TDD, seguridad/API y verificación que correspondan. No invoques un proceso SDD distinto por iniciativa propia si introduce decisiones o artefactos no pedidos.
- Nunca ejecutes builds. Sí ejecuta tests, lint, análisis estático y comprobaciones de tipos pertinentes, comprobando antes que los scripts no encadenen un build. No hagas commits, push, PR ni despliegues sin una petición adicional. No toques secretos ni archivos `.env` reales.
- Prepara y prueba migraciones solo en una base de pruebas aislada y verificada. No ejecutes migraciones, correcciones masivas, borrados ni consultas de datos personales de producción por iniciativa propia. Prueba correos con transporte simulado o entorno de pruebas, nunca con destinatarios reales.
- No inventes decisiones funcionales. Si aparece una ambigüedad que bloquea la implementación, presenta una sola pregunta concreta y espera. No amplíes el alcance ni reescribas el plan para que coincida con una implementación incompleta.

## 2. Skills de UI obligatorias

Lee y utiliza expresamente estas tres skills, indicando después dónde las aplicaste:

1. `$emil-design-eng`: `/Users/abner/.agents/skills/emil-design-eng/SKILL.md`.
   Aplica claridad, respuesta inmediata, estados consistentes y movimiento con propósito. En la revisión de UI entrega la tabla requerida `Before | After | Why`, con referencias de archivos y líneas.
2. `$improve-animations`: `/Users/abner/.agents/skills/improve-animations/SKILL.md`.
   Úsala para una auditoría focalizada de las pantallas afectadas, no para auditar o rediseñar toda la aplicación. Lee sus referencias `AUDIT.md` y `PLAN-TEMPLATE.md` cuando corresponda. Respeta su modalidad de solo lectura del código: separa auditoría/planes de la ejecución; si ejecutas un plan de animación, usa el mecanismo de ejecución previsto por la skill. No inventes defectos ni agregues animaciones para justificar su uso. Las mejoras fuera del alcance quedan como recomendaciones, no como cambios.
3. `$app-ui-design`: `/Users/abner/.agents/skills/app-ui-design/SKILL.md`.
   Aplica accesibilidad, tamaños táctiles, semántica, escalado de texto y adaptación iOS/Android en la app Flutter existente. No cambies de framework ni crees un sistema visual paralelo.

Reutiliza tokens, componentes y patrones del proyecto. Limita el admin a los cambios funcionales y de integración necesarios; respeta el ownership del workspace y no hagas un rediseño visual general. Las skills de diseño no autorizan a alterar reglas de negocio. No muestres éxito ni celebraciones antes de la confirmación del backend. Respeta movimiento reducido, navegación por teclado y estados de carga, vacío, error, sin permiso, pendiente, resolución parcial y año/ventana cerrados. Si no puedes observar la UI ejecutándose sin infringir la prohibición de builds, declara esa verificación pendiente: no inventes evidencia visual.

## 3. Consideraciones funcionales que no debes perder

Esta lista destaca riesgos; NO sustituye ninguna regla del plan:

- Una solicitud pertenece a una sola sección. Todos los permisos y filtros territoriales se hacen cumplir en backend, no solo ocultando botones. Editar fechas no otorga autorización de investidura.
- Conserva los límites de solicitudes activas, la excepción GM sin ampliar inscripciones, el cambio de fecha solo sobre pendientes seleccionados y el bloqueo de progreso/evidencias por enrollment.
- La primera resolución confirmada prevalece. Protege carreras con alta, autorización, rechazo, retiro y cierre anual; actualiza solicitud, enrollment y auditoría atómicamente. Protege también eventos, logros y comunicaciones frente a reintentos.
- El porcentaje y los requisitos deben coincidir entre detalle, listado colectivo y elegibilidad. No cambies la escala de notas ni la duración de las clases.
- Distingue ventana del Campo y cierre del año: la primera puede ampliarse dentro del año abierto; lo pendiente al terminar el año queda no investido y nunca se arrastra. Integra ambos caminos de cierre, manual y automático, sin sustituir la política anual existente. No restaures el plazo individual de siete días.
- Respeta exactamente IA-23 y su aclaración: el 10 de diciembre es un ejemplo de configuración, no una sustitución silenciosa del valor por defecto documentado.
- Recordatorios por correo a las 10:00 locales del Campo: pastor lunes/miércoles/viernes; director/asistente del Campo solo lunes, con todos los pendientes acumulados. Continúan con ventana cerrada, pero no después del cierre/fin del año. Dos roles destinatarios en la misma cuenta producen dos recordatorios el lunes; los reintentos del mismo rol no duplican envíos. Admin/super-admin no reciben recordatorios por esos roles.
- No confundas recordatorios con correos iniciales ni con las notificaciones de resultado existentes en la app. Preserva los textos cerrados y la privacidad de los motivos. Conserva `class.completed` y la evaluación de logros al confirmar investidura, no al solicitarla.
- Implementa la fase 0B antes de habilitar el nuevo flujo: edad al inicio del año eclesiástico acreditado frente al mínimo de la clase. Valida listo/envío/reenvío y aprobación individual/masiva en backend. Faltantes bloquean; OCR solo prepara un borrador. No uses edad actual, no prohíbas indiscriminadamente certificados de la clase actual y no reescribas historial ya acreditado.
- Regresión obligatoria: nacido el 01/01/2016, Amigo con mínimo 10, ciclos iniciados el 01/01; certificado de 2025 rechazado aunque tenga 10 en 2026. No crea un histórico investido, no modifica el pendiente de 2026 ni concede logros. Cubre también certificados válidos, límites de cumpleaños, datos modificados tras envío y ausencia de efectos parciales.
- Retira todas las rutas operativas alternativas del pipeline anterior, incluidos aliases y operaciones masivas, sin perder la lectura histórica. No cierres ni migres expedientes antiguos automáticamente: su tratamiento requiere el inventario y aprobación previstos en la fase 8. Si no hay evidencia suficiente para resolver esa condición, declara el despliegue bloqueado; no supongas que producción está vacía.

## 4. Pruebas y documentación

Comienza las correcciones con pruebas que reproduzcan el fallo; registra evidencia del fallo esperado y de su corrección. Ejecuta las suites pertinentes y regresiones de los módulos afectados, no solo los tests nuevos. Usa reloj controlado para fechas y programación.

Prueba las restricciones y carreras relevantes con PostgreSQL aislado cuando dependan de transacciones o constraints: los mocks no demuestran esas garantías. Cubre bypass por API, acceso entre secciones/Campos, doble envío, dos autorizadores, resolución parcial, reintentos, zonas horarias, cierre retrasado y convivencia de los dos caminos de cierre. Verifica los contratos entre backend, app y admin. Si una prueba no puede ejecutarse, registra motivo e impacto; no la marques aprobada.

Actualiza la documentación canónica de API, datos y features junto con cada cambio de comportamiento, conforme a la fase 9. Documenta migraciones, compatibilidad, orden de activación entre repositorios, programación de jobs y procedimiento seguro de reversión. No des por cumplido un job solo porque su clase existe: comprueba su registro y ejecución controlada.

## 5. Salida obligatoria para revisión independiente

Guarda el informe en:

`/Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-implementation-report.md`

Si trabajas en otro checkout autorizado, usa la ubicación equivalente y devuelve su ruta absoluta real. El informe debe contener:

### A. Estado y alcance

- Estado de implementación: `COMPLETO`, `PARCIAL` o `BLOQUEADO`, con fundamento. Separar explícitamente implementación, verificación y preparación para despliegue.
- Fases terminadas y pendientes. No declarar completo el plan si solo se implementó backend, certificados o un subconjunto de pantallas.
- Desviaciones respecto del plan, decisiones adicionales y aprobación que las respalda; riesgos y bloqueantes sin resolver.

### B. Código revisable

- Tabla por repositorio: ruta absoluta, rama/worktree, SHA base inicial, SHA final y estado del árbol de trabajo.
- Inventario de archivos creados/modificados/eliminados y propósito, distinguiendo cambios preexistentes.
- Referencias exactas para revisar el diff: rango de commits si existen, más cambios sin commit y archivos nuevos no rastreados. No hagas commits solo para producir el informe. Si el revisor no comparte filesystem, entrega parches atribuibles a este trabajo que incluyan archivos nuevos, sin secretos ni cambios ajenos.

### C. Matriz de trazabilidad completa

Una fila por cada regla IA-01 a IA-56:

`Regla | Estado | Implementación (archivo:línea) | Prueba/caso | Evidencia o pendiente`

No uses «no aplica» para omitir trabajo incluido. Distingue las partes expresamente fuera de alcance, como las máquinas de estados de unidades/finanzas, de los requisitos que sí debes implementar.

### D. Verificación reproducible

- Por comando: directorio, comando exacto, resultado, código de salida, número de pruebas y ruta al log sanitizado.
- Distingue pruebas unitarias con mocks, integración con base real aislada, contratos y UI. Incluye evidencia red/green de la regresión de certificados y resultados de concurrencia/idempotencia.
- Lista fallos preexistentes, introducidos y verificaciones no ejecutadas por separado. Indica expresamente que no se ejecutaron builds.

### E. Contratos, datos y operación

- Endpoints/DTOs/errores/permisos modificados; migraciones y constraints; documentos canónicos actualizados.
- Estado de migraciones: creadas, probadas en entorno aislado y NO aplicadas a producción, según corresponda.
- Configuración/jobs requeridos, orden de activación, reversión y condición pendiente de transición de expedientes antiguos. Sin credenciales ni datos personales.

### F. UI y skills

- Skills leídas, cómo se aplicaron y archivos afectados; auditoría focalizada de movimiento y tabla `Before | After | Why`.
- Capturas reales de estados relevantes con datos sintéticos y rutas absolutas, indicando plataforma y entorno. Para animaciones, grabación o comprobación observable cuando esté disponible.
- Evidencia de accesibilidad, texto ampliado y movimiento reducido. Lo inspeccionado solo en código debe etiquetarse como tal, no como validación visual o en dispositivo.

### G. Guía para el revisor

- Pasos reproducibles y fixtures para probar los casos críticos sin acceder a producción.
- Archivos/zonas de mayor riesgo y límites conocidos de las pruebas.
- Siguiente acción concreta para cada pendiente.

En tu respuesta final devuelve: estado, ruta del informe, ubicaciones de código/diffs, resumen de pruebas y bloqueantes. El informe facilita la revisión, pero no reemplaza el acceso al código y la evidencia. No declares el resultado aprobado por otro agente: la revisión independiente aún estará pendiente.
