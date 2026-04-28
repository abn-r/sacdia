# QR + Tarjetas virtuales — Plan de ejecución

**Estado**: PLAN DE IMPLEMENTACIÓN
**Audiencia**: agente IA o ingeniero que ejecutará la implementación
**Origen**: línea 3 del roadmap (`docs/plans/ia-qr-tarjetas-virtuales.md`)
**Fecha**: 2026-04-27

---

## 1. Resumen ejecutivo

Sistema de credencial virtual del miembro con QR firmado para identificación rápida en eventos presenciales. La tarjeta vive en la app móvil (`sacdia-app`) y puede compartirse como PDF/imagen. El QR es **dinámico con rotación cada 24h** (mitiga robo de credencial). El backend valida el QR vía endpoint dedicado.

El alcance se divide en 3 fases ordenadas:
- **Fase 1**: Backend QR (firma HMAC, endpoint validación)
- **Fase 2**: Frontend tarjeta + QR en app móvil
- **Fase 3**: Escáner para roles de coordinador/director

Investidura, certificaciones, asistencia masiva por escaneo y wallet nativo (Apple/Google) quedan para iteración posterior.

---

## 2. Decisiones tomadas

| Decisión | Elegido | Motivo |
|----------|---------|--------|
| Tipo de QR | **Dinámico**, rota cada 24h | Mitiga robo. Estático presenta riesgo si screenshot circula. |
| Algoritmo de firma | **HMAC-SHA256** con secret en env | Sencillo, suficiente. Sin asimetría requerida — backend confía en sí mismo. |
| Payload del QR | `{ user_id, club_id, role, expires_at, sig }` codificado base64url | Mínimo. Servidor reconstruye contexto al validar. |
| Renderizado QR | Librería local (Flutter `qr_flutter`, admin `qrcode.react`) | Sin llamadas externas para generar. |
| Emisión / renovación | Endpoint backend `GET /api/v1/qr/me` | Self-service: devuelve o re-emite el token vigente para el usuario autenticado. |
| Validación | Endpoint backend `POST /api/v1/qr/validate` | Centraliza verificación. |
| Tarjeta visible en | **App móvil** primero. Admin/web no es parte del alcance actual. | Móvil es portable. Web se deja para una fase futura si hace falta. |
| Foto institucional | Reutiliza `users.profile_image_url` existente (R2) | Ya hay UI de upload + recorte. |
| Vigencia | Atada a `is_active=true` y `is_member=true` del usuario + asignación de club activa | Si el miembro deja el club, QR caduca. |
| Roles visibles | Solo el rol activo principal (no listar histórico) | Privacidad + simplicidad UX. |

---

## 3. Arquitectura

### 3.1 Backend (`sacdia-backend`)

**Módulo nuevo**: `src/qr/` — `qr.controller.ts`, `qr.service.ts`, `qr.module.ts`, `dto/`

**Endpoints**:

```
GET    /api/v1/qr/me                 # Devuelve el QR vigente (cacheado, regenera si <2h vigencia)
POST   /api/v1/qr/validate           # Valida un QR escaneado (cualquier usuario con permiso `qr:validate`)
GET    /api/v1/qr/me/card            # Devuelve metadata de la tarjeta (datos para renderizar)
GET    /api/v1/qr/me/card.pdf        # Genera PDF descargable de la tarjeta
```

**Contrato actual**: el QR canónico es **stateless** y se firma como JWT/HMAC con expiración. No existe una tabla QR dedicada ni un flujo de revocación persistente en el schema actual.

**Lógica de firma** (`qr.service.ts`):

```ts
import * as crypto from 'crypto';

const SECRET = process.env.QR_HMAC_SECRET; // 32+ bytes random
const TTL_HOURS = 24;

interface QrPayload {
  uid: string;        // user_id
  cid: number;        // club_id
  role: string;       // role code, ej 'aventurero', 'guia-mayor'
  exp: number;        // unix epoch seconds
  iat: number;        // issued at
}

function sign(payload: QrPayload): string {
  const json = JSON.stringify(payload);
  const sig = crypto.createHmac('sha256', SECRET).update(json).digest('hex');
  const body = Buffer.from(json).toString('base64url');
  return `${body}.${sig}`;
}

function verify(token: string): QrPayload | null {
  const [body, sig] = token.split('.');
  if (!body || !sig) return null;
  const json = Buffer.from(body, 'base64url').toString('utf8');
  const expectedSig = crypto.createHmac('sha256', SECRET).update(json).digest('hex');
  if (!crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expectedSig))) return null;
  const payload: QrPayload = JSON.parse(json);
  if (payload.exp < Math.floor(Date.now() / 1000)) return null;
  return payload;
}
```

El QR escaneado tiene la forma `sacdia://qr/v1/<token>` o un URL `https://app.sacdia.com/qr/<token>` (deep link). Recomendado: URL para fallback web, y la app móvil intercepta vía deep link.

**Validación** (`POST /qr/validate`):
1. Parse `body` + verify HMAC/JWT
2. Verificar expiración y vigencia del claim firmado
3. Verificar `users.is_active=true`, `is_member=true`
4. Verificar que `cid` siga vigente en `club_role_assignments` activo del usuario
5. Devolver `{ valid: true, member: { name, photo_url, role, club_name, tier } }`

**RBAC**:
- `qr:issue:self` — todo miembro autenticado
- `qr:validate` — directores, coordinadores, secretarios

### 3.2 Mobile (`sacdia-app`)

**Feature nueva**: `lib/features/virtual_card/`

**Pantallas**:
- `virtual_card_screen.dart` — vista principal de la tarjeta del usuario
- `qr_full_screen.dart` — modal a pantalla completa con QR ampliado + brillo máximo (para escaneo)
- `qr_scanner_screen.dart` — solo visible para roles con `qr:validate` (camera_input + render `qr_code_scanner` package)
- `validation_result_sheet.dart` — bottom sheet con resultado de validación

**Estado**: provider Riverpod `virtualCardProvider` que:
1. Llama `GET /qr/me/card` al montar
2. Si `expires_at < ahora + 2h` → vuelve a consultar `GET /qr/me` para re-emitir el token vigente
3. Cachea localmente 24h (sobrevive cierres de app si el QR sigue vigente)

**Acceso**:
- Tab bar: agregar ícono "Mi tarjeta" en bottom nav (o como acción rápida desde dashboard)
- Pantalla principal: muestra la tarjeta diseñada (ver `tarjeta-virtual-design-spec.md`)
- Botón "Mostrar QR en grande" → `qr_full_screen` con QR a 80% del ancho de pantalla, brillo máximo automático
- Botón "Compartir" → genera PDF/imagen vía endpoint `GET /qr/me/card.pdf` y abre share sheet del OS

**Paquetes Flutter requeridos**:
- `qr_flutter` (renderizar QR localmente — el server entrega el TOKEN, el cliente dibuja)
- `mobile_scanner` (escáner para validators) — sustituto moderno de `qr_code_scanner`
- `share_plus` (compartir PDF/imagen)
- `screen_brightness` (subir brillo en pantalla QR)

### 3.3 Admin (`sacdia-admin`)

**Fuera de alcance en esta fase**.

- No se implementan vistas admin para descargar PDFs de terceros.
- No se implementa auditoría persistente de tokens QR ni un panel `/dashboard/system/qr-tokens`.
- Si más adelante hace falta soporte para impresión asistida o troubleshooting, se evalúa como fase futura separada.

---

## 4. Tareas por fase

### Fase 1: Backend (subagente backend-developer Sonnet)

1. Verificar que el schema no requiere tabla QR dedicada; mantener contrato stateless con expiración.
2. Env var `QR_HMAC_SECRET` agregada a `.env.example` con instrucciones (32+ bytes random).
3. Módulo `src/qr/` con controller + service + DTO + módulo wired in `app.module.ts`.
4. Endpoints self-service (`GET /qr/me`, `GET /qr/me/card`, `GET /qr/me/card.pdf`, `POST /qr/validate`) con RBAC.
5. PDF service reutilizando `pdfmake` (o lo que use monthly-reports) para `card.pdf` — A6 size landscape, igual al diseño del frontend.
6. i18n keys para mensajes de error: `errors.qr.invalid`, `errors.qr.expired`, `errors.qr.user_not_active` × 4 locales.
7. ErrorCodes: `QR_INVALID`, `QR_EXPIRED`, `QR_USER_INACTIVE`.
8. Tests unitarios del service (sign/verify roundtrip, expiry).
9. Tests E2E del controller (`GET /qr/me` renew/fetch → validate).

**Verificación**:
- `pnpm tsc --noEmit` clean
- `pnpm test src/qr` pasa
- Smoke manual: consultar `GET /qr/me`, validar el token, re-consultar `GET /qr/me` y comprobar expiración/invalidez.

**Commit**: `feat(qr): add virtual card QR system with HMAC-SHA256 dynamic tokens`

### Fase 2: Mobile tarjeta + QR (subagente mobile-developer Sonnet)

Implementar usando el diseño en `docs/plans/tarjeta-virtual-design-spec.md`.

1. Carpeta `lib/features/virtual_card/` con estructura clean (`data/`, `domain/`, `presentation/`).
2. Provider Riverpod + repository que consume endpoints backend.
3. Pantalla `virtual_card_screen` siguiendo el diseño exacto del spec.
4. Pantalla `qr_full_screen` con QR ampliado + auto-brillo.
5. Botón "compartir" que descarga `card.pdf` y abre share sheet.
6. Entrada desde tab bar o dashboard (decisión de UX: agregar 5to tab "Mi tarjeta" o widget destacado en home).
7. i18n keys siguiendo convención `easy_localization` × 4 locales.
8. Tests widget mínimos (renderizado happy path).

**Verificación**:
- `dart analyze` clean
- 4-locale parity en `assets/translations/*.json`
- Smoke en simulador iOS + emulador Android

**Commit**: `feat(virtual_card): add virtual member card with dynamic QR`

### Fase 3: Mobile escáner (subagente mobile-developer Sonnet)

1. Pantalla `qr_scanner_screen` solo accesible si el usuario tiene rol con `qr:validate`.
2. Flow: escanear QR → POST a `/api/v1/qr/validate` con el token → mostrar `validation_result_sheet` con foto, nombre, rol, club, tier de achievements del miembro validado.
3. Manejo de errores: QR inválido, expirado, sin internet.
4. Botón "Escanear otro" para validar en lote (eventos presenciales).
5. Historial local de las últimas 50 validaciones de la sesión (para auditoría rápida).
6. Acceso desde menú lateral o pantalla "Acciones" del director/coordinador.

**Verificación**:
- `dart analyze` clean
- Permisos cámara configurados en `Info.plist` + `AndroidManifest.xml`
- Smoke manual: escanear desde otro dispositivo.

**Commit**: `feat(virtual_card): add QR scanner for directors/coordinators`

### Fase 4 (futura, no incluida en esta entrega)

- Apple Wallet / Google Wallet integration
- Asistencia por escaneo masivo en `activities` y `camporees`
- Inscripción rápida vía QR del club
- IA: resúmenes de validaciones, detección de anomalías
- Panel admin para descarga de PDFs de terceros
- Ledger persistente de revocación/auditoría de tokens QR, si el negocio lo necesita

---

## 5. Riesgos + mitigaciones

| Riesgo | Mitigación |
|--------|-----------|
| Robo de credencial vía screenshot | Rotación 24h del token vigente + backend valida expiración y firma (alertar si reuso desde geolocalización distinta — futuro) |
| `QR_HMAC_SECRET` filtrado | Rotación documentada en `docs/canon/secrets-rotation.md`. Cambiar invalida todos los QR. |
| Falsificación si HMAC débil | HMAC-SHA256 con secret 32+ bytes es seguro. Documentar mínimo. |
| Privacidad de menores | El QR muestra solo nombre + rol + foto + club. No edad, no email, no teléfono. |
| Conexión perdida durante validación | Cliente cachea QR vigente (puede mostrar offline); validación REQUIERE red — fallback "validar offline" punto futuro |
| Performance al validar masivamente | Endpoint `validate` indexa por `token_hash`. 100 ms p99 esperado. |

---

## 6. Decisiones diferidas

- **Geolocalización en validación**: registrar `lat/lng` del validador para detectar fraudes (escaneos desde lugares imposibles). Defer a Phase 4.
- **QR offline grace period**: permitir validación local sin red durante eventos presenciales con conectividad pobre. Defer.
- **Carnés impresos**: el PDF descargable self-service cubre el caso actual. Imprenta institucional masiva o PDFs de terceros = punto comercial/futuro, no técnico actual.
- **Multi-club**: si un usuario pertenece a 2 clubes simultáneos, el QR identifica al primario por defecto. Permitir switch en Phase 4.

---

## 7. Criterio de aceptación

- ✅ Miembro abre la app, ve su tarjeta con foto + nombre + rol + club + tier.
- ✅ Miembro toca "Mostrar QR" → QR a pantalla completa, brillo al 100%.
- ✅ Director escanea con su app → ve foto + nombre + rol + club del miembro en <2s.
- ✅ Si el miembro fue desactivado o cambió de club, el QR escaneado muestra "Credencial inválida".
- ✅ Tarjeta puede descargarse como PDF y compartirse.
- ✅ QR rota automáticamente cada 24h sin acción del usuario.

---

## 8. Próximo paso operativo

1. Generar el `QR_HMAC_SECRET` (32+ bytes random) y agregarlo a Render env vars + `.env.local` dev.
2. Lanzar subagente Fase 1 (backend) con este documento como referencia.
3. Validar Fase 1 en entorno dev (smoke endpoint).
4. Lanzar Fase 2 (mobile tarjeta) en paralelo a Fase 3 (escáner) — diferentes pantallas, no race.
5. QA cross-device.
6. Documentar en `docs/canon/runtime-qr.md` y agregar canon a la baseline.
