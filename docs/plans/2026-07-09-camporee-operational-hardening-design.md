# Camporee Operational Hardening — Diseño

**Estado:** APROBADO

**Fecha:** 2026-07-09
**Origen:** auditoría `docs/audit/2026-07-09-camporee-flow-security-review.md`

## Objetivo

Cerrar el flujo operativo de camporees sin perder trazabilidad: configuración previa, cierre automático de inscripciones, admisiones tardías penalizadas, agenda, jueces, scoring por ventana horaria, resultados para clubes y ranking anual basado en puntos oficiales.

## Decisiones aprobadas

1. La penalización tardía base descuenta puntos.
2. Campo Local o Unión puede activar adicionalmente una penalización monetaria.
3. Las penalizaciones no modifican evaluaciones originales; se registran como movimientos auditables.
4. El juez principal sólo califica una vez y dentro de la ventana del evento.
5. Campo Local/Unión puede corregir mediante override con motivo obligatorio.
6. Los datos competitivos quedan congelados al iniciar el camporee; durante el evento sólo se permiten ajustes operativos explícitos.
7. `club_registration_opens_at` es `TIMESTAMPTZ NULL` en camporees locales y de Unión; `NULL` significa apertura inmediata.

## Arquitectura recomendada

### 1. Fase operativa calculada

Crear `CamporeeLifecyclePolicy` como autoridad única para resolver:

- `preparation`
- `registration_open`
- `registration_closed`
- `in_progress`
- `finished`

La política recibe `clubRegistrationOpensAt` además de los deadlines/cierre manual. Antes de la fecha local de inicio, las fases son:

```text
preparation: now < club_registration_opens_at
registration_open: desde la apertura (o inmediatamente si es NULL) hasta club_registration_deadline inclusive
registration_closed: después del deadline o cuando existe cierre manual
```

Las fechas `start_date`/`end_date` continúan siendo `DATE`: se comparan como calendario en `camporee.timezone`, sin inventar medianoche. Por tanto, `in_progress` aplica para `start_date <= localToday <= end_date` y `finished` después de `end_date`; esas fases operativas tienen prioridad durante/después del evento.

La disposición de inscripción se expone por separado para preservar el caso límite de apertura/deadline el mismo día calendario del inicio:

```text
not_open_yet | open | late_approval_required | manually_frozen
```

El cierre efectivo para el flujo normal de clubes será:

```text
club_registration_closed_at != null
OR now > club_registration_deadline
```

No se requiere cron para aplicar seguridad. Cada mutación consulta la política. Los jobs sólo enviarán notificaciones o materializarán métricas.

Los DTOs aceptan `start_date`/`end_date` sólo como `YYYY-MM-DD`; rechazan timestamps. Apertura y deadlines son `TIMESTAMPTZ` y exigen ISO-8601 con `Z` u offset; rechazan date-only. Validar `start_date <= end_date` como fecha local, `club_registration_opens_at <= club_registration_deadline` cuando ambos existan y todos los deadlines por fecha calendario local `<= start_date`.

Los camporees deberán almacenar un timezone IANA. Para registros existentes, la migración usará `America/Mexico_City` como valor provisional y dejará `timezone_verified_at=null`; readiness y scoring por ventana quedan bloqueados hasta que Campo Local/Unión confirme la zona. `timezone_verified_by` es UUID con FK nombrada a `users`, relación inversa por tipo de camporee, `ON DELETE SET NULL` e índices. Crear o actualizar con una timezone explícita válida registra `timezone_verified_at/by` con `req.user.sub`; un PATCH que omite timezone conserva la verificación previa.

`CamporeeLifecyclePolicy` reemplaza los gates duplicados de servicios/controlador, incluido el flujo de aprobaciones tardías, y se mantiene sincronizado con el mirror de `club_registration_closed_at/by`.

### 2. Matriz de mutaciones

| Operación | Antes de iniciar | En curso | Finalizado |
|---|---:|---:|---:|
| Editar nombre/descripción general | Sí | Sólo notas no competitivas | No |
| Editar máximos, mínimos o rúbricas | Sí | No | No |
| Activar/desactivar scoring | Sí | No | No |
| Eliminar/desactivar evento puntuable | Sí | No | No |
| Cambiar secciones participantes | Sí | No | No |
| Ajustar horario/sede | Sí | Sí, con auditoría | No |
| Ajustar juez principal/ayudantes | Tras cierre efectivo | Sí, con auditoría | No |
| Enviar puntaje como juez | No | Sólo ventana del evento | No |
| Override Campo Local/Unión | No | Sí | Sí, con motivo |

Como defensa adicional, la existencia del primer resultado oficial también congela los campos competitivos del evento.

### 3. Comando atómico de evento

Crear y actualizar una instancia deberá aceptar en el mismo contrato:

```ts
type CamporeeEventDefinition = {
  title: string;
  description?: string;
  requirements?: string;
  development?: string;
  materials?: string;
  auxiliaries?: string;
  max_points: number;
  min_points: number;
  scoring_enabled: boolean;
  rubrics: Array<{
    title: string;
    description?: string;
    max_points: number;
    display_order: number;
  }>;
  // agenda y participantes
};
```

Evento y rúbricas se persisten dentro de una sola transacción. La suma de rúbricas debe coincidir con `max_points`. El cierre de inscripción NO es requisito para diseñar rúbricas; sólo lo es para asignar targets competitivos definitivos. La validación es una función TypeScript pura y dependency-free, compartida por eventos, templates y el endpoint legado de rúbricas, para evitar ciclos de módulos Nest. Los templates ya son transaccionales; se conserva ese comportamiento. Create/update de eventos se vuelve atómico. El endpoint legado sólo puede modificar rúbricas antes del freeze competitivo.

La misma definición competitiva aplica a `camporee_event_templates`: nombre, detalle, requisitos, desarrollo, materiales, auxiliares, máximos, mínimos, penalizaciones del evento, estado puntuable, rúbricas y documentos reutilizables. La agenda, sede, jueces y secciones siguen siendo datos exclusivos de la instancia. Clonar un template copia un snapshot completo; cambios posteriores del template no alteran instancias existentes.

### 3.1. Template de camporee completo

Además de templates de evento, Campo Local y Unión pueden guardar un camporee configurado como blueprint reutilizable. El blueprint conserva:

- tipos de club participantes;
- timezone, costos y reglas de penalización;
- deadlines como offsets relativos a la fecha de inicio;
- sedes como definiciones reutilizables, sin asumir disponibilidad;
- eventos, rúbricas, documentos y agenda por número de día.

No copia inscripciones, pagos, resultados ni asignaciones activas de usuarios. Los roles operativos se guardan como slots (`juez principal`, `ayudante`, `responsable`) y deben resolverse nuevamente contra usuarios elegibles del scope al crear el nuevo camporee. Crear desde blueprint solicita fechas absolutas, recalcula deadlines y persiste el nuevo camporee con sus eventos en una sola transacción.

### 4. Ventana de scoring

La ventana se deriva de:

```text
camporee.start_date
+ (event.day_number - 1)
+ event.starts_at / event.ends_at
en camporee.timezone
```

Todo evento puntuable publicado debe tener inicio y fin. El juez obtiene únicamente asignaciones:

- activas;
- `primary`;
- dentro de ventana;
- sin resultado oficial previo.

El submit devuelve un comprobante con:

- total bruto;
- ajuste por mínimo;
- total oficial;
- estado `scored|no_show`;
- usuario y fecha;
- identificador de submission.

### 5. Ajuste por mínimo

No se ocultará la diferencia entre rúbricas y total oficial:

```text
raw_total
minimum_adjustment
official_total
```

Los ítems conservan la evaluación original. El ajuste queda explícito y consultable.

### 6. Penalizaciones tardías

#### Configuración

Crear una regla por camporee y trigger:

```text
trigger: club_registration | member_registration | payment
points_deduction
financial_enabled
financial_mode: fixed | percentage
financial_value
active
```

La deducción de puntos es la base para admisiones tardías. El recargo financiero queda desactivado por defecto.

#### Aplicación

Al aprobar una solicitud tardía se crean, en la misma transacción:

1. aprobación del enrollment/pago;
2. `camporee_penalty_application` inmutable con snapshot de la regla;
3. `camporee_score_adjustment` negativo para la sección;
4. `camporee_financial_charge` cuando el recargo esté habilitado.

Cada solicitud sólo puede generar una aplicación activa. Una corrección posterior crea reversa/void; nunca reescribe el histórico.

#### Cálculo oficial

```text
official_camporee_points = max(0, sum(active event results) + sum(active adjustments))
```

El leaderboard del camporee y el ranking anual deben consumir exactamente ese agregado.

### 7. Autorización

Separar permisos:

- `camporee_scores:submit`
- `camporee_scores:override`
- `camporee_penalties:configure`
- `camporee_penalties:approve`

Reglas:

- juez principal: submit sólo para su asignación exacta;
- `assistant-lf`/`director-lf`: manual y override en camporee local de su scope;
- `assistant-union`/`director-union`: equivalente para camporee de unión;
- admins globales: override administrativo auditado;
- editar eventos no implica editar puntajes.

El único `POST /camporee-events/:eventId/sections/:clubSectionId/scores` declara metadata de permisos en modo `any` para `camporee_scores:submit|camporee_scores:override` sobre el recurso evento. Después, el servicio exige `submit` para `judge_primary` y `override` para `manual_lf`/`admin_override`, además de rol, asignación exacta y scope.

Toda FK secundaria debe resolverse contra el camporee destino: template, sede, responsable, roster, juez, club y sección. IDs cross-scope devuelven `404`; estados inválidos del recurso propio devuelven `409`/`422`. Los IDs derivados, como `camporee_club_id`, los calcula el backend.

### 8. Resultados para el club

Crear estado de representante por evento/sección:

```text
director_present
director_absent_subdirector_authorized
```

Lo registra el juez principal con actor y timestamp. El director de sección ve resultado y comentarios. El subdirector sólo obtiene acceso cuando exista la segunda marca.

### 9. Archivos PDF

Cada evento y cada template admite hasta cinco PDFs privados. El backend valida:

- MIME permitido y firma real `%PDF`;
- tamaño máximo configurable;
- máximo cinco activos;
- nombre de objeto generado por servidor;
- pertenencia al evento y scope;
- URL firmada de corta duración.

El objeto almacenado es un asset inmutable y las relaciones con template/evento se guardan en filas independientes. Al clonar un template se crean relaciones para la nueva instancia sin depender de que la relación original permanezca activa. Las eliminaciones son soft-delete y el objeto sólo puede purgarse cuando ya no tenga referencias activas.

### 10. Experiencia administrativa

Orden del flujo:

1. datos generales, timezone, costos y deadlines;
2. eventos generales, puntos, rúbricas y PDFs;
3. agenda, sedes y personal;
4. roster de jueces y asignaciones;
5. revisión de readiness y cierre efectivo;
6. operación en vivo, overrides y penalizaciones;
7. resultados y cierre.

Los paneles deben diferenciar `vacío`, `cargando` y `error`; no convertir fallas API en listas vacías. Los datos de scoring se cargarán de forma agregada o lazy para evitar el fan-out por evento.

### 11. Experiencia móvil

- Entrada visible “Evaluaciones asignadas” sólo cuando el usuario tenga assignments.
- Bandeja separada en `pendientes` y `completadas`.
- Confirmación irreversible antes de enviar.
- Opción `Club no se presentó`.
- Comentario global y notas por rúbrica.
- Comprobante posterior con total bruto, ajuste y total oficial.
- Vista de resultado para director/subdirector según estado de representante.

### 12. Concurrencia e idempotencia del scoring

El índice parcial de resultado activo no serializa por sí solo la secuencia `leer → desactivar → insertar`. Todo submit u override deberá adquirir un lock transaccional por `camporee_event_id + club_section_id` antes de consultar el resultado vigente.

El endpoint de scoring aceptará `Idempotency-Key` UUID y guardará un hash canónico del payload:

- misma clave + mismo payload: devuelve el mismo receipt sin volver a mutar;
- misma clave + payload distinto: `409 IDEMPOTENCY_KEY_REUSED`;
- dos submits concurrentes diferentes: sólo uno crea resultado; el otro recibe `409 RESULT_ALREADY_SUBMITTED`;
- un override exige `expected_active_result_id`; si cambió, devuelve `409 SCORE_RESULT_STALE`.

Durante la transición, clientes antiguos pueden omitir la clave, pero no obtienen garantía de reintento idempotente. La serialización y el one-shot siguen siendo obligatorios.

### 13. Borradores móviles offline

La primera versión usa `flutter_secure_storage` y `connectivity_plus`, ya instalados, para una cola pequeña cifrada. No agrega Hive/SQLite ni workers en background.

Estados locales:

```text
draft | pending | syncing | synced | failed
```

La app conserva la misma `Idempotency-Key` en cada reintento y sólo marca `synced` al recibir receipt del servidor. El reloj del dispositivo no autoriza scoring: si el submit llega después de la ventana, falla y requiere override de Campo Local/Unión. Los drafts se scopean por usuario, grant, evento y sección; se purgan al cerrar sesión, perder scope o recibir `403`.

### 14. Concurrencia operativa

Eventos y asignaciones de jueces exponen una versión. Todo PATCH de evento y PATCH individual de asignación recibe `expected_version`; si otro operador modificó el recurso, el backend responde `409 CAMPOREE_CONFIGURATION_STALE` con la versión vigente. La base garantiza un único juez primary activo por `(camporee_event_id, club_section_id)` mediante índice parcial único.

`POST /camporee-events/:eventId/judge-assignments:bulk` recibe `{ expected_event_version, operations }`: bloquea el evento, realiza CAS de versión, prevalida la totalidad de operaciones y ejecuta todo en una transacción o nada. La prevalidación cubre principal único, elegibilidad, `scoring_enabled`, scope de venue/template/roster y freeze competitivo.

### 15. Centro operativo y aclaraciones

El admin se organiza por lifecycle, sin crear una navegación paralela:

- checklist de readiness con enlaces al bloqueo exacto;
- modo `live` sólo en `in_progress`, usando una lectura agregada;
- matriz evento × sección para jueces, con preview de conflictos;
- preview server-side antes de instanciar un blueprint;
- estados `loading | error | empty | ready`, foco visible y mensajes no dependientes sólo de color.

Las aclaraciones son un recurso trazable sobre un resultado, no un chat ni una edición. Estados mínimos: `open | answered | resolved | rejected`. Director/subdirector autorizado solicita; juez o gestor responde; Campo Local/Unión resuelve. Cualquier cambio de puntos sigue pasando por override con motivo.

### 16. Entrega progresiva

La primera entrega usa polling acotado del read model agregado. Realtime push, QR operativo, adjuntos en aclaraciones, SLA y sincronización móvil en background quedan diferidos hasta tener scoring serializado, receipts e idempotencia verificados.

## Estrategia de migración

1. Agregar tablas/campos sin eliminar contratos existentes, incluido `club_registration_opens_at TIMESTAMPTZ NULL` para camporees locales y de Unión, timezone y su auditoría de verificación.
2. Backfill de timezone provisional/no verificado y totales brutos para submissions históricos; sincronizar el mirror documental de `club_registration_closed_at/by`.
3. Mantener lectura compatible de resultados previos.
4. Migrar admin al comando atómico.
5. Retirar el flujo de dos peticiones cuando no existan consumidores antiguos.
6. Actualizar documentación canónica en cada checkpoint que cambie schema, endpoint, permiso o error; no diferirla al final.

## Criterios de aceptación

- No puede existir evento puntuable activo sin rúbricas válidas.
- Fallar la persistencia de rúbricas revierte el evento completo.
- Ningún juez puntúa fuera de ventana ni dos veces.
- Los límites exactos de apertura/deadline, DST, cierre manual y PATCH parcial de timezone están cubiertos por pruebas.
- No puede existir más de un juez primary activo para el mismo evento y sección, incluso bajo concurrencia.
- Reintentar la misma petición idempotente devuelve el mismo receipt.
- Dos peticiones concurrentes no pueden reemplazarse silenciosamente.
- Cambiar un evento ya puntuado no altera resultados históricos.
- Toda admisión tardía aprobada deja ajuste de puntos y auditoría.
- El recargo monetario sólo se aplica cuando está habilitado.
- Leaderboard y ranking anual coinciden con el total oficial ajustado.
- No existe acceso cross-scope mediante IDs adivinados.
- Director/subdirector ve el resultado según la regla de presencia.
- Un draft offline nunca se presenta como oficial antes del receipt del servidor.
