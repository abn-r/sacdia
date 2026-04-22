# SACDIA
## Sistema de Administración de Clubes de la División Interamericana

### Bases del Proyecto

**Documento de fundamentos, arquitectura, módulos funcionales y roadmap**

---

**Versión:** 1.0
**Fecha:** Abril 2026
**Alcance:** División Interamericana (DIA) — Ministerio Juvenil Adventista
**Clubes cubiertos:** Aventureros, Conquistadores y Guías Mayores

---

## Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Bloque 1 — Fundamentos y Visión](#2-bloque-1--fundamentos-y-visión)
3. [Bloque 2 — Arquitectura Jerárquica y Modelo de Datos](#3-bloque-2--arquitectura-jerárquica-y-modelo-de-datos)
4. [Bloque 3 — Módulos Funcionales](#4-bloque-3--módulos-funcionales)
5. [Bloque 4 — Roadmap y Criterios de Éxito](#5-bloque-4--roadmap-y-criterios-de-éxito)
6. [Apéndice A — Catálogo completo de módulos](#6-apéndice-a--catálogo-completo-de-módulos)
7. [Apéndice B — Glosario](#7-apéndice-b--glosario)

---

## 1. Resumen Ejecutivo

**SACDIA** (Sistema de Administración de Clubes de la División Interamericana) es una plataforma integral web + móvil diseñada para gestionar los clubes de Aventureros, Conquistadores y Guías Mayores a lo largo de toda la División Interamericana (DIA). El sistema toma como referencia el SGC (Sistema de Gestión de Clubes) de la División Sudamericana, y lo supera en arquitectura, experiencia de usuario, inteligencia y diferenciadores clave adaptados a la realidad trilingüe y multicultural de la DIA.

### Propuesta de valor

SACDIA se distingue del SGC en los siguientes aspectos fundamentales:

- **App móvil nativa real** (iOS/Android) separada del panel administrativo web.
- **Arquitectura modular API-first** en lugar del monolito PHP/Dart del SGC.
- **UX pensada para líderes voluntarios no técnicos**.
- **Trilingüe nativo** (español, inglés, francés).
- **Concepto de "secciones por club"** que refleja la realidad operativa real de los clubes DIA.
- **Reportes automáticos** generados por uso del sistema (no llenados manualmente).
- **Sistema de clasificación Bronce → Diamante** por puntuación anual.
- **Dashboards accionables** que generan tareas, no solo muestran datos.
- **Carpeta de Evidencias transversal** que elimina duplicación de subidas.
- **Tarjeta virtual con QR dinámico** verificable oficialmente.

### Alcance

- **Cobertura jerárquica**: División → Unión → Campo local → Iglesia → Club → Sección → Unidad.
- **Audiencias**: personal de División, Unión y Campo local (panel web); directivas de club, líderes, miembros y padres/tutores (app móvil).
- **Piloto inicial**: México.
- **Expansión planeada**: las 25 Uniones de la DIA.

### Estado actual del desarrollo

De los 29 módulos identificados, 10 están implementados, 7 en refinamiento y 12 por construir. El roadmap propone 4 fases de implementación, con la Fase 1 (MVP Fundacional) estimada en 3-6 meses desde el estado actual.

---

## 2. Bloque 1 — Fundamentos y Visión

### 2.1 Principios rectores del sistema

Los siguientes siete principios deben atravesar todas las decisiones de diseño y desarrollo del sistema:

**1. Jerarquía eclesiástica como espejo + concepto de secciones por club**

El sistema debe reflejar fielmente la estructura eclesiástica adventista: División → Unión → Campo local → Iglesia → Club → Sección (Aventureros/Conquistadores/Guías Mayores) → Unidad. Los permisos y la visibilidad se controlan estrictamente por nivel, con autorización cruzada entre secciones gestionada por el director de cada sección.

El concepto de "secciones por club" es una innovación clave: un club puede tener hasta tres secciones (una por rango etario), cada una con su propia directiva, pero unificadas bajo el nombre del club (por ejemplo, "Club Alfa y Omega" con sus secciones de Aventureros, Conquistadores y Guías Mayores). Esto refleja la realidad operativa real de los clubes iberoamericanos.

**2. Historia unificada de la persona**

Un único registro por persona que acumula su trayectoria completa a lo largo de su vida en la iglesia: fue Aventurero, luego Conquistador, después Guía Mayor, después líder investido. El sistema conserva el contexto y los logros por cada etapa sin duplicar la identidad de la persona.

Un miembro pertenece a una sola sección a la vez, excepto durante la transición entre Guía (última clase de Conquistadores) y Guía Mayor, donde temporalmente puede estar en ambas mientras completa el proceso.

**3. Trazabilidad total e inmutable**

Cada investidura, clase completada, especialidad lograda, logro obtenido, campamento asistido y transferencia entre clubes queda registrada con fecha, autoridad que la otorgó, evidencia documental y firma digital. La información es auditable a perpetuidad: un Guía Mayor investido en 2015 en Jamaica debe poder probarlo en 2030 desde México.

**4. Trilingüe nativo**

Español, inglés y francés como ciudadanos de primera clase desde el primer día, no traducciones añadidas. La DIA es la única división verdaderamente trilingüe del ministerio juvenil adventista mundial; el sistema debe reflejarlo desde el diseño, no como adaptación posterior.

**5. Offline selectivo en móvil**

Las funcionalidades básicas de consulta y captura ligera funcionan sin conexión; las funciones críticas que requieren validación del servidor exigen estar en línea. La UX debe ser clara sobre qué funciona en cada modo.

| Función | Offline | Online |
|---|---|---|
| Consulta de datos de miembros | ✓ | |
| Contactos de emergencia | ✓ | |
| Datos de salud | ✓ | |
| Calendario ya sincronizado | ✓ | |
| Tarjeta virtual (caché) | ✓ | |
| Registro de asistencia (cola) | ✓ | |
| Creación de actividades | | ✓ |
| Investiduras | | ✓ |
| Transferencias | | ✓ |
| Tesorería | | ✓ |
| Reportes oficiales | | ✓ |
| Aprobaciones directivas | | ✓ |

**6. Privacidad y protección de menores por diseño**

Cumplimiento con leyes locales (LOPD, GDPR donde aplique), políticas de Adventist Risk Management, consentimiento parental digital, no exposición de datos de menores en perfiles públicos, y control granular sobre qué información se comparte con quién.

**7. Perfil como tarjeta viva**

El perfil de cada miembro funciona como credencial digital dinámica que muestra datos personales, información médica, clases investidas, especialidades logradas, cargos ejercidos y logros acumulados. Es verificable mediante QR dinámico y oficialmente reconocida por la DIA.

### 2.2 Propuesta de valor diferenciada vs SGC

El siguiente cuadro identifica los 10 diferenciadores fundamentales del sistema, priorizados por impacto estratégico:

| # | Debilidad del SGC actual | Solución en SACDIA | Prioridad |
|---|---|---|---|
| 1 | Monolítico, PHP/Dart, 153 submódulos acoplados | Arquitectura modular de microservicios, API-first | **Alta** |
| 2 | UX densa y compleja (curva de aprendizaje alta) | Diseño UX centrado en el líder voluntario no técnico | **Alta** |
| 3 | Móvil limitado (web responsive, no app nativa) | App nativa iOS/Android con experiencia propia | **Alta** |
| 4 | Modelo de club uniforme sin secciones | Concepto nativo de secciones por club | **Fundacional** |
| 5 | Bilingüe (portugués/español) | Trilingüe nativo (español/inglés/francés) | **Alta** |
| 6 | Tarjeta virtual como imagen estática | Credencial digital verificable con QR dinámico | **Media-Alta** |
| 7 | Reportes como obligación burocrática | Dashboards en tiempo real con alertas accionables | **Alta** |
| 8 | Especialidades como lista plana | Sistema gamificado con rutas de aprendizaje y evidencia multimedia | **Media** |
| 9 | Sin IA ni automatización | Asistente IA para líderes (v2/v3) | **Aspiracional** |
| 10 | Comunicación fuera del sistema (WhatsApp paralelo) | A evaluar según valor real | **Evaluar** |

### 2.3 Identidad del sistema

**Nombre oficial:** SACDIA — Sistema de Administración de Clubes de la División Interamericana.

Este nombre institucional es apropiado para comunicaciones oficiales, registros formales y documentación. Opcionalmente, podría definirse un tagline o nombre corto más memorable para la app móvil de uso cotidiano por parte de líderes voluntarios.

### 2.4 Arquitectura técnica general

El sistema opera bajo una arquitectura de **dos clientes especializados conectados a un backend central vía REST API**:

```
                    ┌─────────────────────────────────┐
                    │       SACDIA — Ecosistema       │
                    └─────────────────────────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
     📱 APP MÓVIL                                     💻 PANEL WEB
      (iOS/Android)                                  (Administrativo)

     Usuarios:                                       Usuarios:
     • Directiva de club                             • Campo local
     • Líderes y consejeros                          • Unión
     • Miembros (perfil)                             • División
     • Padres (consentimientos)                      • Auditores y soporte
            │                                               │
            └───────────────────┬───────────────────────────┘
                                │
                         🔌 REST API
                       (Backend central)
                                │
                  ┌─────────────┼──────────────┐
                  │             │              │
          🗄 Base datos   📦 Multimedia   🔐 Auth/Permisos
                                │
                        🔔 Notificaciones
```

**Separación estratégica de audiencias:**

- La **app móvil** es la herramienta de operación diaria del club. Su audiencia son líderes en campo que necesitan agilidad, usabilidad y funcionalidad contextual.
- El **panel web** es la herramienta de administración, supervisión y analítica. Su audiencia son administradores en oficinas que necesitan densidad informativa, reportes y control jerárquico.

Esta separación es deliberada porque las necesidades cognitivas y ergonómicas de ambas audiencias son radicalmente distintas.

---

## 3. Bloque 2 — Arquitectura Jerárquica y Modelo de Datos

### 3.1 Jerarquía organizacional completa

SACDIA modela la estructura eclesiástica adventista de la siguiente manera:

```
División Interamericana (1 entidad raíz)
    │
    └── Uniones (25 entidades)  ej: ATCU, NOMU, JAMU, CORU...
            │
            └── Campos locales (Asociaciones/Misiones) (~200+)
                    │
                    ├── Distritos pastorales (relación de visualización)
                    │
                    └── Iglesias (miles)
                            │
                            └── Clubes (1 club por iglesia idealmente)
                                    │
                                    └── Secciones (hasta 3 por club)
                                            │
                                            ├── Directiva anual
                                            │
                                            └── Unidades (6-8 miembros c/u)
                                                    │
                                                    └── Miembros
```

**Puntos clave del modelo:**

- Una iglesia puede tener un solo club (regla adventista estándar), con excepciones autorizadas por el Campo local.
- Un club tiene de 1 a 3 secciones. No es obligatorio tener las tres.
- Cada sección tiene su propia directiva anual (Director, Subdirectores, Secretario, Tesorero o Secretario-Tesorero unificado, Capellán, Consejeros e Instructores).
- Solo las secciones de Aventureros y Conquistadores tienen unidades tradicionales. Guías Mayores se organiza en equipos de trabajo o comisiones.
- El **distrito pastoral** no es un nivel administrativo de edición: funciona como una relación de visualización. El pastor distrital ve información de los clubes de su distrito según lo configure el Campo local, y cumple rol de "verificador y canalizador" en el flujo específico de investiduras.
- El **Director General del Club** no es una figura separada: un director de sección que también dirige otras secciones asume de facto el rol coordinador, pero el sistema no lo modela como entidad aparte.

### 3.2 Modelo de permisos (quién ve y edita qué)

El modelo de permisos combina tres ejes:

#### Eje 1 — Nivel jerárquico

| Nivel | Alcance de lectura | Alcance de edición |
|---|---|---|
| División | Toda la DIA | Configuración global, plantillas maestras, aprobaciones de máximo nivel (GM Instructor) |
| Unión | Su unión completa | Aprobación de GM Máster, organización de camporees de unión, configuración del año eclesiástico |
| Campo local | Sus iglesias y clubes | Registro de clubes, investidura de GM, reportes consolidados, asignación de directores anuales |
| Distrito pastoral | Iglesias de su distrito (según config del Campo local) | Verificación y canalización de listas de investidura |
| Club (Director de sección) | Su sección completa | Miembros, directiva, clases, especialidades, asistencias |
| Directiva de sección | Su sección (lectura amplia) + funciones específicas | Según rol asignado (Secretario, Tesorero, Capellán, Instructor) |
| Consejero de unidad | Su unidad asignada | Asistencia, seguimiento de progresión |
| Miembro | Su propio perfil + actividades de su unidad/sección | Solo sus datos editables |
| Padre/Tutor | Perfil de sus hijos + consentimientos | Consentimientos, datos médicos de sus hijos |

#### Eje 2 — Rol funcional

Dentro de una sección coexisten roles funcionales con permisos distintos: Director, Subdirector, Secretario, Tesorero, Capellán, Instructor de especialidad, Consejero de unidad, etc. Cada uno tiene un subconjunto específico de capacidades.

#### Eje 3 — Multi-sección (caso especial)

Un líder puede tener permisos en varias secciones del mismo club si el director de cada sección lo autoriza. Técnicamente se modela como relación:

```
usuario_id + sección_id + rol + autorizado_por + fecha_inicio + fecha_fin
```

### 3.3 Entidades principales del modelo de datos

#### Entidades estructurales
- `divisions`, `unions`, `local_fields`, `pastoral_districts`, `churches`, `clubs`, `club_sections`, `units`

#### Entidades de personas
- `persons` — registro único de persona (historia unificada), identificado por UUID
- `memberships` — relaciones persona-sección-unidad con fechas de inicio y fin
- `roles` y `user_roles` — asignaciones por nivel jerárquico
- `guardians` y `guardian_relationships` — padres, tutores y sus vínculos

#### Entidades de progresión
- `progressive_classes` — catálogo maestro de clases
- `class_requirements` — requisitos por clase
- `class_investments` — investiduras otorgadas (inmutables)
- `specialties` — catálogo maestro de especialidades DIA
- `specialty_completions` — especialidades logradas
- `advanced_classes` y `masteries` — clases avanzadas y maestrías

#### Entidades de liderazgo
- `leadership_levels` — Guía Mayor, GM Avanzado, GM Instructor
- `leadership_investments` — con autoridad, fecha, vigencia, evidencia
- `leadership_courses` — cursos realizados (PDL JA, CGM, seminarios)
- `course_completions`

#### Entidades operativas
- `activities` — actividades calendarizadas
- `attendances` — asistencias por miembro y actividad
- `events` — camporees, campamentos, ceremonias
- `event_registrations`
- `transfers` — transferencias entre clubes
- `treasury_transactions`
- `insurance_enrollments`

#### Entidades transversales
- `media_evidence` — fotos, videos, documentos
- `digital_signatures` — firmas electrónicas
- `audit_log` — registro inmutable de acciones críticas
- `notifications` y `announcements`

### 3.4 Reglas de negocio transversales

Estas reglas aplican en todos los módulos:

1. **Inmutabilidad de investiduras.** Una vez investida una clase, no puede ser borrada ni editada. Solo puede anularse con justificación auditada por autoridad superior.

2. **Transferencias atómicas.** Al transferir un miembro entre clubes, se traslada su historia completa (clases, especialidades, asistencias). El registro original queda trazado: "perteneció a X desde Y hasta Z, se transfirió a W".

3. **Herencia de idioma.** Cada entidad (club, sección, iglesia) hereda el idioma principal de su Unión, pero cada usuario individual elige su idioma preferido.

4. **Seguro anual obligatorio.** El sistema bloquea inscripciones a eventos y ciertas actividades si el miembro no tiene seguro vigente.

5. **Protección de menores.** Datos sensibles de menores (foto, dirección, contacto) solo son visibles por directiva de la sección, padres/tutores y niveles jerárquicos superiores con justificación registrada.

6. **Validación de edad por sección.** El sistema valida automáticamente que la edad del miembro corresponda a su sección y sugiere promoción al cumplir edad de transición.

7. **Cascada de autoridad para investiduras.**
   - Clases progresivas → autoridad: Campo local (canalizado por el pastor distrital)
   - Guía Mayor → autoridad: Campo local
   - GM Máster → autoridad: Unión
   - GM Instructor → autoridad: División

   El sistema debe impedir que un nivel inferior otorgue una investidura que corresponde a uno superior.

8. **Identificación de duplicados.** Aunque cada persona tiene UUID único, el sistema aplica heurísticas (fecha de nacimiento + nombres + apellidos + país) para detectar posibles duplicados cuando un club registra un nuevo miembro, sugiriendo transferencia si corresponde.

9. **Año eclesiástico configurable por Unión.** Cada Unión define su propio año eclesiástico. Los Campos locales y clubes heredan esa configuración. Al cerrar el año, las directivas se archivan (no se borran) y se requiere nueva asignación para el siguiente año.

10. **Audit log obligatorio en acciones críticas.** Investiduras, transferencias, cambios en tesorería, altas/bajas de miembros, cambios de rol, aprobaciones y rechazos del Campo local quedan registrados permanentemente con usuario, acción, valores antes/después, fecha, IP y dispositivo.

### 3.5 Flujo de investidura (detalle operativo)

El flujo de investidura involucra cuatro actores jerárquicos y culmina en una ceremonia formal:

```
┌─────────────────────────────────────────────────────────────┐
│  1. CLUB (Director de sección)                               │
│     • Identifica candidatos a investir                       │
│     • Marca requisitos completados con evidencias            │
│     • Genera lista de candidatos por clase                   │
│     • Envía al Pastor del Distrito                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. PASTOR DEL DISTRITO (verificador y canalizador)          │
│     • Recibe notificación                                    │
│     • Verifica la lista y evidencias preliminarmente         │
│     • Canaliza al Campo local O devuelve con observaciones   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. CAMPO LOCAL (Coordinadores)                              │
│     • Reciben lista canalizada                               │
│     • Revisan evidencias, carpetas, actividades              │
│     • Aprueban o rechazan cada candidato                     │
│     • Fijan fecha de ceremonia                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  4. NOTIFICACIÓN A PADRES/TUTORES                            │
│     • Consentimiento digital para la ceremonia               │
│     • Confirmación de asistencia                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  5. CEREMONIA DE INVESTIDURA                                 │
│     • Fecha fija                                             │
│     • Autoridad del Campo local presente                     │
│     • Registro de asistentes el día de la ceremonia          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  6. SISTEMA (automático)                                     │
│     • Marca como "investido" a quienes asistieron            │
│     • Genera certificado digital firmado                     │
│     • Actualiza tarjeta virtual + historial                  │
│     • Registra todo en audit_log                             │
└─────────────────────────────────────────────────────────────┘
```

**Casos especiales:**
- Candidato ausente en la ceremonia → "no investido por ausencia", reprograma.
- Investidura de Guías Mayores → no pasa por pastor distrital, va directamente al nivel correspondiente (Campo local, Unión o División según el nivel de GM).
- Reinvestidura → si se perdió vigencia por 2 años de inactividad, requisitos reducidos.

---

## 4. Bloque 3 — Módulos Funcionales

Se identifican 29 módulos agrupados en 6 categorías funcionales. El estado actual (al momento de este documento) se indica con iconos: ✅ implementado, 🟡 en refinamiento, ❌ por construir, 🔮 aspiracional.

### 4.1 Categoría A — Identidad y Acceso

#### A1. Autenticación y gestión de cuentas ✅
Registro, login, recuperación de contraseña, verificación de identidad, gestión de sesiones.

#### A2. Roles y permisos jerárquicos ✅
Sistema de roles por nivel jerárquico + rol funcional + multi-sección. Aplicación granular de permisos por módulo y acción.

#### A3. Consentimientos de padres/tutores ❌
Crítico por la naturaleza del trabajo con menores. Incluye:
- Consentimiento general de membresía.
- Consentimiento para uso de imagen.
- Consentimientos específicos por actividad (caminatas, campamentos, viajes).
- Consentimiento para atención médica de emergencia.
- Firma digital desde el acceso del padre/tutor.
- Vigencias configurables (anuales o por actividad).
- Bloqueo de acciones si no hay consentimiento vigente.

#### A4. Auditoría (audit_log) ❌
Pieza central del sistema. Registra de forma permanente para eventos críticos:
- Usuario que actuó, acción, entidad afectada.
- Valores antes y después del cambio.
- Fecha, hora, IP, dispositivo.
- Retención permanente para: investiduras, transferencias, cambios de tesorería, altas/bajas, cambios de rol, aprobaciones/rechazos.
- Retención de 2 años para acciones operativas.
- Consulta limitada por nivel jerárquico.

### 4.2 Categoría B — Gestión de Personas

#### B1. Registro de miembros y fichas ✅
Registro completo con datos personales, médicos, de contacto y familiares. Fichas con foto y trazabilidad.

#### B2. Directivas de sección con ciclo anual 🟡
- El Campo local asigna al director del año eclesiástico en curso basándose en el informe del distrito sobre sus clubes.
- El director asigna su directiva: Subdirectores, Secretario, Tesorero (o Secretario-Tesorero unificado), Capellán, Consejeros, Instructores.
- Las asignaciones tienen validez solo durante el año eclesiástico.
- Al terminar el año, se archivan (no se borran) y se repite el proceso.
- Histórico visible: "Director del club X en 2024: A; en 2025: B".
- Período de transición configurable (ej. 30 días) para entrega de información.

#### B3. Historia unificada de la persona ✅
Secuencia de tablas que registran la trayectoria completa del miembro: especialidades logradas y en proceso, clases cursadas con evidencias y estado (completa/incompleta/investida/no investida), camporees asistidos, logros, promociones entre secciones (Aventureros → Conquistadores → Guías Mayores).

#### B4. Transferencias entre clubes ❌
- Director del club origen inicia la transferencia.
- Director del club destino valida y aprueba.
- Sistema ejecuta transferencia atómica de la historia completa.
- Registro en club origen: "transferido en fecha X a club Y".
- Validación de tesorería pendiente antes de transferir.

### 4.3 Categoría C — Progresión y Formación

#### C1. Clases progresivas ✅ (con ajustes pendientes)
- Catálogo maestro centralizado DIA (no por club).
- Estructura trilingüe.
- **Aventureros**: Corderitos, Aves Madrugadoras, Abejita Industriosa (6), Rayito de Sol (7), Constructor (8), Manos Ayudadoras (9).
- **Conquistadores**: Amigo (10), Compañero (11), Explorador (12), Orientador (13), Viajero (14), Guía (15).
- **Clases avanzadas paralelas** (pendientes de implementar): Amigo de la Naturaleza, Compañero de Excursionismo, Explorador de Campo, Pionero de Nuevas Fronteras, Excursionista en el Bosque, Guía de Exploración.
- Requisitos marcables como: completado / en proceso / no iniciado / no aplica.
- Evidencias vinculadas a la Carpeta de Evidencias anual.
- Validación automática de prerrequisitos entre clases (parcialmente implementado).
- Funcionalidades avanzadas: progreso visual con anillos, ruta de aprendizaje sugerida, estado bloqueado/desbloqueado, historial auditado por requisito, comparación con cohorte de unidad.

#### C2. Especialidades y maestrías ✅
- Catálogo maestro DIA con categorías por color distintivo:
  - Artes y Habilidades Manuales (celeste)
  - Actividades Misioneras (azul oscuro)
  - Estudio de la Naturaleza (verde)
  - Recreación al Aire Libre (verde claro)
  - Salud y Ciencia (gris/rojo)
  - Actividades Profesionales (rojo)
  - Actividades Domésticas (amarillo)
  - Actividades Agrícolas (marrón)
- Cada especialidad: nivel (principiante/intermedio/avanzado), edad mínima, requisitos específicos.
- Maestrías como agrupaciones: Experto Acuático, Maestría en Zoología, Maestría en Botánica, etc.
- Biblioteca de recursos por especialidad.
- Galería visual de banda de especialidades digital.

#### C3. Directorio de Instructores con agendamiento 🟡
Diferenciador fuerte vs SGC:
- Catálogo de instructores certificados con zona geográfica.
- Especialidades que cada instructor puede impartir (solo las que tiene certificadas).
- Disponibilidad y calendario.
- Agendamiento: el club solicita instructor para fecha específica.
- Validación automática de certificación antes de asignar.
- Histórico: cuántas veces ha impartido, cuántos aprobaron.
- Niveles de alcance: Campo local, Unión, o "circulante" DIA.

#### C4. Investiduras (flujo completo) 🟡
Ver flujo detallado en sección 3.5. Estado: flujo definido y parcialmente implementado; requiere completar integración con Pastor distrital, ceremonia, certificados digitales y actualización automática de tarjeta virtual.

#### C5. Guías Mayores (reutiliza módulo de clases) ✅
El sistema reutiliza el módulo de clases progresivas para los seminarios de GM, modelando los requisitos especiales (proyecto misionero, lecturas obligatorias, seminarios) como tipos de requisito. Se valida:
- Prerrequisito: haber sido investido como Guía.
- Escalamiento de autoridad por nivel (GM → Campo local; GM Máster → Unión; GM Instructor → División).
- Vigencia y revalidación por 2 años de inactividad.
- Alerta con 6 meses de anticipación al vencimiento.
- Directorio público de GM activos.

#### C6. Tarjeta virtual + QR dinámico 🟡
- Perfil funciona como credencial digital viva.
- Visibilidad granular:
  - **Público dentro del club**: nombre, foto, sección, clases, especialidades, logros.
  - **Directiva + padres**: datos médicos, contactos de emergencia, dirección.
  - **Solo directiva autorizada**: información altamente sensible.
- **QR dinámico**: se regenera periódicamente; al escanearse con la app SACDIA por otro líder, muestra la credencial verificada. Los escaneadores con permisos superiores ven información adicional.
- Usos del QR: check-in en camporees, verificación de GM en actividades, acceso a zonas restringidas, confirmación de identidad en transferencias.

### 4.4 Categoría D — Operación del Club

#### D1. Actividades y calendario ✅
- Actividades por sección con posibilidad de actividades conjuntas entre secciones del mismo club.
- Calendario anual.
- Ubicaciones y logística.
- Tipos configurables: reunión semanal, caminata, proyecto comunitario, clase especial, ensayo de marcha, ceremonia.
- Vinculación de actividades a requisitos de clase o especialidad.
- Registro automático de evidencia (fotos subidas se asocian a la Carpeta anual).
- RSVP de padres para menores.
- Recordatorios automáticos.

#### D2. Asistencias + Miembro del Mes ✅
- Registro semanal por unidad.
- Rubros configurables por Campo local: asistencia, uniforme completo, devocional personal, Biblia, puntualidad, comportamiento, etc.
- Cálculo automático del **Miembro del Mes** por sección.
- Histórico guardado en registro del club.
- Reconocimiento visual: miembro del mes destacado en tarjeta virtual, dashboard y galería de logros.
- Modos de captura: manual o por QR dinámico.
- Tipos de asistencia: presente, ausente, justificado, tardanza.
- Alertas automáticas ante 3 ausencias consecutivas.
- Correlación con requisitos que exigen mínimo de asistencia.

#### D3. Eventos ✅
Gestión de camporees, campamentos y ceremonias oficiales con todos sus atributos: fechas, ubicación, organizador, niveles participantes.

#### D4. Inscripciones a eventos 🟡
Doble vertiente:
- **Campo local**: determina qué secciones de clubes pueden ver e inscribirse.
- **Unión**: determina qué secciones de todos los Campos locales pueden ver e inscribirse.

Refinamientos:
- Prerrequisitos configurables (edad, clase mínima investida, seguro vigente, pagos al día).
- Cupos totales y por club/sección.
- Estados: pre-inscrito → pago realizado → confirmado → asistió/ausente.
- Documentos requeridos (permiso parental, certificado médico) vinculados a Carpeta anual.
- Inscripción por cohorte (club completo), no uno a uno.
- Check-in el día del evento vía QR dinámico.

#### D5. Carpeta de Evidencias (módulo transversal) ❌
Diferenciador muy fuerte vs SGC. Una carpeta por sección-año eclesiástico que acumula todas las evidencias del año y es accesible desde clases, especialidades, eventos, investiduras y actividades.

Estructura:
```
Carpeta de Evidencias [Club X — Sección Y — Año 2026]
├── Evidencias de Clases
├── Evidencias de Especialidades
├── Evidencias de Actividades
├── Documentos Oficiales (actas, consentimientos, pólizas, certificados médicos)
└── Evidencias para Investidura (generadas automáticamente enlazando anteriores)
```

Funcionalidades clave:
- **Subida única, uso múltiple**: una foto se etiqueta para varios usos sin duplicarse.
- Permisos granulares por nivel jerárquico.
- Compresión automática de fotos, límites configurables.
- Export automático para paquete de investidura.
- Archivo anual al cerrar el año eclesiástico.

### 4.5 Categoría E — Finanzas

#### E1. Tesorería del club ✅
- Ingresos: cuotas, aportaciones, ingresos de eventos, donativos.
- Egresos: compras, inscripciones, pagos a instructores, materiales.
- Balance en tiempo real por club y por sección.
- Comprobantes digitales vinculados a transacciones.
- Registro por administradores del Campo local (ya que los pagos se reciben en oficinas del Campo local).

#### E2. Seguro anual ✅
- Pólizas por miembro, directiva, cocineros y apoyos.
- Alertas a 30, 15 y 5 días de vencimiento.
- Bloqueo de inscripciones a eventos de alto riesgo sin seguro vigente.
- Histórico por año eclesiástico.

#### E3. Pagos en línea ❌ (fuera de MVP)
- Para Fase 3. En MVP se registran pagos recibidos en oficinas del Campo local.
- El modelo de datos del MVP contempla `payment_methods` y `payment_gateways` para integraciones futuras.
- Recibos digitales automáticos generados por el sistema al registrar pagos.

#### E4. Reportes financieros ❌
- Mensuales, trimestrales y anuales por club.
- Consolidación automática a Campo local, Unión y División.
- Exportación a Excel/PDF.
- Comparativos año contra año.
- Desglose por sección.

### 4.6 Categoría F — Inteligencia y Comunicación

#### F1. Dashboards (3 tipos) 🟡

**Dashboard Operativo** (directiva del club):
- Próximas actividades de la semana.
- Miembros con ausencias recientes.
- Pagos pendientes.
- Evidencias pendientes.
- Cumpleaños del mes.
- Miembro del mes destacado.

**Dashboard Analítico** (Campo local, Unión, División):
- Número de miembros por club/sección/categoría.
- Tasa de finalización de clases.
- Especialidades más populares.
- Cobertura del Ministerio Joven en el territorio.
- Comparativos año contra año.
- Crecimiento/decrecimiento de clubes activos.

**Dashboard de Alertas Accionables** (todos los niveles):

*Nivel club:* directiva no asignada al iniciar año, miembros con 3+ ausencias, evidencias faltantes, consentimientos por vencer, actividades sin confirmación.

*Nivel miembro:* seguro personal por vencer, requisitos próximos al cumplimiento, especialidades sugeridas, cambios de datos personales.

*Nivel Campo local:* clubes con reportes pendientes, candidatos a investidura pendientes de revisión, pastores con listas pendientes, eventos con cupo por agotarse, recordatorios de actividades oficiales.

*Nivel Unión y División:* Campos locales con bajo cumplimiento, tendencias anómalas, próximos camporees con inscripciones bajas.

#### F2. Reportes mensuales automáticos del club ❌
Pieza central del sistema. Corazón del modelo de "reportes como consecuencia natural del uso del sistema":
- El reporte mensual se genera automáticamente con los datos del mes: actividades realizadas, reuniones regulares, especialidades logradas, actividades misioneras y de evangelismo, ingresos y egresos.
- El director del club solo valida y envía. Un clic.
- Cada reporte completado contribuye al puntaje anual que determina la clasificación del club.

#### F3. Sistema de Clasificación y Puntuación de Clubes ❌
Diferenciador clave vs SGC. Clasificación progresiva con metales y gemas:

| Nivel | Rango sugerido | Color | Significado |
|---|---|---|---|
| Bronce | 0–199 pts | Marrón dorado | Club iniciando |
| Plata | 200–399 pts | Gris plateado | Club establecido |
| Oro | 400–599 pts | Dorado | Club consolidado |
| Esmeralda | 600–799 pts | Verde profundo | Club destacado |
| Platino | 800–949 pts | Platino brillante | Club de excelencia |
| Diamante | 950–1000 pts | Blanco brillante | Club de élite |

Fórmula ponderada (sugerida, calibrable):

| Componente | Peso |
|---|---|
| Cumplimiento de reportes mensuales | 25% |
| Actividades realizadas | 15% |
| Clases investidas | 15% |
| Especialidades logradas por miembro | 10% |
| Evidencias cargadas | 10% |
| Asistencia a camporees y eventos | 10% |
| Proyectos misioneros y evangelismo | 10% |
| Uso activo del sistema | 5% |

Clasificación histórica por año eclesiástico permite ver la trayectoria del club: "Club X: 2024 Oro → 2025 Esmeralda → 2026 Platino".

Conecta simbólicamente con las 12 piedras preciosas de la Nueva Jerusalén que memorizan los Guías, dándole identidad bíblica al sistema.

#### F4. Reportes oficiales automáticos a niveles superiores ❌
Diferenciador muy fuerte vs SGC:
- Reportes trimestrales/semestrales/anuales generados automáticamente.
- Del club al Campo local; del Campo local a la Unión; de la Unión a la División.
- Plantillas de formato oficial DIA configurables.
- El director solo valida y envía.
- Historial completo de reportes enviados y quién los validó.

#### F5. Notificaciones ❌
- Push notifications (app móvil).
- Email (contactos registrados).
- Centro de notificaciones dentro de la app.
- Tipos: operativas, administrativas, de alerta.
- Segmentación por audiencia.
- Preferencias configurables por usuario.

#### F6. Configuración del año eclesiástico por Unión ❌
- Cada Unión define fecha de inicio y fin de su año eclesiástico.
- Los Campos locales y clubes heredan la configuración.
- Sistema gestiona automáticamente archivado de directivas y apertura de nuevas asignaciones.

#### F7. Asistente IA para líderes 🔮 (aspiracional)
- Sugerencia de planificación semanal.
- Generación de devocionales personalizados por edad.
- Resumen automático de actividades.
- Chatbot de soporte para directivas nuevas.
- Recomendador de especialidades.
- Análisis predictivo de riesgo de abandono.

**Nota:** Esta fase requiere validación con el cliente antes de comprometerse.

### 4.7 El bucle virtuoso del sistema

Un aspecto central del diseño de SACDIA es el **bucle virtuoso** que motiva el uso consistente del sistema:

```
Usar el sistema diariamente
          │
          ▼
Datos se capturan automáticamente
          │
          ▼
Reporte mensual se genera solo
          │
          ▼
Puntuación se calcula automáticamente
          │
          ▼
Clasificación del club sube de nivel
          │
          ▼
Prestigio y reconocimiento
          │
          ▼
Motivación para usar más el sistema
          │
          └─────────► (vuelve al inicio)
```

Esto convierte a SACDIA en gamificación aplicada al ministerio sin perder seriedad institucional. Es uno de los diferenciadores más poderosos frente al SGC.

---

## 5. Bloque 4 — Roadmap y Criterios de Éxito

### 5.1 Estrategia de priorización

Los 29 módulos se priorizan aplicando tres criterios:

1. **Base fundacional**: ¿este módulo es prerrequisito de otros?
2. **Impacto en el usuario**: ¿cuánto valor entrega al club desde el día 1?
3. **Complejidad de implementación**: ¿qué tanto esfuerzo requiere?

Se prioriza lo que tiene alta base + alto impacto + complejidad baja/media.

### 5.2 Fases de implementación

#### Fase 1 — MVP Fundacional (piloto en México)

**Objetivo:** un club opera completamente en el sistema con flujo esencial de principio a fin.

**Módulos incluidos:**

*Base crítica:* Autenticación y roles, Directivas con ciclo anual, Registro de miembros, Historia unificada, Configuración de año eclesiástico por Unión, Auditoría, Consentimientos parentales básicos.

*Progresión:* Clases progresivas (con clases avanzadas paralelas y validación de prerrequisitos), Especialidades, Investiduras (flujo completo), Guías Mayores (reutilizando módulo).

*Operación:* Actividades y calendario, Asistencias + Miembro del Mes, Eventos, Inscripciones a eventos, Carpeta de Evidencias.

*Financiero básico:* Tesorería (registro en oficina del Campo local), Seguro anual.

*Perfil:* Tarjeta virtual con visibilidad granular (QR dinámico opcional en esta fase).

*Comunicación:* Notificaciones básicas (push y email).

**Criterio de éxito:** un club en México puede registrar su directiva anual, agregar miembros con consentimiento parental, programar actividades, registrar asistencia, avanzar en clases y especialidades con evidencias, completar el flujo de investidura de principio a fin, llevar tesorería básica y recibir notificaciones relevantes.

**Tiempo estimado:** 3 a 6 meses desde el estado actual.

#### Fase 2 — Inteligencia y Escalabilidad

**Objetivo:** convertir SACDIA en un sistema inteligente que genera valor automático a los niveles superiores.

**Módulos incluidos:**
- Reportes mensuales automáticos del club.
- Sistema de Clasificación Bronce → Diamante.
- Dashboards accionables (los 3 tipos).
- Reportes oficiales automáticos.
- Transferencias entre clubes.
- Directorio de Instructores con agendamiento.
- QR dinámico en tarjeta virtual (si no entró en Fase 1).

**Criterio de éxito:** los clubes ya no llenan reportes manualmente; cada club ve su puntuación y clasificación en tiempo real; el Campo local tiene dashboards con clubes ordenados por nivel; los coordinadores identifican clubes con problemas antes de que escalen; las transferencias de miembros son fluidas.

**Tiempo estimado:** 6 a 9 meses después de Fase 1.

#### Fase 3 — Expansión y Enriquecimiento

**Objetivo:** internacionalización completa y funcionalidades avanzadas que consoliden SACDIA como estándar DIA.

**Módulos incluidos:**
- Trilingüe completo (inglés y francés si en Fase 1 se trabajó solo español).
- Reportes financieros avanzados.
- Pagos en línea (integración con pasarelas por país).
- Gamificación avanzada de especialidades.
- Galerías visuales enriquecidas.
- Post-evento: evaluaciones y galerías compartidas.
- Alertas predictivas (detección de clubes con riesgo de abandono).
- Expansión a otras Uniones fuera de México.

**Criterio de éxito:** SACDIA operando en al menos 5 Uniones de la DIA; pagos en línea activos en países grandes; sistema completamente trilingüe.

**Tiempo estimado:** 9 a 12 meses después de Fase 2.

#### Fase 4 — Asistente IA y Automatización Inteligente (a validar con cliente)

**Objetivo:** llevar SACDIA al siguiente nivel con IA como asistente del líder voluntario.

**Módulos aspiracionales:**
- Asistente IA para líderes.
- IA para padres/tutores.
- Análisis predictivo de riesgo.
- Recomendador de especialidades personalizado.
- Coach virtual de Guías Mayores.

**Nota importante:** el alcance de esta fase debe validarse con el cliente antes de cualquier compromiso.

### 5.3 Tabla consolidada del roadmap

| Módulo | Fase 1 | Fase 2 | Fase 3 | Fase 4 |
|---|---|---|---|---|
| Autenticación y roles | ✓ | | | |
| Directivas con ciclo anual | ✓ | | | |
| Registro de miembros | ✓ | | | |
| Historia unificada | ✓ | | | |
| Año eclesiástico por Unión | ✓ | | | |
| Auditoría | ✓ | | | |
| Consentimientos parentales | básico | | avanzado | |
| Clases progresivas | ✓ | | | |
| Clases avanzadas paralelas | ✓ | | | |
| Especialidades | ✓ | | gamificada | |
| Investiduras | ✓ | | | |
| Actividades y calendario | ✓ | | | |
| Asistencias + Miembro del Mes | ✓ | | | |
| Eventos | ✓ | | post-evento | |
| Inscripciones a eventos | ✓ | | | |
| Carpeta de Evidencias | ✓ | | | |
| Tesorería | básica | | | |
| Seguro anual | ✓ | | | |
| Tarjeta virtual | ✓ | + QR | | |
| Notificaciones | básicas | | | |
| Reportes mensuales automáticos | | ✓ | | |
| Clasificación Bronce → Diamante | | ✓ | | |
| Dashboards (3 tipos) | | ✓ | | |
| Reportes oficiales automáticos | | ✓ | | |
| Transferencias entre clubes | | ✓ | | |
| Directorio de Instructores | | ✓ | | |
| Trilingüe completo | | | ✓ | |
| Reportes financieros avanzados | | | ✓ | |
| Pagos en línea | | | ✓ | |
| Asistente IA | | | | ✓ |

### 5.4 Criterios de éxito del proyecto

El éxito de SACDIA se mide en cinco dimensiones:

**1. Adopción**
- Número de clubes activos en el sistema.
- Porcentaje de clubes del Campo local piloto usándolo.
- Usuarios activos mensualmente.

**2. Calidad operativa**
- Porcentaje de reportes mensuales enviados a tiempo.
- Porcentaje de clases completadas con evidencia digital.
- Porcentaje de investiduras procesadas sin errores.

**3. Diferenciación vs SGC**
- Tiempo promedio de llenado de reporte (SACDIA debe ser 5-10x más rápido).
- Satisfacción de líderes voluntarios (encuesta NPS).
- Tasa de abandono del sistema (baja).

**4. Impacto institucional**
- Reducción de carga administrativa para el Campo local.
- Mejora en trazabilidad de investiduras.
- Cumplimiento de protección de menores.

**5. Sostenibilidad**
- Costos de infraestructura por club.
- Tiempo de soporte técnico requerido.
- Velocidad de incorporación de nuevos clubes.

### 5.5 Riesgos principales y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Resistencia al cambio de líderes tradicionales | Capacitación gradual, soporte presencial en Fase 1, materiales en video cortos |
| Diversidad lingüística y cultural de la DIA | Trilingüe desde diseño, validación con Uniones piloto antes de escalar |
| Protección de datos de menores | Diseño alineado con Adventist Risk Management, consentimientos robustos, auditoría permanente |
| Conectividad intermitente en zonas rurales | Offline selectivo bien definido y comunicado en la UX |
| Escalabilidad técnica | Arquitectura de microservicios, API-first, pruebas de carga regulares |
| Adopción por autoridades eclesiásticas | Alineación con DIA desde el inicio, piloto con Unión dispuesta, involucramiento de directores JM |
| Mantenimiento a largo plazo | Documentación técnica rigurosa, equipo técnico adventista, consideración de código abierto intraiglesia |
| Competencia con SGC si la DSA lo ofreciera a DIA | Diferenciadores claros, identidad DIA propia, valor nativo imposible de igualar con adaptaciones |
| Dependencia excesiva de un desarrollador | Documentación detallada, transferencia de conocimiento, diversificación del equipo |
| Cambios regulatorios en protección de datos | Monitoreo legal por país, actualizaciones periódicas de cumplimiento |

---

## 6. Apéndice A — Catálogo completo de módulos

Estado a la fecha del documento:

| # | Categoría | Módulo | Estado |
|---|---|---|---|
| 1 | A. Identidad | Autenticación y gestión de cuentas | ✅ |
| 2 | A. Identidad | Roles y permisos jerárquicos | ✅ |
| 3 | A. Identidad | Consentimientos de padres/tutores | ❌ |
| 4 | A. Identidad | Auditoría (audit_log) | ❌ |
| 5 | B. Personas | Registro de miembros y fichas | ✅ |
| 6 | B. Personas | Directivas de sección con ciclo anual | 🟡 |
| 7 | B. Personas | Historia unificada de la persona | ✅ |
| 8 | B. Personas | Transferencias entre clubes | ❌ |
| 9 | C. Progresión | Clases progresivas | ✅ |
| 10 | C. Progresión | Clases avanzadas paralelas | ❌ |
| 11 | C. Progresión | Especialidades y maestrías | ✅ |
| 12 | C. Progresión | Directorio de Instructores | 🟡 |
| 13 | C. Progresión | Investiduras (flujo completo) | 🟡 |
| 14 | C. Progresión | Guías Mayores (reutiliza módulo) | ✅ |
| 15 | C. Progresión | Tarjeta virtual | 🟡 |
| 16 | C. Progresión | QR dinámico | ❌ |
| 17 | D. Operación | Actividades y calendario | ✅ |
| 18 | D. Operación | Asistencias + Miembro del Mes | ✅ |
| 19 | D. Operación | Eventos | ✅ |
| 20 | D. Operación | Inscripciones a eventos | 🟡 |
| 21 | D. Operación | Carpeta de Evidencias | ❌ |
| 22 | E. Finanzas | Tesorería del club | ✅ |
| 23 | E. Finanzas | Seguro anual | ✅ |
| 24 | E. Finanzas | Pagos en línea | ❌ |
| 25 | E. Finanzas | Reportes financieros | ❌ |
| 26 | F. Inteligencia | Dashboards (3 tipos) | 🟡 |
| 27 | F. Inteligencia | Reportes mensuales automáticos | ❌ |
| 28 | F. Inteligencia | Clasificación Bronce → Diamante | ❌ |
| 29 | F. Inteligencia | Reportes oficiales automáticos | ❌ |
| 30 | F. Inteligencia | Notificaciones | ❌ |
| 31 | F. Inteligencia | Configuración año eclesiástico | ❌ |
| 32 | F. Inteligencia | Asistente IA para líderes | 🔮 |

**Resumen del estado:**
- ✅ Implementado: 11 módulos
- 🟡 En refinamiento: 6 módulos
- ❌ Por construir: 14 módulos
- 🔮 Aspiracional: 1 módulo

---

## 7. Apéndice B — Glosario

**Año eclesiástico:** período anual definido por cada Unión de la DIA durante el cual tienen vigencia las directivas asignadas y se acumulan puntos para la clasificación del club.

**Campo local:** Asociación o Misión adventista. Nivel jerárquico entre la Unión y la iglesia local.

**Carpeta de Evidencias:** módulo transversal del sistema que acumula en una sola ubicación todas las evidencias de un año eclesiástico para una sección de un club.

**Clase progresiva:** cada uno de los niveles formativos por edad que atraviesan los miembros de Aventureros y Conquistadores.

**Directiva de sección:** conjunto de líderes asignados anualmente a una sección de un club (Director, Subdirectores, Secretario, Tesorero, Capellán, etc.).

**División Interamericana (DIA):** sección regional de la Iglesia Adventista Mundial que abarca 42 países de México, Centroamérica, Caribe y norte de Sudamérica con 25 Uniones.

**División Sudamericana (DSA):** sección regional paralela a la DIA que abarca 8 países de Sudamérica con 16 Uniones. Creadora del SGC.

**Guía Mayor (GM):** nivel de liderazgo investido que capacita para dirigir clubes. Tiene tres niveles: GM, GM Avanzado y GM Instructor.

**Investidura:** ceremonia formal en la que una persona es reconocida oficialmente por haber completado una clase progresiva o un nivel de liderazgo.

**Pastor distrital:** pastor responsable pastoralmente de varias iglesias en un distrito. En SACDIA cumple rol de verificador y canalizador en el flujo de investiduras.

**Sección:** subdivisión de un club por rango etario. Un club puede tener hasta tres secciones: Aventureros (6-9), Conquistadores (10-15) y Guías Mayores (16+).

**SGC (Sistema de Gestión de Clubes):** sistema de la División Sudamericana que SACDIA toma como referencia para superarlo.

**Tarjeta virtual:** perfil digital de cada miembro que funciona como credencial verificable, con visibilidad granular y QR dinámico.

**Unidad:** grupo pequeño (6-8 miembros) dentro de una sección, con capitán, subcapitán, secretario y consejero adulto.

**Unión:** agrupación de Campos locales en una región geográfica. La DIA tiene 25 Uniones.

---

**Fin del documento.**

*Este documento constituye la base formal del proyecto SACDIA. Su propósito es servir como referencia contra la cual contrastar el desarrollo actual, identificar brechas funcionales, planificar iteraciones y alinear expectativas con el cliente institucional.*
