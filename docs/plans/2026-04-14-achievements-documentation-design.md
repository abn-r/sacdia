# Design Doc - Achievements Documentation Framing

**Fecha**: 2026-04-14
**Estado**: DRAFT

## Objetivo

Definir como documentar `achievements/gamification` en SACDIA como feature operativa y no canonica, dejando claro que la primera entrega debe cubrir solo superficie runtime verificable y separar material aspiracional de contratos reales.

## Contexto actual

- Existe superficie runtime real en backend, admin, app movil y base de datos.
- Backend verificado: controllers en `sacdia-backend/src/achievements/achievements.controller.ts` y `sacdia-backend/src/achievements/admin/admin-achievements.controller.ts`, servicio en `sacdia-backend/src/achievements/achievements.service.ts`, eventos emitidos desde clases, investiduras y validacion de honores.
- DB verificada: modelos `achievement_categories`, `achievements`, `user_achievements`, `achievement_event_log` y enums relacionados en `sacdia-backend/prisma/schema.prisma`.
- Consumers verificados: feature movil en `sacdia-app/lib/features/achievements/` y UI/admin CRUD en `sacdia-admin/src/app/(dashboard)/dashboard/achievements/` + `sacdia-admin/src/lib/api/achievements.ts`.
- Drift documental actual: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` no documenta achievements aunque la superficie existe en runtime.
- Drift adicional: el cliente admin tiene divergencias visibles con runtime (`scope`, metodos HTTP, nombre de campo multipart), por lo que la capa API debe documentarse solo despues de una reconciliacion puntual.
- Material existente no canonico: `docs/achievements-seed-draft.md` y `docs/achievements-ui-redesign-spec.md` aportan contexto, pero no fijan contrato runtime.

## Decision de encuadre documental

- Documentar `achievements/gamification` como feature en `docs/features/achievements.md`.
- Marcar el dominio como `NO CANON` hasta que exista decision explicita de promoverlo.
- No tocar `docs/canon/*` salvo confirmacion de que hoy no corresponde mover esta feature al canon.
- Permitir soporte en `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/database/SCHEMA-REFERENCE.md` solo para superficie efectivamente verificada.

## Alcance

- Crear un documento feature-first para achievements.
- Actualizar el registry de features para registrar el nuevo dominio y su estado funcional declarado.
- Agregar la superficie achievements faltante al live reference API si la auditoria corta confirma los endpoints finales.
- Agregar notas humanas de DB si falta hacer visible el dominio achievements en la referencia estructural.
- Explicitar limites entre runtime vigente, material seed y rediseno UI.

## No alcance

- No promover achievements al canon.
- No cambiar runtime backend, admin, app ni schema.
- No normalizar drifts de clientes en este trabajo.
- No documentar comportamiento aspiracional que no tenga evidencia runtime.
- No asumir eventos aun no emitidos o reglas de negocio que solo existan en el seed draft.

## Fuentes de verdad

Orden de uso propuesto para esta documentacion:

1. `sacdia-backend/prisma/schema.prisma`
2. `sacdia-backend/src/achievements/*.ts` y emisores reales de eventos
3. `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/database/SCHEMA-REFERENCE.md` como capas operativas a resincronizar
4. `docs/features/README.md` para registro editorial
5. `docs/achievements-seed-draft.md` y `docs/achievements-ui-redesign-spec.md` solo como contexto subordinado

## Propuesta de archivos a tocar

| Archivo | Accion propuesta | Motivo |
|---|---|---|
| `docs/features/achievements.md` | Crear | Documento operativo principal del dominio |
| `docs/features/README.md` | Modificar | Registrar cobertura editorial minima + estado funcional |
| `docs/api/ENDPOINTS-LIVE-REFERENCE.md` | Modificar | Incorporar achievements si la auditoria confirma los endpoints finales |
| `docs/database/SCHEMA-REFERENCE.md` | Modificar | Hacer explicita la estructura y notas operativas del dominio achievements |
| `docs/achievements-seed-draft.md` | No tocar en esta fase | Fuente subordinada; solo citar diferencias |
| `docs/achievements-ui-redesign-spec.md` | No tocar en esta fase | UI spec subordinada, no contrato runtime |

## Criterios para decidir que entra y que no entra

Entra en la documentacion:

- Endpoints definidos en controllers runtime verificados.
- Modelos, enums y relaciones existentes en Prisma.
- Eventos emitidos desde codigo verificado (`class.started`, `class.completed`, `honor.validated` y otros que tengan evidencia real).
- Consumers admin/app solo como evidencia de uso o drift, no como autoridad primaria.

No entra en la documentacion:

- Reglas seed sin soporte runtime confirmado.
- Claims de UI spec que no modifiquen contrato de datos.
- Suposiciones sobre ranking, badges secretos o retroactividad si no estan cerradas por runtime.
- Cualquier promocion a canon o narrativa de negocio estable.

## Riesgos

- `docs/api/ENDPOINTS-LIVE-REFERENCE.md` hoy omite achievements; si se documenta sin auditar, se puede fijar una superficie incompleta.
- El cliente admin evidencia drift contra runtime (ej. `scope` y multipart field), lo que puede contaminar la documentacion si se lo toma como fuente primaria.
- El seed draft mezcla definicion operativa con contenido aspiracional; requiere filtrado estricto.
- La feature ya existe en app/admin/backend, por lo que una doc vaga podria ocultar divergencias reales en vez de exponerlas.

## Recomendacion operativa

Proceder con una entrega feature-first, pero abrir el implementation plan con una auditoria corta de reconciliacion runtime para achievements antes de editar docs API/DB subordinadas.
