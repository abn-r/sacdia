# Guía de Integración Frontend - SACDIA API v3.0

**Estado**: ACTIVE

**Versión**: 3.0.0
**Fecha**: 6 de julio de 2026
**Audiencia**: Desarrolladores Frontend (Admin Panel & Mobile App)
**Estado**: ACTIVE

> [!IMPORTANT]
> Esta guía es operativa y subordinada a `docs/README.md`, `docs/steering/*` y `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.
> Los endpoints y contratos runtime se validan contra la referencia live; los ejemplos de esta guía no reemplazan esa fuente de verdad.

---

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Setup Inicial](#setup-inicial)
3. [Autenticación](#autenticación)
4. [Consumo de Endpoints](#consumo-de-endpoints)
5. [Manejo de Errores](#manejo-de-errores)
6. [Ejemplos por Módulo](#ejemplos-por-módulo)
7. [Best Practices](#best-practices)
8. [Testing](#testing)

---

## Introducción

Esta guía proporciona ejemplos prácticos de cómo consumir la API REST de SACDIA desde aplicaciones frontend (Next.js Admin Panel y Flutter Mobile App).

### URLs Base

Definí la base URL por entorno en variables de entorno del módulo frontend correspondiente. No tomes dominios o puertos hardcodeados de esta guía como contrato global.

```typescript
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL;
```

### Endpoints Totales

- Verificar cobertura y disponibilidad actual en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- **Versionado**: `/api/v1/` (URI-based)
- **Formato**: JSON
- **Autenticación**: Better Auth self-hosted + JWT HS256 emitido/validado por backend

---

## Actualizacion 2026-05-21 (Clases legacy y duración)

El contrato frontend para clases progresivas incorpora clases legacy y duración configurable:

- Admin debe enviar y leer en `/api/v1/admin/classes`: `available_from_year_id`, `available_until_year_id`, `min_duration_years`, `max_duration_years`.
- `available_until_year_id = null` significa sin expiración para nuevas inscripciones. No usar años sentinel.
- Mobile/Admin deben tratar `investiture_status = EXPIRED` como trayectoria histórica: mostrar progreso/registros, pero bloquear edición, subida de evidencias y envío a investidura.
- El proceso manual usa `POST /api/v1/admin/classes/enrollments/expire-overdue`; ejecutar primero con `{ dry_run: true }` y pedir confirmación antes de `{ dry_run: false }`.

## Actualizacion 2026-07-01 (Requisitos básico/avanzado/extra)

El contrato de clases separa requisitos evaluables por track:

- `classes.advanced_enabled` habilita la via avanzada de la clase; si esta en `false`, el frontend no debe exigir ni destacar requisitos `ADVANCED`.
- `class_sections.requirement_track` puede ser `BASIC`, `ADVANCED` o `EXTRA`.
- `GET /api/v1/users/:userId/classes` y `GET /api/v1/users/:userId/classes/:classId/progress` exponen `basic_progress`, `advanced_progress`, `extra_progress`, `investiture_eligibility` y `advanced_eligibility`.
- `overall_progress` y `percentage` representan progreso de investidura: requisitos `BASIC` obligatorios + `EXTRA` aplicables al contexto institucional del miembro. `ADVANCED` se muestra como avance/badge separado.
- En el detalle de progreso, `modules[].sections[]` ya llega filtrado a secciones aplicables para el enrollment resuelto e incluye `requirement_track`, `required_for_investiture` y `display_order`.
- Admin puede configurar secciones `EXTRA` con exactamente un owner institucional (`division_id`, `union_id` o `local_field_id`) y ventana opcional `available_from_year_id` / `available_until_year_id`.

## Actualizacion 2026-07-02 (Camporee scoring móvil)

El flujo móvil de jueces de camporee consume scoring oficial por rúbricas:

- `GET /api/v1/camporee-judges/me/assignments` lista asignaciones del usuario autenticado; la app muestra para captura sólo las asignaciones activas donde `judge_role='primary'` y `can_submit_score=true`.
- `GET /api/v1/camporee-events/:eventId/rubrics` entrega criterios activos; la pantalla de captura debe enviar exactamente un ítem por rúbrica.
- `POST /api/v1/camporee-events/:eventId/sections/:clubSectionId/scores` puede enviar `source` como intención de UI, pero el backend siempre deriva la fuente efectiva desde asignación, rol y scope. Un juez principal sin override explícito queda `judge_primary`; gestores LF/Unión quedan `manual_lf`; sólo admins globales permitidos quedan `admin_override`. El total se calcula desde `items[].awarded_points`. Para "club no se presentó", enviar `{ no_show: true, items: [], notes? }`.
- Para tolerar reintentos de red, la app debe generar un UUID por intento lógico y enviarlo como header `Idempotency-Key`; reutilizarlo sólo para reintentar exactamente el mismo target/payload. Sin header el endpoint sigue siendo compatible, pero no hay replay idempotente.
- El receipt devuelve `camporee_event_score_submission_id`, resultado oficial, `raw_awarded_points`, `minimum_adjustment_points`, totales oficiales, actor/timestamps, notas e ítems. `active=true` describe el estado al emitirse y permanece estable en replays aunque luego exista un override; no usarlo como consulta del estado actual. Mostrar el total oficial y conservar el detalle crudo como auditoría, no como campo editable.
- Antes de enviar una corrección manual contra un resultado existente, admin debe leer/conservar el `camporee_event_section_result_id`, enviarlo como `expected_active_result_id` y exigir un `notes.trim()` no vacío como motivo. Ante `400 CAMPOREE_SCORING_OVERRIDE_REASON_REQUIRED`, mantener el formulario; ante `409 CAMPOREE_SCORING_RESULT_STALE`, refrescar antes de volver a decidir.
- El backend ajusta automáticamente al `min_points` del evento cuando el total queda por debajo del mínimo configurado; si no hay mínimo, conserva el total enviado. Nunca permite superar el máximo por rúbrica/evento.
- Una vez creado un resultado activo, el juez principal no puede reenviar ni editar; sólo gestores LF/Unión dentro de scope o admins globales autorizados pueden corregir. `camporee_events:update` sin esos roles no habilita la acción.
- Jueces `assistant` no ven acción de envío en app; quedan como apoyo/auditoría.
- El admin debe poblar el selector de roster con `GET /api/v1/local-camporees/:camporeeId/judge-candidates` o `GET /api/v1/union-camporees/:camporeeId/judge-candidates`, no con captura manual de UUID. El backend sólo acepta jueces 18+, pastores o Guías Mayores investidos.

## Actualizacion 2026-07-07 (Camporee staff, agenda y cierre de clubes)

El flujo administrativo de camporee separa personal operativo, agenda y scoring:

- Cargar personal del camporee:
  - `GET /api/v1/local-camporees/:camporeeId/staff`
  - `GET /api/v1/local-camporees/:camporeeId/staff-candidates`
  - `POST /api/v1/local-camporees/:camporeeId/staff`
  - equivalentes `union-camporees`.
- `staff-candidates` requiere `camporee_events:update` porque devuelve usuarios elegibles para una mutación.
- Editar/desactivar personal:
  - `PATCH /api/v1/camporee-staff/:staffMemberId`
  - `DELETE /api/v1/camporee-staff/:staffMemberId`
- Asignar personas a una actividad/agenda:
  - `GET /api/v1/camporee-events/:eventId/staff-assignments`
  - `PUT /api/v1/camporee-events/:eventId/staff-assignments`
  - roles válidos: `responsible`, `assistant`, `evaluator`, `support`.
- Para publicar un evento debe existir al menos un `responsible` activo. No se deben forzar roles de cocina/admin/apoyo en todos los eventos.
- Cerrar/reabrir inscripción de clubes:
  - `POST /api/v1/camporees/:camporeeId/club-registration/close|reopen`
  - `POST /api/v1/union-camporees/:camporeeId/club-registration/close|reopen`
- El cierre congela secciones para scoring; las mutaciones de rúbricas, asignación de jueces y captura de puntaje oficial deben mostrar el gate si `club_registration_closed_at` está vacío.
- La inscripción de miembros sigue dependiendo de `member_registration_deadline`; no bloquear UI de miembros por cierre de clubes.

## Actualizacion 2026-07-10 (Lifecycle y timezone de camporees)

- En formularios de creación/edición, enviar `start_date`/`end_date` como `YYYY-MM-DD`; nunca convertirlas a medianoche ni enviar timestamp.
- Para apertura y deadlines enviar un ISO-8601 con `Z` u offset explícito. La apertura ausente significa que clubes pueden inscribirse inmediatamente.
- Capturar una zona IANA explícita (por ejemplo `America/Mexico_City`) cuando se confirme la sede: el backend la audita con el actor. Un PATCH sin `timezone` no borra esa verificación.
- La UI de clubes debe distinguir `not_open_yet`, `open`, `late_approval_required` y `manually_frozen`. Al estar `not_open_yet`, no ofrecer inscripción ni flujo de aprobación tardía; el deadline es inclusivo.

## Actualizacion 2026-08-12 (Órdenes de pago territoriales)

Contrato para admin y app. Rutas completas: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` §field-payment-orders. Contrato detallado para admin: `sacdia-admin/docs/plans/handoffs/field-payment-orders-admin-handoff.md`.

### Decidir qué flujo mostrar (app)

`GET /payment-orders/context` → `{ enabled, local_field_id, club_section_id, insurance_cycles[] }`. Con `enabled: false`, mostrar los flujos legacy (alta directa de seguro, register directo de camporee). Con `enabled: true`, la emisión de órdenes es la única vía; los endpoints legacy responden `403 FIELD_PAYMENT_ORDER_LEGACY_DISABLED`.

### Ciclo de vida de la orden

`ISSUED → PROOF_SUBMITTED → APPROVED` | `PROOF_REJECTED` (permite re-subir o cancelar) | `CANCELLED` | `EXPIRED` (lazy, default 15 días).

1. Emitir: `POST /insurance/payment-orders` (`insurance_cycle_config_id` + `beneficiary_user_ids[]`), `POST /camporees/:id/payment-orders` (camporee local) o `POST /union-camporees/:id/payment-orders` (camporee de unión, v1.1 — cobra el Campo Local del emisor; requiere que el LF participe en el camporee). Body en ambos casos de camporee: `beneficiary_user_ids[]`. Filtros de lista: `camporee_id` (local) / `union_camporee_id` (unión).
2. PDF: `GET /payment-orders/:id/document` (binario `application/pdf`; el Bearer va en el header, nunca en la URL).
3. Comprobante: `POST /payment-orders/:id/proof` multipart campo `file` (PDF/JPG/PNG ≤10 MB).
4. Revisión (admin): `GET /payment-orders/review-queue` → `POST /payment-orders/:id/approve|reject` (reject requiere `reason`). Approve materializa cobertura/inscripciones automáticamente.

### Montos

`unit_cost_centavos` y `total_centavos` son enteros en centavos MXN. Los ciclos de seguro (`insurance_cycles[].unit_cost`) llegan como decimal en pesos (string) — convertir a centavos en cliente.

### Errores de dominio

Envelope estándar con `code` `FIELD_PAYMENT_ORDER_*` (i18n en los 4 locales de app/admin). Claves frecuentes: `FLAG_DISABLED`, `LEGACY_DISABLED`, `DUPLICATE_BENEFICIARY`, `ELIGIBILITY_FAILED`, `COST_NOT_CONFIGURED`, `EXPIRED`, `MAKER_CHECKER`, `INVALID_TRANSITION`.

## Actualizacion 2026-08-11 (Motor de certificaciones configurables)

Contrato mínimo para admin y app móvil. Fuente de verdad de rutas: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` §certifications.

### Identificación de inscripción en paths

- **Participante:** las rutas de ejecución usan `/users/:userId/certifications/:certificationId/...` (no `enrollmentId` en el path).
- **Revisión final:** la bandeja y acciones de cierre usan `:enrollmentId` porque operan sobre filas de `users_certifications`.

### Envelope de respuesta

```json
{ "status": "success", "data": { /* payload */ } }
```

Listados paginados del catálogo añaden `meta`. Errores de dominio incluyen `code` (`CERT_*`) traducible vía i18n.

### Tipos de componente (`certification_component_type_enum`)

| Tipo | Campo en borrador | Notas |
| --- | --- | --- |
| `TEXT_RESPONSE` | `text_value` | Texto libre |
| `FILE_EVIDENCE` | presign → confirm | JPEG/PNG/WebP/PDF, máx. 10 MiB |
| `LINKED_HONOR` | `linked_user_honor_id` | Debe pertenecer al usuario |
| `LINKED_ACTIVITY` | `linked_activity_id` | Actividad del usuario |
| `ATTESTATION` | `attestation_confirmed: boolean` | Confirmación explícita |
| `AUTO_VALIDATION` | — | Evaluado en servidor al enviar |

### Flujo de evidencia (participante)

1. `POST .../evidences/presign` con `component_id`, `file_name`, `mime_type`, `file_size` → `{ upload_url, evidence_id, object_key, expires_in }`.
2. Subir bytes a `upload_url` (PUT directo a R2).
3. `POST .../evidences/confirm` con `evidence_id` → estado `CONFIRMED`.

Comprobante de junta repite el mismo patrón en `/closeout-evidence/presign|confirm`.

### Concurrencia

`submit`, `approve` y `request-changes` envían `lock_version` (entero de `users_certifications`). Ante `409 CERT_CONCURRENT_UPDATE`, refrescar progreso y reintentar.

### Deprecación legacy

`PATCH /certifications/users/:userId/certifications/:certificationId/progress` sigue disponible solo para inscripciones **sin** `certification_version_id`. Inscripciones del motor versionado reciben `410 CERT_LEGACY_ENDPOINT_DEPRECATED`.

## Actualizacion 2026-02-17 (Admin Panel)

Se agrego validacion operativa para frontend admin mediante smoke E2E en `sacdia-admin/scripts/e2e-smoke.mjs`.

Comandos de referencia:

```bash
# Smoke autenticado
set -a; source .env.e2e.local; set +a; pnpm test:e2e:smoke

# Smoke con create/edit opcional
set -a; source .env.e2e.local; set +a; E2E_ENABLE_WRITE=1 pnpm test:e2e:smoke
```

Notas operativas:
- El runner maneja fallback de conectividad `localhost -> 127.0.0.1` para entornos IPv4/IPv6.
- Si un endpoint no esta publicado o hay rate-limit (429), reporta degradacion sin bloquear toda la corrida.

## Setup Inicial

### Next.js Admin Panel

**Instalar dependencias**:

```bash
pnpm add axios @tanstack/react-query
```

> No usar SDKs externos de autenticación en el frontend. El admin consume la API SACDIA; la sesión vive en cookies HTTP-only gestionadas por rutas same-origin de Next.js y el backend valida JWT con `JwtAuthGuard`.

**Cliente API vigente**:

```typescript
// src/lib/api/client.ts
import axios from 'axios';

export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL?.trim()
  ?? 'http://localhost:3000/api/v1';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: { Accept: 'application/json' },
});

async function getClientAuthToken() {
  const res = await fetch('/api/auth/token', { credentials: 'include' });
  if (!res.ok) return null;
  const body = await res.json();
  return typeof body.token === 'string' ? body.token : null;
}

apiClient.interceptors.request.use(async (config) => {
  const token = await getClientAuthToken();
  if (token && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

apiClient.interceptors.response.use(undefined, async (error) => {
  if (error.response?.status === 401) {
    const refresh = await fetch('/api/auth/refresh', {
      method: 'POST',
      credentials: 'include',
      headers: { Accept: 'application/json' },
    });
    if (refresh.ok) {
      const body = await refresh.json();
      error.config.headers.Authorization = `Bearer ${body.token}`;
      return apiClient.request(error.config);
    }
  }
  throw error;
});

export { apiClient };
```

---

### Flutter Mobile App

**Dependencias** (`pubspec.yaml`):

```yaml
dependencies:
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  url_launcher: ^6.2.0
```

**Cliente API vigente**:

```dart
// lib/core/network/dio_client.dart
final dio = Dio(BaseOptions(
  baseUrl: AppConstants.baseUrl, // incluye /api/v1
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
));

dio.interceptors.addAll([
  LoggerInterceptor(),
  AuthInterceptor(dio: dio), // adjunta Bearer y refresca en 401
  ErrorInterceptor(),
]);
```

El token se lee desde `FlutterSecureStorage` (`AppConstants.tokenKey`) y se envía como `Authorization: Bearer <token>`. El refresh reactivo usa `POST /auth/refresh` y reintenta la request original una sola vez.

---

## Autenticación

### 1. Login con Email/Password

**Next.js**:

```typescript
// src/lib/auth/actions.ts
'use server';

import { apiRequest } from '@/lib/api/client';
import { setAuthCookies } from '@/lib/auth/session';

export async function loginAction(email: string, password: string) {
  const response = await apiRequest('/auth/login', {
    method: 'POST',
    body: { email, password },
  });

  await setAuthCookies(response.data);
  return response.data.user;
}
```

**Flutter**:

```dart
Future<UserModel> login(String email, String password) async {
  final response = await dio.post('/auth/login', data: {
    'email': email,
    'password': password,
  });

  final data = response.data['data'] as Map<String, dynamic>;
  await secureStorage.write(AppConstants.tokenKey, data['accessToken']);
  await secureStorage.write(AppConstants.refreshTokenKey, data['refreshToken']);

  return UserModel.fromJson(data['user'] as Map<String, dynamic>);
}
```

---

### 2. OAuth con Google/Apple

El proveedor lo inicia el backend sobre Better Auth. El frontend no llama SDKs de autenticación externos.

**Flujo móvil**:

1. `GET /auth/oauth/{provider}` devuelve una URL de autorización.
2. La app abre esa URL con `url_launcher`.
3. Better Auth redirige al deep link `io.sacdia.app://auth/callback?session_token=...&provider=...`.
4. La app llama `POST /auth/oauth/callback` con `{ session_token, provider }`.
5. El backend devuelve el JWT interno de SACDIA y la app lo persiste en secure storage.

```dart
final urlResponse = await dio.get('/auth/oauth/google');
await launchUrl(Uri.parse(urlResponse.data['data']?['url'] ?? urlResponse.data['url']));

final callback = await dio.post('/auth/oauth/callback', data: {
  'session_token': sessionToken,
  'provider': 'google',
});

final data = callback.data['data'] as Map<String, dynamic>;
await secureStorage.write(AppConstants.tokenKey, data['accessToken']);
```

---

### 3. Verificar Autenticación

**Next.js**:

- Server components y server actions deben leer cookies HTTP-only con helpers de `src/lib/auth/session.ts`.
- Client components consumen `/api/auth/me` y `/api/auth/token` same-origin; no deben acceder directamente a cookies sensibles.
- Las rutas protegidas deben redirigir a `/login` cuando no hay sesión válida o el usuario no tiene rol admin.

**Flutter**:

- `AuthNotifier` valida el estado inicial con `/auth/me`.
- `AuthInterceptor` adjunta Bearer en cada request autenticada.
- Un 401 fuera de endpoints públicos dispara refresh; si falla, limpia tokens y expira la sesión local.

---

## Consumo de Endpoints

### Pattern Recomendado: API Service Layer

**Next.js** (con TanStack Query):

```typescript
// src/lib/api/services/clubs.service.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../client';

export interface Club {
  club_id: number;
  name: string;
  local_field_id: number;
  club_types?: { club_type_id: number; name: string };
  active: boolean;
}

async function fetchClubs() {
  const response = await apiClient.get('/clubs');
  return response.data.data as Club[];
}

export function useClubs() {
  return useQuery({
    queryKey: ['clubs'],
    queryFn: fetchClubs,
  });
}

export async function createClub(clubData: Partial<Club>) {
  const response = await apiClient.post('/clubs', clubData);
  return response.data;
}

export function useCreateClub() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createClub,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['clubs'] }),
  });
}

export async function updateClub(clubId: number, clubData: Partial<Club>) {
  const response = await apiClient.patch(`/clubs/${clubId}`, clubData);
  return response.data;
}

export async function deleteClub(clubId: number) {
  const response = await apiClient.delete(`/clubs/${clubId}`);
  return response.data;
}
```

**Uso en componente**:

```typescript
// app/dashboard/clubs/page.tsx
'use client';

import { useClubs, createClub } from '@/lib/api/services/clubs.service';
import { useState } from 'react';

export default function ClubsPage() {
  const { clubs, isLoading, isError, mutate } = useClubs();
  const [isCreating, setIsCreating] = useState(false);

  const handleCreate = async (data: any) => {
    setIsCreating(true);
    try {
      await createClub(data);
      mutate(); // Revalidar lista
      toast.success('Club creado exitosamente');
    } catch (error) {
      toast.error('Error al crear club');
    } finally {
      setIsCreating(false);
    }
  };

  if (isLoading) return <Spinner />;
  if (isError) return <ErrorMessage />;

  return (
    <div>
      <h1>Clubs</h1>
      <ClubList clubs={clubs} />
      <CreateClubForm onSubmit={handleCreate} isLoading={isCreating} />
    </div>
  );
}
```

---

**Flutter** (con Dio + Riverpod):

```dart
// lib/features/clubs/data/datasources/clubs_remote_datasource.dart
class ClubsRemoteDataSource {
  final Dio dio;

  Future<List<ClubModel>> getClubs() async {
    try {
      final response = await dio.get('/clubs');
      final data = response.data['data'] as List;
      return data.map((json) => ClubModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Error fetching clubs');
    }
  }

  Future<ClubModel> createClub(ClubModel club) async {
    try {
      final response = await dio.post('/clubs', data: club.toJson());
      return ClubModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Error creating club');
    }
  }
}

// lib/features/clubs/domain/usecases/get_clubs.dart
class GetClubs {
  final ClubsRepository repository;

  Future<Either<Failure, List<Club>>> call() async {
    return await repository.getClubs();
  }
}

// lib/features/clubs/presentation/providers/clubs_provider.dart
final clubsProvider = FutureProvider<List<Club>>((ref) async {
  final useCase = ref.read(getClubsUseCaseProvider);
  final result = await useCase();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (clubs) => clubs,
  );
});
```

**Uso en widget**:

```dart
// lib/features/clubs/presentation/pages/clubs_page.dart
class ClubsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Clubs')),
      body: clubsAsync.when(
        data: (clubs) => ClubsList(clubs: clubs),
        loading: () => CircularProgressIndicator(),
        error: (error, stack) => ErrorWidget(error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/clubs/create'),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## Manejo de Errores

### Estructura de Errores de la API

```typescript
// Error Response Format
interface ApiError {
  status: 'error';
  statusCode: number;
  message: string;
  error?: string;
  details?: any;
}
```

### Códigos HTTP Comunes

| Código | Significado | Acción Recomendada |
|--------|-------------|-------------------|
| 200 | OK | Procesar respuesta exitosa |
| 201 | Created | Recurso creado exitosamente |
| 400 | Bad Request | Validar datos de entrada |
| 401 | Unauthorized | Refrescar token o redirigir a login |
| 403 | Forbidden | Usuario sin permisos, mostrar mensaje |
| 404 | Not Found | Recurso no existe, manejar caso |
| 409 | Conflict | Duplicado, mostrar mensaje específico |
| 422 | Validation Error | Mostrar errores de validación |
| 429 | Too Many Requests | Rate limit, esperar y reintentar |
| 500 | Server Error | Error de servidor, reintentar o contactar soporte |

---

### Next.js Error Handler

```typescript
// lib/api/error-handler.ts
import { AxiosError } from 'axios';
import { toast } from 'sonner';

export function handleApiError(error: unknown) {
  if (error instanceof AxiosError) {
    const statusCode = error.response?.status;
    const message = error.response?.data?.message || error.message;

    switch (statusCode) {
      case 400:
        toast.error(`Datos inválidos: ${message}`);
        break;
      case 401:
        toast.error('Sesión expirada. Por favor inicia sesión nuevamente.');
        window.location.href = '/login';
        break;
      case 403:
        toast.error('No tienes permisos para realizar esta acción.');
        break;
      case 404:
        toast.error('Recurso no encontrado.');
        break;
      case 409:
        toast.error(`Conflicto: ${message}`);
        break;
      case 422:
        // Errores de validación específicos
        const details = error.response?.data?.details;
        if (details && Array.isArray(details)) {
          details.forEach((err: any) => {
            toast.error(`${err.field}: ${err.message}`);
          });
        } else {
          toast.error(message);
        }
        break;
      case 429:
        toast.error('Demasiadas peticiones. Por favor espera un momento.');
        break;
      case 500:
      default:
        toast.error('Error del servidor. Por favor intenta nuevamente.');
        break;
    }
  } else {
    toast.error('Error inesperado. Por favor intenta nuevamente.');
  }
}

// Uso
try {
  await createClub(data);
} catch (error) {
  handleApiError(error);
}
```

---

### Flutter Error Handler

```dart
// lib/core/errors/error_handler.dart
class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 400:
          return error.response?.data['message'] ?? 'Datos inválidos';
        case 401:
          return 'Sesión expirada. Por favor inicia sesión nuevamente.';
        case 403:
          return 'No tienes permisos para realizar esta acción.';
        case 404:
          return 'Recurso no encontrado.';
        case 409:
          return error.response?.data['message'] ?? 'Conflicto';
        case 422:
          // Mostrar errores de validación
          final details = error.response?.data['details'];
          if (details is List) {
            return details.map((e) => e['message']).join('\n');
          }
          return error.response?.data['message'] ?? 'Error de validación';
        case 429:
          return 'Demasiadas peticiones. Por favor espera un momento.';
        case 500:
        default:
          return 'Error del servidor. Por favor intenta nuevamente.';
      }
    }
    return 'Error inesperado. Por favor intenta nuevamente.';
  }

  static void show(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getMessage(error)),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Uso
try {
  await createClub(club);
} catch (error) {
  ErrorHandler.show(context, error);
}
```

---

## Ejemplos por Módulo

### Módulo: Perfil de Salud (baseline activo)

El baseline health activo para frontend queda limitado a `allergies` + `diseases` + `medicines` como sub-recursos sensibles de `user`.

Rutas canónicas verificadas:

```http
GET /api/v1/users/:userId/allergies
GET /api/v1/users/:userId/diseases
GET /api/v1/users/:userId/medicines
PUT /api/v1/users/:userId/allergies
PUT /api/v1/users/:userId/diseases
PUT /api/v1/users/:userId/medicines
DELETE /api/v1/users/:userId/allergies/:allergyId
DELETE /api/v1/users/:userId/diseases/:diseaseId
DELETE /api/v1/users/:userId/medicines/:medicineId
```

Contrato de integración:

- Son rutas `user` sensibles con modelo owner-or-global.
- `GET` requiere JWT y `users:read_detail`; `PUT` y `DELETE` por item requieren `users:update`.
- Self-service depende de ownership sobre `userId`; para terceros solo cuenta permiso global suficiente resuelto por backend.
- Clientes no deben derivar acceso a health de terceros desde contexto de club o `active_assignment`.
- La respuesta exitosa siempre usa envelope `{ status: 'success', data: [...] }`.
- En `GET`, `data` llega como lista plana:
  - alergias: `{ allergy_id, name }`
  - enfermedades: `{ disease_id, name }`
- Si el usuario existe pero no tiene selecciones activas, backend responde `200` con `data: []`.
- Frontend NO debe convertir `404` en lista vacía: `404` significa que el usuario no existe y debe tratarse como error real.
- `PUT` reemplaza el conjunto activo completo.
- `DELETE` por item desactiva logicamente una seleccion puntual ya activa.

Ejemplo Flutter:

```dart
final response = await dio.get('/users/$userId/allergies');
final items = (response.data['data'] as List<dynamic>)
    .map((json) => AllergyModel.fromJson(json as Map<String, dynamic>))
    .toList();
```

### Módulo: Rutas sensibles de usuario

Para `/api/v1/users/:userId/...` en superficies sensibles verificadas (`allergies`, `diseases`, `emergency-contacts`, `legal-representative`, `profile-picture`, `post-registration`, `age`, `requires-legal-representative`):

- frontend no debe interpretar estas rutas como mero "JWT-only";
- self-service depende de ownership sobre `userId`;
- acceso sobre terceros requiere permiso global resuelto (`users:read_detail` o `users:update`), no permisos de club derivados del contexto activo;
- no introducir gating fino por salud/legal/contactos porque el backend todavía no expone permisos separados para esas categorías.

Límites transitorios que deben quedar explícitos:

- GAP FORMAL: no existe tier RBAC separado para datos médicos, legales o de emergencia;
- politica cliente opcion C cerrada:
  - admin puede reflejar `process-state` / `administrative completion` de terceros con autorizacion global resuelta explicita;
  - `GET /post-registration/status` de terceros debe tratarse como estado administrativo mínimo, sin feedback guiado extra como `nextStep`;
  - `POST /post-registration/step-{1,2,3}/complete` de terceros debe esperar respuesta administrativa mínima del backend, sin razones sensibles detalladas;
  - mobile y admin no deben exponer ni editar datos sensibles enviados por usuario de terceros solo por `users:update` genérico;
  - clientes deben seguir la autorizacion resuelta del backend y no inventar permisos implicitos desde contexto de club o roles legacy.

### Validacion transversal final (Batch 3)

Checklist final de consistencia para frontend:

- `sacdia-admin` debe seguir usando `authorization.effective.permissions` para gating operativo y `authorization.grants` para contexto y detalle;
- `sacdia-app` debe separar `administrative completion` de acceso a datos sensibles: `users:update` no alcanza por si solo para salud/contactos/legal de terceros;
- ni admin ni mobile deben crear permisos frontend nuevos para cerrar el `GAP FORMAL`;
- la UX sobre terceros debe limitarse a la política mínima documentada y degradar el resto, aun cuando el actor tenga `users:update`.

### Módulo: Actividades

**Listar actividades del club**:

```typescript
// Next.js
export function useClubActivities(clubId: number, filters?: {
  clubTypeId?: number;
  active?: boolean;
  activityType?: string;
}) {
  const query = new URLSearchParams(filters as any).toString();
  const url = `/clubs/${clubId}/activities${query ? `?${query}` : ''}`;

  return useQuery({
    queryKey: ['club-activities', clubId, filters],
    queryFn: async () => (await apiClient.get(url)).data,
  });
}

// Uso
const { data, isLoading } = useClubActivities(5, {
  clubTypeId: 2,
  active: true,
  activityType: 'meeting'
});
```

```dart
// Flutter
Future<List<Activity>> getClubActivities(
  int clubId, {
  int? clubTypeId,
  bool? active,
  String? activityType,
}) async {
  final queryParams = <String, dynamic>{
    if (clubTypeId != null) 'clubTypeId': clubTypeId,
    if (active != null) 'active': active,
    if (activityType != null) 'activityType': activityType,
  };

  final response = await dio.get(
    '/clubs/$clubId/activities',
    queryParameters: queryParams,
  );

  return (response.data['data'] as List)
      .map((json) => Activity.fromJson(json))
      .toList();
}
```

**Registrar asistencia**:

```typescript
// Next.js
export async function registerAttendance(
  activityId: number,
  userId: string
) {
  const response = await apiClient.post(
    `/activities/${activityId}/attendance`,
    { user_id: userId }
  );
  return response.data;
}
```

```dart
// Flutter
Future<Attendance> registerAttendance(int activityId, String userId) async {
  final response = await dio.post(
    '/activities/$activityId/attendance',
    data: {'user_id': userId},
  );
  return Attendance.fromJson(response.data['data']);
}
```

---

### Módulo: Finanzas

**Obtener resumen financiero**:

```typescript
// Next.js
export function useFinancialSummary(
  clubId: number,
  year: number,
  month?: number
) {
  const params = new URLSearchParams({
    year: year.toString(),
    ...(month && { month: month.toString() }),
    clubTypeId: '2', // Conquistadores
  });

  return useQuery({
    queryKey: ['financial-summary', clubId, year, month],
    queryFn: async () => {
      const response = await apiClient.get(
        `/clubs/${clubId}/finances/summary?${params}`,
      );
      return response.data;
    },
  });
}

// Uso en componente
const { data } = useFinancialSummary(5, 2026, 2);
const summary = data?.data?.summary;

// summary.total_income
// summary.total_expenses
// summary.balance
// Si se envía year + month, balance es el saldo acumulado del año eclesiástico
// hasta ese mes; los ingresos/egresos mensuales deben salir del listado mensual.
```

```dart
// Flutter
Future<FinancialSummary> getFinancialSummary(
  int clubId,
  int year, {
  int? month,
}) async {
  final response = await dio.get(
    '/clubs/$clubId/finances/summary',
    queryParameters: {
      'year': year,
      if (month != null) 'month': month,
      'clubTypeId': 2,
    },
  );
  return FinancialSummary.fromJson(response.data['data']);
}
```

**Subir evidencia de ingreso/egreso**:

```typescript
// Next.js / navegador
export async function uploadFinanceEvidence(financeId: number, file: File) {
  const formData = new FormData();
  formData.append('file', file);

  return apiRequestFromClient(`/finances/${financeId}/evidences`, {
    method: 'POST',
    body: formData,
  });
}
```

```dart
// Flutter
Future<FinanceEvidence> uploadFinanceEvidence({
  required int financeId,
  required String filePath,
  required String fileName,
  required String mimeType,
}) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      filePath,
      filename: fileName,
      contentType: DioMediaType.parse(mimeType),
    ),
  });

  final response = await dio.post(
    '/finances/$financeId/evidences',
    data: formData,
  );
  return FinanceEvidence.fromJson(response.data['data'] ?? response.data);
}
```

El backend acepta solo imagenes (`multipart/form-data`, campo `file`), 5MB por foto y maximo 3 evidencias activas por movimiento.

---

### Módulo: Honors (Especialidades)

**Inscribir miembro en especialidad**:

```typescript
// Next.js
export async function enrollInHonor(
  userId: string,
  honorId: number,
  instructorId: string
) {
  const response = await apiClient.post(
    `/users/${userId}/honors/enroll`,
    {
      honor_id: honorId,
      instructor_user_id: instructorId,
    }
  );
  return response.data;
}
```

```dart
// Flutter
Future<Enrollment> enrollInHonor({
  required String userId,
  required int honorId,
  required String instructorId,
}) async {
  final response = await dio.post(
    '/users/$userId/honors/enroll',
    data: {
      'honor_id': honorId,
      'instructor_user_id': instructorId,
    },
  );
  return Enrollment.fromJson(response.data['data']);
}
```

---

## Best Practices

### 1. Cache y Revalidación

**Next.js con TanStack Query**:

```typescript
const { data } = useQuery({
  queryKey: ['clubs'],
  queryFn: fetchClubs,
  refetchInterval: 300000,
  refetchOnWindowFocus: true,
  refetchOnReconnect: true,
});

await createClub(newClub);
queryClient.invalidateQueries({ queryKey: ['clubs'] });
```

**Flutter con Riverpod**:

```dart
// Auto-refresh provider
final clubsProvider = StreamProvider<List<Club>>((ref) {
  return Stream.periodic(Duration(minutes: 5), (_) async {
    final useCase = ref.read(getClubsUseCaseProvider);
    final result = await useCase();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (clubs) => clubs,
    );
  }).asyncMap((future) => future);
});

// Invalidar manualmente
ref.invalidate(clubsProvider);
```

---

### 2. Optimistic Updates

**Next.js**:

```typescript
const deleteActivityMutation = useMutation({
  mutationFn: (activityId: number) => apiClient.delete(`/activities/${activityId}`),
  onMutate: async (activityId) => {
    await queryClient.cancelQueries({ queryKey: ['activities'] });
    const previous = queryClient.getQueryData(['activities']);
    queryClient.setQueryData(['activities'], (current: any) => ({
      ...current,
      data: current?.data?.filter((a: any) => a.activity_id !== activityId) ?? [],
    }));
    return { previous };
  },
  onError: (_error, _activityId, context) => {
    queryClient.setQueryData(['activities'], context?.previous);
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['activities'] });
  },
});
```

---

### 3. Paginación

**Next.js**:

```typescript
export function useActivitiesPaginated(clubId: number, page = 1, limit = 20) {
  return useQuery({
    queryKey: ['club-activities', clubId, page, limit],
    queryFn: async () => {
      const response = await apiClient.get(
        `/clubs/${clubId}/activities?page=${page}&limit=${limit}`,
      );
      return response.data;
    },
  });
}

// Uso
const [page, setPage] = useState(1);
const { data } = useActivitiesPaginated(5, page, 20);
const activities = data?.data;
const meta = data?.meta;

// meta.total, meta.totalPages, meta.page, meta.limit
```

**Flutter**:

```dart
class ActivitiesPaginationNotifier extends StateNotifier<AsyncValue<PaginatedActivities>> {
  int currentPage = 1;
  final int limit = 20;

  Future<void> loadMore() async {
    currentPage++;
    final result = await getActivities(page: currentPage, limit: limit);
    // Agregar a lista existente
  }
}
```

---

### 4. Upload de Archivos

El baseline vigente es Cloudflare R2 mediado por backend. El frontend no debe subir a storage externo directo ni construir URLs públicas manualmente.

Patrones aceptados:

1. **Multipart directo al backend** cuando el endpoint del dominio lo define.
2. **Presigned PUT a R2** cuando el módulo expone un flujo de URL firmada, por ejemplo recursos:
   - `POST /resources/upload-url`
   - `PUT upload_url` directamente a R2
   - `POST /resources/from-uploaded` para registrar el recurso ya subido

**Next.js / navegador**:

```typescript
async function uploadResource(file: File) {
  const signed = await apiClient.post('/resources/upload-url', {
    resource_type: 'document',
    scope_level: 'system',
    file_name: file.name,
    mime_type: file.type,
    file_size: file.size,
  });

  const { upload_url, file_key } = signed.data.data ?? signed.data;

  await fetch(upload_url, {
    method: 'PUT',
    headers: { 'Content-Type': file.type },
    body: file,
  });

  return apiClient.post('/resources/from-uploaded', {
    resource_type: 'document',
    scope_level: 'system',
    title: file.name,
    file_name: file.name,
    mime_type: file.type,
    file_size: file.size,
    file_key,
  });
}
```

**Flutter**:

```dart
Future<void> uploadResource(File file) async {
  final signed = await dio.post('/resources/upload-url', data: {
    'resource_type': 'document',
    'scope_level': 'system',
    'file_name': path.basename(file.path),
    'mime_type': 'application/pdf',
    'file_size': await file.length(),
  });

  final data = signed.data['data'] ?? signed.data;
  await Dio().put(
    data['upload_url'] as String,
    data: file.openRead(),
    options: Options(headers: {'Content-Type': 'application/pdf'}),
  );

  await dio.post('/resources/from-uploaded', data: {
    'resource_type': 'document',
    'scope_level': 'system',
    'title': path.basename(file.path),
    'file_name': path.basename(file.path),
    'mime_type': 'application/pdf',
    'file_size': await file.length(),
    'file_key': data['file_key'],
  });
}
```

---

## Testing

### Next.js Tests (Vitest + React Testing Library)

```typescript
// src/lib/api/clubs.test.ts
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { renderHook, waitFor } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { apiClient } from '@/lib/api/client';
import { createClub, useClubs } from '@/lib/api/services/clubs.service';

vi.mock('@/lib/api/client');

describe('Clubs Service', () => {
  it('fetches clubs', async () => {
    const mockClubs = [{ club_id: 1, name: 'Test Club' }];
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: mockClubs } });

    const queryClient = new QueryClient();
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    );

    const { result } = renderHook(() => useClubs(), { wrapper });

    await waitFor(() => expect(result.current.data).toEqual(mockClubs));
  });

  it('creates club', async () => {
    const newClub = { name: 'New Club', local_field_id: 1 };
    vi.mocked(apiClient.post).mockResolvedValue({
      data: { data: { club_id: 1, ...newClub } },
    });

    const result = await createClub(newClub);

    expect(result.data.name).toBe('New Club');
    expect(apiClient.post).toHaveBeenCalledWith('/clubs', newClub);
  });
});
```

---

### Flutter Tests (Mockito)

```dart
// test/features/clubs/data/datasources/clubs_remote_datasource_test.dart
@GenerateMocks([Dio])
void main() {
  late ClubsRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = ClubsRemoteDataSource(mockDio);
  });

  group('getClubs', () {
    test('should return list of clubs when successful', () async {
      // Arrange
      when(mockDio.get('/clubs')).thenAnswer(
        (_) async => Response(
          data: {
            'status': 'success',
            'data': [
              {'club_id': 1, 'name': 'Test Club'}
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/clubs'),
        ),
      );

      // Act
      final result = await dataSource.getClubs();

      // Assert
      expect(result, isA<List<ClubModel>>());
      expect(result.length, 1);
      expect(result.first.name, 'Test Club');
    });

    test('should throw ServerException when fails', () async {
      // Arrange
      when(mockDio.get('/clubs')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/clubs'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/clubs'),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.getClubs(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
```

---

## Recursos Adicionales

### Documentación Completa

- **API Specification**: `/docs/api/API-SPECIFICATION.md`
- **Endpoints Reference**: `/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- **Walkthroughs**: `/docs/features/*`
- **Security Guide**: `/docs/api/SECURITY-GUIDE.md`

### Collections API

- **Postman**: Importar desde `/postman/sacdia-api-v3.0.json` cuando exista colección publicada.
- **Insomnia**: Importar desde `/insomnia/sacdia-api-v3.0.json` cuando exista colección publicada.

### Soporte

- **Issues**: https://github.com/abn-r/sacdia-backend/issues
- **Documentación**: https://docs.sacdia.app (próximamente)

---

**Generado**: 4 de febrero de 2026
**Revisión editorial**: 2026-07-06
**Versión**: 3.0.0
**Estado**: ACTIVE - validar runtime actual contra `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
