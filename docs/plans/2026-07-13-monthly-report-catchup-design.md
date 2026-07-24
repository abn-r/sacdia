# Monthly Report Catch-up Design

## Resultado aprobado

La generación automática funciona como reconciliación diaria de períodos vencidos. El KPI `monthly_reports_timeliness` mide la primera captura manual dentro de la ventana del período; no depende del estado, de la marca temporal de envío, del contenido capturado ni del snapshot.

## Problema resuelto

La generación anterior solo procesaba el mes previo cuando la ejecución coincidía exactamente con el día configurado. Si el cron o BullMQ fallaban ese día, los períodos vencidos quedaban en `draft` o sin crear. Además, el scoring usaba la entrega formal como proxy de puntualidad, aunque la señal institucional requerida es que el club haya iniciado su captura manual a tiempo.

## Decisiones aprobadas

- El backend sigue siendo la autoridad del estado; la app móvil no infiere cierres ni genera reportes.
- `reports.auto_generate_enabled` se conserva como kill switch y su seed vigente es `true`.
- `reports.auto_generate_day` acepta `1..28`; si está ausente o es inválido, generación y scoring usan fallback `5`. La seed vigente es `5`.
- El deadline de un período es a las `23:00:00 UTC` del día configurado del mes siguiente.
- Cada ejecución revisa todos los períodos vencidos de cada matrícula activa, desde el mes de inicio de su año eclesiástico hasta el menor entre el mes anterior a la ejecución y el mes de cierre del año.
- Los estados se precargan en lotes; solo los períodos faltantes —o el fallback individual de una precarga fallida— ejecutan `getOrCreateDraft()`/upsert. Un `draft` precargado pasa directamente a `generate()` mediante compare-and-set.
- Los estados `generated` y `submitted` no se reabren. La auto-generación termina en `generated`, nunca en `submitted`.
- Un snapshot sin actividad conserva `0` y `[]`; no se crea una fila manual artificial.
- Los recordatorios 27/1/4/5/6 son un flujo legacy separado: no definen ni recalculan el deadline.

## Flujo de catch-up

1. El cron se activa diariamente a las 23:00 UTC y encola el job.
2. `runAutoGeneration(now)` valida el kill switch y resuelve el día configurado o fallback `5`.
3. Consulta matrículas `active` con `ecclesiastical_year.start_date/end_date`.
4. Enumera los meses del año eclesiástico y conserva solo aquellos cuyo deadline ya ocurrió.
5. Precarga los estados existentes en lotes de `500` y omite cualquier reporte con estado distinto de `draft`.
6. Solo los períodos faltantes llaman `getOrCreateDraft()`/upsert; si falla la precarga de un lote, sus períodos usan ese mismo fallback individual.
7. Genera los borradores mediante compare-and-set.
8. Un error de un período se registra y no aborta los demás; la siguiente ejecución reintenta lo pendiente.

## Scoring por primera captura manual

Para cada mes del año eclesiástico se calculan:

- `period_start_at`: primer día del mes reportado a las `00:00:00 UTC`;
- `deadline_at`: día configurado del mes siguiente a las `23:00:00 UTC`.

El denominador incluye únicamente meses con `deadline_at <= CURRENT_TIMESTAMP`. Un mes futuro o todavía abierto no suma al denominador ni penaliza.

Un mes aporta al numerador si existe su fila única de `monthly_report_manual_data` y `created_at` está en el intervalo semiabierto `[period_start_at, deadline_at)`. La ausencia de la fila o una primera captura tardía aporta `0`.

El cálculo no inspecciona el estado del reporte, la marca temporal de envío, valores `0`/`false`/`null` ni `snapshot_data`. Por tanto, no exige `submit` y no aplica una segunda penalización por contenido.

## Contrato de captura manual

`PATCH /api/v1/monthly-reports/:reportId/manual-data` conserva solo campos distintos de `undefined`:

- payload técnico vacío, o creación formada únicamente por textos `null`, blank o whitespace: `MONTHLY_REPORT_MANUAL_DATA_REQUIRED`;
- `null` en campos numéricos o booleanos: `MONTHLY_REPORT_INVALID_MANUAL_DATA`;
- `0` y `false` explícitos: valores válidos y suficientes para crear la primera captura;
- textos nullable con `null`: válidos para limpiar una fila manual existente.

## Pruebas finales cubiertas

- Catch-up de varios meses, límites del año eclesiástico y rollover diciembre/enero.
- Deadline del mes siguiente a las 23:00 UTC, fallback `5`, kill switch e idempotencia upsert/CAS.
- Continuación después de un error individual.
- Denominador limitado a deadlines vencidos y ventana manual `[period_start_at, deadline_at)`.
- Independencia del estado, la marca temporal de envío, el contenido manual y el snapshot.
- Rechazo de payload manual vacío/null inválido; aceptación de `0`, `false` y limpieza nullable existente.

## Fuera de alcance

No se agrega endpoint bulk, migración, cambio de schema, nuevo estado ni requisito de `submit` en la app. La reparación histórica ocurre mediante la siguiente ejecución normal con el kill switch habilitado.
