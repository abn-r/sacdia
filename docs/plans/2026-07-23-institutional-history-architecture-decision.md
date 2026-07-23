# ADR/RFC — Histórico institucional transversal

## Estado

ACTIVE

**Decisión canónica relacionada**: `docs/canon/decisiones-clave.md` §25

**Fecha**: 2026-07-23

**Alcance**: división, unión, campo local, distrito, iglesia, club, sección de
club y registros institucionales dependientes.

## Propósito

Definir cómo SACDIA preservará la verdad institucional cuando una entidad:

- cambia de nombre;
- cambia de autoridad superior;
- se divide;
- se fusiona;
- se cierra;
- es corregida con efecto retroactivo.

El objetivo no es conservar una bitácora decorativa. El objetivo es poder
responder, sin reinterpretar el pasado:

1. qué estructura estaba vigente cuando ocurrió un hecho;
2. qué contexto quedó fijado cuando ese hecho fue reconocido oficialmente;
3. quién registró o corrigió la información;
4. de qué reorganización proviene una entidad;
5. quién puede consultar el registro después de una reorganización.

## Contexto

El canon de SACDIA establece que:

- la trayectoria institucional es el eje del sistema;
- el tiempo forma parte de la semántica;
- la jerarquía determina pertenencia, supervisión y autoridad;
- la lectura del estado vigente no debe destruir el historial.

El runtime ya tiene una base parcial:

- relaciones históricas con `valid_from` y `valid_to` para varios niveles;
- restricciones contra intervalos abiertos duplicados y solapamientos;
- resolución de jerarquía `as_of`;
- `hierarchy_contexts` para snapshots;
- snapshots asociados a carpetas anuales y rankings;
- auditoría parcial para algunos agregados.

Sin embargo, el comportamiento no es transversal:

- las relaciones históricas guardan IDs, pero no versiones de nombres;
- la resolución histórica une contra nombres actuales;
- solo unión → división mantiene actualmente su intervalo desde el comando de
  mutación;
- campo local, distrito, iglesia y club pueden cambiar su FK actual sin
  actualizar la historia correspondiente;
- la auditoría geográfica no es un ledger persistente y transaccional;
- muchos módulos atribuyen registros históricos usando la jerarquía vigente;
- el backfill existente representa una relación conocida, no una reconstrucción
  probada de todo el pasado.

Por ello, el estado actual debe considerarse una implementación parcial, no una
garantía global de trazabilidad.

## Fuerzas y restricciones

- PostgreSQL y Prisma siguen siendo la persistencia y ORM canónicos.
- Las entidades tipadas actuales conservan valor semántico y referencial.
- Las lecturas del estado actual deben seguir siendo simples y rápidas.
- Los registros oficiales no pueden cambiar de atribución por una edición
  posterior del catálogo.
- No se debe inventar historia que nunca fue registrada o verificada.
- La autorización de escrituras usa autoridad vigente.
- La lectura histórica puede contener datos personales, financieros o médicos;
  no puede heredarse implícitamente por una reorganización.
- El sistema debe soportar correcciones retroactivas sin borrar qué había sido
  registrado previamente.
- La solución debe poder adoptarse por etapas, sin exigir una reescritura
  simultánea de todos los módulos.

## Opciones consideradas

### Mantener FKs actuales y audit logs aislados

**Ventaja**: menor esfuerzo inmediato.

**Problemas**:

- reatribuye el pasado al consultar la jerarquía actual;
- no conserva nombres anteriores;
- no modela divisiones ni fusiones;
- depende de que cada módulo implemente su propia interpretación.

**Resultado**: descartado.

### Event sourcing transversal

**Ventaja**: preserva cada evento y permite reconstrucciones completas.

**Problemas**:

- obliga a rediseñar agregados, proyecciones y operación;
- eleva de forma considerable la complejidad de desarrollo y soporte;
- no existe evidencia de que SACDIA necesite event sourcing como modelo global.

**Resultado**: descartado.

### Snapshot completo en cada fila

**Ventaja**: cada registro queda autocontenido.

**Problemas**:

- duplica contexto en grandes volúmenes;
- crea múltiples copias potencialmente contradictorias;
- no diferencia borradores, hijos internos y actos institucionales;
- dificulta correcciones y gobernanza.

**Resultado**: descartado.

### Modelo temporal por capas

Combina:

1. auditoría append-only;
2. estado organizacional efectivo;
3. snapshots de actos oficiales;
4. linaje de reorganizaciones.

Mantiene las FKs actuales como proyección vigente y adopta snapshots únicamente
en raíces de agregado o transiciones oficiales.

**Resultado**: propuesta seleccionada.

## Decisión propuesta

SACDIA adoptará un **modelo temporal institucional por capas**, sin event
sourcing global y sin sustituir inicialmente las entidades tipadas existentes
por una tabla polimórfica genérica.

### Capa 1: auditoría append-only

Responde:

- quién ejecutó la operación;
- cuándo la registró;
- cuál fue el motivo;
- qué valores se declararon;
- qué corrección o reorganización la originó.

Para mutaciones de jerarquía y actos institucionales críticos:

- la auditoría se insertará dentro de la misma transacción de negocio;
- un fallo de auditoría impedirá confirmar la mutación;
- no se usará fire-and-forget;
- una corrección creará una nueva revisión; no eliminará el registro anterior.

Los logs técnicos de aplicación siguen siendo observabilidad, no historia de
negocio.

### Capa 2: estado organizacional efectivo

Responde:

- qué nombre era válido;
- de qué autoridad dependía una entidad;
- durante qué periodo era válida esa relación.

Se conservarán tablas tipadas para:

- versiones de nombres de divisiones, uniones, campos locales, distritos,
  iglesias y clubes;
- traducciones asociadas a cada versión de nombre;
- relaciones efectivas entre niveles de jerarquía;
- historia institucional completa del club.

Las tablas principales conservan el nombre y FKs actuales como **proyección del
estado vigente**. No son la fuente para resolver el pasado.

### Capa 3: snapshot institucional

Responde:

- qué contexto quedó fijado cuando un hecho adquirió reconocimiento oficial.

Un snapshot incluirá, como mínimo:

- IDs de cada nivel aplicable;
- IDs de las versiones de nombre;
- nombres y abreviaturas oficiales copiados para representación inmutable;
- fecha efectiva utilizada;
- precisión y procedencia del contexto;
- fecha de captura;
- actor o proceso que lo capturó.

El snapshot será inmutable y pertenecerá a la raíz del agregado oficial. Sus
filas hijas heredarán ese contexto.

No se crearán snapshots para cada edición de un borrador.

### Capa 4: linaje de reorganización

Responde:

- por qué surgió o terminó una entidad;
- cuál fue su predecesora o sucesora;
- qué transferencias formaron parte de una misma reorganización.

Cada reorganización tendrá:

- tipo: `RENAME`, `TRANSFER`, `SPLIT`, `MERGE`, `CLOSURE` o `CORRECTION`;
- fecha efectiva institucional;
- fecha de registro;
- actor;
- descripción de la decisión ejecutiva;
- fuente de autoridad: Iglesia Adventista a nivel mundial;
- participantes y relación dentro del cambio;
- conjunto de movimientos ejecutados.

Una reorganización se aplicará como una unidad transaccional.

## Semántica temporal

### Tiempo efectivo

Representa cuándo un estado es válido para la institución.

- Se expresará como fecha institucional explícita.
- No se inferirá mediante `CURRENT_DATE` del servidor.
- Los intervalos usarán semántica semiabierta:
  `[effective_from, effective_to)`.
- Una entidad no puede tener dos padres efectivos simultáneos dentro del mismo
  tipo de relación.

La fecha, no la hora, es suficiente para el estado institucional. Dos estados
oficiales distintos para la misma relación en un solo día no estarán
permitidos; una corrección del mismo día se modelará como revisión.

### Tiempo de registro

Representa cuándo SACDIA conoció o almacenó la información.

Debe conservar:

- `recorded_at`;
- `recorded_by`;
- revisión reemplazada o corregida;
- motivo de corrección.

Esto permite distinguir:

> “Era efectivo desde enero” de “SACDIA lo conoció en febrero”.

### Precisión

Cada dato histórico declarará su precisión:

- `exact`;
- `day`;
- `month`;
- `year`;
- `system_backfill`;
- `unknown`.

`system_backfill` y `unknown` nunca deben presentarse como historia verificada.

## Invariantes

1. Cambiar el estado vigente no modifica la atribución de un snapshot oficial.
2. Un renombre conserva la identidad y crea una nueva versión de nombre.
3. Un traslado conserva la identidad y crea una nueva relación efectiva.
4. Una división crea al menos una identidad nueva y registra su linaje.
5. Una fusión debe declarar expresamente si una identidad continúa o nace una
   nueva.
6. Un cierre termina vigencia; no elimina identidad ni relaciones históricas.
7. El nombre histórico se resuelve desde su versión, no desde el catálogo
   actual.
8. Las traducciones pertenecen a una versión de nombre.
9. Toda relación actual tiene exactamente un intervalo histórico abierto
   equivalente.
10. No existen intervalos efectivos solapados para una misma relación.
11. Toda mutación estructural y su auditoría se confirman en la misma
    transacción.
12. Una corrección no destruye la revisión anteriormente registrada.
13. Un registro sin contexto histórico confiable declara su precisión; no usa
    silenciosamente la jerarquía actual.
14. La autorización de escritura se evalúa contra autoridad vigente.
15. La atribución histórica y la custodia de lectura son políticas separadas.
16. La autoridad vigente puede consultar el histórico de la entidad trasladada,
    sin modificar la atribución institucional original de cada registro.

## Semántica de cada cambio

### Renombre

- conserva el ID de la entidad;
- cierra la versión de nombre anterior;
- abre la nueva versión desde `effective_from`;
- mantiene las traducciones por versión;
- no cambia relaciones ni atribución histórica.

### Traslado

- conserva el ID de la entidad trasladada;
- cierra la relación anterior;
- abre la relación con el nuevo padre;
- actualiza la FK vigente;
- actualiza, cuando corresponda, la proyección completa de clubes descendientes;
- no mueve registros oficiales anteriores.

### División

- registra una reorganización `SPLIT`;
- conserva o cierra la identidad original según la decisión institucional;
- crea identidades nuevas para las organizaciones resultantes;
- traslada subordinados desde la fecha efectiva;
- conserva los registros anteriores bajo su contexto original;
- concede a cada nueva autoridad lectura del histórico de las entidades que
  recibe, sujeta a los permisos propios de cada módulo.

### Fusión

- registra una reorganización `MERGE`;
- declara si una identidad continúa o si nace una nueva;
- cierra las identidades que dejan de operar;
- traslada subordinados desde la fecha efectiva;
- conserva linaje hacia todas las predecesoras.

### Corrección retroactiva

- registra una reorganización o revisión `CORRECTION`;
- referencia la revisión corregida;
- conserva cuándo se registró cada versión;
- recalcula relaciones temporales afectadas;
- no reescribe snapshots oficiales ya emitidos;
- no genera reemisiones automáticas por cambios de nombre, jerarquía o contexto;
- si existe un error material en el artefacto, conserva la emisión original
  como reemplazada o revocada y crea una nueva emisión vinculada;
- una descarga o impresión posterior de la emisión original reproduce su
  snapshot histórico, no el estado institucional actual.

## Consultas canónicas

### Estado actual

Pregunta:

> ¿Dónde pertenece esta entidad hoy?

Usa las FKs vigentes o la relación histórica abierta.

### Estado histórico

Pregunta:

> ¿Dónde pertenecía esta entidad en una fecha?

Usa versiones y relaciones efectivas. No puede hacer fallback silencioso al
estado actual.

### Snapshot oficial

Pregunta:

> ¿Qué contexto quedó fijado cuando se cerró o validó este registro?

Usa exclusivamente el snapshot asociado al agregado.

### Linaje

Pregunta:

> ¿De qué entidad proviene esta organización y qué ocurrió durante la
> reorganización?

Usa el registro de reorganizaciones y participantes.

## Atribución, custodia y autorización

La reorganización no cambia la atribución histórica. Para registros
institucionales no sensibles, la lectura acompaña a la entidad trasladada para
que su nueva autoridad pueda consultar su trayectoria completa.

### Autoridad de aprobación

**Decisión de producto confirmada el 2026-07-23**:

- `director-dia`;
- `admin`;
- `super-admin`.

Cualquiera de estos roles puede aprobar formalmente un renombre, traslado,
división, fusión o cierre institucional.

La implementación deberá expresar esta autoridad mediante un permiso dedicado,
por ejemplo `institutional_reorganizations:approve`, asignado explícitamente a
esos tres roles. No se concederá por inferencia a `assistant-dia`,
`assistant-admin` ni a autoridades territoriales inferiores.

Esta decisión todavía no está implementada: el controller geográfico actual
restringe sus operaciones a `admin` y `super-admin`. La futura superficie de
reorganizaciones deberá incorporar `director-dia` sin ampliar el CRUD
geográfico existente de forma accidental.

### Fuente de la decisión institucional

**Decisión de producto confirmada el 2026-07-23**:

Un renombre, traslado, división, fusión o cierre se origina en una decisión
ejecutiva de la Iglesia Adventista a nivel mundial. SACDIA no determinará la
validez institucional de esa decisión ni exigirá adjuntos, número de resolución,
referencia documental o evidencia para registrarla.

Los roles autorizados aprueban y ejecutan su registro en SACDIA. Esa aprobación
es el control operativo del sistema; no reemplaza ni crea la autoridad
institucional que proviene de la decisión mundial.

La trazabilidad conservará únicamente los datos propios del acto registrado:
tipo de reorganización, fecha efectiva, descripción, actor y fecha de registro.

Política propuesta:

- **escritura actual**: solo la autoridad vigente;
- **lectura operativa actual**: scope vigente;
- **lectura histórica**: la autoridad vigente hereda acceso de lectura al
  histórico de la entidad que recibe, respetando los permisos del módulo;
- **autoridad anterior**: conserva acceso de solo lectura a los registros
  generados durante el periodo en que la entidad dependió de ella, pero no a
  registros posteriores al traslado;
- **atribución histórica**: permanece bajo el contexto institucional válido
  cuando se produjo el registro;
- **mutación histórica**: el acceso heredado no permite reatribuir, editar ni
  borrar registros anteriores.

Ejemplo:

Un campo local pasa de Unión 1 a Unión 2 el 1 de enero.

- sus actividades posteriores pertenecen a Unión 2;
- sus actividades anteriores siguen atribuidas a Unión 1;
- Unión 2 puede consultar el histórico del campo, incluidos los registros del
  periodo bajo Unión 1, conforme a los permisos de cada módulo;
- Unión 1 conserva lectura de los registros generados hasta el traslado, pero no
  obtiene acceso a los registros posteriores bajo Unión 2;
- ese acceso no cambia la atribución ni concede edición sobre el pasado.

### Excepción: datos personales sensibles

**Decisión de producto confirmada el 2026-07-23**:

Las reglas anteriores de continuidad histórica no conceden acceso automático a
salud, contactos de emergencia, representante legal, documentos privados ni
otras categorías personales sensibles.

La autorización sensible seguirá mínimo privilegio, finalidad y vigencia:

- la persona titular o su representante legal puede consultar sus propios
  datos;
- el responsable operativo de la sección activa solo accede al mínimo necesario
  para su función, con permiso fino y, por defecto, en lectura;
- el Campo Local requiere un rol expresamente autorizado, una finalidad
  operativa concreta y scope vigente;
- la Unión no posee acceso cotidiano: requiere un caso autorizado, justificado,
  temporal y auditado;
- una autoridad anterior pierde acceso al contenido sensible cuando termina su
  relación efectiva con la persona;
- los administradores técnicos no obtienen acceso al contenido por el solo
  hecho de administrar la plataforma.

El histórico conservará metadatos de acceso y cambio —actor, fecha, finalidad y
categoría—, pero no copiará el contenido sensible dentro de snapshots
institucionales ni logs.

La retención se definirá por categoría y jurisdicción:

- no habrá conservación indefinida por el solo valor histórico;
- los datos permanecerán mientras exista una finalidad vigente o una obligación
  aplicable;
- al terminar esa base, pasarán por bloqueo y luego por supresión o
  anonimización;
- los plazos exactos vivirán en políticas de retención configurables y
  versionadas;
- el tratamiento deberá reflejarse en el aviso de privacidad y en los
  mecanismos de consentimiento o representación legal aplicables.

Esta decisión requiere corregir el contrato runtime vigente: hoy el owner tiene
self-service, pero terceros dependen de permisos globales y la asignación activa
no habilita acceso contextual a recursos sensibles. La implementación deberá
eliminar ese acceso amplio como modelo objetivo, sin asumir que un permiso
global equivale a necesidad operativa.

## Aplicación por agregado

| Dominio | Raíz o acto que fija contexto | Contexto requerido |
|---|---|---|
| Jerarquía | reorganización aprobada | auditoría + relación efectiva + linaje |
| Clubes | alta, traslado o cierre de club | relación efectiva; snapshot solo si se emite artefacto |
| Membresía y cargos | vinculación o asignación efectiva | relación temporal propia + contexto de origen |
| Inscripción anual | aprobación/activación | snapshot institucional |
| Carpetas anuales | evaluación o cierre | snapshot institucional existente, reforzado |
| Rankings | cálculo oficial publicado | snapshot heredado o capturado |
| Finanzas | cierre, aprobación o emisión | snapshot institucional |
| Seguros | confirmación institucional | snapshot institucional |
| Camporees | inscripción confirmada y resultado cerrado | snapshot institucional |
| Actividades | cierre o reconocimiento de realización | snapshot institucional cuando tenga valor histórico |
| Clases y honores | validación/investidura | snapshot institucional |
| Certificados | emisión | snapshot completo de representación |
| Materiales | orden emitida o aprobada | snapshot del contexto comprador |
| Inventario | transferencia o baja | ubicación efectiva + auditoría |
| Reportes y exportaciones | publicación/emisión | snapshot o referencia al snapshot fuente |

Esta tabla identifica fronteras iniciales. Cada dominio debe confirmar su raíz
de agregado antes de implementar.

## Impacto esperado en el modelo de datos

El diseño detallado podrá ajustar nombres, pero deberá preservar estas
responsabilidades:

- versiones efectivas de nombres y traducciones;
- relaciones efectivas con revisión temporal;
- reorganización y participantes;
- snapshot institucional inmutable;
- auditoría transaccional;
- política explícita de custodia histórica.

No se adopta inicialmente una tabla genérica `organization_node`. Las entidades
tipadas actuales permanecen y pueden converger únicamente mediante una decisión
posterior respaldada por necesidad real.

## Estrategia de adopción

**Decisión de cobertura confirmada el 2026-07-23**:

Todos los módulos de SACDIA quedan dentro del alcance. No existe una prioridad
funcional entre agregados; el orden de implementación será técnico y podrá
ajustarse según dependencias, riesgo y capacidad de validación.

Esto no implica una migración simultánea. La base temporal de jerarquía,
auditoría, consultas y autorización debe implementarse antes de conectar los
agregados que la consumen.

### Fase 0 — Contrato e integridad

- aprobar este ADR/RFC;
- inventariar todos los write paths territoriales;
- bloquear actualizaciones directas de FKs fuera de comandos autorizados;
- definir comandos transaccionales de reorganización;
- convertir su auditoría en obligatoria;
- ejecutar verificaciones de correspondencia entre FKs vigentes e historia
  abierta.

### Fase 1 — Identidad y relaciones

- completar writers efectivos para todos los niveles;
- introducir versiones de nombre y traducciones;
- implementar reorganizaciones y correcciones;
- eliminar el fallback silencioso en resolución histórica oficial;
- mantener compatibilidad de lectura actual mediante FKs existentes.

### Fase 2 — Seguridad y consultas

- separar `current-write`, `current-read` e `historical-read`;
- implementar la continuidad de lectura histórica para la autoridad vigente;
- conservar para la autoridad anterior lectura histórica limitada a su periodo
  efectivo;
- implementar autorización contextual y temporal para datos sensibles;
- retirar como modelo objetivo los fallbacks globales amplios sobre familias
  sensibles;
- exponer consultas `current`, `as_of`, `snapshot` y `lineage` sin ambigüedad;
- incluir `precision` y `source` en respuestas históricas.

### Fase 3 — Primeras oleadas técnicas

Conectar inicialmente los agregados que ya poseen snapshots o actos oficiales
claros:

1. carpetas y rankings;
2. inscripciones, validaciones y certificados;
3. finanzas y seguros;
4. camporees y reportes oficiales.

### Fase 4 — Cobertura completa

- actividades;
- materiales;
- inventario;
- reportes derivados;
- superficies admin y móvil para consulta histórica.

## Política de migración y backfill

- Las relaciones ya registradas conservan sus rangos y precisión.
- Las filas generadas desde el estado actual permanecen
  `system_backfill`.
- No se inferirán renombres o traslados antiguos desde `modified_at`.
- Una reconstrucción manual solo podrá registrar una decisión ejecutiva
  institucional identificable, junto con actor, fuente de autoridad y precisión.
- Los periodos que no puedan reconstruirse sin inferencias conservarán
  `unknown`.
- Los snapshots oficiales existentes no se reescribirán masivamente.
- Una reparación debe producir un reporte de reconciliación antes y después.

## Criterios mínimos de aceptación

1. Renombrar una unión no cambia el nombre mostrado en un registro oficial
   anterior.
2. Trasladar un campo local conserva su atribución anterior y aplica la nueva
   desde la fecha efectiva.
3. Dividir una unión crea linaje sin mover registros oficiales anteriores.
4. Una consulta histórica nunca usa silenciosamente el padre actual.
5. La FK vigente coincide con exactamente un intervalo histórico abierto.
6. No existen intervalos efectivos solapados.
7. Una corrección retroactiva conserva la revisión anterior y su fecha de
   registro.
8. Los nombres traducidos históricos continúan resolviendo la versión correcta.
9. Una reorganización fallida no deja relaciones, proyecciones o auditorías
   parciales.
10. La autoridad vigente puede leer el histórico de la entidad trasladada sin
    reatribuir ni modificar sus registros anteriores.
11. La autoridad anterior solo puede leer los registros del periodo durante el
    cual la entidad dependió de ella.
12. Un snapshot oficial es inmutable.
13. Los datos de precisión desconocida se presentan como desconocidos.
14. Una corrección no reemite artefactos automáticamente; una nueva emisión por
    error material conserva y referencia la emisión original.
15. La autoridad anterior pierde acceso al contenido sensible cuando termina su
    relación efectiva con la persona.
16. La Unión solo accede a contenido sensible mediante un caso autorizado,
    justificado, temporal y auditado.
17. Ningún snapshot o log institucional replica contenido personal sensible.
18. Cada categoría sensible posee una política versionada de bloqueo, supresión
    o anonimización.

## Consecuencias

### Positivas

- trazabilidad institucional real;
- reportes históricos estables;
- separación clara entre operación actual y verdad histórica;
- reorganizaciones auditables;
- menor riesgo de exposición de datos tras cambios territoriales;
- adopción incremental sobre el schema existente.

### Negativas

- más tablas, restricciones y reglas transaccionales;
- mayor complejidad en consultas históricas;
- necesidad de revisar cada raíz de agregado;
- backfill incompleto cuando no existe una decisión institucional identificable;
- nuevas superficies administrativas para reorganización y custodia.

### Mitigaciones

- usar un servicio común de jerarquía y contexto;
- mantener FKs actuales como proyección;
- centralizar comandos de reorganización;
- migrar todos los agregados por oleadas técnicas;
- clasificar familias sensibles y aplicar autorización contextual;
- automatizar bloqueo, supresión y anonimización según políticas versionadas;
- incluir validadores y reportes de reconciliación;
- documentar precisión y procedencia.

## Riesgos

- crear una segunda fuente de verdad si los snapshots se usan para estado
  actual;
- permitir drift si sobreviven write paths directos;
- tratar `system_backfill` como historia exacta;
- confundir la continuidad de lectura histórica con reatribución o permiso de
  edición;
- extender el acceso histórico institucional a contenido personal sensible;
- conservar datos sensibles indefinidamente o filtrarlos mediante logs,
  snapshots o permisos globales;
- snapshotear demasiado pronto o en demasiadas filas;
- omitir traducciones del versionado;
- ejecutar correcciones retroactivas sin revisión humana.

## Fuera de alcance

- adoptar event sourcing global;
- reconstruir automáticamente historia previa sin una decisión institucional
  identificable;
- rediseñar todas las entidades como un único árbol polimórfico;
- resolver retención legal específica por país;
- implementar interfaces admin o móvil dentro de este ADR;
- definir endpoints concretos antes del diseño técnico de cada fase.

## Decisiones resueltas para ACTIVE

La autoridad de aprobación ya quedó resuelta: `director-dia`, `admin` o
`super-admin`.

La fuente de autoridad también quedó resuelta: decisión ejecutiva de la Iglesia
Adventista a nivel mundial, sin requisito de evidencia documental en SACDIA.

La custodia de lectura también quedó resuelta: la autoridad vigente consulta la
trayectoria completa y la autoridad anterior conserva lectura únicamente sobre
los registros de su periodo efectivo.

La cobertura también quedó resuelta: todos los módulos se implementarán por
oleadas técnicas, sin excluir agregados ni asignarles una prioridad funcional.

La política de artefactos emitidos también quedó resuelta: una corrección no
provoca reemisión automática. Un error material puede originar una nueva emisión
vinculada, pero la emisión original nunca se modifica ni elimina.

La política sensible también quedó resuelta: acceso mínimo, contextual y
temporal; sin herencia histórica; retención por categoría y jurisdicción con
bloqueo y posterior supresión o anonimización.

## Disparadores de revisión

Revisar este ADR si:

- la institución exige dos estados efectivos distintos en un mismo día;
- aparece obligación legal de bitemporalidad más estricta;
- el volumen hace inviable la resolución temporal relacional;
- múltiples dominios necesitan reproducir estado completo desde eventos;
- se decide sustituir las entidades tipadas por un modelo organizacional
  genérico.

## Referencias

- `docs/canon/dominio-sacdia.md`
- `docs/canon/arquitectura-sacdia.md`
- `docs/canon/decisiones-clave.md`
- `sacdia-backend/prisma/schema.prisma`
- `sacdia-backend/prisma/migrations/20260527120000_institutional_hierarchy_history/migration.sql`
- `sacdia-backend/src/common/services/institutional-hierarchy.service.ts`
- `sacdia-backend/src/admin/admin-geography.service.ts`
- `sacdia-backend/src/common/services/authorization-context.service.ts`
