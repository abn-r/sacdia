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

**Esta guía resuelve eso** con un proceso paso a paso.

---

## Proceso: De Idea a Spec (30-60 min)

### Paso 1: Brain Dump (5-10 min)

**Objetivo**: Sacar todo de tu cabeza sin filtro

Crea archivo temporal y escribe TODO:

```markdown
## Brainstorm - [Tu Idea]

**Lo que quiero lograr**:
[Escribe libremente - no importa si es confuso aún]

**Por qué lo necesito**:
[Qué problema resuelve]

**Quién lo usará**:
[Tipos de usuarios]

**Cómo funcionaría** (ideal):
1. Usuario hace X
2. Sistema hace Y
3. Usuario ve Z

**Preguntas/Dudas**:
- ¿Qué pasa si...?
- ¿Cómo manejo el caso de...?
```

**Ejemplo Real**:
```markdown
## Brainstorm - Sistema de Notificaciones

**Lo que quiero lograr**:
Quiero que los usuarios reciban notificaciones cuando pase algo importante.
No sé si en tiempo real o por email o ambos. Quizás push notifications también?

**Por qué lo necesito**:
Actualmente los usuarios no se enteran de eventos importantes y se pierden cosas.

**Quién lo usará**:
- Usuarios normales (deben poder desactivar)
- Admins (necesitan notificaciones críticas siempre)

**Cómo funcionaría**:
1. Algo pasa en el sistema (nueva orden, mensaje, etc.)
2. Sistema decide si notificar
3. Usuario recibe notificación (¿cómo?)
4. Usuario puede marcar como leída

**Preguntas/Dudas**:
- ¿Tiempo real o batch?
- ¿Email, push, in-app, todo?
- ¿Cómo manejar preferencias de usuario?
- ¿Qué pasa con notificaciones antiguas?
```

---

### Paso 2: Clarificar (10-15 min)

**Objetivo**: Convertir brainstorm en estructura

**Acción**: Responde estas preguntas

#### 2.1 Define el Alcance

**Pregunta clave**: ¿Qué está DENTRO y qué está FUERA de esta versión?

```markdown
## Alcance

### ✅ Dentro (MVP)
- [Funcionalidad 1 mínima]
- [Funcionalidad 2 mínima]
- [Funcionalidad 3 mínima]

### ❌ Fuera (Futuro)
- [Feature avanzada postponed]
- [Nice-to-have para v2]
- [Integración compleja para después]

### 🤔 A Decidir
- [Necesita más investigación]
- [Depende de feedback]
```

**Ejemplo**:
```markdown
## Alcance

### ✅ Dentro (MVP)
- Notificaciones in-app (dentro de la plataforma)
- Notificaciones por email
- Usuarios pueden marcar como leídas
- Preferencias básicas (on/off por tipo)

### ❌ Fuera (v2+)
- Push notifications móviles
- Notificaciones por SMS
- Scheduling avanzado
- Notificaciones agrupadas/digest

### 🤔 A Decidir
- ¿Tiempo real o polling cada X segundos?
  → Investigar: WebSockets vs polling por complejidad
```

#### 2.2 Identifica User Stories

**Pregunta**: ¿Qué quiere hacer cada tipo de usuario?

**Template**:
```markdown
Como [tipo de usuario]
Quiero [hacer algo]
Para [obtener beneficio]
```

**Cómo generar**:
1. Lista tipos de usuarios
2. Para cada uno, pregunta: "¿Qué quiere lograr con esta feature?"
3. Escribe en formato "Como/Quiero/Para"

**Ejemplo**:
```markdown
**US-1**: Recibir Notificación
Como usuario registrado
Quiero recibir notificaciones cuando algo importante suceda
Para no perderme información relevante

**US-2**: Configurar Preferencias
Como usuario
Quiero elegir qué tipo de notificaciones recibir
Para no ser molestado con información irrelevante

**US-3**: Ver Historial
Como usuario
Quiero ver todas mis notificaciones past
Para revisar información que quizás olvidé

**US-4**: Administrar Sistema
Como administrador
Quiero enviar notificaciones masivas
Para comunicar información crítica a todos los usuarios
```

#### 2.3 Define Criterios de Éxito

**Pregunta**: ¿Cómo sabré que está completo y funciona?

```markdown
## Criterios de Éxito

**Funcionales**:
- [ ] [Criterio medible 1]
- [ ] [Criterio medible 2]

**No Funcionales**:
- [ ] Performance: [métrica]
- [ ] Usabilidad: [métrica]

**Aceptación del Usuario**:
- [ ] [Lo que el usuario debe poder hacer]
```

**Ejemplo**:
```markdown
## Criterios de Éxito

**Funcionales**:
- [ ] Usuario recibe notificación en <5 segundos de evento
- [ ] Email enviado en <1 minuto
- [ ] Notificación marca como leída correctamente
- [ ] Preferencias guardan y aplican

**No Funcionales**:
-  [ ] Sistema soporta 1000 notificaciones/min
- [ ] 99.9% de emails entregan exitosamente
- [ ] UI de notificaciones carga en <2s

**Aceptación del Usuario**:
- [ ] "Me entero inmediatamente de mensajes nuevos"
- [ ] "Puedo desactivar notificaciones molestas"
- [ ] "Encuentro fácilmente notificaciones antiguas"
```

---

### Paso 3: Estructura en EARS (10-15 min)

**Objetivo**: Convertir user stories en req

uirements formales

**EARS Format**:
```
WHEN [condición específica]
THE SYSTEM SHALL [acción específica]
```

**Proceso**:
1. Toma cada user story
2. Identifica todos los escenarios (happy path + errores)
3. Escribe en formato EARS

**Ejemplo - De US a EARS**:

**User Story**:
```
Como usuario
Quiero recibir notificaciones cuando algo importante suceda
Para no perderme información relevante
```

**Escenarios posibles**:
- Nueva orden creada
- Mensaje recibido
- Pago procesado
- Error crítico

**En EARS**:
```markdown
### US-1: Recibir Notificación

1. **WHEN** se crea una nueva orden para el usuario
   **THE SYSTEM SHALL** crear una notificación in-app visible en el header

2. **WHEN** se crea una nueva orden para el usuario
   **THE SYSTEM SHALL** enviar un email de confirmación en <1 minuto

3. **WHEN** el usuario abre la página
   **AND** tiene notificaciones no leídas
   **THE SYSTEM SHALL** mostrar un badge con el número de notificaciones

4. **WHEN** el usuario hace click en una notificación
   **THE SYSTEM SHALL** marcarla como leída automáticamente

5. **IF** el usuario tiene preferencia de email desactivada
   **THEN THE SYSTEM SHALL** NO enviar emails pero sí crear notificación in-app

6. **WHEN** el sistema no puede enviar email (servicio caído)
   **THE SYSTEM SHALL** loggear el error y reintentar hasta 3 veces
```

---

### Paso 4: Documentar (10-15 min)

**Objetivo**: Llenar requirements.md con todo lo anterior

**Acción**: Copia template y completa secciones

```bash
cp .specs/_templates/requirements.md.template \
   .specs/features/notifications/requirements.md
```

**Orden recomendado**:

1. **Resumen Ejecutivo**: Copia de tu brainstorm, refinado
2. **User Stories**: Las que identificaste
3. **Criterios EARS**: Los que estructuraste
4. **Fuera de Alcance**: Tu lista de "❌ Fuera"
5. **Criterios de Éxito**: Tu lista de métricas
6. **Preguntas Abiertas**: Tus "🤔 A Decidir"

**No necesitas llenar TODAS las secciones** - solo las relevantes.

**Puedes eliminar**:
- Secciones que no aplican
- Subsecciones vacías
- Templates de ejemplo

---

## Atajos para Casos Comunes

### Atajo 1: Partir de Ejemplos

**Si ya existe algo similar**:
1. Encuentra feature similar en .specs/features/
2. Copia su requirements.md
3. Buscar-reemplazar nombres
4. Ajusta diferencias

**Ahorra**: ~50% del tiempo

---

### Atajo 2: Use IA para Brainstorm

**Prompt efectivo**:
```
Tengo esta idea: [descripción breve]

Ayúdame a estructurarla en:
1. User stories (formato "Como/Quiero/Para")
2. Criterios de aceptación en formato EARS
3. Casos de error importantes a considerar

No implementes nada aún, solo la especificación.
```

**Luego**: Revisa, ajusta, copia a tu requirements.md

---

### Atajo 3: Incremental

**No todo de una vez**:

1. **Versión 0.1** (5 min): Solo resumen y user stories principales
2. **Review con alguien** (15 min)
3. **Versión 0.2** (10 min): Agregar EARS para happy paths
4. **Versión 0.3** (10 min): Agregar error cases
5. **Final** (5 min): Pulir y completar secciones faltantes

**Total**: Mismo tiempo, pero con feedback temprano

---

## Checklist: ¿Está Lista mi Spec?

Antes de pasar a design.md, verifica:

### Must-Have (Mínimo)
- [ ] Resumen ejecutivo claro (alguien sin contexto lo entiende)
- [ ] Al menos 3 user stories principales
- [ ] Criterios EARS para cada user story
- [ ] Criterios de éxito definidos
- [ ] Fuera de alcance documentado

### Should-Have (Recomendado)  
- [ ] Casos de error especificados
- [ ] Requisitos no funcionales (performance, seguridad)
- [ ] Preguntas abiertas documentadas
- [ ] Mockups o wireframes (si aplica)

### Nice-to-Have (Bonus)
- [ ] Casos de uso detallados
- [ ] Diagramas de flujo
- [ ] Métricas específicas
- [ ] Riesgos identificados

---

## Síntomas de Spec Incompleta

### 🚩 Red Flags

**"No sé por dónde empezar a implementar"**
→ Falta detalle en criterios EARS o user stories muy vagas

**"Cada developer la implementaría diferente"**
→ Falta especificación de comportamiento esperado

**"No sé cómo testear esto"**
→ Criterios de aceptación no son testeables

**"¿Qué pasa si X?"**
→ Casos de error no documentados

### ✅ Cómo Arreglar

1. **Pregunta "¿Qué pasa si...?"** para cada flujo
2. **Agrega EARS requirements** para cada respuesta
3. **Define test scenarios** explícitos
4. **Pide feedback** antes de implementar

---

## Ejemplos Completos

### Ejemplo 1: Feature Simple

Ver: `.specs/features/example-feature/requirements.md`

**Complejidad**: Baja  
**Tiempo**: 20-30 min  
**Secciones usadas**: 30% del template

---

### Ejemplo 2: Feature Compleja

[Aquí podrías agregar otro ejemplo cuando lo tengas]

---

## Próximos Pasos

✅ **Requirements completado** → Ahora ve a:
1. **Design.md**: [02-creating-features.md](./02-creating-features.md)
2. **Working with AI**: [04-working-with-ai.md](./04-working-with-ai.md)

---

## Tips Finales

### Para Personas que "No Saben Escribir Specs"

> Eso no existe. Si puedes explicar tu idea a alguien verbalmente, puedes escribirla.

**Truco**: Grábate explicando la idea (5 min) → Transcribe → Edita

### Para Personas Perfeccionistas

> Specs no tienen que ser perfectas v0.1. Iterarás.

**Truco**: Time-box a 30 minutos → Solo lo esencial → Mejora después

### Para Personas Impacientes

> "No tengo tiempo para specs" = "Tendré tiempo para refactors"

**Truco**: 30 min de spec ahorra 3+ horas de rehacer código

---

**¿Listo?** Toma una idea que tengas y practica este proceso ahora mismo. 

**¿Dudás aún?** Lee [Creating Features](./02-creating-features.md) para ver el proceso completo.

