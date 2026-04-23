# Canon Documentation

## Estado
ACTIVE

## Propósito
Esta carpeta contiene la capa documental canónica y activa del proyecto.

Su objetivo es reducir contradicciones entre documentos históricos, walkthroughs, notas de implementación y contratos realmente vigentes.

Acá debe vivir la fuente de verdad operativa para dominios, runtime y procesos clave.

## Regla principal
Si un documento dentro de `docs/canon/` contradice un documento fuera de esta carpeta, manda `docs/canon/`.

Los documentos fuera de `docs/canon/` pueden seguir existiendo como referencia, contexto histórico o evidencia de implementación, pero no redefinen el contrato activo.

## Qué debe vivir en esta carpeta
En `docs/canon/` solo deben vivir documentos que cumplan al menos una de estas funciones:

- definir el lenguaje y límites de un dominio;
- definir el comportamiento técnico vigente de un área;
- definir procesos operativos canónicos;
- mapear la relación entre documentos canónicos y documentos legacy.

## Qué no debe vivir en esta carpeta
No deben vivir acá:

- walkthroughs históricos;
- notas exploratorias sin validar;
- planes temporales de implementación;
- bitácoras de sesión;
- documentación duplicada cuyo contrato activo ya exista en otro documento canónico.

## Precedencia dentro de la capa canónica
Orden de autoridad actual:

1. `gobernanza-canon.md`
2. `dominio-sacdia.md`
3. `identidad-sacdia.md`
4. `arquitectura-sacdia.md`
5. `runtime-sacdia.md`
6. `decisiones-clave.md`

Semántica:
- `gobernanza-canon.md` manda en precedencia y reglas documentales;
- `dominio-sacdia.md` manda en lenguaje, conceptos y semántica del sistema;
- `identidad-sacdia.md` manda en propósito, alcance y frontera;
- `arquitectura-sacdia.md` manda en organización técnica y responsabilidades;
- `runtime-sacdia.md` manda en verdad operativa actual, subordinada al dominio;
- `decisiones-clave.md` conserva memoria estructural y justificación.

## Resolución de conflictos
Si aparece una contradicción:

1. se prioriza el documento canónico más específico dentro de `docs/canon/`;
2. si la contradicción es entre dominio y runtime:
   - `dominio-*.md` manda en intención y semántica del negocio;
   - `runtime-*.md` manda en comportamiento técnico vigente;
3. si la contradicción es con documentación legacy, el documento legacy debe marcarse como `DEPRECATED` o `HISTORICAL`.

## Estados permitidos
Cada documento canónico debe declarar uno de estos estados:

- `ACTIVE` — documento vigente y operativo;
- `DRAFT` — documento en construcción, todavía no definitivo;
- `DEPRECATED` — documento reemplazado por otro canónico;
- `HISTORICAL` — documento preservado por contexto, pero no vigente.

## Convención editorial para futuro y pendientes
- No inventar estados nuevos como `future`, `planned` o `pending`.
- Si un documento sigue siendo canónico, mantener `ACTIVE` y marcar dentro del texto lo que esté `Pendiente`, `Por definir`, `Por verificar` o `Planificado`.
- No presentar como vigente algo que todavía no existe en runtime.

## Estructura actual recomendada
```text
docs/
  canon/
    README.md
    dominio-sacdia.md
    identidad-sacdia.md
    gobernanza-canon.md
    arquitectura-sacdia.md
    runtime-sacdia.md
    decisiones-clave.md
    auth/
      modelo-autorizacion.md
      runtime-auth.md
```

## Documentos canónicos actuales

### `dominio-sacdia.md`

Define el lenguaje oficial, los conceptos centrales, las reglas semánticas, los invariantes y las tensiones del dominio.

### `identidad-sacdia.md`

Define propósito, problema, actores, frontera y criterio rector del sistema.

### `gobernanza-canon.md`

Define planos documentales, precedencia, resolución de contradicciones, estados y reglas de mantenimiento del canon.

### `arquitectura-sacdia.md`

Traduce el dominio a una organización técnica coherente para backend, admin web, app móvil, datos e integraciones.

### `runtime-sacdia.md`

Describe la verdad operativa actual del sistema. Mientras no termine su verificación contra código, permanece en estado `DRAFT`.

### `decisiones-clave.md`

Conserva la memoria estructural de las decisiones que fijan interpretación, organización y evolución del sistema.

### `runtime-achievements.md`

Canoniza el sistema de logros y tiers (Bronze→Diamond) del miembro, evaluación por eventos y journal persistente. Decisión registrada: `decisiones-clave.md` §11.

### `runtime-rankings.md`

Canoniza la clasificación anual de clubes por puntaje de carpetas, categorías de premio configurables y dense ranking. Conceptualmente distinto de `runtime-achievements.md`. Decisión registrada: `decisiones-clave.md` §12.

### `runtime-resiliencia-red.md`

Canoniza la capacidad vigente de cache local + TTL + invalidación por FCM silent messages, y la separa explícitamente de un modelo offline-first (no implementado hoy). Decisión registrada: `decisiones-clave.md` §13.

### `runtime-communications.md`

Canoniza las comunicaciones visibles (notificaciones push + bandeja), persistencia dual `notification_logs` + `notification_deliveries`, opt-out por categoría, ciclo de vida de tokens FCM y convención del tag `source` para trazabilidad. Distinto del path silent (ver `runtime-resiliencia-red.md`). Decisión registrada: `decisiones-clave.md` §14.

### `runtime-sla-dashboard.md`

Canoniza el SLA dashboard como lector puro de datos operacionales (investiture, validation, camporee), con cache in-memory TTL 60s, scope por `local_field_id` del coordinador derivado del JWT, y ventanas temporales fijas (30d overdue, 90d approval rate, 12w throughput). Sin tablas dedicadas. Decisión registrada: `decisiones-clave.md` §15.

### `runtime-member-of-month.md`

Canoniza el reconocimiento mensual del miembro con mayor puntaje por sección, evaluación automática por cron + manual por director con idempotencia, empates permitidos con ganadores múltiples, notificación a ganador + liderazgo, superficie admin multi-sección, y permisos propios `mom:*`. Decisión registrada: `decisiones-clave.md` §16.

### `runtime-scoring-categories.md`

Canoniza el catálogo jerárquico de categorías de puntuación (division/union/local-field) con herencia automática entre niveles, consumido por weekly-records, MoM y annual-folders-scoring. Permisos propios `scoring_categories:read/manage` tras migración desde `units:*`. Decisión registrada: `decisiones-clave.md` §17.

### `runtime-requests.md`

Canoniza el workflow de solicitudes de transferencia de miembros entre clubes y solicitudes de asignación de rol. Permisos propios `requests:read/review` tras migración desde `clubs:*`/`club_roles:*`. `membership-requests` queda explícitamente fuera (dominio separado con `club_members:approve`). Decisión registrada: `decisiones-clave.md` §18.

### `runtime-user-certifications.md`

Canoniza las operaciones admin-level sobre progresión de certificaciones de usuario (enrollUser, getUserCertifications, updateProgress, etc.). Permisos propios `user_certifications:read/manage` con prefix `user_` para evitar colisión con el browse catalog público `certifications:read`. Decisión registrada: `decisiones-clave.md` §19.

### `runtime-user-folders.md`

Canoniza las operaciones admin-level sobre inscripción y progreso de carpetas de usuario. Permisos propios `user_folders:read/manage`. Distinto del browse catalog (`folders:read`) y del subsistema hermano de carpetas de evidencia anual (`evidence_folders:*`). Decisión registrada: `decisiones-clave.md` §19.

### `runtime-camporees.md`

Canoniza operaciones CRUD sobre la entidad camporee con permisos propios `camporees:read/create/update/delete`. Separa explícitamente de `attendance:*` cross-cutting (preservado deliberadamente entre activities y camporees). Permiso `camporees:register` reservado sin uso actual. Decisión registrada: `decisiones-clave.md` §20.

### `runtime-validation.md`

Canoniza el workflow submit → review con permisos propios `validation:submit/review/read`. Coexistencia: los permisos originales `classes:*` y `users:read_detail` PERMANECEN activos para sus dominios propios. Drift histórico corregido: nav `/dashboard/validation` migrado de `investiture:read` a `validation:read`. Decisión registrada: `decisiones-clave.md` §21.

### `runtime-alerting.md`

Canoniza la capa de alerting Sentry sobre los 3 runtimes (backend/admin/app). Separa código (captura + tags + fingerprints) de configuración (reglas Sentry UI, reconfigurables sin redeploy). Documenta convención de tags (`cron`, `job_name`, `source`, `queue`), 5 reglas de alerta recomendadas, runbook operacional y release tracking via `VERCEL_GIT_COMMIT_SHA` / `RENDER_GIT_COMMIT`.

## Convenciones de nombres
- `<area>.md` o `<tema>.md` — documento canónico cuando el nombre exacto comunica mejor su rol sistémico;
- `dominio-<area>.md` — definición funcional y semántica de un dominio específico;
- `modelo-<tema>.md` — decisión conceptual canónica cuando un tema necesita más profundidad que dominio o runtime;
- `runtime-<area>.md` — comportamiento técnico vigente;
- `procesos-<area>.md` — flujos operativos canónicos;
- `legacy-map.md` — mapa de reemplazo documental cuando haga falta cortar autoridad a material viejo.

## Cómo migrar documentación existente
La migración no se hace borrando todo. Se hace así:

1. crear el documento canónico nuevo;
2. declararlo `ACTIVE` cuando ya sea la fuente de verdad;
3. identificar documentos anteriores relacionados;
4. marcar esos documentos anteriores como `DEPRECATED` o `HISTORICAL`;
5. agregar en los documentos anteriores una línea visible con el reemplazo activo.

Ejemplo:

```md
## Estado
DEPRECATED

Reemplazado por: `docs/canon/dominio-sacdia.md`
```

## Regla editorial mínima antes de crear un documento nuevo
Antes de agregar un documento en esta capa, verificar:

- si ya existe otro documento canónico que cubra ese tema;
- si el nuevo documento corresponde a dominio, runtime o proceso;
- si agrega claridad real o solo duplica contenido existente.

## Criterio de calidad mínimo
Un documento canónico debe:

- declarar su propósito;
- declarar su estado;
- no contradecir otros documentos canónicos;
- distinguir claramente entre estado actual y decisiones futuras;
- permitir que otro dev o IA continúe el trabajo sin reinventar el contexto.
