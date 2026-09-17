# Inscripción anual, corte y sucesión

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14  
**Propósito:** cerrar el bloque de conocimiento sobre continuidad de personas,
corte de año y cambio de dirección sin confundir regla de negocio, contrato,
implementación ni disponibilidad desplegada.

> Esta ficha es una explicación verificable, no reemplaza el canon ni certifica
> que las tres superficies estén desplegadas en el mismo entorno. La autoridad
> operativa del API es `docs/api/ENDPOINTS-LIVE-REFERENCE.md`; para datos manda el
> schema efectivo de `sacdia-backend/prisma/schema.prisma`.

## Cinco mensajes para una presentación ejecutiva

1. **El corte abre el año; no inscribe personas automáticamente.** Cierra
   cargos vencidos, activa sucesores programados y deja a la persona como
   `member inactive` para que la directiva decida.
2. **La autoridad de inscripción es la directiva de la sección destino.** El
   dueño del perfil no puede autoactivarse: el endpoint de autoinscripción
   responde `403 ANNUAL_ENROLL_REQUIRES_DIRECTIVE` sin efectos.
3. **Inscribir no copia cargos.** Activa la pertenencia `member` del año vigente
   y resuelve una clase regular del mismo tipo; un director en otra sección no
   cuenta como inscrito en la sección destino.
4. **Preelegir no es reemplazar hoy.** `director-designation` programa el año
   futuro; `director-succession` termina al director operativo del año vigente y
   crea otro inmediatamente.
5. **La política de clase todavía tiene límites explícitos.** Cruces de tipo,
   catálogos agotados, clases multianuales y ciertos casos de Guías Mayores se
   bloquean; no deben venderse como automatización completa.

## Ciclo anual comprobado

1. `EcclesiasticalYearService.getCurrentYear()` determina el año por fechas. No
   se usa un `year_id` distinto como atajo para decidir qué está vigente.
2. Al iniciar el módulo y cada día a las **06:05 UTC**, `YearCutCronService`
   llama la misma ruta `YearCutService.applyCut()`. Usa lock Redis de 23 horas;
   dentro de cada club/año usa `pg_advisory_xact_lock` y el ledger único
   `club_year_transitions`.
3. El corte selecciona asignaciones `status=active` cuyo año saliente termina
   antes del inicio del año vigente; las termina como `active=false,
   status=ended`, conservando un `end_date` anterior más temprano cuando existe.
   También cierra consejeros pedagógicos vencidos.
4. Los planes `director_succession_plans.status=scheduled` con fecha efectiva
   alcanzada se materializan como CRA `director, active` del año vigente. No se
   convierten filas CRA heredadas `designated`.
5. Para quienes vuelven sin inscripción, la política crea una fila `member,
   inactive` del año vigente. El corte no crea `member active`, no crea clases,
   no llama `closeYear` y no invalida JWT; invalida el cache de autorización de
   los usuarios afectados después del commit.
6. La directiva consulta e inscribe desde la sección destino. El POST activa la
   fila `member inactive` y, en la misma transacción, crea o reactiva el
   `enrollment` de la siguiente clase regular.

**Qué significa “no interesado”:** no hay endpoint de rechazo, pausa o
postergación para este ciclo. Si nadie ejecuta la inscripción de la directiva,
la persona permanece `member inactive`, sin permisos operativos; la app muestra
el aviso correspondiente y no ofrece un CTA de autoinscripción.

## Estados: histórico, vigente y futuro

| Estado/registro | Significado | Qué se conserva o cambia |
|---|---|---|
| CRA histórico `active` cuyo año terminó | Cargo cerrado por corte | Pasa a `ended`, `active=false`; no se reescribe el histórico como `inactive`. |
| CRA `member inactive` del año vigente | Pertenencia anual aún no confirmada | Aparece como “no inscrito”; no está en la bandeja de `membership-requests`. |
| CRA `member active` del año vigente | Miembro operativo de esa sección | El POST repetido devuelve `already_enrolled`. |
| CRA `director active` | Dirección operativa de una sección/año | Es la que entra en autorización efectiva y liderazgo vigente. |
| Plan `director_succession_plans scheduled` | Preelección privada del año futuro | No es CRA, no aparece en `/auth/me`, no cambia hoy al director. |
| CRA histórico `designated` legado | Dato no reconciliado | El corte no lo activa; las mutaciones directas lo rechazan hasta regularización. |
| `pending` | Primer ingreso/post-registro esperando aprobación | No es la continuación anual de un miembro existente. |

## Matriz actor × acción × alcance

| Acción | Actor aceptado por backend | Alcance y enforcement | Cliente comprobado |
|---|---|---|---|
| Listar no inscritos (`GET annual-continuations`) | Actor con `club_members:approve` | Recurso `club_section` por `sectionId`; año vigente; pertenencia resuelta por política, no roster exclusivo del año anterior. | App móvil; no se encontró implementación equivalente en `sacdia-admin/src`. |
| Inscribir lote (`POST annual-continuations`) | Directiva/actor con `club_members:approve` en la sección destino | 1–100 UUID distintos; owner del perfil no autoriza; resultado por usuario: `enrolled`, `already_enrolled`, `blocked` o `failed`; actor queda auditado. | App móvil; admin aún no consume este contrato. |
| Autoinscribirse (`POST users/:userId/membership/annual-enroll`) | El guard permite permiso `registration:complete` + owner, pero el servicio lo bloquea deliberadamente. | Siempre `403 ANNUAL_ENROLL_REQUIRES_DIRECTIVE`; sin escritura, ni `pending`, ni éxito simulado. | Data source/notifier Flutter conservados, pero la UI no los llama. |
| Asignación inicial de director | `super-admin`, `admin`, `director-lf`, `assistant-lf` con permiso/alcance de club | Crea director operativo solo del año vigente; no sustituye la preelección futura. | API disponible; no es el flujo anual de continuidad. |
| Reemplazo operativo (`POST director-succession`) | Backend: roles globales `super-admin`, `admin`, `director-lf`, `assistant-lf` + `canManageClub`; requiere `club_roles:assign` y `club_roles:revoke`. | `current_assignment_id` debe ser director activo de la sección y del año vigente; transacción termina el actual y crea el nuevo. | Acción administrativa existe, pero no se encontró formulario conectado en la UI actual. |
| Preelección futura (`POST director-designation`) | `super-admin`, `admin`, `director-lf`, `assistant-lf` + `canManageClub`; permiso `club_roles:assign`. | Sección debe pertenecer al club de la URL; año por fecha debe ser futuro; exige `Idempotency-Key`; un plan abierto por sección/año. | Admin: bloque en detalle de secciones. |
| Leer/reemplazar/cancelar plan futuro (`GET/PATCH/DELETE director-designation`) | Mismos actores y alcance de la preelección. | `PATCH` usa `succession_id + version`; `DELETE` usa `successionId + version`; no mutan al director operativo. | Admin lee y reemplaza; no se encontró botón/cliente de cancelación. |

**Diferencia de exposición en admin:** la acción server-side de sucesión
operativa hace un pre-check más estrecho y solo deja pasar explícitamente
`director-lf`/`assistant-lf`, aunque el backend permite también `admin` y
`super-admin` con `canManageClub`. Es una diferencia de superficie que debe
resolverse antes de presentarla como capacidad uniforme.

## Continuidad de clase y casos borde

### Regla normal

`NextClassResolver` busca matrículas anteriores regulares (`cross_type=false`)
del mismo `club_type_id`, solo de años cuyo fin sea anterior al inicio del año
objetivo. Si no hay historial, propone la primera clase activa; si hay historial,
elige la siguiente clase existente por `display_order`, no por aritmética `+1`.
El resultado conserva la sección de origen y no habilita cruce de tipo.

`ClassEnrollmentPolicyService` en modo `annual` omite la investidura de la clase
predecesora inmediata del mismo tipo, pero mantiene prerrequisitos independientes
y `requires_invested_gm`. Una clase con `max_duration_years > 1`, catálogo vacío,
trayectoria agotada o clase resuelta en otra sección produce
`ANNUAL_CLASS_POLICY_UNRESOLVED`; prerrequisito incumplido y falta de investidura
GM producen códigos específicos. La activación de membresía y la matrícula son
una sola transacción: si la política o el writer fallan, el `member` no queda
activado parcialmente.

### Bordes relevantes

- **Sin interés/no acción:** queda `inactive`; no existe rechazo explícito ni
  autoinscripción.
- **Cambio de sección:** el listado y el POST están acotados a la sección
  destino. Un director activo en otra sección no es `already_enrolled` aquí.
  Una transferencia aprobada tiene prioridad al resolver la base; una base
  ambigua bloquea la continuidad.
- **Cambio de edad:** el canon determina clase por edad al inicio del año y no
  cambia durante ese ciclo. Primera inscripción de un tipo: clase por edad.
  Continuidad en el mismo tipo: siguiente `display_order`. El salto formativo
  AV→CQ / CQ→GM (R13–R14) no se infiere solo por edad: exige última clase
  cursada del origen, edad mínima al 1 de enero destino y sección destino activa.
- **Guías Mayores:** el corte puede retornar directivos de AV/CQ a GM como
  `member inactive` aun sin CRA previo de GM. La inscripción se bloquea si falta
  investidura GM requerida o si no está definida la siguiente clase.
- **Director nuevo/viejo:** el viejo termina en el año saliente; el sucesor
  programado se crea como director operativo del nuevo año y no como `member`.
  Si el sucesor ya es director activo en otra sección, eso no lo inscribe en la
  sección destino.
- **Plan y director existente:** si el corte encuentra ya un director activo en
  la sección, salta ese plan. El ledger del club puede completar dejando el plan
  en `scheduled`; requiere reconciliación operativa y no debe confundirse con
  activación confirmada.

## Idempotencia, fallos y observabilidad

- El ledger evita repetir un club/año ya `completed`; el lock transaccional evita
  dos cortes concurrentes. Un `in_progress` o fallo vuelve a ser candidato en la
  siguiente ejecución.
- El índice parcial anual impide dos miembros activos/inactivos de la misma
  persona, sección y año. El writer de `enrollments` reutiliza una fila existente
  y recupera conflictos de unicidad; el segundo POST responde `already_enrolled`.
- El lote deduplica UUIDs en memoria y aísla cada usuario en su propia
  transacción. `blocked` representa una política conocida; `failed` representa
  fallo no clasificado/infraestructura. Solo el resultado `enrolled` genera el
  evento de auditoría `ANNUAL_ENROLL`.
- La invalidación de autorización ocurre post-commit y captura fallos de cache;
  un Redis caído no revierte el corte. El cron captura y registra el error sin
  propagarlo al scheduler.
- **Riesgo pendiente:** cuando falta el rol `director` o existe un director
  activo que hace saltar un plan, `activateScheduledPlans` devuelve sin marcar el
  plan como `activated`, mientras el ledger puede terminar. Hace falta una cola o
  reporte de planes `scheduled`/`blocked` vencidos.

## Implementación por superficie (corte 2026-09-14)

| Superficie | Implementado y comprobado en código | Ausente o no certificado |
|---|---|---|
| Backend | Controllers, permisos, política de pertenencia, transacciones, auditoría, corte cron/recovery, plan futuro y errores documentados. | No se ejecutaron tests ni se verificó entorno desplegado en esta revisión. |
| App móvil | Tarjeta visible con `club_members:approve`; vista GET/POST, selección por lote, refresco de auth y estados parcial/bloqueado/fallido. Banner `member inactive` sin CTA “Inscribirme”. | El widget deshabilita solo `eligibility=blocked`; el backend siempre construye `eligibility=eligible` y expresa el bloqueo de clase en `suggested_class`. Así, una clase bloqueada puede seleccionarse y recién fallar al POST; la UX no muestra la sugerencia de clase. |
| Admin web | Detalle de club: preelección (`director-designation`), sucesión operativa del año vigente (`director-succession`) y bloque de `annual-continuations` (incluye salto de tipo) en el tab de secciones. | Consumo local; no certifica entorno desplegado. |
| Documentación/deploy | API, RBAC, gestión de clubes y cron describen el contrato; las migraciones recientes constan como aplicadas a Neon **development** el 2026-09-11 en la documentación. | Producción, paridad de artefactos y disponibilidad end-to-end no fueron verificadas. El `CLAUDE.md` del admin aún describe un reset anterior; para el estado actual prevalece el código y la referencia API. |

## Pendientes de negocio y entrega

1. Resolver D01: mantener directiva como única autoridad o definir formalmente
   cuándo permitir autoinscripción, con permisos, auditoría y UX.
2. D02 salto formativo AV→CQ / CQ→GM cerrado en spec 2026-09-16 (R13–R14).
   Sigue abierto: clases GM con `max_duration_years > 1` y política de GM
   investido/multianual. D01 (`annual-enroll` 403) no cambia.
3. Definir “no interesado”: rechazo, recordatorio, caducidad o simplemente
   permanencia `inactive`; hoy solo existe permanencia silenciosa.
4. Admin ya consume `annual-continuations` y sucesión en el tab de secciones;
   no inventar `annual-enroll` en el panel.
5. Añadir reconciliación/alerta para planes futuros que no se activan por slot
   ocupado o rol faltante, y verificar si el `scheduled` residual es aceptable.
6. Verificar en el entorno objetivo las tres migraciones de ciclo, el cron,
   Redis/lock y el flujo completo con datos ficticios; la documentación de
   development no equivale a evidencia de producción.

## Pruebas leídas (no ejecutadas)

- Backend unitario: `annual-continuations.service.spec.ts` cubre inclusión sin
  CRA previo, skip-year, director de otra sección, duplicación, rollback de
  política, GM/prerrequisitos y D01; `year-cut.service.spec.ts` cubre cierre,
  sucesor, GM, vacante, ledger, `designated` legado, cache y no reescritura.
- Backend HTTP/Postgres: `annual-membership-http.e2e-spec.ts` y
  `annual-cycle-postgres.e2e-spec.ts` cubren 403 de owner/otra sección/LF,
  concurrencia, resultados por usuario, sucesor operativo y ledger.
- App: `annual_membership_contract_test.dart` y
  `annual_membership_flow_test.dart` cubren DTOs, banner sin autoinscripción,
  CTA de directiva y estados de autorización.

## Evidencia primaria (archivo:línea)

- `sacdia-backend/src/year-cut/year-cut-cron.service.ts:26-44,46-78` — recovery,
  cron, lock, efectos excluidos.
- `sacdia-backend/src/year-cut/year-cut.service.ts:75-80,93-127,163-189,199-324` —
  alcance, ledger y transacción del corte.
- `sacdia-backend/src/year-cut/year-cut.service.ts:404-478,480-603` — activación
  de planes, retorno AV/CQ→GM y resolución de no inscritos.
- `sacdia-backend/src/annual-membership/annual-continuations.controller.ts:36-118`
  y `dto/annual-continuation.dto.ts:12-35` — contrato, permiso y límites.
- `sacdia-backend/src/annual-membership/annual-membership.service.ts:113-252,254-357`
  — lista actual, lote, actor y auditoría.
- `sacdia-backend/src/annual-membership/annual-membership.service.ts:360-526` —
  estados, transacción, clase y códigos bloqueados.
- `sacdia-backend/src/annual-membership/annual-membership-policy.service.ts:48-136,139-210`
  — base de pertenencia y fila `member inactive`.
- `sacdia-backend/src/annual-membership/annual-enroll.controller.ts:26-59` y
  `annual-membership.service.ts:287-292` — D01 sin efectos.
- `sacdia-backend/src/classes/next-class.resolver.ts:30-147` y
  `class-enrollment-policy.service.ts:26-138` — continuidad de clase y D02.
- `sacdia-backend/src/clubs/clubs.controller.ts:419-557` — sucesión vigente y
  designación futura.
- `sacdia-backend/src/clubs/clubs.service.ts:860-999,1690-1723` — reemplazo
  transaccional y actores/alcance.
- `sacdia-backend/src/clubs/director-designation.service.ts:88-259,321-394` —
  idempotencia, conflicto, versionado y futuro por fecha.
- `sacdia-app/lib/features/members/presentation/views/members_view.dart:215-247`
  y `annual_continuations_view.dart:63-177` — entrada y CTA de directiva.
- `sacdia-app/lib/features/members/presentation/providers/members_providers.dart:564-682`
  y `members_remote_data_source.dart:404-500` — GET/POST y autoinscripción sin
  uso de UI.
- `sacdia-app/lib/features/dashboard/presentation/widgets/membership_status_banner.dart:17-73`
  — aviso `inactive`.
- `sacdia-admin/src/lib/clubs/fetch-detail.ts:105-164` y
  `src/components/clubs/detail/sections-tab.tsx:260-351,438-500` — plan futuro
  en el detalle admin.
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md:1019-1024,1403-1412` y
  `docs/features/gestion-clubs.md:108-136` — contrato documental vigente.

