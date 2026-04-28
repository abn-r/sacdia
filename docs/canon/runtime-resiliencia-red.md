# Runtime — Resiliencia de red (cache + invalidación)

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: estrategia de cache local, invalidación de datos y resiliencia frente a conectividad intermitente en clientes SACDIA (app móvil y admin web)

<!-- VERIFICADO contra código 2026-04-22: capas realtime de Flutter, React Query de admin, y emisión FCM silent en backend cruzadas con implementación real. -->

---

## 1. Propósito

Canoniza lo que SACDIA **sí hace** hoy en materia de resiliencia de red, y separa explícitamente del modelo offline-first que **no existe** en la implementación actual.

La capacidad vigente es **cache local + TTL + invalidación por FCM silent messages** (móvil) y **React Query con staleTime + invalidación tras mutación** (admin). No es offline-first con queue de mutaciones persistidas ni sincronización diferida.

---

## 2. Capacidad VIGENTE

### 2.1 App móvil (Flutter)

**Persistencia local**:

- `SharedPreferences` vía `SharedPreferencesStorage` (`sacdia-app/lib/core/storage/local_storage.dart:53`). No hay TTL automático a nivel de storage — la expiración la maneja cada feature al leer.
- `flutter_cache_manager` vía `SacCacheManager` (`sacdia-app/lib/core/config/cache_config.dart`): `stalePeriod: Duration(days: 30)`, `maxNrOfCacheObjects: 500`. Aplica a assets remotos (`CachedNetworkImage`).

**Realtime invalidation vía FCM silent messages**:

- handler: `sacdia-app/lib/core/realtime/realtime_invalidation_handler.dart`
  - `handleForeground(message, ref)` — invalida providers Riverpod en vivo;
  - `stagePending(message)` — persiste payload en `SharedPreferences['pending_realtime_invalidations']` cuando la app está en background;
  - `drainPending()` — lee, deduplica y procesa la cola al resume (`AppLifecycleState.resumed`).
- registry: `realtime_resource_registry.dart`
  - `RealtimeResourceRegistry.register(resource, handler)` permite extender;
  - handlers activos: **solo `activities`** (`_invalidateActivities`, valida `sectionId` contra contexto activo antes de invalidar `clubActivitiesProvider`).
- feature flag: `RealtimeFeatureFlags.realtimeInvalidationEnabled` (`feature_flags.dart:16`), controlado por `--dart-define=REALTIME_INVALIDATION_ENABLED=true`. **Default: `false` (dark launch)**.

### 2.2 Admin web (Next.js)

- librería predominante: `@tanstack/react-query` v5 (`sacdia-admin/src/lib/api/query-client.ts`):
  - `staleTime: 5 min`;
  - `gcTime: 10 min`;
  - `retry: 1`;
  - `refetchOnWindowFocus: false`.
- invalidación tras mutación: `queryClient.invalidateQueries()` en hooks de features (ej. `use-categories.ts:34`, `use-achievements.ts:60`).
- ISR / revalidación Next.js: `revalidatePath()` en server actions y `export const revalidate = 60` en páginas específicas (ej. SLA dashboard).
- **no hay integración con FCM web**; admin depende de staleTime y revalidación manual.

### 2.3 Backend (sacdia-backend)

- servicio emisor: `NotificationsService.sendSilentToSection(payload)` (`notifications.service.ts:372`) encola job `realtime.invalidate` en BullMQ;
- processor: `NotificationsProcessor.handleRealtimeInvalidate()` (`notifications.processor.ts:678`) resuelve tokens FCM filtrando por `club_role_assignments.club_section_id + active:true`, excluye al `actorId` emisor;
- multicast: `sendSilentMulticast()` construye payload `data`:
  - `type: 'cache_invalidate'`
  - `sectionId: <string>`
  - `resource: <string>`
  - `action: 'CREATED' | 'UPDATED' | 'DELETED'`
  - `entityId: <string>`
  - `actorId: <string>`
  - `timestamp: <ISO string>`
- APNS: `content-available: 1`; Android: `priority: 'high'`;
- fire-and-forget: no crea `notification_logs` ni `notification_deliveries` (ese camino es solo para notificaciones visibles al usuario).

---

## 3. Cobertura por feature

Auditoría exhaustiva al 2026-04-22 contra los 26 directorios de `sacdia-app/lib/features/` y los callers de `sendSilentToSection` en backend.

### 3.1 Features con cobertura vigente

| Feature | Backend emite | Handler Flutter |
|---------|---------------|-----------------|
| Activities | `activities.service.ts:252, 362, 461, 475, 531, 757` (6 puntos) | `realtime_resource_registry.dart` (`_invalidateActivities`) |
| Members | `clubs.service.ts` (assignRole/updateRoleAssignment/removeRoleAssignment), `membership-requests.service.ts` (approve/reject), `units.service.ts` (addMember/removeMember) — 7 puntos | `realtime_resource_registry.dart` (`_invalidateMembers`) — invalida `membersNotifierProvider` tras validar sección activa |

### 3.2 Features con gap de cobertura

Las features listadas abajo tienen UI sensible a staleness (listas mutadas por admin/coordinador/director que otros usuarios pueden tener en cache). Ninguna tiene emisión backend ni handler cliente hoy.

**Prioridad alta** (mutación frecuente + alto impacto en UX):
- `camporees` — aprobaciones por coordinador (clubs, members, payments).
- `honors` — aprobaciones por director/coordinador.

**Prioridad media** (progresión/aprobación con frecuencia menor):
- `classes`, `certifications`, `investiture`, `monthly_reports`, `transfers`, `finances`, `inventory`.

**Prioridad baja**:
- `units`, `enrollment`, `coordinator` (evidence-review list), `role_assignments`, `insurance`, `validation`, `annual_folders`, `evidence_folder`, `dashboard` (derivado), `resources`.

**No aplica** (estado propio del usuario, no sensible a mutación externa):
- `auth`, `notifications`, `post_registration`, `profile`.

### 3.3 Estado del admin

El admin web no consume invalidaciones por FCM silent — el único canal actualmente es `@tanstack/react-query` con `invalidateQueries` tras mutación local e ISR (`revalidatePath` / `export const revalidate = 60`). No hay integración push nativa y no es objetivo canónico de este documento.

### 3.4 Implicación

La capacidad vigente está **acotada a `activities`**. Cerrar el gap por feature requiere dos cambios simultáneos:

1. en el servicio backend correspondiente, agregar método privado análogo a `activities.service.ts:381` (`emitRealtimeInvalidation`) y llamarlo tras cada create/update/delete;
2. en Flutter, registrar el resource en `realtime_resource_registry.dart` con su handler que invalide el/los providers Riverpod afectados.

El feature flag `realtimeInvalidationEnabled` (default `false`) gobierna el rollout; extender cobertura es independiente de activar el flag en producción.

---

## 4. Capacidad NO VIGENTE (no describir como existente)

Confirmado por grep negativo en el código:

- **Offline-first con queue de mutaciones persistida**: no hay `hive`, `sqflite`, `drift` ni `isar` en `sacdia-app/` (ni en `pubspec.yaml` ni en imports);
- **Sincronización diferida con reconciliación**: no existen símbolos `offline_queue`, `pendingMutations` ni `syncQueue`;
- **Endpoints `/sync` o `/delta-sync`**: no existen en `sacdia-backend/src/`;
- **FCM web en admin**: no hay integración push nativa en el admin.

Toda comunicación pública o documental que afirme offline-first debe corregirse antes de publicación. La capacidad actual es **cache + invalidación**, no offline-first.

---

## 5. Política de emisión de `cache_invalidate`

Canonizada:

1. el emisor backend es siempre el servicio dueño del recurso, no un coordinador central;
2. la emisión es **fire-and-forget**: fallos en FCM no pueden propagarse como error al caller del endpoint;
3. la emisión no debe escribirse en `notification_logs` ni `notification_deliveries` (esos son canales de notificación visible al usuario);
4. el payload debe incluir `sectionId`, `resource`, `action`, `entityId`, `actorId`, `timestamp`;
5. `actorId` se usa para excluir al emisor del fanout (evita invalidación al propio dispositivo que acaba de mutar).

---

## 6. Política de consumo en cliente móvil

1. todo resource relevante debe registrarse en `RealtimeResourceRegistry.register()` antes de producción;
2. el handler de cada resource debe validar contexto (`sectionId`, `clubId`) antes de invalidar providers — no invalidar ciegamente;
3. en background, usar `stagePending` + SharedPreferences y drenar en `drainPending()` al resume;
4. la invalidación debe respetar el feature flag `realtimeInvalidationEnabled` para permitir rollout controlado;
5. la invalidación jamás debe bloquear el UI thread ni requerir red adicional (es una señal, no una descarga).

---

## 7. Frontera con roadmap

La evolución hacia offline-first transversal **no es parte de este canon**. Corresponde a `docs/plans/offline-first-roadmap.md` (por crear en P3). Ese plan deberá:

- definir alcance (qué features necesitan mutaciones offline);
- definir tecnología (`hive`, `drift`, `isar`);
- definir política de conflictos;
- definir UX de estado "desconectado".

Mientras ese plan no exista y no haya implementación, no debe describirse capacidad offline en material estratégico.

---

## 8. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — topología general del runtime.
- `docs/canon/arquitectura-sacdia.md` — responsabilidades por capa.
- `docs/canon/decisiones-clave.md` — decisión 13 (SACDIA no es offline-first; es cache + invalidación).

---

## 9. Invariantes

- ninguna invalidación puede crear `notification_logs` o `notification_deliveries`;
- ningún feature móvil debe bloquear al usuario por falta de invalidación en tiempo real (la UX debe tolerar cache stale hasta el próximo staleTime o refresh manual);
- ninguna comunicación oficial puede afirmar que SACDIA es offline-first mientras este canon esté vigente;
- el feature flag `realtimeInvalidationEnabled` es el único interruptor canónico para habilitar o deshabilitar el pipeline de invalidación en móvil.
