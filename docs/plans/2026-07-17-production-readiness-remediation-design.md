# Diseño de remediación para el piloto administrativo SACDIA

**Fecha:** 2026-07-17
**Fuente de evidencia:** `DATABASE_URL` de development
**Documento base:** `docs/audit/PRODUCTION-ONBOARDING-OPERATIONS-READINESS-2026-07-17.md`

## Objetivo

Dejar un corredor operativo verificable para capacitar primero al personal administrativo y después al personal operativo, usando Conquistadores ACV como piloto sin presentar datos inconsistentes como configuración definitiva.

## Decisiones aprobadas

- ACV conserva la iglesia Díaz Aragón y cambia al distrito activo Veracruz.
- Se conservan Carlos Mendoza, Ana Torres y Pedro Ramírez en Guías Mayores, y Abner Reyes como director de Conquistadores; se cierran únicamente las cuatro asignaciones `Test` que exceden slots.
- Las 637 discrepancias Conquistadores→Aventureros se corrigen en `honor_club_types` para quedar como Conquistadores.
- Bioseguridad (`LEGACY-649`) queda como Guías Mayores y su proyección legacy se sincroniza a Guías Mayores.
- Las 22 matrículas de Guía Mayor Avanzado se cierran sin borrarlas ni migrarlas.
- Las tres secciones vacías de Club Estella se desactivan hasta que exista personal real.
- La configuración anual 2026 permanece en el alcance de Campo Local ACV durante el piloto.

## Arquitectura de la solución

### 1. Remediación de datos controlada

Un comando operativo versionado, separado de migraciones globales, ejecutará `dry-run`, `apply`, `verify` y `rollback-clone` contra un manifiesto explícito por fila. Validará el fingerprint de la fase, tomará advisory lock, revalidará dentro de la transacción, generará respaldo cifrado con hash y aplicará cambios en aislamiento serializable.

Habrá dos salidas diferentes:

- **Rollback técnico en clon:** puede borrar la nueva fila de historia y reabrir el baseline para repetir pruebas.
- **Compensación operativa:** nunca borra historia; crea una transición compensatoria posterior y marca `NO-GO`. Si el cambio ocurrió en la fecha vigente, el comando rechaza la compensación hasta el día siguiente porque el historial usa precisión `DATE`.

Las 22 matrículas no se reactivan mediante compensación mientras Guía Mayor Avanzado siga inactiva.

### 2. Aplicabilidad canónica de honores

`honor_club_types` será la fuente oficial. `honors.club_type_id` permanecerá un release como proyección compatible, pero no decidirá catálogo, inicio, validación, eventos ni analítica.

El orden seguro es obligatorio:

1. migración aditiva nullable;
2. bloqueo temporal de escrituras del catálogo;
3. `dry-run`, backup y corrección de las 637 asociaciones más Bioseguridad;
4. despliegue backend que lee HCT y dual-writea;
5. despliegue de admin y app;
6. retiro posterior del legacy.

El backend expondrá `applicable_club_types` y centralizará A→`[1]`, C→`[2]`, GM→`[2,3]`. Un cambio editorial no invalida retroactivamente un honor ya iniciado: el progreso conserva un snapshot del tipo de sección.

### 3. Inscripción anual trazable

La app enviará el DTO exacto: `meeting_schedule` como arreglo `{day,time}`, `latitude`/`longitude` y monto decimal serializable. El admin tendrá una ruta separada `/dashboard/annual-enrollments`; la cola existente de investiduras no se reutiliza.

Approve/reject validará el scope territorial del registro objetivo. Rechazar exige razón. La transacción persiste estado, revisor, fecha, auditoría y un outbox idempotente; un worker entrega la notificación y registra reintentos. Aprobar exige plantilla publicada efectiva y crea la carpeta dentro de la misma transacción: no se permite `active` sin carpeta.

### 4. Configuración anual de ACV

El orden será ranking GM → plantillas AV/GM publicadas → carpeta GM → inscripción/aprobación AV. La tarea no inicia hasta recibir:

- `annual-2026-acv.json` firmado por Unión/Campo Local con pesos, secciones, mínimo de aprobación del 80% y cierre el 15 de diciembre de 2026; el estándar reemplaza los placeholders de la plantilla CQ y crea plantillas AV/GM coherentes;
- `pilot-role-roster.json` con director de Aventureros y secretario/tesorero reales de Conquistadores. Las identidades genéricas territoriales se permiten únicamente como cuentas E2E controladas en development; no sustituyen cargos operativos nominales.

El ejecutor nunca inventa valores ni personas. El postflight valida la configuración efectiva respetando precedencia Unión→Campo Local.

### 5. Piloto aislado y certificación

Infraestructura proporciona `DATABASE_URL_PILOT_CLONE` vacío y con TTL. Un script restaura un dump de development y verifica que origen y destino sean distintos. En el clon, un fixture reversible pone la inscripción CQ en `rejected` y elimina la carpeta existente; sus evidencias, evaluaciones y envíos caen por cascade y quedan respaldados antes.

El escenario cubre login, scope, inscripción, aprobación, carpeta, evidencia, actividad, asistencia, finanzas, inventario, reporte mensual, ranking, auditoría, notificación y negativos RBAC.

El clon certifica el flujo, no producción. Después se repite verificación read-only en staging/ambiente objetivo. Android requiere guard estático/CI y, como gate separado con autorización explícita, build release y smoke contra el ambiente piloto.

## Gates de salida

- No usar `prisma/seed.ts` ni seeds legacy.
- No ejecutar remediación en producción.
- No habilitar Guía Mayor Avanzado sin currículo y elegibilidad aprobados.
- No iniciar configuración anual sin los dos manifiestos funcionales.
- Estella solo se reactiva con personal real.
- El piloto es `NO-GO` ante HCT no declarado, slot excedido, matrícula activa en clase inactiva, actor fuera de scope autorizado, carpeta ausente, auditoría/outbox faltante, reporte mensual roto o release apuntando a localhost.
