# Coding Standards

> Estándares de código específicos para mantener consistencia y calidad

---

## Principios Generales

### SOLID Principles

1. **Single Responsibility**: Una clase/función = una responsabilidad
2. **Open/Closed**: Abierto a extensión, cerrado a modificación  
3. **Liskov Substitution**: Subtipos deben ser sustituibles
4. **Interface Segregation**: Interfaces específicas > generales
5. **Dependency Inversion**: Depender de abstracciones, no concreciones

### DRY, KISS, YAGNI

- **DRY** (Don't Repeat Yourself): No código duplicado
- **KISS** (Keep It Simple, Stupid): Soluciones simples
- **YAGNI** (You Aren't Gonna Need It): No código especulativo

---

## TypeScript / JavaScript

### Variables

**Usa `const` por defecto, `let` cuando sea necesario**:

```typescript
// ✅ Bien
const MAX_RETRIES = 3;
const userData = await fetchUser();
let counter = 0;

// ❌ Mal
var MAX_RETRIES = 3;  // No usar var
let userData = await fetchUser();  // Debería ser const
```

**Nombres descriptivos**:

```typescript
// ✅ Bien
const userAge = calculateAge(birthDate);
const isAuthenticated = checkAuthStatus();
const products = await fetchProducts();

// ❌ Mal
const a = calculateAge(birthDate);  // ¿Qué es 'a'?
const flag = checkAuthStatus();     // ¿Qué flag?
const data = await fetchProducts(); // Muy genérico
```

### Funciones

**Funciones pequeñas y enfocadas**:

```typescript
// ✅ Bien - Hace una cosa bien
function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// ❌ Mal - Hace demasiadas cosas
function processUser(email: string, name: string, age: number) {
  // Valida email
  // Valida nombre
  // Valida edad
  // Crea usuario
  // Envía email
  // Loggea evento
  // ...50 líneas más
}
```

**Parámetros con desestructuración**:

```typescript
// ✅ Bien - Claro qué necesita
interface CreateUserParams {
  email: string;
  name: string;
  age: number;
}

function createUser({ email, name, age }: CreateUserParams) {
  // ...
}

// ❌ Evitar - Muchos parámetros posicionales
function createUser(email: string, name: string, age: number, role: string, status: string) {
  // difícil de llamar: createUser('email', 'name', 25, 'user', 'active')
}
```

**Funciones puras cuando sea posible**:

```typescript
// ✅ Bien - Función pura
function addTax(price: number, taxRate: number): number {
  return price * (1 + taxRate);
}

// ❌ Mal - Modifica estado externo
let total = 0;
function addToTotal(price: number) {
  total += price;  // Side effect
}
```

### Types e Interfaces

**Usar interfaces para objetos, types para uniones/intersecciones**:

```typescript
// ✅ Bien
interface User {
  id: string;
  email: string;
  name: string;
}

type UserRole = 'admin' | 'user' | 'guest';
type UserWithRole = User & { role: UserRole };

// Ambos son válidos, pero interface es más extensible
interface ExtendedUser extends User {
  avatar: string;
}
```

**Evitar `any`, usar `unknown` si es necesario**:

```typescript
// ✅ Bien
function processData(data: unknown) {
  if (typeof data === 'string') {
    return data.toUpperCase();
  }
  throw new Error('Invalid data type');
}

// ❌ Mal
function processData(data: any) {
  return data.toUpperCase();  // No type safety
}
```

### Async/Await

**Preferir async/await sobre callbacks**:

```typescript
// ✅ Bien
async function fetchUserData(userId: string) {
  try {
    const user = await userService.findById(userId);
    const orders = await orderService.findByUserId(userId);
    return { user, orders };
  } catch (error) {
    logger.error('Error fetching user data', error);
    throw error;
  }
}

// ❌ Evitar (callback hell)
function fetchUserData(userId, callback) {
  userService.findById(userId, (err, user) => {
    if (err) return callback(err);
    orderService.findByUserId(userId, (err, orders) => {
      if (err) return callback(err);
      callback(null, { user, orders });
    });
  });
}
```

### Error Handling

**Errores específicos**:

```typescript
// ✅ Bien - Errores específicos
class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

class NotFoundError extends Error {
  constructor(resource: string, id: string) {
    super(`${resource} with id ${id} not found`);
    this.name = 'NotFoundError';
  }
}

// Uso
if (!user) {
  throw new NotFoundError('User', userId);
}
```

**Manejo de errores completo**:

```typescript
// ✅ Bien
async function deleteUser(userId: string) {
  try {
    const user = await userRepository.findById(userId);
    
    if (!user) {
      throw new NotFoundError('User', userId);
    }
    
    await userRepository.delete(userId);
    logger.info(`User ${userId} deleted successfully`);
    
    return { success: true };
    
  } catch (error) {
    if (error instanceof NotFoundError) {
      logger.warn(`Attempted to delete non-existent user: ${userId}`);
      throw error;
    }
    
    logger.error('Error deleting user', { userId, error });
    throw new Error('Failed to delete user');
  }
}
```

---

## React / Vue

### Componentes

**Functional components con hooks**:

```typescript
// ✅ Bien - Functional component
import React, { useState, useEffect } from 'react';

interface UserProfileProps {
  userId: string;
  onUpdate?: (user: User) => void;
}

export const UserProfile: React.FC<UserProfileProps> = ({ userId, onUpdate }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    loadUser();
  }, [userId]);
  
  async function loadUser() {
    try {
      const data = await fetchUser(userId);
      setUser(data);
    } finally {
      setLoading(false);
    }
  }
  
  if (loading) return <LoadingSpinner />;
  if (!user) return <NotFound />;
  
  return (
    <div className="user-profile">
      <h1>{user.name}</h1>
      {/* ... */}
    </div>
  );
};
```

**Separar lógica de presentación**:

```typescript
// ✅ Bien - Lógica en custom hook
function useUserData(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  
  useEffect(() => {
    fetchUser(userId)
      .then(setUser)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [userId]);
  
  return { user, loading, error };
}

// Componente solo presenta
export const UserProfile: React.FC<Props> = ({ userId }) => {
  const { user, loading, error } = useUserData(userId);
  
  if (loading) return <Loading />;
  if (error) return <Error error={error} />;
  if (!user) return <NotFound />;
  
  return <UserView user={user} />;
};
```

### Props

**Desestructurar props**:

```typescript
// ✅ Bien
export const Button: React.FC<ButtonProps> = ({ 
  label, 
  onClick, 
  variant = 'primary',
  disabled = false 
}) => {
  return (
    <button 
      onClick={onClick} 
      className={`btn btn-${variant}`}
      disabled={disabled}
    >
      {label}
    </button>
  );
};

// ❌ Evitar
export const Button: React.FC<ButtonProps> = (props) => {
  return <button onClick={props.onClick}>{props.label}</button>;
};
```

### State Management

**useState para estado local simple**:

```typescript
const [count, setCount] = useState(0);
const [isOpen, setIsOpen] = useState(false);
```

**useReducer para estado complejo**:

```typescript
interface State {
  data: User[];
  loading: boolean;
  error: Error | null;
  filter: FilterOptions;
}

type Action = 
  | { type: 'FETCH_START' }
  | { type: 'FETCH_SUCCESS'; payload: User[] }
  | { type: 'FETCH_ERROR'; payload: Error }
  | { type: 'SET_FILTER'; payload: FilterOptions };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'FETCH_START':
      return { ...state, loading: true, error: null };
    case 'FETCH_SUCCESS':
      return { ...state, loading: false, data: action.payload };
    // ...
  }
}

const [state, dispatch] = useReducer(reducer, initialState);
```

---

## CSS / Styling

### Nombres de Clases (si usas CSS/SCSS)

**BEM o similar**:

```css
/* ✅ Bien - BEM */
.user-card { }
.user-card__header { }
.user-card__title { }
.user-card--featured { }

/* ❌ Evitar - Nombres genéricos */
.card { }
.header { }
.title { }
```

### CSS Modules

```typescript
// UserCard.module.css
.container { }
.header { }
.title { }

// UserCard.tsx
import styles from './UserCard.module.css';

<div className={styles.container}>
  <div className={styles.header}>
    <h2 className={styles.title}>Title</h2>
  </div>
</div>
```

---

## Base de Datos

### Queries

**Usar prepared statements o ORM**:

```typescript
// ✅ Bien - ORM
const user = await prisma.user.findUnique({
  where: { email: userEmail }
});

// ✅ Bien - Prepared statement
const user = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [userEmail]
);

// ❌ NUNCA - SQL injection vulnerable
const user = await db.query(
  `SELECT * FROM users WHERE email = '${userEmail}'`
);
```

### Migrations

```sql
-- ✅ Bien - Reversible
-- UP
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL
);

-- DOWN
DROP TABLE users;
```

---

## Testing

### Estructura de Tests

```typescript
describe('UserService', () => {
  // Setup
  beforeEach(() => {
    // Reset mocks, database, etc.
  });
  
  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const userData = { email: 'test@example.com', name: 'Test' };
      
      // Act
      const user = await userService.createUser(userData);
      
      // Assert
      expect(user).toBeDefined();
      expect(user.email).toBe(userData.email);
    });
    
    it('should throw ValidationError with invalid email', async () => {
      // Arrange
      const userData = { email: 'invalid', name: 'Test' };
      
      // Act & Assert
      await expect(userService.createUser(userData))
        .rejects
        .toThrow(ValidationError);
    });
  });
});
```

### Qué Testear

✅ **Testear**:
- Lógica de negocio compleja
- Edge cases y errores
- Transformaciones de datos
- Validaciones

❌ **No testear excesivamente**:
- Getters/setters triviales
- Third-party code
- Configuración estática

---

## Seguridad

### Never

**❌ NUNCA**:
- Hardcodear credentials
- Confiar en input de usuario sin validar
- Exponer stack traces al cliente
- Usar `eval()` o `Function()` con input de usuario
- Concatenar SQL strings

### Always

**✅ SIEMPRE**:
- Validar y sanitizar inputs
- Usar HTTPS en producción
- Hash passwords (bcrypt, argon2)
- Implementar rate limiting
- Loggear eventos de seguridad

---

## Notas para IA

**Cuando escribas código**:

1. **Sigue estos estándares**
   - No inventes tu propio estilo
   - Pregunta si algo no está claro

2. **Si ves código que no sigue estándares**:
   - Menciona la desviación
   - Sugiere refactor si es significativo
   - No asumas que está bien "porque ya existe"

3. **Cuando refactorices**:
   - Explica qué mejora
   - Muestra antes/después
   - Mantén funcionalidad idéntica

---

**Última actualización**: [YYYY-MM-DD]
