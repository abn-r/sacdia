# 01 · Qué es SACDIA y cómo entenderlo

**Estado**: DRAFT · **Revisión documental**: 2026-09-09

## En una frase

SACDIA organiza la trayectoria institucional de las personas y la operación de
los clubes del Ministerio Juvenil Adventista: su participación, responsabilidades,
formación, evidencias y reconocimiento a lo largo del tiempo.

Esta es su **definición de producto**, no una afirmación de que todos los aspectos
de esa trayectoria ya tienen cobertura completa. La propia documentación de
gestión de clubes declara límites de trazabilidad histórica.

Fuentes: [Identidad](../../canon/identidad-sacdia.md),
[Dominio](../../canon/dominio-sacdia.md) y
[Gestión de clubes, gaps](../../features/gestion-clubs.md).

## El problema que busca resolver

La identidad del sistema identifica tres problemas: historial disperso o perdido,
trabajo administrativo manual y poca visibilidad en validaciones y seguimiento.
El valor buscado es que la información permanezca utilizable aunque cambien
responsables, secciones o periodos.

No es una biblioteca de especialidades ni pretende sustituir la evaluación y
responsabilidad humanas. Un archivo cargado no se convierte por sí solo en un
logro reconocido.

## Siete distinciones que evitan confusiones

| Concepto | Explicación para estudiar | No confundir con |
|---|---|---|
| Miembro | Persona cuya trayectoria se registra | Cuenta técnica de acceso |
| Club | Identidad institucional que mantiene continuidad | Sección operativa |
| Sección de club | Unidad que opera un tipo dentro de un club | Un club independiente por cada tipo |
| Tipo de club | Aventureros, Conquistadores o Guías Mayores | Unidad que opera por sí sola |
| Vinculación | Cómo participa una persona en un contexto y periodo | Un cargo permanente |
| Cargo | Responsabilidad que ejerce en un contexto y periodo | Su pertenencia formativa completa |
| Validación | Decisión institucional que reconoce un registro o avance | Captura de información o investidura automática |

Ejemplo ficticio: «Panteras» es el club; «Panteras · Conquistadores» identifica
una sección. Una persona puede ejercer liderazgo en una sección sin que ese cargo
describa toda su trayectoria formativa. Las condiciones para simultaneidad deben
verificarse por proceso, no deducirse del ejemplo.

Fuente: [Dominio](../../canon/dominio-sacdia.md), secciones Vocabulario canónico,
Reglas semánticas, Liderazgo versus pertenencia formativa.

## El contexto importa tanto como la acción

Para entender cualquier dato o permiso, preguntar:

> ¿De quién es, en qué sección, en qué periodo, bajo qué responsabilidad y con qué estado?

El canon trata el año eclesiástico como contexto estructural. «Activo» sin indicar
si corresponde al club, sección, cargo, inscripción o registro es ambiguo.
Terminar un cargo, cambiar de sección e inscribirse en el siguiente año son
operaciones diferentes: no deben dibujarse como un único automatismo.

El canon también declara que la clase se determina por la edad al inicio del año
eclesiástico y no cambia por cumplir años dentro del ciclo. La conciliación con
continuidad/progresión anual y las excepciones concretas corresponde al bloque 3;
no estamos afirmando que toda inscripción actual use una única regla por edad.

## Quiénes intervienen: mapa inicial, no matriz de permisos

| Actor de negocio | Papel que debemos explicar | Pendiente de precisión |
|---|---|---|
| Miembro | Su participación, formación y evidencias | Qué puede hacer por sí mismo en cada flujo |
| Directiva de sección | Organización y administración cotidiana | Facultades por director, subdirector, secretaría y tesorería |
| Consejero o responsable pedagógico | Acompañamiento de miembros/clases | Diferencia entre cargo y asignación pedagógica |
| Coordinador o revisor | Revisión de procesos según autorización | Territorio, especialidad y recursos que puede validar |
| Responsables de campo/unión | Supervisión y decisiones institucionales | Vistas, acciones y delegación por nivel |
| Administrador técnico | Configuración y gestión autorizada del sistema | Separación respecto de cargos institucionales |

Fuentes: [Identidad](../../canon/identidad-sacdia.md),
[Gestión de clubes](../../features/gestion-clubs.md),
[RBAC](../../features/rbac.md),
[Referencia API](../../api/ENDPOINTS-LIVE-REFERENCE.md).

La referencia API nombra `director-union`, pero eso NO autoriza a equiparar al
director de jóvenes con `admin` ni a prometerle acceso universal. Por ejemplo,
la cola genérica de evidencias enumera `admin`, `super-admin`, `coordinator` y el
permiso `validation:review`, no `director-union`. La combinación efectiva de roles,
permisos y alcance de una cuenta se comprobará por separado.

## Cómo se conectan sus partes

[Abrir mapa interactivo](diagramas/01-mapa-sistema.html).

La app móvil atiende la operación cotidiana; el panel administrativo, gestión y
supervisión. Ambos dependen del backend para reglas y autorización. La persistencia
conserva los datos que el sistema implementa. No hay una aplicación independiente
por rol ni las interfaces sustituyen las reglas del servidor.

El mapa representa responsabilidades de alto nivel, no redes, proveedores,
capacidad de carga ni despliegue. «Personas → interfaz» omite la etiqueta «usa» por
ser redundante; no representa que toda persona tenga acceso a ambas interfaces.
Las demás flechas expresan solicitudes y lectura/escritura, no un protocolo completo.

Fuente: [Arquitectura](../../canon/arquitectura-sacdia.md), Responsabilidades por
módulo y Relaciones entre módulos.

## Beneficios buscados y condiciones

| Beneficio buscado | Mecanismo que lo sostiene | Condición o límite |
|---|---|---|
| Continuidad institucional | Personas, secciones y periodos con contexto | No prometer historial exhaustivo: hay gaps documentados |
| Menos información fragmentada | Clientes que operan con reglas compartidas | Depende de captura correcta y adopción de responsables |
| Claridad al reconocer avances | Separar captura, revisión y resultado | Sigue requiriendo decisiones humanas |
| Mejor supervisión | Información contextual para responsables | Los permisos y vistas deben verificarse por nivel |

Son beneficios cualitativos derivados del diseño. No hay mediciones de ahorro,
tiempo, adopción o capacidad verificadas en este análisis inicial.

## Hallazgos que no debemos ocultar

| ID | Hallazgo documental | Tratamiento en el concentrado |
|---|---|---|
| H01 | Dominio, «Notas de mapeo con runtime», menciona tablas separadas por tipo; Gestión de clubes describe `club_sections` consolidado | Mantener la definición de sección; no usar el mapeo antiguo para diagramar datos. Verificar schema en bloque técnico |
| H02 | Introducción de RBAC usa `super_admin`/`subdirector` y una lista reducida; otros apartados y API usan nombres con guion y roles territoriales | No publicar todavía un catálogo definitivo de roles ni normalizar alias por intuición |
| H03 | Gestión de clubes combina un apartado de corte anual revisado con apartados de plantilla/autoinscripción cuya coherencia y actores deben conciliarse | No mostrar un flujo anual único como confirmado; revisar requisitos aprobados, contrato y ejecución actual |
| H04 | Gestión de clubes declara límites de historial de secciones/unidades | Distinguir propósito de trazabilidad de cobertura implementada |

Estos son hallazgos documentales, **no fallos runtime demostrados**. No se cambió
ninguna fuente canónica. La revisión de cada dominio decidirá qué afirmaciones
pueden avanzar de «documentadas» a «comprobadas».

**Actualización 2026-09-10:** las fuentes de inscripción anual se modificaron
mientras este análisis estaba en curso. Gestión de clubes y API ya describen
inscripción por la directiva y bloqueo de autoinscripción. H03 conserva el hallazgo
del corte inicial, pero esa discrepancia concreta queda conciliada documentalmente.
Ver [detalle y límites de la conciliación](03-roles-permisos-contexto.md).
