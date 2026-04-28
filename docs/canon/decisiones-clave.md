# Decisiones clave

## Estado

ACTIVE
<!-- VERIFICADO contra código 2026-03-14: las 9 decisiones revisadas contra Reality Matrix. Todas siguen vigentes. -->

## Propósito

Este documento conserva las decisiones estructurales que afectan de forma duradera la interpretación, organización o evolución de SACDIA. Su función es preservar memoria útil, evitar rediscusiones sin contexto y explicar por qué ciertas elecciones quedaron fijadas en el nuevo canon.

Este documento justifica decisiones. No reemplaza a `docs/canon/dominio-sacdia.md`, `docs/canon/identidad-sacdia.md`, `docs/canon/gobernanza-canon.md`, `docs/canon/arquitectura-sacdia.md` ni `docs/canon/runtime-sacdia.md`.

## Criterio de inclusión

Solo deben entrar decisiones que cumplan al menos una de estas condiciones:

- fijan un concepto estructural del dominio;
- condicionan arquitectura, autorización, trazabilidad o persistencia;
- afectan más de un módulo o más de una capa del sistema;
- tienen costo alto de revertir;
- explican una restricción fuerte del sistema actual.

No deben entrar decisiones menores de implementación, notas de sesión, bugs tácticos o cronologías sin valor estructural.

## Decisiones vigentes

### 1. La trayectoria institucional es el eje del sistema

**Estado**: Vigente <!-- VERIFICADO: enrollments + users_classes + classes implementados y ALINEADO -->

**Contexto**: La documentación previa tendía a describir SACDIA como un sistema de gestión o catálogo administrativo. Esa lectura debilitaba el valor principal del producto y fragmentaba la semántica del dominio.

**Decisión**: El nuevo canon fija la trayectoria institucional del miembro como eje semántico del sistema.

**Consecuencias**:

- el valor principal del sistema no se interpreta desde CRUDs o pantallas, sino desde continuidad, contexto y reconocimiento institucional;
- procesos, secciones, validaciones y reportes deben leerse como soporte de trayectoria;
- identidad, arquitectura y runtime quedan subordinados a este eje.

### 2. Club y sección de club se modelan como entidades distintas

**Estado**: Vigente <!-- VERIFICADO: clubs + club_sections implementados (consolidado 2026-03-17) -->

**Contexto**: La documentación y el runtime actual distinguían de manera parcial entre club y `instance`, pero sin una formulación canónica estable. Eso generaba ruido entre raíz institucional y unidad operativa.

**Decisión**: El canon fija al `Club` como entidad institucional raíz y a la `Sección de club` como unidad operativa real.

**Consecuencias**:

- la operación concreta se interpreta principalmente desde la sección;
- la agregación e identidad institucional se interpretan desde el club;
- se evita colapsar tipo, instancia y club en una sola idea ambigua.

### 3. Tipo de club clasifica, pero no opera por sí solo

**Estado**: Vigente <!-- VERIFICADO: club_types es catálogo, operación vía instances -->

**Contexto**: Parte de la documentación heredada trataba el tipo de club como si fuera casi equivalente a la unidad operativa.

**Decisión**: El `Tipo de club` queda definido como clasificación institucional y formativa. La unidad operativa es la `Sección de club`.

**Consecuencias**:

- el dominio separa clasificación de operación;
- el lenguaje canónico evita usar tipo de club como sustituto de sección;
- la interpretación del runtime actual requiere mapeo explícito.

### 4. La pertenencia se interpreta mediante vinculación contextual

**Estado**: Vigente <!-- VERIFICADO: club_role_assignments con año eclesiástico, active_assignment en users_pr -->

**Contexto**: La pertenencia plana al club no soporta bien historial, simultaneidad de roles, cambios de etapa ni lectura contextual del miembro.

**Decisión**: La participación institucional de una persona se interpreta mediante `Vinculación institucional` en contexto y tiempo.

**Consecuencias**:

- la pertenencia deja de leerse como atributo plano;
- trayectoria, liderazgo, apoyo y formación pueden diferenciarse con más claridad;
- el runtime actual requiere leerse con cuidado cuando mezcla participación y asignación de roles.

### 5. Sección de club es el término canónico; instancia queda relegado al runtime

**Estado**: Vigente <!-- VERIFICADO: código usa "club_sections" desde consolidación 2026-03-17. Naming canónico y técnico ahora alineados. -->

**Contexto**: El sistema actual usa `instance` y tablas separadas por tipo. Ese naming es útil técnicamente, pero no es el mejor lenguaje para el dominio.

**Decisión**: El canon adopta `Sección de club` como término rector y deja `instance` como representación técnica de runtime.

**Consecuencias**:

- la documentación canónica gana claridad humana y semántica;
- el runtime actual debe mapearse al canon en lugar de imponer su naming;
- cualquier futura convergencia técnica de nombres debe partir de esta decisión.

### 6. Registrar y validar son actos distintos

**Estado**: Vigente <!-- VERIFICADO: runtime de investiduras activo con pipeline, historial, config CRUD y compat legacy -->

**Contexto**: El flujo de investidura y otros procesos muestran que existe una diferencia real entre captura operativa y reconocimiento institucional.

**Decisión**: El canon separa de forma explícita registro, revisión y validación.

**Consecuencias**:

- el sistema puede representar estados intermedios sin mentir;
- no se trata como verdad institucional final algo que solo fue capturado;
- runtime, reportes y UI deben respetar esta separación; la superficie activa de investiduras ya aplica esta distinción.

### 7. El canon se reconstruye desde conceptos, no desde plantillas ni parches

**Estado**: Vigente

**Contexto**: La documentación anterior acumuló referencias cruzadas, material genérico, capas parciales y rutas que competían por autoridad.

**Decisión**: El nuevo canon se construye desde modelo del dominio, identidad, gobernanza, arquitectura, runtime y decisiones clave, evitando seguir parchando la estructura anterior como si ya fuera suficiente.

**Consecuencias**:

- la reescritura documental se ordena por fundamento conceptual y no por carpeta heredada;
- lo nuevo absorbe verdad y lo viejo conserva contexto;
- la migración deja de ser acumulación de archivos y pasa a ser corte de autoridad.

### 8. El modelo del dominio es el primer documento rector del nuevo canon

**Estado**: Vigente

**Contexto**: Si identidad, arquitectura o runtime se escriben antes de fijar el lenguaje del negocio, el sistema vuelve a dispersar semántica.

**Decisión**: El primer documento rector del nuevo canon es `docs/canon/dominio-sacdia.md`.

**Consecuencias**:

- identidad, gobernanza, arquitectura y runtime se derivan del dominio;
- el vocabulario canónico queda fijado antes de organizar el resto del sistema documental;
- se reduce el riesgo de volver a escribir documentación bonita pero conceptualmente floja.

### 9. La verdad formativa se separa entre ciclo anual y trayectoria consolidada

**Estado**: Vigente <!-- VERIFICADO: enrollments = ciclo anual, users_classes = trayectoria consolidada. Backend implementa ambos con FS-02/FS-03 -->

**Contexto**: El sistema actual usa `users_classes` y `enrollments` con semánticas parcialmente superpuestas. La intención original distingue dos planos válidos: trayectoria histórica por clase y cursado anual dentro de un año eclesiástico. El problema actual no es la existencia de ambas estructuras, sino la falta de una frontera de autoridad clara en runtime.

**Decisión**: El canon adopta un modelo de responsabilidad dividida:

- `enrollments` es la fuente de verdad del ciclo anual operativo de una clase, incluyendo inscripción, progreso, validación e investidura del periodo;
- `users_classes` es la fuente de verdad de la trayectoria consolidada por clase del miembro a lo largo del tiempo.

**Consecuencias**:

- `users_classes` no debe seguir tratándose como fuente operativa primaria del ciclo actual;
- post-registro, clases, admin y certificaciones deben alinearse con esta frontera;
- cuando un ciclo anual llegue a un estado consolidado, su resultado debe proyectarse o sincronizarse hacia `users_classes`;
- mientras esta frontera no esté implementada de forma consistente, el runtime canónico debe seguir tratándose con cautela.

### 10. Consolidación de secciones de club en tabla única (2026-03-17)

**Estado**: Vigente

**Contexto**: Las secciones de club estaban representadas por 3 tablas idénticas (`club_adventurers`, `club_pathfinders`, `club_master_guilds`) que violaban DRY y forzaban switch/case patterns en todo el stack. 10 tablas dependientes usaban 3 FK nullables (`club_adv_id`, `club_pathf_id`, `club_mg_id`) con un CHECK constraint de exclusividad mutua en vez de 1 FK directa. Agregar un nuevo tipo de club requería cambios de schema, no solo un INSERT en el catálogo.

**Decisión**: Consolidar las 3 tablas en una sola tabla `club_sections` con `club_type_id` como discriminador y constraint `UNIQUE(main_club_id, club_type_id)`.

**Consecuencias**:

- SQL: 1 tabla `club_sections` reemplaza 3 tablas idénticas; 10 tablas dependientes usan `club_section_id` (FK directa) en vez de 3 FK nullables;
- Backend: switch/if eliminados, queries parametrizados por `club_section_id`;
- Admin: API URLs `/clubs/:id/sections/:sectionId` (sin `:type` param);
- App: `ClubSection` entity, `sectionId` en vez de `instanceType` + `instanceId`;
- Permisos: `club_instances:*` renombrado a `club_sections:*`;
- el naming técnico converge con el naming canónico de Decisión 5.

### 11. Achievements y sistema de tiers son canon operativo (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: enums achievement_tier/type/scope, BullMQ queue "achievements", journal achievement_event_log, 5 emisores de eventos activos. Canonizado en docs/canon/runtime-achievements.md. -->

**Contexto**: El sistema de achievements existía en backend, admin, app y base de datos, pero `docs/features/achievements.md:3` declaraba explícitamente `NO CANON`. Eso dejaba sin autoridad canónica una feature operativa con 5 tiers institucionales (Bronze → Diamond), cola BullMQ dedicada, journal de eventos y emisores en 5 features del runtime.

**Decisión**: El canon adopta achievements como capa operativa canónica. La autoridad rectora es `docs/canon/runtime-achievements.md`. Se fija que el tier es atributo estático del achievement, el journal (`achievement_event_log`) es fuente de verdad del evento, y la cola BullMQ es solo el mecanismo de evaluación (no la fuente de verdad).

**Consecuencias**:

- el sistema de tiers Bronze→Diamond queda con respaldo canónico y auditable;
- los emisores de eventos (activities, honors, camporees, investiture, evidence-review) deben seguir el patrón "persistir → intentar enqueue → no lanzar en fallo";
- la caída de BullMQ no puede propagarse como error al feature emisor;
- `docs/features/achievements.md` deja de declararse `NO CANON`.

### 12. Rankings institucionales y award categories son canon operativo (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: schema club_annual_rankings + award_categories, rankings.service.ts con cron diario 02:00 UTC, dense ranking, sentinel UUID. Canonizado en docs/canon/runtime-rankings.md. -->

**Contexto**: La clasificación anual de clubes existía implementada (cron diario, endpoints, admin UI) pero no tenía respaldo canónico. Eso dejaba la política institucional de desempate, el sentinel UUID para ranking general y la interacción con carpetas cerradas fuera del canon.

**Decisión**: El canon adopta los rankings institucionales como subsistema distinto del sistema de tiers de achievements. La autoridad rectora es `docs/canon/runtime-rankings.md`. Se fija dense ranking como única semántica permitida, el sentinel `00000000-0000-0000-0000-000000000000` como token de ausencia de categoría, y el lock distribuido por año como mecanismo de concurrencia entre cron y recálculo manual.

**Consecuencias**:

- la clasificación deja de leerse como afán de producto y pasa a ser política institucional trazable;
- carpetas en estado `closed` participan en ranking pero no admiten reopen de secciones;
- categorías con `club_type_id = null` son universales; categorías con `club_type_id = X` son específicas de tipo;
- cualquier recálculo debe respetar el lock distribuido para evitar inconsistencias.

### 13. SACDIA no es offline-first; es cache + invalidación (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: ausencia de hive/sqflite/drift/isar y de endpoints /sync; presencia de RealtimeInvalidationHandler + React Query + FCM silent messages. Canonizado en docs/canon/runtime-resiliencia-red.md. -->

**Contexto**: Material estratégico anterior y el documento base describían "offline selectivo" como capacidad parcial. La implementación real **no es offline-first**: no hay queue persistida de mutaciones, no hay sincronización diferida, no hay endpoints delta. Lo que sí existe es cache local + TTL + invalidación por FCM silent messages en móvil, y React Query con staleTime + invalidación manual en admin.

**Decisión**: El canon adopta la estrategia vigente como **cache + invalidación**, explícitamente distinta de offline-first. La autoridad rectora es `docs/canon/runtime-resiliencia-red.md`. El feature flag `realtimeInvalidationEnabled` (default `false`) es el único interruptor canónico para habilitar el pipeline de invalidación en móvil.

**Consecuencias**:

- ninguna comunicación oficial puede afirmar que SACDIA es offline-first mientras este canon esté vigente;
- la emisión de `cache_invalidate` no debe crear `notification_logs` ni `notification_deliveries`;
- la cobertura de invalidación por FCM hoy está acotada a `activities`; extender a otros features requiere registro explícito en `RealtimeResourceRegistry` del cliente y cableado en el servicio backend correspondiente;
- la evolución hacia offline-first transversal corresponde a `docs/plans/offline-first-roadmap.md` (aún no creado).

### 14. Comunicaciones visibles son canon operativo (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: NotificationsService con 7 métodos públicos, BullMQ queue "notifications" con retry 3x exponential, notification_logs + notification_deliveries + notification_preferences + user_fcm_tokens en schema, 6 features emisores activos. Canonizado en docs/canon/runtime-communications.md. -->

**Contexto**: El subsistema de notificaciones push + bandeja existía completo (backend, admin UI, app móvil con inbox) pero sin respaldo canónico. Eso dejaba sin autoridad política decisiones estructurales: persistencia dual (logs auditoría + deliveries bandeja), opt-out que suprime push e inbox, ciclo de vida de tokens FCM, retry policy BullMQ, distinción entre push visibles y silent messages (cache invalidation), y convención del tag `source` para trazabilidad.

**Decisión**: El canon adopta las comunicaciones visibles como capa operativa canónica distinta del subsistema de invalidación por FCM silent. La autoridad rectora es `docs/canon/runtime-communications.md`. Se fija que:

- el contrato de entrega crea `notification_log` + `notification_deliveries` antes de intentar push FCM, garantizando bandeja incluso sin tokens activos;
- el opt-out por categoría suprime **tanto push como bandeja** — no hay override de inbox;
- los tokens FCM con error permanente se desactivan automáticamente y son purgados por `CleanupService` cada 6 horas;
- el fallo de transporte no puede propagarse al feature emisor (patrón fire-and-forget obligatorio);
- cada envío debe declarar un `source` trazable (`admin:*`, `camporees:*`, `achievements:*`, etc.);
- el path silent (cache invalidation) comparte cola pero no crea log/delivery — queda gobernado por `docs/canon/runtime-resiliencia-red.md`.

**Consecuencias**:

- cualquier feature nuevo que emita notificaciones debe usar `NotificationsService` con el método correspondiente al alcance (`sendToUser`, `broadcast`, `sendToClubMembers`, `sendToSectionRole`, `sendToGlobalRole`, `notifySafe`);
- admin UI debe alinearse con los endpoints canónicos (pendiente: formulario de envío por club todavía cableado a ruta legacy según `docs/features/communications.md:45`);
- la bandeja respeta opt-out; no debe construirse lógica que fuerce entregas en bandeja a usuarios opted-out;
- toda nueva categoría de notificación debe crearse con convención `source = '<feature>:<evento>'` y documentarse.

### 15. SLA dashboard es lector puro sobre datos operacionales (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: AnalyticsModule independiente, endpoint único GET /api/v1/admin/analytics/sla-dashboard, cache in-memory TTL 60s, cobertura 3 pipelines, admin-only. Canonizado en docs/canon/runtime-sla-dashboard.md. -->

**Contexto**: Existía una capa de analíticas operacionales completa (`AnalyticsModule` + página admin) sin respaldo canónico. Eso dejaba sin autoridad política decisiones estructurales: módulo independiente para evitar acoplamiento inverso con pipelines operacionales, cache in-memory en lugar de Redis, ventanas temporales fijas (30d/90d/12w), scope derivado del JWT en lugar de query params, y ausencia deliberada de tablas `sla_*` dedicadas.

**Decisión**: El canon adopta el SLA dashboard como **lector puro** de datos operacionales existentes. La autoridad rectora es `docs/canon/runtime-sla-dashboard.md`. Se fija que:

- el subsistema vive en `AnalyticsModule`, separado de los módulos operacionales que observa (investiture, validation, camporees);
- el endpoint único `GET /api/v1/admin/analytics/sla-dashboard` agrega todas las métricas para evitar múltiples round-trips;
- el cache es in-memory con TTL 60s; migrar a Redis requeriría justificación explícita de beneficio;
- el scope del coordinador se deriva del JWT (`local_field_id` de su asignación activa), nunca de query params;
- las ventanas temporales canonizadas son: 30 días para overdue, 90 días para approval rate, 12 semanas para throughput;
- ninguna métrica puede calcularse a partir de tablas `sla_*` dedicadas; el subsistema permanece como lector puro;
- roles admitidos: solo `admin` y `coordinator`.

**Consecuencias**:

- nuevas métricas operacionales similares deben evaluarse para incorporarse al endpoint existente antes de crear superficies paralelas;
- si se requiere drill-down desde una métrica a los items individuales, esa superficie debe vivir en el módulo operacional correspondiente, no en `AnalyticsModule`;
- si en el futuro se canonizan alertas sobre umbrales del SLA (gap actual), la emisión debe seguir `docs/canon/runtime-communications.md` con `source = 'analytics:sla:*'`;
- mover el cache a Redis rompe este canon — cualquier cambio arquitectural debe actualizar la decisión.

### 16. Miembro del mes es dominio canónico propio (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: member-of-month.service.ts con runEvaluation idempotente, schema con empates permitidos, cron mensual, notificaciones a ganador + directores, superficie admin multi-sección. Canonizado en docs/canon/runtime-member-of-month.md. -->

**Contexto**: El subsistema de Miembro del Mes (MoM) existía completo (backend, cron mensual, evaluación manual, notificaciones, admin UI multi-sección) pero sin respaldo canónico propio. Los permisos reutilizaban `units:read` / `units:update` mezclando concerns: gestión de unidades vs reconocimiento mensual institucional. El modelo de datos es intencionalmente plano, sin `evaluated_by`/`evaluated_at`/`manual`, y las empates son ganadores múltiples válidos — estas decisiones no estaban registradas explícitamente.

**Decisión**: El canon adopta MoM como subsistema operativo propio, conceptualmente distinto de `achievements` (tiers individuales por evento), `rankings` (clasificación anual de clubes) y `weekly-records` (scoring semanal fuente). La autoridad rectora es `docs/canon/runtime-member-of-month.md`. Se fija que:

- la evaluación (automática o manual) es idempotente: borra e reinserta ganadores del periodo `(club_section_id, month, year)`;
- los empates en `total_points` producen múltiples ganadores legítimos por periodo; ninguna regla debe forzar desempate;
- el scoring fuente es `weekly_record_scores`; MoM es lector puro (no muta scoring);
- la notificación al ganador + directores de la sección es parte integral del acto institucional;
- la supervisión admin multi-sección usa scope derivado via `AuthorizationContextService` (patrón canon ya establecido para SLA dashboard y monthly-reports admin);
- los permisos vigentes son `mom:read` / `mom:evaluate` / `mom:supervise` (migración completada 2026-04-22 con cambio duro — el seed otorga `mom:*` a todos los roles que tenían `units:*` antes del switch de handlers, garantizando continuidad sin compat window).

**Consecuencias**:

- cualquier cambio en la fórmula de agregación de `weekly_record_scores` (categorías, caps, factores) impacta directamente MoM y debe coordinarse con este canon;
- la migración de permisos requiere agregar las constantes nuevas en backend + admin, cablear enforcement en los handlers, y mantener compatibilidad con `units:*` durante la transición — al cerrar, actualizar este canon + `docs/canon/runtime-member-of-month.md` §7 y §8;
- nuevos endpoints o superficies de MoM deben usar `source = 'member-of-month:*'` al emitir notificaciones, alineados con `docs/canon/runtime-communications.md`;
- ninguna herramienta externa puede crear reconocimientos MoM bypassing `runEvaluation` — el pipeline es la única fuente canónica del acto institucional.

### 17. Scoring categories es dominio canónico propio (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: scoring-categories.controller.ts con 12 handlers, jerarquía division/union/local-field, permisos propios scoring_categories:read/manage. Canonizado en docs/canon/runtime-scoring-categories.md. -->

**Contexto**: El subsistema `scoring-categories` (catálogo jerárquico de categorías de puntuación) existía con 12 endpoints en backend pero reutilizaba permisos `units:read`/`units:update` para lectura y gestión. Además los 4 handlers de nivel `division` (L46-87 del controller) carecían de `@RequirePermissions` — gap de seguridad identificado en auditoría. Los permisos reutilizados mezclaban concerns (gestión de unidades operativas vs configuración de catálogo de puntuación) y dificultaban auditoría RBAC.

**Decisión**: El canon adopta `scoring-categories` como dominio operativo propio con permisos propios `scoring_categories:read` / `scoring_categories:manage`. La autoridad rectora es `docs/canon/runtime-scoring-categories.md`. Se fija que:

- el subsistema es puramente de **configuración** — los datos operativos de scoring viven en `weekly_record_scores` y otros features consumidores (weekly-records, MoM, annual-folders-scoring);
- la jerarquía `division → union → local-field` se preserva con herencia automática (categorías de niveles superiores se aplican a niveles inferiores sin duplicación en datos);
- los 4 endpoints `division` mantienen `@GlobalRolesGuard + @GlobalRoles('admin','super_admin')` ADEMÁS del permiso, porque son configuración global reservada;
- la migración es cambio duro (sin compat window) porque el seed otorga `scoring_categories:*` a todos los roles que tenían `units:*` antes del switch de handlers — continuidad garantizada.

**Consecuencias**:

- la configuración de scoring queda desacoplada de la gestión de unidades a nivel permiso;
- cualquier feature consumidor (weekly-records, MoM, rankings) no muta categorías — solo lee;
- nuevos niveles jerárquicos (si se agregaran) deben cablear con `scoring_categories:*`, no inventar subdominios paralelos;
- el fix del gap L46-87 (division handlers sin `@RequirePermissions`) queda documentado como invariante — nunca pueden quedar endpoints sin permiso explícito en este módulo.

### 18. Requests es dominio canónico propio (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: requests.controller.ts con 8 handlers migrados, permisos propios requests:read/review, grants alineados con patrón MoM y scoring-categories. Canonizado en docs/canon/runtime-requests.md. -->

**Contexto**: El subsistema `requests` (transferencias de miembros + asignaciones de rol) existía con 8 endpoints en backend pero reutilizaba permisos `clubs:read`, `club_roles:read`, `club_roles:assign` para gatear acciones propias del workflow de solicitudes. Esta reutilización mezclaba concerns (gestión de clubs y asignación directa vs workflow de aprobación), dificultaba auditoría RBAC y creaba escaladas indirectas: quien tenía `club_roles:assign` recibía también acceso al workflow de solicitudes sin haberlo solicitado.

Hallazgo paralelo: la ruta admin `/dashboard/requests/membership` apuntaba al módulo `membership-requests` (distinto de `requests`) con permiso `club_members:approve`. Drift detectado y revertido — `membership-requests` es dominio separado con su propio permiso; agruparlo bajo nav admin no justifica unificación de permisos.

**Decisión**: El canon adopta `requests` como dominio operativo propio con permisos propios `requests:read` / `requests:review`. La autoridad rectora es `docs/canon/runtime-requests.md`. Se fija que:

- `requests:read` cubre todas las lecturas + creación de solicitudes de transferencia (acción accesible a contextos institucionales amplios);
- `requests:review` cubre aprobación/rechazo de ambos tipos + creación de solicitudes de asignación (acción privilegiada de asistente de campo, no self-service);
- `membership-requests` permanece como dominio distinto con `club_members:approve` — no se unifica a pesar de compartir nav admin;
- la migración es cambio duro sin compat window: seed otorga `requests:*` a todos los roles con permisos previos antes del switch de handlers.

**Consecuencias**:

- directores de club (CLUB), asistentes de campo local (GLOBAL) + JOIN copies (director-lf, assistant-union, director-union, assistant-dia, director-dia) mantienen capacidad de review tras migración;
- directores de club + assistant-lf + JOIN copies reciben `requests:review` explícito;
- admin/super_admin capturan via wildcard;
- futuros casos de self-service de asignación pueden introducir `requests:create` sin romper este canon, pero requieren extender la decisión;
- cualquier notificación emitida por aprobación/rechazo debe usar `source = 'requests:*'` siguiendo `docs/canon/runtime-communications.md`.

### 19. User certifications + user folders son dominios canónicos propios (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: certifications.controller.ts y folders/folders.controller.ts con 10 handlers migrados a user_certifications:* y user_folders:*. Colisión con permisos existentes certifications:read / folders:read (browse catalog) resuelta con prefix user_. Canonizado en docs/canon/runtime-user-certifications.md y runtime-user-folders.md. -->

**Contexto**: Sprint C del audit de permisos reutilizados migró `certifications` y `folders` modules desde `users:update_profile`/`users:read_detail` hacia permisos propios. Al ejecutar, se detectó colisión semántica grave: los strings `certifications:read` y `folders:read` YA existían en el seed con semántica **browse catalog** y grants amplios (user, member, counselor, etc.). Redefinirlos para operaciones admin-level habría expandido silenciosamente el scope: cualquier rol con el permiso de browse habría ganado acceso a endpoints que manipulan progresión de otros usuarios.

El patrón `folders:*` también conflictuaba con `evidence_folders:*` (subsistema hermano en `folders/evidence-folder.controller.ts`) y con el browse catalog (`OptionalJwtAuthGuard`) — tres dominios ortogonales compartiendo carpeta de código.

**Decisión**: El canon adopta prefijo `user_` para distinguir las operaciones admin-level sobre progresión de usuario, preservando los permisos originales de browse catalog sin cambios. Se introducen:

- `user_certifications:read` / `user_certifications:manage` — para endpoints admin de progresión de certificaciones.
- `user_folders:read` / `user_folders:manage` — para endpoints admin de inscripción/progreso de carpetas de usuario.

Autoridades rectoras: `docs/canon/runtime-user-certifications.md` + `docs/canon/runtime-user-folders.md`. Se fija que:

- `certifications:read` y `folders:read` conservan sus semánticas originales (browse catalog, broad grants) — NO se redefinen ni se retiran;
- `user_*:read` se otorgan solo a staff con autoridad operativa sobre otros usuarios: counselor, secretary, treasurer, secretary-treasurer, deputy-director, director (CLUB) + assistant-lf + JOIN copies + admin/super_admin;
- `user_*:manage` queda restringido a liderazgo: deputy-director, director, assistant-lf + JOIN + admin/super_admin;
- los tres dominios de carpetas (`folders:read` browse, `user_folders:*` admin progression, `evidence_folders:*` evidencia anual) permanecen separados por diseño;
- la migración es cambio duro con corrección: primero se retrajeron grants incorrectos de `certifications:manage` / `folders:manage` (agregados brevemente por Sprint C inicial), luego se introdujeron los `user_*` con grants correctos, finalmente se conmutaron los handlers.

**Consecuencias**:

- nunca debe redefinirse un permiso existente con semántica distinta sin auditoría previa de uso y grants; el prefix `user_` queda como patrón canónico para operaciones sobre datos de otros usuarios;
- futuros módulos similares (ej. si surge `user_*`-operations para otras entidades de trayectoria) deben seguir el mismo patrón;
- los canons `runtime-user-certifications.md` y `runtime-user-folders.md` documentan la separación explícita de los browse catalogs públicos — cualquier intento de colapsarlos en un único permiso es violación del canon;
- notificaciones emitidas por operaciones de progresión deben usar `source = 'user_certifications:*'` o `source = 'user_folders:*'` respectivamente.

### 20. Camporees CRUD es dominio canónico propio; attendance permanece cross-cutting (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: camporees.controller.ts con 10 CRUD handlers migrados a camporees:*, 24 handlers attendance/registration/payments preservados en attendance:*. Permisos camporees:create/update/delete agregados al seed. Canonizado en docs/canon/runtime-camporees.md. -->

**Contexto**: El módulo `camporees` tenía 34 handlers gateados por dominios ajenos: 10 CRUD por `activities:*` (mezcla conceptual — crear un camporee no es equivalente a crear una actividad semanal) y 24 operaciones de attendance/registration/payments por `attendance:*` (correcto semánticamente — attendance es cross-cutting entre actividades regulares y camporees). Los permisos `camporees:read` y `camporees:register` YA existían en el seed pero nunca se usaron — gap de implementación.

Audit C2 clasificó `camporees` en media prioridad. Sprint D aborda la migración con decisión explícita de scope: migrar solo CRUD, preservar attendance cross-cutting.

**Decisión**: El canon adopta `camporees` como dominio propio **solo para la capa Operation (CRUD)**. La autoridad rectora es `docs/canon/runtime-camporees.md`. Se fija que:

- `camporees:read/create/update/delete` son los permisos canónicos para CRUD de la entidad camporee (local y union);
- `attendance:read/manage/approve_late` permanecen como permisos cross-cutting entre activities y camporees — fragmentarlos en `camporees:attendance:*` rompería consistencia con el patrón existente en activities;
- `camporees:register` permanece en seed como permiso reservado sin uso — reactivarlo requiere decisión explícita posterior (ej. si el producto diferencia "inscripción de club" del generic `attendance:manage`);
- la migración es cambio duro: seed otorga `camporees:*` a roles con `activities:*` mirrored antes del switch de handlers (mismo patrón de sprints anteriores).

**Consecuencias**:

- creación/eliminación de camporees tiene autoridad independiente de creación de actividades semanales — roles pueden ser otorgados/revocados sin afectar el otro dominio;
- attendance en camporees comparte UX y permiso con attendance en actividades — coherente para staff que opera ambos contextos;
- el wildcard de `admin` (`NOT LIKE '%:delete'`) excluye `camporees:delete` — si se requiere acceso admin a delete, debe agregarse explícitamente; hoy solo `super_admin` captura via wildcard full;
- handlers futuros en camporees deben clasificarse en las dos capas antes de elegir permiso; documentar en el canon cualquier caso borderline.

### 21. Validation es dominio canónico propio con coexistencia (2026-04-22)

**Estado**: Vigente <!-- VERIFICADO: validation.controller.ts con 5 handlers migrados a validation:submit/review/read, permisos originales classes:* y users:read_detail preservados intactos en seed, roles granted correctamente. Canonizado en docs/canon/runtime-validation.md. -->

**Contexto**: El módulo `validation` (workflow de submit → review para progreso de clases y honores) tenía 5 handlers gateados por `classes:submit_progress`, `classes:validate`, `classes:read`, y `users:read_detail` — reutilización que mezclaba concerns entre currículo y workflow de revisión. Audit C2 clasificó como Sprint E con modelo de coexistencia: agregar permisos propios sin retirar los originales, para no afectar otros módulos legítimos que puedan usarlos.

Hallazgo paralelo: la ruta admin `/dashboard/validation` usaba `investiture:read` (dominio incorrecto, drift histórico). Corregido en la misma ola.

**Decisión**: El canon adopta `validation` como dominio propio con permisos propios `validation:submit` / `validation:review` / `validation:read`. La autoridad rectora es `docs/canon/runtime-validation.md`. Se fija que:

- `validation:submit` → enviar progreso para revisión (member + staff con autoridad de envío).
- `validation:review` → aprobar o rechazar progreso enviado (counselor, staff, director, coordinator globales).
- `validation:read` → leer cola pendiente, historial, elegibilidad (amplio — incluye user, pastor).
- los permisos originales `classes:submit_progress`, `classes:validate`, `classes:read`, `users:read_detail` PERMANECEN ACTIVOS en el seed — no se retiran en esta ola;
- `member` tiene `validation:submit` deliberadamente (self-service de envío);
- `coordinator`/`zone-coordinator`/`general-coordinator` tienen `review` pero no `submit` — son revisores institucionales;
- la migración fue coexistencia, no destructiva: si otros módulos usan los permisos originales, siguen operativos sin cambio.

**Consecuencias**:

- deprecación futura de `classes:submit_progress`/`classes:validate`/`classes:read`/`users:read_detail` como permisos de validación requiere decisión explícita + audit adicional para confirmar que no quedan otros callers;
- nav admin en rutas de validación debe usar `validation:*`; usar permisos de otros dominios (ej. `investiture:read`) es drift y debe corregirse;
- cualquier nuevo handler de validación debe usar `validation:*`; reutilizar `classes:*` rompe el canon;
- notificaciones emitidas por aprobación/rechazo deben usar `source = 'validation:*'`.

**Cierre del audit C2 de permisos reutilizados**: Sprint E es el último del plan de 5 sprints (MoM §16, scoring-categories §17, requests §18, user_certifications+user_folders §19, camporees §20, validation §21). 6 dominios canonizados con permisos propios. Audit cerrado.

### 22. Criterios institucionales ampliados (8.4-C)

**Estado**: Vigente <!-- VERIFICADO: schema club_annual_rankings con 5 columnas nuevas + composite_calculated_at, ranking_weight_configs, award_categories extendido con min/max_composite_pct + is_legacy, score-calculators/*, WeightsResolver, endpoint /breakdown, CRUD /ranking-weights. Vigente desde 2026-04-28. -->

**Contexto**: El sistema de rankings institucionales (§12, `docs/canon/runtime-rankings.md`) ordenaba los clubes únicamente por `total_earned_points` de carpeta evaluada. Eso dejaba fuera criterios institucionales relevantes (cumplimiento financiero mensual, asistencia a camporees, cobertura de evidencias) y no permitía configurar pesos por tipo de club.

**Decisión**: El canon adopta un composite ponderado de 4 componentes como índice de clasificación institucional. Se fija que:

- el composite es el promedio ponderado de `folder_score_pct` (0-100) + `finance_score_pct` + `camporee_score_pct` + `evidence_score_pct`, cada uno calculado independientemente por su propio score-calculator;
- los pesos globales por defecto son `60 / 15 / 15 / 10` (folder / finance / camporee / evidence); se pueden sobreescribir por `club_type_id` en `ranking_weight_configs`; la suma debe ser exactamente 100 (DB CHECK + API validation);
- el dense ranking (`rank_position`) se asigna sobre `composite_score_pct DESC` (antes sobre `total_earned_points DESC`);
- semántica current-year-forward: los rankings históricos retienen `0` en los campos nuevos vía `DEFAULT 0` sin recomputación retroactiva;
- `award_categories.{min,max}_composite_pct` interpretan umbrales en escala 0-100; las filas pre-2026-04-28 están marcadas `is_legacy = true` y excluidas del composite ranking;
- el kill-switch `system_config[ranking.recalculation_enabled]` (default `true`) inhibe tanto el cron como el recálculo manual; ambas rutas lo consultan antes de ejecutar;
- el `system_config[ranking.finance_closing_deadline_day]` (default `5`) parametriza qué día del mes se considera como fecha límite de cierre financiero para el cálculo de `finance_score_pct`.

**Consecuencias**:

- `GET /annual-folders/rankings*` ahora incluye los 6 campos nuevos por fila;
- el nuevo endpoint `GET /annual-folders/rankings/:enrollmentId/breakdown?year_id` expone el composite + pesos + detalle por componente (permiso `rankings:read`);
- el CRUD `/ranking-weights` (5 endpoints, permisos `ranking_weights:read/write`) gestiona las configuraciones de pesos; el default global no puede eliminarse;
- cualquier nuevo criterio de clasificación debe agregarse como componente en `score-calculators/*` y requerir actualización de este canon;
- la integración de camporee score requiere que los camporees del año estén registrados en la DB antes del recálculo; ausencia de camporees produce `score_pct = 0`, no error.

**Referencias**:

- Spec: `docs/superpowers/specs/2026-04-28-clasificacion-criterios-ampliados-design.md`
- Plan: `docs/superpowers/plans/2026-04-28-clasificacion-criterios-ampliados.md`
- Canon rector: `docs/canon/runtime-rankings.md` §13.

## Estados posibles de una decisión

Las decisiones de este documento deben estar en uno de estos estados:

- `Vigente`;
- `Superada`;
- `En revisión`.

Una decisión importante no debe desaparecer sin dejar rastro. Si deja de aplicar, debe marcarse como superada y mantenerse trazabilidad hacia su reemplazo.

## Cierre

Este documento existe para conservar memoria estructural, no nostalgia técnica. Su función es impedir que decisiones profundas vuelvan a discutirse sin contexto, como si hubieran aparecido de la nada. En SACDIA, las decisiones clave deben servir para sostener claridad, no para inflar el archivo con historia irrelevante.
