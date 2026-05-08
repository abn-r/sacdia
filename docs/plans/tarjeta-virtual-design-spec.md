# Tarjeta virtual — Spec de diseño

**Estado**: SPEC DE DISEÑO LISTO PARA IMPLEMENTAR
**Audiencia**: agente IA o developer mobile que implementará la pantalla
**Plataformas**: iOS + Android (Flutter, paquete `sacdia-app`)
**Origen**: complemento de `docs/plans/qr-tarjetas-virtuales-implementacion.md`

---

## 1. Concepto

Tarjeta de identificación digital del miembro Conquistador / Aventurero / Guía Mayor. Presente en la app móvil. Diseñada como un **carnet digital premium** que el miembro **muestra con orgullo** en eventos presenciales.

Inspiración: tarjetas de embarque digitales (Apple Wallet boarding pass) + credenciales corporativas modernas + estilo institucional Adventista.

**No es**: una tarjeta de crédito plastificada genérica. **Sí es**: una credencial institucional con estética cuidada, jerarquía visual clara y elementos de gamificación (tier de achievements visible).

---

## 2. Especificaciones físicas (en pantalla)

| Elemento | Valor |
|----------|-------|
| Aspect ratio | 5:8 (vertical) — referencia ISO/IEC 7810 ID-1 girada |
| Ancho en pantalla | 90% del ancho del viewport, max 360pt |
| Alto | calculado por aspect ratio |
| Border radius | 24pt (suave, premium) |
| Sombra | `0 12px 32px rgba(0,0,0,0.18)` — eleva del fondo |
| Padding interno | 24pt todos los lados |

---

## 3. Layout (de arriba hacia abajo)

```
┌───────────────────────────────────────┐
│  [logo SACDIA]      [club logo]       │  ← header band (60pt alto)
├───────────────────────────────────────┤
│                                       │
│         ┌──────────────┐              │  ← foto circular 120×120pt
│         │              │              │     borde según tier (oro/plata/etc)
│         │    [foto]    │              │
│         │              │              │
│         └──────────────┘              │
│                                       │
│         JUAN PÉREZ MARTÍNEZ           │  ← nombre completo (24pt bold)
│         CONQUISTADOR · AMIGO          │  ← rol institucional (14pt medium)
│                                       │
│  ─────────────────────────────────    │  ← divider sutil
│                                       │
│   CLUB                                │  ← micro-label (10pt uppercase)
│   Trompetas de Sión                   │  ← valor (16pt regular)
│                                       │
│   SECCIÓN                             │
│   Unidad Pioneros                     │
│                                       │
│   MIEMBRO DESDE                       │
│   Marzo 2024                          │
│                                       │
│  ─────────────────────────────────    │
│                                       │
│         ┌─────────────────┐           │  ← QR (160×160pt centrado)
│         │                 │           │
│         │   [QR CODE]     │           │
│         │                 │           │
│         └─────────────────┘           │
│                                       │
│         [Mostrar en grande →]         │  ← ghost button (subtle)
│                                       │
├───────────────────────────────────────┤
│  ID #SACDIA-202410-0421    [tier 🏆]  │  ← footer (10pt) + tier badge
└───────────────────────────────────────┘
```

---

## 4. Sistema de diseño

### 4.1 Color base (light mode)

| Token | Hex | Uso |
|-------|-----|-----|
| `card.bg.primary` | `#FFFFFF` | fondo principal de la tarjeta |
| `card.bg.header` | `#0F2645` | header band azul Adventista |
| `card.text.primary` | `#0F1B2D` | nombre, valores principales |
| `card.text.secondary` | `#5A6378` | micro-labels (uppercase) |
| `card.text.tertiary` | `#9099AB` | footer, hints |
| `card.divider` | `#E5E8EE` | líneas finas |
| `card.shadow` | `rgba(15,27,45,0.18)` | sombra de elevación |

### 4.2 Color base (dark mode)

| Token | Hex | Uso |
|-------|-----|-----|
| `card.bg.primary` | `#1A2235` | fondo principal |
| `card.bg.header` | `#0B1A36` | header band |
| `card.text.primary` | `#F4F7FB` | nombre, valores |
| `card.text.secondary` | `#A0AABF` | micro-labels |
| `card.text.tertiary` | `#5A6378` | footer |
| `card.divider` | `#2A344C` | líneas |

### 4.3 Tier (achievements rank) — borde de la foto + badge

| Tier | Color borde foto | Badge color | Glow |
|------|------------------|-------------|------|
| Bronze | `#A86E3D` | `#A86E3D` con texto blanco | sutil bronce |
| Silver | `#A8B0BD` | `#A8B0BD` texto `#0F1B2D` | sutil plata |
| Gold | `#D4AF37` | `#D4AF37` texto `#0F1B2D` | brillo dorado |
| Platinum | `#5DD9C8` | `#5DD9C8` texto `#0F1B2D` | aqua frío |
| Diamond | gradiente `linear(135deg, #B0E0FF, #C5A6FF, #FFE4F1)` | gradiente | shimmer animado sutil |

El **borde de la foto** tiene 4pt de grosor con el color del tier. La **badge en el footer** es una pill con ícono de copa (lucide `trophy`) + label del tier en mayúsculas (`BRONCE`, `PLATA`, `ORO`, `PLATINO`, `DIAMANTE`).

### 4.4 Tipografía

Usar la fuente del sistema (Flutter `theme.textTheme` con la familia ya definida en sacdia-app — probablemente Inter o SF Pro).

| Elemento | Tamaño | Peso | Letter spacing |
|----------|--------|------|----------------|
| Nombre completo | 24pt | 700 (bold) | -0.4 |
| Rol institucional | 14pt | 500 (medium) | 0.6, UPPERCASE |
| Micro-labels (CLUB, SECCIÓN...) | 10pt | 600 | 1.2, UPPERCASE |
| Valores | 16pt | 400 (regular) | 0 |
| Footer ID | 10pt | 500 | 0.4, monospace |
| Tier badge | 11pt | 700 | 0.8, UPPERCASE |

### 4.5 Iconografía

- Lucide-react/lucide-flutter equivalente: `award`, `trophy`, `qr-code`, `share-2`, `download`, `refresh-cw`, `expand`.
- Tamaño consistente: 16pt para inline, 24pt para acciones.

---

## 5. Estados visuales

### 5.1 Activa (default)

Renderizado tal cual descrito arriba. Color primario completo. QR vigente.

### 5.2 Cargando (skeleton)

Placeholders shimmer en cada bloque. Sin spinners — solo el shimmer de izquierda a derecha (1.5s loop) sobre cada bloque (foto, nombre, rol, valores, QR area).

### 5.3 Sin red

Tarjeta visible con datos del cache local. Banner sutil arriba: `⚠ Modo sin conexión — datos cacheados`. QR puede mostrarse pero validador externo no podrá completar — la app del validador maneja eso.

### 5.4 QR expirado

Si por alguna razón el QR caducó y no pudo renovarse (sin red prolongado):
- QR area se vuelve gris con ícono `refresh-cw` central
- Texto: "Renová tu credencial cuando recuperes conexión"
- Botón "Reintentar"

### 5.5 Cuenta desactivada

Tarjeta con overlay translúcido rojo (`#C53D3D` con 20% opacity) y texto central:
> "Esta credencial no está activa. Comunicate con tu director."

QR oculto.

### 5.6 Modo presentación QR (full screen)

Al tocar "Mostrar en grande":
- Fondo blanco puro
- QR a 80% del ancho de pantalla, centrado
- Brillo de pantalla forzado al 100% (vía `screen_brightness`)
- Bajo el QR: nombre del miembro en grande (28pt) + rol pequeño
- Botón cerrar arriba derecha (X grande, fácil de tocar)
- Auto-restablece brillo al cerrar

---

## 6. Interacciones

| Acción | Comportamiento |
|--------|----------------|
| Tap en QR area | abre `qr_full_screen` |
| Tap en foto | abre visor de foto en pantalla completa (zoom + pinch) |
| Swipe horizontal | si el usuario pertenece a múltiples clubes, switchea entre tarjetas (futuro) |
| Pull-to-refresh | renueva / re-emite el token vigente |
| Botón "Compartir" | bottom sheet con opciones: "Descargar PDF", "Compartir como imagen", "Copiar link de validación" |
| Botón "Renovar QR" | re-emite el token vigente manualmente (útil si sospecha que el QR fue comprometido) |

---

## 7. Animaciones

- **Entrada de la tarjeta**: scale 0.96 → 1.0 con spring (damping 0.8) + fade in 200ms
- **Tap en QR**: scale 0.97 al press, vuelta a 1.0 al release
- **Tier Diamond**: shimmer sutil sobre el borde de la foto (loop 4s, opacity 0.3 max)
- **Refresh QR**: el QR antiguo hace fade out 200ms, fade in del nuevo 200ms con un sutil pulse del borde
- **Modo presentación**: transición hero del QR pequeño al grande (Flutter `Hero` widget)

Mantener animaciones discretas. Nada que distraiga del propósito (mostrar la credencial).

---

## 8. Accesibilidad (WCAG AA mínimo)

- Contraste mínimo 4.5:1 para texto sobre fondo (validado para light + dark)
- Tamaño táctil mínimo 44×44pt para todos los botones
- VoiceOver / TalkBack: cada bloque etiquetado:
  - Foto: "Foto de perfil de Juan Pérez"
  - Nombre: leído como nombre completo
  - QR: "Código QR. Doble toque para ampliar."
  - Botón compartir: "Compartir credencial. Botón."
- Soporte Dynamic Type / Font Scale (Flutter `MediaQuery.textScaleFactor`) — la tarjeta no debe romperse con fuentes grandes (max scale 1.5)
- Alternativa al QR: el footer muestra el ID `#SACDIA-202410-0421` — si el QR falla, el director puede ingresar el ID manualmente.

---

## 9. Datos requeridos del backend

Endpoint `GET /api/v1/qr/me/card` devuelve:

```json
{
  "user_id": "usr_abc123",
  "name_full": "Juan Pérez Martínez",
  "photo_url": "https://r2.sacdia.com/profiles/usr_abc123.jpg",
  "role_label": "Conquistador · Amigo",
  "role_code": "amigo",
  "club_name": "Trompetas de Sión",
  "club_logo_url": "https://r2.sacdia.com/clubs/12.png",
  "section_name": "Unidad Pioneros",
  "member_since": "2024-03-15",
  "achievement_tier": "gold",
  "card_id_short": "SACDIA-202410-0421",
  "qr_token": "eyJ1aWQiOiJ1c3JfYWJj...sig",
  "qr_expires_at": "2026-04-28T17:00:00Z",
  "is_active": true
}
```

El cliente renderiza el QR localmente con `qr_flutter` a partir de `qr_token` (no descarga imagen del backend).

---

## 10. PDF descargable

Endpoint `GET /api/v1/qr/me/card.pdf` genera un PDF A6 horizontal (105×148mm landscape):
- Mismo layout que la app pero adaptado a horizontal
- Resolución 300 DPI
- QR a 4cm × 4cm (escaneable post-impresión)
- Marca de agua sutil "SACDIA · Credencial digital"
- Sin botones (es estático)

Nombre del archivo: `tarjeta-{name_short}-{card_id}.pdf`

---

## 11. Internacionalización

Todos los textos de UI vía `easy_localization`. Nuevas keys bajo `virtual_card.*`:

```json
{
  "virtual_card": {
    "title": "Mi Credencial",
    "label_club": "CLUB",
    "label_section": "SECCIÓN",
    "label_member_since": "MIEMBRO DESDE",
    "actions": {
      "show_qr": "Mostrar en grande",
      "share": "Compartir",
      "refresh": "Renovar QR",
      "download_pdf": "Descargar PDF",
      "share_image": "Compartir como imagen",
      "copy_link": "Copiar link"
    },
    "states": {
      "offline_banner": "Modo sin conexión — datos cacheados",
      "qr_expired": "Renová tu credencial cuando recuperes conexión",
      "retry": "Reintentar",
      "inactive_overlay": "Esta credencial no está activa. Comunicate con tu director.",
      "loading": "Cargando credencial..."
    },
    "tier": {
      "bronze": "BRONCE",
      "silver": "PLATA",
      "gold": "ORO",
      "platinum": "PLATINO",
      "diamond": "DIAMANTE"
    }
  }
}
```

4-locale parity mandatorio (es, pt-BR, en, fr).

---

## 12. Casos de uso visuales (para referencia del implementador)

### Caso 1: miembro nuevo, sin tier aún

- Foto sin borde de color (gris neutro `#E5E8EE`)
- Tier badge oculta (no se renderiza)
- Resto igual

### Caso 2: miembro con tier Gold

- Foto con borde dorado 4pt
- Badge `🏆 ORO` visible en footer
- Sutil acento dorado en la barra divisora superior (1pt línea dorada en el borde inferior del header band)

### Caso 3: miembro con tier Diamond

- Foto con borde gradiente animado (shimmer 4s)
- Badge `💎 DIAMANTE` con gradiente
- Acento sutil en header band (gradiente 1pt en el borde inferior)
- Sin sobrecarga visual: la diferencia se nota pero no es ostentosa

### Caso 4: ex-miembro (is_active=false)

- Toda la tarjeta desaturada (opacity 0.5)
- Overlay rojo translúcido sobre todo
- QR oculto
- Mensaje central

---

## 13. Performance

- Imagen de perfil cargada con `cached_network_image` + placeholder shimmer
- QR generado al vuelo (no bytecode pesado)
- Tarjeta debe renderizar en <100ms desde data lista
- Animación de entrada no bloquea: si el usuario interactúa antes de que termine, se interrumpe

---

## 14. Testing visual

El implementador debe:
1. Generar screenshots en simulador iOS (iPhone 16 Pro, iPhone SE) y emulador Android (Pixel 8, pixel sm)
2. Verificar light + dark mode
3. Verificar los 5 tiers + tier ausente
4. Verificar estados loading, offline, expired, inactive
5. Verificar text scale 1.0, 1.3, 1.5

Adjuntar screenshots al PR.

---

## 15. Recursos visuales necesarios

- Logo SACDIA (institucional) — verificar `assets/images/logo.png` o equivalente en `sacdia-app`
- Logos de clubes — vienen de `clubs.logo_url` (R2)
- Fotos de perfil — vienen de `users.profile_image_url` (R2)
- Iconos lucide — paquete `lucide_icons` o equivalente Flutter

---

## 16. Definición de "hecho"

- ✅ Pantalla `virtual_card_screen.dart` renderiza según spec
- ✅ Pantalla `qr_full_screen.dart` con brillo automático
- ✅ Estados loading / offline / expired / inactive funcionando
- ✅ 5 tiers visualmente distintos
- ✅ Light + dark mode coherentes
- ✅ Botón compartir funcional (PDF + imagen + link)
- ✅ Animaciones de entrada y transiciones suaves
- ✅ Accesibilidad VoiceOver / TalkBack
- ✅ 4-locale i18n parity
- ✅ Screenshots adjuntos al PR (light + dark, 5 tiers, estados)
- ✅ `dart analyze` clean
- ✅ Tests widget mínimos (renderizado + tap on QR opens full screen)

---

## 17. Anti-patrones a evitar

- ❌ Diseño tipo "tarjeta de crédito" con números grandes y bandas magnéticas falsas
- ❌ Animaciones excesivas tipo TikTok
- ❌ Gradientes saturados o psicodélicos
- ❌ Tipografía decorativa (script, condensed extreme)
- ❌ Stickers, emojis decorativos en la tarjeta
- ❌ Información innecesaria (email, teléfono, dirección — privacidad)
- ❌ Hardcoded strings (todo via `tr()`)
- ❌ Colores hardcoded (todo via tokens del theme)

La tarjeta debe sentirse **institucional, premium, sobria**. No casual ni infantil.

---

## 18. Referencia visual (descripción para implementación)

Imaginá un boarding pass digital de aerolínea premium (estética Apple Wallet) **adaptado al contexto institucional Adventista**:

- Header oscuro con dos logos (institución + club) en blanco
- Cuerpo blanco/limpio con jerarquía tipográfica clara
- Foto circular destacada con borde sutil que refleja status
- Datos institucionales mínimos en formato label + value
- QR central, generoso pero no abrumador
- Footer técnico discreto con ID y badge de tier
- Sombra suave que la eleva del fondo

El miembro debe sentir que **su credencial es algo bonito de mostrar**, no un documento burocrático.

---

## 19. Checklist final pre-merge

```
[ ] Layout ratio 5:8, padding 24pt, radius 24pt
[ ] Light + dark mode tokens implementados
[ ] 5 tiers + sin tier renderizados correctamente
[ ] Tipografía: nombre 24pt bold, micro-labels 10pt 1.2 letter-spacing
[ ] Foto circular 120pt con borde dinámico
[ ] QR 160pt centrado + acción "mostrar en grande"
[ ] Footer: ID monospace + tier badge
[ ] Estados: loading skeleton, offline banner, expired, inactive
[ ] Animación entrada spring
[ ] Modo presentación full-screen con brillo automático
[ ] PDF download + share sheet
[ ] Pull-to-refresh renueva / re-emite token vigente
[ ] i18n keys en 4 locales con paridad
[ ] Accesibilidad VoiceOver/TalkBack labels
[ ] Text scale soportado hasta 1.5
[ ] Screenshots light/dark + 5 tiers + estados adjuntos
[ ] dart analyze clean
[ ] Tests widget mínimos verdes
```

Cuando esto esté hecho, la línea 3 del roadmap (QR + tarjetas virtuales) cierra su Phase 2.
