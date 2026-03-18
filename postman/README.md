# SACDIA API - Collections para Postman e Insomnia

**Version**: 2.2.0
**Last Updated**: 4 de febrero de 2026
**Total Endpoints**: 105+

---

## 📥 Importar Collection

### Opción 1: Postman Desktop/Web

1. Abrir Postman
2. Click en **Import** (arriba izquierda)
3. Arrastrar archivos o seleccionar:
   - `SACDIA-API-v2.2.postman_collection.json`
   - `SACDIA-Environment.postman_environment.json`
4. Click **Import**

### Opción 2: Insomnia

1. Abrir Insomnia
2. Click en **Application** → **Preferences** → **Data** → **Import Data**
3. Seleccionar archivo:
   - `SACDIA-API-v2.2.insomnia.json`
4. Click **Import**

**Nota**: La colección de Insomnia incluye el environment integrado, no necesitas importar archivos adicionales.

---

## ⚙️ Configuración

### Postman

#### 1. Seleccionar Environment

1. En Postman, arriba derecha, seleccionar **SACDIA Environment**
2. Verificar variables:
   - `base_url`: URL del backend (default: `http://localhost:3000`)
   - `test_email`: Email para testing
   - `test_password`: Password para testing

#### 2. Actualizar Variables (Opcional)

Click en el ojo 👁️ (arriba derecha) → Click en **Edit**:

```
base_url = http://localhost:3000          # Local
base_url = https://api-staging.sacdia.app # Staging
base_url = https://api.sacdia.app         # Production
```

### Insomnia

El environment viene integrado en la colección. Para cambiar variables:

1. Click en **No Environment** → **Base Environment**
2. Click en el ícono de engranaje ⚙️
3. Editar variables JSON directamente:

```json
{
  "base_url": "http://localhost:3000",
  "auth_token": "",
  "test_email": "test@sacdia.app",
  "test_password": "Test123!"
}
```

---

## 🚀 Primeros Pasos

### 1. Health Check

Verificar que el backend está corriendo:

```
GET {{base_url}}/api/v1/health
```

**Expected Response**:
```json
{
  "status": "ok"
}
```

---

### 2. Login

**Importante**: Ejecutar este endpoint PRIMERO para obtener token de autenticación.

```
POST {{base_url}}/api/v1/auth/login
Body: {
  "email": "{{test_email}}",
  "password": "{{test_password}}"
}
```

**Qué hace**:
- Autentica con Supabase
- **Auto-guarda** el token en `auth_token` (variable de environment)
- **Auto-guarda** el `user_id`

Después de login exitoso, todos los demás endpoints usarán automáticamente el token.

---

### 3. Probar Endpoints

Ahora puedes probar cualquier endpoint. Ejemplos:

**Listar Clubs**:
```
GET {{base_url}}/api/v1/clubs
```

**Crear Actividad**:
```
POST {{base_url}}/api/v1/clubs/5/activities
```

**Ver Finanzas**:
```
GET {{base_url}}/api/v1/clubs/5/finances/summary?year=2026&month=2
```

---

## 📁 Estructura de la Collection

### Módulos (17)

1. **01. Authentication** (7 endpoints)
   - Login, Register, Logout
   - Refresh Token
   - Password Reset
   - Get Current User

2. **02. Clubs** (5 endpoints)
   - CRUD completo de clubs

3. **03. Activities** (5 endpoints)
   - CRUD de actividades
   - Registro de asistencia

4. **04. Finances** (4 endpoints)
   - Transacciones financieras
   - Resúmenes

5. **05. Honors** (5 endpoints)
   - Especialidades
   - Enrollment y progreso

6. **06. Catalogs** (5 endpoints)
   - Países, Uniones, Campos
   - Tipos de club, Roles

7. **07. OAuth** (3 endpoints)
   - Google y Apple OAuth
   - Providers

8. **Health Check** (1 endpoint)
   - Sin autenticación

**Total en esta collection**: 35 endpoints principales
**Nota**: La collection completa con todos los 105+ endpoints está disponible en formato extendido.

---

## 🔐 Autenticación

### Bearer Token

#### En Postman (Automático)

La collection está configurada con **Auth inheritance** y scripts automáticos:

- Login guarda token automáticamente en `{{auth_token}}`
- Todos los endpoints usan automáticamente:
  ```
  Authorization: Bearer {{auth_token}}
  ```

#### En Insomnia (Manual)

1. Ejecutar **01. Authentication → Login**
2. Copiar el `access_token` del response
3. Click en **Base Environment** → ⚙️
4. Pegar token en `auth_token`
5. Todos los endpoints usan automáticamente:
  ```
  Authorization: Bearer {{ _.auth_token }}
  ```

**Nota**: En Insomnia, las variables se referencian con `{{ _.variable_name }}`

### Refrescar Token

Si el token expira (401 Unauthorized):

```
POST {{base_url}}/api/v1/auth/refresh
Body: {
  "refresh_token": "{{refresh_token}}"
}
```

---

## 🧪 Tests Automáticos

### Postman

Algunos endpoints tienen **Tests** integrados que se ejecutan automáticamente:

#### Login Test
```javascript
// Auto-guarda token y user_id
if (pm.response.code === 200) {
    const jsonData = pm.response.json();
    pm.environment.set('auth_token', jsonData.data.session.access_token);
    pm.environment.set('user_id', jsonData.data.user.id);
}
```

#### Ver Tests

1. Click en un request
2. Tab **Tests**
3. Ver scripts que se ejecutan después del request

### Insomnia

Insomnia no soporta tests automáticos como Postman. En su lugar:

1. Verificar manualmente el status code (200, 201, etc.)
2. Inspeccionar el response JSON en el panel derecho
3. Copiar manualmente valores del response a variables de environment según necesites

---

## 📊 Variables de Environment

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `base_url` | URL del backend | `http://localhost:3000` |
| `auth_token` | JWT token (auto) | `eyJhbGciOiJIUzI1...` |
| `refresh_token` | Refresh token (auto) | `refresh_token_here` |
| `user_id` | ID del usuario (auto) | `uuid-123-456` |
| `test_email` | Email de prueba | `test@sacdia.app` |
| `test_password` | Password de prueba | `Test123!` |

**Auto** = Se guarda automáticamente después de Login

---

## 🔄 Workflows Comunes

### Workflow 1: Setup Inicial

1. Health Check
2. Login
3. Get Current User
4. List Clubs

### Workflow 2: Crear Actividad

1. Login
2. List Clubs → Obtener `clubId`
3. Create Activity
4. Register Attendance

### Workflow 3: Gestión de Finanzas

1. Login
2. Get Finance Categories
3. Create Finance Transaction (Ingreso)
4. Create Finance Transaction (Egreso)
5. Get Financial Summary

---

## 🐛 Troubleshooting

### Error: "Unauthorized" (401)

**Causa**: Token expirado o no válido

**Solución**:
1. Ejecutar **Auth → Login** nuevamente
2. O ejecutar **Auth → Refresh Token**

---

### Error: "Forbidden" (403)

**Causa**: Usuario sin permisos para esta acción

**Solución**:
- Verificar que tu usuario tenga el rol correcto (director, subdirector, etc.)
- Algunos endpoints requieren roles específicos

---

### Error: Connection Refused

**Causa**: Backend no está corriendo

**Solución**:
```bash
cd sacdia-backend
npm run start:dev
```

---

### Variables no se guardan

**Causa**: Environment no seleccionado

**Solución**:
1. Arriba derecha, seleccionar **SACDIA Environment**
2. No debe decir "No Environment"

---

## 🔗 Recursos Adicionales

### Documentación

- **API Specification**: `/docs/api/API-SPECIFICATION.md`
- **Endpoints Reference**: `/docs/api/ENDPOINTS-REFERENCE.md`
- **Walkthroughs**: `/docs/api/walkthrough-*.md`
- **Frontend Guide**: `/docs/api/FRONTEND-INTEGRATION-GUIDE.md`

### Swagger UI

Abrir en navegador:
```
http://localhost:3000/api
```

---

## 📝 Notas

### Datos de Prueba

Para crear datos de prueba iniciales:

1. Register new user
2. Create club
3. Assign role to user
4. Create activities, finances, etc.

### Rate Limiting

El backend tiene rate limiting:
- **3 requests/segundo**
- **20 requests/10 segundos**
- **100 requests/minuto**

Si recibes `429 Too Many Requests`, espera un momento.

---

## 🔄 Postman vs Insomnia

| Característica | Postman | Insomnia |
|----------------|---------|----------|
| **Auto-save tokens** | ✅ Sí (con tests) | ❌ Manual |
| **Tests automáticos** | ✅ Sí (JavaScript) | ❌ No |
| **Variables** | `{{variable}}` | `{{ _.variable }}` |
| **UI** | Completa, muchas features | Minimalista, rápida |
| **GraphQL** | ✅ Sí | ✅✅ Excelente |
| **Open Source** | Parcial | ✅ Sí |
| **Recomendado para** | Testing completo, CI/CD | Desarrollo rápido, GraphQL |

**Recomendación**:
- Usa **Postman** si necesitas tests automáticos y workflows complejos
- Usa **Insomnia** si prefieres una interfaz minimalista y desarrollo rápido

---

## 🆕 Actualizaciones

### v2.2.0 (4 Feb 2026)
- ✅ Collections para Postman e Insomnia
- ✅ 35 endpoints principales en 7 módulos
- ✅ Environment con variables configuradas
- ✅ Tests automáticos en Login (Postman)
- ✅ Documentación completa

### Próximas Actualizaciones
- [ ] Collection extendida con 105+ endpoints
- [ ] Tests automáticos en todos los endpoints (Postman)
- [ ] Collection Runners para workflows completos
- [ ] Mock Server integration

---

**Mantenido por**: Equipo SACDIA
**Issues**: https://github.com/abn-r/sacdia-backend/issues
