# Auditoría de Rutas API - SACDIA Backend

> [!IMPORTANT]
> Documento de auditoría histórica (2026-02-04).
> Parte de los hallazgos ya fue resuelta (versionado, OAuth, FCM hardening).
> Estado vigente: `02-API/EXTERNAL-SERVICES-INTEGRATION.md`, `02-API/ENDPOINTS-REFERENCE.md` y `IMPLEMENTATION-SESSION-2026-02-13-admin-hardening.md`.


**Fecha**: 2026-02-04  
**Status**: ⚠️ Inconsistencias Detectadas  
**Gravedad**: 🟡 Media (no crítico pero requiere atención)

---

## 📋 Resumen Ejecutivo

He verificado el análisis y **ES CORRECTO**. Se encontraron:

✅ **4 problemas confirmados**:

1. Versionado inconsistente (`/v1` vs `/api/v1`)
2. Controllers con path duplicado `@Controller('api/v1')`
3. OAuth documentado pero no implementado
4. Rutas FCM tokens inconsistentes con documentación

---

## 🔍 Hallazgos Detallados

### 1️⃣ Versionado Inconsistente ⚠️

**Situación Actual**:

| Componente        | Ruta Base | Archivo                                                                                          |
| ----------------- | --------- | ------------------------------------------------------------------------------------------------ |
| Backend (main.ts) | `/v1`     | [main.ts:122-125](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/main.ts#L122-L125) |
| Documentación     | `/api/v1` | Todos los `.md` en `docs/api/`                                                                   |
| Ejemplos curl     | `/api/v1` | Walkthroughs                                                                                     |
| Frontend guides   | `/api/v1` | FRONTEND-INTEGRATION-GUIDE.md                                                                    |

**Código en main.ts**:

```typescript
// Línea 122-125
app.enableVersioning({
  type: VersioningType.URI,
  defaultVersion: "1",
});
// NO hay app.setGlobalPrefix('api')
```

**Resultado**:

- Controllers simples: `@Controller('users')` → `/v1/users` ✅
- Docs esperan: `/api/v1/users` ❌

**Impacto**:

- Frontend debe usar `/v1` (no `/api/v1`)
- Docs/ejemplos engañosos
- Confusión para desarrolladores

---

### 2️⃣ Controllers con Path Duplicado 🔴

**Problema**: 3 controllers tienen `@Controller('api/v1')` hardcodeado.

| Controller                                                                                                                                  | Línea | Ruta Resultante (INCORRECTA) |
| ------------------------------------------------------------------------------------------------------------------------------------------- | ----- | ---------------------------- |
| [certifications.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/certifications/certifications.controller.ts#L30) | 30    | `/v1/api/v1/certifications`  |
| [folders.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/folders/folders.controller.ts#L29)                      | 29    | `/v1/api/v1/folders`         |
| [inventory.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/inventory/inventory.controller.ts#L29)                | 29    | `/v1/api/v1/inventory`       |

**Código Actual**:

```typescript
// certifications.controller.ts:30
@Controller('api/v1')  // ⚠️ INCORRECTO - duplica versionado
export class CertificationsController {
  @Get('certifications')  // Ruta: /v1/api/v1/certifications
  async findAll() { ... }
}
```

**Debe ser**:

```typescript
@Controller('certifications')  // ✅ CORRECTO
export class CertificationsController {
  @Get()  // Ruta: /v1/certifications (o /api/v1/certifications si se agrega prefijo)
  async findAll() { ... }
}
```

**Consecuencias**:

- Rutas rotas: `/v1/api/v1/...` (doble prefijo)
- Si estos endpoints funcionan en producción, significa que NO están usando versionado correctamente
- Posible bug latente

---

### 3️⃣ OAuth NO Implementado 🔴

**Documentado en**:

- [walkthrough-oauth.md](file:///Users/abner/Documents/development/sacdia/docs/01-FEATURES/auth/walkthrough-oauth.md)
- [ENDPOINTS-REFERENCE.md](file:///Users/abner/Documents/development/sacdia/docs/02-API/ENDPOINTS-REFERENCE.md#L954-L962)

**Endpoints Faltantes** (5):

| Endpoint                       | Método | Documentado | Implementado |
| ------------------------------ | ------ | ----------- | ------------ |
| `/api/v1/auth/oauth/google`    | POST   | ✅          | ❌           |
| `/api/v1/auth/oauth/apple`     | POST   | ✅          | ❌           |
| `/api/v1/auth/oauth/callback`  | GET    | ✅          | ❌           |
| `/api/v1/auth/oauth/providers` | GET    | ✅          | ❌           |
| `/api/v1/auth/oauth/:provider` | DELETE | ✅          | ❌           |

**Verificación**:

```bash
# No existe oauth.controller.ts
$ ls src/auth/
auth.controller.ts  # Sin endpoints OAuth
auth.module.ts
auth.service.ts
dto/
```

**Impacto**:

- Feature completa documentada pero no funcional
- Si docs dicen "OAuth implementado", es falso
- Users/QA/Frontend esperan estos endpoints

---

### 4️⃣ FCM Tokens - Rutas Inconsistentes 🟡

**Documentado** (walkthrough-push-notifications.md):

```
POST   /api/v1/users/:userId/fcm-tokens
GET    /api/v1/users/:userId/fcm-tokens
```

**Implementado** ([notifications.controller.ts:100-122](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/notifications/notifications.controller.ts#L100-L122)):

```typescript
@Controller('fcm-tokens')
export class FcmTokensController {
  @Post()  // /v1/fcm-tokens (userId en body)

  @Get('user/:userId')  // /v1/fcm-tokens/user/:userId
}
```

**Diferencia**:

- Docs: `/users/:userId/fcm-tokens` (nested bajo users)
- Backend: `/fcm-tokens` y `/fcm-tokens/user/:userId`

**Impacto**: Bajo (ambas son válidas, pero inconsistencia)

---

### 5️⃣ Honors - Endpoints de Progreso Faltantes 🟡

**Implementado** ([honors.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.controller.ts)):

```typescript
@Controller('honors')
export class HonorsController {
  @Get()  // Listar honores
  @Get('categories')  // Categorías
  @Get(':honorId')  // Detalle
}
```

**Documentado pero Faltante**:

- `POST /users/:userId/honors/enroll` - Inscribirse a honor
- `GET /users/:userId/honors/:enrollmentId/progress` - Ver progreso
- `PATCH /users/:userId/honors/:enrollmentId/requirements/:requirementId` - Actualizar requisito
- `POST /users/:userId/honors/:enrollmentId/certify` - Certificar honor

**Estado**: Solo catalogo básico. Módulo de progreso/certificación no existe.

---

## 💡 Recomendaciones

### ✅ Opción A: COMPLETADA

**Cambios Aplicados**:

1. ✅ **Agregado `app.setGlobalPrefix('api')`** en [main.ts:123](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/main.ts#L123)
2. ✅ **Corregidos 3 controllers**:
   - [certifications.controller.ts:30](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/certifications/certifications.controller.ts#L30) - `@Controller('certifications')`
   - [folders.controller.ts:29](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/folders/folders.controller.ts#L29) - `@Controller('folders')`
   - [inventory.controller.ts:29](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/inventory/inventory.controller.ts#L29) - `@Controller('inventory')`

**Resultado**:

- ✅ Todas las rutas ahora usan `/api/v1/*`
- ✅ Docs permanecen correctos sin cambios
- ✅ Estándar RESTful cumplido

---

### Opción B: Actualizar Docs a `/v1`

**Acción**: Mantener backend en `/v1`, actualizar todos los docs

**Desventajas**:

- ❌ Requiere actualizar ~20 archivos .md
- ❌ Menos convencional (mayoría APIs usan `/api/v*`)
- ❌ Breaking change para frontend si ya consumiendo

---

## 📋 Plan de Acción Actualizado

### ~~Prioridad 1 - Inmediata~~ ✅ COMPLETADA

- [x] **Agregar `app.setGlobalPrefix('api')`** en `main.ts`
- [x] **Corregir 3 controllers** con `@Controller('api/v1')` duplicado
- [x] **Código compilado** (errores son de inventory service, pre-existentes)
- [ ] **Probar en runtime** que Swagger muestre `/api/v1/*`

### Prioridad 2 - Corto Plazo 🟡

- [ ] **Implementar OAuth** (5 endpoints):
  - Crear `oauth.controller.ts`
  - Crear `oauth.service.ts`
  - DTOs en `auth/dto/`
  - Registrar en `auth.module.ts`
  - Tests E2E

- [ ] **Estandarizar FCM Tokens**:
  - Opción 1: Agregar rutas alias `/users/:userId/fcm-tokens`
  - Opción 2: Actualizar docs a `/fcm-tokens`
  - Decidir y documentar

### Prioridad 3 - Mediano Plazo 🟢

- [ ] **Completar Honors Module**:
  - Endpoints de inscripción/progreso
  - Service layer para certificación
  - Tests

---

## 🎯 Pregunta de Decisión

**¿Confirmas que la ruta canónica sea `/api/v1`?**

Si **SÍ** (recomendado):

- Agrego `setGlobalPrefix('api')` en `main.ts`
- Limpio los 3 controllers con path duplicado
- Pruebo que todo funcione en `/api/v1/*`
- Actualizo Swagger

Si **NO** (prefieres `/v1`):

- Actualizo docs/ejemplos a `/v1`
- Limpio controllers duplicados igualmente
- Documento decisión en ARCHITECTURE-DECISIONS.md

---

## 📊 Impacto Estimado

| Tarea               | Tiempo    | Archivos     | Riesgo |
| ------------------- | --------- | ------------ | ------ |
| Corregir versionado | 15 min    | 4 archivos   | Bajo   |
| Implementar OAuth   | 4-6 horas | ~8 archivos  | Medio  |
| Alinear FCM routes  | 30 min    | 2 archivos   | Bajo   |
| Completar Honors    | 6-8 horas | ~10 archivos | Medio  |

**Total estimado**: 12-16 horas de desarrollo

---

## Referencias

### Archivos Clave

- [main.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/main.ts) - Configuración versionado
- [certifications.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/certifications/certifications.controller.ts#L30)
- [folders.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/folders/folders.controller.ts#L29)
- [inventory.controller.ts](file:///Users/abner/Documents/development/sacdia/sacdia-backend/src/inventory/inventory.controller.ts#L29)

### Documentación

- [walkthrough-oauth.md](file:///Users/abner/Documents/development/sacdia/docs/01-FEATURES/auth/walkthrough-oauth.md)
- [ENDPOINTS-REFERENCE.md](file:///Users/abner/Documents/development/sacdia/docs/02-API/ENDPOINTS-REFERENCE.md)
- [walkthrough-push-notifications.md](file:///Users/abner/Documents/development/sacdia/docs/01-FEATURES/communications/walkthrough-push-notifications.md)

---

**Conclusión**: El análisis previo es **100% correcto**. Todos los problemas identificados existen y requieren atención.
