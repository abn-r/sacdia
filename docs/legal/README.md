# docs/legal/ — Documentos legales operativos de SACDIA

Esta carpeta concentra los textos legales y de privacidad usados para la publicación inicial de SACDIA en App Store y Google Play.

## Documentos vigentes para tiendas

| Archivo | Uso |
|---|---|
| [`aviso-de-privacidad.md`](./aviso-de-privacidad.md) | Aviso de privacidad operativo para publicar en `https://sacdia.com/privacy`. Explica datos recolectados, finalidades, proveedores, seguridad, menores, ubicación, eliminación y contacto. |
| [`terminos-y-condiciones.md`](./terminos-y-condiciones.md) | Términos de uso operativos para publicar en `https://sacdia.com/terms`. Regula uso de cuenta, conducta, menores, contenido, notificaciones, pagos no habilitados, eliminación y soporte. |
| [`store-submission-privacy-checklist.md`](./store-submission-privacy-checklist.md) | Checklist para alinear App Store Connect y Google Play Console con el runtime real de SACDIA. |

## Versiones vigentes y aceptación en la app

La versión vigente de cada documento vive en el código, no en esta carpeta: `sacdia-backend/src/legal/legal-documents.constants.ts` (`CURRENT_LEGAL_DOCUMENTS`, con la versión y la URL pública de `terms` y `privacy`). Ese archivo es la fuente de verdad para el registro y para la pantalla de aceptación de la app.

- La versión del código debe coincidir con el `version` del frontmatter de cada documento (hoy `1.0.0-store` en ambos).
- Subir una versión obliga a TODOS los usuarios a volver a aceptar: quien no tenga una aceptación registrada para la versión vigente queda bloqueado en la pantalla de aceptación hasta aceptar (ver `legal_acceptances` en `docs/database/SCHEMA-REFERENCE.md` y la sección `legal` en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`).
- Publica primero el texto nuevo en el sitio web (`https://sacdia.com/terms` y `https://sacdia.com/privacy`) y solo después despliega el cambio de versión. Nunca al revés: los usuarios tendrían que aceptar un texto que todavía no pueden leer.

## Posición pública de privacidad

SACDIA debe comunicar esta idea de forma consistente:

> No vendemos datos personales, no compartimos datos con anunciantes y no usamos información para publicidad comportamental. Solo procesamos datos con proveedores técnicos necesarios para operar, proteger y dar soporte a la plataforma.

## Archivos preservados para revisión legal futura

Los documentos legales extensos previos se preservaron como referencia para una futura revisión jurídica formal:

| Archivo | Uso |
|---|---|
| [`aviso-de-privacidad.full-draft-2026-04-17.md`](./aviso-de-privacidad.full-draft-2026-04-17.md) | Draft legal amplio con placeholders de entidad/RFC/domicilio y controles futuros. No usar directamente para tiendas. |
| [`terminos-y-condiciones.full-draft-2026-04-17.md`](./terminos-y-condiciones.full-draft-2026-04-17.md) | Draft legal amplio con placeholders de entidad/RFC/domicilio y controles futuros. No usar directamente para tiendas. |
| [`REVIEW-REPORT.md`](./REVIEW-REPORT.md) | Reporte de revisión del draft legal anterior. |

## Reglas antes de publicar

- No publicar documentos con placeholders.
- No prometer pagos, patrocinios, RFC, domicilio fiscal o entidad legal si todavía no existen.
- No prometer controles que el sistema no implementa aún.
- Mantener las declaraciones de App Store / Google Play alineadas con `store-submission-privacy-checklist.md`.
- Rotar y remover secretos antes del envío a tiendas.

## Nota

Estos documentos están redactados para publicación operativa inicial y revisión de tiendas. No sustituyen asesoría legal personalizada. Cuando SACDIA tenga entidad formal, pagos, patrocinio o alcance comercial, deben revisarse con abogado y actualizarse.
