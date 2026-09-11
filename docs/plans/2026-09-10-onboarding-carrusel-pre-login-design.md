# Diseño: carrusel pre-login (enfoque A)

**Fecha:** 2026-09-10  
**Estado:** IMPLEMENTADO en app (2026-09-10) — escenario v4 (escena compuesta)  
**Código:** `sacdia-app/lib/features/auth/presentation/views/welcome_carousel_view.dart` + `welcome_carousel_visuals.dart`  
**Alcance:** solo app Flutter, antes de login/registro  
**Archivo del resto:** [propuesta completa diferida](2026-09-10-onboarding-producto-propuesta.md)

No tours por rol. No `SacOnboarding`/Showcase. No panel admin. No cambios de post-registro.

---

## Objetivo

En el primer arranque sin sesión, mostrar 5 láminas que expliquen **qué se puede hacer en SACDIA** antes del formulario de login. Quien ya vio el carrusel (o lo omitió) va directo a login.

Criterio de éxito: alguien del ministerio juvenil entiende, antes de crear cuenta, qué puede hacer: clase, especialidades, administración del club y trayectoria de servicio.

---

## Dónde encaja

```
splash (resuelve auth)
  → con sesión: post-registro o dashboard (igual que hoy)
  → sin sesión y carrusel no visto: /welcome
  → sin sesión y carrusel visto/omitido: /login
```

`/welcome` es ruta pública, como login y registro.

Si el usuario llega autenticado a `/welcome` (sesión restaurada a mitad), redirigir igual que splash: post-registro o dashboard. El carrusel no se muestra a quien ya tiene cuenta en este dispositivo.

OAuth `/auth/callback` no pasa por el carrusel.

No hay flag de first-run hoy. Habrá que añadir uno.

---

## Persistencia

Nivel **dispositivo**, no usuario. Todavía no hay cuenta.

| Campo | Valor |
|---|---|
| Store | `SharedPreferences` (mismo patrón que tema, locale, a11y) |
| Clave | `welcome_carousel_seen_v4` |
| Valores | `true` tras Omitir o «Continuar» en la última lámina |
| Versión | `v4` — escena Flutter (no poster JPG) |

No PII. Logout no vuelve a mostrar el carrusel. Reinstalar la app sí (prefs borradas).

Replay desde Ajustes queda fuera de esta oleada.

---

## Cinco láminas

Copy en español neutro, tono de club adventista (no slang). Claves i18n bajo `welcome_carousel.*`. El escenario ocupa ~60% de la pantalla y se mueve 1:1 con el swipe.

### 1. Intro

- **Eyebrow:** SACDIA
- **Título:** Los clubes de tu iglesia, en un sistema
- **Cuerpo:** Aventureros, Conquistadores y Guías Mayores. El registro de los clubes de la Iglesia Adventista, en un solo lugar.
- **Visual:** paisaje (cielo, cerros, iglesia) + banderas de ministerio + celular con UI viva de los tres clubes.

### 2. Clases

- **Título:** El avance de tu clase, de principio a fin
- **Cuerpo:** Desde Corderitos hasta Guía Mayor. Registra el avance de tu clase sin perder nada en el camino.
- **Visual:** corderito (AV-01), letrero de senda, celular con avance de clase (logos reales). Stagger 40 ms, `scale(0.96)`, una vez. PNG sin `FadeTransition`.

### 3. Especialidades

- **Título:** Tus especialidades, como la banda
- **Cuerpo:** Todas las especialidades que curses, en un solo lugar. Como llevar la banda en el celular.
- **Visual:** banda ilustrada (`barra_ave`) + parches de clase + grilla viva de especialidades en el celular.

### 4. Administración

- **Título:** Tú diriges. El club queda en orden
- **Cuerpo:** Lleva el control de cada registro del club. Tú diriges las actividades; nosotros nos encargamos de que todo quede ordenado.
- **Visual:** archivadores + clipboard + grilla administrativa viva.

### 5. Trayectoria

- **Título:** Tu trayectoria de servicio
- **Cuerpo:** Cada paso que das queda registrado: tu trayectoria de servicio y devoción a Dios en los clubes.
- **Visual:** sendero y cruz en el paisaje, polaroids, celular con trayectoria.
- **CTA:** Continuar → marca visto, `go(/login)`. Login ya tiene iniciar sesión y crear cuenta; no se duplican aquí.

---

## Controles (todas las láminas)

- Indicadores de página (5 puntos).
- **Omitir** arriba a la derecha: marca visto, va a login. Visible desde la lámina 1.
- Siguiente en 1–4. En 5, Continuar (mismo estilo) sustituye a Siguiente y va a login.
- Atrás: láminas 2–5. En 1, no hay atrás (no volver a splash).
- Swipe horizontal (`PageView`).
- Reduced motion: `jumpToPage`, sin scale ni stagger.

No autoplay. No bloqueo de tiempo. No pedir notificaciones ni permisos aquí.

---

## Motion

Reutilizar `SacMotion`, no un motor nuevo.

- Cambio de lámina: `PageView` con bounce (Apple rubber-band). `animateToPage` ~240 ms (`routeEnter` / `easeOut`).
- Escenario: `Transform.translate` ligado a `PageController.page` (direct manipulation 1:1). Nunca `scale(0)` — foco mínimo 0.93.
- Copy compacto bajo el escenario (viaja con el swipe). Omitir flota sobre el arte. Dots y CTA quedan fuera del `PageView`.
- Reduced motion: `jumpToPage`, parallax en 0.
- JPG de escena: no se usa. Paisaje pintado + PNG de ministerio/clase. Sin `FadeTransition` sobre bitmaps.
- Duración total si el usuario no para: ~20–30 s. No hay timer. No hay loop idle.

---

## Encaje técnico (cuando se implemente)

Archivos previstos, sin crearlos aún:

- Ruta: `RouteNames.welcome = '/welcome'` en `route_names.dart`
- Redirect en `router.dart`: incluir `/welcome` en `publicRoutes`; al salir de splash sin sesión, leer el flag
- Vista: `lib/features/auth/presentation/views/welcome_carousel_view.dart`
- Flag: constante en `app_constants.dart` + provider síncrono (el redirect del router no puede esperar un Future)
- Tests: first-run → welcome; seen → login; logged-in salta welcome; omitir persiste; callback OAuth intacto

El redirect de splash es el único disparo. Deep link a `/login` o `/register` no obliga el carrusel (el usuario ya eligió entrar).

---

## Fuera de alcance

- Coach marks, checklists por rol, post-registro, dashboard pending/ghost
- Panel Next.js
- Pedir permisos de notificaciones / biométricos
- Video, Lottie a pantalla completa, mascota
- Re-mostrar el carrusel tras logout o cambio de cuenta

---

## Riesgos

- Retrasa a quien ya conoce el ministerio y solo quiere entrar. Mitigación: Omitir desde la lámina 1.
- Quien omite no ve las 5 ideas. Aceptable: el carrusel es marca, no capacitación operativa.
