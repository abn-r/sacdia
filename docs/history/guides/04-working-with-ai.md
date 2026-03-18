# Working with AI - Mejores Prácticas

## Contexto es Clave

### Asegura que la IA Lea los Steering Files

**Siempre empieza con**:
```
Lee estos archivos antes de continuar:
- .specs/_steering/agents.md
- .specs/_steering/tech.md  
- .specs/_steering/coding-standards.md
```

## Prompts Efectivos

### ✅ Bueno (Específico con Contexto)
```
Lee .specs/features/auth/requirements.md y design.md

Implementa tarea T2.3: Crear endpoint POST /api/v1/auth/login
- Validación según US-1 criterios 1-3
- JWT según design.md sección "Autenticación"
- Tests con >80% coverage

¿Preguntas?
```

### ❌ Malo (Vago)
```
Haz un login
```

## Tips Rápidos

1. **Referencias específicas**: "requirements.md US-2 criterio 3" no solo "el spec"
2. **Pide confirmación**: "Confirma que entiendes X antes de implementar"
3. **Iterativo**: Backend → API → Frontend, no todo junto
4. **Usa agents.md**: Si la IA no sigue reglas, referencia la sección específica

## Troubleshooting

- **IA ignora specs** → Verifica que las leyó explícitamente
- **Usa tech incorrecta** → Referencia tech.md
- **Inventa requisitos** → Enfatiza "SOLO lo en requirements.md"
