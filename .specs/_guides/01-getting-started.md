# Getting Started

## Bienvenido al Sistema de Spec-Driven Development

Este sistema te ayuda a transformar ideas en código de forma estructurada.

## Setup (5 minutos)

### 1. Familiarízate con la Estructura

```bash
cd .specs/
ls -la
```

Deberías ver:
- `_templates/`: Plantillas para copiar
- `_steering/`: Configuración global del proyecto  
- `_guides/`: Estas guías
- `features/`: Tus especificaciones de features

### 2. Lee los Steering Files

**Orden recomendado**:
1. `agents.md` - Cómo trabajan los agentes IA
2. `product.md` - Visión del producto
3. `tech.md` - Stack tecnológico
4. `structure.md` - Organización de código

**Por qué**: Estos archivos dan contexto a cualquier IA que uses.

### 3. Explora el Ejemplo

```bash
cd features/example-feature/
cat requirements.md
```

## Tu Primera Feature (15 minutos)

### Opción A: Feature Nueva

```bash
# 1. Crea directorio
cd .specs/features/
mkdir mi-feature

# 2. Copia plantillas relevantes
cp ../_templates/requirements.md.template mi-feature/requirements.md
cp ../_templates/design.md.template mi-feature/design.md
cp ../_templates/tasks.md.template mi-feature/tasks.md

# 3. Edita requirements.md
# (Ver guía 03-idea-to-spec.md para ayuda)
```

### Opción B: Duplicar Ejemplo

```bash
# Más rápido para empezar
cp -r example-feature/ mi-feature/
# Luego edita los archivos
```

## Workflow Básico

```
Idea → Requirements → Design → Tasks → Implementación
```

**Lee next**: [Creating Features](./02-creating-features.md)

## Troubleshooting

**"No sé por dónde empezar"**  
→ Lee [Idea to Spec](./03-idea-to-spec.md)

**"¿Tengo que llenar todo el template?"**  
→ No, solo lo relevante. Borra secciones que no uses.

**"Mi IA no sigue las specs"**  
→ Asegúrate que lea `agents.md` primero

## Recursos

- [README Principal](../README.md)
- [Kiro Documentation](https://kiro.dev/docs)
- [EARS Notation](https://alistairmavin.com/ears/)

¡Listo! Ahora ve a crear tu primera spec.
