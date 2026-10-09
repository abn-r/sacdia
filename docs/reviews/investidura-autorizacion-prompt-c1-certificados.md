# Prompt — C-1: certificados frente a solicitud viva (IA-57 a IA-60)

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. Esta entrega va **después** de R26-1 a R26-5. Spec: `docs/plans/2026-09-28-investidura-autorizacion.md`, sección 3.9 y las reglas nuevas **IA-57 a IA-60**, aprobadas el 2026-10-07. Contexto previo: hallazgos A2 y X-2 en `docs/reviews/investidura-autorizacion-independent-review.md`, revisiones 25 y 26.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- Se permite: Jest, `tsc --noEmit -p tsconfig.build.json`, ESLint y PostgreSQL aislado de loopback (base terminada en `_test`).
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4, P5, P6, P7, W1, X-1, X-2, X-3, X-4 y R26.
- No cambiar los roles que hoy aprueban certificados (`admin-certificate-bulk-imports.controller.ts:34-40` e institucionales).
- **TDD:** registrá la prueba roja antes de cada corrección.
- **Corré la suite unitaria completa** (`pnpm run test`) y ESLint `--no-fix` sobre todos los archivos tocados, specs incluidas.

## Problema

`certificate-bulk-imports-application.service.ts` acredita sin mirar `investiture_authorization_people` y sin los candados de la solicitud. La edad histórica de la fase 0B no cubre estos dos casos, porque en ambos la edad cuadra:

- **Caso 1, mismo año (`accreditHistoricalClass` L395-403 → `reconcileOperationalEnrollment` L495-549).** Pedro, 10 años, cursa Amigo en 2026 y está `PENDING` con el pastor. Llega un certificado de Amigo fechado en 2026. El código pasa su inscripción operativa a `INVESTIDO`, salteando la autorización, y la persona sigue `PENDING`.
- **Caso 2, Guía Mayor de un año anterior (`substituteGuideMajor` L439-484).** Ana, 35 años, cursa Guía Mayor en 2026 y está `PENDING`. Llega un certificado de Guía Mayor de 2019. El código convierte su inscripción de 2026 en `HISTORICAL_CERTIFICATE` de 2019 `INVESTIDO`, y la solicitud queda apuntando a una inscripción que ya no es operativa.
- **Variante del caso 2, otras clases.** Un certificado de un año anterior para AV/CQ crea una fila histórica `INVESTIDO` (L418-436) mientras la operativa sigue `PENDING`. Hoy X-2 la retira recién al resolver, con `ALREADY_INVESTED`.

## Reglas a implementar

1. **IA-57.** Si el año eclesiástico del certificado coincide con el de una inscripción operativa de esa persona y clase que tiene un registro `PENDING`, la aprobación se rechaza con un código nuevo (por ejemplo `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`, con i18n es/en/fr/pt-BR y un mensaje accionable: «la persona tiene una solicitud de investidura pendiente en este año; la autorización tiene prioridad»).
   - No escribe enrollment, historial, evento ni conciliación, y el ítem no queda aprobado.
   - Aplicalo también al marcar listo, al enviar y al reenviar, como aviso temprano. La autoridad es la comprobación al aprobar.
2. **IA-58.** Sin registro `PENDING` de esa persona y clase, el comportamiento actual del mismo año no cambia. Si el Campo rechaza el certificado y el año cierra, la clase queda no investida: verificá que el cierre anual no requiere nada adicional y documentalo.
3. **IA-59.** Si el certificado es de un año **anterior** y existe un registro `PENDING` de esa persona y clase (incluido `substituteGuideMajor` y la variante de AV/CQ), se acredita y **en la misma transacción** el registro pasa a `REMOVED` con un `resolution_code` nuevo (por ejemplo `HISTORICAL_CERTIFICATE_APPLIED`). Además:
   - El texto informativo es «Investidura aplicada por certificado de un año anterior».
   - No usa el texto de falta de requisitos, no emite `class.completed` desde la solicitud ni crea un resultado de autorización.
   - Sale de los recordatorios y queda visible en las lecturas de la solicitud para quienes autorizan y para la directiva.
   - Documentá si corresponde un aviso en la bandeja. Por defecto, no se envía correo.
4. **IA-60.** Las comprobaciones de IA-57 e IA-59 corren dentro de la transacción de aprobación (`approveItem`/`approveItemInTransaction` y la aprobación institucional), bajo los mismos candados advisory de usuario (`investiture-authorization-user:`) y de enrollment (`investiture-authorization-enrollment:`) que usan presentar, agregar y resolver.
   - La aprobación hoy toma `FOR UPDATE` sobre `users`, `classes` y `ecclesiastical_years` (`class-certificate-historical-age.ts:150-166`). Definí y justificá el orden de candados para que no se produzca un interbloqueo con presentar o resolver.
   - Evaluá cambiar esos `FOR UPDATE` por `FOR SHARE` (observación de la revisión de fases 0B–3) y documentá la decisión.

## Aceptación

- **Unidad.** Caso 1 rechazado sin efectos. Caso 1 sin `PENDING`, aceptado como hoy. Caso 2 de Guía Mayor y variante AV/CQ: acreditados, con el `PENDING` en `REMOVED` y `HISTORICAL_CERTIFICATE_APPLIED`, sin evento ni recordatorio. Rechazo o retiro seguidos de reintento del certificado del mismo año: aceptado.
- **PostgreSQL aislado, ambos órdenes:**
  - presentar contra aprobar un certificado del mismo año: nunca quedan juntos un `INVESTIDO` por certificado y un `PENDING`;
  - resolver contra aprobar un certificado de un año anterior: un solo `INVESTIDO` y un solo `class.completed`, sin `PENDING` huérfano;
  - prueba explícita de que no hay interbloqueo.
- Las lecturas de la solicitud muestran el motivo informativo de IA-59.

## Fuera de esta entrega

Las pantallas y la fase 8.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «C-1 certificados frente a solicitud viva» con:

1. Por regla: archivo y línea, la salida roja, la salida verde y la decisión tomada (orden de candados, `FOR SHARE`, aviso en la bandeja).
2. El conteo total de `pnpm run test`, PostgreSQL aislado, `tsc` y ESLint sobre la lista de archivos.
3. Los códigos nuevos y su contrato, en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md` y `docs/features/validacion-investiduras.md`.
4. Migración, si hace falta un valor de enum nuevo, sin aplicar en Neon.
5. Los límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

No des C-1 por cerrado: queda pendiente de revisión independiente.
