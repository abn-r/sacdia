# Prompt — análisis de benchmark SACDIA contra canon e implementación

Quiero que analices el documento `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md` contra el canon oficial de SACDIA y contra la implementación real del sistema, y que a partir de eso generes una planificación accionable.

## Objetivo
Necesito que:
1. valides qué partes del documento normalizado están respaldadas por canon e implementación,
2. detectes qué partes son parciales, estratégicas o de roadmap,
3. identifiques gaps entre documentación e implementación,
4. propongas una planificación concreta para cerrar esos gaps y ordenar el material documental.

## Fuente principal a analizar
- `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md`

## Fuentes de verdad
Contrastá contra:
- `docs/README.md`
- `docs/canon/`
- `docs/features/`
- `docs/api/`
- `docs/database/`

Y verificá además en implementación real:
- `sacdia-backend/`
- `sacdia-admin/`
- `sacdia-app/`

## Reglas duras
- No inventes capacidades.
- No asumas que algo existe si no encontrás evidencia.
- Si algo aparece en código pero no en docs, marcá gap documental.
- Si algo aparece en docs pero no en código, marcá gap de implementación o de vigencia documental.
- No trates roadmap como si fuera capacidad vigente.
- Todo hallazgo importante debe incluir evidencia con archivo y línea.

## Contexto editorial ya resuelto
El documento normalizado YA fue adaptado con estas decisiones:
- se eliminó microservicios
- trilingüe pasó a roadmap
- offline selectivo debe tratarse como capacidad parcial trabajada en código pero no canonizada transversalmente
- reportes automáticos deben tratarse como existentes al menos en monthly reports, sin generalizar más de lo verificado
- clasificación debe tratarse como parcial: rankings/categorías configurables y tiers en algunos dominios, sin asumir una clasificación institucional única ya cerrada
- carpeta de evidencias debe tratarse como capacidad vigente
- el conteo de módulos debe ignorarse
- lo aspiracional debe proponerse para roadmap/planning/estrategia, no como estado actual

## Qué tenés que responder
Quiero estos entregables:

# 1. Resumen ejecutivo
- qué partes del documento están sólidas
- qué partes siguen débiles o ambiguas
- qué contradicciones o gaps encontraste
- qué valor aporta el documento para estrategia y planificación

# 2. Matriz de validación
Tabla con columnas:
- Tema
- Qué dice el documento normalizado
- Qué dice el canon
- Qué existe en implementación
- Estado (`confirmado`, `parcial`, `no respaldado`, `contradicción`)
- Acción recomendada

# 3. Gaps priorizados
Separá en:
- Alta prioridad
- Media prioridad
- Baja prioridad

Incluir para cada gap:
- descripción
- impacto
- si es gap de canon, feature docs, API docs, database docs o implementación

# 4. Planificación accionable
Armá un plan concreto en fases o bloques de trabajo para avanzar desde el estado actual.

Para cada ítem del plan incluir:
- objetivo
- tipo (`documentación`, `validación`, `implementación`, `roadmap`, `estrategia`)
- artefactos afectados
- dependencia si aplica
- prioridad (`alta`, `media`, `baja`)

# 5. Propuesta de destino documental
Indicá para cada tema si debe vivir en:
- `docs/canon/`
- `docs/features/`
- `docs/api/`
- `docs/database/`
- `docs/plans/` o roadmap/planning
- documento estratégico frente a competidores

# 6. Evidencia
Listá archivo + líneas exactas para cada conclusión importante.

## Criterio de clasificación
Usá estas definiciones:
- `confirmado`: respaldado por canon y/o implementación verificable
- `parcial`: existe evidencia incompleta, acotada o no consolidada
- `no respaldado`: no encontraste soporte suficiente
- `contradicción`: el documento afirma algo que contradice canon o implementación

## Resultado esperado
No quiero solo análisis. Quiero que cierres con una planificación clara de qué conviene hacer ahora:
1. qué corregir en docs,
2. qué mover a roadmap/estrategia,
3. qué validar mejor en implementación,
4. qué capacidades merecen evolución futura.

Tratán el documento base como insumo estratégico validable, no como fuente de verdad operativa.

Verificá al final que ambos archivos existan y respondé solo con:
- rutas creadas
- confirmación breve

Si hacés descubrimientos importantes, guardalos en engram con project `sacdia`.
