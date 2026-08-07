# Backfill de artefactos PDF de informes mensuales

**Estado**: ACTIVE
**Alcance**: operación puntual para reparar artefactos históricos de `monthly_reports`.

## Objetivo

Crear o reparar el PDF canónico privado de los informes en estado `generated` o
`submitted` cuando `pdf_r2_key` sea nulo o la plantilla almacenada no sea
`monthly-report-v2-three-page`. El proceso es idempotente: reutiliza
`MonthlyReportArtifactsService`, la clave `year/month/enrollmentId/reportId.pdf`
y la semántica de sobrescritura de R2.

## Precondiciones

1. Confirmar que la migración de `monthly_reports` con las columnas de metadata
   ya está aplicada en el entorno objetivo.
2. Confirmar que `R2_BUCKET_MONTHLY_REPORTS`,
   `R2_PUBLIC_URL_MONTHLY_REPORTS` y `R2_KEY_PREFIX_MONTHLY_REPORTS` están
   configuradas en el runtime. El bucket debe ser privado y el acceso debe
   hacerse mediante URLs firmadas generadas por el backend.
3. Verificar conectividad de base de datos y R2 en staging primero. No copiar
   credenciales a comandos, logs o tickets.
4. Verificar que el renderer puede operar con los datos históricos disponibles.
   Valores ausentes deben quedar vacíos; no completar datos por inferencia.
5. Tener una ventana operativa, un responsable y un plan de observabilidad. El
   backfill no forma parte del arranque de Nest ni de un cron de aplicación.

## Dry-run obligatorio

El modo seguro es el default, pero conviene declararlo explícitamente:

```bash
pnpm reports:backfill-pdfs -- --dry-run --batch-size 25 --limit 100
```

Revisar:

- cantidad de candidatos seleccionados;
- IDs de informe y cursor de continuación;
- que ningún objeto R2 sea subido y ninguna fila sea actualizada;
- errores de lectura o de configuración antes de autorizar escrituras.

El selector sólo incluye `generated|submitted` y exige metadata faltante o una
versión de plantilla distinta de la actual. Los informes `draft` se excluyen.

## Apply explícito y acotado

El modo de escritura **requiere** `--apply`; nunca se debe omitir el límite en
la primera ejecución:

```bash
pnpm reports:backfill-pdfs -- --apply --batch-size 10 --limit 1
```

Verificar en la base y mediante `GET /api/v1/monthly-reports/:reportId/pdf` que
el objeto sea privado, descargable con `reports:download`, tenga tamaño y hash
consistentes, y conserve el mismo estado y snapshot del informe.

Para continuar una ejecución, usar el cursor impreso por el resumen:

```bash
pnpm reports:backfill-pdfs -- --apply \
  --batch-size 25 --limit 100 \
  --cursor <monthly_report_id>
```

El cursor ordena por `monthly_report_id` ascendente y usa `skip: 1` para no
reprocesar el último registro confirmado. Un `SIGINT` termina el informe en
curso, imprime el último cursor y detiene el lote sin iniciar otro registro.

## Observabilidad

El proceso registra sólo:

- `reportId`;
- clave R2 canónica;
- versión de plantilla;
- tamaño en bytes;
- prefijo del SHA-256 (no el contenido, URL firmada ni credenciales);
- contadores `selected`, `processed`, `generated`, `skipped`, `failed` y
  `nextCursor`.

Cada fallo se registra por informe y no detiene los siguientes. Guardar la
salida del comando en el registro operativo aprobado, sin incluir variables de
entorno.

## Reintento y rollback

- Es seguro repetir el mismo rango: los candidatos que ya tienen metadata y
  plantilla vigente dejan de ser seleccionados; una reparación vuelve a usar la
  misma clave y sobrescribe el objeto de forma controlada.
- Si hay fallos de R2 o de renderer, detener la ejecución, conservar el cursor
  y corregir la causa antes de reintentar.
- No existe rollback destructivo del snapshot: el script no cambia
  `snapshot_data`, estado, submitter ni timestamps de transición. Para retirar
  un objeto incorrecto, usar el procedimiento de storage aprobado y corregir
  metadata mediante una operación auditada; no ejecutar SQL manual en
  producción.
- No ejecutar backfills masivos en producción sin validación de staging,
  aprobación del responsable y monitoreo de errores.

## Bloqueo conocido

Si faltan los SVG oficiales de marca, registrar ese bloqueo puntual y continuar
con el backfill que no dependa de logos. No generar ni subir logotipos
alternativos.
