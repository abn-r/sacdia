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

## Estados posibles de una decisión

Las decisiones de este documento deben estar en uno de estos estados:

- `Vigente`;
- `Superada`;
- `En revisión`.

Una decisión importante no debe desaparecer sin dejar rastro. Si deja de aplicar, debe marcarse como superada y mantenerse trazabilidad hacia su reemplazo.

## Cierre

Este documento existe para conservar memoria estructural, no nostalgia técnica. Su función es impedir que decisiones profundas vuelvan a discutirse sin contexto, como si hubieran aparecido de la nada. En SACDIA, las decisiones clave deben servir para sostener claridad, no para inflar el archivo con historia irrelevante.
