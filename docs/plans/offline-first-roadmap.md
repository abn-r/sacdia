# Offline-first — roadmap

**Estado**: PLANIFICADO (aspiracional)
**Autoridad rectora de la capacidad actual**: `docs/canon/runtime-resiliencia-red.md`

> Este documento describe una evolución futura. La capacidad actual del sistema es cache + invalidación, **no** offline-first. No debe comunicarse como vigente.

---

## 1. Motivación

Hoy SACDIA resuelve resiliencia de red con cache local (TTL + `flutter_cache_manager`) e invalidación por FCM silent messages. La cobertura está acotada a `activities`. Cuando el usuario pierde conectividad:

- las lecturas funcionan mientras el cache esté vigente;
- las mutaciones (crear evidencias, registrar actividades, enviar formularios) **fallan** sin fallback.

Un modelo offline-first permitiría capturar mutaciones localmente y sincronizarlas cuando la conexión regrese.

## 2. Alcance candidato (por definir)

Features prioritarias a evaluar (ordenamiento tentativo):

1. evidence_folder — subir evidencias y firmar secciones sin red;
2. activities — registrar asistencia/puntaje de sesión sin red;
3. weekly-records — captura semanal sin red;
4. honors / classes — progresión sin red;
5. monthly-reports — draft offline.

No alcance:
- autenticación offline;
- operaciones administrativas sensibles (aprobaciones, validaciones institucionales, finanzas).

## 3. Tecnología candidata

| Opción | Pros | Contras |
|--------|------|---------|
| `drift` (SQL) | schema fuerte, migraciones, queries relacionales | curva, setup grande |
| `isar` | rápido, NoSQL embebido | menos relacional |
| `hive` | simple key-value | no relacional |

Decisión pendiente. Requiere spike y prueba de concepto.

## 4. Arquitectura tentativa

- capa `LocalRepository` por feature, con contrato `read/write/pendingCount`;
- **outbox pattern**: mutaciones se guardan en cola local con `status ∈ {pending, synced, failed}`;
- worker de sync al `onConnectivityChanged` + al foreground resume;
- reconciliación de conflictos (server wins vs last-writer-wins vs merge por campo — a definir por feature);
- endpoints backend tolerantes a reintentos idempotentes (clave `client_operation_id`).

## 5. Política de conflictos (por definir)

| Tipo | Estrategia candidata |
|------|---------------------|
| create puro (ej. subir evidencia) | server asigna id; cliente reconcilia local id → server id |
| update sobre recurso propio | last-writer-wins con timestamp |
| update sobre recurso institucional | server rechaza si cambió; cliente muestra conflicto |

## 6. UX

- indicador visible de "offline";
- badge por feature con conteo de mutaciones pendientes;
- manejo explícito de rechazo (item queda en estado `failed` con acción manual "reintentar" o "descartar").

## 7. Requisitos backend

- endpoints deben aceptar `client_operation_id` idempotente;
- respuestas 409/422 deben ser estructuradas para permitir reconciliación automática cuando corresponda;
- auditoría debe distinguir mutación offline tardía vs online directa.

## 8. Hitos tentativos

1. **Fase 0** — spike de tecnología (1 semana) sobre 1 feature (evidence_folder).
2. **Fase 1** — diseño de outbox + sync worker + política de conflictos.
3. **Fase 2** — implementación en `evidence_folder`. Rollout con feature flag.
4. **Fase 3** — extensión a `activities` y `weekly-records`.
5. **Fase 4** — auditoría coverage + documentación en `docs/canon/` (promoción del capítulo offline a canon).

## 9. Criterio de éxito

- mutaciones offline sincronizadas sin intervención manual en ≥95% de los casos;
- cero duplicados por reenvío;
- UX distingue claramente "sincronizado" vs "pendiente" vs "fallido".

## 10. Riesgos

- complejidad de reconciliación de conflictos en features con validación institucional;
- storage local puede crecer descontroladamente si el sync falla persistente — requiere política de expiración;
- pruebas E2E de escenarios offline son costosas.

## 11. Estado actual

- **Prioridad**: baja hasta que la cobertura actual de cache + invalidación esté auditada y las features con mutación crítica tengan demanda real de offline.
- **Decisión inmediata**: ninguna. Mantener roadmap visible y no comunicar como capacidad.
