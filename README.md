# SACDIA

Workspace de SACDIA con documentacion global y modulos runtime del proyecto.

## Rol de este archivo

- `README.md` es onboarding resumido del workspace.
- La capa canonica del sistema vive en `docs/canon/`.
- La baseline global y rutas de lectura viven en `docs/README.md`.
- Si un roadmap, guia de integracion o nota historica contradice el canon, gana `docs/canon/*`.

## Estructura del workspace

```text
sacdia/
|- docs/             # Baseline documental global
|- sacdia-backend/   # Backend NestJS + Prisma
|- sacdia-admin/     # Admin web Next.js
|- sacdia-app/       # App movil Flutter
|- postman/          # Artefactos de apoyo
`- scripts/          # Utilidades del workspace
```

## Punto de entrada recomendado

1. `docs/README.md`
2. `docs/canon/dominio-sacdia.md`
3. `docs/canon/identidad-sacdia.md`
4. `docs/canon/gobernanza-canon.md`
5. `docs/00-STEERING/tech.md`
6. `docs/00-STEERING/coding-standards.md`

## Baseline documental

- Canon del sistema: `docs/canon/`
- Reglas globales: `docs/00-STEERING/`
- Features por dominio: `docs/01-FEATURES/`
- Contratos API runtime: `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
- Integracion frontend: `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`
- Datos y schema: `docs/03-DATABASE/`
- Planes y cierres historicos: `docs/history/` y documentos marcados como `HISTORICAL`

## Como trabajar en este workspace

- Lee primero `AGENTS.md` y el `CLAUDE.md` del modulo que vayas a tocar.
- Hace cambios runtime dentro de `sacdia-backend/`, `sacdia-admin/` o `sacdia-app/` segun corresponda.
- Si cambias comportamiento, actualiza la documentacion canonica en el mismo trabajo.
- Trata roadmap, changelogs y notas de sesiones como contexto subordinado, no como contrato vigente.

## Estado de la documentacion

- La taxonomia oficial de documentos es `ACTIVE`, `DRAFT`, `HISTORICAL` y `DEPRECATED`.
- La explicacion operativa y precedencia completa estan en `docs/README.md`.
