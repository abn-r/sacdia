# CLAUDE - 01-FEATURES

Guia operativa para documentacion por feature.

## 1) Alcance

- Dominio: modulos funcionales
- Ruta: docs/01-FEATURES/

## 2) Leer primero (orden)

1. docs/00-STEERING/product.md
2. docs/00-STEERING/tech.md
3. docs/01-FEATURES/<feature>/CLAUDE.md
4. docs/01-FEATURES/<feature>/requirements.md (si existe)
5. docs/01-FEATURES/<feature>/design.md (si existe)
6. docs/01-FEATURES/<feature>/walkthrough-*.md (si existe)

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

- Cada feature debe declarar alcance, rutas, riesgos y checklist en su CLAUDE.md.
- Si cambia el contrato API, sincronizar tambien docs/02-API/.
- Si cambia schema/relaciones, sincronizar tambien docs/03-DATABASE/.

## 5) Checklist

- [ ] Se actualizo el feature correcto.
- [ ] Los cambios mantienen trazabilidad con requirements/design.
- [ ] Se sincronizo API/DB si aplica.
