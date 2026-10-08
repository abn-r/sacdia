# Investidura por autorización — Pantallas de la app (Plan 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que la directiva de la sección presente, agregue, quite y cambie la fecha de quienes cumplen, y que cada persona vea su estado de investidura, desde la app.

**Architecture:** Un feature nuevo `lib/features/investiture_requests/` con Clean Architecture (datasource Dio → repositorio con `Either<Failure, T>` → providers Riverpod sin codegen → vistas). Reutiliza `ClubContext`, `currentEcclesiasticalYearProvider`, los widgets `Sac*` y el screen catalog. La vista de la persona se integra en el detalle de clase existente. El feature legado `lib/features/investiture/` queda intacto hasta la fase 8, salvo el badge de estado.

**Tech Stack:** Flutter, Riverpod 2.6 (sin codegen), Dio, dartz, Equatable, easy_localization (JSON), HugeIcons, flutter_test.

**Depende de:** Plan 0 (`docs/plans/2026-10-08-investidura-ui-0-backend-soporte.md`) Tasks 2 y 5 mergeadas, y backend #465.

---

## Reglas para quien ejecute

- Leer `sacdia-app/CLAUDE.md`. La estructura real es `lib/features/<feature>/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{providers,views,widgets}}`.
- **Diseño:** antes de las vistas (Tasks 6 a 9), seguir el flujo de diseño del proyecto: skill `mobile-design` (principios) → `nextlevelbuilder-ui-ux-pro-max` (sistema) → implementación. Usar `SacTopBar(frosted: true)`, `SacCard`, `SacBadge`, `SacButton`, `SacEmptyState`, `SacLoading`, `SacDialog.show`, `showSacSheet`, `SacSnackBar.show`, colores de `context.sac`/`AppColors`. Iconos **solo** `HugeIcon` (hay un guard: `test/hugeicons_guard_test.dart`) y campos tipados `HugeIconData`.
- **TDD con `flutter_test`:** prueba roja antes de cada pieza. Los mocks son fakes manuales que implementan el repositorio. Los datasources se prueban con Dio + `InterceptorsWrapper(onRequest: (o, h) => h.resolve(Response(...)))` (ver `test/features/classes/classes_remote_data_source_test.dart`). Los providers se prueban con `ProviderContainer(overrides: [...])`.
- **Comandos:** `flutter test test/features/investiture_requests/`, `flutter analyze`. Sin builds.
- **Textos:** van en `assets/translations/{es,en,fr,pt-BR}.json`, bajo `investiture_requests.*`. Los textos cerrados del plan funcional (§4) van literales en `es`: «En espera de autorización.», «Falta de requisitos para investidura», «El camino rindió fruto. Ya estás investido, y esta noticia es para celebrarla.».
- **Commits:** por unidad de trabajo, en formato Conventional Commits.

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `lib/features/investiture_requests/domain/entities/*.dart` | `PresentationContext`, `PresentationCandidate`, `InvestitureRequest`, `RequestPerson`, `PersonStatus`, `OwnInvestitureEntry`, `YearbookEntry` |
| `lib/features/investiture_requests/data/models/*.dart` | `fromJson` de cada entidad |
| `lib/features/investiture_requests/data/datasources/investiture_requests_remote_data_source.dart` | Endpoints y mapeo de códigos de error |
| `lib/features/investiture_requests/data/repositories/investiture_requests_repository_impl.dart` | `Either<Failure, T>` |
| `lib/features/investiture_requests/domain/repositories/investiture_requests_repository.dart` | Contrato |
| `lib/features/investiture_requests/presentation/providers/investiture_requests_providers.dart` | Providers de lectura y notifiers de acciones |
| `lib/features/investiture_requests/presentation/views/section_investiture_view.dart` | Pantalla de la directiva |
| `lib/features/investiture_requests/presentation/widgets/present_sheet.dart` | Hoja para presentar o agregar |
| `lib/features/investiture_requests/presentation/widgets/change_date_sheet.dart` | Hoja de cambio de fecha |
| `lib/features/investiture_requests/presentation/views/section_investiture_history_view.dart` | Historial y anuario de la sección |
| `lib/features/investiture_requests/presentation/widgets/own_investiture_card.dart` | Tarjeta de la persona en el detalle de clase |
| `lib/core/auth/club_role_names.dart` | Lista `investitureBoard` |
| `lib/features/members/presentation/providers/members_providers.dart` | `ClubContext.isInvestitureBoard` |
| `lib/core/authorization/screen_catalog.dart` + `test/fixtures/screen-catalog.snapshot.json` | Pantalla `app-section-investiture` |
| `lib/core/config/route_names.dart`, `lib/core/config/router.dart` | Rutas nuevas |
| `lib/features/classes/presentation/views/class_detail_with_progress_view.dart` | Reemplazar el bloque de envío legado por `OwnInvestitureCard` |
| `lib/features/profile/presentation/widgets/class_status_circles.dart` | Quitar `progress >= 80` como «investida» |
| `lib/features/notifications/presentation/views/notifications_inbox_view.dart`, `lib/core/notifications/push_notification_service.dart` | Navegación por resultado |

---

### Task 1: Entidades y modelos

**Files:** Create las entidades y modelos listados; Test `test/features/investiture_requests/models_test.dart`.

- [ ] **Step 1: Prueba roja.** Parsear un JSON del contexto de presentación (forma del Plan 0, Task 2) y un `InvestitureRequestView` (forma del backend #465):

```dart
test('parses presentation context', () {
  final ctx = PresentationContextModel.fromJson({
    'club_section_id': 4, 'ecclesiastical_year_id': 9,
    'window': {'start_date': '2026-10-01', 'end_date': '2026-12-20', 'open_today': true},
    'year_open': true, 'open_request_id': null,
    'candidates': [
      {'enrollment_id': 11, 'user_id': 'u1', 'user_name': 'Ana', 'class_id': 3, 'class_name': 'Amigo',
       'overall_progress': 92, 'eligible': true, 'blocked_code': null, 'pending_person_id': null},
    ],
  });
  expect(ctx.window.openToday, isTrue);
  expect(ctx.candidates.single.eligible, isTrue);
  expect(ctx.candidates.single.className, 'Amigo');
});

test('maps person status strings', () {
  expect(PersonStatus.fromString('REJECTED_BY_SYSTEM'), PersonStatus.rejectedBySystem);
  expect(PersonStatus.fromString('UNKNOWN'), PersonStatus.unknown);
});
```

- [ ] **Step 2:** `flutter test test/features/investiture_requests/models_test.dart` → FAIL.
- [ ] **Step 3: Implementación.** Entidades `Equatable` con campos camelCase equivalentes a la API:
  - `PresentationContext{clubSectionId, ecclesiasticalYearId, window(WindowState{startDate, endDate, openToday}), yearOpen, openRequestId, candidates}`.
  - `PresentationCandidate{enrollmentId, userId, userName, classId, className, overallProgress, eligible, blockedCode, pendingPersonId}`.
  - `InvestitureRequest{requestId, clubSectionId, ecclesiasticalYearId, people}`.
  - `RequestPerson{personId, userId, userName, classId, className, enrollmentId, investitureDate(DateTime), status, authorizationComment, rejectionReason, systemReason, resolvedByName}`.
  - `OwnInvestitureEntry{personId, classId, className, ecclesiasticalYearId, investitureDate, status, personText, authorizationComment}`.
  - `YearbookEntry{enrollmentId, userId, classId, className, ecclesiasticalYearId}`.

  `PersonStatus` es un enum con `pending, invested, rejectedByPerson, rejectedBySystem, rejected, removed, closedYear, unknown`; `fromString` no lanza. Las fechas `YYYY-MM-DD` se parsean como fecha civil, sin zona.
- [ ] **Step 4:** PASS. **Commit:** `feat(investiture): add authorization request entities and models`.

### Task 2: Datasource y mapeo de errores

**Files:** Create `investiture_requests_remote_data_source.dart`; Test `test/features/investiture_requests/remote_data_source_test.dart`; Modify los 4 JSON de traducciones.

Endpoints, con prefijo `$baseUrl`, igual que los datasources existentes:

| Método | Ruta | Uso |
| --- | --- | --- |
| GET | `/club-sections/{sectionId}/investiture-requests/presentation-context?ecclesiastical_year_id=` | Contexto |
| GET | `/club-sections/{sectionId}/investiture-requests?ecclesiastical_year_id=` | Solicitud abierta |
| POST | `/club-sections/{sectionId}/investiture-requests` | `{ecclesiastical_year_id, investiture_date, enrollment_ids}` |
| POST | `/investiture-requests/{requestId}/people` | `{investiture_date, enrollment_ids}` |
| DELETE | `/investiture-requests/{requestId}/people/{personId}` | Quitar |
| PATCH | `/investiture-requests/{requestId}/dates` | `{investiture_date, person_ids}` |
| GET | `/investiture-history` | Propio |
| GET | `/club-sections/{sectionId}/investiture-history` | Sección |
| GET | `/club-sections/{sectionId}/investiture-yearbook` | Anuario |

- [ ] **Step 1: Pruebas rojas.**
  - `present` envía el cuerpo exacto a la ruta exacta (capturar `RequestOptions`).
  - Un 409 con `{"code":"INVESTITURE_REQUEST_STALE"}` lanza `ServerException` con el mensaje `tr('investiture_requests.errors.stale')`.
  - La respuesta envuelta en `{status, data}` se desenvuelve. Usar `extractInvestitureListFromResponse` (`lib/features/investiture/data/datasources/investiture_remote_data_source.dart` ~L314) para las listas.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3: Implementación.** Mismo patrón `_rethrow`/`_extractDioCode` que `investiture_remote_data_source.dart:48-63`. Agregar un `if` por código y una clave por código en los 4 JSON:
  - `INVESTITURE_REQUEST_FORBIDDEN`, `_STALE`, `_ACTIVE_EXISTS`, `_ALREADY_INVESTED`, `_LEGACY_PIPELINE_ACTIVE`, `_CLASS_NOT_ELIGIBLE`, `_NOT_ELIGIBLE`, `_OUTSIDE_SECTION`, `_WINDOW_CLOSED`, `_YEAR_CLOSED`, `_DATE_OUTSIDE_WINDOW`, `_PROGRESS_LOCKED`, `_TIME_ZONE_INVALID`;
  - `INVESTITURE_DURATION_MIN_NOT_MET`, `INVESTITURE_DURATION_EXPIRED`.

  Los nombres exactos se confirman con `rg -o "INVESTITURE_[A-Z_]+" sacdia-backend/src/common/errors/error-codes.ts | sort -u`. Los textos en `es` salen de `sacdia-backend/src/i18n/es/errors.json`.
- [ ] **Step 4:** PASS. **Commit:** `feat(investiture): add authorization requests data source`.

### Task 3: Repositorio y providers

**Files:** Create el repositorio (contrato e implementación) y `investiture_requests_providers.dart`; Test `test/features/investiture_requests/providers_test.dart`.

- [ ] **Step 1: Prueba roja** con un `FakeInvestitureRequestsRepository`:
  - `presentationContextProvider(SectionYearQuery(sectionId: 4, yearId: 9))` devuelve el contexto.
  - `PresentNotifier.submit(...)` pasa por `isLoading`, después a `success` e invalida `presentationContextProvider` y `openRequestProvider`.
  - Un `Left(ServerFailure('msg'))` deja `errorMessage = 'msg'`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3: Implementación**, siguiendo el estilo de `investiture_providers.dart:12-27`:

```dart
class SectionYearQuery extends Equatable {
  const SectionYearQuery({required this.sectionId, required this.yearId});
  final int sectionId; final int yearId;
  @override List<Object?> get props => [sectionId, yearId];
}

final investitureRequestsRemoteDataSourceProvider = Provider<InvestitureRequestsRemoteDataSource>((ref) =>
  InvestitureRequestsRemoteDataSourceImpl(dio: ref.watch(dioProvider), baseUrl: ref.watch(apiBaseUrlProvider)));
final investitureRequestsRepositoryProvider = Provider<InvestitureRequestsRepository>((ref) =>
  InvestitureRequestsRepositoryImpl(remote: ref.watch(investitureRequestsRemoteDataSourceProvider), networkInfo: ref.watch(networkInfoProvider)));

final presentationContextProvider = FutureProvider.autoDispose.family<PresentationContext, SectionYearQuery>((ref, q) async =>
  (await ref.watch(investitureRequestsRepositoryProvider).presentationContext(q.sectionId, q.yearId)).fold((f) => throw f, (v) => v));
final openRequestProvider = FutureProvider.autoDispose.family<InvestitureRequest?, SectionYearQuery>(/* mismo patrón con openRequest */);
final ownInvestitureHistoryProvider = FutureProvider.autoDispose<List<OwnInvestitureEntry>>(/* ownHistory */);
final sectionInvestitureHistoryProvider = FutureProvider.autoDispose.family<List<OwnInvestitureEntry>, int>(/* sectionHistory */);
final sectionYearbookProvider = FutureProvider.autoDispose.family<List<YearbookEntry>, int>(/* yearbook */);
```

  Notifiers `AutoDisposeFamilyNotifier<InvestitureActionState, SectionYearQuery>` para `present`, `addPeople`, `remove` y `changeDates`. Reutilizan la forma de `InvestitureActionState{isLoading, errorMessage, success}` del feature legado e invalidan `presentationContextProvider(q)` y `openRequestProvider(q)` cuando la acción sale bien.
- [ ] **Step 4:** PASS. **Commit:** `feat(investiture): add authorization request providers`.

### Task 4: Rol de directiva y screen catalog

**Files:** Modify `lib/core/auth/club_role_names.dart`, `members_providers.dart` (`ClubContext`), `lib/core/authorization/screen_catalog.dart`, `test/fixtures/screen-catalog.snapshot.json`; Test `test/core/auth/club_context_investiture_test.dart`.

- [ ] **Step 1: Prueba roja:**
  - `ClubContext(roleName: 'secretary-treasurer').isInvestitureBoard` vale `true`.
  - Con `'deputy-director'` vale `false`, y con `'counselor'` también `false`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3: Implementación:**

```dart
// club_role_names.dart
static const List<String> investitureBoard = [director, secretary, secretaryTreasurer];

// ClubContext
bool get isInvestitureBoard {
  final role = roleName?.trim().toLowerCase();
  return role != null && ClubRoleNames.investitureBoard.contains(role);
}
```

  Registrar en `kAppScreenCatalog` la pantalla `app-section-investiture`, con los roles de club `director`, `secretary` y `secretary-treasurer`, y regenerar el fixture como indica `CLAUDE.md` (paridad con el admin).
- [ ] **Step 4:** PASS + `flutter test test/core/authorization/`. **Commit:** `feat(investiture): gate the section investiture screen to the board`.

### Task 5: Rutas

**Files:** Modify `route_names.dart` y `router.dart`.

- [ ] **Step 1: Prueba roja** en `test/core/config/router_investiture_test.dart`: `RouteNames.sectionInvestiture`, `RouteNames.sectionInvestitureHistory` y `RouteNames.ownInvestiture` existen y el router resuelve cada una a su vista, siguiendo el patrón de las pruebas del router existentes; si no hay, verificar `GoRouter.of` con un `MaterialApp.router`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Declarar las tres rutas `GoRoute(path: ..., pageBuilder: (c, s) => _sharedAxisBuild(c, s, const View()))` junto a las de investidura (`router.dart` ~L731-754). Agregar un acceso rápido «Investiduras» en `_quickAccessItemsConfig` (`quick_access_grid.dart`), con gate por `canViewScreen(subject, 'app-section-investiture')`.
- [ ] **Step 4:** PASS. **Commit:** `feat(investiture): add investiture routes and quick access`.

### Task 6: Pantalla de la directiva (presentar, agregar, quitar, cambiar fecha)

Antes de esta task, correr el flujo de diseño (`mobile-design` y luego `nextlevelbuilder-ui-ux-pro-max`) con este contexto: usuarios de la directiva de un club juvenil adventista; tono cálido pero profesional; estados de carga, vacío, error y éxito; datos y acciones como se describen abajo.

**Files:** Create `section_investiture_view.dart`, `present_sheet.dart`, `change_date_sheet.dart`; Tests en `test/features/investiture_requests/presentation/`.

Comportamiento (IA-01, IA-02, IA-04 a IA-08, IA-11, IA-20 a IA-22, IA-25 a IA-28):
- Sección y año salen de `clubContextProvider` y `currentEcclesiasticalYearProvider`. Si `!isInvestitureBoard`, mostrar `SacEmptyState` de acceso restringido.
- **Banner de ventana** con `window` del contexto:
  - Abierta: «Podés presentar hasta el {fin}.»
  - Cerrada: «La ventana del Campo está cerrada. No se puede presentar ni agregar personas.» En este caso se ocultan las acciones de presentar y agregar.
  - Año cerrado (`yearOpen == false`): todo queda en solo lectura.
- **Sección «En espera de autorización»:** personas `PENDING` de la solicitud abierta, con fecha, clase y `SacBadge.warning`. Selección múltiple para «Cambiar fecha» (abre `ChangeDateSheet` con `showDatePicker`; la fecha debe caer en la ventana y en el año) y acción «Quitar» por persona con `SacDialog.show(confirmIsDestructive: true)`. Quitar no envía correo; mostrarlo en el texto del diálogo.
- **Sección «Pueden presentarse»:** candidatos con `eligible == true` y `pendingPersonId == null`, con nombre, clase y `SacProgressBar` de `overallProgress`. Tienen selección múltiple, y el botón primario es «Presentar (N)» o «Agregar a la solicitud (N)» según `openRequestId`. Abre `PresentSheet` con un selector de fecha obligatorio (IA-20). Si se agrega a una solicitud existente, se muestra la fecha anterior como valor inicial (IA-21).
- **Sección «No pueden presentarse»:** candidatos con `eligible == false`, sin acción y con el motivo traducido desde `blockedCode` (mismo mapa de la Task 2). Ejemplos: «Ya está investido en esta clase», «Todavía no cumple la duración mínima», «Tiene un trámite del flujo anterior».
- **Resultados:** éxito → `SacSnackBar.show` y refresco por invalidación; error → `SacSnackBar.show(isError: true)` con el mensaje mapeado. Ante `INVESTITURE_REQUEST_STALE`, refrescar automáticamente.
- Pull-to-refresh sobre `presentationContextProvider` y `openRequestProvider`.

- [ ] **Step 1: Pruebas rojas** (`testWidgets` con `ProviderScope(overrides: [...])` y un repositorio fake):
  - Con ventana cerrada no aparece «Presentar».
  - Seleccionar dos elegibles y confirmar con fecha llama a `present` con `enrollment_ids` `[11, 12]` y la fecha `YYYY-MM-DD`.
  - Un candidato con `blockedCode: 'INVESTITURE_REQUEST_ALREADY_INVESTED'` muestra el motivo y no tiene checkbox.
  - Con una solicitud abierta, el botón dice «Agregar a la solicitud» y llama a `addPeople`.
  - «Quitar» pide confirmación antes de llamar a `remove`.
  - Con `deputy-director` se muestra acceso restringido.
- [ ] **Step 2:** FAIL. **Step 3:** Implementar. **Step 4:** PASS + `flutter analyze`. **Commit:** `feat(investiture): add section board presentation screen`.

### Task 7: Vista de la persona en el detalle de clase

**Files:** Create `own_investiture_card.dart`; Modify `class_detail_with_progress_view.dart` (`_InvestitureCompletionCard` ~L518 y `_canSubmitInvestiture`); Test.

Comportamiento (§3.6, §4, BC-3):
- Se busca en `ownInvestitureHistoryProvider` la entrada de esa clase y del año más reciente:
  - `pending`: «En espera de autorización.», la fecha y la clase, con `SacBadge.warning`.
  - `invested`: el texto alegre, la fecha y la clase. Si existe, el comentario va debajo con estilo de cita.
  - `rejected`: la fecha, la clase y solo «Falta de requisitos para investidura». No hay ningún otro dato disponible.
  - `closedYear`: «No investido en {año}». Sin el texto de requisitos.
  - `removed` con `personText` (IA-59/IA-61): mostrar `personText`.
  - Sin entrada: no se muestra la tarjeta.
- Se elimina el botón legado «Enviar a validación» (`_canSubmitInvestiture`) **para quien ve su propia clase**. El envío pasa a ser de la directiva, en la Task 6. La pantalla legada de validación de coordinador queda para la fase 8.

- [ ] **Step 1: Pruebas rojas:** un caso por estado. El rechazo **no** muestra el motivo aunque el fake lo traiga en otros campos.
- [ ] **Step 2:** FAIL. **Step 3:** Implementar. **Step 4:** PASS. **Commit:** `feat(investiture): show own authorization status on class detail`.

### Task 8: Historial y anuario de la sección

**Files:** Create `section_investiture_history_view.dart` + test.

- Dos pestañas:
  - **«Historial»:** agrupa `sectionInvestitureHistoryProvider` por año y clase. La directiva ve el estado; el motivo humano solo aparece si la API lo trae.
  - **«Anuario»:** lista `sectionYearbookProvider` por año y luego por clase, con nombre y clase.
- Se entra desde la pantalla de la Task 6, con una acción en `SacTopBar`.

- [ ] **Step 1: Prueba roja:** agrupa dos años en orden descendente. Con lista vacía muestra `SacEmptyState`.
- [ ] **Step 2:** FAIL. **Step 3:** Implementar. **Step 4:** PASS. **Commit:** `feat(investiture): add section investiture history and yearbook`.

### Task 9: Navegación desde notificaciones

**Files:** Modify `notifications_inbox_view.dart` (`_handleTap` ~L180) y `push_notification_service.dart` (`_handledNotificationTypes`, `_handleTypedNotification` ~L933); Tests.

- **Bandeja:** si `source` empieza con `investiture:invested` o `investiture:rejected`, después de marcar como leída se navega:
  - Si `clubContext.isInvestitureBoard`, a `RouteNames.sectionInvestiture`.
  - Si no, a `RouteNames.ownInvestiture`.
- **Push:** se agrega `'investiture_result'` a los tipos manejados. Con `audience == 'board'` va a `sectionInvestiture`; con `'person'`, a `ownInvestiture`. Esto depende de la Task 5 del Plan 0.

- [ ] **Step 1: Pruebas rojas:** un tap sobre una notificación con `source: 'investiture:invested'` navega a la ruta de la persona. Un push con `type: 'investiture_result'` y `audience: 'board'` llama a `_pushRoute(sectionInvestiture)`.
- [ ] **Step 2:** FAIL. **Step 3:** Implementar. **Step 4:** PASS. **Commit:** `feat(investiture): route result notifications to the right screen`.

### Task 10: Correcciones del flujo legado que contradicen la autorización

**Files:** Modify `class_status_circles.dart:115`; Test.

El pendiente de autorización vive en la solicitud (`investiture_authorization_people`), no en el `investiture_status` del enrollment, así que **no** se agrega un estado nuevo al enum legado `InvestitureStatus`; la persona ve su pendiente con `OwnInvestitureCard` (Task 7).

- [ ] **Step 1: Prueba roja:** `class_status_circles` con `progress: 95` y `status: 'IN_PROGRESS'` **no** devuelve `invested`; con `status: 'INVESTIDO'` sí.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Cambiar la condición a `if (status == 'INVESTIDO') return _ClassState.invested;`.
- [ ] **Step 4:** PASS. **Commit:** `fix(investiture): stop inferring investiture from progress`.

### Task 10b: Acceso del pastor y autorización en la app (decisión del 2026-10-08)

El pastor, rol global sin club, puede entrar a la app y, de momento, solo ve «Autorizaciones» y su perfil. `director-lf` y `assistant-lf` también pueden autorizar desde la app (plan funcional §1).

**Files:**
- Modify: `lib/core/config/router.dart` (`redirect` ~L130-250, bootstrap y post-registro), `lib/core/authorization/screen_catalog.dart` + fixture, `route_names.dart`.
- Create: `lib/features/investiture_requests/presentation/views/authorizer_requests_view.dart`, `authorizer_request_detail_view.dart`, `widgets/decision_sheet.dart`.
- Modify: el datasource, el repositorio y los providers de la Task 2-3, con `listForAuthorizer(yearId)`, `readRequest(requestId)` y `resolve(requestId, invest, reject)`, que llaman a `GET /investiture-requests?ecclesiastical_year_id=`, `GET /investiture-requests/{id}` y `POST /investiture-requests/{id}/resolutions`.

Comportamiento:
- **Acceso sin club:**
  - Un usuario con rol global `pastor` y sin membresía de club **no** pasa por el post-registro de club. Verificar en `redirect` cómo se decide hoy el post-registro y agregar la excepción por rol global. Si el backend del post-registro exige club, documentarlo y frenar la tarea para consultarlo con el usuario.
  - Su inicio muestra solo «Autorizaciones» y «Perfil». Las tabs y los accesos rápidos se filtran con `canViewScreen` y una pantalla nueva `app-investiture-authorizer`, con roles globales `pastor`, `director-lf` y `assistant-lf`.
- **Listado:** año actual y tarjetas por solicitud con club, sección, distrito, cantidad de pendientes y fecha más próxima. Usa los campos de la Task 3 del Plan 0. Sin solicitudes, `SacEmptyState`.
- **Detalle:** personas con su estado.
  - Para cada `PENDING` con `can_authorize`, `DecisionSheet` (`showSacSheet`) ofrece investir (comentario opcional, máximo 500) o rechazar (motivo obligatorio, máximo 1000).
  - «Confirmar decisiones (N)» pide confirmación con `SacDialog.show` y llama a `resolve`. Después muestra el resumen: investidos, rechazados, rechazados por el sistema con su texto largo, y los no aplicados con el motivo mapeado.
  - Con la ventana o el año cerrados, muestra un banner y bloquea las acciones.
  - El autorizador no ve el motivo humano: la API lo devuelve `null`.
- **Notificaciones:** los correos llegan al panel. En la app, el pastor ve sus pendientes desde el listado; no hay push por presentación.

- [ ] **Step 1: Pruebas rojas:**
  - El `redirect` no envía al post-registro a un usuario con rol global `pastor` sin club.
  - El inicio del pastor muestra solo «Autorizaciones» y «Perfil».
  - El detalle envía `{invest:[{person_id:'p1'}], reject:[{person_id:'p2', reason:'Faltan evidencias'}]}` después de confirmar.
  - Un rechazo sin motivo deshabilita «Confirmar».
  - Con `can_authorize: false` no hay controles de decisión.
- [ ] **Step 2:** FAIL. **Step 3:** Implementar. **Step 4:** PASS + `flutter analyze`. **Commit:** `feat(investiture): let pastors and the field authorize from the app`.

### Task 11: Verificación integral y PR

- [ ] `flutter test`, `flutter analyze` y `test/hugeicons_guard_test.dart` en verde.
- [ ] Prueba manual en el simulador contra el backend local, si el usuario lo autoriza: presentar con la ventana abierta, quitar, cambiar la fecha, ver el estado como persona y abrir una notificación.
- [ ] PR contra `development` de `sacdia-app`, `type:feature`. Si supera 400 líneas sin contar tests, partir en PRs encadenados: (a) Tasks 1 a 5, (b) Task 6, (c) Tasks 7 a 10.

## Fuera de este plan

- Retirar las pantallas legadas: `InvestiturePendingListView`, `InvestitureSubmitView` y la validación de coordinador. Eso corresponde a la fase 8.
- Qué más ve el pastor en la app, aparte de autorizar y su perfil: se define después (decisión del 2026-10-08).
