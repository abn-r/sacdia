# 14 · Mapa de producto para la iglesia

**Estado:** DRAFT · **Corte:** 2026-09-14  
**Para qué:** fuente para **armar presentaciones de venta**. No es el deck
congelado de 15 minutos. No certifica que ya esté implantado en toda la Unión
ni en la Iglesia.

> Cómo leer cada capacidad:
>
> | Etiqueta | Qué puedes decir |
> |---|---|
> | **En el producto** | Está modelado en código (app, panel y/o API). Puedes venderlo como parte de SACDIA, con piloto e implantación. |
> | **En proceso** | Forma parte de cómo queda el sistema; aún no lo presentes como recorrido estable. |
> | **No vender como hecho** | Canon o idea; runtime incompleto o otra rama. |

El deck ejecutivo de 15 láminas sigue siendo el recorte prudente de la cita
corta. **Este mapa es el universo.** Las fichas 02–13 dan el detalle
verificado cuando hace falta no improvisar.

## La oferta, en una página

SACDIA es el sistema de **trazabilidad institucional** de los clubes del
Ministerio Juvenil Adventista (Aventureros, Conquistadores, Guías Mayores).

**Problema.** Historial en papeles y hojas sueltas. Cargos que se olvidan al
cambiar de director. Validaciones opacas. Unión y campo sin una vista común.

**Promesa.** La trayectoria de cada persona y la vida de cada sección quedan
registradas, con contexto (quién, dónde, en qué año, bajo qué cargo) y con
**reconocimiento formal** cuando un responsable decide. No sustituye al
ministerio humano: le da memoria y operación.

**Unidad de valor.** La trayectoria del miembro. Clubes, clases, camporees y
tableros existen para sostenerla.

**Qué no es.** Una biblioteca de especialidades. Un Excel en la nube. Un
robot que “aprueba todo solo”. Un ERP genérico.

Fuentes: `docs/canon/identidad-sacdia.md`, `docs/canon/dominio-sacdia.md`.

## A quién le sirve (iglesia)

Jerarquía que el producto modela: país → unión → campo local → distrito →
iglesia → **club** → **sección**.

| Actor | Qué gana cuando el sistema está implantado |
|---|---|
| Niño / joven / Guía Mayor | Cuenta, historial, clase del año, especialidades, credencial, avisos |
| Padres / representante | Datos del menor, solicitud de ingreso, visibilidad de pertenencia |
| Directiva de sección | Roster, cargos, unidades, actividades, informe, carpeta, camporee |
| Consejero | Acompañamiento de clase y evidencia; no es automáticamente el director |
| Coordinador de zona | Revisión de evidencias e investiduras de **su** alcance; no es atajo de campo para camporee |
| Campo local | Aprobaciones territoriales, evaluación de carpetas, camporee local, cobro |
| Unión | Camporee de unión, confirmación de carpetas cuando aplica, tablero operativo, informes |
| Administración técnica | Cuentas, catálogos, permisos; **no** es el cargo de director de jóvenes |

Un cargo de iglesia **no** equivale a administrador del software.

## Cómo queda el sistema (mapa completo)

### 1. Entrar y existir

La persona crea identidad (correo, Google o Apple; opcional MFA). Completa
foto, ficha y pide una sección. Queda **pendiente** hasta que la directiva
aprueba. Existe como usuario sin ser aún miembro operativo.

**En el producto.** Auth, sesiones, OAuth, post-registro, solicitudes de
membresía, cancelar y vencer solicitudes.

Ficha: [06](06-ingreso-inicial.md).

### 2. Club, sección y año

El club es la identidad de la iglesia. La sección es AV, CQ o GM. Los cargos
son del **año eclesiástico**. Al corte de año no se copia el roster: la
directiva inscribe de nuevo; los sucesores de director se programan.

**En el producto.** Clubes y secciones, cupos de directiva, designación /
sucesión de director, corte de año, inscripción anual por directiva.

**No vender como hecho.** Estados canónicos de vinculación (suspendido,
apoyo, historial de transiciones de sección) no están todos en runtime;
hoy la pertenencia es el cargo anual.

Fichas: [01](01-fundamentos.md), [07](07-inscripcion-anual.md), [13](13-operacion-seccion.md).

### 3. Formación y reconocimiento

Tres caminos distintos, más la carpeta anual:

| Camino | Qué es | Quién cierra |
|---|---|---|
| Clase progresiva | Etapa del año (Amigo, Compañero, …) | Investidura: evidencias + pipeline institucional |
| Especialidad (honor) | Competencia elegida por la persona | Revisión de esa especialidad |
| Certificación electiva | Programa versionado (p. ej. personal de club / GM) | Junta + certificador, cola propia |
| Carpeta anual | Expediente de la **sección** para el campo/unión | Evaluación LF; Unión confirma si el folder lo exige |

Registrar un archivo **no** es validar. Aprobar un requisito **no** investe.

**En el producto.** Los cuatro caminos, con matices de UI (p. ej. app usa
ruta legado en un envío de clase; certificaciones: hay pantallas, no se
ensayó piloto).

**En proceso.** Aprobaciones masivas de investidura (para el cierre de año).
Coordinación por zonas: modelo en implementación.

Fichas: [02](02-revision-evidencias.md), [08](08-clases-progresivas.md),
[09](09-honores.md), [10](10-certificaciones.md), [12](12-supervision-institucional.md).

### 4. Vida cotidiana de la sección

| Capacidad | Cómo queda | Etiqueta |
|---|---|---|
| Miembros y cargos | Lista por sección, clase del año, perfil | En el producto |
| Unidades | Grupos menores; una unidad activa por persona en la sección | En el producto |
| Actividades | Calendario, series, conjuntas, asistencia (la registra la directiva, no el miembro) | En el producto |
| Planilla semanal | Puntos por categoría, semana vigente | En el producto |
| Finanzas | Ingresos/egresos, resumen, cierre de mes | En el producto |
| Inventario | Bienes de la sección | En el producto |
| Seguros | GENERAL_ACTIVITIES, CAMPOREE, alto riesgo; condición para camporee | En el producto |
| Traslado entre secciones | Solicitud y aprobación; historial de trayectoria aún limitado | En el producto / hueco de historial |

Ficha recorte demo: [13](13-operacion-seccion.md). Tesorería e inventario:
existen; no hace falta abrirlos en una cita de 15 minutos, **sí** en una
presentación de producto completo.

### 5. Camporees y eventos institucionales

Dos niveles: camporee de **campo** y de **unión**. Inscribir la sección ≠
inscribir personas. Con órdenes de pago, los asistentes nacen al aprobar el
comprobante. Unión: cobra el campo; el dinero campo→unión es fuera del
sistema. Puntuar: rúbricas y juez principal, después de cerrar clubes. No
promedia. No es el ranking anual por inscribirse.

**En el producto.** CRUD, inscripciones, late approval, agenda, scoring,
órdenes de pago de inscripción.

**En proceso.** Pedidos de playeras/gorras e insumos de cocina: código en
**otra rama**, no en la base del piloto. No vender logística de campamento
(transporte, alojamiento).

Ficha: [11](11-camporees.md).

### 6. Supervisión de campo y unión

| Capacidad | Cómo queda | Etiqueta |
|---|---|---|
| Informe mensual | Snapshot del mes; Unión consulta PDF; no hay sello aprobar | En el producto |
| Carpeta anual | Campo califica; Unión confirma si aplica | En el producto |
| Tablero operativo | Clubes operativos vs administrativos, coberturas, colas | En el producto (home de Unión) |
| SLA de colas | Tiempos de investidura/evidencias; **admin y coordinador**, no director-unión | En el producto; no es la vista de Unión |
| Clasificación anual | Ejes (carpeta, informes, finanzas, actividades, camporee oficial, …) | En el producto; fórmulas no auditadas en el concentrado |
| Miembro del mes | Derivado de planilla semanal | En el producto; no profundizado |

Ficha: [12](12-supervision-institucional.md).

### 7. Materiales, avisos y plataforma

| Capacidad | Cómo queda | Etiqueta |
|---|---|---|
| Recursos digitales | Materiales por alcance (unión/campo/tipo) | En el producto |
| Notificaciones | Push, bandeja, preferencias; no cubren todos los eventos (p. ej. aprobar carpeta) | En el producto / huecos |
| App + panel | Misma API; coberturas distintas (ejemplo: inscripción anual en app) | En el producto |
| Auditoría | Parcial | En proceso |
| Logros gamificados | Fuera de canon de negocio | No vender |

### 8. Permisos

Nadie ve “todo” por título. El backend comprueba identidad, permiso, sección
o territorio, y vigencia del cargo.

**En el producto.** RBAC. Matriz contrastada en [05](05-matriz-roles-verificada.md)
(no es auditoría de grants de producción).

## Recorrido de una persona (historia para vender)

1. Se registra y pide Panteras · Conquistadores → queda pendiente.
2. La directiva aprueba. El sistema le asigna la clase del año por edad al
   inicio del ciclo.
3. Avanza requisitos, especialidades, tal vez una certificación.
4. Cada acto de reconocimiento lo decide un responsable (consejero, director,
   coordinador, campo, unión, según el circuito).
5. La sección informa el mes, arma la carpeta, va a camporee.
6. Campo y unión ven operación y pendientes de **su** territorio.
7. Al año siguiente la cuenta sigue; la inscripción y los cargos se
   resuelven de nuevo.

Esa historia **es** el producto. Los módulos de tesorería, inventario y
materiales la sostienen; no la reemplazan.

## Qué sí puedes afirmar en una venta

- Un solo sistema para trayectoria, operación de sección y supervisión.
- App para el club; panel para territorio y administración.
- El reconocimiento institucional no es automático: hay revisión.
- Unión y campo tienen vistas propias; no son el mismo rol que el director
  de club ni el administrador técnico.
- Hay un camino de implantación: piloto de secciones, no un interruptor
  nacional.

## Qué no debes afirmar

- “Ya está en toda la Unión / toda la Iglesia.”
- “El coordinador aprueba camporees.”
- “Unión cobra el camporee en la app.”
- “Subir la foto ya investe / ya puntúa el ranking.”
- “El informe mensual lo sella Unión.”
- “El SLA es el tablero del director de jóvenes.”
- Cifras de ahorro, adopción o uptime no medidas.
- Pedidos de mercancía e insumos de camporee como listos en el piloto
  actual (otra rama).
- Historial perfecto de todos los cambios de sección y unidad (hueco
  declarado).
- Operación 100 % sin red.

## Cómo usar esto para armar *tu* presentación

1. Portada y problema: sección “La oferta”.
2. Para quién: tabla de actores (elige 4–5, no los 8).
3. Recorrido de una persona: 5–7 pasos, una lámina de flujo.
4. Tres o cuatro bloques de valor: formación, operación de club, camporee,
   supervisión de Unión.
5. Una lámina de honestidad: “en implantación; el piloto acota secciones y
   procesos”.
6. Cierre: qué secciones, qué responsables, qué se ensaya primero.

El deck de 15 láminas cubre 1, 2, 5 y 6 con tono prudente. El de **venta de
producto completo** (19 láminas) ya está en
[presentacion/entrega/SACDIA-presentacion-venta-iglesia-2026-09-14.pptx](presentacion/entrega/SACDIA-presentacion-venta-iglesia-2026-09-14.pptx),
con [guía del expositor](presentacion/guia-expositor-venta.md). Reserva la
demo viva a lo ensayado en verde
([ensayo](presentacion/ensayo-cuentas-ficticias.md)).

## Relación con el resto del concentrado

| Necesitas | Ve a |
|---|---|
| Vender / diseñar láminas | Este archivo |
| No equivocarte en una demo | Fichas 06–13 y [guía](presentacion/guia-expositor.md) |
| Lista de módulos técnicos | [inventario-dominios.md](inventario-dominios.md) |
| Cita corta ya armada | [presentacion/README.md](presentacion/README.md) (PPTX de 15 láminas, congelado) |
| Venta de producto completo | [presentacion/entrega/SACDIA-presentacion-venta-iglesia-2026-09-14.pptx](presentacion/entrega/SACDIA-presentacion-venta-iglesia-2026-09-14.pptx) |

**Este mapa no reemplaza un piloto.** Describe cómo queda SACDIA para la
iglesia; la implantación se acuerda territorio por territorio.
