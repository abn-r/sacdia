# Plan de Acción - SACDIA Flutter App

> **Basado en**: Auditoría del 11 de febrero de 2026
> **Objetivo**: Resolver problemas críticos y completar Microfase 10
> **Última actualización**: 18 de febrero de 2026

## Resumen de Progreso

| Métrica | Antes | Después | Cambio |
|---------|-------|---------|--------|
| Issues totales | 87 | 52 | -40% |
| API Coverage | 49% | ~65% | +16% |
| Warnings críticos | 5 | 0 | ✅ |
| Deprecaciones withOpacity | 52 | 0 | ✅ |
| UI Rediseño (Phase 2B) | — | ✅ Completo | 57 archivos |
| HugeIcons migración | — | ✅ Completo | 0 Material Icons |

## Resumen de Sprints

| Sprint | Enfoque | Duración Est. | Estado |
|--------|---------|---------------|--------|
| Sprint 1 | Bugs Críticos de Auth | 2-3 días | ✅ COMPLETADO |
| Sprint 2 | Completar API Core | 3-4 días | ✅ COMPLETADO |
| Sprint 3 | Code Quality | 2-3 días | ✅ COMPLETADO |
| Sprint 4 | Testing (Microfase 10) | 5-7 días | ⏳ PENDIENTE |

---

## Sprint 1: Bugs Críticos de Autenticación ✅ COMPLETADO

**Duración real**: 12 de febrero de 2026
**Estado**: ✅ COMPLETADO

### Task 1.1: Corregir AuthInterceptor ✅

**Archivo**: `lib/core/network/interceptors/auth_interceptor.dart`

**Cambios realizados**:
- Migrado de `Interceptor` a `QueuedInterceptor` para soporte async
- Reemplazado Supabase session por FlutterSecureStorage
- Agregado inyección de dependencias (FlutterSecureStorage, Dio opcional)

**Checklist**:
- [x] Modificar `auth_interceptor.dart`
- [x] Verificar que el interceptor sea async-compatible (QueuedInterceptor)
- [x] Actualizar `dio_client.dart` si es necesario
- [x] Probar login/logout flujo completo

### Task 1.2: Implementar Refresh Token ✅

> Nota de contrato (2026-03-04): `POST /api/v1/auth/refresh` usa `refreshToken` como contrato oficial.
> Compatibilidad temporal: `refresh_token` solo entre **2026-03-04** y **2026-03-18** con `AUTH_REJECT_SNAKE_CASE=false`.
> `POST /api/v1/auth/logout` es fail-safe (best effort) y no debe bloquear cierre de sesión en app.

**Archivo**: `lib/core/network/interceptors/auth_interceptor.dart`

**Cambios realizados**:
- Implementado `_tryRefreshToken()` con llamada a `/api/v1/auth/refresh`
- Auto-refresh en `onError` cuando recibe 401
- Retry automático de request original tras refresh exitoso
- Almacenamiento de refreshToken en FlutterSecureStorage

**Checklist**:
- [x] Crear modelo `AuthTokens` si no existe
- [x] Agregar método `refreshToken` al datasource
- [x] Agregar al repository interface y implementation
- [x] Crear use case `RefreshToken`
- [x] Implementar auto-refresh en interceptor (401 → refresh → retry)
- [x] Almacenar refreshToken en FlutterSecureStorage

### Task 1.3: Corregir Endpoint de Registro ✅

**Archivo**: `lib/features/auth/data/datasources/auth_remote_data_source.dart`

**Cambios realizados**:
- Endpoint cambiado a `/api/v1/auth/register`
- Campos renombrados: `p_lastname` → `paternal_last_name`, `m_lastname` → `maternal_last_name`
- Guardado de refreshToken junto con accessToken

**Checklist**:
- [x] Cambiar endpoint a `/api/v1/auth/register`
- [x] Verificar campos de request body según API spec
- [x] Actualizar modelo de response si es necesario
- [x] Probar registro completo

### Task 1.4: Estandarizar Nombres de Tokens ✅

**Cambios realizados**:
- Agregado `refreshTokenKey` a `AppConstants`
- Actualizado `auth_remote_data_source.dart` para guardar ambos tokens
- Corregido `network_info.dart` - bug de tipo (List vs single value)

**Checklist**:
- [x] Auditar todos los datasources
- [x] Crear constantes centralizadas en `AppConstants`
- [x] Reemplazar strings hardcodeados
- [x] Verificar que todos lean/escriban con las mismas keys

---

## Sprint 2: Completar API Core ✅ COMPLETADO

**Duración real**: 12 de febrero de 2026
**Estado**: ✅ COMPLETADO

### Task 2.1: Implementar Catálogos Faltantes ✅

**Archivos creados**:
- `lib/shared/models/catalogs/club_type_model.dart`
- `lib/shared/models/catalogs/district_model.dart`
- `lib/shared/models/catalogs/church_model.dart`
- `lib/shared/models/catalogs/role_model.dart`
- `lib/shared/models/catalogs/ecclesiastical_year_model.dart`
- `lib/shared/data/datasources/catalogs_remote_data_source.dart`
- `lib/providers/catalogs_provider.dart`

**Endpoints implementados**: 5 nuevos endpoints de catálogos
- `GET /catalogs/club-types`
- `GET /catalogs/districts`
- `GET /catalogs/churches`
- `GET /catalogs/roles`
- `GET /catalogs/ecclesiastical-years`

**Checklist**:
- [x] Crear modelos: `ClubTypeModel`, `DistrictModel`, `ChurchModel`, `RoleModel`, `EcclesiasticalYearModel`
- [x] Agregar métodos al datasource
- [x] Actualizar repository
- [x] Crear use cases correspondientes
- [x] Agregar providers (FutureProvider y FutureProvider.family)

### Task 2.2: Completar Endpoints de Activities ✅

**Archivo**: `lib/features/activities/data/datasources/activities_remote_data_source.dart`

**Cambios realizados**:
- Agregado `createActivity()` - POST /clubs/{clubId}/activities
- Agregado `updateActivity()` - PATCH /activities/{id}
- Agregado `deleteActivity()` - DELETE /activities/{id}
- Actualizado `registerAttendance()` - Cambio de firma: `(activityId, userId)` → `(activityId, List<String> userIds)`

**Archivos actualizados para nueva firma de attendance**:
- `activities_repository.dart` (interface + implementation)
- `register_attendance.dart` (use case + params)
- `activities_providers.dart` (notifier)
- `activity_detail_view.dart` (UI)

**Checklist**:
- [x] Crear DTOs: `CreateActivityDto`, `UpdateActivityDto`
- [x] Agregar métodos al datasource
- [x] Actualizar repository interface e implementation
- [x] Crear use cases
- [x] Agregar providers
- [x] Implementar UI para crear/editar/eliminar

### Task 2.3: Agregar Paginación Consistente ⏳

**Estado**: Parcialmente implementado (estructura base existe)

**Checklist**:
- [x] `GET /clubs` - Agregar page/limit
- [x] `GET /honors` - Agregar page/limit
- [x] `GET /activities` - Agregar page/limit
- [ ] Modelo genérico `PaginatedResponse<T>` (opcional para futuro)

---

## Sprint 3: Code Quality ✅ COMPLETADO

**Duración real**: 12 de febrero de 2026
**Estado**: ✅ COMPLETADO

### Task 3.1: Corregir Warnings Críticos ✅

#### 3.1.1 network_info.dart ✅
- Corregido bug de tipo: `List<ConnectivityResult>` vs single value
- Cambio: `result != ConnectivityResult.none` → `!result.contains(ConnectivityResult.none)`

#### 3.1.2 theme_provider.dart ✅
- Corregido: eliminado `await` innecesario en `getString()` que no es Future

#### 3.1.3 BuildContext Async ✅

**Archivos actualizados con patrón `if (!mounted) return`**:
- [x] `activity_detail_view.dart:144`
- [x] `section_detail_view.dart:119`
- [x] `home_view.dart:108,114`
- [x] `club_selection_step_view.dart:78`

### Task 3.2: Actualizar Deprecaciones ✅

**Resultado**: 27 archivos actualizados

**Cambio aplicado**:
```dart
// DE:
color.withOpacity(0.5)

// A:
color.withValues(alpha: 0.5)
```

**Archivos modificados** (batch update via sed):
- `app_colors.dart`
- `profile_header.dart`
- `info_section.dart`
- `setting_tile.dart`
- `activity_detail_view.dart`
- `post_registration_page.dart`
- `step_indicator.dart`
- `personal_info_step.dart`
- `club_selection_step_view.dart`
- `club_membership_card.dart`
- `club_role_selector.dart`
- `club_selector.dart`
- `personal_info_form.dart`
- `home_view.dart`
- `honor_detail_view.dart`
- `honor_card.dart`
- `honor_requirements_section.dart`
- `class_card.dart`
- `class_detail_view.dart`
- `section_detail_view.dart`
- `requirement_item.dart`
- `dashboard_card.dart`
- `dashboard_view.dart`
- `activity_card.dart`
- `attendance_button.dart`
- `activities_list_view.dart`
- `login_view.dart`

### Task 3.3: Crear Constantes Centralizadas ✅

**Estado**: Parcialmente implementado

- [x] `AppConstants.tokenKey` y `refreshTokenKey` centralizados
- [ ] Archivo separado `storage_keys.dart` (opcional)
- [ ] Archivo `api_endpoints.dart` (opcional para futuro refactor)

---

## Sprint 4: Testing (Microfase 10)

**Duración estimada**: 5-7 días
**Prioridad**: 🟡 MEDIA

### Task 4.1: Unit Tests para Use Cases

**Estructura de tests**:
```
test/
├── features/
│   ├── auth/
│   │   └── domain/
│   │       └── usecases/
│   │           ├── sign_in_test.dart
│   │           ├── sign_out_test.dart
│   │           └── get_current_user_test.dart
│   ├── classes/
│   │   └── domain/
│   │       └── usecases/
│   │           └── get_classes_test.dart
│   └── honors/
│       └── domain/
│           └── usecases/
│               └── get_honors_test.dart
└── core/
    └── network/
        └── dio_client_test.dart
```

**Patrón de test**:
```dart
void main() {
  late SignIn useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignIn(mockRepository);
  });

  test('should return UserEntity on successful login', () async {
    // Arrange
    when(mockRepository.signIn(any, any))
        .thenAnswer((_) async => Right(tUserEntity));

    // Act
    final result = await useCase(SignInParams(email: 'test@test.com', password: 'pass'));

    // Assert
    expect(result, Right(tUserEntity));
    verify(mockRepository.signIn('test@test.com', 'pass'));
  });
}
```

### Task 4.2: Widget Tests

**Prioridad de screens**:
1. [ ] LoginView
2. [ ] RegisterView
3. [ ] PostRegistration Steps
4. [ ] DashboardView
5. [ ] ClassesListView
6. [ ] HonorsListView

### Task 4.3: Integration Tests

**Flujos críticos**:
1. [ ] Login → Dashboard → Logout
2. [ ] Register → Post-Registration Complete
3. [ ] Ver clases → Ver progreso → Actualizar progreso
4. [ ] Ver honores → Iniciar honor → Actualizar

---

## Checklist de Completitud

### Sprint 1 ✅ COMPLETADO (12 Feb 2026)
- [x] AuthInterceptor corregido (QueuedInterceptor + FlutterSecureStorage)
- [x] Refresh token implementado (auto-refresh en 401)
- [x] Endpoint registro corregido (/auth/register + campos correctos)
- [x] Tokens estandarizados (AppConstants.tokenKey, refreshTokenKey)
- [ ] Tests de auth pasando (pendiente Sprint 4)

### Sprint 2 ✅ COMPLETADO (12 Feb 2026)
- [x] Catálogos implementados (5 modelos + datasource + providers)
- [x] Activities CRUD completo (create, update, delete, registerAttendance)
- [x] Paginación consistente (endpoints soportan page/limit)
- [x] Providers actualizados (FutureProvider.family para catálogos)

### Sprint 3 ✅ COMPLETADO (12 Feb 2026)
- [x] 0 warnings críticos (network_info, theme_provider, BuildContext async)
- [x] Deprecaciones actualizadas (27 archivos: withOpacity → withValues)
- [x] Constantes centralizadas (parcial - AppConstants)
- [ ] flutter analyze limpio (0 errors, 0 warnings, ~60 info items restantes)

### Sprint 4 ⏳ PENDIENTE
- [ ] Unit tests >80% coverage en use cases
- [ ] Widget tests para screens principales
- [ ] Integration tests para flujos críticos
- [ ] CI/CD configurado

---

## Notas de Implementación

### Orden de Ejecución (Completado)

1. ✅ **Task 1.4** (Estandarizar tokens) - Base para todo lo demás
2. ✅ **Task 1.1** (AuthInterceptor) - Crítico para que funcione auth
3. ✅ **Task 1.3** (Endpoint registro) - Quick fix
4. ✅ **Task 1.2** (Refresh token) - Más complejo, depende de 1.1
5. ✅ **Sprint 2** - Una vez auth funciona
6. ✅ **Sprint 3** - Limpieza de código
7. ⏳ **Sprint 4** - Testing (Próximo paso)

### Dependencias de Paquetes Necesarias

```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

### Comandos Útiles

```bash
# Ejecutar flutter analyze
flutter analyze

# Ejecutar tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Ver reporte de coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Historial de Cambios

### 12 Feb 2026 - Sprints 1-3 Completados

**Archivos críticos modificados**:
- `lib/core/network/interceptors/auth_interceptor.dart` - QueuedInterceptor + refresh token
- `lib/core/network/network_info.dart` - Fix tipo List<ConnectivityResult>
- `lib/core/constants/app_constants.dart` - Agregado refreshTokenKey
- `lib/core/theme/theme_provider.dart` - Removido await innecesario
- `lib/features/auth/data/datasources/auth_remote_data_source.dart` - Endpoint + campos corregidos

**Archivos nuevos creados**:
- `lib/shared/models/catalogs/club_type_model.dart`
- `lib/shared/models/catalogs/district_model.dart`
- `lib/shared/models/catalogs/church_model.dart`
- `lib/shared/models/catalogs/role_model.dart`
- `lib/shared/models/catalogs/ecclesiastical_year_model.dart`
- `lib/shared/data/datasources/catalogs_remote_data_source.dart`
- `lib/providers/catalogs_provider.dart`

**Mejoras de código**:
- 27 archivos actualizados: `withOpacity()` → `withValues(alpha:)`
- 4 archivos con BuildContext async pattern aplicado
- Activities CRUD completo con nueva firma de attendance

**Próximos pasos**: Sprint 4 (Testing - Microfase 10)
