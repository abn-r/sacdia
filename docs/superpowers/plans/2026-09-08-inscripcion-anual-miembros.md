# Inscripción anual y nombramientos — Plan de corrección e implementación

**Revisión**: 2026-09-09  
**Estado**: T0–T8 ejecutados en local. D01/D02 siguen abiertos. No declara implementación desplegada.  
**Spec obligatoria**: [diseño corregido](../specs/2026-09-08-inscripcion-anual-miembros-design.md)

> **Para el agente ejecutor:** usa `executing-plans` y TDD. Este documento reemplaza el plan anterior, no se ejecuta junto con él. Lee primero `AGENTS.md` raíz y el contexto del repo. No estás solo en el workspace: conserva los cambios de otros agentes, no hagas reset/checkout destructivo ni regeneres carpetas completas. No crear ramas, commits, PRs o builds sin solicitud explícita. Nunca añadir atribución de IA a commits.

**Goal:** separar retorno, inscripción por directiva y nombramiento vigente, corrigiendo código local que todavía activa automáticamente a quienes vuelven a GM.

**Architecture:** pertenencia no inscrita del año actual mediante CRA `member inactive`, sin permisos; directiva completa la inscripción. Preelección privada en `director_succession_plans`; transición atómica por club/año con garantías temporales de autorización. Matrícula y clase aplicable comparten transacción. No hay tres entregas independientes: seguir el DAG.

**Tech Stack:** herramientas instaladas del proyecto: NestJS, Prisma/PostgreSQL, Redis, Clock institucional, Jest; Flutter/Riverpod y Next.js para integración. Verificar versiones al iniciar, no fijarlas desde notas históricas.

## 0. Mandato y estado de partida

Esta tarea documental NO modificó runtime ni ejecutó sus tests. Al revisar el 2026-09-09 se encontraron cambios locales sin commit:

| Superficie | Hallazgo que el ejecutor debe verificar nuevamente |
|---|---|
| `src/year-cut/year-cut.service.ts` | Crea `member active` al retornar a GM; debe convertirse en **no inscrito**, no solo cambiar copy. |
| `src/year-cut/year-cut.service.spec.ts` | Hay tests que exigen esa inscripción automática; reemplazar la expectativa errónea con R04/A01. |
| `src/annual-membership/annual-membership.service.ts` | Lista por sección/año previo y `active=true`; puede omitir retornados GM y registros cuyo cargo terminó. |
| `src/annual-membership/annual-enroll.controller.ts` | Ofrece activación directa por propietario; D01 no autoriza publicarla. |
| `src/classes/next-class.resolver.ts` | No limita historial al año anterior al objetivo; distingue incorrectamente algunos fallos como fin de trayectoria. |
| `src/common/services/authorization-context.service.ts` | Ya filtra grants por año y vacía permisos no operativos; revisar caché, exposición del cargo futuro y consumidores, sin deshacer correcciones. |
| `prisma/migrations/20260908180000_director_year_slots/migration.sql` | La copia local YA restringe índice a director y ajusta trigger por año. No reintroducir el SQL genérico del plan viejo. Verificar si se aplicó antes de cambiarla. |
| `prisma/schema.prisma` | Ya existe `director_succession_plans`; integrarlo en vez de mantener dos autoridades de programación. |
| App | Ya existe `annual_continuations_view.dart`; adaptar, no duplicar pantallas. |

No asumir que estos archivos están desplegados o que sus pruebas pasan. Documentar HEAD, diff y evidencia actual antes de editar.

### 0.1 Requisitos que NO se reinterpretan

- Retornar a GM no inscribe, no crea clase ni conserva poderes CQ/AV.
- La **directiva** realiza el proceso de inscripción anual. No decir al miembro que debe repetir su registro.
- Un nombramiento nuevo se respeta; no transformarlo en `member` por ejecutar retorno o inscripción.
- La investidura e historial no se pierden al acabar un cargo.
- Inscripción del miembro y matrícula institucional de la sección son distintas.

### 0.2 Decisiones pendientes, con alcance limitado

- **D01:** solicitud propia «quiero inscribirme». No implementar aprobación automática ni inventar aprobación nueva. Bloquear el endpoint local de autoactivación y retirar su CTA mientras no se defina el flujo. Esto no bloquea inscripción por directiva.
- **D02:** clase GM ya investido/multianual y discrepancias edad–trayectoria entre tipos. Detener solo esos escenarios antes de escribir sus reglas; no inventar inscripción avanzada obligatoria, pérdida de avance GM ni permiso para ignorar prerrequisitos.
- Una tarea puede estar implementada sin que D01/D02 estén habilitados. El informe final debe distinguir esas superficies bloqueadas, no declarar el feature integral terminado.

## 1. Dependencias y entregas revisables

```text
T0 baseline + pruebas de contrato
  -> T1 pertenencia no inscrita + integridad de datos
  -> T2 nombramientos programados
  -> T3 corte transaccional + recuperación
  -> T4 autorización temporal + ausencia de fuga en clientes
  -> T5 lista e inscripción por directiva -> T7 app/admin
       T6 clases compartidas -----------^ (antes de habilitar matrícula con clase)
T1..T7 -> T8 verificación integrada + docs canónicas
```

T5 puede preparar lista/validaciones antes de T6, pero no se publica la inscripción con clase hasta integrar T6. T2–T4 se liberan coordinadamente: no activar transición que deje a clientes usando permisos antiguos.

**Review Workload Forecast:** corrección cross-repo y migraciones; riesgo >400 líneas **alto**, estimación preliminar 1.000–2.000 líneas, a reemplazar por diff real. Entregas encadenadas recomendadas: datos/contratos, ciclo+auth, inscripción+clases, clientes. No crear PR monolítico ni commits sin autorización. Si el usuario exige un único PR, obtener `size:exception`; el modo automático no elimina ese control.

## 2. Contratos de destino (propuestos, no runtime vigente)

Todas las rutas bajo `/api/v1`. Mantener envoltorio `{ status, data }` y catálogo de errores/i18n. Cambios incompatibles requieren adaptar clientes en la misma entrega y actualizar documentación canónica.

### 2.1 Nombramientos

- `POST /clubs/:clubId/sections/:sectionId/director-designation`: body `{ user_id, ecclesiastical_year_id }`, encabezado `Idempotency-Key`. Crea programación en `director_succession_plans`, NO CRA `designated`.
- `GET` misma ruta, query `yearId`: programación o `null`. Incluye `succession_id`, usuario, año, fecha efectiva, estado, versión; nunca datos de otro Campo Local.
- `PATCH` misma ruta: `{ succession_id, version, successor_user_id }`; reemplaza antes de vigencia y audita. `DELETE` misma ruta con `successionId` y `version`: cancela plan no activado. No muta al director vigente.
- Solo actores ya autorizados para gestionar dirección y dentro de su territorio; validar que sección pertenece a club de la URL. Aplicar checks también a lectura.
- `director-succession` mantiene reemplazo inmediato del año vigente. Verificar contra **año vigente**, no solo igualdad entre dos IDs enviados.
- `director-assignment` cubre vacante vigente, no preelección futura. Rutas genéricas de asignación/update tampoco pueden saltarse estas reglas.

Errores propuestos: `CLUB_DIRECTOR_PLAN_CONFLICT` (409), `CLUB_DIRECTOR_PLAN_VERSION_CONFLICT` (409), `CLUB_DIRECTOR_PLAN_YEAR_INVALID` (400), `CLUB_DIRECTOR_PLAN_NOT_FOUND` (404). Reutilizar equivalentes existentes cuando sean semánticamente iguales y documentar el mapeo; no duplicar códigos innecesariamente.

### 2.2 Lista e inscripción

- `GET /club-sections/:sectionId/annual-continuations`: miembros no inscritos de la base actual; NO fuente exclusiva de año anterior. Paginación `page`/`limit` y búsqueda acotada. Año destino = vigente en backend.
- Cada elemento: `{ user_id, name, base_section_id, ecclesiastical_year_id, annual_status, current_role, eligibility, blocked_reason, suggested_class }`. `suggested_class` puede estar pendiente/bloqueada; no confundirlo con inscripción ya realizada.
- `POST` misma ruta, body `{ user_ids: string[] }`, máximo 100 distintos; ámbito comprobado por usuario/destino. Reintentos idempotentes por usuario/sección/año; filas no inscritas existentes se activan, no se omiten por existir.
- Respuesta: `{ results: [{ user_id, outcome, club_section_id, ecclesiastical_year_id, enrollment_id, error_code }] }`; `outcome` = `enrolled|already_enrolled|blocked|failed`. `enrollment_id` nullable solo en escenario sin clase expresamente permitido, no como fallback por catálogo roto.
- Una transacción por persona para miembro+clase; reportar claramente fallos parciales del lote. Actor siempre registrado.
- Autorización: directiva vigente con permiso de plantilla en sección destino. Ser dueño del perfil NO permite ejecutar este POST administrativo.
- `POST /users/:userId/membership/annual-enroll`: mientras D01 esté pendiente, rechazar sin efectos con 403 `ANNUAL_ENROLL_REQUIRES_DIRECTIVE`. No devolver éxito engañoso ni convertir el endpoint en otra cosa silenciosamente.

### 2.3 Autorización y errores de ciclo

- `/auth/me`: incluir pertenencia no inscrita actual con permisos vacíos; no devolver programación futura. Contextos seleccionables solamente operativos.
- Campo/rol futuro solo se consulta por endpoint de programación autorizado, no ocultado únicamente en UI.
- Reutilizar `EcclesiasticalYearService`; no crear otro resolver de calendario con criterios distintos.
- Errores propuestos: `ECCLESIASTICAL_YEAR_AMBIGUOUS` (409), `CLUB_CYCLE_NOT_READY` (503 recuperable), `ANNUAL_MEMBERSHIP_BASE_UNRESOLVED` (409), `ANNUAL_CLASS_POLICY_UNRESOLVED` (409). Ausencia de año puede reutilizar el código existente, sin convertirla en acceso permisivo.
- Cambios de ciclo no invalidan JWT por sí mismos. FCM es refresco de UX, no autorización.

## 3. Procedimiento TDD obligatorio para cada tarea

1. Escribir/agregar los tests de aceptación indicados y ejecutar el comando focalizado.
2. Registrar RED por la razón de negocio esperada; si ya pasa, verificar que realmente cubra el caso, no forzar un fallo artificial.
3. Implementar lo mínimo dentro de archivos asignados; compartir transacciones/políticas, no copiar lógica.
4. Ejecutar nuevamente, registrar GREEN y regresiones. No marcar una casilla por inspección solamente.
5. Actualizar docs del comportamiento y entregar diff/evidencia. Commits solo si el usuario los pide.

Todos los comandos backend se ejecutan desde `sacdia-backend/`; los de app desde `sacdia-app/`; los de admin desde `sacdia-admin/`. Usar `pnpm exec` evita descargas accidentales de `npx`. No ejecutar `pnpm lint` si tiene `--fix` global: limitar lint a archivos tocados sin autofix.

## 4. Tareas

### T0 — Capturar baseline y fijar regresiones (R04–R06)

**Archivos existentes a leer/modificar para tests**:
- `sacdia-backend/src/year-cut/year-cut.service.spec.ts`
- `sacdia-backend/src/annual-membership/annual-continuations.service.spec.ts`
- `sacdia-backend/src/common/services/authorization-context.service.spec.ts`

- [x] Registrar `git status --short`, HEAD y diff por repo; identificar modificaciones concurrentes. No asumir ownership de cambios preexistentes.
- [x] Cambiar el test que exige GM activo por A01: cargo CQ termina, cero `member active` GM y cero nuevas clases; aparece como no inscrito del nuevo año.
- [x] Agregar A02 con usuario cuyo único vínculo del año previo es cargo CQ, sin fila GM previa; GET GM y POST GM deben reconocerlo tras retorno válido.
- [x] Agregar A04: mismo usuario nuevo director GM; retorno no crea member adicional ni elimina director.
- [x] Ejecutar y registrar RED, no arreglar tests para conservar la regla vieja.

```bash
pnpm exec jest --runInBand --no-coverage --runTestsByPath src/year-cut/year-cut.service.spec.ts src/annual-membership/annual-continuations.service.spec.ts
```

**Salida**: baseline y fallos esperados identificados por A01/A02/A04; pruebas ajenas preservadas.

### T1 — Representar no inscrito y proteger historial (R04, R07)

**Modificar**:
- `sacdia-backend/prisma/schema.prisma`
- `sacdia-backend/src/annual-membership/annual-membership.service.ts`
**Crear**:
- `sacdia-backend/src/annual-membership/annual-membership-policy.service.ts`
- `sacdia-backend/src/annual-membership/annual-membership-policy.service.spec.ts`
- Una NUEVA migración Prisma fechada de corrección, después de las existentes; no reescribir migración aplicada.

- [x] Tests A02/A09/A10: base válida actual, retorno CQ->GM, historial cerrado, pertenencia transferida, solicitud rechazada, GM deshabilitada, más de una base candidata.
- [x] Resolver base en una política compartida; error explícito si ambigua. No elegir simplemente último cargo o primer club.
- [x] Definir helper transaccional `ensureNotEnrolled(tx, userId, baseSectionId, year)` con fila `member inactive` actual; no toca historia ni crea clase.
- [x] Upsert/reactivación se limita a fila del año actual; no reciclar asignación histórica cambiando año/sección/rol.
- [x] Integridad DB (SQL escrito, no aplicado): unique parcial de member anual; aborta si hay duplicados. Ejecución real pendiente de T8 en PostgreSQL aislado.
- [x] `club_year_transitions` y `outgoing_assignment_id` nullable en schema/migración local. No aplicada a DB compartida.
- [x] Dry-run `reportLegacyConflicts` (unitario, sin mutar). No ejecutado contra Neon ni datos reales.
- [x] Migración previa `20260908180000_director_year_slots` conservada (local, untracked). No se migró Neon.

```bash
pnpm exec jest --runInBand --no-coverage --runTestsByPath src/annual-membership/annual-membership-policy.service.spec.ts
pnpm exec prisma validate
```

`prisma validate` solo valida schema; T8 exige ejecutar SQL en PostgreSQL aislado.

### T2 — Programación privada de director (R01–R03, R06)

**Modificar**:
- `sacdia-backend/src/clubs/director-designation.service.ts` y `.spec.ts`
- `sacdia-backend/src/clubs/clubs.service.ts` y `.spec.ts`
- `sacdia-backend/src/clubs/clubs.controller.ts`
- `sacdia-backend/src/clubs/dto/role-assignment.dto.ts`
- `sacdia-backend/src/clubs/clubs.module.ts`

- [x] RED A05 y pruebas de create/replace/cancel, vacante, territorio ajeno, club/sección de URL distintos, periodo actual/pasado, retry y versión obsoleta.
- [x] Implementar §2.1 sobre `director_succession_plans`; no nueva CRA `designated`. Invalidación/realtime no deben revelar programación al designado.
- [x] Conservar unicidad y auditoría del plan; un request repetido con misma clave y payload devuelve el mismo resultado; misma clave y distinto payload rechaza.
- [x] Adaptar entrada de reemplazo inmediato y asignación inicial a periodo vigente; impedir bypass desde `assignRole`/`updateRoleAssignment` cambiando año/estado/rol.
- [x] Migrar designados legacy mediante herramienta dry-run revisable; bloquear activación de filas no reconciliadas, no ejecutar dos caminos paralelos.
- [x] La migración de índice de director local corregida se conserva/reconcilia, no se reemplaza por unique global que limite miembros.

```bash
pnpm exec jest --runInBand --no-coverage --runTestsByPath src/clubs/director-designation.service.spec.ts src/clubs/clubs.service.spec.ts src/clubs/director-year-slots.migration.spec.ts
```

**Salida**: JSON request/response/errores de §2.1 documentados en API; ninguna programación en perfil del designado.

### T3 — Corte atómico y retorno NO INSCRITO (R03–R08)

**Modificar**:
- `sacdia-backend/src/year-cut/year-cut.service.ts` y `.spec.ts`
- `sacdia-backend/src/year-cut/year-cut-cron.service.ts`
- `sacdia-backend/src/year-cut/year-cut.module.ts`
- `sacdia-backend/src/annual-membership/annual-membership-policy.service.ts`
- `sacdia-backend/src/app.module.ts`
**Crear**: `sacdia-backend/src/year-cut/year-cut-cron.service.spec.ts`.

- [x] RED/GREEN year-cut A01/A04/A07/A10: director CQ retorna no inscrito, secretario/cargo operativo vencido, sección vacante, miembros sin director, nuevo director GM, reintento con ledger `completed`. A02 GET/POST queda T5; A09 vigencia/caché queda T4.
- [x] Eliminar creación automática de `member active` en retorno y contador engañoso `gmMembersCreated`; proponer `returned_not_enrolled` separado de `directors_activated`.
- [x] Seleccionar periodos vencidos por fecha; no `not currentYearId`. No cerrar futuros ni cambiar final histórico ya correcto.
- [x] Transacción por club/año con lock de DB y ledger. Releer candidatos dentro del lock; activar planes, resolver situación final y crear filas no inscritas con política T1.
- [x] Cubrir consejeros/instructores con vigencia vencida y grants pedagógicos; nunca trasladar su autoridad al año siguiente automáticamente.
- [x] Incrementar versiones auth en la transacción; invalidación/notificación posterior con retry durable. Fallo de notificación no duplica inscripción al reintentar.
- [x] Cron y reconciliación al recuperar backend usan el mismo servicio. No depender de las 00:05 para cortar permisos; T4 verifica vigencia antes de operar.
- [x] No llamar `closeYear`, no borrar JWT ni reinscribir sección institucional.

```bash
pnpm exec jest --runInBand --no-coverage --runTestsByPath src/year-cut/year-cut.service.spec.ts src/year-cut/year-cut-cron.service.spec.ts
```

### T4 — Vigencia segura con caché y clientes desactualizados (R01, R07–R09)

**Modificar**:
- `sacdia-backend/src/common/services/ecclesiastical-year.service.ts` y `.spec.ts`
- `sacdia-backend/src/common/services/authorization-context.service.ts` y `.spec.ts`
- `sacdia-backend/src/auth/auth.service.ts` y `.spec.ts`
- `sacdia-backend/src/common/guards/permissions.guard.ts` y tests focalizados si el recorrido lo requiere
- `sacdia-backend/src/clubs/clubs.service.ts` (año de roster)
- `sacdia-backend/src/common/common.module.ts`

- [x] RED A05/A06/A09: reloj institucional, calendario no enero, sin año, años solapados, caché cargada antes del corte, cron caído, revisión de fechas mientras existe caché.
- [x] Resolver año/revisión antes de reutilizar caché y limitar TTL a próxima frontera. Obtener transición completada T3 antes de exponer operación del periodo nuevo; error recuperable si no se puede completar.
- [x] Evitar ciclo de DI auth->year-cut->auth: extraer coordinación/repositorios y emitir invalidación tras commit sin recursión en resolución de permisos.
- [x] No exponer planes/directores futuros en `grants`, legacy context, selector o perfil. No inscritos conservan banner/pertenencia sin permisos operativos.
- [x] Inspeccionar consumidores de `grants.club_assignments`, consultas CRA y permisos directos con alcance de club: ningún atajo extiende un cargo vencido. No alterar roles globales legítimos fuera del alcance.
- [x] Rechazar PATCH context a futuro/inactive/ended; no confiar en estado de UI ni evento FCM recibido.

```bash
pnpm exec jest --runInBand --no-coverage --runTestsByPath src/common/services/ecclesiastical-year.service.spec.ts src/common/services/authorization-context.service.spec.ts src/auth/auth.service.spec.ts
```

### T5 — Lista e inscripción por directiva (R04–R06, R09)

**Modificar**:
- `sacdia-backend/src/annual-membership/annual-membership.service.ts`
- `sacdia-backend/src/annual-membership/annual-continuations.controller.ts`
- `sacdia-backend/src/annual-membership/annual-enroll.controller.ts`
- `sacdia-backend/src/annual-membership/annual-membership.module.ts`
- `sacdia-backend/src/annual-membership/dto/annual-continuation.dto.ts`
- `sacdia-backend/src/annual-membership/annual-continuations.service.spec.ts`
**Crear**: `sacdia-backend/src/annual-membership/annual-continuations.controller.spec.ts`.

- [x] RED A02/A03/A11/A15: retornado GM sin fila previa, miembro ausente un año con pertenencia válida, actor ajeno/owner, inscripción repetida, cargo nuevo preservado y fallo en clase.
- [x] GET/POST usan política T1 y año actual, con paginación real; no filtrar elegibilidad por `active=true` de cargos históricos ni lista exclusiva del año pasado.
- [x] POST reconoce primero una inscripción ya completada en el destino autorizado y devuelve `already_enrolled`, aunque el usuario ya no aparezca en GET de no inscritos. No usar la ausencia en ese listado para rechazar un retry válido.
- [x] Cambiar `already_continued` global de club por estado de inscripción de la sección objetivo. No confundir director actual en otra sección con miembro inscrito aquí.
- [x] Activar la fila `member inactive` actual, no saltarla porque existe con `status != ended`; revalidar estados rechazados/pendientes por su flujo correspondiente.
- [x] Registrar actor y repetir sin duplicados. Cada persona comparte transacción con servicio T6; no invocar `ClassesService.enrollUser` si abre otra transacción.
- [x] Lote devuelve outcomes de §2.2; no abortar sin informar a quién ya inscribió una iteración anterior.
- [x] Conservar cargo vigente durante inscripción; cambiar sección por trayectoria solo con autoridad destino, no por identidad del club.
- [x] Deshabilitar activación directa de annual-enroll con error explícito hasta D01. No convertirla en solicitud `pending` sin requisito aprobado.

```bash
pnpm exec jest --runInBand --no-coverage --runTestsByPath src/annual-membership/annual-continuations.service.spec.ts src/annual-membership/annual-continuations.controller.spec.ts
```

**Gate**: T5 no está listo para matrícula con clase hasta integrar y verificar T6.

### T6 — Política de clase compartida e historial protegido (R11–R12)

**Modificar**:
- `sacdia-backend/src/classes/next-class.resolver.ts` y `.spec.ts`
- `sacdia-backend/src/classes/classes.service.ts` y `.spec.ts`
- `sacdia-backend/src/classes/classes.module.ts`
- `sacdia-backend/src/classes/class-progress-access.service.ts`
- `sacdia-backend/src/classes/class-progress-scope.service.ts` y `.spec.ts`
- `sacdia-backend/src/annual-membership/annual-membership.service.ts`
**Crear**:
- `sacdia-backend/src/classes/class-enrollment-policy.service.ts` y `.spec.ts`
- `sacdia-backend/src/classes/class-enrollment-writer.service.ts` y `.spec.ts`

- [x] RED A11/A12/A13/A14: siguiente clase en nuevo año sin investir anterior, historial futuro/cruzado excluido, no salto indebido, catálogo incompleto distinto de final, disponibilidad y edad, concurrencia de inscripción.
- [x] Definir respuesta discriminada del resolver: `next_class`, `policy_blocked`, `configuration_error`, y `no_class_required` solo cuando D02 lo autorice. No `null` que mezcle todas las causas.
- [x] Compartir política de clase, límites y writer que recibe `Prisma.TransactionClient`; invocar desde inscripción por directiva y endpoint de clases, sin dos motores que apliquen reglas distintas.
- [x] Consultar historial regular de periodos anteriores al objetivo. No tratar mayor `year_id` como posterior ni exigir `display_order+1` numérico.
- [x] Identificar prerrequisito de trayectoria que contradice R11 y conservar requisitos independientes. Si catálogo no permite distinguirlos, detener ese caso y registrar decisión antes de migrar datos.
- [x] D02: confirmar clase de GM investido/multianual y transiciones entre tipos antes de habilitarlas. No borrar evidencias, forzar avanzada o convertir errores de catálogo en matrícula sin clase.
- [x] Añadir guard de escritura temporal común a PATCH progreso, archivos y submit; owner bypass no lo evita. Lectura histórica conserva alcance y no ejecuta ese guard de escritura.
- [x] Retomar como GM investido crea enrollment nuevo del ciclo permitido; si ya existe uno con progreso, reintento no reinicia ni borra avance. Lista cruzada no crea membresía AV/CQ.

```bash
pnpm exec jest --runInBand --no-coverage --runTestsByPath src/classes/next-class.resolver.spec.ts src/classes/class-enrollment-policy.service.spec.ts src/classes/class-enrollment-writer.service.spec.ts src/classes/classes.service.spec.ts src/classes/class-progress-scope.service.spec.ts src/annual-membership/annual-continuations.service.spec.ts
```

### T7 — App y handoff administrativo (contrato primero)

**Codex / app — adaptar existentes**:
- `sacdia-app/lib/features/members/presentation/views/annual_continuations_view.dart`
- `sacdia-app/lib/features/members/presentation/views/members_view.dart`
- `sacdia-app/lib/features/members/presentation/providers/members_providers.dart`
- `sacdia-app/lib/features/members/data/datasources/members_remote_data_source.dart`
- `sacdia-app/lib/features/members/data/repositories/members_repository_impl.dart`
- `sacdia-app/lib/features/members/domain/repositories/members_repository.dart`
- `sacdia-app/lib/features/members/domain/entities/annual_continuation.dart`
- `sacdia-app/lib/features/members/data/models/annual_continuation_model.dart`
- `sacdia-app/lib/features/auth/data/models/user_model.dart`
- `sacdia-app/lib/features/home/presentation/widgets/club_context_card.dart`
- Localización/contratos auth/realtime encontrados por referencias; no asumir que el switcher «se corrige solo».

**Crear pruebas**:
- `sacdia-app/test/features/members/annual_membership_contract_test.dart`
- `sacdia-app/test/features/members/annual_membership_flow_test.dart`

- [x] Tests DTO/outcomes, ausencia de futuro director, banner no inscrito, lista directiva GM con retornado y reanudación después del corte.
- [x] La directiva ve «Miembros no inscritos» y acción «Inscribir para [periodo]»; usuario ve «No inscrito este año. La directiva realiza tu inscripción».
- [x] Retirar CTA de autoactivación mientras D01 no esté definido. No reabrir registro ni afirmar que se perdió investidura.
- [x] Manejar fallos parciales y `blocked_reason`, recargar auth al inscribir/cambiar ciclo y purgar datos operativos de sección anterior. FCM no garantiza refresh ni acceso seguro offline.
- [x] Mantener nombramiento vigente prioritario respecto a banner de otra sección; no esconder director GM por ser no inscrito en otro contexto.

```bash
flutter test test/features/members/annual_membership_contract_test.dart test/features/members/annual_membership_flow_test.dart
flutter analyze
```

**Evidencia T7 (2026-09-09):** `flutter test` de esos dos archivos: **exit 0**. Auth utils relacionados también GREEN. `flutter analyze` en `sacdia-app`: exit 1 por **7** avisos previos, ninguno en archivos de T7. Admin: sin UI; runner real en el handoff (`cd sacdia-admin && pnpm test` = vitest run; `pnpm exec tsc --noEmit`).

**Cursor / admin — solo después del contrato backend**:
- `sacdia-admin/src/lib/api/clubs.ts`
- `sacdia-admin/src/lib/clubs/actions.ts` y `actions.test.ts`
- `sacdia-admin/src/lib/auth/director-succession.ts` y `.test.ts`
- `sacdia-admin/src/app/(dashboard)/dashboard/clubs/[id]/page.tsx` y componentes referenciados.

Entregar request/response de §2, autorización territorial, errores, control de versión, estados loading/empty/blocked/partial y copy. Campo Local ve programación futura separada del director operativo. Codex no rediseña admin; Cursor adapta UI existente. El ejecutor verifica el runner real del admin antes de escribir el comando de prueba y lo deja registrado en su informe, además de `pnpm exec tsc --noEmit`.

### T8 — Verificación integrada, datos y documentos

**Crear**:
- `sacdia-backend/test/annual-cycle-postgres.e2e-spec.ts`
- `sacdia-backend/test/annual-membership-http.e2e-spec.ts`
- `sacdia-backend/test/helpers/annual-cycle-db.helper.ts`

**Seguridad del entorno de pruebas**:
- [x] El helper exige una variable de test dedicada `SACDIA_TEST_DATABASE_URL` (nueva, solo test) y rechaza destinos no loopback y DB sin sufijo `_test`. No fallback a `DATABASE_URL` ni `.env` reales.
- [x] Después de validar el destino, configurar la conexión Prisma del proceso de test con esa URL antes de importar/bootstrap de la app. No permitir que dotenv la reemplace por una conexión compartida.
- [x] Provisionar PostgreSQL desechable compatible con migraciones/extensiones del proyecto; fixtures explícitos de roles, dos años, club y secciones. No ejecutar seed global en entornos compartidos.
- [x] Ejecutar SQL real de migraciones, índices y triggers en esa DB. Mocks o búsqueda de texto SQL no sustituyen esta prueba.

```bash
# El helper valida el destino antes de abrir conexión o ejecutar SQL.
# La variable debe apuntar a una DB local desechable; nunca imprimir credenciales.
pnpm exec jest --config test/jest-e2e.json --runInBand --runTestsByPath test/annual-cycle-postgres.e2e-spec.ts test/annual-membership-http.e2e-spec.ts
pnpm exec tsc --noEmit
pnpm exec tsc --noEmit -p tsconfig.build.json
```

- [x] A01–A15 con HTTP real/DB según caso; probar actores directiva, propietario no directivo y Campo Local ajeno.
- [x] Concurrencia REAL: dos conexiones para programar/activar y dos para inscribir; rollback a mitad, restart, cache caliente al límite y push perdido.
- [x] A08: DB permite dos members y dos subdirectores según cupos; rechaza dos directores simultáneos y membresía anual duplicada.
- [x] Verificar sin logout, sin `closeYear`, sin modificaciones de historia y sin matrícula de clase en corte.
- [x] Dry-run de reconciliación de datos heredados; aprobación antes de aplicar fuera de DB desechable. No considerar resuelto solo porque no fallan tests nuevos.
- [x] Validar contratos anteriores/clientes; documentar deprecación del autoenroll si existía consumidor. No publicar interfaz incompatible aislada.

**Docs a actualizar al implementar comportamiento**:
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- `docs/features/gestion-clubs.md`
- `docs/features/membership-requests.md`
- `docs/features/clases-progresivas.md`
- `docs/features/auth.md`
- `docs/features/cron-automation.md`
- `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/database/schema.prisma` y `docs/database/SCHEMA-REFERENCE.md`
- Manuales equivalentes del portal `sacdia-docs` si publican esos flujos; localizar fuente vigente antes de editar, no duplicar documentación histórica.

**Evidencia T8 (2026-09-09):**

```text
SACDIA_TEST_DATABASE_URL=<loopback, nombre *_test>
cd sacdia-backend
pnpm exec jest --config test/jest-e2e.json --runInBand --runTestsByPath test/annual-cycle-postgres.e2e-spec.ts test/annual-membership-http.e2e-spec.ts
# 20 passed, 2 suites, exit 0
pnpm exec tsc --noEmit -p tsconfig.build.json
# exit 0
```

`pnpm exec tsc --noEmit` (tsconfig raíz, sin `-p`) sigue fallando por tipos Jest no listados: miles de `describe`/`expect` en `test/` y `scripts/`, preexistente, no introducido por T8.

**Riesgos y límites T8 (no cerrados):**
- D01: autoenroll sigue 403 `ANNUAL_ENROLL_REQUIRES_DIRECTIVE`.
- D02: GM investido/multianual y cruce AV→CQ por inscripción anual siguen `blocked` `ANNUAL_CLASS_POLICY_UNRESOLVED`; A14 no habilita membresía CQ al cursar cruzado.
- Historial Prisma no es replayable; T8 aplica `prisma migrate diff --from-empty` más SQL de índices/triggers. No se migró Neon ni se usó `DATABASE_URL` compartida.
- Postgres local Homebrew (loopback, DB `*_test`), no Docker. El client Prisma del entorno local requirió `prisma generate` porque faltaba `club_year_transitions`.
- `NODE_ENV=test` usa cupo de throttler de 3 req/s; las suites HTTP esperan 1.2s entre ráfagas. No se relajó el cupo de producción.
- Segundo director: PostgreSQL puede responder `23514` (trigger) o `23505` (único parcial).
- Concurrencia HTTP de programación de director: cubierta en `test/annual-membership-http.e2e-spec.ts` (dos POST, un 201 y un 409 `CLUB_DIRECTOR_PLAN_CONFLICT`; misma Idempotency-Key reutiliza `succession_id`; PATCH+GET). El corte concurrente sigue en `applyCut` ×2.
- A13 HTTP: PATCH de progreso histórico y `POST .../sections/:sectionId/submit` del enrollment no operativo → 403 `CLASS_PROGRESS_YEAR_NOT_OPERATIONAL`. Upload multipart no se re-probó por HTTP (sí en unidad).
- FCM «push perdido» no se simuló; el contrato sigue siendo: el corte no blacklistea JWT y FCM no autoriza.
- Portal `sacdia-docs` no está vacío: nota corta en técnico (gestión de clubs, API, clases, admin-integration) que apunta a docs canónicos del workspace, sin duplicar contratos.
- No desplegado. No builds de app. Sin commits.

## 5. Handoff listo para copiar al agente ejecutor

> Implementa la corrección de inscripción anual siguiendo `docs/superpowers/specs/2026-09-08-inscripcion-anual-miembros-design.md` revisión 2026-09-09 y este plan, no su versión anterior. Empieza por T0 y avanza por dependencias en entregas pequeñas. Ya hay código local de otros agentes: verifica el diff y conserva sus cambios. Regla esencial: retorno GM crea estado NO INSCRITO, la DIRECTIVA realiza la inscripción y un nombramiento nuevo válido no se pierde. No ejecutar builds, commits, crear ramas ni modificar datos compartidos sin solicitud explícita. Deshabilita activación directa por propietario mientras D01 esté pendiente; no inventes reglas D02. Usa TDD, pruebas PostgreSQL aisladas y actualiza contratos/documentación con el cambio. No rediseñes admin: prepara handoff para Cursor. Devuelve tareas completadas, evidencia RED/GREEN, archivos cambiados, decisiones pendientes y siguiente entrega; no declares terminado lo que esté bloqueado o no probado.

No se ha creado ni enviado una nueva tarea: este es el texto de transferencia para que el usuario lo entregue a otro agente.
