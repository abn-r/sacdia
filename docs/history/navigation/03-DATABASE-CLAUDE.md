# CLAUDE - 03-DATABASE

Guia operativa para base de datos y migraciones.

## 1) Alcance

- Dominio: database
- Ruta principal: docs/03-DATABASE/
- Codigo relacionado: sacdia-backend/ (Prisma + SQL)

## 2) Leer primero (orden)

1. docs/00-STEERING/tech.md
2. docs/03-DATABASE/README.md
3. docs/03-DATABASE/SCHEMA-REFERENCE.md
4. docs/03-DATABASE/schema.prisma
5. docs/03-DATABASE/migrations/README.md

## 3) Fuente de verdad

- Modelo de datos: docs/03-DATABASE/schema.prisma
- Referencia consolidada: docs/03-DATABASE/SCHEMA-REFERENCE.md
- SQL de migraciones: docs/03-DATABASE/migrations/

## 4) Reglas

- Cambios de schema deben mantener consistencia Prisma <-> SQL.
- Toda migracion debe venir con notas de impacto y rollback cuando aplique.
- Si cambia contrato de datos expuesto por API, actualizar docs/02-API/.

## 5) Checklist

- [ ] Schema Prisma y docs sincronizados.
- [ ] Script SQL agregado/ajustado cuando corresponde.
- [ ] Impacto en endpoints revisado y documentado.
