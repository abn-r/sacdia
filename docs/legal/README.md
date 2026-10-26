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

- La versión del código debe coincidir con el `version` del frontmatter de cada documento. **En la rama `feat/family-profiles-phase3` la constante del backend ya es `2.0.0-family`** (`CURRENT_LEGAL_DOCUMENTS`, `src/legal/legal-documents.constants.ts`, commit propio `86d3717a`, marcada como BORRADOR en el comentario del archivo) y coincide con el frontmatter de los documentos operativos, que es un **borrador pendiente de revisión** (ver «Versión 2.0.0-family» abajo). La versión publicada hoy sigue siendo `1.0.0-store`: **no promover esa rama a `main` hasta que el texto se apruebe y se publique** en `https://sacdia.com/terms` y `https://sacdia.com/privacy`. Si el texto no se aprueba, se revierte solo `86d3717a`.
- Subir una versión obliga a TODOS los usuarios a volver a aceptar: quien no tenga una aceptación registrada para la versión vigente queda bloqueado en la pantalla de aceptación hasta aceptar (ver `legal_acceptances` en `docs/database/SCHEMA-REFERENCE.md` y la sección `legal` en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`).
- Publica primero el texto nuevo en el sitio web (`https://sacdia.com/terms` y `https://sacdia.com/privacy`) y solo después despliega el cambio de versión. Nunca al revés: los usuarios tendrían que aceptar un texto que todavía no pueden leer.

## Versión 2.0.0-family (BORRADOR, perfiles familiares Fase 3)

> **BORRADOR — requiere revisión del usuario o de un abogado.** Pendiente de merge (PR #531 de sacdia-backend).

Cambia el texto de menores: cuentas supervisadas de 13 a 17 años, modo pendiente de tutor con plazo de 90 días, facultades del tutor verificado, analítica anónima para menores y, como funciones que **aún no están activas** (Fases 3b y 3c), el dispositivo vinculado de menores de 13 años (3b: implementado en el servidor y en la app, en la rama `feat/family-profiles-phase3`, y desactivado tras `FAMILY_LINKED_DEVICE_ENABLED` hasta su despliegue) y el registro de menores por un director (3c: implementado en servidor, app y panel, en la misma rama, tras `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED`). También corrige la promesa de un segundo opt-in por correo (privacidad §6.2.c.1) que el producto no hace.

| Archivo | Versión | Qué cambió |
|---|---|---|
| `terminos-y-condiciones.md` | `2.0.0-family` | §2, §3 (reescrita) y el párrafo de menores de §10 |
| `aviso-de-privacidad.md` | `2.0.0-family` | §2.1, §2.4 (reescrita: 2.4.1 a 2.4.3), §2.8, §4 (PostHog), §6 y §7 |
| `store-submission-privacy-checklist.md` | `2.0.0-family` | Datos de menores, analítica anónima, modo dispositivo, minimización a 90 días |
| `terminos-y-condiciones.full-draft-2026-04-17.md` | `2.0.0-family-draft` | §0, §1.2, §1.4, §3.2, §8.1 |
| `aviso-de-privacidad.full-draft-2026-04-17.md` | `2.0.0-family-draft` | §0, §6.1, §6.2 (con la corrección de 6.2.c.1), §6.3, §6.6, §11, §13 |

Los borradores completos (`*.full-draft-*`) llevan el sufijo `-draft` porque no se publican en las tiendas; la constante del backend solo se compara con los documentos operativos.

**Puerta de publicación (lista de verificación de release):**

1. El usuario o un abogado aprueba el texto y se quita el aviso «BORRADOR» de cada sección.
2. Se decide si las funciones aún inactivas (dispositivo vinculado y registro por director, ya implementadas pero apagadas por bandera) se publican ya o se retiran del texto hasta su activación. Las frases que el código desmentía (la app del dispositivo «todavía no existe», el coordinador como verificador, que el seguimiento `coordinator-consent-verify` volvió cierto para las secciones que cubren sus asignaciones, y los avisos de desvinculación sin excepciones) se corrigieron el 2026-10-20 en `terminos-y-condiciones.md` y en `terminos-y-condiciones.full-draft-2026-04-17.md`; siguen como BORRADOR pendiente de revisión.
3. Se publica el texto en `https://sacdia.com/terms` y `https://sacdia.com/privacy`.
4. Solo entonces se despliega el commit de versión del backend (`2.0.0-family`; es el último commit de la sub-fase 3a y se puede revertir solo).
5. **No promover a `main` mientras exista el aviso «BORRADOR» en estos archivos.**

Verificación manual: la versión del frontmatter de `terminos-y-condiciones.md` y de `aviso-de-privacidad.md` es igual a `CURRENT_LEGAL_DOCUMENTS` el día de la publicación, y ni `rg "BORRADOR — requiere revisión" docs/legal` ni `rg "\[PENDIENTE:" docs/legal/aviso-de-privacidad.md docs/legal/terminos-y-condiciones.md` devuelven nada.

### Mejoras P0 del benchmark legal (2026-10-26)

[`BENCHMARK-2026-10-26.md`](./BENCHMARK-2026-10-26.md) comparó los documentos operativos con 7 apps del nicho y con el código real. Las mejoras P0 ya están aplicadas al borrador 2.0.0-family:

| Mejora | Dónde | Pendiente para publicar |
|---|---|---|
| Identidad y domicilio del responsable (LFPDPPP art. 16-I) | Aviso §1; Términos intro y §12 | Resolver los marcadores `[PENDIENTE: ...]` |
| Consentimiento expreso separado para salud y religión (art. 9) | Aviso §2.3.1 | La app hoy tiene un solo checkbox (`sac_legal_consent.dart`); implementar dos controles o retirar §2.3.1 |
| Lista de encargados completa, con datos y país | Aviso §4.1 a §4.3; checklist §4 | Confirmar razones sociales y DPA; migrar imágenes de AWS S3 a R2; publicar Cloud Run/Firestore solo al desplegar el proxy OCR |
| Derechos ARCO con procedimiento, plazos y revocación | Aviso §7; Términos §3.5 | Abogado confirma plazos y autoridad con la LFPDPPP 2025 |

Las mejoras P1 y P2 del benchmark (página `/subprocessors` aparte, cookies del panel web, retención por categoría, ley aplicable y jurisdicción en términos, resumen inicial, historial de versiones) **no** están aplicadas.

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
| [`BENCHMARK-2026-10-26.md`](./BENCHMARK-2026-10-26.md) | Benchmark contra 7 apps comparables y contra el código real; 15 mejoras priorizadas (P0 aplicadas al borrador 2.0.0-family). |

## Reglas antes de publicar

- No publicar documentos con placeholders.
- No prometer pagos, patrocinios, RFC, domicilio fiscal o entidad legal si todavía no existen.
- No prometer controles que el sistema no implementa aún.
- Mantener las declaraciones de App Store / Google Play alineadas con `store-submission-privacy-checklist.md`.
- Rotar y remover secretos antes del envío a tiendas.

## Nota

Estos documentos están redactados para publicación operativa inicial y revisión de tiendas. No sustituyen asesoría legal personalizada. Cuando SACDIA tenga entidad formal, pagos, patrocinio o alcance comercial, deben revisarse con abogado y actualizarse.
