# 16 · Verificación de los recorridos pendientes

**Fecha:** 2026-09-16 · **Estado:** revisión focalizada; validación E2E pendiente.

**Resultado:** se localizaron las reaperturas web de carpeta anual y camporee. No se localizaron consumidores de tres operaciones administrativas en los clientes revisados. Pasaron **104 pruebas automatizadas focalizadas** con dependencias simuladas. La inspección del panel local llegó a la pantalla de acceso; no se ejecutaron operaciones autenticadas ni se modificaron registros reales.

Esta ficha complementa el [catálogo de 48 familias](15-catalogo-flujos-usuarios.md), sin ampliar su numeración ni afirmar que todos los flujos están certificados.

## 1. Resultado por pendiente

| Pendiente | Resultado verificado | Tratamiento para la explicación |
|---|---|---|
| Reabrir evaluación de carpeta anual | Acción **Reabrir**, diálogo de confirmación, llamada API y actualización de carpeta localizados en el panel. | Explicar el recorrido; demostrarlo solo con datos de prueba y autorización efectiva. |
| Reabrir inscripción de camporee local/unión | Acción y diálogo conectados a los dos endpoints; bloqueo UI si se conocen registros de evaluación/competencia. | Explicar el recorrido y el bloqueo; no confundir con reapertura de pagos ni aprobación tardía. |
| Revertir compra legacy de cupos de seguro | Backend y pruebas localizados; no se encontró consumidor en admin/app revisados. | **Fuera de la demostración de usuario final.** Describirlo como operación backend del circuito legacy, no inventar un botón. |
| Editar/regenerar/finalizar informes trimestrales/anuales | Contratos backend; clientes revisados muestran consultas/tablas del club, no consumidores administrativos de esas operaciones. | Mostrar únicamente lectura si los datos cargan; mantenimiento fuera de la demo. |
| Administrar reportes de soporte | Alta móvil localizada previamente; no se encontró consumidor de `admin/support` en los clientes revisados. | Mostrar envío móvil como recepción, no prometer bandeja de seguimiento o resolución administrativa visible. |

**Alcance de las conclusiones negativas:** búsqueda estática sobre el checkout local de `sacdia-admin/src` y `sacdia-app/lib`; no prueba ausencia en otras ramas, clientes, despliegues o integraciones dinámicas. No se implementaron pantallas faltantes como parte de este trabajo de documentación.

## 2. Reapertura de evaluación de carpeta anual

**Entrada web:** `/dashboard/clubs/evidence-folders/[folderId]`.

1. Abrir una carpeta dentro del alcance del revisor.
2. Localizar el apartado evaluado y su estado.
3. Para `PREAPPROVED_LF`, `VALIDATED` o `REJECTED`, el componente muestra **Reabrir**.
4. Abrir el diálogo y revisar su advertencia; cancelar no envía la operación.
5. Confirmar llama a `reopenSection`; si tiene éxito, cierra el diálogo y vuelve a consultar la carpeta. Si falla, muestra error.
6. El backend devuelve la evaluación a `SUBMITTED`, limpia decisiones y puntos y recalcula totales. **No vuelve a borrador para editar archivos.**

La visibilidad del botón por estado **no prueba permiso efectivo**; el backend conserva los controles de autorización y territorio. La carpeta debe estar `open`, `under_evaluation` o `evaluated`, y tener una evaluación reabrible.

**Evidencia local:**

- [Página de detalle](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/clubs/evidence-folders/%5BfolderId%5D/page.tsx), líneas 26–50: conecta `EvaluationClientPage`.
- [Componente de evaluación](../../../sacdia-admin/src/components/annual-folders/evaluation-client-page.tsx), líneas 152–159, 215–225, 676–694 y 862–888: condición, botón, ejecución y confirmación.
- [Cliente API](../../../sacdia-admin/src/lib/api/annual-folders.ts), líneas 703–711: POST de reapertura.
- [Reglas backend](../../../sacdia-backend/src/annual-folders/evaluation.service.ts), líneas 537–659: estados, controles y efectos.

## 3. Reapertura de inscripción de camporee

**Entradas web:** `/dashboard/campamentos/[id]` y `/dashboard/campamentos/union/[id]`.

1. Abrir el detalle del evento con capacidad de gestión correspondiente.
2. Si el registro está cerrado, el control ofrece reapertura; si no, ofrece cierre.
3. El control no se renderiza cuando `canManage` es falso. La reapertura queda deshabilitada cuando recibe `hasScoringArtifacts=true`.
4. Abrir el diálogo, leer la consecuencia y confirmar solo sobre un evento de prueba.
5. Se llama al endpoint local o de unión según el evento; éxito refresca la página, error muestra el mensaje.
6. El backend vuelve a comprobar sus propias condiciones. Una pantalla que no detecta todavía los registros de competencia no evita el rechazo del servidor.

**Evidencia local:**

- [Control compartido](../../../sacdia-admin/src/components/camporees/club-registration-actions.tsx), líneas 45–146.
- [Detalle local](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/campamentos/%5Bid%5D/page.tsx), líneas 398–413, y [detalle de unión](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/campamentos/union/%5Bid%5D/page.tsx), líneas 387–403.
- [Cliente API](../../../sacdia-admin/src/lib/api/camporees.ts), líneas 286–294.
- [Servicio backend](../../../sacdia-backend/src/camporees/camporees.service.ts), métodos `reopenLocalCamporeeClubRegistration` y `reopenUnionCamporeeClubRegistration`.

## 4. Búsqueda de interfaces no localizadas

Se consultó primero el grafo (`graft grep`/`callers`) y después el árbol fuente para incluir archivos que pudieran no estar indexados. La comprobación textual abarcó **897 archivos TS/TSX de admin y 1060 archivos Dart de app**, excluyendo nombres de tests y generados `.g`/`.freezed`.

| Patrones comprobados | Resultado |
|---|---|
| `insurance/purchases`, `reverseInsurance`, `reversePurchase` | Sin coincidencias en los dos clientes. |
| `admin/annual-reports`, `admin/quarterly-reports` | Sin coincidencias; sí existen lecturas `/clubs/:id/annual-reports` y `/clubs/:id/quarterly-reports` en admin. |
| `admin/support`, `support_reports`, `listSupportReports`, `updateSupportReport` | Solo una declaración de traducción en admin y un comentario en app; no consumidor administrativo localizado. |
| Páginas admin bajo `support`, `annual-reports`, `quarterly-reports` | Sin rutas con esos segmentos en el árbol revisado. |

Esto sustituye “no lo revisamos” por **“no se localizó en el alcance inspeccionado”**, no por una afirmación absoluta de inexistencia.

Referencias de contraste: [consulta de informes](../../../sacdia-admin/src/lib/api/reports.ts), [tablas en detalle de club](../../../sacdia-admin/src/components/clubs/detail/reports-tab.tsx), [alta móvil de soporte](../../../sacdia-app/lib/features/support/data/datasources/support_remote_data_source.dart), [contrato API](../../api/ENDPOINTS-LIVE-REFERENCE.md).

## 5. Pruebas ejecutadas

| Superficie | Selección | Resultado |
|---|---|---|
| Backend/Jest | Compras de seguro, evaluación de carpeta, servicio de órdenes territoriales y máquina de estados de órdenes. | **4 suites, 99 pruebas: PASS.** |
| Admin/Vitest | `ClubRegistrationActions`: sin permiso, cierre local, bloqueo sin inscritos, reapertura de unión y bloqueo por scoring. | **1 suite, 5 pruebas: PASS.** |

Comandos ejecutados desde cada repositorio, sin build, instalación, seed ni migración:

```sh
# sacdia-backend
pnpm exec jest --runInBand --watchman=false --runTestsByPath \
  src/insurance/insurance-purchases.service.spec.ts \
  src/annual-folders/__tests__/evaluation.service.spec.ts \
  src/field-payment-orders/field-payment-orders.service.spec.ts \
  src/field-payment-orders/state-machine.spec.ts

# sacdia-admin
pnpm exec vitest run src/components/camporees/club-registration-actions.test.tsx
```

Las suites backend sustituyen Prisma y colaboradores por mocks. El componente web sustituye llamadas de cierre/reapertura y router; su setup MSW rechaza solicitudes no manejadas. Los mensajes de órdenes emitidas/canceladas que aparecen en la salida de Jest provienen de estas pruebas con dependencias simuladas, no de acciones sobre personas reales.

**No cubren:** recorrido autenticado completo, permisos de cuentas reales, configuración desplegada, transacciones contra una base real, UI móvil, conservación de formularios tras cortes de red ni garantía universal contra duplicados. No se ejecutó una suite de cancelación de materiales ni de edición de informes mayores en esta selección.

Referencias de checkout al revisar: backend `acf65ba`, admin `5e8160e`, app `9ad81d3b`. Son referencias de HEAD, no una garantía de árboles limpios ni de idéntico despliegue.

## 6. Comprobación visual y bloqueo concreto

- Había servicios escuchando en los puertos locales 3000 y 3001.
- Se abrió el panel en el navegador: `http://localhost:3001` redirigió a `/login?next=%2Fdashboard` y mostró correo, contraseña e **Iniciar sesión**.
- No había sesión disponible en esa pestaña. No se buscaron credenciales, no se inició sesión ni se creó una cuenta.
- No se confirmó qué base de datos usa el entorno local. Que la interfaz esté en localhost **no demuestra que los datos sean desechables**.

**Requisito para continuar con operaciones:** identificar el entorno y los registros de prueba autorizados, y disponer de sesiones de prueba representativas. Hasta entonces, no ejecutar cancelaciones, reaperturas, aprobaciones ni cierres reales.

## 7. Casos pendientes para el entorno de prueba

| Caso | Preparación | Comprobación esperada |
|---|---|---|
| Carpeta: reapertura permitida | Revisor autorizado, carpeta y apartado de prueba elegibles. | Confirmar transición a `SUBMITTED`, decisiones reiniciadas y totales recalculados. |
| Carpeta: rechazo de operación | Apartado no reabrible o actor sin autorización. | Operación denegada, sin cambios persistidos. |
| Camporee: reapertura permitida | Registro cerrado y sin datos que bloqueen; repetir local y unión. | Registro abierto tras confirmación y lectura posterior. |
| Camporee: bloqueo por competencia | Evento de prueba con asignaciones/resultados que bloqueen. | Control deshabilitado o rechazo del backend, sin reapertura. |
| Orden territorial: cancelación | Orden de prueba emitida o con comprobante rechazado, actor autorizado. | Estado cancelado y consulta posterior coherente; orden aprobada no admite esta vía. |
| Materiales: cancelación pagada | Pedido de prueba pagado, sin movimiento bancario real. | Cancelado, stock restaurado, devolución pendiente; no simular ni afirmar reembolso ejecutado. |
| Escritura con resultado incierto | Operación de prueba y fallo de red controlado, sin desconectar otros servicios del usuario. | Consultar resultado antes de repetir; registrar si quedó duplicado o se perdió el formulario. |
| Cambios de rol/contexto | Cuentas representativas y sección/año preparados. | Acceso y alcance correctos; una cuenta no ve ni modifica registros ajenos. |

Los casos son **pendientes**, no pruebas aprobadas. No deben ensayarse sobre registros institucionales reales para completar una presentación.

## Key Learnings:

1. Las reaperturas sí tienen acciones web localizadas; su autorización efectiva debe verificarse con cuentas de prueba.
2. Un contrato backend sin consumidor encontrado no debe enseñarse como botón disponible al usuario.
3. Las 104 pruebas focalizadas aportan evidencia, pero no sustituyen un recorrido autenticado de extremo a extremo.
