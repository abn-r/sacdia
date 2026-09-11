# Propuesta de onboarding de producto (archivo)

**Fecha:** 2026-09-10  
**Estado:** ARCHIVADO / diferido  
**Foco vigente:** [carrusel pre-login (enfoque A)](2026-09-10-onboarding-carrusel-pre-login-design.md)

Este documento guarda el análisis del 2026-09-10. No se implementa ahora.
El trabajo inmediato es solo el carrusel pre-login.

---

## Diagnóstico

La app ya mete al usuario al sistema. No le enseña el sistema.

Camino actual: splash → login/registro → post-registro (foto, datos, club/sección) → dashboard. Si la membresía sigue pendiente, la superficie operativa se cierra. Tabs: Inicio, Clases, Actividades, Perfil. El resto vive en la grilla de acceso rápido, filtrada por permisos.

`SacOnboarding` (ShowcaseView) ya envuelve la app y no se usa en producción. FAQ «Inicio» responde dudas, no guía una primera tarea. Auditoría de julio 2026: captura datos, no hay tour por rol.

SACDIA no es un CRUD. Es trayectoria en una **sección**, en un **año**, con un **rol**, y **alguien valida**.

Cuatro ideas del primer día (siguen válidas para oleadas posteriores):

1. Tu sección (no el club entero).
2. Tu rol este año.
3. Qué puedes hacer ahora (una sola acción).
4. Registrar no equivale a reconocer.

---

## Tres enfoques (2026-09-10)

| | A. Carrusel pre-login | B. Solo coach marks | C. Híbrido |
|---|---|---|---|
| Qué es | 4–5 pantallas ilustradas antes de entrar | Luces sobre UI real | Micro-historia + tour en la pantalla real, por estado y rol |
| Fortaleza | Marca, emoción | Enseña dónde está cada cosa | Enseña el modelo mental y la primera acción útil |
| Riesgo | Retrasa a quien ya sabe; se olvida al llegar al home | Sin contexto, parece un tutorial de UI | Más diseño de contenido |
| Encaje | Login ya tiene constelación de logos | `SacOnboarding` ya está | Reutiliza post-registro, banners y dashboard |

**Decisión 2026-09-10:** implementar de momento **solo A**. B y C quedan diferidos.

---

## Cuatro actos (diferidos)

No construir ahora. Quedan como mapa para cuando vuelva el onboarding instructivo.

### Acto 0 — Primera impresión

Splash: fade + scale 420 ms. Login: constelación Aventureros / Conquistadores / Guías Mayores. El carrusel A cubre este hueco de marca.

### Acto 1 — Post-registro

Alta, no tour. Falta copy de propósito en los 3 pasos (foto, datos, club/sección).

### Acto 2 — Espera de aprobación / ghost

Dashboard pending y miembro inactivo este año. Una escena anclada al banner.

### Acto 3 — Primera sesión activa

3–4 focos sobre UI real (`DashboardView`): ClubInfoCard, clase, acceso rápido, tabs. Checklists por rol.

Guiones diferidos:

- **Miembro:** espera → sección y clase → evidencia la valida otra persona.
- **Director:** contexto → inscripción anual / miembros → primera actividad.
- **Secretaría:** miembros y solicitudes.
- **Tesorería:** finanzas; leer no es crear.
- **Consejero:** clase agrupada / unidades.
- **Coordinador:** hub aparte. Panel admin: otro onboarding.

Infra a reutilizar más adelante: `sacdia-app/lib/core/onboarding/sac_onboarding.dart`, `SacMotion`, `DashboardView`, banners de membresía e inscripción.

---

## Motion (canon de app, aplicable a A)

Usar `SacMotion`. Entradas fade + scale desde `0.96`. Stagger 40 ms. Reduced motion: sin scale ni drift. Nada de mascota, confetti ni video de 30 s.

---

## Fuentes de evidencia (corte 2026-09-10)

- `docs/canon/identidad-sacdia.md`
- `docs/audit/PRODUCTION-ONBOARDING-OPERATIONS-READINESS-2026-07-17.md` §7
- `sacdia-app/lib/core/config/router.dart` (splash → login / post-registro / dashboard)
- `sacdia-app/lib/core/onboarding/sac_onboarding.dart`
- `sacdia-app/lib/features/dashboard/presentation/views/dashboard_view.dart`
- `sacdia-app/lib/features/post_registration/presentation/views/post_registration_shell.dart`
