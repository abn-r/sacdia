# Credencial QR y tarjeta virtual

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)

## Descripcion de dominio

Cada miembro tiene una credencial digital: una tarjeta virtual en la app con sus datos visibles y un código QR. El QR contiene un JWT de corta duración que identifica al miembro. Un directivo con permiso lo escanea para identificar a la persona (con datos de primeros auxilios) y, si lo hace desde una actividad, registra su asistencia.

## Que existe (verificado contra codigo)

### Backend (`src/qr/`)

Controller con `JwtAuthGuard` a nivel de clase.

| Método | Ruta (`/api/v1`) | Autorización | Límite |
|---|---|---|---|
| GET | `/qr/member/token` | `@SkipPermissions` (cualquier usuario autenticado) | 10/min |
| GET | `/qr/me` | `@SkipPermissions` | 10/min |
| GET | `/qr/me/card` | `@SkipPermissions` | 10/min |
| GET | `/qr/me/card.pdf` | `@SkipPermissions` | 10/min |
| POST | `/qr/validate` | `qr:validate` + `AuthorizationResource({ type: 'active_assignment' })` | 60/min |
| POST | `/qr/scan` (alias heredado) | `attendance:manage` + `active_assignment` | 60/min |

Reglas verificadas en `qr.service.ts`:

- **Token**: JWT HS256 con `sub = user_id`, `aud = sacdia:qr-member` y `ver`; dura 24 horas. Se firma con `QR_JWT_SECRET`, que debe tener al menos 32 caracteres y ser distinto de `BETTER_AUTH_SECRET` (`qr-jwt-secret.ts`; si no, el arranque falla). El token no se guarda en base de datos.
- **Validación**: se rechaza con `QR_TOKEN_INVALID` si la firma, la audiencia o la versión no coinciden, o si falta `sub`. Si el usuario no existe: `QR_MEMBER_NOT_FOUND`.
- **Respuesta de `validate`**: datos del miembro (nombre, foto con URL firmada, club y tipo de club de la asignación activa más reciente, clase actual, tipo de sangre y contacto de emergencia principal), más `attendance` y `scanned_at`.
- **Asistencia** (si el body trae `activity_id`): la actividad debe existir (`QR_ACTIVITY_NOT_FOUND`) y no ser virtual (`platform = 1` → `QR_ACTIVITY_VIRTUAL_NO_SCAN`); el escáner debe poder gestionar la actividad. El miembro se agrega a `activities.attendees` (JSON); si ya estaba, devuelve `already_present: true` sin duplicar. Emite el evento de logros `activity.attended` con `source: 'qr-scan'` (un fallo ahí solo se registra en log).
- **Tarjeta (`me/card`)**: token más campos visuales, clase actual y tipo de sangre; no incluye contacto de emergencia ni permisos.
- **PDF (`me/card.pdf`)**: PDF imprimible con los datos de la tarjeta y el token como texto; el backend no dibuja el QR. Las respuestas de `me`, `me/card` y `me/card.pdf` llevan `Cache-Control: no-store`.

### App móvil

- `lib/features/virtual_card/`: `VirtualCardView` consume `GET /qr/me/card` y dibuja el QR en el dispositivo (`qr_flutter`; `screen_brightness` sube el brillo en pantalla completa). Se abre desde el perfil, los ajustes y el detalle de actividad.
- `lib/features/qr/`: `QrScannerView` (`mobile_scanner`) llama a `POST /qr/validate`. Se abre desde ajustes (solo identificación) y desde el detalle de actividad con `activityId` (registra asistencia). El data source también expone `GET /qr/member/token`.

### Admin

- Sin pantallas.

### Base de datos

- Sin tablas propias. Lee `users` (incluido `users.blood`), `club_role_assignments`, `enrollments` y `emergency_contacts`; escribe `activities.attendees`.

## Gaps y pendientes

- El token no se puede revocar antes de que venza (24 h).
- `GET /qr/me/card.pdf` no tiene consumidor en la app ni en el admin.
- La asistencia se guarda como arreglo JSON en `activities.attendees`, sin tabla de asistencia ni hora de escaneo por miembro.
