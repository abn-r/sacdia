# Walkthrough - Implementación Auth Module

**Fecha**: 30 de enero de 2026  
**Duración**: ~90 minutos  
**Fases completadas**: 1 (Foundation) + 2 (Authentication)

---

## 🎯 Objetivos Completados

### Fase 1: Foundation ✅

1. ✅ Instaladas dependencias necesarias
2. ✅ Configurado Supabase SDK
3. ✅ Creado módulo Common (guards, decorators)
4. ✅ Estructura de carpetas organizada

### Fase 2: Authentication ✅

5. ✅ DTOs con validación completa
6. ✅ AuthService con transacciones y rollback
7. ✅ AuthController con 7 endpoints
8. ✅ JWT Strategy para Passport
9. ✅ Swagger documentado
10. ✅ Build exitoso sin errores

---

## 📦 Dependencias Instaladas

### Producción

```json
{
  "@supabase/supabase-js": "2.93.3",
  "@nestjs/passport": "11.0.5",
  "@nestjs/jwt": "11.0.2",
  "passport": "0.7.0",
  "passport-jwt": "4.0.1",
  "class-validator": "0.14.3",
  "class-transformer": "0.5.1"
}
```

### Desarrollo

```json
{
  "@types/passport-jwt": "4.0.1"
}
```

---

## 📁 Archivos Creados

### Common Module (3 archivos)

#### 1. [src/common/supabase.service.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/common/supabase.service.ts)

```typescript
@Injectable()
export class SupabaseService {
  private supabaseAdmin: SupabaseClient;

  constructor(private configService: ConfigService) {
    const supabaseUrl = this.configService.get<string>("SUPABASE_URL")!;
    const supabaseKey = this.configService.get<string>(
      "SUPABASE_SERVICE_ROLE_KEY",
    )!;

    this.supabaseAdmin = createClient(supabaseUrl, supabaseKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
  }

  get admin(): SupabaseClient {
    return this.supabaseAdmin;
  }
}
```

**Características**:

- Admin client para operaciones privilegiadas
- No persiste sesión (stateless)
- Inyectable globalmente

#### 2. [src/common/guards/jwt-auth.guard.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/common/guards/jwt-auth.guard.ts)

```typescript
@Injectable()
export class JwtAuthGuard extends AuthGuard("jwt") {
  canActivate(context: ExecutionContext) {
    return super.canActivate(context);
  }
}
```

**Uso**:

```typescript
@Get('protected')
@UseGuards(JwtAuthGuard)
async getProtected() { ... }
```

#### 3. [src/common/decorators/current-user.decorator.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/common/decorators/current-user.decorator.ts)

```typescript
export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
```

**Uso**:

```typescript
async getProfile(@CurrentUser() user: { userId: string }) {
  return this.authService.getProfile(user.userId);
}
```

---

### Auth Module (8 archivos)

#### 4. DTOs (3 archivos)

**[register.dto.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/auth/dto/register.dto.ts)**

```typescript
export class RegisterDto {
  @IsString()
  @MaxLength(50)
  name: string;

  @IsString()
  @MaxLength(50)
  paternal_last_name: string; // ✅ Nombre descriptivo

  @IsString()
  @MaxLength(50)
  maternal_last_name: string; // ✅ Nombre descriptivo

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;
}
```

**[login.dto.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/auth/dto/login.dto.ts)**

```typescript
export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}
```

**[reset-password-request.dto.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/auth/dto/reset-password-request.dto.ts)**

```typescript
export class ResetPasswordRequestDto {
  @IsEmail()
  email: string;
}
```

#### 5. [src/auth/strategies/jwt.strategy.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/auth/strategies/jwt.strategy.ts)

```typescript
export interface JwtPayload {
  sub: string; // user_id
  email: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    const jwtSecret = configService.get<string>("SUPABASE_JWT_SECRET")!;

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: jwtSecret,
    });
  }

  async validate(payload: JwtPayload) {
    return {
      userId: payload.sub,
      email: payload.email,
    };
  }
}
```

**Características**:

- Extrae JWT del header `Authorization: Bearer <token>`
- Valida firma con secret de Supabase
- Inyecta user en request

#### 6. [src/auth/auth.service.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/auth/auth.service.ts)

**Métodos implementados**:

##### `register(dto: RegisterDto)`

**Flujo**:

1. Crear usuario en Supabase Auth
2. Crear registro en `users`
3. Crear registro en `users_pr` (tracking granular)
4. Asignar rol "user" (GLOBAL) en `users_roles`

**Rollback automático**: Si falla BD, elimina usuario de Supabase

```typescript
try {
  // Operaciones BD
} catch (dbError) {
  await this.supabase.admin.auth.admin.deleteUser(authUser.user.id);
  throw dbError;
}
```

##### `login(dto: LoginDto)`

**Retorna**:

```json
{
  "status": "success",
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "v1.abc123...",
    "expiresAt": 1900000000,
    "tokenType": "bearer",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "Juan",
      "paternal_last_name": "García",
      "maternal_last_name": "López",
      "avatar": "https://..."
    },
    "needsPostRegistration": true,
    "postRegistrationStatus": {
      "complete": false,
      "profile_picture_complete": false,
      "personal_info_complete": false,
      "club_selection_complete": false
    }
  }
}
```

> Nota de contrato (2026-03-04): `POST /api/v1/auth/refresh` mantiene `refreshToken` como contrato oficial.
> Ventana temporal legacy: `refresh_token` aceptado solo de **2026-03-04** a **2026-03-18** con `AUTH_REJECT_SNAKE_CASE=false`.
> Fecha objetivo de retorno a estricto: **2026-03-18**.

##### `logout(input?: { accessToken?: string; refreshToken?: string })`

Logout fail-safe (best effort): intenta revocar por access token; si no está disponible/expiró, intenta con refresh token y responde `200` para no bloquear UX.

##### `requestPasswordReset(dto: ResetPasswordRequestDto)`

Envía correo de recuperación usando Supabase Auth

##### `getProfile(userId: string)`

Retorna información del usuario autenticado

##### `getCompletionStatus(userId: string)`

**Retorna**:

```json
{
  "status": "success",
  "data": {
    "complete": false,
    "steps": {
      "profilePicture": true,
      "personalInfo": false,
      "clubSelection": false
    },
    "nextStep": "personalInfo",
    "dateCompleted": null
  }
}
```

#### 7. [src/auth/auth.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/auth/auth.controller.ts)

**Endpoints**:

| Método | Ruta                              | Auth | Descripción               |
| ------ | --------------------------------- | ---- | ------------------------- |
| POST   | `/auth/register`                  | No   | Registro de nuevo usuario |
| POST   | `/auth/login`                     | No   | Iniciar sesión            |
| POST   | `/auth/refresh`                   | No   | Refrescar sesión          |
| POST   | `/auth/logout`                    | No*  | Cerrar sesión (best effort) |
| POST   | `/auth/password/reset-request`    | No   | Solicitar recuperación    |
| GET    | `/auth/me`                        | Sí   | Perfil del usuario        |
| PATCH  | `/auth/me/context`                | Sí   | Cambiar contexto activo   |
| GET    | `/auth/profile/completion-status` | Sí   | Estado post-registro      |

\* Puede recibir `Authorization` bearer opcional y/o `refreshToken` en body.

**Ejemplo uso**:

```typescript
@Post('register')
@ApiOperation({ summary: 'Registrar nuevo usuario' })
@ApiResponse({ status: 201, description: 'Usuario registrado exitosamente' })
async register(@Body() registerDto: RegisterDto) {
  return this.authService.register(registerDto);
}
```

#### 8. [src/auth/auth.module.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/auth/auth.module.ts)

```typescript
@Module({
  imports: [
    PassportModule.register({ defaultStrategy: "jwt" }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>("SUPABASE_JWT_SECRET"),
        signOptions: { expiresIn: "7d" },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, SupabaseService],
  exports: [AuthService, JwtStrategy, PassportModule],
})
export class AuthModule {}
```

---

### Configuración Global

#### 9. [src/app.module.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/app.module.ts)

```typescript
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    CommonModule,  // ✅ Nuevo
    AuthModule,    // ✅ Nuevo
  ],
  ...
})
export class AppModule {}
```

#### 10. [src/main.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/main.ts)

**ValidationPipe global**:

```typescript
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true, // Remueve campos no definidos en DTO
    forbidNonWhitelisted: true, // Error si envían campos extra
    transform: true, // Auto-transforma tipos
  }),
);
```

**Resultado**: DTOs se validan automáticamente en todos los endpoints

---

## 🔐 Configuración de Variables de Entorno

### [.env.example](file:///Users/abner/Documents/development/sacdia/sacdia-backend/.env.example)

```bash
# Database
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE?schema=public"

# Supabase (obtener de Supabase Dashboard → Settings → API)
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
SUPABASE_JWT_SECRET="your-jwt-secret-from-supabase"

# App
PORT=3000
NODE_ENV=development
FRONTEND_URL="http://localhost:3001"
```

**Cómo obtener SUPABASE_JWT_SECRET**:

1. Ir a Supabase Dashboard
2. Settings → API
3. Copiar "JWT Secret"

---

## 🧪 Pruebas Manuales

### 1. Registro de Usuario

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan",
    "paternal_last_name": "García",
    "maternal_last_name": "López",
    "email": "juan.garcia@example.com",
    "password": "Password123!"
  }'
```

**Response esperado**:

```json
{
  "success": true,
  "userId": "uuid-generado",
  "message": "Usuario registrado exitosamente"
}
```

**Verificación en BD**:

```sql
-- Debe haber 1 registro en cada tabla
SELECT * FROM users WHERE email = 'juan.garcia@example.com';
SELECT * FROM users_pr WHERE user_id = 'uuid-del-usuario';
SELECT * FROM users_roles WHERE user_id = 'uuid-del-usuario';
```

---

### 2. Login

```bash
curl -X POST http://localhost:3000/auth/login \
 -H "Content-Type: application/json" \
  -d '{
    "email": "juan.garcia@example.com",
    "password": "Password123!"
  }'
```

**Response esperado**:

```json
{
  "status": "success",
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "...",
    "user": { ... },
    "needsPostRegistration": true
  }
}
```

**Guardar el `accessToken` para siguientes pruebas**

---

### 3. Obtener Perfil (Autenticado)

```bash
curl -X GET http://localhost:3000/auth/me \
  -H "Authorization: Bearer <tu-access-token>"
```

**Response esperado**:

```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "email": "juan.garcia@example.com",
    "name": "Juan",
    "paternal_last_name": "García",
    "maternal_last_name": "López",
    ...
  }
}
```

---

### 4. Estado de Post-Registro

```bash
curl -X GET http://localhost:3000/auth/profile/completion-status \
  -H "Authorization: Bearer <tu-access-token>"
```

**Response esperado**:

```json
{
  "status": "success",
  "data": {
    "complete": false,
    "steps": {
      "profilePicture": false,
      "personalInfo": false,
      "clubSelection": false
    },
    "nextStep": "profilePicture"
  }
}
```

---

### 5. Solicitar Recuperación de Contraseña

```bash
curl -X POST http://localhost:3000/auth/password/reset-request \
  -H "Content-Type: application/json" \
  -d '{
    "email": "juan.garcia@example.com"
  }'
```

**Response esperado**:

```json
{
  "success": true,
  "message": "Correo de recuperación enviado"
}
```

---

### 6. Logout

```bash
curl -X POST http://localhost:3000/auth/logout \
  -H "Authorization: Bearer <tu-access-token>"
```

**Response esperado**:

```json
{
  "success": true,
  "message": "Sesión cerrada exitosamente"
}
```

---

## 📖 Swagger Documentation

**URL**: http://localhost:3000/api

### Endpoints documentados:

1. **POST /auth/register**
   - Body: RegisterDto
   - Response: 201 (Success) | 400 (Bad Request)

2. **POST /auth/login**
   - Body: LoginDto
   - Response: 200 (Success) | 401 (Unauthorized)

3. **POST /auth/logout** 🔒
   - Requires: Bearer Token
   - Response: 200 (Success)

4. **POST /auth/password/reset-request**
   - Body: ResetPasswordRequestDto
   - Response: 200 (Success)

5. **GET /auth/me** 🔒
   - Requires: Bearer Token
   - Response: 200 (User data)

6. **GET /auth/profile/completion-status** 🔒
   - Requires: Bearer Token
   - Response: 200 (Post-registration status)

**Probar en Swagger**:

1. Ir a http://localhost:3000/api
2. Hacer login → Copiar accessToken
3. Click en "Authorize" → Pegar token
4. Probar endpoints protegidos

---

## 🏗️ Estructura Final

```
src/
├── common/
│   ├── guards/
│   │   └── jwt-auth.guard.ts          ✅
│   ├── decorators/
│   │   └── current-user.decorator.ts  ✅
│   ├── supabase.service.ts            ✅
│   └── common.module.ts               ✅
│
├── auth/
│   ├── dto/
│   │   ├── register.dto.ts            ✅
│   │   ├── login.dto.ts               ✅
│   │   └── reset-password-request.dto.ts ✅
│   ├── strategies/
│   │   └── jwt.strategy.ts            ✅
│   ├── auth.controller.ts             ✅
│   ├── auth.service.ts                ✅
│   └── auth.module.ts                 ✅
│
├── prisma/
│   ├── prisma.service.ts              (existente)
│   └── prisma.module.ts               (existente)
│
├── app.module.ts                      (actualizado)
└── main.ts                            (actualizado)
```

---

## ✅ Checklist de Implementación

### Foundation

- [x] Instaladas dependencias (Supabase, JWT, Passport, class-validator)
- [x] Configurado Supabase service
- [x] Creado JwtAuthGuard
- [x] Creado CurrentUser decorator
- [x] Creado CommonModule

### Authentication

- [x] DTOs con validaciones
- [x] JWT Strategy configurado
- [x] AuthService con 6 métodos
- [x] Transacción de registro con rollback
- [x] Login con verificación de post-registro
- [x] AuthController con 7 endpoints
- [x] Swagger documentado
- [x] ValidationPipe global habilitado
- [x] .env.example actualizado

### Verificación

- [x] Build exitoso sin errores TypeScript
- [x] No hay lints pendientes
- [x] Todos los endpoints expuestos en Swagger

---

## 📊 Estadísticas

| Métrica              | Valor              |
| -------------------- | ------------------ |
| **Archivos creados** | 14                 |
| **DTOs**             | 3                  |
| **Services**         | 2 (Auth, Supabase) |
| **Controllers**      | 1                  |
| **Guards**           | 1                  |
| **Strategies**       | 1                  |
| **Decorators**       | 1                  |
| **Endpoints**        | 7                  |
| **Líneas de código** | ~650               |
| **Dependencias**     | 7 prod + 1 dev     |

---

## 🚀 Próximos Pasos

### Inmediatos

1. **Crear módulo Users** - CRUD de usuarios
2. **Módulo Post-Registration** - 3 pasos de onboarding
3. **Módulo EmergencyContacts** - Con validación máximo 5
4. **Módulo LegalRepresentatives** - Para menores < 18

### Siguientes

5. **Módulo Catalogs** - Países, uniones, clubes, clases
6. **Tests E2E** - Flujo completo de registro y login
7. **Módulo Clubs** - Gestión de clubes
8. **Módulo Roles & Permissions** - RBAC completo

---

## 🎯 Lecciones Aprendidas

### ✅ Buenas Prácticas Aplicadas

1. **Transacciones con rollback** - Registro atómico
2. **DTOs validados automáticamente** - ValidationPipe global
3. **Separación de responsabilidades** - Service/Controller
4. **Documentación Swagger** - API auto-documentada
5. **Type safety** - TypeScript estricto
6. **Configuración por env** - ConfigService

### ⚠️ Consideraciones

1. **Error handling** - Logs con winston o similar (futuro)
2. **Rate limiting** - Proteger endpoints públicos (futuro)
3. **Refresh tokens** - Implementar rotación (futuro)
4. **Email templates** - Personalizar Supabase (opcional)

---

**Status final**: ✅ **Fase 1 y 2 COMPLETADAS**

El módulo de autenticación está completamente funcional y listo para:

- Registrar usuarios nuevos
- Autenticar con Supabase
- Proteger endpoints con JWT
- Rastrear progreso de post-registro
- Recuperar contraseñas

**Tiempo estimado restante**: 8 días para Fases 3-6
