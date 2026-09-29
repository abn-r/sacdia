# Cierre de carga por certificados — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Completar la carga, lectura, revisión y acreditación de comprobantes de especialidades e investiduras históricas desde la app, con validación institucional desde el administrador.

**Architecture:** Mantener `users_honors` y `enrollments` como fuentes finales; las tablas `certificate_bulk_import_*` conservan borradores, documentos y auditoría. Diferenciar acreditación histórica de cursado operativo dentro de `enrollments`, reutilizar almacenamiento privado R2 y ejecutar OCR fuera de transacciones de base de datos. El OCR propone; el miembro confirma datos; el revisor autorizado acredita hechos ya realizados.

**Tech Stack:** NestJS, Prisma/PostgreSQL, FileStorageService/R2, BullMQ existente, Flutter/Riverpod/Dio, Next.js y pruebas Jest/Vitest/Flutter.

**Estado:** DRAFT técnico — reglas de negocio confirmadas: certificados independientes, sustitución de inscripción `GM-01` y bandeja institucional exclusiva del superadministrador. No implementación ejecutada.
**Fecha:** 2026-09-19. Acuerdos finales consolidados el 2026-09-21; sustituyen las reglas anteriores de secuencia curricular y coexistencia de inscripciones de Guía Mayor.
**Alcance de esta entrega:** planificación. No se modificó código runtime, no se ejecutaron migraciones, tests ni builds.

---

## 1. Reglas confirmadas y límites

1. Aprobar un comprobante de clase en la vía de Campo Local acredita que la persona **ya fue investida**: estado final `INVESTIDO`, con la fecha original del certificado. La revisión de clases descontinuadas tiene el alcance separado de la regla 14.
2. `FIELD_APPROVED` no es el resultado final de esta acreditación histórica.
3. No exigir duración mínima/máxima, progreso actual, ventana de solicitud ni ceremonia actual para validar el hecho histórico. No expirar estas acreditaciones.
4. Cuando falte el periodo eclesiástico, un administrador autorizado debe registrar el periodo correcto **antes de aprobar**. El miembro puede conservar y enviar su expediente sin inventar el periodo.
5. Crear periodos históricos no debe activar otro ciclo ni reemplazar el año vigente. No asignar un año actual como fallback ni deducir límites enero–diciembre sin respaldo institucional.
6. Campo Local valida especialidades y clases ordinarias dentro de su ámbito, incluido `GM-01`. La excepción institucional de la regla 14 corresponde exclusivamente al superadministrador. Revisar certificados no concede automáticamente permiso para crear periodos.
7. Admitir varias clases distintas acreditadas en un mismo periodo sin convertirlas en varios cursados operativos simultáneos.
8. No reutilizar `cross_type_enrollment` como indicador histórico: representa otro privilegio.
9. No desactivar inscripciones operativas ajenas ni marcar toda acreditación `active=false` para eludir una restricción.
10. No crear una fuente paralela de trayectoria formativa ni reintroducir `users_classes`.
11. Cada certificado acredita un hecho histórico independiente: clase, persona y fecha/año indicados y confirmados por el revisor competente. No exigir inscripción operativa vigente como prerrequisito de acreditación ni usar el curso actual para aceptar o rechazar por posición en la escala.
12. No exigir clases anteriores, secuencia continua, ausencia de saltos ni orden de carga/aprobación. Es válido acreditar Amigo y Explorador sin Compañero, incluso en documentos separados. Se mantiene una carga de documento a la vez; si un documento respalda varias filas, se revisan sin dependencias curriculares. Esto aplica solo a certificados: las reglas normales de inscripción, progresión y validación anual siguen vigentes. El documento no se autoaprueba: conservar controles de identidad, evidencia, fecha, periodo, duplicados y autorización humana.
13. El certificado aprobado de Guía Mayor (`GM-01`) **sustituye** la inscripción actual de esa misma clase. Debe quedar una sola inscripción/acreditación GM, `INVESTIDO`, con fecha y periodo originales del certificado y comprobante asociado: no conservar dos inscripciones, ni siquiera como dos históricos. Campo Local confirma identidad y hecho acreditado. Se libera del cursado actual, sus requisitos y expiración; se impide recursado, nueva inscripción GM y reinvestidura posterior. La trazabilidad de la sustitución se conserva en auditoría, no como otra inscripción. No inventar fecha de inicio de cursado ni activar el periodo histórico. Esta sustitución específica no elimina inscripciones de otras clases ni se generaliza automáticamente a ellas.
14. Guía Mayor Avanzado (Máster) e Instructor permanecen inactivos y no inscribibles en la operación normal. Sus certificados generan solicitudes en una **bandeja institucional adicional y exclusiva del superadministrador**, con consulta del comprobante, aprobación/rechazo y actor, fecha y motivo auditados. Campo Local, administradores genéricos y Unión no reciben esa facultad en esta entrega; soporte a Unión u otra entidad queda para una feature futura. El solicitante consulta su propio estado. El OCR solo propone: el envío confirmado o la captura manual generan la solicitud sin duplicarla. Esta validación institucional no crea automáticamente `enrollments`, no reactiva clases ni cambia el curso actual; el registro manual final permanece fuera de alcance y no debe confundirse con aprobar la solicitud.
15. No builds, commits, despliegues ni operaciones sobre datos reales en esta entrega. En ejecución: tests/lint/analyze; commits convencionales solo con autorización, sin atribución de IA.

## 2. Diagnóstico verificado

| Hallazgo | Evidencia local | Consecuencia |
|---|---|---|
| La app entrega `image.path`/`file.path` y los serializa como `file_url` | `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/presentation/views/certificate_import_upload_view.dart:48–84`; `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/data/datasources/certificate_import_remote_data_source.dart:44–54` | No hay transferencia real de bytes en ese recorrido. |
| El proveedor registrado es `NoopCertificateOcrProvider` | `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.module.ts:22–23` | Solo interpreta texto ya suministrado; no lee imágenes/PDF. |
| Aprobar CLASS busca un periodo que cubra `completed_at` | `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts:184–280` | Si no existe, devuelve `CERTIFICATE_IMPORT_YEAR_NOT_FOUND`; actualmente escribe `FIELD_APPROVED`. |
| `enrollments` exige `ecclesiastical_year_id` y unicidad usuario/clase/año | `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma:1124–1173` | No se puede guardar una inscripción sin periodo con el schema vigente. |
| Dos índices permiten solo una inscripción activa regular y una cruzada por usuario/año | `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/20260903180000_cross_type_active_enrollment_slots/migration.sql:10–16` | Dos CLASS diferentes importadas como regulares activas pueden colisionar. |
| Aprobar lote usa una transacción para todas sus filas | `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/admin-certificate-bulk-imports.service.ts:72–120` | Una colisión revierte la aprobación completa de ese lote. |
| Expiración solo considera `IN_PROGRESS` y `REJECTED` | `/Users/abner/Documents/development/sacdia/sacdia-backend/src/investiture/investiture.service.ts:70–73,1734–1859` | `INVESTIDO` ya está excluido; no hay que imponer duración a los históricos. |
| `markItemApproved` deja el lote en `PARTIALLY_APPROVED` | `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts:333–364` | Aprobar individualmente la última fila requiere recalcular el estado global. |
| Ya existe infraestructura de subida firmada y confirmación | `/Users/abner/Documents/development/sacdia/sacdia-backend/src/common/services/file-storage.service.ts:86–134`; `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certifications/evidence/certification-evidence.service.ts:68–229` | Reutilizar la abstracción; no crear otro cliente de storage. |

### Ejemplo concreto de la colisión

Usuario A sube, por separado y en cualquier orden, certificados de Amigo y Compañero con fechas dentro del periodo P. La aplicación intenta insertar `(A, Amigo, P, active=true, cross_type=false)` y `(A, Compañero, P, active=true, cross_type=false)`. Aunque las clases son distintas, el índice único regular solo usa `(user_id, ecclesiastical_year_id)`: el segundo registro falla. También puede chocar un certificado contra una inscripción regular que ya existía en ese periodo. Esto es una limitación de representación actual, **no una prohibición de acreditar ambas clases**.

## 3. Diseño técnico propuesto

Estas decisiones técnicas son propuestas del plan; no se presentan como cambios ya aprobados o desplegados.

### 3.1 Trayectoria histórica sin consumir cupos operativos

- Añadir a `enrollments` un discriminador propuesto `record_kind`: `OPERATIONAL` por defecto y `HISTORICAL_CERTIFICATE` para altas por comprobante histórico.
- Mantener la unicidad `(user_id, class_id, ecclesiastical_year_id)` y las relaciones existentes.
- Reemplazar los dos índices parciales por equivalentes que solo consideren `record_kind = 'OPERATIONAL'`.
- Los históricos nuevos permanecen `active=true`, `INVESTIDO`, bloqueados para edición de progreso. `active` mantiene su significado de vigencia del registro, no de cursado actual.
- Las consultas de cursado actual, cupos y asignación de consejero deben filtrar `OPERATIONAL`. Trayectoria, logros, prerrequisitos operativos y condición de GM ya investido reconocen los hechos históricos válidos. Tener GM reconocido no implica mantener un curso GM activo; los escritores de inscripción también deben consultar esa acreditación para impedir recursado.
- No basta con cambiar índices: auditar contadores de aplicación que usan `active=true`, y todos los consumidores de `enrollments` por intención de lectura.
- Salvo la sustitución específica de GM descrita abajo, un certificado coincidente con una inscripción operativa existente no debe cambiar silenciosamente su tipo, fecha o progreso. Reutilizar automáticamente solo un hecho final idéntico. Si la inscripción no está investida, el revisor puede confirmar explícitamente «acreditar sobre esta inscripción»: conservar ID, `record_kind`, progreso y fecha de inscripción; actualizar únicamente el hecho de investidura y su validación, dejando auditoría. Una investidura final con fecha contradictoria se bloquea; corregir hechos finales queda fuera de este importador.
- No usar `enrollment_date = fecha del certificado` como si se conociera cuándo empezó a cursar. Para una fila exclusivamente histórica, documentar que `enrollment_date` es fecha técnica de alta y `investiture_date` la fecha acreditada; la UI no la presenta como inicio de cursado.
- Aplicar las reglas 11–14 sin validar secuencia ni clase actual. Fuera de la sustitución GM o conciliación explícita, no modificar inscripciones operativas ajenas al hecho acreditado. Guía Mayor Avanzado e Instructor se separan hacia la revisión institucional; no son filas aprobables por Campo Local.

**Tradeoff:** un discriminador exige migración y revisión de consumidores, pero conserva el canon y evita ocultar históricos con `active=false`. Excluir del índice todos los `INVESTIDO` sería menor cambio, pero alteraría cupos del flujo normal; una tabla histórica paralela obligaría a unir dos fuentes en todas las consultas. No se proponen esas alternativas.

### 3.1.1 Sustitución de Guía Mayor: una sola inscripción final

- Antes de escribir, inventariar todas las filas GM del usuario y las referencias a sus IDs: progreso, evidencias, historial de validación, rankings y `applied_entity_id`. Distinguir auditoría de inscripción: no basta con ocultar o desactivar la fila actual.
- Propuesta preferida cuando sea segura: reutilizar la inscripción GM existente, convertirla en `HISTORICAL_CERTIFICATE` y fijar periodo/fecha del hecho certificado. Si ya existe una fila histórica candidata, conciliar las referencias y dejar una sola fila GM. La estrategia física y restricciones se cierran con el inventario T2; no autorizar borrados en cascada ni pérdida de evidencias.
- La confirmación del revisor identifica inscripción(es), versiones esperadas y resultado. Bloquear usuario/clase y revalidar dentro de la transacción: periodo válido, identidad, estado de solicitud y ausencia de una investidura final contradictoria. Duplicado final idéntico reutiliza el hecho; contradicción requiere resolución fuera de la aprobación automática.
- Guardar auditoría antes/después y referencia al certificado sin conservar una segunda inscripción. El progreso previo no se transforma en requisitos cumplidos: su trazabilidad se preserva sin volverlo trabajo pendiente ni recalcular puntos históricos automáticamente.
- Al terminar, una sola inscripción GM tanto en persistencia como en historial visible, sin curso GM pendiente. Si no había inscripción GM previa, registrar solo el hecho acreditado. El reintento tras la sustitución es idempotente y no exige que siga existiendo un curso actual.
- Proteger también post-registro, inscripción anual, promoción y cualquier escritor descubierto en T2: la acreditación reconocida impide generar otra inscripción GM o solicitar nueva investidura, incluso en ciclos futuros. Las clases ajenas y sus reglas normales no se modifican.

### 3.2 Periodo faltante y fechas

- Resolver la fecha civil del comprobante, no el instante actual. Preservar `YYYY-MM-DD` de extremo a extremo; probar que zonas horarias no resten un día.
- Cero periodos que cubren la fecha: dependencia administrativa pendiente. Más de uno: conflicto por solapamiento; no elegir el primero arbitrariamente.
- Un periodo inactivo puede ser válido como referencia histórica. No exigir configuración de ceremonia para ese periodo.
- La ausencia se informa en el detalle antes de aprobar; se verifica otra vez dentro de la transacción de aprobación.
- El administrador crea el periodo con límites institucionales correctos y sin activarlo. Proteger alta/edición contra solapamientos y carreras, con auditoría e invalidación de caché.
- No reescribir algoritmos de duración como parte del importador: solo probar que el nuevo histórico queda fuera de expiración y de continuidad operativa. Si una regresión independiente aparece al modificar el catálogo, registrarla y tratarla separadamente antes del despliegue afectado.

### 3.3 Archivo privado y OCR

- Flujo propuesto: crear borrador → solicitar subida firmada → PUT a R2 → confirmar archivo → procesar OCR o capturar manualmente → corregir filas → enviar → revisión por autoridad competente. Campo Local acredita; la bandeja institucional valida solicitudes sin alta automática de inscripción.
- Mantener un documento por carga en esta entrega. Documentos de clases diferentes se cargan y aprueban independientemente; no implementar ordenación curricular ni exigir una carga múltiple para completar el flujo.
- El servidor genera la clave y la vincula a usuario/lote. La app no puede adjuntar una clave de otro usuario aunque el host esté permitido.
- Confirmar existencia, tamaño y tipo real. Solo archivos confirmados participan en OCR/revisión/aprobación.
- Guardar claves durables, no URLs temporales. Autorizar cada descarga y generar URLs cortas para miembro/revisor autorizado.
- Aislar el PUT de R2 del cliente Dio con JWT de la API para no filtrar tokens a storage.
- Hacer inmutable el documento confirmado: una URL PUT aún vigente no debe permitir cambiar el objeto que será validado. Usar staging y promoción a clave final inmutable, o mecanismo equivalente verificado.
- Procesar OCR en trabajo acotado fuera de una transacción SQL larga; persistir versión, estado y fallos; reintento no duplica filas ni pisa correcciones humanas.
- PDF con texto y PDF escaneado se consideran casos distintos. OCR sin resultados permite alta manual de filas; nunca aprobar automáticamente por confianza alta.
- **Proveedor OCR pendiente de evaluación técnica**, no elegido por este plan. Antes de integrarlo: fixture anónimo, calidad español/fechas/listas mixtas, PDF multipágina, privacidad, latencia, límites y costo; consultar documentación oficial vigente. No contratar servicios ni transferir certificados reales sin aprobación.
- Los límites de bytes/páginas/archivos y timeout se fijan en esa evaluación y se publican como contrato compartido; no inventar cifras finales aquí.

### 3.4 Contrato API propuesto, no vigente todavía

Conservar prefijo `/api/v1` y envelope del proyecto. No cambiar a ciegas los endpoints existentes.

| Operación | Contrato propuesto | Condición |
|---|---|---|
| Crear borrador | `POST /certificate-bulk-imports` admite borrador sin archivos confirmados | Compatibilidad documentada con cliente anterior; nunca aceptar sus rutas locales como prueba válida. |
| Preparar subida | `POST /certificate-bulk-imports/:batchId/files/presign` | Devuelve `file_id`, `upload_url`, headers y expiración; clave controlada por backend. |
| Confirmar subida | `POST /certificate-bulk-imports/:batchId/files/:fileId/confirm` | Idempotente y valida archivo real. |
| Obtener comprobante | `GET /certificate-bulk-imports/:batchId/files/:fileId/download` | Owner o revisor de la jurisdicción correspondiente; para evidencia exclusivamente institucional, solo owner/superadministrador. Sin bypass desde lote/fila general; URL efímera. |
| Retirar archivo del borrador | `DELETE /certificate-bulk-imports/:batchId/files/:fileId` | Solo editable y sin romper evidencia de filas enviadas/aprobadas. |
| Iniciar OCR | `POST /certificate-bulk-imports/:batchId/process-ocr` | Trabajo idempotente, `202`; GET del lote expone estado de OCR separado del estado de revisión. |
| Recuperar mis expedientes | `GET /certificate-bulk-imports` | Paginado, owner tomado del JWT; reanudar tras cerrar la app. |
| Crear/quitar fila manual | `POST /certificate-bulk-imports/:batchId/items`; `DELETE /certificate-bulk-imports/:batchId/items/:itemId` | Solo borrador editable; evidencia confirmada obligatoria al enviar. |
| Editar/enviar/corregir/revisar | Mantener PATCH, submit, resubmit y endpoints admin existentes | Validar contenido persistido completo, no solo campos presentes en PATCH. |

Extender detalle con `ocr_status`, `revision`, `approval_blockers` por fila y referencias al comprobante. Diferenciar fecha OCR, fecha confirmada y fecha administrativa de validación. Clasificar errores de archivo, autorización, periodo ausente/ambiguo, conflicto de registro y versión obsoleta con códigos estables en el catálogo de errores existente. `CERTIFICATE_IMPORT_YEAR_NOT_FOUND` es dependencia resoluble, no rechazo por documento inválido.

Para la conciliación propuesta, extender el DTO de aprobación individual con una resolución explícita que identifique la inscripción y versión esperadas. No aceptar un ID de otro usuario/clase; para conciliación ordinaria debe coincidir también el periodo. La sustitución GM valida expresamente el cambio del periodo actual al del certificado y todos los IDs afectados. Aprobar lote no resuelve automáticamente estos conflictos: resolver la fila individualmente y después aprobar las restantes. La opción exacta y sus campos deben quedar en OpenAPI y en tests antes de consumirlos desde el admin.

### 3.5 Bandeja institucional de clases descontinuadas

**Alcance incluido:** solicitud persistida, bandeja adicional, detalle/evidencia privada, aprobación o rechazo motivados, auditoría y consulta de estado por el solicitante. **No incluido:** alta automática ni nuevo flujo de registro manual de `enrollments`; «solicitud aprobada» no se presenta como «clase registrada».

- Proponer entidad de solicitud ligada a persona, clase descontinuada, fecha certificada, periodo (nullable mientras falte; obligatorio al aprobar), archivo confirmado, origen de la carga, estado, revisión/versión y decisión (actor, fecha, motivo). No es otra fuente de trayectoria: almacena un expediente, no una inscripción.
- Estados propuestos: `PENDING_REVIEW`, `APPROVED`, `REJECTED`. Un periodo faltante se expone como bloqueo resoluble sin rechazar el documento; no aprobar hasta resolverlo. La decisión final es inmutable en esta entrega; una nueva presentación conserva vínculo al antecedente y no borra su auditoría.
- El envío confirmado enruta según identidad estable de clase/catálogo, no por rol elegido por el cliente ni texto libre del OCR. Captura manual y OCR usan el mismo servicio; repetir el envío o el trabajo OCR no duplica solicitudes.
- Aplicar autorización backend explícita de superadministrador a listado institucional, detalle de revisión, descarga y decisiones. Permisos ordinarios de certificados, administración o Unión no la sustituyen. El acceso del solicitante a su propio expediente es consulta, no facultad de revisión.
- Separar estados y contadores de solicitudes institucionales de los de Campo Local. Si un documento tiene filas de ambas jurisdicciones, cada una conserva su autoridad y referencias; no permitir resolver la institucional por aprobación del lote general ni filtrar datos exclusivos de otra jurisdicción.
- Transiciones con versión esperada, bloqueo/compare-and-set y auditoría: doble aprobación/rechazo concurrente produce una sola decisión; el reintento idéntico no duplica eventos.

**Rutas propuestas (prefijo `/api/v1`; publicar contrato antes de implementarlas):**

| Operación | Contrato propuesto | Acceso |
|---|---|---|
| Enviar solicitud | `POST /certificate-import-institutional-requests` | Propietario, evidencia propia confirmada, clase admitida e idempotencia; el envío del expediente reutiliza este mismo servicio. |
| Consultar mis solicitudes | `GET /certificate-import-institutional-requests`; `GET /certificate-import-institutional-requests/:requestId` | Propietario desde JWT; paginación y estado/motivo visibles. |
| Bandeja y detalle institucional | `GET /admin/certificate-import-institutional-requests`; `GET /admin/certificate-import-institutional-requests/:requestId` | Exclusivamente superadministrador. |
| Resolver solicitud | `POST /admin/certificate-import-institutional-requests/:requestId/approve`; `POST /admin/certificate-import-institutional-requests/:requestId/reject` | Exclusivamente superadministrador; versión esperada y motivo, auditoría transaccional. |

Descarga reutiliza el contrato privado de §3.4, comprobando la relación archivo/solicitud y su jurisdicción. No crear acceso público alternativo. Rutas, entidad y estados son diseño propuesto, no endpoints/modelos ya existentes.

## 4. Secuencia de implementación y pruebas

**Método común:** para cada microtarea, escribir primero el caso que falla, ejecutarlo aislado y comprobar fallo por la causa esperada; implementar lo mínimo; repetir prueba; ejecutar regresión del módulo. No confundir tests con Prisma simulado con validación de índices PostgreSQL. Los archivos marcados **nuevo** son propuestos, no existentes. Antes de tocar consumidores, usar `graft grep`/`graft callers` y verificar el checkout vigente.

### T1 — Congelar contrato, invariantes y fixtures

**Dependencias:** ninguna. **Responsable:** backend/contratos.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/docs/features/carga-masiva-certificados.md`.
- `/Users/abner/Documents/development/sacdia/docs/features/validacion-investiduras.md`.
- `/Users/abner/Documents/development/sacdia/docs/features/clases-progresivas.md`.
- `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md` — cambios futuros claramente etiquetados hasta existir.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/test/fixtures/certificate-import/` — nuevo, solo muestras sintéticas/anónimas.

**Pasos:**
1. Registrar las reglas 1–14 y distinguir acreditación histórica, cursado y validación anual normal.
2. Incorporar fixtures: especialidad única, dos certificados separados del mismo año, documento mixto, periodo inexistente, fecha ilegible, duplicado, ausencia de curso actual, Amigo y Explorador sin Compañero, carga en orden inverso, clase igual/superior a la actual sin rechazo curricular, GM actual más certificado anterior, GM sin curso actual y Guía Mayor Avanzado/Instructor por OCR o captura manual.
3. Añadir tests rojos para `INVESTIDO` y fecha histórica sin prerrequisitos curriculares; sustitución GM con exactamente una fila final; bandeja institucional exclusiva del superadministrador. Comprobar que fallan por la causa esperada, no por fixtures incompletos. Guía Mayor Avanzado/Instructor siguen sin crear inscripción automática.
4. Definir tabla de estados/transiciones y errores públicos antes de implementar nuevas rutas.

**Prueba:** `pnpm exec jest --runInBand --runTestsByPath src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts` desde `/Users/abner/Documents/development/sacdia/sacdia-backend`.
**Salida:** contrato revisable y reproducción automatizada; no marcar esta fase como pruebas verdes mientras el nuevo caso sea rojo.

### T2 — Separar registros históricos de cupos operativos

**Dependencias:** T1. **Responsable:** backend/datos.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/<timestamp>_historical_certificate_enrollments/migration.sql` — nuevo; asignar timestamp real al implementar, no editar la migración ya existente.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/classes/classes.service.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/investiture/investiture.service.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/test/certificate-import-postgres.e2e-spec.ts` — nuevo.
- `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md` y `/Users/abner/Documents/development/sacdia/docs/database/schema.prisma`.

**Pasos:**
1. Crear prueba PostgreSQL que reproduce la colisión actual con dos clases/año y comprueba rollback.
2. Añadir discriminador con default operativo; mantener FK y unique usuario/clase/año.
3. Sustituir índices parciales solo para registros operativos y agregar restricciones coherentes para históricos (`INVESTIDO`, fecha obligatoria y progreso bloqueado).
4. Inventariar consumidores de `enrollments`; etiquetar cada lectura: operación, trayectoria, prerrequisito, ranking, auditoría. Anexar el inventario y archivos exactos al plan antes de modificar cada consumidor adicional.
5. Excluir históricos de cupos y cursos pendientes sin perderlos en trayectoria/prerrequisitos ni en la condición efectiva de GM investido. Mantener límites operativos existentes.
6. Comprobar convivencia de un cursado operativo con dos históricos del mismo periodo; demostrar que dos cursados regulares siguen fallando.
7. No backfillear automáticamente registros existentes: identificar importados por `applied_entity_id`, generar reporte dry-run y exigir clasificación inequívoca antes de migrar semántica.
8. Inventariar FK y escritores de GM antes de T4: definir reutilización/conciliación segura de IDs, tratamiento de progreso/evidencias/auditoría y protección concurrente entre importación e inscripción ordinaria. Probar que solo queda una fila GM, no dos con distinto estado; documentar cambios de referencias antes de cualquier eliminación física.

**Prueba:** `pnpm exec jest --config test/jest-e2e.json --runInBand --runTestsByPath test/certificate-import-postgres.e2e-spec.ts` desde backend, únicamente con base desechable validada como se define en §6.
**Salida:** restricciones SQL y filtros operativos consistentes, no solo mocks verdes.

#### Inventario T2 — lectores de `enrollments`

No aplicar un filtro global. Clasificación usada al implementar el discriminador:

| Intención | Archivos | Tratamiento en T2 |
|---|---|---|
| Cupo y curso pendiente | `classes.service.ts` conteos de `enrollUser` y `resolveProgressEnrollment`; `class-progress-scope.service.ts`; `class-progress-access.service.ts`; `investiture.service.ts` `getPending` y expiración; `validation.service.ts` `getPendingReviews` | Solo `record_kind = OPERATIONAL` |
| Escritores operativos | `class-enrollment-writer.service.ts`; `post-registration.service.ts` `resolveOperationalEnrollment`; `classes.service.ts` reactivación | No adoptan ni reactivan `HISTORICAL_CERTIFICATE`. Writer y post-registro rechazan una segunda fila `GM-01`. El trigger SQL cubre el alta directa |
| Trayectoria, prerrequisito y GM investido | `next-class.resolver.ts`; prerrequisitos y `validateDisplayOrderProgression` en `classes.service.ts`; búsqueda `INVESTIDO` de `GM-01` en `enrollUser`; `class-enrollment-policy.service.ts`; `club-role-eligibility.service.ts`; `class-counselor-assignments.service.ts` | Sin filtro de `record_kind`. El hecho histórico sigue contando |
| Ranking, auditoría y ficha | servicios de ranking por `enrollment_id`; `investiture_validation_history`; `admin-users.service.ts` `getUserById` | Sin cambio. La ficha debe seguir mostrando la trayectoria |

#### Inventario T2 — referencias de una fila GM

Sustitución prevista para T4: reutilizar el `enrollment_id` existente y cambiar periodo, fecha, estado y `record_kind` en esa misma fila. No borrar.

| Referencia | Comportamiento al borrar | Decisión |
|---|---|---|
| `class_module_progress.enrollment_id` | `ON DELETE NO ACTION` | Conservar el ID |
| `class_section_progress.enrollment_id` | `ON DELETE NO ACTION` | Conservar el ID |
| `investiture_validation_history.enrollment_id` | `ON DELETE CASCADE` | Conservar el ID; la auditoría no es otra inscripción |
| `enrollment_rankings.enrollment_id` | `ON DELETE CASCADE` | Conservar el ID |
| `certificate_bulk_import_items.applied_entity_id` | Sin FK | Si el ID sobreviviente cambiara, habría que reescribir el puntero. La reutilización evita ese cambio |

No hay backfill. Las filas actuales quedan `OPERATIONAL`. El comentario de la migración `20260921140000` deja el SELECT de hechos ya aplicados por `applied_entity_id` como dry-run, sin ejecutarlo.

### T3 — Resolver periodos históricos y dependencias administrativas

**Dependencias:** T1. **Responsable:** backend/contratos.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-import-year-resolver.service.ts` y `.spec.ts` — nuevos.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-reference.service.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/admin-certificate-bulk-imports.service.ts` y `.spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/common/errors/error-codes.ts`.

**Pasos:**
1. Escribir tests para cero/uno/dos periodos, periodo inactivo y fecha justo en cada límite.
2. Resolver por fecha civil con resultado explícito; no reutilizar `getCurrentYear(at)` sin comprobar su conversión de zona horaria.
3. Exponer bloqueos por fila desde el detalle sin transformar el expediente en rechazado.
4. Validar alta/edición administrativa de rangos, solapamientos y concurrencia; preservar año activo y permisos actuales del catálogo. Añadir prueba SQL para carrera de altas si se cambia su integridad.
5. Tras alta correcta, refrescar detalle y permitir aprobación sin subir de nuevo el documento.

**Prueba:** `pnpm exec jest --runInBand --runTestsByPath src/certificate-bulk-imports/certificate-import-year-resolver.service.spec.ts src/certificate-bulk-imports/admin-certificate-bulk-imports.service.spec.ts` desde backend; agregar la suite del catálogo identificada en ejecución.
**Salida:** falta de periodo visible y accionable; sin creación automática ni datos inventados.

### T4 — Registrar investidura histórica de forma transaccional

**Dependencias:** T2, T3.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts` y `.spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/admin-certificate-bulk-imports.service.ts` y `.spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/test/certificate-import-postgres.e2e-spec.ts` — nuevo.

**Pasos:**
1. Extender casos rojos: CLASS histórica independiente, HONOR, duplicado idéntico, fecha contradictoria, sin curso actual, saltos/orden inverso, clase igual/superior sin bloqueo curricular, sustitución GM, clases institucionales excluidas de Campo Local, dos revisores concurrentes y pérdida de respuesta HTTP.
2. Crear nuevos históricos con `INVESTIDO` conforme a reglas 11–13, sin filtro curricular; guardar fecha del hecho y fecha actual de validación por separado. Registrar actor y referencia a importación/comprobante sin fingir ceremonia actual. Para GM, aplicar la sustitución de §3.1.1 en lugar de añadir un histórico junto al curso actual. Guía Mayor Avanzado/Instructor solo se tramitan en T9, sin alta automática de `enrollments`.
3. No pasar por requisitos/duración/ceremonia del flujo normal. No crear progresos completos artificiales.
4. Proteger aplicación con bloqueo/compare-and-set transaccional y unique real; reintentar no duplica filas, evidencia ni auditoría.
5. Para hechos finales idénticos, vincular evidencia sin sobrescribir fecha/validador original. Para conciliación ordinaria no final, exigir ID/versión esperados y conservar tipo/progreso. Para GM, confirmar explícitamente sustitución, reconciliar referencias y conservar una sola fila con periodo/fecha certificados; no limitarse a desactivar la anterior. Fecha final contradictoria bloquea sin sobrescribir. Probar todas las rutas, rollback sin pérdida de datos y reintento después de sustituir.
6. Conservar atomicidad de aprobar lote: preflight de las filas de Campo Local y confirmación transaccional, sin ordenación ni dependencias curriculares. Los bloqueos reales de evidencia/periodo/conflicto permiten revisión individual de las demás; filas institucionales quedan fuera de esta acción y su estado se presenta por separado.
7. Recalcular estado del lote después de cada aprobar/rechazar/reenviar; la última aprobación individual debe producir `APPROVED` cuando corresponda.

**Prueba:** repetir suites de T1/T3 y PostgreSQL T2.
**Salida:** documento aprobado produce un hecho histórico verificable una sola vez; GM sustituye su cursado previo y las inscripciones ajenas permanecen intactas.

### T5 — Subida real, privada y confirmada a R2

**Dependencias:** T1; puede desarrollarse antes de T4 manteniendo el feature deshabilitado.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-import-files.service.ts` y `.spec.ts` — nuevos.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/dto/presign-certificate-import-file.dto.ts` — nuevo.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.controller.ts`, `.controller.spec.ts` y `.module.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma` — metadata/estado del archivo; migración aditiva propia.
- Referencia a reutilizar: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/common/services/file-storage.service.ts`.

**Pasos:**
1. Probar presign/confirm/download con owner, otro usuario y revisor fuera de campo; añadir jurisdicción institucional owner/superadministrador sin acceso por permisos genéricos de Campo Local. Todos los fallos deben ser controlados.
2. Crear borrador vacío seguro; generar clave aleatoria de staging, metadata y firma mediante `FileStorageService`.
3. Confirmar bytes/tipo real, tamaño y pertenencia; invalidar archivos dañados o fuera de límites. No confiar en extensión ni checksum aportado por el cliente.
4. Sellar archivo confirmado contra sobrescrituras; generar referencia final privada e inmutable.
5. Implementar descarga autorizada con renovación de URL y sin fallback a URL pública.
6. Retirar uploads abandonados mediante limpieza acotada; nunca eliminar comprobantes aplicados o enviados.
7. Mantener errores recuperables de red/storage y confirmación idempotente.

**Prueba:** `pnpm exec jest --runInBand --runTestsByPath src/certificate-bulk-imports/certificate-import-files.service.spec.ts src/certificate-bulk-imports/certificate-bulk-imports.controller.spec.ts` desde backend.
**Salida:** la referencia persistida representa bytes reales, privados e inmutables; no una ruta del teléfono.

### T6 — Completar edición manual, recuperación y estados

**Dependencias:** T1, T5.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.ts` y `.spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` y `.controller.spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/dto/update-certificate-import-item.dto.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.types.ts`.

**Pasos:**
1. Probar lote vacío, sin archivo confirmado, referencia de catálogo inexistente, fecha futura, PATCH parcial y edición posterior al envío.
2. Añadir alta/eliminación de filas de borrador y listado paginado de lotes propios para retomar expedientes.
3. Validar el estado final fusionado de la fila al aplicar PATCH; conservar correcciones anteriores. No exigir que cada PATCH repita campos que ya son válidos.
4. Bloquear submit vacío o incompleto en backend, no solo en UI. Faltante de periodo puede viajar como dependencia administrativa, no como fecha inválida.
5. Vincular cada fila al documento confirmado y las páginas que la respaldan; no asociar evidencia de otros expedientes. No ampliar a selección múltiple como requisito de esta entrega.
6. Añadir revisión optimista de versión para evitar que OCR tardío, dos pantallas o un reenvío pisen decisiones nuevas.
7. En expedientes de Campo Local, tratar rechazo como motivo visible y permitir corregir/reenviar solo lo rechazado, sin desbloquear aprobados. Las solicitudes institucionales usan el ciclo explícito de §3.5.
8. No validar curso actual, secuencia ni clases previas al editar/enviar; determinar jurisdicción desde catálogo y confirmar datos antes de enrutar. El fallback manual también admite solicitud institucional y no depende del proveedor OCR.

**Prueba:** `pnpm exec jest --runInBand --runTestsByPath src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts src/certificate-bulk-imports/certificate-bulk-imports.controller.spec.ts` desde backend.
**Salida:** el usuario puede completar el expediente incluso cuando OCR no reconoce nada y retomarlo otro día.

### T7 — OCR real con fallback manual y reintentos seguros

**Dependencias:** T5, T6; elección de proveedor es gate de esta tarea, no de las tareas anteriores.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.provider.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.parser.ts` y `.spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/ocr/configured-certificate-ocr.provider.ts` y `.spec.ts` — nuevos; nombre de adaptador final según evaluación.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/ocr/certificate-ocr.processor.ts` y `.spec.ts` — nuevos.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.module.ts` y `.service.ts`.

**Pasos:**
1. Evaluar proveedor con fixtures, documentar calidad/costo/privacidad/límites y aprobar configuración antes de contratar o activar credenciales.
2. Probar imágenes, PDF digital, PDF escaneado multipágina, fechas ambiguas, nombres parciales, lista mixta y documento ilegible.
3. Implementar adaptador usando referencia autorizada al archivo y devolver candidatos con página/origen, confianza y datos detectados separados de los confirmados.
4. Encolar fuera de la transacción de negocio; persistir versión/estado del trabajo. No marcar éxito si falta worker/proveedor.
5. Limitar reintentos/tiempo/páginas; concurrencia por versión de lote, consumo acotado y error explícito si Redis/proveedor no está disponible. Mantener salida manual.
6. Hacer procesamiento idempotente y proteger correcciones humanas: reejecutar propone nueva lectura, no borra filas aprobadas/editadas.
7. Registrar métricas de estado/latencia/volumen, sin texto OCR completo, datos personales ni URLs firmadas en logs.
8. Si la lectura coincide con Guía Mayor Avanzado o Instructor, proponer destino institucional. La integración de envío confirmado se completa en T9 usando su servicio, separado de las filas aprobables por Campo Local; T7 puede probar candidatos sin esa integración. No crear solicitudes definitivas solo por OCR, no duplicarlas al reintentar y no crear `enrollments`.

**Prueba:** `pnpm exec jest --runInBand src/certificate-bulk-imports/ocr` desde backend; integración externa exclusivamente con fixture autorizado y entorno aislado.
**Salida:** OCR realmente extrae del archivo y nunca actúa como aprobador. El Noop queda restringido a tests o modo manual explícito.

**Evaluación 2026-09-21, sin credenciales y sin adaptador.** No se contrata un OCR de pago. Google Vision, Azure y Textract dejan de ser gratis al pasar de una cuota mensual y piden tarjeta. OCR.space tiene un plan sin cobro (tope diario por IP y tope mensual), pero el comprobante saldría del servidor. Los certificados incluyen nombres y fechas de personas, a veces menores. La vía sin factura y sin sacar el archivo es un motor local con licencia Apache 2.0: Tesseract para texto impreso limpio, o PaddleOCR si la foto está girada o borrosa. En el teléfono, ML Kit en el dispositivo también es sin cobro y no llama a la nube; un PDF multipágina le queda grande. El parser actual solo propone filas si el texto trae etiquetas `clase:` o `honor:`; un motor perfecto no alcanza si el certificado no usa esas palabras. El flujo manual ya no depende de esta decisión.

### T8 — Conectar el flujo Flutter completo

**Dependencias:** contratos T5–T7 y §3.5 publicados; aprobación T4 y servicio institucional T9 para el recorrido completo. El flujo manual puede avanzar sin proveedor OCR.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/domain/entities/certificate_import_payloads.dart`.
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/domain/repositories/certificate_import_repository.dart`.
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/data/datasources/certificate_import_remote_data_source.dart`.
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/data/repositories/certificate_import_repository_impl.dart`.
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/presentation/providers/certificate_import_providers.dart`.
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/presentation/views/certificate_import_upload_view.dart`, `certificate_import_processing_view.dart`, `certificate_import_review_view.dart`, `certificate_import_status_view.dart` — todos dentro del mismo directorio absoluto anterior.
- `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/certificate_import/` — extender suites existentes de datasource, repositorio, modelos y views.

**Pasos:**
1. Crear test que falla si el cliente manda `file.path` como evidencia remota o envía Authorization de la API al PUT de R2.
2. Implementar crear → presign → PUT con progreso/cancelación → confirm → OCR; recuperar errores sin duplicar borrador.
3. Mantener un documento por carga y límites compartidos. Probar cargas separadas de Amigo/Explorador en cualquier orden, sin exigir Compañero ni selección múltiple. Las filas reconocidas dentro de un mismo documento también son independientes.
4. Añadir procesamiento asíncrono con polling acotado, cancelación al salir y reanudación desde el listado de expedientes; no lanzar OCR repetidamente por rebuild del widget.
5. Completar editor con catálogo/fecha, alta manual, quitar fila errónea y resumen de errores por fila.
6. Mostrar estado «pendiente de periodo administrativo» sin culpar al usuario ni solicitar que altere la fecha real.
7. Mostrar certificado, fecha histórica y resultado final; diferenciar rechazo de error de OCR/red.
8. Mantener textos localizados, accesibilidad, loading/error/empty y navegación atrás sin perder borrador.
9. Eliminar bloqueos curriculares de este flujo; mostrar errores reales de identidad/evidencia/periodo/conflicto. Informar que GM aprobado sustituye el cursado actual. Mostrar destino y estado institucional para Guía Mayor Avanzado/Instructor, con motivo de decisión y sin confundir aprobación de solicitud con inscripción aplicada.

**Pruebas:** `flutter test test/features/certificate_import` y `flutter analyze lib/features/certificate_import test/features/certificate_import` desde `/Users/abner/Documents/development/sacdia/sacdia-app`.
**Salida:** cámara/archivos funcionan contra backend real, el flujo sobrevive a interrupciones y no pierde correcciones.

### T9 — Revisión de Campo Local y nueva bandeja institucional

**Dependencias:** T1, T3–T6; integración de candidatos OCR con T7, sin depender de este para captura manual. **Ownership:** Codex entrega backend/contratos; Cursor implementa composición/polish del admin. La bandeja adicional está incluida; no implica rediseño general del panel.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma` y `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/<timestamp>_institutional_certificate_requests/migration.sql` — nueva entidad/migración de solicitudes y auditoría; sin alta de inscripciones.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/institutional-certificate-requests.service.ts` y `.spec.ts` — nuevos.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/institutional-certificate-requests.controller.ts` y `.controller.spec.ts` — nuevos, consulta/envío propios.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` y `.controller.spec.ts` — nuevos, exclusivamente superadministrador.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/dto/create-institutional-certificate-request.dto.ts` y `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/dto/review-institutional-certificate-request.dto.ts` — nuevos.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.module.ts` — registrar servicios/controladores y reutilizar guards existentes tras verificar su alcance efectivo.
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/api/certificate-bulk-imports.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/certificate-bulk-imports/certificate-bulk-import-detail-page.tsx`.
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/certificate-bulk-imports/certificate-bulk-import-action-dialog.tsx` y `.test.tsx`.
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/certificate-bulk-imports/certificate-bulk-import-list-page.tsx`.
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/api/institutional-certificate-requests.ts` — nuevo.
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/institutional-certificate-requests/institutional-certificate-request-list-page.tsx`, `institutional-certificate-request-detail-page.tsx` y `institutional-certificate-request-action-dialog.test.tsx` — nuevos dentro del mismo directorio absoluto; fijar las rutas de navegación compatibles con el router vigente antes de implementar.
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/auth/screen-catalog/index.ts` — añadir entrada institucional restringida, no ampliar permisos de la bandeja general.
- `/Users/abner/Documents/development/sacdia/docs/api/FRONTEND-INTEGRATION-GUIDE.md` y `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`.

**Pasos — backend institucional primero:**
1. Publicar contrato §3.5 con estados, DTOs, códigos, paginación y reglas de acceso; entregar fixtures al admin y Flutter T8.
2. Escribir tests rojos de ownership, evidencia confirmada, periodo faltante, duplicado de envío/OCR y roles. Probar denegación a Campo Local, administrador genérico y Unión aunque tengan permisos ordinarios de certificados.
3. Implementar persistencia, deduplicación y listado/detalle propio e institucional; tomar identidad del JWT y resolver jurisdicción desde catálogo. Separar estado/contadores del expediente general.
4. Implementar aprobación/rechazo con versión esperada y motivo, auditoría transaccional y resultado visible al solicitante. Probar carrera approve/reject e idempotencia; ninguna decisión crea `enrollments` ni activa clases.
5. Verificar que las rutas generales de revisión/descarga no permiten resolver ni consultar expedientes exclusivamente institucionales por pertenecer al mismo lote. El propietario conserva acceso a su propia solicitud.

**Pasos — paneles:**
1. Campo Local: preview privado, fecha acreditada frente a fecha de revisión, bloqueos reales y enlace al catálogo de periodos solo con permiso; retorno/refresco sin aprobación automática.
2. Mantener revisión individual y aprobación atómica de filas ordinarias, sin exigir orden curricular; mostrar motivo de rechazo y actualizar contadores al resolver la última fila.
3. GM: confirmar identidad y mostrar explícitamente inscripción que será sustituida, año/fecha certificados y resultado de una sola inscripción ya investida. No presentar conservar ambos registros como alternativa.
4. Crear entrada y bandeja institucional exclusiva del superadministrador: listado paginado/filtrable por estado, solicitante, clase, fecha, detalle y comprobante privado. No ofrecer estas decisiones en Campo Local.
5. Añadir acciones aprobar/rechazar con motivo, tratamiento de versión obsoleta, estados loading/error/empty, renovación de preview y auditoría visible al revisor. El estado aprobado significa «validación institucional aprobada», no «inscripción registrada».
6. Añadir tests de navegación, permisos y acciones; ocultar menú no sustituye autorización backend. Entregar a Flutter el resultado/motivo propio; no incorporar roles de Unión en esta entrega.

**Pruebas:** `pnpm exec jest --runInBand src/certificate-bulk-imports` desde backend; ampliar PostgreSQL T2 con entidad, deduplicación y carreras de solicitudes. Desde `/Users/abner/Documents/development/sacdia/sacdia-admin`: `pnpm exec vitest run src/components/certificate-bulk-imports src/components/institutional-certificate-requests` y `pnpm typecheck`; agregar tests de catálogo/rutas tocados. Flutter usa suites de T8 para consulta de estado.
**Salida:** revisión ordinaria y bandeja institucional separadas, con decisiones auditables, estado propio visible y autorización efectiva exclusivamente del superadministrador para la segunda.

### T10 — Proyecciones finales y no regresión de la operación

**Dependencias:** T2, T4, T8.

**Archivos iniciales:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/classes/classes.service.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/investiture/investiture.service.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.service.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/certificate_import/presentation/widgets/certificate_import_proof_card.dart`.
- Consumidores concretos de trayectoria, clases actuales, liderazgo, certificaciones y rankings identificados en el inventario T2; registrar rutas y tests antes de editar, no aplicar filtros globales mecánicos.

**Pasos:**
1. Probar que se ve el logro histórico y su documento, sin checklist vacío ni «cursando». Si se concilió sobre un registro operativo, conservar su progreso previo como información separada; identificar acreditación por la relación con importación, no únicamente por `record_kind`.
2. Probar independencia del certificado: sin clase vigente, saltos, orden inverso y posición igual/superior no generan rechazo curricular. No cambiar reglas del `NextClassResolver`: probar trayectoria acreditada como entrada válida y ausencia de altas operativas automáticas. Para GM, probar sustitución con una sola inscripción e historial visible; no queda cursado pendiente ni se regenera GM desde post-registro/inscripción anual/promoción, incluso el siguiente ciclo.
3. Probar que prerequisitos y condición de Guía Mayor investido sí reconocen un hecho histórico válido.
4. Probar que el endpoint de expiración no selecciona ni modifica históricos `INVESTIDO`; no validar antigüedad contra duración del cursado.
5. Probar que fuera de la acreditación/sustitución aprobada no se generan inscripciones, membresías, progresos ni puntos operativos por mero ingreso documental; evitar recomputar rankings históricos automáticamente. Solicitud institucional aprobada no se representa como inscripción aplicada.
6. No cambiar globalmente duración, promoción o scoring. Si un consumidor requiere decisión de negocio adicional, documentar el caso exacto y pausar solo esa modificación.

**Pruebas:** suites identificadas por el inventario más `pnpm exec jest --runInBand src/classes src/investiture src/honors` desde backend; Flutter tests del consumidor modificado.
**Salida:** el histórico acredita logros sin comportarse como una inscripción anual adicional.

### T11 — Seguridad, integridad y aceptación de punta a punta

**Dependencias:** T1–T10.

**Archivos nuevos:**
- `/Users/abner/Documents/development/sacdia/sacdia-backend/test/certificate-import-http.e2e-spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/test/certificate-import-postgres.e2e-spec.ts`.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/test/helpers/certificate-import-db.helper.ts`.

**Pasos:**
1. Probar ownership de lote/fila/archivo/solicitud, scope territorial, revisión exclusiva institucional del superadministrador y permiso separado de periodos. Campo Local, admin genérico y Unión no pueden revisar solicitudes institucionales; cambiar IDs o usar endpoints generales no debe filtrar documentos ni eludir jurisdicción.
2. Verificar referencia de archivo final inmutable, MIME real, ausencia de URLs internas/externas arbitrarias para OCR y ausencia de datos sensibles en logs.
3. Ejecutar carreras reales: doble approve, approve vs reject en ambas bandejas, sustitución GM vs nueva inscripción, altas paralelas de periodos, retry de confirm/OCR/envío institucional y modificación posterior al envío.
4. Recorrer con fixtures: certificados separados y en orden inverso de dos clases del mismo año, sin clase intermedia + honor → revisión → periodo faltante → alta administrativa → aprobación → historial. Repetir con documento mixto sin dependencias curriculares.
5. Repetir con OCR sin resultados → captura manual → rechazo motivado → corrección → reenvío → aprobación.
6. Probar caída de storage/proveedor/Redis sin reportar éxito falso, ni perder archivo/ediciones, ni dejar transacciones largas abiertas.
7. GM actual → certificado anterior → aprobación Campo Local → exactamente una inscripción GM con fecha histórica; no requisitos pendientes, expiración, recursado ni reinvestidura. Reintentar y avanzar ciclo: no reaparece otro GM; rollback conserva referencias si falla la sustitución.
8. Guía Mayor Avanzado/Instructor → envío OCR o manual → bandeja exclusiva del superadministrador → aprobación/rechazo motivado → solicitante consulta resultado. Verificar no duplicados, no alta automática, clase inactiva y denegación efectiva a Campo Local/Unión.

**Prueba HTTP:** `pnpm exec jest --config test/jest-e2e.json --runInBand --runTestsByPath test/certificate-import-http.e2e-spec.ts` desde backend.
**Prueba PostgreSQL:** comando T2 con base explícitamente desechable. La suite HTTP debe declarar qué dependencias simula y no se considera prueba de integridad SQL.
**Salida:** acta de aceptación con escenarios, resultados y limitaciones del entorno, sin afirmar verificación productiva desde mocks.

### T12 — Documentación, rollout y saneamiento controlado

**Dependencias:** T11 aprobado.

**Archivos:**
- `/Users/abner/Documents/development/sacdia/docs/features/carga-masiva-certificados.md`.
- `/Users/abner/Documents/development/sacdia/docs/features/clases-progresivas.md`.
- `/Users/abner/Documents/development/sacdia/docs/features/validacion-investiduras.md`.
- `/Users/abner/Documents/development/sacdia/docs/features/honores.md`.
- `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`.
- `/Users/abner/Documents/development/sacdia/docs/api/FRONTEND-INTEGRATION-GUIDE.md`.
- `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`.
- `/Users/abner/Documents/development/sacdia/docs/canon/decisiones-clave.md` — aclarar histórico vs operativo dentro de la misma fuente.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/audit-certificate-imports.ts` — nuevo, dry-run por defecto.

**Pasos:**
1. Sincronizar documentación con contratos realmente implementados y registrar comandos/resultados de pruebas.
2. Auditar importaciones previas: rutas locales inválidas, falta de objeto, lotes vacíos, aplicaciones en `FIELD_APPROVED`, duplicados GM/otras clases y evidencia incompleta. No promoverlos masivamente a `INVESTIDO` ni consolidar GM sin comprobar procedencia, referencias y decisión institucional.
3. Separar reporte de reparación. Cualquier escritura sobre datos reales requiere alcance, backup, dry-run e instrucción expresa; script idempotente y con auditoría.
4. Desplegar por compatibilidad: schema aditivo → backend y worker con feature apagado → consumidores actualizados → piloto autorizado → habilitación gradual. Coordinar el cambio de índices y filtros; clientes/backend anteriores no deben leer históricos como cursados.
5. Ante falla, apagar nuevas cargas/aprobaciones y conservar lectura/auditoría y reconocimiento efectivo de GM ya investido, sin reactivar su cursado. No restaurar índices antiguos si existen históricos incompatibles; no borrar hechos acreditados como rollback.
6. Documentar configuración mediante ejemplos sin secretos. No tocar `.env` reales, ejecutar builds ni contratar OCR desde este plan.

**Salida:** procedimiento operativo, evidencia de aceptación y rollback no destructivo.

## 5. Orden de entregas revisables

| Entrega sugerida | Contenido | Condición para continuar |
|---|---|---|
| A | T1 y T2: contrato, modelo e integridad | Dos históricos/año conviven; cupo operativo sigue protegido. |
| B | T3 y T4: periodo, investidura histórica y sustitución GM | Sin prerrequisitos curriculares; GM único, fecha correcta, referencias intactas e idempotencia. |
| C | T5 y T6: documentos y expediente recuperable | Archivo real/privado y revisión manual completa. |
| D | T7: OCR | Proveedor evaluado/aprobado; no-op eliminado del modo real; fallback probado. |
| E | T8 y T9: clientes y servicio/bandeja institucional | Dos jurisdicciones verificadas; bandeja exclusiva del superadministrador, estado propio y flujo recuperable. |
| F | T10–T12: integración y liberación | Matriz completa verde, docs sincronizadas, piloto y rollback preparados. |

Son unidades lógicas, no promesa de seis PRs: dividir cada entrega si excede el presupuesto de revisión del proyecto (referencia: 400 líneas). No cambiar automáticamente a un PR gigante. No se crean ramas, worktrees o PRs con esta entrega; el aislamiento y estrategia se resuelven al autorizar ejecución.

## 6. Validación, seguridad del entorno y criterios de cierre

### Comandos finales previstos (no ejecutados al redactar)

Desde `/Users/abner/Documents/development/sacdia/sacdia-backend`:

```sh
pnpm exec jest --runInBand src/certificate-bulk-imports
pnpm exec jest --runInBand src/classes src/investiture src/honors
pnpm exec eslint src/certificate-bulk-imports
pnpm exec jest --config test/jest-e2e.json --runInBand --runTestsByPath test/certificate-import-http.e2e-spec.ts
pnpm exec jest --config test/jest-e2e.json --runInBand --runTestsByPath test/certificate-import-postgres.e2e-spec.ts
```

Ampliar lint/tests a los otros archivos modificados según el inventario, sin usar el script backend `lint` con `--fix` indiscriminadamente. La suite PostgreSQL nueva debe reutilizar las garantías de `/Users/abner/Documents/development/sacdia/sacdia-backend/test/helpers/annual-cycle-db.helper.ts`: requerir `SACDIA_TEST_DATABASE_URL`, host loopback, nombre terminado en `_test`, sin fallback a `DATABASE_URL`. Si no hay base desechable, reportar bloqueo de esa verificación y no tocar Neon ni conexiones reales. Migraciones de prueba solo después de esa validación.

Desde `/Users/abner/Documents/development/sacdia/sacdia-app`:

```sh
flutter test test/features/certificate_import
flutter analyze lib/features/certificate_import test/features/certificate_import
```

Desde `/Users/abner/Documents/development/sacdia/sacdia-admin`:

```sh
pnpm exec vitest run src/components/certificate-bulk-imports src/components/institutional-certificate-requests
pnpm typecheck
pnpm exec eslint src/components/certificate-bulk-imports src/components/institutional-certificate-requests src/lib/api/certificate-bulk-imports.ts src/lib/api/institutional-certificate-requests.ts
```

Esperado: pruebas focalizadas y regresiones relevantes en PASS, sin errores de análisis/lint nuevos. Ningún comando anterior sustituye un recorrido con app/backend/worker/storage integrados. No incluir `build`, `flutter build`, `next build` ni `nest build` como validación.

### Criterios de aceptación obligatorios

- [ ] Se carga una imagen/PDF real desde el teléfono y se recupera tras reiniciar la app.
- [ ] El miembro y el revisor autorizado pueden ver el comprobante; otros usuarios/campos no.
- [ ] OCR real propone datos; si falla, se pueden ingresar manualmente sin perder el archivo.
- [ ] Las filas no se envían vacías, sin catálogo, sin fecha o sin prueba confirmada.
- [ ] Falta de periodo conserva expediente, informa dependencia y requiere administrador autorizado.
- [ ] Crear periodo histórico no activa ese periodo ni modifica la fecha del certificado.
- [ ] Una clase aprobada por Campo Local termina `INVESTIDO` con fecha histórica y auditoría administrativa actual; solicitud institucional tiene resultado separado, no alta automática.
- [ ] Dos clases distintas del mismo año se acreditan sin consumir dos cupos ni alterar inscripciones ajenas; GM respeta su sustitución específica.
- [ ] Certificados independientes se acreditan sin inscripción vigente, clases anteriores, continuidad u orden de carga/aprobación; no se rechazan por posición relativa al curso actual. Amigo y Explorador sin Compañero pasan revisión si sus evidencias son válidas.
- [ ] Campo Local aprueba GM y sustituye la inscripción actual: exactamente una inscripción/acreditación GM persistida y visible, con fecha/periodo certificados. No quedan dos históricos ni otro registro desactivado; evidencia y auditoría no se pierden.
- [ ] GM reconocido no tiene requisitos/cursado pendientes, no expira y no puede reinscribirse ni reinvestirse; post-registro, inscripción anual y promoción no lo recrean en ciclos futuros.
- [ ] Guía Mayor Avanzado/Instructor tienen bandeja adicional exclusiva del superadministrador, con evidencia, aprobar/rechazar, motivo y auditoría. Campo Local, admin genérico y Unión no pueden revisarlos, tampoco mediante endpoints alternativos.
- [ ] OCR o captura manual permiten enviar la solicitud institucional sin duplicados; el solicitante consulta su resultado. Aprobar no crea `enrollments`, no reactiva clases ni se muestra como inscripción aplicada.
- [ ] `INVESTIDO` histórico no expira ni requiere duración/progreso/ceremonia actual.
- [ ] Duplicados, conflictos, rechazos, reenvíos y concurrencia producen resultados definidos y auditables.
- [ ] Especialidades acreditadas quedan en `users_honors`; clases acreditadas por Campo Local en `enrollments`; solicitudes institucionales no se hacen pasar por trayectoria aplicada ni crean segunda fuente de verdad.
- [ ] La última aprobación individual deja el lote con el estado global correcto.
- [ ] Se verifican índices y carreras en PostgreSQL aislado, no únicamente con mocks.
- [ ] Contratos, schema documental y manual de operación reflejan la implementación final.
- [ ] Proveedor/límites OCR, rollout y cualquier saneamiento de datos reales reciben autorización antes de activarse.

## 7. Qué queda deliberadamente fuera

- Rediseño general del administrador y cambios de reglas del cursado anual.
- Conceder automáticamente roles, membresías, rankings o progresos por subir un documento.
- Crear periodos arbitrarios desde el OCR, usar el año actual por conveniencia o aprobar sin revisión humana.
- Reconocer reinvestiduras contradictorias o modificar hechos finales sin conciliación explícita.
- Contratar OCR, cargar documentos personales en servicios externos, migrar producción o desplegar sin autorización.
- Alta automática y nuevo flujo de registro manual final de Guía Mayor Avanzado/Instructor: la bandeja y decisión institucional sí están incluidas; aplicar posteriormente ese reconocimiento a la trayectoria sigue fuera de esta entrega.
- Extender revisión institucional a Unión u otra entidad/rol; se definirá en una feature futura, sin habilitar permisos anticipadamente.

## 8. Estado de ejecución

T1–T6 quedaron verificados el 2026-09-21. Aprobar una fila CLASS escribe `HISTORICAL_CERTIFICATE` / `INVESTIDO`. `GM-01` actualiza la fila existente. La subida nueva usa URL firmada, confirma bytes y sella la clave privada. El envío exige ese archivo confirmado y filas completas. El backend de T9 también quedó verificado ese día: `institutional_certificate_requests` persiste Guía Mayor Avanzado e Instructor, solo el superadministrador decide, y aprobar no crea `enrollments`. La base local de prueba rechaza una segunda solicitud abierta del mismo hecho y permite otra después de un rechazo. El panel del superadministrador ya lista y decide esas solicitudes, y Campo Local no ofrece esa acción. El detalle incluye `batch_id` para el comprobante firmado. No se tocó Neon ni se clasificaron filas existentes. T7 lee imágenes con Google Cloud Vision (`DOCUMENT_TEXT_DETECTION`, español) para JPEG, PNG y WebP. Un PDF responde `CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE` y se completa a mano. El tope es 10 MB, el mismo del comprobante. No hay tope diario local: la cuota la responde Vision. La petición encola `certificate-import-ocr` (concurrencia 1, dos intentos) y no comparte el worker de finanzas. Sin Redis la petición responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` y no escribe `OCR_PROCESSED`. Sin `GOOGLE_VISION_API_KEY`, con un PDF, un archivo grande o cuota de Vision, la lectura se detiene y el expediente sigue a mano. No hay clave en el repositorio y no se envió un certificado real. El flujo manual de la app (T8) ya sube con URL firmada. T10 muestra el comprobante con la descarga firmada. Guía Mayor queda como última clase: la continuación anual no abre otra inscripción. T11 cubrió el borde HTTP (anónimo 401, dueño sin cola 400, otro miembro 404, miembro en la bandeja institucional 403) el 2026-09-21. La misma base local comprobó que dos aprobaciones simultáneas de una clase dejan una sola inscripción histórica y un solo evento. La misma base recorrió lectura vacía con proveedor falso (sin llamar a OCR.space), captura manual, rechazo con motivo, corrección, reenvío y aprobación: una inscripción `HISTORICAL_CERTIFICATE` / `INVESTIDO`. Guía Mayor Avanzado solo se aprobó después de crear el periodo inactivo y no creó inscripción. Una carrera aprobar/rechazar de Instructor dejó una sola decisión y cero inscripciones. Esas pruebas están en `certificate-import-journey.e2e-spec.ts`. La prueba SQL de colisión sigue en `certificate-import-postgres.e2e-spec.ts`. El mismo recorrido sustituye la inscripción vigente de Guía Mayor: conserva el identificador, pasa a `INVESTIDO` con la fecha del certificado y deja Amigo y Explorador históricos del mismo periodo aunque no exista Compañero. Sin el periodo, la aprobación no cambia la inscripción vigente. Un alta posterior de otra Guía Mayor responde `ENROLLMENT_GM_SINGLE_ROW`. Crear el periodo no lo activa. Una especialidad aprobada queda en `users_honors` con la fecha del certificado y una sola evidencia; reaprobar no duplica la fila ni abre una inscripción. Un administrador genérico y Unión no listan, aprueban, rechazan ni descargan Guía Mayor Avanzado. La bandeja común no lista ni muestra esos registros, tampoco al superadministrador. Solo aparecen en la pantalla institucional, visible únicamente para ese rol. Aprobar y rechazar a la vez una fila de Campo Local deja una sola decisión: o una inscripción histórica, o un rechazo sin inscripción. La Guía Mayor sustituida sigue INVESTIDO con la fecha del certificado: el vencimiento no la toca, no queda un cursado operativo pendiente, el año siguiente no abre otra clase y un alta posterior de la misma clase se rechaza. Un mismo archivo sellado puede traer una clase y una especialidad, y cada fila se decide sola: aprobar la clase no aprueba la especialidad ni cierra el expediente, y rechazar una fila deja la otra pendiente. Decidir el lote entero se rechaza. Si el almacenamiento no entrega el archivo, la lectura no queda como exitosa y el comprobante sellado sigue en el borrador. Confirmar otra vez un archivo ya sellado no vuelve a copiarlo. Reenviar una solicitud institucional, incluso dos veces a la vez, deja una sola solicitud y un solo evento. Después de enviar, no se puede editar ni agregar filas ni enviar de nuevo. La bandeja institucional muestra la lista, el comprobante firmado, la aprobación y el rechazo solo para el superadministrador; la vista previa de una imagen firmada usa la dirección, no un nombre de archivo. Esa pasada fue sobre los componentes de la pantalla, no sobre una sesión abierta en el navegador. El lector solo propone filas si el texto trae `clase:`, `honor:` o `especialidad:`. Un comprobante que nombra la clase y la fecha sin esas etiquetas no crea sugerencias; la persona las captura a mano. Esas sugerencias quedan en revisión y no acreditan inscripción ni especialidad. Una segunda lectura sustituye solo las sugerencias que nadie completó; la fila ya marcada se conserva. Una etiqueta de Guía Mayor Avanzado no abre solicitud institucional ni inscripción. Una investidura histórica cuenta como prerrequisito y como Guía Mayor investido: la clase operativa siguiente se abre, un salto de orden no, y esa Guía Mayor permite otra escala sin crear una segunda fila. En la ficha, el seguro y la lista de la sección, ese logro sigue visible y no se presenta como la clase en curso. El resumen del miembro tampoco lo toma como clase en curso ni abre un checklist. El recálculo de rankings de miembros solo toma inscripciones operativas, borra la fila de puntaje si la inscripción ya pasó a histórica, y el listado, el desglose y el promedio de la sección no la muestran. Si la sustitución de Guía Mayor falla al escribir el historial, la inscripción vigente, su progreso y el expediente quedan como estaban. Dos certificados distintos del mismo año, aprobados primero la clase posterior, quedan históricos sin gastar el cupo: esa persona puede abrir el curso operativo de ese periodo y la inscripción de otra persona no cambia. Si la sustitución de Guía Mayor corre al mismo tiempo que un alta de esa clase, queda una sola fila: la vigente pasa a histórica con la fecha del certificado y el alta nueva se rechaza. Un cursado operativo no investido del mismo periodo se inviste solo si el revisor confirma esa inscripción y su versión: se conservan el identificador, el tipo, el progreso y la fecha de alta. La ficha muestra el comprobante del logro y, si la fila es histórica, el progreso archivado sin checklist. Un revisor de otro campo, un administrador genérico y Unión no entran a la bandeja institucional por HTTP. La bandeja institucional se recorrió en el navegador contra la base local: lista, detalle, aprobar y rechazar. Aprobar no creó `enrollments`. La fecha civil del certificado se muestra en el día del documento. El comprobante de esa corrida respondió `CERTIFICATE_IMPORT_STORAGE_UNAVAILABLE` porque el objeto no está en el almacén. Sigue pendiente la lectura contra el proveedor real. T12 tiene `scripts/audit-certificate-imports.ts`: solo lectura, solo base local cuyo nombre termina en `_test`, y `--apply` se rechaza. No se auditó producción. Esta actualización no es evidencia de que la carga masiva esté terminada.
