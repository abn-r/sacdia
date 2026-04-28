# docs/legal/ — Documentos Legales de SACDIA

Esta carpeta concentra los documentos legales que rigen el uso de la plataforma SACDIA (aplicación móvil iOS/Android y panel administrativo web). Todos los documentos son **borradores en español formal mexicano**, redactados con base en la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP) vigente desde el 21 de marzo de 2025 y en mejores prácticas internacionales (COPPA, RGPD-K, patrones de Apple Health, Strava, Scoutbook y Khan Academy Kids).

> **Versión vigente (borrador):** `v1.1.0-draft` — **2026-04-17**. Incorpora los fixes de la auditoría legal independiente documentada en [`REVIEW-REPORT.md`](./REVIEW-REPORT.md) (5 críticos, 8 altos, 6 medios, 7 bajos). Decisión estratégica aplicada: **exclusión territorial a México**. Pendientes antes de publicación: **resolver los 9 placeholders `[PENDIENTE: ...]` + revisión por abogado**.

---

## Documentos

| Archivo | Cubre |
|---|---|
| [`terminos-y-condiciones.md`](./terminos-y-condiciones.md) | Términos y Condiciones de Uso. Regula aceptación, edad mínima, **alcance territorial limitado a México**, registro de adultos y menores (vía Representante Legal o Director de Club), conducta aceptable, normas de protección a menores (two-deep communication, ausencia de mensajería privada adulto-menor), licencia sobre contenido subido (con restricción reforzada sobre imágenes de Menores y mención explícita a Cloudflare R2), propiedad intelectual, suscripciones con cancelación LFPC-compliant, terminación, limitación de responsabilidad a daño directo acreditado, indemnización, ley aplicable (México) y jurisdicción, con coordinación a vía administrativa ARCO. |
| [`aviso-de-privacidad.md`](./aviso-de-privacidad.md) | Aviso de Privacidad Integral. Incluye identidad del Responsable, inventario completo de datos tratados (identificación, contacto, sensibles de salud y religiosos, académicos, ubicación, autenticación), finalidades primarias vs secundarias, consentimiento expreso para datos sensibles, cláusula especial de menores, transferencias a encargados (Neon, Cloudflare R2, Google, Apple, Sentry, Maps), procedimiento ARCO con plantilla, revocación del consentimiento, medidas de seguridad, retención, cookies y contacto del responsable de datos. |

---

## Placeholders pendientes de resolver antes de publicación

Ambos documentos utilizan el formato `[PENDIENTE: descripción]`. Todos deben quedar resueltos antes de publicar los documentos en producción.

| Placeholder | Presente en | Acción requerida |
|---|---|---|
| `[PENDIENTE: Razón social de la entidad responsable]` | T&C + Aviso | Definir persona moral que operará SACDIA (A.C., S.C., S.A.P.I. de C.V., etc.). |
| `[PENDIENTE: RFC]` | T&C + Aviso | RFC de la entidad ante el SAT. |
| `[PENDIENTE: Domicilio fiscal completo]` | T&C + Aviso | Domicilio para notificaciones legales y ARCO. |
| `[PENDIENTE: Correo ARCO — ej. arco@sacdia.app]` | T&C + Aviso | Crear buzón dedicado para solicitudes ARCO (Art. 29 LFPDPPP). |
| `[PENDIENTE: Correo de contacto del responsable]` | T&C + Aviso | Correo legal general. |
| `[PENDIENTE: Nombre y cargo del responsable de datos personales]` | Aviso | Designar persona/departamento conforme al Art. 29 LFPDPPP. |
| `[PENDIENTE: Ciudad y entidad federativa para jurisdicción — ej. CDMX]` | T&C | Elegir sede judicial. |
| `[PENDIENTE: URL pública del sitio web]` | T&C + Aviso | URL canónica donde se publicarán los documentos. |
| `[PENDIENTE: Versión y fecha de última actualización]` | T&C + Aviso | Actualizar en cada bump de versión. |

---

## Proceso de actualización

Cualquier cambio a estos documentos requiere:

1. **Bump de versión** en el frontmatter (`version: X.Y.Z-draft` o `version: X.Y.Z`) siguiendo Semantic Versioning:
   - **MAJOR** para cambios sustanciales (nuevas finalidades, nuevas transferencias, cambios en derechos del Titular).
   - **MINOR** para secciones nuevas no sustanciales.
   - **PATCH** para correcciones de redacción, typos o ajustes menores.
2. **Actualización de fecha** en el frontmatter y en el encabezado del documento.
3. **Cambio de estado** de `BORRADOR - pendiente revisión legal` a `VIGENTE` únicamente tras revisión por abogado.
4. **Notificación al Titular** cuando el cambio sea sustancial, conforme a la sección 13 del Aviso de Privacidad y a la sección 12 de los Términos.
5. **Commit** con `docs(legal): <descripción>` siguiendo Conventional Commits.

---

## Advertencia

> Estos documentos son **borradores redactados por IA** con base en mejores prácticas legales y en la normativa mexicana vigente al 2026-04-17. **REQUIEREN revisión por abogado** antes de su publicación definitiva en la aplicación, el sitio web o cualquier canal público.

El Responsable, al publicar estos documentos, asume responsabilidad legal sobre su contenido. Una revisión legal externa es indispensable para validar el cumplimiento con la LFPDPPP, la Ley Federal de Protección al Consumidor, la Ley Federal del Derecho de Autor y cualquier norma aplicable en función de la jurisdicción final del Responsable.
