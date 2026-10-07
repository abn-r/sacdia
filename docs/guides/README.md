# Guides

**Estado**: ACTIVE
**Actualizado**: 2026-10-04

Guías prácticas. Están subordinadas al canon y a los contratos (ver `docs/canon/source-of-truth.md`).

## Puesta en marcha y flujo de trabajo

| Guía | Para qué |
|---|---|
| [`SETUP-NEW-PC.md`](SETUP-NEW-PC.md) | Preparar un equipo nuevo: repos, toolchain (Node 24, pnpm 10, Flutter), git/gh, flujo de ramas y Claude Code |
| [`developer-workflow.md`](developer-workflow.md) | Flujo de trabajo con código y documentación |
| [`idea-to-spec.md`](idea-to-spec.md) | Convertir una idea en diseño y plan |
| [`admin-integration.md`](admin-integration.md) | Integrar pantallas del admin con la API y el screen catalog |

## Operación

| Guía | Para qué |
|---|---|
| [`domain-email-operations.md`](domain-email-operations.md) | Correo `contacto@sacdia.com`: Cloudflare Email Routing, Resend, Render y Gmail |
| [`google-vision-certificate-ocr.md`](google-vision-certificate-ocr.md) | Runbook de Google Vision con ADC y PDF para certificados. **Pendiente de merge (PR #448 de sacdia-backend)** |
| [`../deployment/DEPLOYMENT-GUIDE.md`](../deployment/DEPLOYMENT-GUIDE.md) | Despliegue del backend (Render), admin (Vercel) y app |

## Dominio

| Guía | Para qué |
|---|---|
| [`formative-state-alignment.md`](formative-state-alignment.md) | Cómo leer el estado formativo anual (`enrollments`) frente a la trayectoria |

## Material de estudio

| Carpeta | Para qué |
|---|---|
| [`conocimiento-sistema/`](conocimiento-sistema/README.md) | Concentrado de conocimiento del sistema (DRAFT, corte 2026-09-14), diagramas y presentación. No reemplaza al canon; revalidar contra el código antes de reutilizarlo |

Las guías antiguas que ya no aplicaban (despliegue en Vercel/Supabase, guías de onboarding del formato anterior) se eliminaron; git conserva su historial.
