# Candidato importable de reglas de maestrías

Estado: **aplicado en base de datos y recálculo ejecutado**.

## Resumen
- Archivo JSON: `/Users/abner/Documents/development/sacdia/docs/working/master-honor-rules/import-candidate.json`
- Maestrías incluidas: **17**
- Maestrías pendientes: **3**
- Especialidades diferidas por no existir en catálogo: **6**
- Opciones con equivalencias/avanzadas incluidas con IDs existentes: **38**

## Criterio aplicado
- No se alteraron mínimos oficiales.
- Las especialidades sin `honor_id` existente se omitieron y quedaron registradas como diferidas.
- Si al omitir faltantes un grupo quedaba imposible de cumplir, la maestría completa quedó pendiente.
- Se conservaron `name` y `master_image` actuales para maestrías existentes, evitando renombres o borrado accidental de imágenes durante el import.

## Maestrías incluidas
- `2` Maestría en Acuática — grupos: 1, opciones explícitas: 14
- `3` Maestría en ADRA — grupos: 2, opciones explícitas: 5
- `1` Maestría en Actividades Agrícolas (fuente: Maestría en Actividades agrícolas) — grupos: 1, opciones explícitas: 0
- `4` Maestría en Artesanía — grupos: 1, opciones explícitas: 0
- `5` Maestría en Ciencias Naturales (fuente: Maestría en Ciencias naturales) — grupos: 3, opciones explícitas: 35
- `6` Maestría en Conservación — grupos: 1, opciones explícitas: 16
- `7` Maestría en Crecimiento Espiritual y Ministerios (fuente: Maestría en Crecimiento espiritual y ministerios) — grupos: 2, opciones explícitas: 19
- `8` Maestría en Deportes — grupos: 1, opciones explícitas: 15
- `9` Maestría en Familia, Orígenes y Herencia (fuente: Maestría en Familia, orígenes y herencia) — grupos: 2, opciones explícitas: 13
- `10` Maestría en Habilidades Domésticas (fuente: Maestría en Habilidades domésticas) — grupos: 1, opciones explícitas: 0
- `11` Maestría en Habilidades Vocacionales (fuente: Maestría en Habilidades vocacionales) — grupos: 1, opciones explícitas: 0
- `13` Maestría en Recreación (fuente: Experto en Recreación) — grupos: 1, opciones explícitas: 18
- `14` Maestría en Salud y Ciencia (fuente: Maestría en Salud y ciencia) — grupos: 3, opciones explícitas: 19
- `15` Maestría en Tecnología Moderna (fuente: Maestría en Tecnología moderna) — grupos: 1, opciones explícitas: 7
- `16` Maestría en Testificación — grupos: 1, opciones explícitas: 0
- `17` Maestría en Vida Primitiva (fuente: Maestría en Vida primitiva) — grupos: 1, opciones explícitas: 17
- `18` Maestría en Zoología — grupos: 3, opciones explícitas: 27

## Maestrías pendientes
- Maestría en Botánica: No existe master_honor_id actual/legacy confirmado; Alcance SELECTED_DIVISIONS apunta a división/unión no existente en SACDIA actual
- Maestría en Ciencia y tecnología: No existe master_honor_id actual/legacy confirmado; Alcance SELECTED_DIVISIONS apunta a división/unión no existente en SACDIA actual
- Maestría del Medioambiente: No existe master_honor_id actual/legacy confirmado; Alcance SELECTED_DIVISIONS apunta a división/unión no existente en SACDIA actual

## Especialidades diferidas por catálogo
- Maestría en Crecimiento espiritual y ministerios / Biblia viva línea 152: missing_from_catalog
- Maestría del Medioambiente / Agricultura ecológica línea 229: missing_from_catalog
- Maestría del Medioambiente / Bioconstrucción línea 230: missing_from_catalog
- Maestría del Medioambiente / Medioambiente acuático línea 233: missing_from_catalog
- Maestría del Medioambiente / Medioambiente terrestre línea 234: missing_from_catalog
- Maestría del Medioambiente / Recogida selectiva línea 235: missing_from_catalog

## Mapeos de categoría usados
- `1` ADRA → ADRA (9 especialidades activas)
- `2` Actividades agropecuarias → Actividades Agropecuarias (17 especialidades activas)
- `5` Artes y actividades manuales → Artes y Actividades Manuales (135 especialidades activas)
- `4` Artes domésticas → Artes Domésticas (24 especialidades activas)
- `8` Actividades vocacionales → Artes Vocacionales (92 especialidades activas)
- `6` Crecimiento espiritual, actividades misioneras y herencia → Crecimiento Espiritual, Actividades Misioneras y Herencia (93 especialidades activas)

## Diferencias de nombre conservadas
Se usó el nombre actual de la base para evitar renombres no solicitados:
- `1` DB: Maestría en Actividades Agrícolas; fuente: Maestría en Actividades agrícolas
- `5` DB: Maestría en Ciencias Naturales; fuente: Maestría en Ciencias naturales
- `7` DB: Maestría en Crecimiento Espiritual y Ministerios; fuente: Maestría en Crecimiento espiritual y ministerios
- `9` DB: Maestría en Familia, Orígenes y Herencia; fuente: Maestría en Familia, orígenes y herencia
- `10` DB: Maestría en Habilidades Domésticas; fuente: Maestría en Habilidades domésticas
- `11` DB: Maestría en Habilidades Vocacionales; fuente: Maestría en Habilidades vocacionales
- `13` DB: Maestría en Recreación; fuente: Experto en Recreación
- `14` DB: Maestría en Salud y Ciencia; fuente: Maestría en Salud y ciencia
- `15` DB: Maestría en Tecnología Moderna; fuente: Maestría en Tecnología moderna
- `17` DB: Maestría en Vida Primitiva; fuente: Maestría en Vida primitiva

## Dry-run contra base configurada
Validación ejecutada en modo dry-run: **PASÓ**. No se aplicaron cambios en base de datos.

- Checksum: `sha256:653ddbf00239b48de7a1c706feaf79b9ac1f148ca4563635268b9f0b02b2350c`
- Maestrías: **17**
- Grupos: **26**
- Opciones explícitas: **205**
- Equivalencias `honor_id`: **243**
- Updates detectados: **17**
- Creates detectados: **0**
- IDs afectados: `2, 3, 1, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18`

Nota técnica: el cliente Node `pg` emitió una advertencia de SSL al usar la URL ajustada para dry-run, pero la validación terminó correctamente.

## Apply contra base configurada
Importación ejecutada con `--apply`: **PASÓ**.

- Checksum: `sha256:653ddbf00239b48de7a1c706feaf79b9ac1f148ca4563635268b9f0b02b2350c`
- Maestrías actualizadas: **17**
- Maestrías creadas: **0**
- Grupos importados: **26**
- Opciones explícitas importadas: **205**
- Enlaces `option -> honor`: **243**
- IDs afectados: `2, 3, 1, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18`
- Recalculo de usuarios: **ejecutado posteriormente; ver sección de recálculo**

Verificación read-only posterior al apply confirmó en BD: `26` grupos, `205` opciones y `243` enlaces de especialidades equivalentes.

## Recálculo de maestrías afectadas
Recálculo ejecutado con el `MasterHonorsEvaluatorService` real.

- Maestrías evaluadas: **17**
- Usuarios únicos afectados: **1**
- Evaluaciones ejecutadas: **1**
- Fallas: **0**
- Transiciones: `NONE: 1`
- Nuevos registros `users_master_honors`: **0**
- Nuevos registros de historial: **0**
- Nuevas notificaciones de maestrías: **0**

Verificación read-only posterior confirmó: `0` registros activos en `users_master_honors` para las maestrías afectadas, `0` registros en `master_honor_evaluation_history` y `0` logs de notificación `master_honors:*`.

## Siguiente validación
El import y el recálculo ya fueron ejecutados. Quedan pendientes las 3 maestrías fuera del candidato y, si se desea, commitear los artefactos de trabajo/reporte.
