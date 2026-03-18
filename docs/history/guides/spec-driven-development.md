# Guía: De Idea a Especificación

> Esta guía te ayuda a transformar ideas vagas en especificaciones estructuradas y actionables

---

## El Problema: Ideas Confusas

¿Te ha pasado esto?

- Tienes una idea pero no sabes cómo empezar a documentarla
- Tu idea parece clara en tu mente pero al escribirla se vuelve confusa
- No sabes qué nivel de detalle incluir
- Te sientes abrumado por la cantidad de cosas que hay que especificar
- Empiezas a codear directamente porque "es más rápido"

**Solución**: Este proceso estructurado

---

## Proceso: De Idea a Spec

### Fase 0: Captura Inicial (5-10 min)

**Objetivo**: Sacar de tu cabeza a papel/markdown

**Acción**: Brain dump sin filtro

Crea un archivo temporal y escribe TODO lo que se te ocurra:

```markdown
## Brainstorm - [Nombre de tu idea]

**Lo que quiero lograr**:
[Escribe libremente qué quieres hacer, sin preocuparte por formato]

**Por qué lo necesito**:
[Por qué es importante, qué problema resuelve]

**Usuarios**: [Quién lo usará]

**Flujo básico**:
1. Usuario hace X
2. Sistema hace Y
3. Usuario ve Z
```

**Cómo llenar la plantilla de requirements.md basándote en tu spec actual**:

Para ayudarte a plasmar mejor tus ideas, aquí está el README principal del sistema que creamos. Voy a crear todas las guías complementarias y luego te daré el walkthrough completo:

<function_calls>
<invoke name="write_to_file">
<parameter name="CodeContent"># Sistema de Spec-Driven Development

Un framework completo para transformar ideas en especificaciones estructuradas que cualquier IDE con IA puede implementar efectivamente.

---

## 🎯 ¿Qué es esto?

Este es un sistema inspirado en [Kiro IDE](https://kiro.dev) que te ayuda a:

1. **Estructurar tus ideas** en especificaciones claras
2. **Documentar requerimientos** usando notación EARS (Easy Approach to Requirements Syntax)
3. **Diseñar arquitectura** técnica before codear
4. **Planificar implementación** con tareas discretas y trazables
5. **Trabajar efectivamente con IA** proporcionando contexto rico

---

## 🚀 Quick Start

### Para crear tu primera feature:

1. **Copia una plantilla**:
   ```bash
   cd .specs/features/
   cp -r example-feature/ mi-nueva-feature/
   ```

2. **Completa las especificaciones** en este orden:
   - `requirements.md` - ¿Qué necesitas?
   - `design.md` - ¿Cómo lo implementarás?
   - `tasks.md` - ¿Qué pasos seguirás?

3. **Dale contexto a tu IA**:
   ```
   Lee los archivos en .specs/_steering/ y .specs/features/mi-nueva-feature/
   
   Implementa la tarea T2.1 del tasks.md siguiendo requirements y design.
   ```

4. **Iterar y mejorar** según avances

---

## 📁 Estructura del Sistema

```
.specs/
├── README.md                    # 👈 Estás aquí
├── _templates/                  # Plantillas reutilizables
│   ├── requirements.md.template # EARS notation
│   ├── design.md.template      # Arquitectura técnica
│   ├── tasks.md.template       # Plan de implementación
│   ├── data-sources.md.template # Fuentes de datos
│   └── feature-complete.md.template # Todo en uno (features pequeñas)
│
├── _steering/                   #  Configuración global del proyecto
│   ├── agents.md               # 🤖 Cómo deben comportarse los agentes IA
│   ├── product.md              # Visión y objetivos del producto
│   ├── tech.md                 # Stack tecnológico
│   ├── structure.md            # Estructura del proyecto
│   ├── coding-standards.md     # Estándares de código
│   └── data-guidelines.md      # Manejo de datos
│
├── _guides/                     # 📚 Guías de uso
│   ├── 01-getting-started.md
│   ├── 02-creating-features.md
│   ├── 03-idea-to-spec.md      # 💡 Cómo plasmar tus ideas
│   ├── 04-working-with-ai.md
│   └── 05-best-practices.md
│
└── features/                    # Specs de tus features
    └── example-feature/         # Ejemplo completo
        ├── requirements.md
        ├── design.md
        ├── tasks.md
        └── data-sources.md
```

---

## 🎓 Conceptos Clave

### 1. Spec-Driven Development

En lugar de "vibe coding" (codear directo), seguimos:

```
Idea → Requirements → Design → Tasks → Implementation
```

**Beneficios**:
- ✅ Menos tiempo perdido en refactors
- ✅ IA entiende mejor qué necesitas
- ✅ Documentación automática
- ✅ Trazabilidad completa

### 2. EARS Notation (Requirements)

Formato estructurado para requisitos claros:

```markdown
WHEN [condición específica]
THE SYSTEM SHALL [comportamiento esperado]
```

**Ejemplo**:
```markdown
WHEN un usuario envía un formulario con datos inválidos
THE SYSTEM SHALL mostrar mensajes de error específicos junto a cada campo
```

### 3. Steering Files

Archivos que "guían" a los agentes IA sobre:
- Cómo debe ser el código (coding-standards.md)
- Qué tecnologías usar (tech.md)
- Cómo organizar archivos (structure.md)
- Reglas de negocio (product.md)

### 4. Three-Phase Workflow

**Phase 1: Requirements**
- Define QUÉ necesitas
- User stories + criterios de aceptación
- Sin detalles técnicos aún

**Phase 2: Design**
- Define CÓMO lo implementarás
- Arquitectura, DB schemas, APIs
- Diagramas y decisiones técnicas

**Phase 3: Tasks**
- Define PASOS específicos
- Tareas discretas con criterios de completitud
- Orden de implementación

---

## 💼 Casos de Uso

### Caso 1: Feature Nueva Compleja

**Usar**: Templates separados (requirements.md + design.md + tasks.md)

**Cuándo**: Feature con múltiples componentes, integraciones, o complejidad técnica

**Ejemplo**: Sistema de autenticación completo con OAuth, 2FA, recuperación de password

---

### Caso 2: Feature Pequeña/Mediana

**Usar**: Template unificado (feature-complete.md.template)

**Cuándo**: Feature autocontenida sin muchas dependencias

**Ejemplo**: Agregar filtros a una lista existente, nuevo endpoint simple

---

### Caso 3: Mejora o Bug Fix

**Usar**: Specs existentes + nueva task en tasks.md

**Cuándo**: Modificación a feature existente

**Ejemplo**: Optimizar query, agregar validación faltante

---

## 🤖 Trabajando con IA

### Setup Inicial

1. **Asegúrate que tu IA lea los steering files**:
   ```
   Por favor lee todos los archivos en .specs/_steering/ para entender
   el contexto del proyecto antes de continuar.
   ```

2. **Referencia specs específicas**:
   ```
   Basándote en .specs/features/user-auth/requirements.md y design.md,
   implementa la tarea T2.3 del tasks.md
   ```

### Prompts Efectivos

**❌ Mal** (vago):
```
Haz un sistema de login
```

**✅ Bien** (con contexto):
```
Lee .specs/_steering/agents.md y tech.md.

Luego implementa el endpoint POST /auth/login según especificado en:
- requirements.md (ver US-1, criterios 1-5)
- design.md (sección "API Endpoints")
- tasks.md (tarea T2.3)

Asegúrate de:
- Seguir estructura en structure.md
- Aplicar coding standards de coding-standards.md
- Incluir tests (coverage >80%)
```

### Iteración

**Actualiza specs según aprendes**:

```markdown
<!-- En requirements.md -->

## Control de Cambios
| Fecha | Versión | Cambios |
|-------|---------|---------|
| 2026-01-09 | 0.1 | Creación inicial |
| 2026-01-10 | 0.2 | Agregado requisito de 2FA (feedback de security review) |
```

---

## 📋 Workflows Comunes

### Workflow 1: Nueva Feature desde Cero

1. Duplica template:
   ```bash
   cp -r .specs/_templates/ .specs/features/nombre-feature/
   ```

2. Completa `requirements.md`:
   - User stories
   - Criterios EARS
   - Casos de uso

3. Obtén approval (equipo/stakeholders)

4. Completa `design.md`:
   - Arquitectura
   - DB schema
   - API contracts

5. Obtén technical review

6. Genera `tasks.md`:
   - Desglosa en tareas
   - Estima esfuerzo
   - Define dependencias

7. Implementa task por task

8. Actualiza specs si cambia algo

---

### Workflow 2: Iterar sobre Feature Existente

1. Lee specs actuales

2. Actualiza `requirements.md`:
   - Agrega nuevos criterios
   - Marca versión

3. Actualiza `design.md` si cambia arquitectura

4. Agrega nuevas tasks en `tasks.md`

5. Implementa

---

### Workflow 3: Bug Fix

1. ¿El bug indica requirement faltante?
   - Sí → Actualiza requirements.md
   - No → Solo fix el código

2. Agrega test que reproduzca el bug

3. Fix y verifica que test pase

4. Actualiza docs si es necesario

---

## 🎨 Tips y Best Practices

### Para Requerimientos

✅ **Hazlo**:
- Usa EARS notation consistentemente
- Incluye casos de error y edge cases
- Define métricas de éxito
- Pregunta "¿cómo sabré que está completo?"

❌ **Evita**:
- Soluciones técnicas en requirements (van en design)
- Ambigüedad ("debería funcionar bien")
- Requerimientos sin criterios de aceptación

### Para Design

✅ **Hazlo**:
- Incluye diagramas (valen más que 1000 palabras)
- Documenta decisiones técnicas y "por qué"
- Define contratos de API explícitamente
- Considera error handling y edge cases

❌ **Evita**:
- Diseño sin considerar requirements
- Detalles de implementación (nombres de variables, etc.)
- Diseño sin alternativas consideradas

### Para Tasks

✅ **Hazlo**:
- Tareas pequeñas (1-2 días máx)
- Criterios claros de "done"
- Dependencias explícitas
- Tests incluidos en cada tarea

❌ **Evita**:
- Tareas gigantes ("implementar todo el backend")
- Tareas sin criterios de completitud
- Ignorar dependencias entre tareas

---

## 🆘 Troubleshooting

### "Mi IA no sigue las especificaciones"

**Problema**: La IA implementa cosas diferentes a lo especificado

**Soluciones**:
1. Asegura que la IA LEA las specs antes de codear
2. Referencia secciones específicas del spec en tu prompt
3. Pide que confirme entendimiento antes de implementar
4. Usa `agents.md` para establecer workflow obligatorio

---

### "No sé qué nivel de detalle usar"

**Regla general**:
- **Requirements**: Suficiente para que alguien sin contexto técnico entienda QUÉ
- **Design**: Suficiente para que un developer nuevo pueda implementar CÓMO
- **Tasks**: Suficiente para trackear progreso y saber CUÁNDO está done

**Si tienes dudas**: Más detalle > menos detalle

---

### "Mis specs se vuelven obsoletas"

**Solución**: Specs son documentos vivos

1. Establece regla: "No code change sin spec update"
2. En code reviews, verifica que specs estén actualizadas
3. Usa control de cambios en specs
4. Acepta que iterarás

---

## 🔄 Mantenimiento del Sistema

### Actualizar Templates

Cuando aprendas mejores prácticas:

1. Actualiza el template en `_templates/`
2. NO actualices features existentes automáticamente
3. Aplica a nuevas features
4. Migra features antiguas caso por caso si vale la pena

### Actualizar Steering Files

1. `agents.md`: Cuando cambien workflows o reglas
2. `tech.md`: Cuando agregues/cambies tecnología
3. `structure.md`: Cuando reorganices el proyecto
4. `product.md`: Cuando pivotes o cambies estrategia
5. `coding-standards.md`: Cuando adoptes nuevas convenciones
6. `data-guidelines.md`: Cuando cambien políticas de datos

**Importante**: Comunica cambios al equipo

---

## 📖 Recursos Adicionales

### Guías Detalladas

1. [Getting Started](./01-getting-started.md) - Primeros pasos
2. [Creating Features](./02-creating-features.md) - Crear una feature paso a paso
3. [Idea to Spec](./03-idea-to-spec.md) - Transformar ideas vagas en specs
4. [Working with AI](./04-working-with-ai.md) - Sacar máximo provecho de IA
5. [Best Practices](./05-best-practices.md) - Consejos avanzados

### Referencias Externas

- [Kiro IDE Documentation](https://kiro.dev/docs) - Inspiración original
- [EARS Notation](https://alistairmavin.com/ears/) - Spec de requirements
- [C4 Model](https://c4model.com/) - Para diagramas de arquitectura
- [ADRs](https://adr.github.io/) - Architecture Decision Records

---

## 🤝 Contribuir

### Mejorar el Sistema

Si encuentras formas de mejorar:

1. Actualiza templates o steering files
2. Documenta el cambio
3. Comparte con el equipo (si aplica)

### Agregar Nuevas Plantillas

1. Crea en `.specs/_templates/`
2. Incluye ejemplo en `.specs/features/example-[tipo]/`
3. Documenta cuándo usarla en este README

---

## ❓ FAQ

**P: ¿Tengo que usar TODAS las plantillas?**  
R: No. Usa lo que necesites. Para features pequeñas, `feature-complete.md` puede ser suficiente.

**P: ¿Qué tan detalladas deben ser las specs?**  
R: Lo suficiente para que otra persona (o tu yo futuro) pueda implementar sin adivinar.

**P: ¿Puedo modificar las plantillas?**  
R: Sí, adapta a tus necesidades. Estas son guías, no leyes.

**P: ¿Funciona con cualquier IDE con IA?**  
R: Sí. Funciona con Cursor, Windsurf, GitHub Copilot, Claude, ChatGPT, etc. Solo asegúrate de que la IA lea los contextos necesarios.

**P: ¿Esto no hace el desarrollo más lento?**  
R: Al principio puede parecer más lento, pero reduces MUCHO tiempo en refactors, bugs por malentendidos, y iteraciones innecesarias. A largo plazo es más rápido.

**P: ¿Qué hago si cambio de opinión mid-implementation?**  
R: Actualiza las specs. Son documentos vivos. Mejor tener specs ligeramente outdated que seguir specs incorrectas.

---

## 📝 Changelog

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 2026-01-09 | 1.0 | Sistema inicial creado |

---

## 📄 Licencia

Este sistema es para uso interno del proyecto. Adapta y modifica según necesites.

---

**¿Listo para empezar?** → Lee [Getting Started](./01-getting-started.md)

**¿Necesitas ayuda con tus ideas?** → Lee [Idea to Spec](./03-idea-to-spec.md)

**¿Primera feature?** → Lee [Creating Features](./02-creating-features.md)
