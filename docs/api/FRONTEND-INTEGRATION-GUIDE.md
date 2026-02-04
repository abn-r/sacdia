# Guía de Integración Frontend - SACDIA API v2.2

**Versión**: 2.2.0
**Fecha**: 4 de febrero de 2026
**Audiencia**: Desarrolladores Frontend (Admin Panel & Mobile App)

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

```typescript
const API_URLS = {
  development: 'http://localhost:3000/api/v1',
  staging: 'https://api-staging.sacdia.app/api/v1',
  production: 'https://api.sacdia.app/api/v1'
};
```

### Endpoints Totales

- **105+ endpoints REST**
- **17 módulos funcionales**
- **Versionado**: `/api/v1/` (URI-based)
- **Formato**: JSON
- **Autenticación**: JWT (Supabase Auth)

---

## Setup Inicial

### Next.js Admin Panel

**Instalar dependencias**:

```bash
pnpm add @supabase/supabase-js axios swr
```

**Configurar cliente API**:

```typescript
// lib/api/client.ts
import axios from 'axios';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para agregar token automáticamente
apiClient.interceptors.request.use(async (config) => {
  const { data: { session } } = await supabase.auth.getSession();

  if (session?.access_token) {
    config.headers.Authorization = `Bearer ${session.access_token}`;
  }

  return config;
});

// Interceptor para manejo de errores
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expirado, refrescar
      const { data: { session } } = await supabase.auth.refreshSession();

      if (session) {
        // Reintentar request con nuevo token
        error.config.headers.Authorization = `Bearer ${session.access_token}`;
        return apiClient.request(error.config);
      } else {
        // Sesión inválida, redirigir a login
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  }
);

export { apiClient, supabase };
```

---

### Flutter Mobile App

**Dependencias** (`pubspec.yaml`):

```yaml
dependencies:
  dio: ^5.4.0
  supabase_flutter: ^2.3.0
  flutter_secure_storage: ^9.0.0
```

**Configurar cliente API**:

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  late final Dio _dio;
  final SupabaseClient _supabase;

  ApiClient(this._supabase) {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://localhost:3000/api/v1',
      ),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor para token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final session = _supabase.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expirado, refrescar
          final session = await _supabase.auth.refreshSession();
          if (session.session != null) {
            // Reintentar request
            final opts = error.requestOptions;
            opts.headers['Authorization'] =
              'Bearer ${session.session!.accessToken}';
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}
```

---

## Autenticación

### 1. Login con Email/Password

**Next.js**:

```typescript
// app/login/actions.ts
'use server';

import { supabase } from '@/lib/api/client';

export async function loginAction(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    return { error: error.message };
  }

  return { user: data.user, session: data.session };
}
```

**Flutter**:

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart
class AuthRemoteDataSource {
  final SupabaseClient supabase;

  Future<Session> login(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session == null) {
      throw ServerException('Login failed');
    }

    return response.session!;
  }
}
```

---

### 2. OAuth con Google

**Next.js**:

```typescript
// app/login/oauth-buttons.tsx
'use client';

import { supabase } from '@/lib/api/client';

export function GoogleLoginButton() {
  const handleGoogleLogin = async () => {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    if (error) {
      console.error('OAuth error:', error);
    }
  };

  return (
    <button onClick={handleGoogleLogin}>
      Sign in with Google
    </button>
  );
}
```

**Flutter**:

```dart
Future<void> signInWithGoogle() async {
  final response = await supabase.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'com.sacdia.app://auth/callback',
  );

  if (!response) {
    throw ServerException('OAuth failed');
  }
}
```

---

### 3. Verificar Autenticación

**Next.js Middleware**:

```typescript
// middleware.ts
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export async function middleware(req: NextRequest) {
  const res = NextResponse.next();
  const supabase = createMiddlewareClient({ req, res });

  const {
    data: { session },
  } = await supabase.auth.getSession();

  // Proteger rutas
  if (!session && req.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', req.url));
  }

  return res;
}

export const config = {
  matcher: ['/dashboard/:path*', '/clubs/:path*'],
};
```

**Flutter Route Guard**:

```dart
class AuthGuard extends AutoRouteGuard {
  final SupabaseClient supabase;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (supabase.auth.currentSession != null) {
      resolver.next();
    } else {
      router.push(const LoginRoute());
    }
  }
}
```

---

## Consumo de Endpoints

### Pattern Recomendado: API Service Layer

**Next.js** (con SWR):

```typescript
// lib/api/services/clubs.service.ts
import { apiClient } from '../client';
import useSWR from 'swr';

export interface Club {
  club_id: number;
  name: string;
  local_field_id: number;
  club_types: {
    club_type_id: number;
    name: string;
  };
  active: boolean;
}

// Fetcher genérico
const fetcher = (url: string) => apiClient.get(url).then((res) => res.data);

// Hook para listar clubs
export function useClubs() {
  const { data, error, isLoading, mutate } = useSWR<{
    status: string;
    data: Club[];
  }>('/clubs', fetcher);

  return {
    clubs: data?.data,
    isLoading,
    isError: error,
    mutate,
  };
}

// Función para crear club
export async function createClub(clubData: Partial<Club>) {
  const response = await apiClient.post('/clubs', clubData);
  return response.data;
}

// Función para actualizar club
export async function updateClub(clubId: number, clubData: Partial<Club>) {
  const response = await apiClient.patch(`/clubs/${clubId}`, clubData);
  return response.data;
}

// Función para eliminar club
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

  return useSWR(url, fetcher);
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

  return useSWR(
    `/clubs/${clubId}/finances/summary?${params}`,
    fetcher
  );
}

// Uso en componente
const { data } = useFinancialSummary(5, 2026, 2);
const summary = data?.data?.summary;

// summary.total_income
// summary.total_expenses
// summary.balance
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

**Next.js con SWR**:

```typescript
// Revalidar automáticamente cada 5 minutos
const { data } = useSWR('/clubs', fetcher, {
  refreshInterval: 300000,
  revalidateOnFocus: true,
  revalidateOnReconnect: true,
});

// Revalidar manualmente
const { mutate } = useSWR('/clubs', fetcher);
await createClub(newClub);
mutate(); // Revalidar inmediatamente
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
async function deleteActivity(activityId: number) {
  const { data, mutate } = useSWR('/activities', fetcher);

  // Optimistic update
  mutate(
    {
      ...data,
      data: data.data.filter((a: any) => a.activity_id !== activityId),
    },
    false // No revalidar aún
  );

  try {
    await apiClient.delete(`/activities/${activityId}`);
    mutate(); // Revalidar para confirmar
  } catch (error) {
    mutate(); // Revertir en caso de error
    throw error;
  }
}
```

---

### 3. Paginación

**Next.js**:

```typescript
export function useActivitiesPaginated(clubId: number, page = 1, limit = 20) {
  const url = `/clubs/${clubId}/activities?page=${page}&limit=${limit}`;
  const { data, error, isLoading } = useSWR(url, fetcher);

  return {
    activities: data?.data,
    meta: data?.meta,
    isLoading,
    isError: error,
  };
}

// Uso
const [page, setPage] = useState(1);
const { activities, meta } = useActivitiesPaginated(5, page, 20);

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

**Next.js**:

```typescript
export async function uploadActivityPhoto(
  activityId: number,
  file: File
) {
  // 1. Upload a Supabase Storage
  const fileName = `${activityId}_${Date.now()}_${file.name}`;
  const { data: uploadData, error: uploadError } = await supabase
    .storage
    .from('activities')
    .upload(fileName, file);

  if (uploadError) throw uploadError;

  // 2. Get public URL
  const { data: { publicUrl } } = supabase
    .storage
    .from('activities')
    .getPublicUrl(fileName);

  // 3. Update activity with photo URL
  await apiClient.patch(`/activities/${activityId}`, {
    photos: [publicUrl], // O agregar a array existente
  });

  return publicUrl;
}
```

**Flutter**:

```dart
Future<String> uploadActivityPhoto(int activityId, File file) async {
  // 1. Upload to Supabase Storage
  final fileName = '${activityId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
  final response = await supabase.storage
      .from('activities')
      .upload(fileName, file);

  // 2. Get public URL
  final publicUrl = supabase.storage
      .from('activities')
      .getPublicUrl(fileName);

  // 3. Update activity
  await dio.patch('/activities/$activityId', data: {
    'photos': [publicUrl],
  });

  return publicUrl;
}
```

---

## Testing

### Next.js Tests (Jest + React Testing Library)

```typescript
// __tests__/api/clubs.service.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { SWRConfig } from 'swr';
import { useClubs, createClub } from '@/lib/api/services/clubs.service';
import { apiClient } from '@/lib/api/client';

jest.mock('@/lib/api/client');

describe('Clubs Service', () => {
  it('should fetch clubs', async () => {
    const mockClubs = [{ club_id: 1, name: 'Test Club' }];
    (apiClient.get as jest.Mock).mockResolvedValue({
      data: { data: mockClubs },
    });

    const wrapper = ({ children }: any) => (
      <SWRConfig value={{ provider: () => new Map() }}>
        {children}
      </SWRConfig>
    );

    const { result } = renderHook(() => useClubs(), { wrapper });

    await waitFor(() => expect(result.current.clubs).toEqual(mockClubs));
  });

  it('should create club', async () => {
    const newClub = { name: 'New Club', local_field_id: 1 };
    (apiClient.post as jest.Mock).mockResolvedValue({
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
- **Endpoints Reference**: `/docs/api/ENDPOINTS-REFERENCE.md`
- **Walkthroughs**: `/docs/api/walkthrough-*.md` (15 guías)
- **Security Guide**: `/docs/api/SECURITY-GUIDE.md`

### Collections API

- **Postman**: Importar desde `/postman/sacdia-api-v2.2.json` (próximamente)
- **Insomnia**: Importar desde `/insomnia/sacdia-api-v2.2.json` (próximamente)

### Soporte

- **Issues**: https://github.com/abn-r/sacdia-backend/issues
- **Documentación**: https://docs.sacdia.app (próximamente)

---

**Generado**: 4 de febrero de 2026
**Versión**: 2.2.0
**Estado**: Producción Ready
