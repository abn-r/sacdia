# Agent Ownership — Codex + Cursor Composer

**Estado**: ACTIVE  
**Última actualización**: 2026-06-25  
**Propósito**: coordinar cambios integrales en SACDIA separando responsabilidades entre Codex y Cursor Composer sin perder trazabilidad técnica.

---

## Principio rector

SACDIA trabaja **contract-first**: primero se valida el contrato funcional y técnico; después cada agente implementa en su superficie.

El objetivo no es que dos agentes "codeen más rápido". El objetivo es que cada uno trabaje donde aporta mejor calidad:

- Codex protege backend, app móvil, contratos, seguridad, datos y documentación técnica.
- Cursor Composer 2.5 concentra el diseño y acomodo visual del panel administrativo.

---

## Ownership por superficie

### Codex

Responsable principal de:

- `sacdia-backend/`
- `sacdia-app/`
- contratos REST, DTOs, errores, paginación, permisos y validaciones
- cambios de schema/migraciones y documentación de datos
- documentación funcional/técnica en `docs/api/`, `docs/database/`, `docs/features/` y `docs/steering/`
- revisión de integración, seguridad y consistencia cross-repo

Codex **no debe rediseñar el panel administrativo** salvo que el usuario lo pida explícitamente o que sea un ajuste mínimo para corregir integración rota.

### Cursor Composer 2.5

Responsable principal de:

- `sacdia-admin/`
- composición visual del panel administrativo
- jerarquía de información
- layouts, responsive, dashboards, tablas, cards, estados vacíos y polish visual
- uso de shadcn/ui, Tailwind CSS y componentes del admin

Cursor Composer **no debe inventar contratos backend**: endpoints, DTOs, permisos, errores y reglas de negocio deben venir de la documentación o de una decisión explícita.

---

## Flujo para cambios integrales

1. **Definir dominio y contrato**
   - Revisar `docs/features/`, `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y documentación del módulo.
   - Identificar qué necesita backend, app y admin.

2. **Codex prepara la base contractual**
   - Implementa o ajusta backend/app cuando aplique.
   - Actualiza contratos API, DTOs, errores, permisos y docs.
   - Deja claro qué debe consumir el admin.

3. **Cursor implementa el admin**
   - Trabaja sobre `sacdia-admin/`.
   - Mejora acomodo, jerarquía visual y experiencia de uso.
   - Consume los contratos ya definidos.

4. **Codex revisa integración**
   - Verifica que el admin no rompa contratos, auth, permisos, tipos o seguridad.
   - No evalúa el diseño por gusto visual salvo problemas funcionales claros.

---

## Reglas de coordinación

- Si el admin necesita datos nuevos, primero se documenta como solicitud de contrato backend.
- Si backend o app cambian comportamiento visible para admin, se actualiza documentación antes del handoff.
- No usar mocks como sustituto de contrato real; si se usan para diseño, deben quedar marcados como fixtures temporales.
- Mantener cambios por superficie cuando sea posible: backend/app por Codex, admin por Cursor.
- En cambios cross-repo, el handoff debe indicar endpoints, DTOs, permisos, estados de carga/vacío/error y criterios de aceptación.

---

## Template de handoff para Cursor

```markdown
# Handoff admin — [feature]

## Objetivo
[Qué debe mejorar o implementar el panel]

## Fuente de verdad
- Docs de feature:
- API reference:
- Diseño/criterios:

## Contratos disponibles
- Endpoint:
- DTO request:
- DTO response:
- Errores esperados:
- Permisos/RBAC:

## Estados UI requeridos
- Loading:
- Empty:
- Error:
- Success:

## Restricciones
- No cambiar contratos backend.
- No hardcodear datos productivos.
- Mantener patrones existentes de `sacdia-admin/`.

## Criterios de aceptación
- [Criterio verificable 1]
- [Criterio verificable 2]
```
