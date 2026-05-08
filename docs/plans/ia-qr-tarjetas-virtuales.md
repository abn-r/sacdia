# IA, QR y tarjetas virtuales — roadmap

**Estado**: PLANIFICADO (aspiracional / exploración)

> Ninguna de las capacidades descritas está implementada. Este documento captura hipótesis de valor y candidatos a exploración. No comunicar como vigente.

---

## 1. Motivación

Explorar capacidades diferenciales frente a soluciones tradicionales (SGC) con tres líneas de trabajo candidatas:

- **IA aplicada** — asistente institucional, generación de reportes, análisis predictivo, sugerencias contextuales;
- **Códigos QR** — identificación rápida de miembros, asistencia por escaneo, integración con eventos presenciales;
- **Tarjetas virtuales** — credencial digital del miembro con vigencia, roles y foto.

## 2. Estado actual

Nada implementado. Verificado por grep negativo al 2026-04-22: no hay módulos, endpoints ni UI relacionados con IA, QR o tarjetas virtuales en `sacdia-backend/`, `sacdia-admin/` ni `sacdia-app/`.

## 3. Hipótesis de valor — IA aplicada

Casos candidatos:

1. **Asistente institucional conversacional** — responde preguntas sobre trayectoria, requisitos de investidura, estado de validaciones.
2. **Resumen automático de reportes mensuales** — genera narrativa ejecutiva a partir de `monthly_reports`.
3. **Predicción de riesgo** — detecta clubes con patrones de abandono o caída de puntajes.
4. **Sugerencia de actividades** — recomienda próximos pasos formativos a cada miembro.
5. **Triaje de validaciones** — prioriza cola de `evidence-review` según señales.

Decisiones pendientes:

- uso de modelo propio vs API externa (Claude, GPT);
- privacidad de datos institucionales y de menores;
- presupuesto recurrente.

## 4. Hipótesis de valor — QR

Casos candidatos:

1. **QR del miembro** — identificación única escaneable (usa `users.user_id` + firma HMAC).
2. **Asistencia por escaneo** — acelera captura de presencia en actividades y camporees.
3. **Inscripción rápida** — QR del club para unirse sin formularios.
4. **Validación cruzada** — escanear QR para confirmar identidad en eventos multi-club.

Decisiones pendientes:

- duración y rotación del QR (estático vs dinámico por sesión);
- escáner embebido en la app vs lector externo;
- integración con `activities` y `camporees`.

## 5. Hipótesis de valor — Tarjetas virtuales

Casos candidatos:

1. **Credencial del miembro** — foto, nombre, rol institucional activo, club, sección, vigencia.
2. **Tarjeta descargable (PDF/imagen)** — para imprimir o compartir.
3. **Apple Wallet / Google Wallet** — integración nativa (exploración lejana).
4. **Tarjeta con tier de achievements** — refleja nivel institucional del miembro.

Decisiones pendientes:

- política de foto institucional (quién la toma, cómo se valida);
- vigencia y renovación;
- qué roles son visibles públicamente en la tarjeta.

## 6. Secuencia tentativa de exploración

1. spike IA (asistente lectura sobre canon + docs; riesgo bajo; valor demostrativo);
2. QR miembro (infraestructura menor; alto valor en presencial);
3. Tarjeta virtual básica (PDF/imagen descargable, sin wallets nativos).

El resto queda en exploración pasiva hasta que haya señales de demanda.

## 7. Riesgos

- **IA**: alucinaciones sobre datos institucionales sensibles; costo de inferencia; responsabilidad legal sobre respuestas.
- **QR**: robo de credencial si no hay rotación; falsificación si la firma es débil.
- **Tarjetas virtuales**: privacidad de menores; actualizaciones que requieren regenerar.

## 8. Criterio de éxito (tentativo por línea)

| Línea | Éxito mínimo |
|-------|--------------|
| IA asistente | 80% de consultas respondidas con precisión institucional |
| QR miembro | captura de asistencia 3× más rápida que manual |
| Tarjeta virtual | descarga disponible y válida ante consulta institucional |

## 9. Estado actual

- **Prioridad**: baja. Son diferenciadores estratégicos, no urgencias operativas.
- **Decisión inmediata**: dejar en backlog exploratorio. Priorizar una sola línea si surge demanda concreta.
