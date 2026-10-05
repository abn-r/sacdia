# Coding Standards

**Estado**: ACTIVE
**Actualizado**: 2026-10-04

> Reglas de código que el proyecto aplica de verdad (configuración, CI o patrones dominantes en el código de `development`). Si una regla no está aquí, se sigue el patrón del código vecino.

---

## 1. Reglas comunes

- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:`).
- **Ramas**: desde `development`; integración `development` → `preproduction` → `main`.
- **Async**: `async/await`; nada de callbacks ni `.then()` encadenados en código nuevo.
- **Validación**: toda entrada de usuario se valida en el borde (DTO en backend, `zod` en formularios del admin, validadores de formulario en la app).
- **Errores**: `try/catch` en operaciones asíncronas que pueden fallar; no tragar errores sin log.
- **Secretos**: nunca en el código ni en documentación versionada; los nombres de variables viven en `sacdia-backend/.env.example`.
- **Textos de UI**: siempre traducibles (admin con `next-intl`, app con `easy_localization`); los cuatro locales son `es`, `en`, `fr` y `pt-BR`.
- **Documentación**: si cambia comportamiento, se actualiza la documentación en el mismo trabajo (ver `AGENTS.md` §5).

---

## 2. Backend (NestJS + Prisma)

### Estructura

- Un módulo por dominio en `src/<módulo>/` con `*.module.ts`, `*.controller.ts`, `*.service.ts` y `dto/`.
- Los controllers solo traducen HTTP ↔ servicio; la lógica vive en servicios.
- Lo transversal va en `src/common/` (guards, decorators, pipes, filters, errores, email).

### Validación de entrada

- DTOs con `class-validator` + `class-transformer` (`@Type(() => Number)` para query params numéricos).
- El pipe global es `I18nValidationPipe` con `whitelist: true`, `forbidNonWhitelisted: true` y `transform: true`, precedido por `SanitizePipe`. Un campo no declarado en el DTO provoca 400: declara todo lo que el cliente envía.
- Paginación con `PaginationDto` (`page` desde 1, `limit` por defecto 20, máximo 100) y `createPaginatedResult` (`src/common/dto/pagination.dto.ts`).

### Autorización

- `PermissionsGuard` es global y deny-by-default: cada handler nuevo declara `@Public()`, `@SkipPermissions()` o `@RequirePermissions('recurso:acción')` con su recurso de autorización. Sin eso el endpoint responde error de configuración.
- `@GlobalRoles(...)` solo para superficies reservadas a roles de plataforma (`admin`, `super-admin`, `coordinator`).
- Un permiso nuevo se añade a `prisma/seeds/permissions.seed.sql` y se reparte en `role-permissions.seed.sql`; después se refleja en el screen catalog del admin si afecta a una pantalla.
- Reutilizar permisos de otro dominio rompe la frontera de concerns (ver `docs/canon/decisiones-clave.md` §16–§21).

### Respuestas y errores

- Éxito: `{ status: 'success', data }` (algunos endpoints de analytics usan `status: 'ok'`; no extender esa variante).
- Errores de dominio: `throw new AppException(ErrorCode.X, HttpStatus.Y)` o sus subclases (`AppForbiddenException`, `AppConflictException`...). El filtro global traduce `errors.<CODE>` con `nestjs-i18n` y responde `{ status: 'error', code, message }`.
- Códigos nuevos: añadirlos a `src/common/errors/error-codes.ts` y traducirlos en `src/i18n/<locale>/errors.json` para los cuatro locales.

### Datos

- Prisma como única vía de acceso a datos; `$transaction` cuando una operación toca varias tablas que deben quedar consistentes.
- Cambios de schema solo con migración Prisma (`pnpm prisma migrate dev`), nunca `db push` contra entornos compartidos.
- Reglas de datos detalladas en `docs/steering/data-guidelines.md`.

### Efectos secundarios

- Notificaciones, invalidación realtime y logros se disparan **fire-and-forget**: el fallo del transporte no puede romper la respuesta del endpoint.
- Trabajo pesado o diferible va a BullMQ (`emails`, `notifications`, `achievements`, `background-jobs`, `master-honors`, `certificate-import-ocr`).

### Logs

- `Logger` de NestJS (salida `nestjs-pino`) con `new Logger(<Clase>.name)`. No usar `console.log` en código de servidor.
- No registrar PII ni tokens.

### Calidad

- Formato: Prettier (`singleQuote`, `trailingComma: all`); `pnpm run format`.
- Lint: ESLint (`pnpm run lint`); las reglas `no-unsafe-*` están desactivadas por compatibilidad con Prisma.
- Tests: Jest; los unitarios van junto al código (`*.spec.ts`), los e2e en `test/*.e2e-spec.ts`.
- CI bloqueante: `prisma validate`, lint, build, tests unitarios y `pnpm run audit:security`.

---

## 3. Admin (Next.js 16)

- App Router: Server Components por defecto; `'use client'` solo cuando hace falta interacción o estado de navegador.
- Llamadas a la API con el cliente de `src/lib/api/client.ts` (un archivo por recurso en `src/lib/api/`). No llamar al backend con `fetch` suelto.
- La sesión vive en cookies httpOnly gestionadas por `src/app/api/auth/*`; el código cliente no lee tokens.
- Toda pantalla nueva se registra en el screen catalog (`src/lib/auth/screen-catalog/screens/`) con los mismos permisos que exige el backend, y su entrada de sidebar usa el mismo id.
- UI con componentes de `src/components/ui/` (shadcn) y Tailwind v4; reutilizar antes de crear.
- Formularios con `react-hook-form` + `zod`.
- Estado de servidor con TanStack Query; estado de preferencias con Zustand.
- Textos con `next-intl`; añadir la clave a los cuatro archivos de `messages/`.
- Tests con Vitest + Testing Library (`*.test.ts(x)` junto al código). CI: `pnpm build`, `pnpm test`, `pnpm typecheck`.

---

## 4. App móvil (Flutter)

- Feature-first: `lib/features/<feature>/{data,domain,presentation}`; lo transversal en `lib/core/` y `lib/shared/`.
- Dominio: entidades y contratos de repositorio en `domain/`; los repositorios devuelven `Either<Failure, T>` (`dartz`).
- Estado e inyección de dependencias con Riverpod; nada de singletons globales nuevos.
- HTTP con el `Dio` de `lib/providers/dio_provider.dart` y rutas en `lib/core/constants/api_endpoints.dart`. El interceptor añade el token.
- Navegación con `go_router`; nombres en `lib/core/config/route_names.dart`.
- Acceso a pantallas con `canViewScreen(screenId)` (`lib/core/authorization/`); si cambia un gate `app` en el screen catalog del admin, regenerar `test/fixtures/screen-catalog.snapshot.json`.
- Textos con `easy_localization` (`'clave'.tr()`) en los cuatro archivos de `assets/translations/`.
- Tokens solo en `flutter_secure_storage`.
- CI bloqueante: `dart format --set-exit-if-changed`, `flutter analyze` y `flutter test`.

---

## 5. Seguridad

Nunca:

- desactivar `PermissionsGuard` o marcar `@Public()` un endpoint que lee datos de usuario;
- exponer Swagger en producción ni relajar `ALLOWED_ORIGINS`;
- guardar tokens fuera de cookies httpOnly (admin) o `flutter_secure_storage` (app);
- reutilizar `BETTER_AUTH_SECRET` como `QR_JWT_SECRET`;
- devolver URLs públicas de buckets privados (usar URLs firmadas).

Siempre:

- validar ownership o alcance territorial en el servicio cuando el permiso no basta (patrón de `AnnualFoldersService` y superficies sensibles de usuario);
- aplicar rate limit específico (`@Throttle`) a endpoints sensibles de auth.
