# SACDIA — Posicionamiento frente a SGC

**Estado**: DOCUMENTO ESTRATÉGICO
**Tipo**: material de comunicación institucional y comercial
**Alcance**: sostener hipótesis de valor con evidencia verificable

<!-- Este documento sintetiza capacidades VIGENTES verificadas en el canon operativo. Cualquier claim debe tener respaldo trazable en canon o features. Las hipótesis estratégicas sin respaldo se marcan explícitamente. -->

---

## 1. Propósito

Articular el posicionamiento de SACDIA frente a soluciones existentes del ecosistema DIA (principalmente SGC) apoyándose en capacidades **verificadas y canonizadas**, no en afirmaciones aspiracionales.

Este documento no reemplaza al material operativo (`docs/canon/`, `docs/features/`). Lo resume para uso estratégico. Cualquier claim aquí debe poder rastrearse a su canon de origen.

---

## 2. Marco de lectura

Cada capacidad se presenta con tres etiquetas:

- **[VIGENTE]** — respaldado por canon + implementación verificada;
- **[PARCIAL]** — existe de forma acotada, con cobertura incompleta;
- **[HIPÓTESIS]** — diferencial estratégico no sostenible hoy como hecho operativo.

---

## 3. Capacidades VIGENTES

### 3.1 Modelo institucional coherente
**[VIGENTE]** — canon `dominio-sacdia.md`, `decisiones-clave.md` §1, §2, §5.

- trayectoria institucional del miembro como eje semántico (no CRUD desconectados);
- club como entidad raíz + sección de club como unidad operativa real;
- separación explícita entre tipo de club, sección y club raíz.

### 3.2 Validación institucional como acto distinto del registro
**[VIGENTE]** — canon `decisiones-clave.md` §6 + features `validacion-evidencias.md`, `validacion-investiduras.md`.

- pipelines multietapa con historial y trazabilidad;
- investiduras, clases, honores y camporees operan con validación formal.

### 3.3 Carpeta de evidencias anual
**[VIGENTE]** — canon `runtime-sacdia.md` §10 + features `carpetas-evidencias.md`, `annual-folders-scoring.md`.

- sección como fuente única de verdad del estado de evaluación;
- folders templates + progreso + evidencias + evaluación multiétapa (LF + Unión).

### 3.4 Sistema de logros con cinco tiers institucionales
**[VIGENTE]** — canon `runtime-achievements.md` + decisión §11.

- tiers Bronze → Diamond con semántica canonizada;
- evaluación por eventos con journal persistente (`achievement_event_log`);
- cola BullMQ con fallback documentado;
- 5 features emisores activos del runtime.

### 3.5 Clasificación institucional de clubes
**[VIGENTE]** — canon `runtime-rankings.md` + decisión §12.

- ranking anual por puntaje de carpetas;
- categorías de premio configurables (globales y por tipo de club);
- pipeline automático de recálculo (cron diario 02:00 UTC, lock distribuido);
- dense ranking canonizado.

### 3.6 Analíticas operacionales (SLA dashboard)
**[VIGENTE]** — canon `runtime-sla-dashboard.md` + decisión §15.

- superficie dedicada para coordinadores;
- cobertura 3 pipelines (investiduras, validación, camporees);
- ventanas temporales canonizadas (30d overdue, 90d approval rate, 12w throughput);
- scope por `local_field_id` derivado del JWT.

### 3.7 Comunicaciones institucionales (push + bandeja)
**[VIGENTE]** — canon `runtime-communications.md` + decisión §14.

- transporte FCM con cola BullMQ y retry exponencial;
- persistencia dual (auditoría + bandeja por recipient);
- opt-out por categoría que suprime push e inbox;
- ciclo de vida completo de tokens FCM (registro, desactivación, cleanup).

### 3.8 Invalidación en tiempo real vía FCM silent messages
**[VIGENTE PARCIAL]** — canon `runtime-resiliencia-red.md` + decisión §13.

- pipeline backend → FCM silent → clientes activos;
- cobertura actual acotada a `activities`; ampliable.

### 3.9 Autenticación institucional
**[VIGENTE]** — canon `docs/canon/auth/`.

- Better Auth self-hosted (HS256 JWT + OAuth Google/Apple);
- RBAC contextual con scope territorial, asignaciones de club y asignación activa.

### 3.10 Pipeline de automatización
**[VIGENTE]** — feature `cron-automation.md`.

- 8 jobs programados en UTC con política canónica de idempotencia, lock distribuido y fire-and-forget.

### 3.11 Miembro del mes
**[VIGENTE]** — feature `member-of-month.md`.

- reconocimiento mensual automático por sección con cron dedicado.

### 3.12 Múltiples clientes
**[VIGENTE]** — canon `arquitectura-sacdia.md`, `runtime-sacdia.md`.

- backend REST + panel admin web (Next.js) + app móvil (Flutter).
- arquitectura consolidada; sin microservicios ni fragmentación innecesaria.

---

## 4. Capacidades PARCIALES (comunicar con matiz)

### 4.1 Resiliencia de red
**[PARCIAL]** — cache local + invalidación FCM en móvil; React Query con staleTime en admin. **No es offline-first** (canon `runtime-resiliencia-red.md` §4).

### 4.2 Cobertura de invalidación en tiempo real
**[PARCIAL]** — hoy `activities` solamente. Resto de features no registrados en el registry.

### 4.3 Internacionalización
**[PARCIAL]** — 2 locales parciales en admin (`es-MX`, `es-ES`); base `intl` en Flutter sin catálogo activo. No es trilingüe (ver `docs/plans/i18n-multilenguaje-roadmap.md`).

---

## 5. Hipótesis estratégicas (no comunicar como hecho)

### 5.1 Ventaja de trayectoria vs SGC
**[HIPÓTESIS]** — SACDIA modela trayectoria institucional completa del miembro. SGC históricamente se orienta a registro operativo.

Sostenible como diferencial **siempre que** se comunique como hipótesis de valor, no como afirmación absoluta.

### 5.2 Ventaja de validación institucional
**[HIPÓTESIS]** — SACDIA separa registrar, revisar y validar; sostiene pipelines multietapa con historial.

### 5.3 Ventaja de continuidad digital
**[HIPÓTESIS]** — SACDIA preserva historial completo en lugar de vistas del estado actual (`decisiones-clave.md` — tensión "historial completo versus vistas del estado actual").

---

## 6. Líneas futuras (no vigentes)

Estas capacidades se describen en `docs/plans/`:

- **offline-first transversal** — `docs/plans/offline-first-roadmap.md`;
- **multilenguaje (pt-BR, en)** — `docs/plans/i18n-multilenguaje-roadmap.md`;
- **IA, QR, tarjetas virtuales** — `docs/plans/ia-qr-tarjetas-virtuales.md`;
- **expansión de reportes (trimestrales, anuales, dashboards de jobs)** — `docs/plans/reportes-expansion.md`.

Comunicar como roadmap. No como capacidad actual.

---

## 7. Regla editorial del posicionamiento

1. **No afirmar ventaja sin evidencia verificable** — cada claim debe rastrearse a canon o features.
2. **No generalizar cobertura parcial** — "acotado a activities" no es "transversal".
3. **No tratar roadmap como presente** — líneas futuras van siempre con etiqueta explícita.
4. **No inflar comparación con SGC** — la superioridad se demuestra en capacidades concretas, no en afirmaciones absolutas.
5. **Canon manda sobre marketing** — si este documento contradice `docs/canon/`, gana el canon y este documento debe actualizarse.

---

## 8. Versión y mantenimiento

Este documento debe revisarse cada vez que:

- una nueva decisión se agrega a `docs/canon/decisiones-clave.md`;
- un nuevo canon `runtime-*.md` entra en `docs/canon/`;
- una capacidad PARCIAL pasa a VIGENTE o viceversa;
- una línea ROADMAP entra en producción.

Última revisión: 2026-04-22 (creación inicial tras ola de canonización P1-P2).
