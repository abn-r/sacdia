# IA, QR y tarjetas virtuales — roadmap

**Estado**: QR y tarjeta virtual IMPLEMENTADOS; línea de IA PLANIFICADA (actualizado 2026-10-04, verificado contra `development`)

> **Hecho** (en `development`): QR firmado del miembro, validación y escaneo de QR, credencial virtual con PDF y modo offline.
> **Falta**: toda la línea de IA aplicada (§3); integración con Apple/Google Wallet; inscripción rápida por QR de club.
> El diseño ya implementado de QR y credencial está archivado en `docs/history/plans/`.

---

## 1. Motivación

Explorar capacidades diferenciales frente a soluciones tradicionales (SGC) con tres líneas de trabajo:

- **IA aplicada** — asistente institucional, generación de reportes, análisis predictivo, sugerencias contextuales;
- **Códigos QR** — identificación rápida de miembros, asistencia por escaneo, integración con eventos presenciales;
- **Tarjetas virtuales** — credencial digital del miembro con vigencia, roles y foto.

## 2. Estado actual

| Línea | Estado | Evidencia |
|---|---|---|
| QR del miembro | Implementado | Módulo `sacdia-backend/src/qr/`: `GET /qr/member/token` emite un JWT HS256 de 24 h firmado con `QR_JWT_SECRET` (`aud=sacdia:qr-member`, no válido como token de API); `GET /qr/me`, `GET /qr/me/card`, `GET /qr/me/card.pdf`; `POST /qr/validate` (`qr:validate`) y `POST /qr/scan` (alias legacy con captura de asistencia, `attendance:manage`) |
| Escaneo en la app | Implementado | `sacdia-app/lib/features/qr/` (`qr_scanner_view.dart`, `mobile_scanner`) |
| Tarjeta virtual | Implementado | `sacdia-app/lib/features/virtual_card/`: credencial con QR, compartir como imagen/PDF (`credential_image_pdf.dart`) y copia cacheada mostrada como offline si falla la red |
| Wallets nativos | No implementado | Sin integración Apple Wallet / Google Wallet |
| IA aplicada | No implementado | Ningún módulo, endpoint ni dependencia de modelos de IA en los repos runtime |

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

> Casos 1, 2 y 4 implementados (ver §2): el QR usa un JWT firmado de 24 h, no una firma HMAC sobre `user_id`; el escáner va embebido en la app. El caso 3 sigue pendiente.

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

> Casos 1 y 2 implementados (ver §2). Los casos 3 y 4 siguen pendientes.

Casos candidatos:

1. **Credencial del miembro** — foto, nombre, rol institucional activo, club, sección, vigencia.
2. **Tarjeta descargable (PDF/imagen)** — para imprimir o compartir.
3. **Apple Wallet / Google Wallet** — integración nativa (exploración lejana).
4. **Tarjeta con tier de achievements** — refleja nivel institucional del miembro.

Decisiones pendientes:

- política de foto institucional (quién la toma, cómo se valida);
- vigencia y renovación;
- qué roles son visibles públicamente en la tarjeta.

## 6. Secuencia

1. QR miembro — hecho.
2. Tarjeta virtual básica (imagen/PDF, sin wallets) — hecho.
3. Spike de IA (asistente de lectura sobre canon y documentación; riesgo bajo, valor demostrativo) — pendiente.
4. Wallets nativos e inscripción por QR de club — exploración pasiva hasta que haya demanda.

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

## 9. Siguiente paso

- **Prioridad**: baja para IA; es un diferenciador estratégico, no una urgencia operativa.
- **Decisión inmediata**: mantener la línea de IA en backlog exploratorio y priorizarla solo si surge demanda concreta. Las decisiones pendientes de §3 (modelo, privacidad de datos de menores, presupuesto) deben cerrarse antes de cualquier spike.
