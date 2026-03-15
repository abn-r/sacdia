# Infrastructure (Health, Logging)
Estado: NO CANON (infraestructura operativa)

> Este dominio no es parte del canon de negocio. Es infraestructura operativa documentada por referencia en `docs/canon/runtime-sacdia.md` (sección 9.1).

## Que existe (verificado contra codigo)
- **Backend**: CommonModule (global) + AppModule. Health check endpoint (GET /health). Root endpoint (GET /). Infraestructura compartida: guards (7), decorators (7), services (6), pipes (1), filters (2), interceptors (2), DTOs (1). Integraciones: Sentry (condicional), Redis/Upstash (condicional), Cloudflare R2. Seguridad global: helmet, compression, rate limiting (3/1s, 20/10s, 100/60s), validation, sanitization. Logging: nestjs-pino. API versioning: /api/v1.
- **Admin**: No implementado. No hay pages de infraestructura o monitoreo.
- **App**: No implementado.
- **DB**: error_logs

## Que define el canon
- Canon runtime 6.7 menciona health check como endpoint publico
- Canon runtime 9 documenta Redis como dependencia y baseline tecnica
- Canon runtime 9.1 clasifica infraestructura como operativa, fuera del dominio de negocio

## Gap
- No hay UI de monitoreo o diagnostico en admin ni app

## Prioridad
- Baja — infraestructura operativa, no afecta canon de negocio
