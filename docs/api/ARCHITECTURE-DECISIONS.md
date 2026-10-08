# Decisiones de Estandarización - SACDIA

**Estado**: ACTIVE

**Fecha**: 29 de enero de 2026  
**Status**: Aprobado por usuario

---

## 1. Nombres de Campos

### ✅ DECISIÓN FINAL

Usar nombres **descriptivos completos** en inglés:

```typescript
// ✅ USAR (Descriptivo)
interface User {
  id: string;
  email: string;
  name: string;
  paternal_last_name: string;  // ← Descriptivo
  maternal_last_name: string;  // ← Descriptivo (cambio de mother_last_name)
  gender: 'M' | 'F';
  birthdate: string;
  is_baptized: boolean;
  baptism_date?: string;
}

// ❌ NO USAR (Abreviado)
interface User {
  p_lastname: string;  // Muy corto
  m_lastname: string;  // No claro
}
```

**Impacto**:
- ✅ Actualizar schema Prisma
- ✅ Actualizar DTOs en NestJS
- ✅ Actualizar modelos en Flutter
- ✅ Actualizar documentación

---

## 2. Tabla `users_pr` - Tracking de Post-Registro

### ✅ DECISIÓN FINAL: Opción B - Tracking Individual

**Estructura confirmada**:
```sql
CREATE TABLE users_pr (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  complete BOOLEAN DEFAULT false,
  profile_picture_complete BOOLEAN DEFAULT false,
  personal_info_complete BOOLEAN DEFAULT false,
  club_selection_complete BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Ventajas**:
- ✅ App puede retomar exactamente donde se quedó el usuario
- ✅ Métricas de abandono por paso
- ✅ Mejor UX (no repetir pasos ya completados)
- ✅ Validación granular del progreso

**Flujo**:
1. Paso 1 completo → `profile_picture_complete = true`
2. Paso 2 completo → `personal_info_complete = true`
3. Paso 3 completo → `club_selection_complete = true` AND `complete = true`

---

## 3. Representante Legal para Menores

### ✅ DECISIÓN FINAL

**Crear nueva tabla**: `legal_representatives`

```sql
CREATE TABLE legal_representatives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Opción 1: Representante es usuario registrado
  representative_user_id UUID REFERENCES users(id),
  
  -- Opción 2: Solo datos del representante (si no es usuario)
  name VARCHAR(100),
  paternal_last_name VARCHAR(100),
  maternal_last_name VARCHAR(100),
  phone VARCHAR(20),
  
  -- Tipo de relación
  relationship_type_id UUID REFERENCES relationship_types(id),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT one_representative_per_user UNIQUE(user_id),
  CONSTRAINT representative_data_check CHECK (
    (representative_user_id IS NOT NULL) OR 
    (name IS NOT NULL AND paternal_last_name IS NOT NULL AND phone IS NOT NULL)
  )
);
```

**Reglas de negocio**:
1. ✅ Máximo 1 representante por usuario
2. ✅ Puede ser usuario registrado (`representative_user_id`) o datos simples
3. ✅ Modificable a futuro
4. ✅ Solo requerido para menores de 18 años (validar en backend)

**Endpoints**:
```typescript
POST   /api/v1/users/:userId/legal-representative
GET    /api/v1/users/:userId/legal-representative
PATCH  /api/v1/users/:userId/legal-representative
DELETE /api/v1/users/:userId/legal-representative
```

---

## 4. Año Eclesiástico (Ecclesiastical Year)

### ✅ DECISIÓN FINAL

**Auto-asignar** año eclesiástico actual al usuario.

**Implementación**:
```typescript
// En post-registro, Paso 3: Selección de club
async completeClubSelection(userId: string, dto: CompleteClubSelectionDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Obtener año eclesiástico actual
    const currentYear = await tx.ecclesiastical_years.findFirst({
      where: {
        start_date: { lte: new Date() },
        end_date: { gte: new Date() }
      }
    });
    
    if (!currentYear) {
      throw new Error('No active ecclesiastical year found');
    }
    
    // 2. Asignar rol de miembro con año actual
    await tx.club_role_assignments.create({
      data: {
        user_id: userId,
        role_id: memberRole.id,
        [dto.clubType + '_id']: dto.clubInstanceId,
        ecclesiastical_year_id: currentYear.id,  // ← Auto-asignado
        start_date: new Date(),
        active: true,
        status: 'pending'
      }
    });
  });
}
```

**Reglas**:
- ✅ Usuario **NUNCA** selecciona año eclesiástico
- ✅ Sistema auto-asigna el año actual
- ✅ Admin panel puede cambiar años en el futuro

---

## 5. Sistema de Membresía y Roles

### ✅ DECISIÓN FINAL

**Todos los miembros tienen rol** en `club_role_assignments`.

**Flujo de registro**:
```typescript
// En registro (PROCESO 2)
await tx.users_roles.create({
  data: {
    user_id: userId,
    role_id: 'uuid-del-rol-user',  // Rol GLOBAL: "user"
  }
});

// En post-registro - Paso 3 (PROCESO 3 del post-registro)
await tx.club_role_assignments.create({
  data: {
    user_id: userId,
    role_id: 'uuid-del-rol-member',  // Rol CLUB: "member"
    club_section_id: clubSectionId,  // FK directa a club_sections
    ecclesiastical_year_id: currentYear.id,
    start_date: new Date(),
    active: true,
    status: 'pending'  // Pendiente de aprobación por director
  }
});
```

**Roles de sistema**:

### Roles Globales (tabla: `users_roles`)
```typescript
- super_admin  // Acceso total
- admin        // Admin de campo local
- coordinator  // Coordinador
- user         // Usuario estándar (asignado en registro)
```

### Roles de Club (tabla: `club_role_assignments`)
```typescript
- director      // Director del club
- subdirector   // Subdirector
- secretary     // Secretario
- treasurer     // Tesorero
- counselor     // Consejero
- member        // Miembro regular (asignado en post-registro)
```

**Tabla `roles` tiene campo `role_category`**:
```sql
CREATE TABLE roles (
  id UUID PRIMARY KEY,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  role_category VARCHAR(10) NOT NULL CHECK (role_category IN ('GLOBAL', 'CLUB')),
  description TEXT,
  active BOOLEAN DEFAULT true
);
```

---

## 📊 Resumen de Cambios Requeridos

### Documentos a actualizar

1. ✅ **especificacion-tecnica-nueva-api.md**
   - Cambiar nombres de campos (p_lastname → paternal_last_name)
   - Agregar tabla `legal_representatives`
   - Incluir `role_category` en roles
   - Auto-asignación de `ecclesiastical_year_id`

2. ✅ **mapeo-procesos-endpoints.md**
   - Actualizar DTOs con nombres descriptivos
   - Agregar endpoints de representante legal
   - Incluir validación edad < 18 para representante
   - Agregar `ecclesiastical_year_id` en Proceso 3

3. ✅ **Nuevo**: `schema-legal-representatives.sql`
   - Crear migration para tabla nueva

4. ✅ **Completado**: Estructura final de `users_pr` confirmada (Opción B)

---

## ✅ Checklist de Implementación

### Base de Datos
- [ ] Actualizar `schema.prisma` con `paternal_last_name`/`maternal_last_name`
- [ ] Crear tabla `legal_representatives`
- [ ] Confirmar estructura de `users_pr`
- [ ] Agregar `role_category` a tabla `roles`
- [ ] Crear migration

### Backend (NestJS)
- [ ] Actualizar DTOs (RegisterDto, UpdateUserDto)
- [ ] Crear módulo `LegalRepresentativesModule`
- [ ] Auto-asignar `ecclesiastical_year_id` en post-registro
- [ ] Validar edad < 18 para requerir representante legal
- [ ] Actualizar RolesGuard para verificar `role_category`

### Frontend (Flutter)
- [ ] Actualizar modelos (`User`, `LegalRepresentative`)
- [ ] Agregar pantalla de representante legal en post-registro
- [ ] Validar edad y mostrar form condicionalmente

### Documentación
- [ ] Actualizar todos los documentos con decisiones
- [ ] Crear guía de migración de datos (si hay API existente)

---

---

## 6. Módulo RBAC y Gestión de Permisos desde Admin Panel

### ✅ DECISIÓN FINAL (2026-02-09)

#### Cambios en `auth.service.ts`

- **`login()`**: Ahora incluye `users_roles` (con `role_name` y `role_category`) en el query de Prisma. Retorna `roles: string[]` en el objeto `user` de la respuesta.
- **`getProfile()`**: Ahora incluye `users_roles → roles → role_permissions → permissions`. Retorna `roles: string[]` y `permissions: string[]` aplanados en `data`.

#### Módulo `RbacModule` (Backend)

Nuevo módulo NestJS en `src/rbac/` registrado en `app.module.ts`:

| Archivo | Propósito |
|---------|-----------|
| `rbac.module.ts` | Módulo con imports de `PrismaModule` |
| `rbac.controller.ts` | 8 endpoints bajo `/admin/rbac`, protegidos por `GlobalRolesGuard` |
| `rbac.service.ts` | CRUD permisos + sync de permisos a roles |
| `dto/create-permission.dto.ts` | Validación regex `resource:action` |
| `dto/update-permission.dto.ts` | Actualización parcial |
| `dto/assign-permissions.dto.ts` | Asignación bulk de UUIDs |

**Endpoints**:
- CRUD de permisos: `GET/POST/PATCH/DELETE /admin/rbac/permissions`
- Roles con permisos: `GET /admin/rbac/roles`
- Sync permisos a rol: `PUT /admin/rbac/roles/:id/permissions`
- Remover permiso: `DELETE /admin/rbac/roles/:id/permissions/:pid`

#### Pantallas Admin Panel (Frontend)

| Ruta | Descripción |
|------|-------------|
| `/dashboard/rbac` | Índice con tarjetas |
| `/dashboard/rbac/permissions` | CRUD de permisos (tabla + formularios) |
| `/dashboard/rbac/roles` | Matriz de asignación permisos↔roles con checkboxes |

#### Cambios en frontend auth

- `extractRoles()` (`roles.ts`): Ahora desenvuelve `{ status, data }` wrapper y soporta `users_roles` en formato Prisma
- `getCurrentUser()` (`session.ts`): Desenvuelve respuesta backend `{ status, data }` antes de retornar `AuthUser`
- Sidebar: Nueva sección "Seguridad" con enlaces a Permisos y Roles

**Documentación completa**: [`docs/01-FEATURES/auth/PERMISSIONS-SYSTEM.md`](../01-FEATURES/auth/PERMISSIONS-SYSTEM.md)

---

## 7. Sacdia Admin nativo: eligibility y sesión administrativa privada

### ✅ DECISIÓN APROBADA — AÚN NO EXPUESTA EN RUNTIME (2026-07-10)

#### Contexto

La app iOS nativa necesita una fachada de autenticación administrativa específica sin cambiar el login vigente del panel web y la app móvil. La entrada a la superficie administrativa debe separarse de la autorización fina de cada operación.

#### Decisión

| Tema | Contrato |
|------|----------|
| Compatibilidad | La futura fachada `/api/v1/auth/admin/*` será aditiva. `/auth/*` legacy conservará sus contratos y comportamiento. |
| Orden seguro | Primero `validateCredentials` valida credenciales sin crear sesión, firmar JWT ni consultar TOTP; después `AdminEligibilityService` evalúa eligibility. |
| Gate de superficie | Una consulta fresca a `users` permitirá continuar solo con `active === true && access_panel === true`. Usuario ausente, `active=false`, `access_panel=false` o `access_panel=null` niegan. |
| Fallo de datos | Los errores de base de datos se propagan; nunca se interpretan como usuario elegible. |
| Denegación | `AUTH_PANEL_ACCESS_DENIED`, HTTP 403, sin indicar qué condición falló. |
| Roles y scope | Roles GLOBAL y asignaciones no participan en el login. Después de autenticar, cada operación exige permiso RBAC y scope backend. |
| Persistencia | En la rama, `admin_auth_sessions` extiende 1:1 a Better Auth `sessions`; guarda familia, superficie, cliente, assurance, assignment opcional, expiración absoluta y revocación. La sesión opaca interna usa ventana de 7 días y límite absoluto de 30 días. |
| Token admin | JWT HS256 de acceso por 15 minutos con `iss='https://api.sacdia.app'`, `aud='sacdia-admin-api'`, `surface='admin'`, `client_type='ios'`, `sid`, `jti`, `aal`, `amr` y `mfa_pending=false`; no incluye email. Para `aal1`, `amr=['pwd']`; para `aal2`, `amr=['pwd','otp']`. Los identificadores deben ser claims canónicos sin espacios periféricos. |
| Tiempo del token | `iat`, `exp` y `accessTokenExpiresAt` derivan del mismo segundo epoch: `exp = iat + 900`, sin divergencia entre la expiración pública y la firmada. |
| Autoridad y revocación | Cada request valida en base de datos el vínculo entre sesión y sujeto/usuario, además de assurance, revocación y expiraciones. No hace join de `active`/`access_panel` por request: esos cambios requieren revocar las sesiones desde la mutación administrativa, integración pendiente de A5. El parser Bearer de Passport también alimenta la blacklist. Una caída de esta autoridad falla cerrada con HTTP 503, no con acceso concedido ni con 401 ambiguo. |
| Compatibilidad JWT | Si `surface` está ausente, `JwtStrategy` conserva intacto el contrato legacy. Si está presente, la estrategia valida manualmente y solo acepta `surface='admin'` con el contrato administrativo completo y stateful. |
| MFA pre-auth privado | La rama emite por 5 minutos un JWT HS256 con `iss='https://api.sacdia.app'`, `aud='sacdia-admin-mfa'`, `surface='admin'`, `client_type='ios'`, `purpose='mfa'`, `mfa_pending=true`, `aal='aal1'` y `amr=['pwd']`. Persiste únicamente SHA-256 del token junto al challenge; el token crudo solo se devuelve al llamador privado. |
| Encapsulación | `AdminEligibilityService`, `AdminSessionRepository`, `AdminSessionService`, `AdminMfaChallengeRepository` y `AdminMfaChallengeService` son providers privados de `AuthModule`; no se exportan ni se conectan a un controller. |
| Estado de implementación | La rama backend `codex/sacdia-admin-ios-auth`, hasta `b928c8b`, implementa credentials sin side effects/timing diferencial evitable, eligibility `active + access_panel`, persistencia/transacción 1:1, emisión y validación estricta del access token, revocación stateful y emisión/persistencia hash-only del challenge MFA pre-auth. Todavía no está integrada al runtime de referencia. |
| Publicación | No existe endpoint `/api/v1/auth/admin/*`, las migraciones no están desplegadas ni verificadas, y refresh rotation, finalización del challenge MFA, controller y OAuth siguen pendientes. |

#### Consecuencias

- La nueva superficie puede evolucionar sin regresiones deliberadas sobre consumidores legacy.
- La autorización permanece en dos capas: eligibility de entrada y permiso + scope por operación.
- Una caída de la autoridad de datos falla cerrada y no genera credenciales administrativas.
- La sesión administrativa es deliberadamente stateful: la revocación en base de datos tiene efecto inmediato.
- Mientras la implementación no se integre y no exista el controller, no hay un endpoint público nuevo que documentar en la referencia runtime ni se modifica el contrato legacy.

---

## 8. Motor de certificaciones: bandeja propia vs. `evidence-review`

### ✅ DECISIÓN FINAL (2026-08-11)

#### Contexto

Clases progresivas y honores comparten la cola unificada `evidence-review` con estados `VALIDATED` / `REJECTED`. El motor de certificaciones configurables introduce requisitos compuestos por componentes tipados, revisión requisito-a-requisito, comprobante de junta separado y cierre institucional con estados propios.

#### Decisión

| Tema | Contrato |
|------|----------|
| Bandeja de revisión | **Propia** bajo `/api/v1/certifications/reviews/*`. No adaptar certificaciones a `evidence-review`. |
| Motivo | Revisión por requisito con componentes (`TEXT_RESPONSE`, `FILE_EVIDENCE`, `LINKED_HONOR`, etc.), historial append-only y cierre final desacoplado del modelo clase/honor. |
| Costo asumido | Revisores institucionales (`director-lf`, `assistant-lf`) operan una bandeja adicional junto a la de evidencias de clases/honores. |
| Vocabulario de estados — requisito | `DRAFT` → `SUBMITTED` → `APPROVED` \| `CHANGES_REQUESTED` → `SUBMITTED` |
| Vocabulario de estados — clases/honores | `SUBMITTED` → `VALIDATED` \| `REJECTED` |
| Regla de integración | **No unificar** vocabularios ni bandejas sin ADR nuevo; mapear en UI si hace falta presentación conjunta. |
| Inscripción | Cada enrollment fija `certification_version_id` de una versión `PUBLISHED` inmutable. |
| Concurrencia | Envíos y decisiones de revisión exigen `lock_version` de `users_certifications`. |
| Evidencias | Bucket R2 privado; URLs firmadas de corta duración tras verificar ownership o scope de revisor. |

#### Consecuencias

- Admin y app móvil deben consumir endpoints documentados en `ENDPOINTS-LIVE-REFERENCE.md` §certifications, no la cola `evidence-review`.
- El endpoint legacy `PATCH .../progress` queda deprecado (2026-08-11) para inscripciones versionadas; responde `410 CERT_LEGACY_ENDPOINT_DEPRECATED`.
- Permisos nuevos (`certifications:configure`, `:publish`, `:review`, `:certify`) son ortogonales a `user_certifications:*` y a `certifications:read` (browse).

---

## 9. Bounded context `camporee-orders` independiente de Materials y FieldPaymentOrders

### ✅ DECISIÓN FINAL (2026-08-24)

#### Contexto

Una sección inscrita en un campamento o camporee necesita pedir artículos (playeras, gorras, pañoletas, libros) asignados a personas concretas, pagar esa obligación aparte de la inscripción y seguir la entrega hasta cada miembro.

Ya existen Materials (catálogo LF, stock, líneas anónimas), Field Payment Orders (purpose y costo uniforme por beneficiario de inscripción/seguro), `camporee_payments` (ledger por miembro sin carrito) y recursos/inventario de club (archivos digitales o bienes operativos). Extender cualquiera de esos modelos para un carrito heterogéneo, hecho bajo pedido y nominado al inscrito mezclaría invariantes y ampliaría regresiones.

#### Decisión

| Tema | Contrato |
|------|----------|
| Persistencia | Nuevo bounded context `camporee-orders`. No extender `MaterialProduct` / `MaterialOrder`, el purpose de `field_payment_orders`, `camporee_payments`, `resources` ni `club_inventory`. Reutilizar patrones (folio, state machine, proof, PDF, scope, caja LF), no tablas. |
| Elegibilidad | Solo inscritos: cada línea referencia `camporee_member_id` activo con estado `registered` \| `approved` del mismo camporee y sección. El cliente no envía `user_id` libre como autoridad. |
| Líneas | Nominadas; consolidado derivado `SUM(qty)` / `SUM(line_total_centavos)`. Sin tabla de allocations. |
| Pago | Independiente de la inscripción. Varios pedidos independientes por sección y camporee (suplementarios permitidos). |
| Cobro | El campo local cobra siempre, incluso catálogo Unión/División. Hecho bajo pedido en v1 (sin stock). |
| Tallas | Un eje `LETTER` \| `NUMERIC` \| `NONE`. Género = dos productos. |
| Proof | Flujo normal: upload → maker-checker → `PAID`. Excepción LF `authorize-without-proof` con motivo obligatorio; habilita entrega; un proof posterior no cambia `PAID` \| `DELIVERED`. |
| Entrega | Dos niveles: LF → sección (`DELIVERED`); el director marca cada línea `delivered_to_member`. `distribution_status` derivado `NOT_STARTED` \| `PARTIAL` \| `COMPLETE`. |
| Permisos | Familia `camporee-orders:*`. Read model `payment-obligations` une `field_payment_orders` + `material_orders` + `camporee_orders` sin fusionar folios. |
| Settings | En `local_camporees` / `union_camporees`: `orders_enabled` default `false`, `orders_opens_at`, `orders_deadline`. |
| Folio | `PED{yyyy}{####}`. |
| HTTP | 27 rutas bajo `/api/v1` en controllers Nest de `feat/camporee-orders` (worktree `/private/tmp/sacdia-backend-camporee-orders`, HEAD `47d12f3`). Registradas en `ENDPOINTS-LIVE-REFERENCE.md` con salvedad de rama: no están en el checkout principal ni en Neon. |
| Plan | [`docs/plans/2026-08-24-pedidos-camporees-consolidado-codex.md`](../plans/2026-08-24-pedidos-camporees-consolidado-codex.md) |

#### Consecuencias

- Materials, Field Payment Orders e inscripción de camporee conservan sus invariantes; un defecto de pedidos no muta esas tablas.
- “Pagos pendientes” es lectura agregada; cada acción abre el flujo dueño de la fuente.
- La elegibilidad “cualquier miembro activo de la sección” queda rechazada; el roster del camporee es la autoridad.
- Admin y app consumen los contratos de la rama; admin no impersona `deliver-to-member` y aún no cablea POST/PATCH de tallas en UI.
- Hasta merge + migración Neon, las rutas `/camporee-orders` y `GET /payment-obligations/pending` no existen en el runtime desplegado. Los códigos `CAMPOREE_ORDER_*` están en `ErrorCode` del worktree; i18n `errors.json` puede seguir incompleto.

---

## 10. Bounded context `camporee-supplies` independiente de `camporee-orders`

### ✅ DECISIÓN FINAL (2026-08-26)

#### Contexto

Una sección inscrita necesita planificar insumos de cocina por horario de entrega (hielo, tortillas, garrafones), pagar un total antes del evento y ajustar solo días no congelados. Mercancía (`camporee-orders`) es nominada a `camporee_member_id`, folio PED inmutable y entrega LF→sección→miembro. Materials y Field Payment Orders tampoco modelan día/slot/kg del camporee.

#### Decisión

| Tema | Contrato |
|------|----------|
| Persistencia | Nuevo bounded context `camporee-supplies`. No extender `camporee_orders`, `MaterialOrder`, `field_payment_orders` ni inventario de club. Reutilizar patrones (folio, scope territorial, caja LF, Pagos pendientes), no tablas. |
| Unidad | La **sección** inscrita (`registered\|approved`). Un plan por sección. Sin líneas nominadas. |
| Líneas | `(date, slot_id, product_id, qty)`. El club elige slots del organizador; no inventa horarios. Totales de día derivados. |
| Emisores club | Solo `director`, `secretary`, `secretary-treasurer`. |
| Config / caja | LF `director-lf` / `assistant-lf`; unión si el evento es de unión; admin por rol. |
| Freeze | TZ del camporee. `supply_edit_cutoff_local_time` default `21:00`. DRAFT libre. SUBMITTED: no hoy/pasado; mañana solo antes del corte. Club → `CAMPOREE_SUPPLIES_DAY_LOCKED`. LF/unión/admin bypass con motivo obligatorio. |
| Precio | Snapshot del catálogo. PATCH de costo bloqueado si hay algún plan SUBMITTED (`CAMPOREE_SUPPLIES_PRICE_LOCKED`). |
| Pago | Primer submit → un PRINCIPAL `INS{yyyy}{####}` (contador propio). Aumentos CHARGE; reducciones REFUND. PRINCIPAL no se reescribe. |
| Entrega | Parcial a la sección. No exige PRINCIPAL PAID. No hay `delivered_to_member`. |
| UX | Dentro de la ficha/detalle del camporee. Admin no impersona submit del club. |
| Pagos pendientes | Fuentes `CAMPOREE_SUPPLY_CHARGE` / `CAMPOREE_SUPPLY_REFUND`, purpose `CAMPOREE_SUPPLIES`, acciones `PAY_AT_CAMP` / `PROCESS_REFUND`. No fusionar con PED. |
| HTTP | 29 rutas bajo `/api/v1` en `feat/camporee-supplies` (worktree `/private/tmp/sacdia-backend-camporee-orders`). |
| Plan | [`docs/plans/2026-08-26-camporee-supplies.md`](../plans/2026-08-26-camporee-supplies.md) |

#### Consecuencias

- Un defecto de insumos no muta mercancía, inscripción ni materiales.
- Folios INS y PED conviven en Pagos pendientes como filas distintas.
- Hasta merge + migración Neon, las rutas `/supply-*` no existen en el runtime desplegado.

---

## 11. Proxy OCR keyless: Render → HTTPS HMAC → Cloud Run → Vision US

### ✅ DECISIÓN ACEPTADA (2026-10-02; revisada 2026-10-07) — aprobada en local, NO desplegada

#### Contexto

La lectura OCR de certificados usa Google Cloud Vision. En la Mac funciona con ADC personal (modo `direct`), pero Render no puede usar ADC personal ni una clave de cuenta de servicio: la organización de Google impone `iam.disableServiceAccountKeyCreation` y no se propone debilitar esa política ni se probó una excepción exclusiva. Render tampoco tiene una identidad de Google nativa. Hacía falta una vía de autenticación hacia Vision sin credenciales Google de larga vida en Render.

#### Decisión

| Tema | Contrato |
|------|----------|
| Ruta | Render (API y worker) → HTTPS con HMAC-SHA256 entre servidores → proxy en Cloud Run (`us-east4`) → Vision en el endpoint `us-vision.googleapis.com`. Cloud Run usa su identidad de servicio (ADC), sin claves. |
| Estado | Aprobado en local en Task0, 1, 1b, 2, R, 3 y 4 (`PASS_LOCAL_SLICE`). **No desplegado**: no existen Cloud Run, Firestore, Secret Manager ni el modo `remote` en Render. |
| Autenticación | HMAC v1 con `kid`, llave actual y anterior para rotación, secreto de al menos 32 bytes por entorno, nonce y ventana de ±120 s. El replay es durable (Firestore). Invocación pública de Cloud Run con `run.googleapis.com/invoker-iam-disabled`, sin `allUsers`; la firma es la única barrera de aplicación. |
| Estado durable | Firestore Standard regional (`us-east4`), solo metadata: operación, nonce y cuota diaria. `CALLING` se confirma antes de llamar a Vision. Incertidumbre o respuesta `COMPLETE` perdida: revisión manual, sin segunda llamada. No hay exactly-once ni caché de texto. |
| Cuota | 400 páginas por día UTC y por entorno, compartidas entre usuarios (`OCR_MAX_PAGES_PER_ENV_PER_DAY`, 1..400). |
| Contención PDF | `pdf-lib` ya corría en el proceso API de Render sin aislamiento. Se aplicó un parche a `pdf-lib` 1.17.1 (tope de descompresión 1 MiB por stream y 2 MiB acumulados, con `AsyncLocalStorage`) y la validación corre en un `worker_thread` descartable con heap acotado, un worker a la vez, dimensionado para el plan Free de Render (512 MB, 0,1 CPU). Render cuenta las páginas y las firma (`X-Ocr-Page-Count`); el proxy **no** parsea PDF y exige cobertura exacta de Vision. `confirm` responde HTTP 429 `CERTIFICATE_IMPORT_PDF_BUSY` cuando no hay turno. |
| Errores | Solo un sobre JSON v1 válido decide el código. 429/5xx/504 de plataforma sin sobre es `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`, nunca `CERTIFICATE_IMPORT_OCR_QUOTA`. API pública, schema, Flutter y aprobación humana no cambian. |
| Plazos y perfil | Vision 25 s, proxy 35 s, cliente 40 s; 1 vCPU, 512 MiB, instancias mínimas 0, máximas 1, concurrencia 1. Valores tentativos hasta el humo. |
| Modos | `OCR_MODE=direct` (ADC en la Mac) o `remote`. Obligatorio con `NODE_ENV=production`; `remote` incompleto no arranca ni cae a ADC. |

#### Alternativas

- **Clave de cuenta de servicio en Render**: imposible, la organización bloquea su creación.
- **Worker en Google que pide trabajos a un endpoint privado de Render**: evita el ingreso público al proxy, pero exige leases, acuses, planificación y estados de entrega nuevos, y no encaja con el contrato síncrono interno elegido.
- **API key estándar de Vision (evaluada y descartada el 2026-10-07)**: la organización permite API keys estándar (solo bloquea las vinculadas a cuentas de servicio), pero Vision solo tiene cuotas **por minuto** (1800 por minuto por defecto) y ningún tope diario para estas llamadas. Una key filtrada expondría del orden de **US$19 000 por día** (1800 solicitudes por minuto durante 24 horas con PDF de cinco páginas, a US$1,50 por 1000 unidades). Un HMAC filtrado queda acotado por la cuota diaria a **400 páginas, unos US$0,60 por día**. Decisión humana: seguir con el proxy.
- **Pre-escaneo `zlib` del PDF para acotar la descompresión**: rechazado en revisión (evadible con nombres escapados, comentarios y cabeceras partidas; rechazaba filtros que `pdf-lib` no decodifica). Se reemplazó por el parche del decodificador más el worker descartable.
- **Parseo de PDF dentro del proxy (proceso hijo con `pdf-lib`)**: reemplazado. El riesgo vive primero en Render, que ya valida y cuenta las páginas; un PDF que miente cuesta como máximo las N ≤ 5 páginas pedidas.

#### Consecuencias

- Se agregan un servicio (Cloud Run) y un almacén durable (Firestore) adicionales, con su costo y su operación.
- La seguridad descansa en el secreto HMAC y en la cuota diaria; Google keyless **no** elimina el secreto de aplicación ni el riesgo de costo. Las instancias máximas y las alertas no son un tope de factura.
- Ante respuesta perdida o ejecución incierta, el documento va a revisión manual: se acepta no repetir Vision a cambio de no duplicar el gasto.
- Con Render en plan Free, el worker PDF y sus supuestos de memoria no están medidos en Render. Al pasar a un plan de pago hay que revisar topes y plazos y sincronizar `render.yaml` (declara `starter`).
- Pendientes antes de desplegar: entrypoint de producción del proxy, campo `expireAt` de tipo `Timestamp` en todos los documentos del ledger (decisión del usuario, 2026-10-07: opción a) y política TTL de Firestore sobre `expireAt` en `operations`, `nonces` y `quota` una vez desplegado ese código (las fechas de purga lógica siguen siendo texto ISO y siguen decidiendo la lógica; el TTL solo borra físicamente y no es autenticación), herramienta de humo y verificación de las políticas de la organización en el proyecto de producción.
- Nada de esto es una autorización de infraestructura. Pasos, permisos mínimos y rollback: [runbook de infraestructura](../guides/ocr-proxy-preprod-infra.md) y [runbook de uso](../guides/google-vision-certificate-ocr.md). Diseño y plan: [diseño](../plans/2026-10-02-vision-keyless-design.md), [plan](../plans/2026-10-02-vision-keyless-plan.md).

---

**Generado**: 2026-01-29
**Actualizado por**: Usuario
**Última actualización**: 2026-10-07 (ADR #11 — proxy OCR keyless, aprobado en local, no desplegado). Anterior: 2026-08-26 (ADR #10 — camporee-supplies en rama `feat/camporee-supplies`, no Neon)
**Status**: ✅ Decisiones confirmadas; ADR #7 parcialmente implementada en rama, no expuesta en runtime; ADR #9 y #10 implementadas en worktree `feat/camporee-supplies` / historial de orders, no merge Neon
