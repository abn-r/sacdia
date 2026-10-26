---
documento: Benchmark legal — T&C y Aviso de Privacidad vs apps comparables
fecha: 2026-10-26
estado: ANÁLISIS INTERNO (no publicable). Insumo para la revisión del abogado y para la 2.0.0-family.
aplica_a: docs/legal/aviso-de-privacidad.md, docs/legal/terminos-y-condiciones.md, store-submission-privacy-checklist.md
---

# Benchmark legal: SACDIA vs apps comparables

Compara la versión operativa `2.0.0-family` (borrador) contra 7 apps del nicho (gestión de clubes, equipos juveniles, iglesias, escuelas) y contra el código real de los tres repos. No es asesoría legal.

## 0. Respuesta corta a la duda de origen

**Nombrar proveedores y decir con quién se comparten datos es correcto y hay que mantenerlo.** Razones:

1. **LFPDPPP art. 16-V**: el aviso debe informar las transferencias. La reforma de 2025 movió el detalle al Reglamento, pero todos los despachos consultados recomiendan seguir listándolas.
2. **App Store 5.1.1(i) y 5.1.2(i)**: la política debe identificar a los terceros (SDK, analítica) con los que se comparten datos. Apple lo exige, no es opcional.
3. **Benchmark**: solo 2 de 7 comparables nombran proveedores (ClassDojo y Planning Center), que son justo los dos con mejor reputación en privacidad infantil. Scouting America, TroopTrack y TeamSnap solo dicen "categorías"; su política es más débil que la nuestra.
4. **Riesgo de seguridad por nombrar el stack**: bajo. El stack ya es visible desde fuera (DNS de Vercel/Render, URLs `*.r2.dev` embebidas en la app, SDKs de Sentry/PostHog en el binario). Lo que sí cuesta es **mantener la lista exacta**: una lista desactualizada es una inexactitud en el aviso.

Lo que sí falla hoy no es nombrar, sino **cómo** lo hacemos: la lista está incompleta frente al código, no dice qué datos ni en qué país por proveedor, y vive dentro del documento versionado (cada cambio de proveedor obliga a re-aceptación de TODOS los usuarios).

## 1. Hallazgos contra el código (verificados 2026-10-26)

Proveedores que están en el código y NO aparecen en Aviso §4 ni en el checklist §4:

| Proveedor | Evidencia | Qué procesa | Acción |
|---|---|---|---|
| **Upstash (Redis)** | `redis`, `@keyv/redis` en backend; `docs/steering/tech.md` §Cache: "Upstash recomendado" | Caché de respuestas y colas BullMQ (OCR). Puede contener datos personales en caché temporal | Agregar a §4 como encargado (caché e infraestructura) |
| **Google Cloud Run + Firestore** | `cloud-run-certificate-ocr.provider.ts`; tech.md §10 "proxy keyless `sacdia-ocr-proxy` (us-east4), ledger Firestore solo metadata" | Imágenes/PDF de certificados en tránsito hacia Vision; ledger de metadata | Hoy §4 solo dice "Google Cloud Vision". Ampliar a "Google Cloud (Vision, Cloud Run, Firestore)". Aún no desplegado: publicar solo cuando se active |
| **AWS S3 (legado)** | `sacdia-files.s3.us-east-1.amazonaws.com/Especialidades/` en 4 modelos de `sacdia-app/lib/features/honors` y `classes` | Imágenes del catálogo de especialidades (sin datos personales), pero la IP del dispositivo llega a AWS | Migrar esas imágenes a R2 y borrar la constante, o declarar AWS. Preferible migrar |
| **YouTube (img.youtube.com)** | `resource_preview.dart` | Miniaturas de recursos del club; IP del dispositivo a Google | Una línea en §4: "contenido externo enlazado por el club (p. ej. YouTube)" |
| **Google Fonts (fonts.gstatic.com)** | admin web | IP del navegador a Google al cargar el panel | Self-host de fuentes (Next.js `next/font` ya lo hace si se configura) o declarar |

Verificado como correcto o inocuo:

- **Nominatim** sí se usa (`nominatim_remote_data_source.dart`, búsqueda de lugares). Declaración correcta.
- **Google Maps** se usa en app (`google_maps_flutter`) y admin (`@vis.gl/react-google-maps`). Cubierto por "Google... mapas cuando aplique", pero conviene nombrarlo como "Google Maps Platform".
- **Geocoding inverso en móvil** usa geocoders nativos (CLGeocoder de Apple / Android Geocoder), no Nominatim. Cubierto por Apple/Google.
- **CARTO** (`tileUrlTemplate` en `maps_constants.dart`) es código muerto: ningún uso. No declarar; candidato a limpieza. Igual la clave de Google Static Maps.
- **Resend, Sentry, PostHog, Firebase (FCM + App Check), Better Auth, Neon, Render, Vercel, Cloudflare R2**: coinciden con el aviso.

## 2. Tabla comparativa

| Dimensión | SACDIA (2.0.0-family) | ClassDojo | Planning Center | Scouting America | TeamSnap | TroopTrack | Brightwheel |
|---|---|---|---|---|---|---|---|
| Nombra proveedores | Sí, inline, solo propósito | Sí, página aparte: propósito + datos + país | Sí, página aparte: propósito; suscripción a cambios | No | No | No | Parcial |
| Razón social + domicilio | **No** | Sí | Sí | Sí | Sí | Sí | No |
| Menores <13 vs 13-17 | Sí, muy detallado | Sí, COPPA Safe Harbor | Parcial (<16) | Parcial | Parcial | Mínimo | Excluye |
| Consentimiento parental descrito | Sí (formato firmado + verificación por director) | Sí | No | No | "Se presume" | No | No |
| Salud / sensibles | Sección sí, sin consentimiento separado | Opt-in por tipo | Solo CCPA | Menciona, sin consentimiento | No | No | No |
| Plazos de retención | Solo menores (90+90 días); resto vago | Sí (6 y 12 meses) | No | No | Parcial | No | No |
| Transferencias internacionales | "pueden procesar en MX, EE.UU. u otros" | DPF + SCCs | Vaga | N/A | SCCs | No | SCCs |
| Cookies (web) | **No** (el admin usa PostHog + cookies de sesión) | Sí, política aparte | Sí | Sí | Sí | Sí | Sí |
| Resumen "highlights" arriba | No | Sí | No | No | No | No | No |
| Historial de versiones público | No (solo en DB `legal_acceptances`) | Sí (/legal-history) | No | No | No | No | No |
| ARCO / plazos / revocación | Genérico ("puedes solicitar") | N/A (EE.UU.) | N/A | N/A | N/A | N/A | N/A |
| Ley aplicable y jurisdicción (T&C) | **No** | Sí | Sí | Sí | Sí | Sí | Sí |

Lectura: en **menores** SACDIA está por encima de todo el nicho scout. En **formalidades legales mexicanas** (entidad, domicilio, ARCO, cookies, jurisdicción) está por debajo de todos.

## 3. Qué mejorar, priorizado

### P0 — Bloquea publicación legal seria (LFPDPPP)

1. **Identidad y domicilio del responsable** (art. 16-I). Hoy §1 dice "SACDIA opera como plataforma tecnológica" sin persona física o moral ni domicilio. Es el único comparable junto con Brightwheel que falla esto. Sin entidad formal, al menos: nombre de la persona física responsable + domicilio para oír notificaciones + correo ARCO. Ya marcado CRÍTICO en `REVIEW-REPORT.md`; sigue abierto.
2. **Consentimiento expreso separado para salud y para religión** (art. 9). Hoy la UI y el aviso los agrupan. ClassDojo hace opt-in por tipo de dato sensible. Pendiente C-01 del REVIEW-REPORT.
3. **Derechos ARCO con procedimiento, plazos y revocación** (art. 16-III, IV). §7 operativo dice "puedes solicitar acceso, corrección..." sin plazos ni requisitos ni medio de revocación ni opción de limitar uso. El full draft §8-§9 ya lo tiene bien; traer una versión compacta.
4. **Completar la lista de encargados** con lo del punto 1 (Upstash, Google Cloud Run/Firestore, YouTube) y resolver AWS S3 por migración.

### P1 — Antes de enviar 2.0.0-family a tiendas

5. **Página aparte `/subprocessors`** (modelo ClassDojo + Planning Center) con columnas: proveedor, entidad legal, propósito, categorías de datos, país, ¿esencial?, fecha de última actualización. El aviso §4 remite a esa página. **Ventaja específica de SACDIA**: cambiar un proveedor deja de exigir bump de `CURRENT_LEGAL_DOCUMENTS` y re-aceptación forzada de todos los usuarios (ver `docs/legal/README.md`). El full draft §7.2 ya tiene la tabla con datos y país; está hecho el 70 %.
6. **Sección de cookies para el panel web**. El admin usa `posthog-js` (sin session recording, verificado en `instrumentation-client.ts`) y cookies de sesión/preferencias. El aviso operativo no tiene sección de cookies; el full draft §13 sí. Obligatorio por Lineamientos del Aviso.
7. **Transferencias internacionales con mecanismo**. Cambiar "pueden procesar en México, EE.UU. u otros países" por: destinos concretos por proveedor + "DPA/términos de encargado suscritos con cada uno". **Verificar antes** que realmente se aceptaron los DPA de Neon, Cloudflare, Google Cloud, Sentry, PostHog, Resend, Upstash, Render, Vercel (la mayoría son click-through en el dashboard). El full draft §7.2.1 afirma que están firmados; no asumirlo.
8. **Plazos de retención por categoría** (modelo ClassDojo). Ya tenemos cifras reales: 90+90 días menores sin tutor, 180 días sesión de dispositivo vinculado, URLs firmadas con TTL, Sentry/PostHog con retención del proveedor. Tabular lo que el runtime ya cumple; no prometer lo que no.
9. **T&C: ley aplicable y jurisdicción** (México, tribunales de la ciudad/estado del responsable), **propiedad intelectual** de SACDIA (marca, software) y **limitación de responsabilidad sin tope monetario fijo** (el tope de MXN 5,000 del full draft fue marcado como potencialmente abusivo por LFPC art. 90). Todos los comparables tienen estas tres cláusulas; el operativo no tiene ninguna.
10. **Declarar que los proveedores de IA/OCR no entrenan con nuestros datos** (modelo Planning Center). Google Cloud Vision bajo términos de Cloud no usa datos de clientes para entrenar; decirlo explícitamente da confianza a padres.

### P2 — Diferenciación (nadie en el nicho adventista lo hace)

11. **Bloque "Resumen" al inicio del aviso** (modelo ClassDojo "Highlights"): 6-8 bullets en lenguaje llano: qué recolectamos, qué nunca hacemos, quién ve datos de menores, cómo borrar, a quién escribir.
12. **Historial público de versiones** `/legal-history`: ya existe la fuente de verdad (`legal_acceptances` + `CURRENT_LEGAL_DOCUMENTS`). Publicar cada versión con fecha y diff resumido prueba qué texto aceptó cada usuario.
13. **Aclarar roles responsable/encargado respecto del club** (modelo Brightwheel/Planning Center). Hoy SACDIA se declara responsable de todo. Si el club o la asociación recaba el consentimiento del tutor en papel, hay corresponsabilidad. Decisión legal, no técnica.
14. **Posicionamiento en tiendas**: NO aplicar a categoría Kids de Apple (prohíbe analítica de terceros; usamos Sentry/PostHog). En Google Play existe la figura **"mixed audience"**: si se declara que incluye menores, exige pantalla neutral de edad y restricciones de SDK. Hoy la fecha de nacimiento se pide en post-registro, no es pantalla neutral de edad. Confirmar con abogado o soporte de Play antes de declarar. Relacionado con la pregunta abierta #8 del REVIEW-REPORT.
15. **Suscripción a cambios de proveedores** (modelo Planning Center/Vercel): un correo o RSS. Para el tamaño de SACDIA, basta un apartado "Cambios" en la página de sub-procesadores.

## 4. Ventajas actuales a conservar

- Separación <13 / 13-17 / 18+ con mecanismos reales y verificados en código (`AnalyticsPolicy`, `no_sentry_user_test`). Ningún comparable scout llega a esto.
- Posición pública "no vendemos, no anunciantes, solo encargados técnicos" (correcta; no decir "no compartimos").
- Honestidad sobre lo no implementado (sin segundo opt-in por correo, sin eliminación desde la app para 13-17). TeamSnap y ClassDojo también reconocen límites; sube credibilidad.
- Texto alineado con runtime (regla del README). Mantener el check `rg "BORRADOR — requiere revisión" docs/legal`.

## 5. Preguntas para el abogado (nuevas, no están en REVIEW-REPORT)

1. ¿Basta remitir a una página externa `/subprocessors` para cumplir art. 16-V, o la lista debe estar íntegra en el aviso al momento de la aceptación?
2. Con la reforma LFPDPPP 2025, ¿sigue vigente la distinción transferencia/remisión y los Lineamientos del Aviso de 2013? (Fuentes de despachos en conflicto; no se leyó el DOF.)
3. ¿La aceptación del aviso por un menor de 13-17 en "modo pendiente de tutor" tiene efecto jurídico? (Pregunta #10 del REVIEW-REPORT; pendiente.)

## Fuentes

- https://www.classdojo.com/privacy/ y https://www.classdojo.com/third-party-service-providers/
- https://www.planningcenter.com/privacy y https://www.planningcenter.com/subprocessors
- https://www.teamsnap.com/privacy-policy
- https://www.trooptrack.com/privacy
- https://mybrightwheel.com/privacy/
- https://scoutingmemories.org/privacy-policy/ (copia de terceros; la oficial de scouting.org devolvió 403)
- https://developer.apple.com/app-store/review/guidelines/ (5.1.1, 5.1.2, 5.1.4, 2.3.8)
- https://support.google.com/googleplay/android-developer/answer/9893335 (Families / mixed audience)
- LFPDPPP 2025: https://www.garrigues.com/es_ES/noticia/mexico-nueva-ley-federal-proteccion-datos-personales-posesion-particulares-introduce · https://basham.com.mx/en/nueva-ley-federal-de-proteccion-de-datos-personales-en-posesion-de-los-particulares-publicada-en-el-diario-oficial-de-la-federacion/ · https://www.hlc.com/es/publications/mexicos-new-federal-data-protection-law-what-it-means-for-companies
- No se pudo leer: ClassDojo Children's Policy, política oficial de Scouting America, política de Remind/ParentSquare, texto oficial del DOF.
