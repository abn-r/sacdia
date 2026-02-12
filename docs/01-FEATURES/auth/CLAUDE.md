# CLAUDE - 01-FEATURES/auth

Guia operativa para el feature auth.

## 1) Alcance

- Dominio: feature
- Feature: auth
- Ruta docs: docs/01-FEATURES/auth/
- Codigo relacionado: sacdia-backend/, sacdia-admin/, sacdia-app/ (segun aplique)

## 2) Leer primero (orden)

1. docs/00-STEERING/product.md
2. docs/00-STEERING/tech.md
3. docs/00-STEERING/coding-standards.md
4. docs/01-FEATURES/auth/PERMISSIONS-SYSTEM.md
5. docs/01-FEATURES/auth/walkthrough-auth-module.md
6. docs/01-FEATURES/auth/walkthrough-mfa.md
7. docs/01-FEATURES/auth/walkthrough-oauth.md
8. docs/01-FEATURES/auth/walkthrough-security.md
9. docs/01-FEATURES/auth/walkthrough-sessions.md
10. docs/01-FEATURES/auth/walkthrough-users-emergency.md

## 3) Fuente de verdad del feature

- Requisitos funcionales: docs/01-FEATURES/auth/requirements.md (si existe)
- Diseno funcional/tecnico: docs/01-FEATURES/auth/design.md (si existe)
- Walkthroughs: docs/01-FEATURES/auth/walkthrough-*.md (si existe)
- Contratos API: docs/02-API/ENDPOINTS-REFERENCE.md y docs/02-API/API-SPECIFICATION.md
- Datos/schema: docs/03-DATABASE/SCHEMA-REFERENCE.md

## 4) Riesgos y limites

- Riesgo alto: romper contratos API consumidos por admin/app.
- Riesgo medio: cambios en validaciones, reglas de negocio o catalogos.
- No usar este archivo para memoria temporal de sesion.

## 5) Checklist rapido

- [ ] Cambios alineados a requirements/design del feature.
- [ ] Contratos API actualizados si hubo cambios de endpoint/DTO/error.
- [ ] Documentacion de DB actualizada si hubo cambios de schema.
