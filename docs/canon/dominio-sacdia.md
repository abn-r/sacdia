# Modelo del dominio

## Estado

ACTIVE

## Propósito del documento

Este documento define el lenguaje oficial, los conceptos centrales y las reglas de interpretación del dominio de SACDIA. Su función es disciplinar cómo se entienden miembros, clubes, secciones, procesos formativos, validaciones, responsabilidades y autoridad institucional.

El modelo del dominio manda en semántica e interpretación documental. Ningún endpoint, tabla, permiso, pantalla o documento técnico puede redefinir los conceptos establecidos aquí.

## Alcance del modelo

SACDIA modela la trayectoria institucional de las personas y la operación institucional de clubes y secciones dentro del ecosistema del Ministerio Juvenil Adventista. El dominio cubre miembros, clubes, secciones de club, tipos de club, jerarquía organizacional, periodos operativos, vinculaciones, cargos, procesos formativos y validaciones.

Este documento no define detalles de implementación técnica, autenticación, estructura de base de datos, endpoints ni interfaces. Esos elementos pueden mapearse a este modelo, pero no lo sustituyen.

## Principios del modelo

### La trayectoria es el eje del sistema

SACDIA existe para preservar, operar y dar trazabilidad a la trayectoria institucional del miembro a lo largo del tiempo.

### El club es la raíz institucional

El club es la entidad institucional base con identidad, continuidad y pertenencia dentro de la estructura organizacional.

### La sección es la unidad operativa real

La operación concreta del sistema vive principalmente en la sección de club. Allí se organizan membresía, responsabilidades, procesos y actividad, aunque ciertas lecturas agregadas existan a nivel club.

### El tipo de club clasifica; la sección ejecuta

El tipo de club define el marco institucional y formativo. La sección de club expresa su realización operativa dentro de un club específico.

### La pertenencia es contextual e histórica

La participación institucional de una persona se interpreta mediante una vinculación contextual dentro de una estructura y un periodo, no como pertenencia plana al club.

### El tiempo es estructural

La operación del dominio se organiza por ciclos institucionales. El tiempo no es metadato decorativo; forma parte de la semántica del sistema.

### Registrar no equivale a validar

Un registro operativo puede existir sin reconocimiento institucional formal. La validación es un acto distinto.

### La jerarquía organizacional define alcance y autoridad

La autoridad institucional depende de una estructura jerárquica explícita que determina supervisión, alcance y capacidad de validación.

### El lenguaje técnico no redefine el dominio

Los nombres usados en runtime, base de datos o API deben mapearse al modelo del dominio. No pueden imponerse sobre él.

## Vocabulario canónico

### Miembro

Persona cuya trayectoria institucional es registrada por SACDIA.

### Club

Entidad institucional base con identidad y continuidad organizacional.

### Sección de club

Unidad operativa de un club para un tipo de club específico.

### Tipo de club

Clasificación institucional que define el marco formativo y operativo de una sección.

### Trayectoria

Continuidad histórica, institucional y verificable del miembro a lo largo del tiempo.

### Vinculación institucional

Relación contextual entre una persona y una estructura institucional durante un periodo operativo.

### Periodo operativo

Marco temporal institucional en el que se organiza membresía, cargos, procesos y actividad.

### Proceso formativo

Camino estructurado de avance institucional del miembro dentro de una sección.

### Validación

Acto institucional mediante el cual un registro, avance o resultado recibe reconocimiento formal.

### Catálogo de trayectoria

Dato de referencia que soporta la operación y trazabilidad de la trayectoria del miembro. Incluye alergias, enfermedades, medicamentos, tipos de relación, ideales de club, años eclesiásticos, categorías de honores y otros catálogos operativos necesarios para registrar, clasificar y contextualizar la información institucional del miembro.

### Seguro institucional

Registro asociado a la trayectoria del miembro que documenta la cobertura de seguros vinculada a su participación institucional (actividades generales, camporees, actividades de alto riesgo). Forma parte de la dimensión administrativa de la trayectoria.

### Cargo

Responsabilidad institucional ejercida por una persona en un contexto y periodo determinados.

### Jerarquía organizacional

Estructura institucional de pertenencia, supervisión, autoridad y alcance.

## Términos no canónicos o restringidos

### instance

Término técnico evitado como nombre principal del dominio. El término canónico es `Sección de club`.

### user

Término técnico de implementación. En dominio debe usarse `Miembro` cuando se hable del sujeto institucional.

### approved

No debe usarse como equivalente automático de `Validado` sin contexto institucional explícito.

### active

No debe usarse sin contexto. Debe aclararse si se habla de club, sección, vinculación, cargo, periodo o registro.

### club_type usado como unidad operativa

`Tipo de club` clasifica, pero no reemplaza a la sección como unidad operativa viva.

### role o assignment como sustituto conceptual

Términos técnicos de runtime no deben sustituir `Cargo` o `Vinculación institucional` en el plano del dominio.

## Entidades núcleo

### Miembro

El miembro es el sujeto principal del dominio. Sobre él recaen trayectoria, participación, avance formativo, responsabilidades y validaciones.

### Club

El club es la entidad institucional madre. Conserva identidad, continuidad y pertenencia dentro de la jerarquía organizacional.

### Sección de club

La sección de club es la unidad operativa real del sistema. Cada sección pertenece a un solo club, representa un solo tipo de club y concentra la operación concreta de ese tipo dentro del club.

### Trayectoria

La trayectoria es la continuidad histórica e institucional del miembro. Integra cambios de sección, rol, etapa, periodo y validación sin romper identidad.

## Estructuras de contexto

### Tipo de club

En el estado actual del sistema, los tipos de club incluyen Aventureros, Conquistadores y Guías Mayores. Cada tipo define reglas formativas y operativas específicas.

### Jerarquía organizacional

La jerarquía organizacional define la estructura de pertenencia, supervisión y autoridad institucional del sistema. En el estado actual verificado de SACDIA, esta cadena incluye país, unión, campo local, distrito, iglesia y club.

La forma exacta de la cadena puede evolucionar en implementación, pero el principio canónico es que la autoridad y el alcance dependen de una estructura jerárquica explícita.

### Periodo operativo

El periodo operativo es el marco temporal dentro del cual una sección organiza membresía, cargos, procesos, actividades y validaciones. En el estado actual del sistema, este concepto se expresa principalmente a través del ciclo anual o año eclesiástico.

El periodo operativo es condición de lectura del estado vigente y del historial, no solo una referencia de archivo.

## Relaciones estructurales

### Vinculación institucional

La vinculación institucional es la relación contextual entre una persona y una estructura institucional durante un periodo operativo. Es la forma principal de interpretar participación, pertenencia y continuidad del miembro dentro del sistema.

No toda vinculación implica proceso formativo. Una vinculación puede expresar formación, liderazgo, apoyo u otra modalidad institucional legítima.

### Vinculación a sección

La vinculación más importante del dominio es la vinculación a una sección de club. A través de ella se entienden membresía operativa, liderazgo, participación y contexto histórico.

### Tipo de vinculación

El tipo de vinculación describe el modo de participación de una persona. Como base mínima, el dominio debe distinguir entre participación formativa, liderazgo y apoyo.

### Estado de vinculación

El estado de vinculación expresa la situación del vínculo en el tiempo. Debe distinguir, al menos, entre activo, cerrado, suspendido o pendiente de formalización.

### Cargo

El cargo expresa una responsabilidad institucional dentro de un contexto y un periodo. Complementa la vinculación, pero no la reemplaza.

## Procesos institucionales

### Proceso formativo

El proceso formativo organiza el avance institucional del miembro dentro de una sección. Incluye etapas, requisitos, clases, actividades y resultados reconocibles.

Su interpretación depende del tipo de club y del periodo operativo en el que ocurre.

### Regla de edad y etapa

La relación entre miembro y proceso formativo no depende solo de la edad biológica, sino del contexto del periodo operativo. En el estado actual documentado, la clase se determina por la edad al inicio del año eclesiástico y no cambia durante ese ciclo.

### Investidura

La investidura es un acto institucional de reconocimiento asociado al cierre exitoso de una etapa o proceso formativo. Según el proceso aplicable, puede funcionar como reconocimiento final posterior a una validación o como parte del mismo circuito institucional de reconocimiento.

### Validación

La validación es el acto institucional mediante el cual un registro o avance recibe reconocimiento formal. El dominio distingue entre captura operativa, revisión institucional y resultado validado.

### Efectos de validación

Cuando un registro entra a validación, deja de ser completamente editable y pasa a una fase institucional de revisión. Si es aprobado, adquiere reconocimiento formal. Si es rechazado, vuelve a estado corregible según el proceso aplicable.

## Reglas semánticas

- `Club` y `Sección de club` no son sinónimos.
- `Tipo de club` clasifica la sección, pero no opera por sí solo.
- `Miembro` y `Usuario` no son equivalentes.
- Pertenecer implica una `Vinculación institucional` contextual.
- `Cargo` no sustituye a la `Vinculación institucional`.
- `Registrar` no equivale a `Validar`.
- Lo consolidado a nivel club no debe perder trazabilidad hacia la sección de origen.
- La jerarquía organizacional no es un catálogo geográfico; define alcance institucional.
- Ningún nombre técnico del runtime puede imponerse sobre el vocabulario canónico.

## Invariantes del dominio

- La trayectoria del miembro es única y continua.
- La lectura del estado actual no debe destruir la continuidad histórica del miembro.
- Una sección de club pertenece a un solo club.
- Una sección de club representa exactamente un solo tipo de club.
- La operación concreta nace en la sección.
- Toda participación institucional relevante debe poder leerse en contexto.
- Un cargo no sustituye la naturaleza de la vinculación.
- Un registro operativo no debe presentarse como reconocimiento institucional sin validación cuando el proceso la exige.

## Tensiones y casos de interpretación

### Simultaneidad de vinculaciones

Un miembro puede tener múltiples vinculaciones a lo largo del tiempo y, en ciertos casos, de forma simultánea, siempre que el dominio pueda interpretarlas sin contradicción. La simultaneidad requiere criterio del dominio, no permiso automático.

### Transición entre secciones

El paso de una sección a otra por edad, etapa o responsabilidad no rompe la trayectoria. Debe leerse como transición dentro de una continuidad institucional.

### Liderazgo versus pertenencia formativa

Una persona puede ejercer un cargo en una sección sin que ese sea su vínculo formativo principal. Liderazgo y pertenencia formativa deben mantenerse separados.

### Consolidación por club versus origen en sección

La consolidación a nivel club es válida, pero no debe borrar el origen operativo del dato en la sección. La agregación no sustituye el contexto.

### Estado actual versus historial

La lectura del estado vigente no debe destruir el historial. El pasado institucional forma parte de la verdad del dominio.

### Registro operativo versus reconocimiento institucional

Puede existir avance, evidencia o carga operativa sin reconocimiento institucional final. El sistema debe poder expresar esa diferencia con claridad.

## Notas de mapeo con runtime

- En la implementación actual, `Miembro` suele aparecer como `user` en API y base de datos.
- En la implementación actual, `Sección de club` aparece como `instance` y se materializa en tablas separadas por tipo.
- En la implementación actual, `Periodo operativo` se representa principalmente mediante `ecclesiastical_year_id`.
- En la implementación actual, parte de la relación entre cargos y participación aparece en estructuras como `club_role_assignments`.

Estas representaciones técnicas no sustituyen el lenguaje del dominio. Solo expresan su estado actual en runtime.

## Cierre del modelo

SACDIA modela la trayectoria institucional de los miembros mediante vinculaciones contextuales con secciones de club, dentro de periodos operativos, procesos formativos y actos de validación gobernados por una jerarquía organizacional.

Este marco conceptual disciplina el lenguaje, la documentación, la arquitectura y la interpretación del sistema. Si una implementación no refleja este modelo, debe tratarse como una desalineación a resolver entre dominio, runtime o documentación.
