# i18n multilenguaje — roadmap

**Estado**: PLANIFICADO (aspiracional)

> La capacidad actual es monolenguaje operativo (Español), con dos locales en admin (`es-MX`, `es-ES`) y base `intl` en Flutter. No debe comunicarse como trilingüe.

---

## 1. Motivación

SACDIA tiene presencia regional potencial en países de habla española y portuguesa dentro del ecosistema DIA. Habilitar multilenguaje abre mercado y mejora la experiencia institucional.

## 2. Estado actual

- **Admin (Next.js)**: 2 locales configurados (`es-MX`, `es-ES`) en `sacdia-admin/src/lib/i18n/messages.ts`. Cobertura limitada (mensajes de login principalmente).
- **App móvil (Flutter)**: `flutter_localizations` + `intl` en `pubspec.yaml`, pero sin catálogo de traducciones (`/l10n`, `/translations`) ni locales activos más allá del default.
- **Backend**: textos hardcoded en Español (logs, validaciones, respuestas de error).

## 3. Alcance candidato

Idiomas objetivo:

- `es` (base — ya parcial);
- `pt-BR` (Brasil — mercado regional grande);
- `en` (opcional, alcance global).

Superficies a cubrir:

- textos de UI en admin y app;
- mensajes de error del backend (¿traducción por `Accept-Language`?);
- templates de notificaciones push y bandeja;
- PDFs generados (monthly reports, certificados).

## 4. Arquitectura tentativa

- **Admin**: adoptar `next-intl` con archivos JSON por locale, rutas con prefijo `/:locale/...` o header-based.
- **App móvil**: adoptar `easy_localization` o `flutter_gen_l10n` con archivos ARB o JSON por locale.
- **Backend**: capa de i18n por `Accept-Language` header, fallback a Español. Catálogo compartido con clientes vía build-time sync o endpoint `GET /api/v1/i18n/:locale/:namespace`.
- **Base de datos**: considerar si catálogos institucionales (club_types, category names) requieren versiones por locale.

## 5. Hitos tentativos

1. **Fase 0** — relevamiento exhaustivo de textos hardcoded por cliente y backend. Inventario de strings.
2. **Fase 1** — adopción de librería en admin, migración de strings, escritura de `pt-BR`.
3. **Fase 2** — adopción en app móvil con catálogo ARB, traducción de strings.
4. **Fase 3** — i18n de backend (errores + notificaciones).
5. **Fase 4** — i18n de PDFs y artefactos generados.
6. **Fase 5** — canonización en `docs/canon/runtime-i18n.md` (promoción a canon).

## 6. Decisiones pendientes

- locales prioritarios (`pt-BR` primero, o directamente `en`);
- estrategia de traducción (manual vs traductor automático + revisión humana);
- si los catálogos institucionales deben traducirse o permanecer en Español;
- si las notificaciones push deben respetar el locale del usuario.

## 7. Criterio de éxito

- el usuario puede cambiar su locale en la app y la UI respeta la selección;
- los mensajes de error del backend llegan traducidos cuando se envía `Accept-Language`;
- los PDFs se generan en el locale del usuario solicitante;
- ningún texto hardcoded en Español en código de producción.

## 8. Riesgos

- duplicación de strings si el catálogo no está compartido entre admin y app;
- drift entre versiones traducidas cuando la fuente cambia;
- costo recurrente de mantener traducciones al agregar features.

## 9. Estado actual

- **Prioridad**: baja hasta tener demanda concreta de un mercado no hispano.
- **Decisión inmediata**: mantener default Español. Canonizar la infraestructura mínima vigente (`es-MX`, `es-ES`) como "2 locales parciales, cobertura limitada".
