# Developer Workflow Guide

**Estado**: ACTIVE

Guía unificada para trabajar con documentación y desarrollo en SACDIA.

## Flujo recomendado

1. Leer contexto canónico:
   - `docs/README.md`
   - `docs/00-STEERING/*`
2. Ubicar dominio afectado:
   - `docs/01-FEATURES/<feature>/`
   - `docs/02-API/`
   - `docs/03-DATABASE/`
3. Definir alcance:
   - qué cambia
   - qué no cambia
   - impacto en API/DB/UI
4. Implementar con pruebas.
5. Actualizar documentación en el mismo cambio.

## Reglas prácticas

- No implementar desde documentos históricos.
- Si cambia contrato de endpoint, actualizar `docs/02-API/`.
- Si cambia schema o relaciones, actualizar `docs/03-DATABASE/`.
- Si cambia flujo de negocio, actualizar `docs/01-FEATURES/<feature>/`.

## Checklist pre-implementación

- [ ] Leí steering y docs del dominio.
- [ ] Confirmé contrato vigente.
- [ ] Identifiqué pruebas a ejecutar.

## Checklist post-implementación

- [ ] Pruebas relevantes ejecutadas.
- [ ] Documentación sincronizada.
- [ ] Sin referencias a rutas legacy fuera de la estructura canónica actual.
