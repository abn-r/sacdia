# SACDIA — Bases del Proyecto  
## Versión normalizada para análisis contra canon e implementación

### Propósito del documento
Este documento presenta la visión base de SACDIA, su posicionamiento frente a soluciones existentes del ecosistema y una síntesis de capacidades actuales, capacidades parciales y líneas de evolución futura.

> **Regla de lectura**
> - **[VIGENTE]**: respaldado por canon y/o implementación verificada
> - **[PARCIAL]**: existe de forma parcial o no está canonizado transversalmente
> - **[ROADMAP]**: visión futura, no capacidad vigente consolidada
> - **[ESTRATÉGICO]**: útil para posicionamiento, no describe por sí solo estado operativo
> - **[NO RESPALDADO]**: no debe usarse como claim operativo sin verificación adicional

---

## 1. Visión general

**[ESTRATÉGICO]**  
SACDIA se concibe como una plataforma institucional orientada a acompañar la trayectoria completa de miembros, líderes, secciones y clubes dentro del ecosistema DIA. No se limita a resolver una necesidad administrativa puntual, sino que busca integrar operación, seguimiento, validación, trazabilidad y soporte a la toma de decisiones.

**[ESTRATÉGICO]**  
Frente a herramientas tradicionales como SGC, SACDIA propone una experiencia más integrada, con mejor articulación entre operación local, seguimiento institucional, validación de procesos y evolución digital del club.

---

## 2. Diferencia conceptual frente a soluciones existentes

**[ESTRATÉGICO]**  
Mientras otras soluciones tienden a concentrarse en registro operativo o control administrativo, SACDIA apunta a consolidar una visión institucional más amplia:

- trayectoria unificada del miembro
- relación estructurada entre club y secciones
- trazabilidad documental y validación formal
- mayor capacidad de evolución digital en múltiples clientes
- posibilidad de crecer hacia mejores capacidades de seguimiento, reportes y analítica

**[ESTRATÉGICO]**  
Esta comparación debe leerse como marco de posicionamiento, no como inventario funcional cerrado ni como afirmación automática de superioridad en todas las áreas.

---

## 3. Modelo institucional de SACDIA

**[VIGENTE]**  
SACDIA modela al **club** como entidad raíz de gestión y a las **secciones/unidades** como espacios operativos donde se registra y organiza buena parte de la actividad institucional.

**[VIGENTE]**  
La plataforma busca sostener una **trayectoria única del miembro**, integrando datos administrativos, participación, progresión y evidencias relevantes dentro de un mismo sistema.

**[VIGENTE]**  
La lógica del sistema contempla que el registro de actividades o hitos institucionales no equivale automáticamente a su validación final. Existen flujos donde la verificación y aprobación institucional son parte central del modelo.

---

## 4. Arquitectura funcional del sistema

**[VIGENTE]**  
SACDIA opera como un sistema con:
- backend principal
- panel administrativo web
- aplicación móvil
- persistencia centralizada de datos
- documentación funcional y técnica asociada

**[VIGENTE]**  
La comunicación principal se entiende bajo una arquitectura de **backend REST + múltiples clientes**.

> Se elimina cualquier referencia a “microservicios”, ya que no corresponde al canon vigente verificado.

---

## 5. Capacidades actualmente respaldadas

### 5.1 Trayectoria y operación institucional
**[VIGENTE]**  
SACDIA ya expresa una visión institucional orientada a centralizar la información relevante de miembros, secciones y clubes, con foco en seguimiento y consistencia operativa. La trayectoria única del miembro es el eje semántico del sistema (ver `docs/canon/dominio-sacdia.md` y `docs/canon/decisiones-clave.md` §1).

### 5.2 Validación institucional
**[VIGENTE]**  
Los flujos de validación forman parte real del sistema en dominios donde la aprobación institucional y la trazabilidad son necesarias. Canon rector: `docs/canon/decisiones-clave.md` §6 (registrar y validar son actos distintos).

### 5.3 Carpeta de evidencias
**[VIGENTE]**  
La **carpeta de evidencias** es capacidad vigente del sistema, sostenida tanto desde documentación funcional (`docs/features/carpetas-evidencias.md`, `docs/features/annual-folders-scoring.md`, `docs/features/validacion-evidencias.md`) como desde implementación backend (módulos `annual-folders`, `folders`, `evidence-review`), admin (`/dashboard/evidence-review`) y app móvil (`features/evidence_folder/`).

### 5.4 Autenticación institucional
**[VIGENTE]**  
SACDIA opera con **Better Auth self-hosted** (HS256 JWT + OAuth Google/Apple) integrado en el backend NestJS, con un modelo de autorización contextual (RBAC por rol global + asignaciones de club). Canon: `docs/canon/auth/`.

### 5.5 Comunicaciones institucionales
**[VIGENTE]**  
El sistema cuenta con un subsistema completo de comunicaciones visibles (push FCM + bandeja persistente + preferencias opt-out por categoría) que cubre envío directo, broadcast, envío por sección de club, envío por rol de sección y envío por rol global. Canon rector: `docs/canon/runtime-communications.md`.

### 5.6 Invalidación en tiempo real
**[VIGENTE]**  
Adicional a las notificaciones visibles, el sistema emite **FCM silent messages** para invalidación de cache en clientes, permitiendo consistencia eventual entre sesiones activas. Canon rector: `docs/canon/runtime-resiliencia-red.md`.

**[PARCIAL]**  
Cobertura actual acotada a un recurso (activities); ampliar cobertura por feature es gap abierto.

### 5.7 Clasificación institucional de clubes
**[VIGENTE]**  
Existe un subsistema de **ranking anual de clubes** con categorías de premio configurables, pipeline automático de recálculo (cron diario 02:00 UTC con lock distribuido) y superficie admin dedicada. Canon rector: `docs/canon/runtime-rankings.md`.

### 5.8 Sistema de logros y tiers del miembro
**[VIGENTE]**  
SACDIA cuenta con un sistema de **achievements con cinco tiers institucionales** (Bronze → Diamond), evaluación por eventos vía cola BullMQ con journal persistente y emisores activos en cinco features del runtime. Canon rector: `docs/canon/runtime-achievements.md`.

### 5.9 Analíticas operacionales (SLA dashboard)
**[VIGENTE]**  
Existe un dashboard de métricas operacionales para coordinadores y administradores que cubre tres pipelines (investiduras, validación, camporees) con ventanas temporales canonizadas (30d overdue, 90d approval rate, 12w throughput). Canon rector: `docs/canon/runtime-sla-dashboard.md`.

### 5.10 Miembro del mes
**[VIGENTE]**  
Reconocimiento mensual automático por sección de club con pipeline cron dedicado. Doc operativa: `docs/features/member-of-month.md`.

### 5.11 Reportes automáticos
**[VIGENTE]**  
Existen **ocho jobs programados** en el backend que cubren automatización recurrente: generación de reportes mensuales, cierre financiero mensual, recálculo de rankings anuales, evaluación de miembro del mes, recordatorios de actividades, expiración de solicitudes de membresía, cleanup de sesiones/tokens y limpieza de exportes vencidos. Doc operativa: `docs/features/cron-automation.md`.

**[PARCIAL]**  
Algunos jobs están en dark launch (ej. `reports.auto_generate_enabled` default `false`). No debe generalizarse como "sistema universal de reportes automáticos para todos los dominios"; la cobertura es acotada, documentada y gobernable por feature flag.

### 5.12 Pipeline de automatización
**[VIGENTE]**  
El backend usa `ScheduleModule` de NestJS con política canónica de idempotencia, locks distribuidos, fire-and-forget, batching con timeout propio y timezone UTC consistente para los ocho jobs. Ver `docs/features/cron-automation.md`.

---

## 6. Capacidades parcialmente presentes

### 6.1 Cache local + invalidación en tiempo real
**[VIGENTE]**  
SACDIA implementa en la app móvil una capa de **cache local con TTL** (`SharedPreferences`, `flutter_cache_manager`) combinada con **invalidación en tiempo real vía FCM silent messages** (`RealtimeInvalidationHandler`). Esto provee resiliencia frente a conectividad intermitente y consistencia eventual entre clientes.

**[PARCIAL]**  
La cobertura de invalidación por feature no está auditada transversalmente y no todas las features usan cache uniformemente. El canon operativo vive en `docs/canon/runtime-resiliencia-red.md`.

**[ROADMAP]**  
Una experiencia **offline-first** real (queue persistida de mutaciones, sincronización diferida con reconciliación de conflictos) **no existe hoy** y debe tratarse como línea futura. No describir la capacidad actual como "offline" sin matizar — es cache + invalidación, no offline-first.

### 6.2 Clasificación y ranking
**[PARCIAL]**  
SACDIA ya muestra bases para lógica de clasificación/ranking mediante categorías configurables y estructuras relacionadas con puntajes o niveles en algunos dominios.

**[PARCIAL]**  
También existen niveles tipo Bronce/Plata/Oro/Platino/Diamante en ciertos contextos específicos.

**[PARCIAL]**  
Sin embargo, no debe afirmarse todavía como una **clasificación institucional única y cerrada** aplicable a todo el sistema sin mayor verificación.

---

## 7. Capacidades de valor estratégico

### 7.1 Posicionamiento frente a SGC
**[ESTRATÉGICO]**  
Uno de los aportes más valiosos de SACDIA es la posibilidad de articular mejor operación, trazabilidad, validación y evolución digital en una misma plataforma institucional.

### 7.2 Ventajas percibidas
**[ESTRATÉGICO]**  
Como hipótesis de valor, SACDIA puede comunicar ventajas en:
- trazabilidad más rica
- mayor integración entre clientes
- mejor continuidad del historial institucional
- mejor base para crecimiento hacia analítica y automatización

> Estas ventajas deben sostenerse con evidencia o presentarse explícitamente como hipótesis estratégicas, no como hechos absolutos.

---

## 8. Capacidades futuras y evolución

### 8.1 Trilingüe
**[ROADMAP]**  
La expansión multilenguaje debe tratarse como línea futura de evolución.  
No corresponde describirla como capacidad vigente consolidada del sistema actual.

### 8.2 Offline transversal
**[ROADMAP]**  
La consolidación de una experiencia offline más amplia, consistente y documentada puede formar parte de una evolución futura del producto.

### 8.3 Expansión de reportes
**[ROADMAP]**  
La automatización de reportes podría ampliarse a nuevos dominios, con mayor cobertura y dashboards más accionables.

### 8.4 Clasificación institucional ampliada
**[ROADMAP]**  
La evolución hacia un modelo más visible y uniforme de clasificación institucional puede evaluarse como línea futura, siempre que se defina su alcance funcional y su valor real para clubes, secciones y liderazgo.

### 8.5 IA, QR y otras capacidades diferenciales
**[ROADMAP]**  
Capacidades como asistentes inteligentes, tarjetas virtuales con QR, automatizaciones avanzadas o inteligencia aplicada deben tratarse como líneas de evolución estratégica y no como funcionalidades actuales verificadas.

---

## 9. Criterio sobre módulos y cobertura funcional

**[ESTRATÉGICO]**  
Este documento no debe usar conteos de módulos como fuente de verdad operativa.  
La evaluación de cobertura funcional debe hacerse contra:
- canon documental
- documentación por feature
- endpoints disponibles
- implementación real en backend, admin y app

---

## 10. Conclusión editorial de la base

**[ESTRATÉGICO]**  
SACDIA puede presentarse como una plataforma institucional con una propuesta sólida de integración, trazabilidad y evolución digital frente a alternativas más limitadas en alcance o continuidad operativa.

**[VIGENTE]**  
Esa propuesta ya tiene soporte real en varias capacidades del sistema.

**[PARCIAL]**  
Otras líneas muestran avance parcial y deben comunicarse con precisión para no sobredescribir el estado actual.

**[ROADMAP]**  
Las capacidades todavía no consolidadas deben moverse explícitamente a roadmap o planificación.

---

## Apéndice — reglas para la siguiente fase de análisis

La siguiente fase debe contrastar este documento normalizado contra:
- `docs/canon/`
- `docs/features/`
- `docs/api/`
- `docs/database/`
- `sacdia-backend/`
- `sacdia-admin/`
- `sacdia-app/`

Y responder, con evidencia:
- qué partes están confirmadas
- qué partes son parciales
- qué partes no están respaldadas
- qué gaps existen entre implementación y documentación
- qué debe vivir en canon, estrategia o roadmap
