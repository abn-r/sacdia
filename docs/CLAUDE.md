# CLAUDE - docs

Guia operativa de navegacion para toda la carpeta docs/.
Este archivo resume por donde empezar segun el tipo de cambio.

## 1) Alcance

- Dominio: documentacion global
- Ruta principal: docs/
- Owner: equipo SACDIA

## 2) Leer primero (orden)

1. docs/README.md
2. docs/01-OVERVIEW.md
3. docs/00-STEERING/product.md
4. docs/00-STEERING/tech.md
5. docs/00-STEERING/structure.md
6. docs/00-STEERING/coding-standards.md
7. docs/00-STEERING/data-guidelines.md

Si hay conflicto, priorizar docs/00-STEERING/*.

## 3) Router rapido

- Reglas globales: docs/00-STEERING/
- Features: docs/01-FEATURES/
- API: docs/02-API/
- Database: docs/03-DATABASE/
- Guias: docs/guides/
- Templates: docs/templates/

## 4) Reglas de mantenimiento

- Cualquier cambio funcional debe reflejarse en docs/ en el mismo trabajo.
- Evitar que CLAUDE.md sea memoria de sesion; usar *.local.md para eso.
- Mantener links internos actualizados cuando se renombren archivos.

## 5) Checklist rapido

- [ ] Se actualizo la seccion correcta segun el tipo de cambio.
- [ ] No hay contradiccion con docs/00-STEERING/*.
- [ ] Se validaron rutas y referencias cruzadas.
