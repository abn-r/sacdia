# Auditoría Legal — SACDIA T&C y Aviso de Privacidad
**Fecha revisión:** 2026-04-17
**Revisor:** Agente independiente (sin contexto previo)
**Documentos auditados:**
- `terminos-y-condiciones.md` v1.0.0-draft
- `aviso-de-privacidad.md` v1.0.0-draft
- `README.md` (índice legal)

**Marcos normativos de referencia:** LFPDPPP 2025 (MX), COPPA (US), GDPR-K (EU), LFPC (MX), Código Civil Federal, Convención sobre los Derechos del Niño.

---

## Resumen ejecutivo

**Veredicto global: APROBADO CON OBSERVACIONES — REQUIERE CAMBIOS MAYORES antes de publicación.**

Los documentos tienen una base técnica sólida y cubren la mayoría de los requisitos formales de LFPDPPP 2025. La estructura es correcta, la cláusula de menores es razonablemente completa, y se declaran correctamente encargados y transferencias. **Sin embargo**, existen cuatro bloques de hallazgos críticos que impiden publicación tal cual:

1. Consentimiento separado para datos sensibles no está granularmente implementado (se agrupa salud + religión en una sola casilla, incompatible con Art. 9 LFPDPPP).
2. Inconsistencias entre T&C y Aviso (definición de "Menor", jurisdicción ARCO, alcance del consentimiento parental).
3. Mecanismo de verificación de consentimiento parental (COPPA §312.5 / GDPR-K Art. 8) no descrito de forma verificable — solo se declara "bajo protesta de decir verdad".
4. Riesgos PROFECO: cláusula de renovación automática sin derecho de cancelación explícito y limitación de responsabilidad potencialmente abusiva para consumidor final.

Además, 9 placeholders sin resolver, incluidos datos imprescindibles (razón social, RFC, domicilio, jurisdicción, responsable de datos personales).

---

## Hallazgos por severidad

### CRÍTICO (bloquea publicación)

#### C-01 — Consentimiento de datos sensibles no granular
**Ubicación:** `aviso-de-privacidad.md § 5` y `§ Consentimiento del Titular`
**Riesgo:** LFPDPPP Art. 9 exige consentimiento **expreso y por escrito** para datos sensibles, y la doctrina INAI (aún aplicable hasta sustitución por Secretaría Anticorrupción) exige que el consentimiento para **cada categoría sensible** sea identificable y separable. El documento agrupa salud y afiliación religiosa bajo una sola casilla ("el Titular... otorga su consentimiento EXPRESO y POR ESCRITO... para a) Datos de salud... b) Afiliación religiosa"). Esto impide al Titular revocar uno sin el otro y puede invalidar el consentimiento.
**Fix:** Dividir el consentimiento en dos casillas independientes en la UI y dos cláusulas separables en el documento:
- Casilla 1: Consentimiento para tratamiento de datos de salud (ficha médica).
- Casilla 2: Consentimiento para tratamiento de dato sensible de afiliación religiosa (pertenencia a club adventista).
Documentar en § 5 que cada consentimiento es independiente y revocable por separado, y que la revocación del dato religioso implica baja del club (no del Servicio completo).

#### C-02 — Mecanismo de verificación de consentimiento parental insuficiente (COPPA / GDPR-K)
**Ubicación:** `T&C § 3.2(b)` y `Aviso § 6.2(b)`
**Riesgo:** COPPA §312.5(b) y GDPR-K Art. 8(2) exigen **esfuerzos razonables verificables** para obtener y validar el consentimiento parental (mail + confirmación, verificación por ID, doble opt-in, tarjeta de crédito simbólica, firma digital, etc.). El documento se limita a que el Director de Club "declare bajo protesta de decir verdad" — esto no es un método verificable y expone al Responsable a sanciones FTC (USD 51,744 por infracción, CFR 16 §312) y multas GDPR (hasta €20M).
**Fix:** En `Aviso § 6.2` agregar subsección 6.2.c "Método de verificación":
- Describir formato físico/digital del consentimiento parental (quién lo archiva, cómo, retención mínima).
- Requerir que el Responsable exija al club auspiciador evidencia auditable (formato firmado escaneado + ID del tutor) conservada por al menos el plazo de retención ARCO (mínimo 2 años post-baja).
- Agregar mecanismo de segunda verificación: correo al Representante Legal con link de confirmación antes de activar la ficha del Menor.

#### C-03 — Inconsistencia: definición de "Menor" vs aplicabilidad del Servicio
**Ubicación:** `T&C § 0` define Menor como <18 años, pero `§ 2.1(1)` describe Aventureros como 6-9 años y Conquistadores 10-15. Los Guías Mayores son "adultos".
**Riesgo:** El texto no aclara si los Aventureros (6-9) están sujetos a consideraciones adicionales (COPPA aplica a <13, que cubre TODOS los Aventureros y parte de Conquistadores). Si el Responsable tiene un solo Titular estadounidense <13, COPPA aplica integralmente. El Aviso § 6.7 delega a "estándares más protectores" sin operacionalizarlo.
**Fix:** Agregar en `Aviso § 6.1` matriz de edades con tratamiento diferenciado:

| Edad | Régimen aplicable | Requisitos adicionales |
|------|-------------------|------------------------|
| <13 | COPPA + LFPDPPP + GDPR-K | Consentimiento parental verificable obligatorio, prohibición absoluta de tracking/analytics personalizados, sin collección de datos no esenciales |
| 13-15 | GDPR-K + LFPDPPP | Consentimiento parental obligatorio por LFPDPPP (<18) |
| 16-17 | LFPDPPP (GDPR permite consentimiento del menor) | Consentimiento parental obligatorio en MX |
| ≥18 | LFPDPPP estándar | Consentimiento propio |

#### C-04 — Cláusula de autorización de atención médica de urgencia: alcance legal inadecuado
**Ubicación:** `Aviso § 2` (tabla, fila "Sensibles de salud") y `§ 5.1`
**Riesgo:** Se incluye "autorización de atención médica de urgencia" como dato personal sensible, pero en México la autorización para **aplicar tratamiento médico** a un menor requiere consentimiento específico del titular de la patria potestad conforme al Art. 51 de la Ley General de Salud y es un acto jurídico **separado** del tratamiento de datos personales. Una casilla en una app no suple este consentimiento médico.
**Fix:** Agregar en `§ 5.1` un disclaimer explícito: "La autorización de atención médica de urgencia capturada en la Plataforma tiene carácter **informativo y facilitador** para el personal del club. No sustituye el consentimiento informado requerido por la Ley General de Salud para procedimientos médicos, el cual debe obtenerse del Representante Legal al momento de la emergencia cuando sea practicable."

#### C-05 — Placeholders críticos sin resolver bloquean obligaciones legales
**Ubicación:** Ambos documentos + `README.md`
**Riesgo:** Sin `Razón social`, `RFC`, `Domicilio`, `Correo ARCO`, `Nombre del responsable de datos` y `Jurisdicción`, el documento no puede cumplir con:
- Art. 16 LFPDPPP (identificación del Responsable).
- Art. 29 LFPDPPP (designación de responsable de datos personales).
- Art. 22 CPEUM (domicilio para notificaciones procesales).
- Art. 1803 CCF (capacidad plena identificable de las partes).
Un Titular que reciba el documento tal cual no puede presentar una solicitud ARCO válida — lo que automáticamente activa la presunción de incumplimiento.
**Fix:** Resolver los 9 placeholders antes de cualquier publicación. Bloquear estado `VIGENTE` hasta que los 9 estén resueltos.

---

### ALTO (debe resolverse antes de publicación)

#### H-01 — Transferencias internacionales: falta cláusula específica de consentimiento
**Ubicación:** `Aviso § 7.2` y `§ 7.3`
**Riesgo:** Todos los encargados listados operan en **EE.UU.** — jurisdicción sin decisión de adecuación LFPDPPP. La transferencia internacional a Neon, Cloudflare, Google, Apple y Sentry requiere (a) cláusulas contractuales con obligaciones equivalentes (Art. 36 LFPDPPP) y (b) **informar al Titular** que sus datos cruzan fronteras. La mención actual en la tabla es insuficiente; no se menciona la transferencia transfronteriza como concepto diferenciado.
**Fix:** Agregar `§ 7.2.1 Transferencias internacionales`:
- Declarar expresamente que los datos viajarán a EE.UU. y UE.
- Enunciar que el Responsable ha suscrito contratos de encargo con cláusulas equivalentes a LFPDPPP con cada proveedor.
- Aclarar si existe Data Processing Agreement (DPA) con cada uno (Neon DPA, Google Cloud DPA, Cloudflare DPA, Apple DPA, Sentry DPA — todos públicos).
- Agregar en la casilla de consentimiento inicial referencia explícita a esta transferencia.

#### H-02 — Retención: 2 años es insuficientemente justificado y puede ser abusivo para menores
**Ubicación:** `Aviso § 11`
**Riesgo:** Para datos sensibles de salud de menores, 2 años post-baja puede considerarse excesivo si no está motivado por obligación legal específica. El principio de minimización (Art. 6 y 11 LFPDPPP) exige que la retención sea la mínima necesaria.
**Fix:** Diferenciar retención por categoría:
- Datos de identificación y del club: 2 años (obligación fiscal/contable razonable).
- Datos sensibles de salud: **máximo 6 meses** post-baja o 2 años si hubo siniestro/evento médico reportado.
- Logs técnicos y tokens: 90 días.
- Evidencia de consentimiento parental: mínimo 5 años para cubrir plazo de prescripción civil (Art. 1159 CCF).
Documentar la tabla en § 11.

#### H-03 — T&C § 9.2 Limitación a MXN $5,000: potencialmente abusiva ante PROFECO
**Ubicación:** `T&C § 9.2`
**Riesgo:** La Ley Federal de Protección al Consumidor (LFPC) Art. 90 prohíbe cláusulas que **limiten desproporcionadamente** la responsabilidad del proveedor. MXN $5,000 como tope para una plataforma que maneja datos sensibles de menores puede ser declarado abusivo por PROFECO, especialmente si hay daño moral derivado de una brecha de datos de un menor. El texto ya excluye dolo/negligencia grave/incumplimiento de protección de datos — **bien**, pero el tope monetario como numerario fijo es el problema.
**Fix:** Reformular § 9.2 eliminando el piso de MXN $5,000 y dejando solo:
- "Lo pagado por el Usuario en los 12 meses previos" (como el Servicio es gratuito hoy, sería $0 + daño directo demostrable).
- O alternativamente: "responsabilidad limitada a daño directo efectivamente acreditado, excluyendo daños indirectos", sin tope numérico, consistente con Art. 79 LFPC.
- Mantener las exclusiones actuales (dolo, negligencia grave, datos personales).

#### H-04 — Renovación automática de suscripciones sin derecho de cancelación expreso
**Ubicación:** `T&C § 7.2(3)`
**Riesgo:** LFPC Art. 10 Bis exige que la renovación automática sea **expresamente aceptada** y que el consumidor pueda cancelar en cualquier momento sin penalización. El texto dice "se renovarán automáticamente salvo cancelación previa" — no describe cómo cancelar, plazo ni proporcionalidad del reembolso.
**Fix:** Reescribir § 7.2(3):
- "Las suscripciones se renovarán automáticamente si el Usuario lo autorizó expresamente durante la contratación."
- "El Usuario puede cancelar la renovación en cualquier momento desde la app o mediante solicitud a [correo] con al menos 48 horas de anticipación al inicio del siguiente período."
- "La cancelación detiene renovaciones futuras sin penalización. No aplica reembolso por el período ya iniciado, salvo lo dispuesto por la LFPC."

#### H-05 — Inconsistencia cruzada: jurisdicción de solicitudes ARCO
**Ubicación:** `T&C § 8.1` remite a `[correo ARCO]`; `Aviso § 8.3` también; pero `T&C § 11.2` establece jurisdicción **tribunales** sin aclarar si los conflictos derivados de ARCO deben pasar primero por la autoridad administrativa (Secretaría Anticorrupción y Buen Gobierno).
**Riesgo:** Conforme LFPDPPP Art. 46, el Titular tiene acción administrativa ante la autoridad ANTES de la vía jurisdiccional. Si el T&C sugiere directamente tribunales, puede inducir a confusión.
**Fix:** Agregar en `T&C § 11.2` cláusula de coordinación: "Para controversias relativas a la protección de datos personales, el Titular podrá acudir a la Secretaría Anticorrupción y Buen Gobierno conforme al procedimiento del Aviso de Privacidad § 8.7, sin perjuicio de las acciones jurisdiccionales aplicables."

#### H-06 — Falta cláusula de notificación a autoridad en caso de brecha
**Ubicación:** `Aviso § 10.1`
**Riesgo:** LFPDPPP 2025 y su Reglamento exigen notificación **al Titular** en 72 horas (ya cubierto) y **a la autoridad reguladora** (Secretaría Anticorrupción y Buen Gobierno) en supuestos de alto riesgo. Solo se menciona la notificación al Titular.
**Fix:** Agregar `§ 10.2 Notificación a autoridad`:
"Cuando la vulneración represente un riesgo alto para los derechos y libertades del Titular, el Responsable notificará adicionalmente a la Secretaría Anticorrupción y Buen Gobierno en el plazo y forma que determine el Reglamento aplicable."

#### H-07 — Ausencia de cláusula sobre decisiones automatizadas / profiling
**Ubicación:** No existe
**Riesgo:** Aun si SACDIA no aplica decisiones automatizadas hoy, es buena práctica declararlo expresamente (GDPR Art. 22, referencia análoga en LFPDPPP). Evita reclamos futuros si se introducen recomendaciones algorítmicas.
**Fix:** Agregar en `Aviso` nueva sección 12.1 "Decisiones automatizadas":
"SACDIA **no somete** al Titular a decisiones basadas exclusivamente en tratamiento automatizado que produzcan efectos jurídicos o le afecten significativamente. Si en el futuro se incorporaran, se notificará con 30 días de anticipación y se habilitará derecho de oposición."

#### H-08 — Two-deep communication: solo declarativo, sin mecanismo técnico
**Ubicación:** `T&C § 4.2(1)`
**Riesgo:** La obligación de two-deep es una norma de conducta, pero no hay mecanismo técnico ni sanción clara. Si ocurre abuso, el Responsable puede ser codemandado por negligencia (standard de cuidado aplicable a plataformas que administran menores — Scoutbook, por ejemplo, implementa bloqueo de mensajería privada adulto-menor).
**Fix:**
- Declarar en T&C § 4.2 que la Plataforma "no habilita canal de mensajería privada entre Usuario adulto y Menor; toda comunicación ocurre a nivel de grupo o con CC al Representante Legal". Si la app actualmente permite mensajes privados, es un riesgo CRÍTICO que debe subirse a C-06.
- Documentar política de auditoría/retención de logs de comunicación para investigaciones de abuso.

---

### MEDIO (recomendado)

#### M-01 — Licencia sobre contenido de menores: redacción extensiva
**Ubicación:** `T&C § 5.2`
**Observación:** La licencia "mundial, sublicenciable, libre de regalías" sobre fotos de menores es potencialmente problemática aunque se limite a "operar el Servicio". Padres pueden objetar.
**Fix:** Reformular eliminando "sublicenciable" y aclarando que el Responsable solo sub-licencia a encargados en lista explícita (§ 7.2 del Aviso). Agregar: "El Responsable no utilizará imágenes de Menores para fines de marketing, promoción del Servicio o testimonios públicos sin consentimiento expreso adicional del Representante Legal."

#### M-02 — Correo ARCO es ejemplo (`arco@sacdia.app`) — placeholder ambiguo
**Ubicación:** Múltiples referencias en ambos documentos
**Observación:** El string `[PENDIENTE: Correo ARCO — ej. arco@sacdia.app]` puede ser malinterpretado como valor final. Debe quedar claro que el ejemplo es ilustrativo.
**Fix:** Cambiar a `[PENDIENTE: Correo ARCO (obligatorio, ej. arco@sacdia.app)]` y asegurar que el README lo liste como CRÍTICO.

#### M-03 — Sección 6.7 (cumplimiento internacional) es demasiado vaga
**Ubicación:** `Aviso § 6.7`
**Observación:** "Aplicará los estándares más protectores exigibles" no es accionable. Un auditor GDPR exigirá cláusulas específicas sobre Data Protection Officer (DPO), representante en UE, o exclusión territorial clara.
**Fix:** Dos alternativas:
- **Exclusión territorial:** "SACDIA no ofrece el Servicio a Titulares domiciliados en la UE o EE.UU. menores de edad. El registro requiere domicilio en los Estados Unidos Mexicanos."
- **Compliance internacional:** designar Data Protection Officer y representante bajo GDPR Art. 27; declarar elegibilidad COPPA Safe Harbor si aplica.

#### M-04 — Revocación de consentimiento: no describe consecuencia técnica por categoría
**Ubicación:** `Aviso § 9.3`
**Observación:** Solo se menciona consecuencia para "datos sensibles de salud". Falta describir qué pasa si se revoca consentimiento para finalidad secundaria, transferencias, o autenticación OAuth.
**Fix:** Tabla de "efecto de revocación" por categoría:

| Dato/Finalidad | Efecto de revocación |
|----------------|---------------------|
| Finalidad secundaria (boletines) | Se dejan de enviar, sin impacto en el Servicio |
| Datos de salud | Restricción de participación en actividades que requieran ficha médica |
| Afiliación religiosa | Baja del club, el Titular mantiene cuenta sin membresía |
| Transferencia a Sentry | No posible sin desactivar monitoreo global (se declara el trade-off) |
| OAuth Google/Apple | Cuenta queda sin método de acceso salvo que migre a password |

#### M-05 — Definiciones inconsistentes entre T&C y Aviso
**Ubicación:** `T&C § 0` vs `Aviso § 0`
**Observación:** `T&C § 0` define "Representante Legal"; `Aviso § 0` también pero ligeramente distinto. "Responsable" se define en ambos, pero el T&C lo declara "titular del tratamiento", lo cual puede confundirse con "Titular" (persona física).
**Fix:** Asegurar que las definiciones sean literalmente idénticas entre ambos documentos. Usar frase "Responsable del tratamiento" (no solo "Responsable") para distinguir de "Titular".

#### M-06 — Sentry: monitoreo de errores con datos sensibles redactados — verificación técnica
**Ubicación:** `Aviso § 7.2` y nota al pie de § 2
**Observación:** El documento afirma que campos sensibles (contraseñas, tokens, tipo sanguíneo, fecha nacimiento, alergias, enfermedades, medicamentos) están "marcados en el interceptor". Esta afirmación es **verificable técnicamente** y, si es incorrecta, expone al Responsable a responsabilidad por declaración falsa en aviso de privacidad.
**Fix:** Antes de publicar, auditar el interceptor Sentry para confirmar que los campos listados están efectivamente redactados. Si hay discrepancia, ajustar el documento o el código.

#### M-07 — FCM / push tokens: no se menciona consentimiento granular para notificaciones
**Ubicación:** `Aviso § 3(8)` (finalidad primaria) vs Apple/Google requieren opt-in para push
**Observación:** Las notificaciones push están en finalidad primaria, pero iOS y Android requieren que el usuario acepte el permiso del sistema. Si rechaza, no debe haber impacto en el Servicio.
**Fix:** Mover "notificaciones push" a finalidad primaria condicional o aclarar que "el envío de notificaciones requiere que el Titular acepte el permiso del sistema operativo; su rechazo no afecta la prestación del Servicio".

---

### BAJO (mejora continua)

#### B-01 — Versión y fecha en header duplicado con frontmatter
**Ubicación:** Línea 11 de ambos documentos vs frontmatter
**Fix:** Dejar solo el frontmatter o generarlo automáticamente desde el frontmatter al render.

#### B-02 — Ausencia de tabla de contenidos navegable
**Ubicación:** Ambos documentos
**Fix:** Agregar TOC markdown al inicio — mejora accesibilidad para usuarios y auditores.

#### B-03 — Idioma inglés no mencionado
**Ubicación:** Ambos documentos
**Observación:** El frontmatter indica aplicabilidad a app iOS/Android + admin web. Si la app es multilingüe (i18n), los documentos legales deben existir en todos los idiomas soportados, con cláusula de prelación.
**Fix:** Agregar cláusula final: "La versión en español es la versión vinculante. Traducciones a otros idiomas se proporcionan por conveniencia."

#### B-04 — Uso de "bajo protesta de decir verdad"
**Ubicación:** `T&C § 3.2(b)`, `§ 3.3`
**Observación:** Figura de Derecho mexicano correcta, pero el Director de Club podría no entender su alcance jurídico (responsabilidad penal por falsedad en declaraciones — CPF Art. 247).
**Fix:** Agregar una oración educativa en la onboarding del Director: "Esta declaración es equivalente a una manifestación bajo protesta de decir verdad ante autoridad, con consecuencias legales si resulta falsa."

#### B-05 — Plantilla ARCO (§ 8.6): incluir campo "tipo de Titular"
**Ubicación:** `Aviso § 8.6`
**Fix:** Agregar campo (7 bis): "Tipo de Titular: [ ] Adulto titular propio [ ] Representante Legal de Menor". Ayuda al triage.

#### B-06 — Copias de respaldo: plazo de purga (90 días) mencionado en T&C pero no en Aviso
**Ubicación:** `T&C § 5.2` menciona purga en 90 días; `Aviso § 10(8)` solo dice "políticas de retención documentadas".
**Fix:** Consolidar el plazo de 90 días en ambos documentos.

#### B-07 — "Firma electrónica" en § 1.1: referencia correcta pero ambigua
**Ubicación:** `T&C § 1.1`
**Observación:** Invoca Art. 1803 CCF, correcto. Pero a nivel federal en materia mercantil aplica también el Código de Comercio Art. 89-114. Una mención dual es más robusta.
**Fix:** "constituye firma electrónica en términos del artículo 1803 del Código Civil Federal y del Título Segundo del Libro Segundo del Código de Comercio."

---

## Checklist de compliance

### LFPDPPP 2025 (México)

| Requisito | Estado | Notas |
|-----------|:------:|-------|
| Identidad del Responsable (Art. 16-I) | ⚠️ | Estructura correcta pero placeholder sin resolver |
| Domicilio del Responsable | ⚠️ | Placeholder |
| Finalidades primarias declaradas (Art. 16-II) | ✅ | § 3, 11 finalidades primarias enumeradas |
| Finalidades secundarias separadas con opt-in | ✅ | § 4, redacción adecuada |
| Mecanismo de oposición a finalidades secundarias | ✅ | § 4 + § 9 |
| Consentimiento expreso para datos sensibles (Art. 9) | ❌ | **C-01**: agrupa salud + religión en una casilla |
| Transferencias declaradas (Art. 36) | ⚠️ | Declaradas pero falta cláusula internacional específica — **H-01** |
| Lista de encargados (Art. 50 Reglamento) | ✅ | § 7.2 tabla completa |
| Derechos ARCO — descripción (Art. 22-26) | ✅ | § 8 correcto |
| Plazo ARCO 20 días hábiles (Art. 32) | ✅ | § 8.4 correcto |
| Gratuidad ARCO (Art. 35) | ✅ | § 8.5 correcto |
| Revocación del consentimiento (Art. 8) | ✅ | § 9, procedimiento claro |
| Responsable de datos personales designado (Art. 29) | ⚠️ | § 14, placeholder sin resolver |
| Notificación de brechas — Titular | ✅ | § 10.1, 72 horas declarado |
| Notificación de brechas — Autoridad | ❌ | **H-06**: no declarado |
| Autoridad correcta: Secretaría Anticorrupción y Buen Gobierno | ✅ | § 8.7 correcto (NO menciona INAI) |
| Medidas de seguridad técnicas/administrativas (Art. 19) | ✅ | § 10, 9 medidas listadas |
| Política de retención | ⚠️ | § 11, plazo 2 años uniforme — **H-02** |
| Cláusula de modificaciones con notificación | ✅ | § 13 correcto |
| Cookies y tecnologías de rastreo | ✅ | § 12 tabla completa |

### COPPA (US — aplica si hay usuarios <13)

| Requisito | Estado | Notas |
|-----------|:------:|-------|
| Aviso claro a padres antes de colectar datos | ✅ | § 6 del Aviso |
| Consentimiento parental verificable (§312.5) | ❌ | **C-02**: solo "bajo protesta de decir verdad" |
| Prohibición de tracking cross-site para <13 | ✅ | § 6.4 |
| Derecho de los padres a revisar y suprimir datos | ✅ | § 6.5 |
| Seguridad de datos de menores | ✅ | § 10 |
| Retención limitada | ⚠️ | **H-02** |
| Safe Harbor / compliance certificada | ❌ | No declarado |

### GDPR-K (EU — aplica si hay usuarios UE)

| Requisito | Estado | Notas |
|-----------|:------:|-------|
| Edad mínima sin consentimiento parental (13-16, varía por país) | ⚠️ | § 6.7 delega vagamente — **M-03** |
| Consentimiento parental verificable (Art. 8) | ❌ | **C-02** |
| Base legal para tratamiento de cada categoría | ⚠️ | No enumerada explícitamente por finalidad |
| DPO designado (Art. 37) | ❌ | No mencionado |
| Representante UE (Art. 27) | ❌ | No mencionado |
| Derecho al olvido diferenciado para menores | ⚠️ | Cubierto por ARCO-Cancelación pero sin énfasis |

### PROFECO / LFPC

| Requisito | Estado | Notas |
|-----------|:------:|-------|
| Limitación de responsabilidad no abusiva (Art. 90) | ❌ | **H-03**: tope MXN $5,000 potencialmente abusivo |
| Renovación automática con cancelación clara (Art. 10 Bis) | ❌ | **H-04** |
| Modificaciones con notificación previa razonable | ✅ | § 12.1 T&C, 15 días |
| Derecho a reembolso | ⚠️ | § 7.2(4) remite a política futura, suficiente si el servicio sigue gratuito |

### Menores — tabla específica

| Requisito | Estado | Notas |
|-----------|:------:|-------|
| Edad mínima declarada | ✅ | T&C § 1.2, sin cuentas propias <18 |
| Prohibición de cuentas independientes para menores | ✅ | T&C § 1.2, § 3.2 |
| Proceso de registro vía Representante Legal | ✅ | T&C § 3.2, Aviso § 6.2 |
| Verificación verificable del consentimiento parental | ❌ | **C-02** |
| Prohibición de publicidad dirigida | ✅ | Aviso § 6.4 |
| Two-deep communication | ⚠️ | **H-08**: declarativo sin mecanismo técnico |
| ARCO para Representante Legal con documentación | ✅ | Aviso § 6.5, § 8.6 |
| Control granular de acceso (RBAC) | ✅ | Aviso § 6.6 |

---

## Placeholders pendientes

El `README.md` lista 9 placeholders. Se confirma la lista completa; agrego severidad:

| Placeholder | Severidad | Justificación |
|---|:-:|---|
| `Razón social de la entidad responsable` | CRÍTICO | Sin esto, no hay identificación legal del Responsable (Art. 16 LFPDPPP) |
| `RFC` | CRÍTICO | Requisito fiscal y de identificación |
| `Domicilio fiscal completo` | CRÍTICO | Requisito para notificaciones ARCO y procesales |
| `Correo ARCO` | CRÍTICO | Sin esto, no hay canal ARCO operativo |
| `Correo de contacto del responsable` | ALTO | Contacto general obligatorio |
| `Nombre y cargo del responsable de datos personales` | CRÍTICO | Art. 29 LFPDPPP |
| `Ciudad y entidad federativa para jurisdicción` | ALTO | Sin esto, se aplica competencia supletoria |
| `URL pública del sitio web` | MEDIO | Canal de publicación del aviso |
| `Versión y fecha de última actualización` | ALTO | Obligatorio para trazabilidad de cambios |

**Observación adicional:** falta placeholder para **responsable DPO/representante GDPR** si se decide compliance EU (M-03).

---

## Recomendaciones finales (top 5 priorizadas)

1. **[BLOQUEANTE] Separar el consentimiento de datos sensibles en dos casillas independientes** (salud vs religión) tanto en UI como en Aviso § 5. Es el riesgo legal más alto porque invalida la base jurídica de todo el tratamiento sensible.

2. **[BLOQUEANTE] Implementar verificación verificable del consentimiento parental** (COPPA §312.5): segundo opt-in por correo al Representante Legal con link único + almacenamiento auditable del formato firmado por mínimo 5 años. Sin esto, exposición FTC + GDPR + LFPDPPP simultánea.

3. **[BLOQUEANTE] Resolver los 9 placeholders**, empezando por razón social, RFC, domicilio, correo ARCO y responsable de datos personales. Mientras no estén resueltos, el documento es inejecutable. Una solicitud ARCO sin correo destino es incumplimiento presunto.

4. **[ALTO] Reescribir T&C § 9.2 (limitación de responsabilidad)** eliminando tope monetario fijo y consolidar redacción en línea con LFPC Art. 79 para mitigar riesgo PROFECO. Reescribir T&C § 7.2(3) (renovación automática) para cumplir LFPC Art. 10 Bis, aun si hoy el servicio es gratuito (el texto queda como provisión futura).

5. **[ALTO] Armonizar COPPA/GDPR-K con la cláusula de edades reales**: los Aventureros (6-9 años) están bajo COPPA por defecto. Decidir y documentar: ¿exclusión territorial (solo México) o compliance multi-jurisdiccional con DPO, Safe Harbor y verificación técnica de consentimiento parental? La ambigüedad actual (§ 6.7) no es defensible ante ninguna autoridad.

**Sugerencia operativa:** bloquear el cambio de estado a `VIGENTE` mediante un check de CI/CD que busque el string `[PENDIENTE:` en los dos archivos y falle si encuentra al menos uno. Esto evita publicación accidental con placeholders.

---

**Fin del reporte.**
