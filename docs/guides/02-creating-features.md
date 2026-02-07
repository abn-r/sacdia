# Creating Features - Paso a Paso

## Workflow de 3 Fases

### Fase 1: Requirements (30-60 min)
**QUÉ necesitas**

1. Brain dump (ver [Idea to Spec](./03-idea-to-spec.md))
2. Crear user stories  
3. Escribir criterios EARS
4. Definir out of scope
5. Obtener aprobación

**Output**: `requirements.md`

---

### Fase 2: Design (1-3 horas)
**CÓMO lo implementarás**

1. Leer requirements.md
2. Diseñar arquitectura (diagrama)
3. Definir DB schema
4. Especificar API contracts
5. Identificar componentes
6. Documentar decisiones técnicas

**Output**: `design.md`

**Tips**: Usa diagramas Mermaid, documenta el "por qué"

---

### Fase 3: Tasks (30-60 min)
**PASOS específicos**

1. Leer requirements + design
2. Dividir en fases (Backend → Frontend → Testing)
3. Crear tareas pequeñas (1-2 días)
4. Definir dependencias
5. Estimar esfuerzo

**Output**: `tasks.md`

---

## Implementación

### Con IA
```
Lee .specs/_steering/agents.md y tech.md

Luego .specs/features/[nombre]/requirements.md y design.md

Implementa tarea T2.1 del tasks.md
```

### Manual
1. Lee specs
2. Implementa tarea  
3. Escribe tests
4. Marca como done en tasks.md

---

## Checklist Antes de Empezar

- [ ] requirements.md aprobado
- [ ] design.md revisado técnicamente
- [ ] tasks.md con criterios claros
- [ ] IA tiene contexto necesario

---

## Plantillas a Usar

**Feature Compleja**: requirements + design + tasks + data-sources  
**Feature Simple**: feature-complete.md (todo en uno)

---

**Next**: [Working with AI](./04-working-with-ai.md)
