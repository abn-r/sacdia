# Health y observabilidad del piloto

**Estado**: STACK-LOCAL — contrato coordinado con PR-03a `c3c7aa7`; no integrado ni
desplegado. Este documento no autoriza readiness, publicación ni piloto.

## Propósito y límites

- `GET /api/v1/health` es liveness público mínimo. Devuelve HTTP 200 con
  `status: "ok"` y un `timestamp` RFC3339 cuando el proceso responde. No devuelve
  release, ambiente, dependencias, proveedores, uptime ni infraestructura.
- `GET /api/v1/health/details` es una observación operacional V1, no un endpoint de
  readiness. Requiere JWT con rol global efectivo `super-admin`, `admin` o
  `assistant-admin`. Un JWT ausente/inválido recibe `401`; otro rol autenticado, `403`.
- HTTP 200 en el detalle significa solamente que se emitió la observación. Nunca es
  evidencia de deploy, proveedor alcanzable, readiness o GO.

## Respuesta segura V1

El detalle devuelve `schemaVersion: "1"`, `status`, `observedAt`, un
`correlationId` generado en servidor, `release`, `environment` y las observaciones de
`database`, `redis`, `queues`, `r2`, `fcm`, `resend` y `sentry`. Cada observación usa
solo `required`, `configured`, `reachable`, `verified`, `observedAt`, `status` y, si
aplica, `READINESS_DEPENDENCY_UNVERIFIED` o
`READINESS_OBSERVABILITY_INCOMPLETE`.

La identidad de release/ambiente permanece sin verificar. Una identidad no verificada
o una dependencia requerida `NOT_CONFIGURED`, `UNVERIFIED` o `DEGRADED` fuerza
`status: "NOT_READY"`. La configuración es presencia de configuración válida: no
prueba conectividad, alcance ni evidencia operacional.

## Política de sondeo y datos

- La base de datos puede quedar `READY` solo tras un `SELECT 1` de solo lectura.
- Redis, colas, R2, FCM, Resend y Sentry no se consideran verificados sin un adaptador
  de evidencia específico. Un proveedor configurado, inicializado o importado queda
  `UNVERIFIED`.
- No ejecutar writes de DB/caché, llamadas a colas/proveedores ni crear clientes de red
  para responder esta ruta.
- Nunca incluir secretos, valores de entorno, URLs, DSN, hostnames, stacks ni
  `error.message` en respuesta, logs de diagnóstico o evidencia.

## Caché, evidencia y escalamiento

El detalle usa `Cache-Control: private, no-store, max-age=0`, `Pragma: no-cache` y
`Vary: Authorization`; el liveness usa `Cache-Control: no-store`. Los dashboards,
alertas o decisiones de proveedor no existen como evidencia hasta registrar una
`EvidenceReference` verificable. Sin ella, el estado operativo es `MISSING/NO_GO`, no
`READY`.

Antes de cualquier paso de piloto, un owner de plataforma debe aportar identidad de
ambiente autoritativa y adaptadores/evidencia para cada dependencia requerida. Si falta
cualquiera, detener la promoción: este contrato sigue siendo observacional y
`NOT_READY`.

## Verificación contractual

Las pruebas focales deben comprobar liveness mínimo, `401`/`403`, alias de roles,
cabeceras privadas, `NOT_READY` frente a identidad/dependencias no verificadas y
redacción total de excepciones y valores sensibles. Son pruebas locales de contrato;
no sustituyen smoke remoto, certificación de proveedor ni aprobación de piloto.
