# Best Practices

## Generales

1. **Specs son documentos vivos** - Actualiza cuando cambies código
2. **Menos es más** - Solo llena secciones relevantes del template
3. **Reviewea antes de implementar** - 30 min de review ahorra 3 horas de refactor
4. **Itera** - v0.1 básica → feedback → v0.2 mejorada

## Para Requirements

- Usa EARS consistentemente
- Incluye casos de error
- Define métricas claras de éxito
- Documenta qué NO está incluido (out of scope)

## Para Design

- Agrega diagramas (Mermaid)
- Documenta el "por qué" de decisiones
- Define API contracts explícitamente
- Considera alternativas

## Para Tasks

- Tareas pequeñas (máx 1-2 días)
- Criterios claros de "done"
- Dependencias explícitas
- Tests en cada tarea

## Trabajando con IA

- Asegura que lea steering files primero
- Referencias específicas a specs
- Prompt iterativo, no todo junto
- Valida entendimiento antes de implementar

## Organización

- Una feature = un directorio
- Agrupa features relacionadas en subdirectorios
- Actualiza steering files cuando cambien los estándares
- Version control para specs importantes

## Errores Comunes

❌ Empezar a codear sin spec  
❌ Specs muy vagas  
❌ No actualizar specs cuando código cambia  
❌ Llenar TODO el template (solo lo relevante)  
❌ No versionar cambios importantes  

✅ Spec → Código  
✅ EARS claro y específico  
✅ Specs actualizadas  
✅ Template adaptado a tu necesidad  
✅ Control de cambios documentado  

## Regla de Oro

**Si no está en el spec, no se implementa.**  
**Si se implementó y no está en el spec, actualiza el spec.**
