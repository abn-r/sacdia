# Verificación de arquitectura técnica

**Fecha:** 2026-09-10 · **Estado:** entrega parcial (2/4).

Se completaron dos rondas de corrección por candidato. Solo backend y app pasaron
el gate final; no se generaron HTML del general ni del panel. No se modificó el
renderer para eludir diagnósticos. No se ejecutaron builds ni pruebas del producto.

## Artefactos entregados

Chrome midió 1440×900, 1600×1000, 1920×1080 y 2048×1320: sin overflow horizontal
ni vertical. Se inspeccionaron las capturas claro 1440×900 y oscuro 2048×1320
de ambos mapas: rutas distinguibles, nodos y tarjetas contenidos, composición
equilibrada. El texto secundario es pequeño en laptop; el visor permite zoom.
No se ensayaron manualmente exportación, búsqueda ni todos los controles.
La revisión perceptual es independiente del resultado automatizado, cuyo campo
visualReview permanece pending por contrato del instrumento.

### 04-arquitectura-backend

```text
diagram_type: architecture
output: /Users/abner/Documents/development/sacdia/docs/guides/conocimiento-sistema/diagramas/04-arquitectura-backend.html
specification_sha256: ca35f6c0a6d49537827672c351d09b849a6d3e799bfd8a6683a10dd7c5368888
artifact_sha256: e33cbe23c1fe6461b86667bf81299ed8b05b6121a9e6ce47e1f4f8a00dd4ca6f
validation: 9/9 showcase, 0 errors, 0 warnings
browser_evidence: passed
visual_review: passed
correction_rounds: 2
```

Recibos: [delivery](04-arquitectura-backend-delivery.json), [navegador](04-arquitectura-backend-browser.json).

### 05-arquitectura-app

```text
diagram_type: architecture
output: /Users/abner/Documents/development/sacdia/docs/guides/conocimiento-sistema/diagramas/05-arquitectura-app.html
specification_sha256: 97892af34ae5ed44ce4938228fd10c5beb3ea6d9585e51a519dcda6814c85ba8
artifact_sha256: 5043680ea44b7527015ad60a54d6ba574873bca1f5eef91d4024711c75a413dc
validation: 9/9 showcase, 0 errors, 0 warnings
browser_evidence: passed
visual_review: passed
correction_rounds: 2
```

Recibos: [delivery](05-arquitectura-app-delivery.json), [navegador](05-arquitectura-app-browser.json).

## Candidatos no entregados

- General: composition/label-route-clearance. «Prisma / SQL» se superpone con
  la rama API → R2. Los desplazamientos verticales no resolvieron la colisión.
- Panel: clean-flow/endpoint-side-direction en Next → backend. El redondeo de
  coordenadas deja 0.005 px de diferencia horizontal en los segmentos verticales
  explícitos. Requiere recalcular via con los centros exactos antes de validar.

Recibos: [general](03-arquitectura-general-validation.json),
[panel](06-arquitectura-panel-validation.json). Sus JSON siguen como borradores.
No tienen evidencia de navegador ni revisión perceptual de HTML final.

## Reproducibilidad

Los SHA-256 de las fuentes consultadas están en
[fuentes-arquitectura-2026-09-10.json](fuentes-arquitectura-2026-09-10.json).
Las capturas y recibos del navegador están junto a cada HTML. Archify local
2.17.0-dev.1; comprobación de actualizaciones desactivada mediante variable
de proceso. Los recibos describen estos bytes, no revisiones futuras.
