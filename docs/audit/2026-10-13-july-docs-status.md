# Estado de los documentos de julio rescatados en #130

**Fecha de corte:** 2026-10-13
**Alcance:** los documentos de julio de 2026 que el PR #130 (`60683843`) recuperó de una rama local: la auditoría de preparación para producción del 2026-07-17, su SQL y manifiestos, el panel v2, los planes de inscripción de sección a Camporí, de puesta al día de reportes mensuales, de remediación de preparación para producción y de correo de dominio con Resend.
**Método:** se leyó cada documento y se comprobó contra `origin/development` de `sacdia-backend`, `sacdia-admin` y `sacdia-app` (rutas, migraciones, scripts, historial de merges). No se ejecutaron pruebas, builds ni consultas a bases de datos. Cada documento markdown lleva un banner de estado al inicio; su cuerpo no se tocó.

## Resumen

| Documento | Estado | Evidencia principal | Pendiente o sin determinar |
|---|---|---|---|
| `docs/audit/PRODUCTION-ONBOARDING-OPERATIONS-READINESS-2026-07-17.md` | Parcialmente superado | App #143 y #144 (URL de API y demo de animaciones), backend #447 (año sin solapamiento) | Aprobación anual sin interfaz, integridad del post-registro, División en el alta, manifest de readiness; bootstrap de RBAC sin verificar en base vacía |
| `docs/audit/sql/development-database-readiness-2026-07-17.sql` | Vigente como herramienta; resultados históricos | Consultas de solo lectura citadas en el §13 de la auditoría | Los conteos de julio no se reverificaron; el plan de remediación exige no sobrescribir este baseline |
| `docs/audit/manifests/annual-2026-acv.json` | Aprobado, sin ejecutor | `approvals` del 2026-07-20 con un `content_sha256` común | Ningún script ni servicio lo consume; las aprobaciones son de cuentas `Test` de development |
| `docs/audit/manifests/annual-2026-acv.proposal.json` | Superado | Lo reemplaza `annual-2026-acv.json` (mismo contenido, ya con aprobaciones) | Se conserva como historia |
| `docs/audit/manifests/annual-2026-acv.schema.json` | Vigente, sin validador | Esquema del manifiesto anual | No hay código que lo valide |
| `docs/audit/manifests/pilot-role-roster.schema.json` | Pendiente | Esquema del roster del piloto | No existe un `pilot-role-roster.json` ni consumidor |
| `docs/features/infrastructure/admin-panel-v2.md` | Superado | sacdia-admin `2458e7b` (2026-07-24) retiró el shell v2; `/dashboard/v2` redirige | Eliminar o archivar este documento |
| `docs/plans/2026-07-13-camporee-section-enrollment-design.md` | Implementado | Backend #175 (migración `20260713220000_camporee_section_registration_context`, FK `camporee_members.camporee_club_id`), app #117 | — |
| `docs/plans/2026-07-13-camporee-section-enrollment.md` | Implementado | Ídem | Cada tarea no se reverificó por separado |
| `docs/plans/2026-07-13-monthly-report-catchup-design.md` | Implementado | Backend #181; `runAutoGeneration`, `monthly-reports-timeliness-score.ts`, `MONTHLY_REPORT_MANUAL_DATA_REQUIRED` | — |
| `docs/plans/2026-07-13-monthly-report-catchup-implementation.md` | Implementado | Ídem | — |
| `docs/plans/2026-07-17-production-readiness-remediation-design.md` | Parcial | Backend #191 (núcleo de seguridad), app #143 y #144 (guard del release), DTO móvil con `meeting_schedule` | Comando operativo, cola admin anual, outbox, ejecutor ACV, piloto en clon |
| `docs/plans/2026-07-17-production-readiness-remediation-implementation-plan.md` | Parcial | Ídem | Ver el detalle por tarea abajo |
| `docs/plans/2026-07-23-domain-email-resend-implementation-plan.md` | Implementado | Backend #186; `env.validation.ts`, límite de 90 por 24 horas en `email.processor.ts`, guía `docs/guides/domain-email-operations.md` | Pasos manuales de Cloudflare, Resend y Gmail no verificables desde el código |

## Detalle de la auditoría del 2026-07-17

| Brecha del documento | Hoy | Evidencia |
|---|---|---|
| P0 Bootstrap productivo incompleto | Parcial | Hay seeds versionados en `sacdia-backend/prisma/seeds/` (permisos, `role_permissions`, límites de slots, `system_config`) y el orden está en `docs/deployment/DEPLOYMENT-GUIDE.md` §3. No hay prueba de una base vacía de punta a punta |
| P0 URL de API ausente en el APK release | Resuelto | sacdia-app #143 (2026-08-12) exige HTTPS en `API_BASE_URL`; el CI valida el secret (job `Validate API_BASE_URL`, #149 lo deduplicó) |
| P0 Aprobación anual sin interfaz | Pendiente | El backend expone `GET /club-enrollments/validation/queue` y approve/reject; no hay referencias en `sacdia-admin/src` ni en `sacdia-app/lib` (en la app, las aprobaciones del coordinador son de Camporee, no de inscripción anual) |
| P1 Integridad del post-registro | Pendiente | `resolveSelectedClub` solo comprueba que la sección exista |
| P1 División ausente en el alta | Pendiente | Sin `divisionId` en la app (`lib/features/post_registration`) ni en el DTO |
| P1 Año vigente ambiguo | Resuelto | Migración `20260921153000_ecclesiastical_year_no_overlap` (backend #447) |
| P1 Manifest de catálogos / readiness | Pendiente | Solo existe el núcleo de `scripts/remediate-production-readiness.ts` |
| P1 Onboarding instructivo | Parcial | La app tiene `lib/core/onboarding/sac_onboarding.dart` (showcase contextual); no se verificó que cubra tours por rol |
| P1 `assistant-admin` inconsistente | Parcial | `role-permissions.seed.sql` ya le asigna permisos; no se verificó la política completa |
| P2 Demo de animaciones en el dashboard móvil | Resuelto | Retirado en sacdia-app #143 |

## Detalle del plan de remediación del 2026-07-17

| Tarea | Estado | Nota |
|---|---|---|
| 0. Inputs funcionales y roster | Parcial | Manifiesto ACV aprobado el 2026-07-20; no hay `pilot-role-roster.json` |
| 1. Baseline, respaldo y attestation | Parcial | Funciones en `scripts/remediate-production-readiness.ts` (backend #191); sin CLI que las ejecute |
| 2. Saneamiento de jerarquía, cargos, matrículas y Estella | No determinado | Es una corrección de datos de `development`; no se consultó la base |
| 3. Aplicabilidad de honores | No determinado | `honor_club_types` y `applicable_club_types` existen en backend desde antes de julio; no se verificó el retiro del campo legado ni los 637 ajustes |
| 4A y 4B. Admin y app de honores | No determinado | — |
| 5. Aprobación anual scoped, atómica y durable | Parcial | Hay filtro de alcance en la cola; la carpeta se crea solo si existe plantilla y no hay outbox |
| 6. Contrato móvil de inscripción anual | Implementado | `meeting_schedule` como arreglo y `latitude`/`longitude` en `enrollment_remote_data_source.dart` |
| 7. Cola admin anual independiente | Pendiente | No existe `/dashboard/annual-enrollments` en `sacdia-admin` |
| 8. Configuración anual de ACV | Pendiente | Sin ejecutor del manifiesto |
| 9. Android release y reportes | Parcial | Guard y firma del release en CI (app #143 y #144); el reporte mensual lo cubre #181 |
| 10. Piloto E2E en clon y staging | Pendiente | No hay script de clon; ver además que `staging` y `production` de Neon no se usan hoy |

## Otras observaciones

- **Copias duplicadas.** El commit `b1dec72a` (2026-10-04) movió varios de estos archivos a `docs/history/` y #130 los volvió a poner en su ruta activa. Quedan dos copias idénticas (salvo el banner nuevo, y `admin-panel-v2.md`, que ya difería) de: la auditoría, su SQL, los tres manifiestos `annual-2026-acv.*`, `admin-panel-v2.md`, el diseño de inscripción de sección y el diseño de reportes mensuales. Conviene decidir una sola ubicación.
- **Documentos de investidura desactualizados.** `docs/features/validacion-investiduras.md` y `docs/plans/2026-09-28-investidura-autorizacion.md` aún dicen que nada está mergeado ni desplegado y que las migraciones no están en Neon, pero la fase 8 y las pantallas de panel y app están en `development` (backend #465, #466, #468, #469; panel #223 a #226; app #157 a #160). Esta rama no los modificó.
- **Neon.** La nota de la fase 8 del 2026-10-08 dice que la rama `staging` está archivada y que `production` no tenía las migraciones de investidura; el estado informado el 2026-10-13 es que ambas existen y están migradas, sin uso. Ver `docs/deployment/DEPLOYMENT-GUIDE.md` §0.
- **Runbook OCR.** `docs/guides/ocr-proxy-preprod-infra.md` conserva el estado «propuesto» del 2026-10-07 aunque el proxy ya está en Cloud Run según el responsable.
