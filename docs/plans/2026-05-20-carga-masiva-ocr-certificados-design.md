# Carga Masiva OCR de Comprobantes — Diseño

**Fecha**: 2026-05-20
**Estado**: Diseño aprobado conversacionalmente
**Ámbito**: `sacdia-app`, `sacdia-admin`, `sacdia-backend`
**Feature**: carga masiva iniciada por miembro para clases y especialidades/honores a partir de comprobantes o certificados.

---

## 1. Objetivo

Permitir que un miembro cargue uno o varios comprobantes/certificados desde `sacdia-app`, que el sistema extraiga datos con OCR, que el usuario revise y corrija una sábana móvil de datos, y que el Campo Local apruebe o rechace el lote o filas individuales desde `sacdia-admin`.

La aprobación final debe aplicar los registros en la estructura existente de SACDIA:

- especialidades/honores en `users_honors`;
- clases en `enrollments` y su flujo vigente de investidura/completado;
- evidencias en `evidence_files` cuando corresponda.

## 2. Principio rector

**OCR propone, el miembro confirma, Campo Local valida.**

El OCR nunca debe ser autoridad institucional. La validación sigue siendo un acto separado, trazable y realizado por Director LF o Asistente LF.

## 3. Alcance

Incluye:

- carga desde app móvil;
- uno o varios comprobantes por lote;
- comprobantes mixtos con especialidades y clases en el mismo archivo;
- OCR con extracción de texto, filas candidatas y confianza por campo;
- revisión móvil editable antes de enviar;
- aprobación/rechazo por lote y por fila en admin;
- corrección y reenvío de filas rechazadas;
- vista especial en app para registros creados por carga masiva.

No incluye en primera versión:

- aprobación automática sin humano;
- IA avanzada para decidir validez institucional;
- reemplazar pantallas actuales de progreso normal;
- crear tablas paralelas como fuente final de clases o especialidades.

## 4. Actores

- **Miembro**: inicia carga, revisa OCR, corrige datos y reenvía rechazos.
- **Director LF / Asistente LF**: revisa en `sacdia-admin`, aprueba o rechaza por lote/fila.
- **Sistema OCR**: extrae texto y sugiere filas, campos y coincidencias de catálogo.

## 5. Flujo aprobado

1. El miembro sube comprobantes desde `sacdia-app`.
2. Backend crea un lote `DRAFT` y guarda archivos originales.
3. OCR procesa y genera filas candidatas.
4. App muestra tarjetas editables con tipo, nombre, fecha y estado de confianza.
5. El miembro corrige datos faltantes o ambiguos.
6. El miembro envía el lote a revisión.
7. Admin revisa y puede aprobar/rechazar lote completo o filas individuales.
8. Si una fila se rechaza, el miembro puede corregirla y reenviarla dentro del mismo lote.
9. Al aprobar una fila, backend aplica el resultado en las tablas existentes.

## 6. Estados

### Lote

- `DRAFT`
- `READY_TO_SUBMIT`
- `SUBMITTED`
- `PARTIALLY_APPROVED`
- `APPROVED`
- `REJECTED`
- `NEEDS_CORRECTION`

### Fila

- `NEEDS_REVIEW`
- `READY`
- `SUBMITTED`
- `APPROVED`
- `REJECTED`
- `RESUBMITTED`

La implementación puede ajustar nombres finales, pero debe conservar la semántica: lote y fila tienen estados independientes.

## 7. UX móvil en `sacdia-app`

La app debe comportarse como un asistente de revisión, no como una tabla de escritorio.

### Pantallas

#### 7.1 Carga de comprobantes

- CTA principal: “Subir comprobante”.
- Permitir cámara o archivo.
- Mensaje: “Intentaremos leer tus datos automáticamente, pero podrás revisarlos antes de enviar.”

#### 7.2 Procesando OCR

- Estados visibles: subiendo, leyendo, preparando resultados.
- Si OCR falla, no bloquear: pasar a carga manual con comprobante adjunto.

#### 7.3 Revisión de resultados

Lista de tarjetas editables, agrupadas por comprobante.

Cada tarjeta muestra:

- badge `Clase` o `Especialidad`;
- nombre detectado;
- match contra catálogo;
- fecha de completado/certificación;
- estado: listo, falta dato, revisar coincidencia;
- indicador de confianza OCR;
- acceso al comprobante original.

CTA inferior fijo: “Enviar a revisión”. Solo se habilita si todas las filas obligatorias están completas.

#### 7.4 Detalle de fila

- selector de tipo: clase o especialidad;
- buscador contra catálogo;
- fecha requerida de completado/certificación;
- observaciones opcionales;
- preview del comprobante.

#### 7.5 Estado posterior al envío

- Mostrar lote pendiente de Campo Local.
- Mostrar aprobadas, pendientes y rechazadas.
- Rechazadas muestran motivo y botón “Corregir y reenviar”.

### Reglas visuales

- No usar tablas en mobile.
- Usar tarjetas editables.
- Usar `SacButton`, `SacCard`, `SacTextField`, `SacBadge` y componentes del design system.
- Usar `context.sac` para colores, no `AppColors` directo en pintura de widgets.
- Respetar targets táctiles de 44–48px mínimo.
- Usar lista eficiente si el lote puede crecer; evitar `SingleChildScrollView` con muchas tarjetas.
- Mantener identidad “Scout Vibrante” de `sacdia-app`.

## 8. Backend y modelo de datos conceptual

Crear un módulo de workflow, por ejemplo `CertificateBulkImportsModule`.

Este módulo no reemplaza `users_honors`, `enrollments` ni `evidence_files`. Solo administra entrada, OCR, estados, auditoría y trazabilidad.

### Entidades conceptuales

#### `certificate_bulk_import_batches`

- `batch_id`
- `user_id`
- `local_field_id`
- `status`
- `raw_ocr_payload`
- `submitted_at`
- `reviewed_at`
- `created_at`
- `modified_at`

#### `certificate_bulk_import_items`

- `item_id`
- `batch_id`
- `type`: `HONOR` | `CLASS`
- `honor_id` nullable
- `class_id` nullable
- `detected_name`
- `detected_date`
- `completed_at` / `certified_at`
- `ocr_confidence`
- `field_confidence`
- `status`
- `rejection_reason`
- `reviewed_by_id`
- `reviewed_at`
- `applied_entity_type`
- `applied_entity_id`

#### `certificate_bulk_import_files`

- `file_id`
- `batch_id`
- `file_url` / `file_key`
- `file_name`
- `mime_type`
- `uploaded_by_id`
- `ocr_raw_text`
- `created_at`

#### `certificate_bulk_import_item_events`

Audit trail para:

- extracción OCR;
- edición del usuario;
- envío;
- aprobación/rechazo;
- corrección;
- reenvío;
- aplicación a tabla final.

## 9. API propuesta

### App

- `POST /certificate-bulk-imports` — crear lote y subir archivos.
- `POST /certificate-bulk-imports/:id/process-ocr` — ejecutar o reintentar OCR.
- `GET /certificate-bulk-imports/:id` — obtener lote completo.
- `PATCH /certificate-bulk-imports/:id/items/:itemId` — editar fila.
- `POST /certificate-bulk-imports/:id/submit` — enviar lote a revisión.
- `POST /certificate-bulk-imports/:id/items/:itemId/resubmit` — reenviar fila corregida.

### Admin

- `GET /admin/certificate-bulk-imports/pending` — bandeja de revisión.
- `GET /admin/certificate-bulk-imports/:id` — detalle con comprobantes y filas.
- `POST /admin/certificate-bulk-imports/:id/approve` — aprobar lote.
- `POST /admin/certificate-bulk-imports/:id/reject` — rechazar lote.
- `POST /admin/certificate-bulk-imports/:id/items/:itemId/approve` — aprobar fila.
- `POST /admin/certificate-bulk-imports/:id/items/:itemId/reject` — rechazar fila con motivo.

## 10. Reglas al aprobar

### Especialidad / honor

Al aprobar `HONOR`:

1. Buscar `users_honors` por `(user_id, honor_id)`.
2. Si existe inactiva, reactivar.
3. Si existe activa, no duplicar.
4. Actualizar datos de validación si corresponde:
   - `date` = fecha de completado/certificación;
   - `certificate` = comprobante;
   - `validation_status` según enum vigente;
   - `validated_by_id`;
   - `validated_at`.
5. Crear o vincular evidencia en `evidence_files.user_honor_id`.
6. Guardar referencia inversa desde import item a `users_honors.user_honor_id`.

### Clase

Al aprobar `CLASS`:

1. Buscar o crear `enrollments` por `(user_id, class_id, ecclesiastical_year_id)`.
2. Usar `enrollments` como autoridad de clase anual.
3. No usar `users_classes` legacy.
4. Registrar validación institucional según transición vigente.
5. Si el comprobante representa clase completada/investida:
   - actualizar `investiture_status` según regla final;
   - `validated_by`;
   - `validated_at`;
   - `investiture_date` si aplica;
   - registrar `investiture_validation_history`.
6. Guardar referencia inversa desde import item a `enrollments.enrollment_id`.

La semántica exacta de `investiture_status` debe verificarse durante implementación para no saltarse transiciones inválidas.

## 11. Reglas de idempotencia

- Aprobar dos veces una fila no debe duplicar registros.
- Reintentar aplicación tras error debe ser seguro.
- Rechazar no elimina comprobantes.
- Reenviar una fila rechazada mantiene historial.
- Un lote parcialmente aprobado conserva estado por fila.

## 12. Vista especial para registros importados

Los registros aplicados desde carga masiva deben quedar trazables con:

- `source = CERTIFICATE_BULK_IMPORT`;
- `source_batch_id`;
- `source_item_id`;
- comprobante asociado.

En `sacdia-app`, al abrir una especialidad/clase importada:

- mostrar vista simplificada;
- nombre;
- tipo;
- fecha de completado/certificación;
- estado validado;
- comprobante visualizable;
- aprobador y fecha de aprobación.

No mostrar checklist, módulos, secciones ni progreso editable para registros importados por certificado.

Los registros normales siguen usando las vistas actuales.

## 13. OCR y matching

Primera versión:

- extraer texto bruto;
- detectar posibles nombres de clases/especialidades;
- detectar fecha de completado/certificación;
- sugerir match contra catálogo;
- guardar confianza por campo;
- requerir confirmación humana.

Si hay varias fechas o baja confianza, la app marca la fila como “requiere revisión” y el usuario elige la fecha correcta.

## 14. Seguridad y permisos

- Miembro solo puede crear/ver/editar sus propios lotes.
- Director LF / Asistente LF solo puede revisar lotes de su Campo Local.
- Toda aprobación/rechazo debe guardar actor y timestamp.
- No exponer archivos sin URL firmada o mecanismo seguro equivalente.
- Validar tamaño, tipo MIME y cantidad de archivos.
- Rate limit para OCR y uploads.

## 15. Admin UX

`Sacdia-admin` debe tener una bandeja de revisión con:

- filtros por estado, miembro, club/campo local, fecha;
- detalle del lote con preview del comprobante;
- lista de filas con tipo, nombre, fecha, confianza y estado;
- acción aprobar/rechazar lote;
- acción aprobar/rechazar fila;
- motivo obligatorio para rechazo;
- manejo de éxito parcial.

Puede reutilizar patrones de `evidence-review` e `investiture` bulk ops.

## 16. Testing esperado

Backend:

- OCR failover a carga manual;
- creación de lote draft;
- edición de filas;
- submit solo con filas completas;
- aprobación por lote;
- aprobación por fila;
- rechazo y corrección;
- idempotencia;
- aplicación a `users_honors`;
- aplicación a `enrollments`;
- autorización por owner/campo local.

App:

- flujo de carga;
- OCR loading/error states;
- revisión de tarjetas;
- validación de campos obligatorios;
- corrección y reenvío;
- vista simplificada de registros importados.

Admin:

- bandeja pendiente;
- preview;
- bulk approve/reject;
- per-item approve/reject;
- partial success.

## 17. Pendientes de decisión fina

Antes de implementar, confirmar:

1. proveedor OCR inicial;
2. límite de archivos por lote;
3. límite de filas por lote;
4. regla exacta de transición de clase completada/investida;
5. si el año eclesiástico se infiere por fecha del certificado o por año activo.

## 18. Documentación relacionada

- `docs/features/honores.md`
- `docs/features/clases-progresivas.md`
- `docs/features/validacion-evidencias.md`
- `docs/features/validacion-investiduras.md`
- `docs/canon/runtime-validation.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `sacdia-app/DESIGN-SYSTEM.md`
