# 02 · Revisión de evidencias de clases y honores

**Estado**: DRAFT · **Revisión documental**: 2026-09-09

Primer ejemplo de ficha de flujo. Contraste de documentación de dominio con la
referencia API; todavía no es una prueba del recorrido en un entorno ejecutándose.

[Abrir diagrama interactivo](diagramas/02-revision-evidencias.html).

## Propósito

Permitir que una persona autorizada revise archivos que respaldan el avance de
un miembro en clases u honores, y registre una aprobación o un rechazo justificado.

## Actores y condiciones

- **Carga:** miembro o consejero, según la descripción del dominio. El permiso y
  punto de entrada exactos de cada modalidad de carga siguen pendientes de revisión.
- **Revisión:** el contrato de `/evidence-review/*` exige autenticación, un rol
  global entre `admin`, `super-admin`, `coordinator`, y `validation:review`.
- **Sistema:** ofrece cola/detalle y registra las decisiones en un historial.
- **Contexto:** el alcance de datos permitido por cuenta no queda demostrado solo
  por la lista de roles. No se asume acceso a cualquier miembro o territorio.

## Recorrido documentado

| Paso | Responsable | Acción | Resultado |
|---|---|---|---|
| 1 | Miembro o consejero | Prepara, carga y presenta la evidencia según el flujo del tipo | Evidencia presentada; la carga aislada no prueba envío a revisión |
| 2 | Sistema | Presenta evidencias pendientes | Cola consultable y filtrable por tipo |
| 3 | Revisor autorizado | Abre detalle y revisa los archivos | Evaluación humana; ver el archivo no lo aprueba |
| 4a | Revisor autorizado | Confirma aprobación | Decisión registrada e historial consultable |
| 4b | Revisor autorizado | Rechaza e indica motivo | Rechazo registrado e historial consultable |

Las ramas 4a y 4b son alternativas. El diagrama no afirma que se ejecuten juntas,
ni representa transacciones internas. Las flechas sin etiqueta conectan pasos
consecutivos cuya acción ya está escrita en los nodos.

La API distingue carga de archivos y envío (`submit`) en clases. Por eso el nodo
inicial agrupa preparación/presentación y NO afirma que subir un archivo lo coloque
automáticamente en la cola. El detalle de envío de cada modalidad de honor sigue
pendiente; el diagrama comienza en la evidencia presentada al circuito de revisión.

## Reglas y particularidades

1. La cola genérica cubre **clases y honores**, no carpetas anuales.
2. Aprobar requiere confirmación; rechazar requiere motivo.
3. Las operaciones masivas solo permiten evidencias del mismo tipo.
4. Las decisiones deben dejar historial por evidencia.
5. La documentación indica archivos privados mediante URLs firmadas y un visor PDF
   autenticado en el panel: no confundir archivo privado con URL pública permanente.
6. Validar una evidencia no equivale a completar toda la clase ni a investir.

## Resultados y límites

Beneficio esperado: revisión con una decisión explícita y trazable, en vez de dar
por reconocido todo archivo cargado. No hay mediciones de reducción de tiempo.

El documento de dominio declara como pendientes las notificaciones push de la
decisión, métricas de tiempos promedio y exportación de reportes. Este análisis
no ha comprobado esos límites contra el código actual.

El rechazo no tiene aquí una flecha de regreso automática: falta verificar cómo
se corrige, reenvía y vuelve a revisión cada tipo. También quedan pendientes
comprobaciones de duplicados, concurrencia, archivos inválidos y autorización
territorial. No inventamos esos comportamientos para completar el dibujo.

## Fuentes y trazabilidad

- [Validación de evidencias](../../features/validacion-evidencias.md): descripción,
  requisitos, frontend, decisiones y gaps.
- [Referencia API](../../api/ENDPOINTS-LIVE-REFERENCE.md): sección `evidence-review`,
  rutas de pendientes, detalle, approve/reject, bulk-approve/bulk-reject e history.
- [Dominio](../../canon/dominio-sacdia.md): registrar no equivale a validar;
  validación e investidura son conceptos que deben distinguirse.

El diagrama es una síntesis de estas fuentes, no un export automático del código.
Las reglas, recorridos y excepciones deben mantenerse junto con el JSON al revisar
el flujo. Los hashes del corte se conservan en `evidencias/fuentes.json`.
