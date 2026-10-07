# i18n multilenguaje — roadmap

**Estado**: PARCIALMENTE IMPLEMENTADO (actualizado 2026-10-04, verificado contra `development`)

> **Hecho**: infraestructura i18n con cuatro locales (`es` base, `en`, `fr`, `pt-BR`) en backend, admin y app, y 27 tablas `*_translations` para catálogos.
> **Falta**: que los clientes propaguen el idioma elegido al backend, traducir los catálogos en lecturas públicas, revisar cobertura y calidad de traducciones, y canonizar el runtime i18n.
> **Rama**: todo lo hecho está en `development` de los tres repos.

---

## 1. Motivación

SACDIA tiene presencia regional potencial en países de habla española, portuguesa, inglesa y francesa dentro del ecosistema DIA. Habilitar multilenguaje abre mercado y mejora la experiencia institucional.

## 2. Estado actual

- **Backend**: `nestjs-i18n` con `src/i18n/{es,en,fr,pt-BR}/` (namespaces `errors`, `emails`, `notifications`, `monthly_reports`, `quarterly_reports`, `annual_reports`). Resuelve el idioma por query `?lang=` y luego por `Accept-Language`; fallback `es`. Los errores de dominio (`AppException` + `ErrorCode`) y los mensajes de validación se traducen; el PDF del informe mensual usa el locale de la petición.
- **Catálogos**: 27 tablas `*_translations` (fila base en español; `CHECK (locale <> 'es')`). Hoy la traducción se edita y se lee en endpoints admin; las lecturas públicas de `catalogs.service.ts` siguen sin depender del locale.
- **Admin (Next.js)**: `next-intl` con `messages/{es,en,fr,pt-BR}.json` usado en todo el panel. El locale se toma de la cookie `sacdia_admin_locale` (`src/i18n/request.ts`). Los formularios de catálogos tienen pestañas de traducción.
- **App móvil (Flutter)**: `easy_localization` con `assets/translations/{es,en,fr,pt-BR}.json` y selector de idioma en Ajustes (`language_picker_tile.dart`).
- **Brecha**: ni la app ni el cliente HTTP del admin envían de forma explícita el idioma elegido (`Accept-Language` o `?lang=`) al backend, así que los textos generados por el backend no siguen necesariamente la selección del usuario.

## 3. Alcance candidato

Idiomas objetivo:

- `es` (base) — hecho;
- `pt-BR`, `en`, `fr` — archivos de traducción presentes en los tres repos; pendiente revisión de calidad y cobertura.

Superficies a cubrir:

- textos de UI en admin y app;
- mensajes de error del backend (¿traducción por `Accept-Language`?);
- templates de notificaciones push y bandeja;
- PDFs generados (monthly reports, certificados).

## 4. Arquitectura adoptada

- **Admin**: `next-intl` con un JSON por locale; locale por cookie, sin prefijo en la ruta.
- **App móvil**: `easy_localization` con un JSON por locale.
- **Backend**: `nestjs-i18n` con resolvers `?lang=` y `Accept-Language`, fallback `es`. No hay endpoint para compartir catálogos de mensajes con los clientes: cada cliente mantiene los suyos.
- **Base de datos**: tablas `<catálogo>_translations` por locale distinto de `es`.

## 5. Hitos

1. **Fase 0** — inventario de textos. Hecho (inventario archivado en `docs/history/audit/i18n-strings-inventory.md`).
2. **Fase 1** — librería y catálogos de mensajes en admin (`next-intl`). Hecho.
3. **Fase 2** — librería y catálogos en la app (`easy_localization`) con selector de idioma. Hecho.
4. **Fase 3** — i18n de backend (errores, validación, correos, notificaciones). Infraestructura hecha; pendiente que los clientes envíen el idioma.
5. **Fase 4** — PDFs y artefactos generados. Parcial: el informe mensual usa el locale de la petición; falta revisar trimestral, anual y certificados.
6. **Fase 5** — catálogos traducidos en lecturas públicas y canonización en `docs/canon/runtime-i18n.md`. Pendiente.

## 6. Decisiones pendientes

- estrategia de traducción (manual vs traductor automático + revisión humana);
- si las lecturas públicas de catálogos deben devolver la traducción del locale;
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

## 9. Siguiente paso

- Enviar `Accept-Language` (o `?lang=`) desde el interceptor de Dio y desde `src/lib/api/client.ts` con el locale activo.
- Decidir si las lecturas públicas de catálogos deben devolver la traducción del locale.
- Revisar con hablantes nativos las traducciones `en`, `fr` y `pt-BR` antes de anunciar soporte multilenguaje.
