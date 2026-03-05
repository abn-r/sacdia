# CLAUDE - 01-FEATURES

Guía operativa para documentación por feature.

## 1) Alcance

- Dominio: módulos funcionales
- Ruta: `docs/01-FEATURES/`

## 2) Leer primero (orden)

1. `docs/00-STEERING/product.md`
2. `docs/00-STEERING/tech.md`
3. `docs/00-STEERING/coding-standards.md`
4. `docs/01-FEATURES/<feature>/requirements.md` (si existe)
5. `docs/01-FEATURES/<feature>/design.md` (si existe)
6. `docs/01-FEATURES/<feature>/walkthrough-*.md` (si existe)

## 3) Features disponibles

- actividades
- auth
- catalogos
- certificaciones-guias-mayores
- clases-progresivas
- communications
- finanzas
- gestion-clubs
- gestion-seguros
- honores
- infrastructure
- inventario
- validacion-investiduras

## 4) Reglas

- El contexto por feature se centraliza en este archivo y en los docs propios del feature.
- Si cambia contrato API, sincronizar `docs/02-API/`.
- Si cambia schema/relaciones, sincronizar `docs/03-DATABASE/`.

## 5) Checklist

- [ ] Se actualizó el feature correcto.
- [ ] Los cambios mantienen trazabilidad con requirements/design.
- [ ] Se sincronizó API/DB si aplica.

