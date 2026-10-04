# SACDIA

Workspace de SACDIA (Sistema de Administración de Clubes JA): documentación global y punto de encuentro de los repositorios del proyecto.

## Rol de este archivo

- `README.md` es onboarding resumido del workspace.
- La precedencia documental se define en `docs/canon/source-of-truth.md`.
- La navegación completa de la documentación está en `docs/README.md`.
- Si un roadmap, guía o nota histórica contradice el canon, gana `docs/canon/*`; si la documentación contradice el código de `development`, se corrige la documentación.

## Estructura del workspace

Cada carpeta runtime es un repositorio Git independiente (están en `.gitignore` de este repo).

```text
sacdia/                # Este repo: documentación global y scripts
|- docs/               # Documentación (canon, api, database, features, steering, guías)
|- scripts/            # Verificaciones documentales que corren en CI
|- assets/             # Recursos compartidos
|- sacdia-docs/        # Portal de manuales (gitlink; pendiente de rediseño)
|- sacdia-backend/     # API REST: NestJS + Prisma (repo propio)
|- sacdia-admin/       # Panel web: Next.js 16 (repo propio)
`- sacdia-app/         # App móvil: Flutter (repo propio)
```

`sacdia-docs` es el portal de manuales. Está registrado como gitlink sin `.gitmodules` y se rediseñará como portal de manuales sin permisos por rol; mientras tanto no se edita desde este workspace.

## Flujo de ramas

En los repos runtime (`sacdia-backend`, `sacdia-admin`, `sacdia-app`):

```text
development  →  preproduction (QA)  →  main
```

- `development` es la rama de integración y la referencia de "código actual" para la documentación.
- `preproduction` es el entorno de QA.
- `main` es la rama de release. El producto todavía no está en producción.

## Punto de entrada recomendado

1. `docs/README.md`
2. `docs/canon/source-of-truth.md`
3. `docs/canon/dominio-sacdia.md`
4. `docs/canon/runtime-sacdia.md`
5. `docs/steering/tech.md`
6. `docs/steering/coding-standards.md`

## Documentación

- Canon del sistema: `docs/canon/`
- Normativa técnica: `docs/steering/`
- Features por dominio y estado: `docs/features/README.md`
- Contrato API: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Integración frontend: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Datos: `sacdia-backend/prisma/schema.prisma` (autoridad) y `docs/database/`
- Despliegue: `docs/deployment/DEPLOYMENT-GUIDE.md`
- Puesta en marcha: `docs/guides/SETUP-NEW-PC.md`
- Planes pendientes: `docs/plans/`
- Histórico: `docs/history/` (no es estado actual)

## Cómo trabajar en este workspace

- Lee primero `AGENTS.md` y el `CLAUDE.md` del repo que vayas a tocar.
- Haz los cambios runtime dentro de `sacdia-backend/`, `sacdia-admin/` o `sacdia-app/`, partiendo de `development`.
- Si cambias comportamiento, actualiza la documentación canónica en el mismo trabajo.
- Trata roadmaps, changelogs y notas de sesión como contexto subordinado, no como contrato vigente.

## Estado de la documentación

- Estados de documento: `ACTIVE`, `DRAFT`, `HISTORICAL` y `DEPRECATED` (ver `docs/README.md`).
