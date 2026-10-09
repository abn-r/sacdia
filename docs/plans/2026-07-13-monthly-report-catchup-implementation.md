# Monthly Report Catch-up Implementation Plan

**Estado:** decisión aprobada e implementación alineada con el contrato final.

**Objetivo:** reconciliar diariamente todos los períodos mensuales vencidos de una matrícula activa y calcular `monthly_reports_timeliness` desde la primera captura manual a tiempo.

**Arquitectura:** `runAutoGeneration()` es un reconciliador acotado por el año eclesiástico. Generación y scoring comparten `reports.auto_generate_day` —o fallback `5`— para construir el deadline del mes siguiente a las 23:00 UTC. El scoring no depende de entrega formal.

**Stack:** NestJS, TypeScript, Prisma, PostgreSQL y Jest.

---

## 1. Catch-up automático

**Archivos backend:**

- `src/monthly-reports/monthly-reports.service.ts`
- `src/monthly-reports/monthly-reports.service.spec.ts`

Resultado final:

1. `reports.auto_generate_enabled` permanece como kill switch con seed `true`.
2. `reports.auto_generate_day` acepta `1..28`; ausencia o valor inválido usa fallback `5`.
3. Cada ejecución diaria enumera los meses del año eclesiástico de cada matrícula activa y procesa solo deadlines vencidos.
4. `getOrCreateDraft()` usa upsert; `generate()` aplica compare-and-set de `draft` a `generated`.
5. `generated` y `submitted` se omiten, y los errores se aíslan por período.
6. Snapshots sin datos conservan `0` y `[]`; el sistema no crea captura manual artificial ni cambia a `submitted`.

## 2. Scoring por primera captura manual

**Archivos backend:**

- `src/annual-folders/score-calculators/monthly-reports-timeliness-score.ts`
- `src/annual-folders/score-calculators/monthly-reports-timeliness-score.spec.ts`

Resultado final:

1. Los meses esperados salen de `ecclesiastical_years.start_date/end_date`.
2. El denominador cuenta solo meses con `deadline_at <= CURRENT_TIMESTAMP`.
3. Un mes suma si existe `monthly_report_manual_data` con `created_at >= period_start_at` y `created_at < deadline_at`.
4. La consulta no usa estado, marca temporal de envío, campos de contenido ni `snapshot_data`.
5. Captura ausente o tardía aporta `0`; meses abiertos o futuros no penalizan.
6. El porcentaje queda normalizado entre `0` y `100`.

## 3. Guardas del PATCH manual

**Archivos backend:**

- `src/monthly-reports/dto/update-manual-data.dto.ts`
- `src/monthly-reports/monthly-reports.service.ts`
- `src/common/errors/error-codes.ts`
- `src/i18n/en/errors.json`
- `src/i18n/es/errors.json`

Resultado final:

1. Los campos `undefined` se excluyen antes de persistir.
2. Payload vacío o creación compuesta solo por textos `null`, blank o whitespace retorna `MONTHLY_REPORT_MANUAL_DATA_REQUIRED`.
3. `null` en numéricos o booleanos retorna `MONTHLY_REPORT_INVALID_MANUAL_DATA`.
4. `0` y `false` son capturas válidas.
5. Los textos nullable aceptan `null` para limpiar una fila existente.

## 4. Documentación sincronizada

- `docs/features/monthly-reports.md`
- `docs/features/cron-automation.md`
- `docs/canon/runtime-rankings.md`
- `docs/features/annual-folders-scoring.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`

La documentación separa catch-up, recordatorios legacy, captura manual y envío formal; además documenta ambos errores estables del PATCH sin cambiar el shape de otros endpoints.

## 5. Pruebas finales

Cobertura focalizada:

- catch-up de varios meses, rango eclesiástico, rollover UTC, cutoff 23:00, fallback `5`, kill switch, idempotencia y error aislado;
- scoring de primera captura manual, exclusión de meses abiertos, límites inclusivo/exclusivo e independencia de estado, envío, contenido y snapshot;
- PATCH vacío/undefined, textos null/blank/whitespace, null numérico/booleano, `0`, `false` y limpieza nullable existente;
- delegación y reintentos del processor BullMQ.

Comando de verificación focalizada, sin build:

```bash
pnpm exec jest --runInBand \
  src/monthly-reports/monthly-reports.service.spec.ts \
  src/annual-folders/score-calculators/monthly-reports-timeliness-score.spec.ts \
  src/background-jobs/__tests__/background-jobs.processor.monthly-reports.spec.ts
```

Validación documental final:

```bash
git diff --check
rg -n 'ranking\.monthly_report_deadline_day|default[[:space:]]+false' \
  docs/plans/2026-07-13-monthly-report-catchup-design.md \
  docs/plans/2026-07-13-monthly-report-catchup-implementation.md \
  docs/features/monthly-reports.md \
  docs/features/cron-automation.md \
  docs/canon/runtime-rankings.md \
  docs/features/annual-folders-scoring.md \
  docs/api/ENDPOINTS-LIVE-REFERENCE.md
```
