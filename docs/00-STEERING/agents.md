# Agents Configuration

> Este archivo configura el comportamiento de los agentes de IA para tu proyecto  
> Compatible con el estándar AGENTS.md y IDEs con IA como Cursor, Windsurf, Copilot, etc.

---

## Filosofía del Proyecto

Este proyecto sigue una filosofía de **spec-driven development** (desarrollo basado en especificaciones). Todas las features comienzan con especificaciones detalladas antes de escribir código.

### Valores Fundamentales

1. **Claridad sobre Velocidad**: Preferimos pensar antes de codear
2. **Documentación Viva**: Las specs no son documentos muertos, evolucionan con el código
3. **Trazabilidad**: Cada línea de código debe ser trazable a un requisito
4. **Calidad sobre Cantidad**: Código bien testeado > código rápido

---

## Workflow de Desarrollo

### Proceso Estándar

Cuando trabajas en una nueva feature, **SIEMPRE** sigue este flujo:

```
1. Leer specs existentes (.specs/_steering/)
   ↓
2. Crear/Actualizar requirements.md
   ↓
3. Crear/Actualizar design.md
   ↓
4. Crear/Actualizar tasks.md
   ↓
5. Implementar según tasks.md
   ↓
6. Escribir tests
   ↓
7. Actualizar documentación
   ↓
8. Code review
```

### Checkpoint Important

**ANTES de escribir una sola línea de código**:
- [ ] ¿Existe un `requirements.md` para esta feature?
- [ ] ¿Está aprobado por el equipo?
- [ ] ¿Entiendes completamente los criterios EARS?

Si contestas "no" a cualquiera, **DETENTE** y crea/revisa las specs primero.

---

## Reglas Generales para Agentes IA

### 1. Lectura de Contexto

**ANTES de implementar cualquier código**:

```markdown
1. Lee TODOS los steering files en `.specs/_steering/`:
   - product.md (visión del producto)
   - tech.md (stack tecnológico)
   - structure.md (organización del proyecto)
   - coding-standards.md (estándares de código)
   - data-guidelines.md (manejo de datos)

2. Si existe una spec para la feature actual:
   - Lee requirements.md
   - Lee design.md
   - Lee tasks.md
   
3. Busca implementaciones similares en el codebase
```

### 2. Pregunta Antes de Asumir

Si algo no está claro en las especificaciones:
- ❌ **NO** asumas la respuesta
- ❌ **NO** inventes requisitos
- ✅ **SÍ** pregunta al usuario
- ✅ **SÍ** sugiere opciones con pros/contras

### 3. Prioriza la Consistencia

- Sigue los patrones existentes en el codebase
- No introduzcas nuevas librerías sin justificación
- Mantén el mismo estilo de código que el proyecto
- Respeta las convenciones de nombres

### 4. Testing es Obligatorio

Para **CADA** funcionalidad que implementes:
- ✅ Escribe unit tests
- ✅ Asegura coverage >80% para lógica de negocio
- ✅ Incluye casos de error, no solo casos felices
- ✅ Documenta los tests

### 5. Seguridad Primero

**NUNCA**:
- ❌ Hardcodees credenciales o secrets
- ❌ Concatenes strings en SQL queries
- ❌ Confíes en input del usuario sin validar
- ❌ Expongas stack traces al cliente
- ❌ Uses dependencias con vulnerabilidades conocidas

**SIEMPRE**:
- ✅ Usa variables de entorno para secrets
- ✅ Valida y sanitiza inputs
- ✅ Usa prepared statements o ORMs
- ✅ Implementa rate limiting en APIs
- ✅ Loggea operaciones sensibles

---

## Convenciones de Código

### Lenguajes y Frameworks

**Backend**:
- Lenguaje: [Especificar en tech.md]
- Framework: [Especificar en tech.md]

**Frontend**:
- Lenguaje: [Especificar en tech.md]
- Framework: [Especificar en tech.md]

### Estructura de Archivos

Sigue **ESTRICTAMENTE** la estructura definida en `structure.md`.

### Nombres

**Variables y Funciones**:
- `camelCase` para JavaScript/TypeScript
- `snake_case` para Python
- Nombres descriptivos, no abreviaturas crípticas

❌ Mal:
```javascript
const u = getUserData();
const d = new Date();
```

✅ Bien:
```javascript
const userData = getUserData();
const currentDate = new Date();
```

**Archivos**:
- Componentes React: `PascalCase.tsx` (ej: `UserProfile.tsx`)
- Utilities: `camelCase.ts` (ej: `formatDate.ts`)
- Constantes: `UPPER_SNAKE_CASE.ts` (ej: `API_ENDPOINTS.ts`)

### Comentarios

**Comenta el "por qué", no el "qué"**:

❌ Mal:
```javascript
// Incrementa el contador
counter++;
```

✅ Bien:
```javascript
// Incrementamos aquí en lugar de en el reducer porque necesitamos
// el valor inmediatamente para el cálculo que sigue
counter++;
```

**Documenta funciones públicas**:
```typescript
/**
 * Valida un email usando regex RFC 5322 simplificado
 * 
 * @param email - Email a validar
 * @returns true si el email es válido, false en caso contrario
 * @throws Error si email es null o undefined
 */
function validateEmail(email: string): boolean {
  // implementación
}
```

---

## Manejo de Errores

### Estrategia General

1. **Valida Temprano**: Falla rápido en inputs inválidos
2. **Errores Específicos**: Usa tipos de error específicos
3. **Logging Completo**: Loggea contexto suficiente para debugging
4. **Mensajes Amigables**: Al usuario, mensajes claros; en logs, detalles técnicos

### Ejemplo Backend

```javascript
try {
  // Validación temprana
  if (!userId) {
    throw new ValidationError('userId es requerido');
  }
  
  const user = await userService.findById(userId);
  
  if (!user) {
    throw new NotFoundError(`Usuario ${userId} no encontrado`);
  }
  
  // Lógica de negocio
  
} catch (error) {
  logger.error('Error al procesar usuario', {
    userId,
    error: error.message,
    stack: error.stack,
    requestId: req.id
  });
  
  if (error instanceof ValidationError) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: error.message
      }
    });
  }
  
  if (error instanceof NotFoundError) {
    return res.status(404).json({
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: error.message
      }
    });
  }
  
  // Error no esperado
  return res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Ocurrió un error inesperado'
      // NO incluir detalles técnicos al cliente
    }
  });
}
```

---

## Git y Control de Versiones

### Commits

**Formato**:
```
<tipo>(<alcance>): <descripción corta>

<descripción detallada opcional>

<footer opcional>
```

**Tipos**:
- `feat`: Nueva funcionalidad
- `fix`: Bug fix
- `docs`: Cambios en documentación
- `style`: Formato, no afecta lógica
- `refactor`: Refactorización
- `test`: Agregar/modificar tests
- `chore`: Tareas de mantenimiento

**Ejemplos**:
```
feat(auth): implementar login con JWT

- Agregar endpoint POST /auth/login
- Validar credenciales contra database
- Generar JWT con expiración de 1h
- Incluir tests de integración

Closes #123
```

```
fix(api): corregir race condition en cache

El cache de Redis no se estaba invalidando correctamente
cuando múltiples requests actualizaban el mismo recurso
simultáneamente.

Solución: Implementar locks distribuidos con Redlock.
```

### Branches

**Estrategia**: [Git Flow | GitHub Flow | Trunk-based]

**Nombres de Branches**:
- `main` / `master`: Producción
- `develop`: Desarrollo
- `feature/[nombre]`: Nueva feature
- `fix/[nombre]`: Bug fix
- `hotfix/[nombre]`: Fix crítico en producción

**Ejemplo**:
```bash
git checkout -b feature/user-authentication
```

---

## Testing

### Niveles de Testing

1. **Unit Tests**: Funciones individuales, clases
   - Coverage objetivo: >80% para lógica de negocio
   
2. **Integration Tests**: Interacción entre componentes
   - Endpoints de API
   - Flujos de datos
   
3. **E2E Tests**: User journeys completos
   - Solo para flujos críticos (login, checkout, etc.)

### Convenciones

**Nombres de Tests**:
```javascript
describe('UserService', () => {
  describe('create', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const userData = { email: 'test@example.com', name: 'Test' };
      
      // Act
      const user = await userService.create(userData);
      
      // Assert
      expect(user).toBeDefined();
      expect(user.email).toBe(userData.email);
    });
    
    it('should throw ValidationError when email is invalid', async () => {
      // Arrange
      const userData = { email: 'invalid-email', name: 'Test' };
      
      // Act & Assert
      await expect(userService.create(userData))
        .rejects
        .toThrow(ValidationError);
    });
  });
});
```

### Qué Testear

✅ **SÍ Testear**:
- Lógica de negocio
- Validaciones
- Transformaciones de datos
- Manejo de errores
- Edge cases

❌ **NO Testear** (o testear mínimamente):
- Third-party libraries (ya están testeadas)
- Código trivial (getters/setters simples)
- Configuración estática

---

## Performance

### Backend

- Usa índices en queries frecuentes
- Implementa paginación (no retornes miles de registros)
- Cachea datos que cambian poco
- Usa connection pooling para DB
- Implementa rate limiting

### Frontend

- Code splitting para reducir bundle size
- Lazy loading de imágenes
- Memoización de componentes pesados (React.memo)
- Debounce/throttle en inputs de búsqueda
- Optimistic updates para mejor UX

---

## Interacción con el Usuario

### Cuando Necesites Input

**Pregunta Estructurada**:
```markdown
Necesito tu decisión sobre [tema]:

**Opciones**:
1. [Opción A]
   - Pros: [lista]
   - Contras: [lista]
   
2. [Opción B]
   - Pros: [lista]
   - Contras: [lista]

**Recomendación**: Sugiero [opción] porque [razón].

¿Cuál prefieres?
```

### Cuando Propongas Cambios

**Formato**:
```markdown
**Situación Actual**: [Descripción]

**Problema**: [Qué está mal]

**Propuesta**: [Qué cambiaría]

**Impacto**: 
- Archivos afectados: [lista]
- Tiempo estimado: [X horas]
- Riesgos: [lista]

¿Procedo con este cambio?
```

---

## Antipatrones a Evitar

### ❌ NO Hagas

1. **Copiar-Pegar Código**: Refactoriza en función reutilizable
2. **Funciones de 100+ Líneas**: Divide en funciones más pequeñas
3. **God Objects**: Clases que hacen demasiado
4. **Magic Numbers**: Usa constantes nombradas
5. **Comentarios Obsoletos**: Elimina o actualiza
6. **Try-Catch Vacíos**: Siempre loggea errores
7. **Ignorar Warnings**: Arregla warnings del linter
8. **Premature Optimization**: Optimiza solo con datos que lo justifiquen

### ✅ SÍ Haz

1. **DRY (Don't Repeat Yourself)**: Reutiliza código
2. **KISS (Keep It Simple, Stupid)**: Soluciones simples > complejas
3. **YAGNI (You Aren't Gonna Need It)**: No código especulativo
4. **Single Responsibility**: Una clase/función = una responsabilidad
5. **Fail Fast**: Valida y falla temprano
6. **Code Review**: Todo código debe ser revisado
7. **Refactor Constantemente**: Mejora código continuamente
8. **Documenta Decisiones**: Especialmente las no obvias

---

## Checklist de Pre-Implementación

Antes de empezar a codear, verifica:

- [ ] ¿Leíste todos los steering files?
- [ ] ¿Leíste la spec de esta feature (requirements + design + tasks)?
- [ ] ¿Entiendes completamente qué se espera?
- [ ] ¿Identificaste qué task específica implementarás?
- [ ] ¿Revisaste código similar en el proyecto?
- [ ] ¿Conoces las dependencias de esta tarea?
- [ ] ¿Sabes cómo testear lo que implementarás?

Si contestas "no" a alguna, **DETENTE y resuelve primero**.

---

## Checklist Post-Implementación

Después de implementar, verifica:

- [ ] ¿El código cumple los criterios de aceptación del requirement?
- [ ] ¿Escribiste tests con coverage >80%?
- [ ] ¿Los tests pasan localmente?
- [ ] ¿Corriste el linter y no hay errores?
- [ ] ¿Documentaste funciones públicas?
- [ ] ¿Actualizaste task.md marcando como completado?
- [ ] ¿El código sigue las convenciones del proyecto?
- [ ] ¿No hay secrets hardcodeados?
- [ ] ¿Agregaste manejo de errores apropiado?
- [ ] ¿Actualizaste documentación relevante?

---

## Recursos Adicionales

### Documentación Interna
- `.specs/_steering/product.md`: Visión del producto
- `.specs/_steering/tech.md`: Stack tecnológico
- `.specs/_steering/structure.md`: Estructura del proyecto
- `.specs/_steering/coding-standards.md`: Estándares detallados
- `.specs/_guides/`: Guías de uso del sistema

### Cuando Tengas Dudas

1. Revisa specs existentes
2. Busca código similar en el proyecto
3. Consulta steering files
4. Pregunta al usuario con opciones claras

---

## Actualización de Este Archivo

Este archivo debe evolucionar con el proyecto:
- Actualiza cuando cambien procesos
- Agrega nuevas reglas según aprendizajes
- Elimina reglas obsoletas
- Mantén ejemplos actualizados

**Última revisión**: [YYYY-MM-DD]  
**Próxima revisión sugerida**: [YYYY-MM-DD]

---

## Nota Final

> La IA es una herramienta poderosa, pero tú (humano) eres quien toma las decisiones finales.
> Este archivo es una guía, no una prisión. Úsalo para mantener consistencia y calidad,
> pero siéntete libre de desviarte cuando tenga sentido.
> 
> **Principio rector**: Pregunta cuando dudes, sugiere cuando sepas, implementa cuando esté claro.
