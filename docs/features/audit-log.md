# Audit Log Interno de Operaciones

Registro persistente en `audit_logs` de toda mutación del sistema: quién, qué, cuándo y con qué resultado. Fase 1 implementada el 2026-08-12.

## Arquitectura: 3 niveles

| Nivel | Mecanismo | Cobertura | Garantía |
|-------|-----------|-----------|----------|
| 1. Automático | `HttpAuditInterceptor` (global, `APP_INTERCEPTOR` en `AuditLogsModule`) | Toda mutación HTTP (POST/PUT/PATCH/DELETE) | Best-effort |
| 2. Explícito | `AuditLogsService.recordEvent()` | Eventos de dominio con `summary`/`changes` ricos | Best-effort |
| 3. Crítico | `CriticalAuditWriterService.write()` | RBAC, denegaciones, operaciones sensibles | Durable, misma TX, idempotente vía `event_key` |

Una operación produce **una sola fila**: si un servicio escribe un evento explícito (nivel 2 o 3) durante el request, el interceptor omite su fila genérica (dedup vía flag en el contexto de request).

## Componentes (sacdia-backend)

| Archivo | Rol |
|---------|-----|
| `src/audit-logs/audit-request-context.ts` | Contexto por request (`AsyncLocalStorage`): `correlationId` + flag `explicitAuditRecorded`. Middleware registrado en `main.ts`. |
| `src/audit-logs/http-audit.interceptor.ts` | Interceptor global: log de aplicación para todo request + persistencia de mutaciones en `audit_logs` con `source='http'`. Reemplazó a `common/interceptors/audit.interceptor.ts`. |
| `src/common/decorators/audit.decorator.ts` | `@Audit({ skip })` excluye un endpoint; `@Audit({ entityType, action })` corrige la derivación automática. Aplica a handler o controller. |
| `src/audit-logs/audit-logs.service.ts` | `recordEvent` extendido: `result`, `source`, `request_context`, `correlation_id` (autocompletado desde el contexto), `actor_kind`. Marca el flag de dedup para eventos `source='service'`. |
| `src/audit-logs/critical-audit-writer.service.ts` | Sin cambios de datos; ahora marca el flag de dedup al escribir. |
| `prisma/migrations/20260812190000_audit_http_operations/` | Columnas `source`, `request_context` + índice `idx_audit_logs_created`. |

## Derivación automática (nivel 1)

Sobre el path sanitizado (query strings y segmentos tipo token eliminados), sin prefijo `api` ni versión `vN`:

- `entity_type`: primer segmento (`/api/v1/clubs/42/members` → `clubs`).
- `entity_id`: param `id`, o el param `*Id`/`*_id` más profundo de la ruta; `-` si no hay.
- `action`: `POST→CREATED`, `PUT/PATCH→UPDATED`, `DELETE→DELETED`.
- `club_id`: params `clubId`/`club_id` si son enteros positivos.
- `actor_user_id`: `request.user.user_id`; `actor_kind`: `user` o `anonymous`.
- `result`: `succeeded` / `failed` (status del error si es `HttpException`, 500 si no).
- `summary`: `"<METHOD> <path sanitizado>"`.
- `request_context`: `{ method, path, status_code, duration_ms, ip, user_agent }`.

**Nunca se persiste el body del request** — `changes` queda reservado para eventos explícitos. Evita filtrar credenciales o datos de salud.

## Exclusiones

- GET/HEAD/OPTIONS: nunca se persisten.
- Rutas: `health`, `auth/refresh` (constante `EXCLUDED_PATHS` en el interceptor).
- Endpoints con `@Audit({ skip: true })`.
- Requests que ya registraron un evento explícito (dedup).
- Escritura fire-and-forget: un fallo de audit jamás afecta la respuesta.

## Correlación

`auditContextMiddleware` (registrado en `main.ts` antes de los handlers) abre el contexto por request:

- `correlation_id`: header `x-request-id` si es UUID válido; si no, UUID generado.
- Los tres niveles comparten el mismo `correlation_id` automáticamente (niveles 1 y 2; nivel 3 lo recibe explícito por diseño de idempotencia).
- Consulta de una operación completa: `WHERE correlation_id = ?` (índice `idx_audit_logs_correlation_id`).

## Fases

- **Fase 1 (hecha)**: migración, contexto, interceptor, decorador, dedup, tests.
- **Fase 2 (pendiente)**: `GET /admin/audit-logs` con filtros (`entity_type`, `actor_user_id`, `action`, `result`, fechas) + permiso `audit:read` + UI en sacdia-admin. Contract-first: definir DTOs antes de consumir.
- **Fase 3 (pendiente)**: cron de retención — exportar filas > 24 meses a R2 (NDJSON comprimido) y purgar; filas con `event_key` (críticas) se conservan más tiempo (definir con negocio).

## Tests

- `src/audit-logs/http-audit.interceptor.spec.ts` — derivación, exclusiones, overrides, dedup, correlación, fallos.
- `src/audit-logs/audit-request-context.spec.ts` — contexto ALS y middleware.
- `src/audit-logs/audit-logs.service.spec.ts` — campos nuevos de `recordEvent`.
- `src/audit-logs/audit-http-operations.migration.spec.ts` — migración (gated: `ALLOW_AUTHORIZATION_P0_INTEGRATION_DB=1` + `AUTHORIZATION_P0_INTEGRATION_DATABASE_URL`).
