# SACDIA — Especificacion de Diseno: 10 Features (Roadmap Enfoque A)

> **Fecha**: 2026-03-23
> **Estado**: Aprobado
> **Alcance**: sacdia-backend (NestJS+Prisma), sacdia-admin (Next.js), sacdia-app (Flutter)

---

## Tabla de Contenidos

1. [Contexto](#contexto)
2. [Orden de Implementacion (Enfoque A — Por Dependencias)](#orden-de-implementacion-enfoque-a--por-dependencias)
3. [Fase 1: Inscripcion Anual del Club](#fase-1-inscripcion-anual-del-club-club_enrollments)
4. [Fase 2: Validacion de Clases y Especialidades](#fase-2-validacion-de-clases-y-especialidades)
5. [Fase 3: Flujo de Investidura](#fase-3-flujo-de-investidura)
6. [Fase 4: Camporees Completo](#fase-4-camporees-completo)
7. [Fase 5: Carpeta Anual](#fase-5-carpeta-anual)
8. [Fase 6: Reportes Mensuales](#fase-6-reportes-mensuales)
9. [Fase 7: Cambio de Club + Asignacion de Cargos con Autorizacion](#fase-7-cambio-de-club--asignacion-de-cargos-con-autorizacion)
10. [Configuracion Global del Sistema](#configuracion-global-del-sistema)
11. [Resumen de Modelos](#resumen-de-modelos)

---

## Contexto

| Componente | Tecnologia |
|---|---|
| Monorepo backend | NestJS + Prisma |
| Panel admin | Next.js |
| App movil | Flutter |
| RBAC | 20 roles, 107 permisos, ~780 role_permissions |
| Auth | Better Auth, JWT HS256 |
| Base de datos | PostgreSQL via Neon |
| Storage | Cloudflare R2 |

---

## Orden de Implementacion (Enfoque A — Por Dependencias)

| Fase | Feature | Prioridad |
|---|---|---|
| 1 | Inscripcion Anual del Club | Prerequisito de todo |
| 2 | Validacion de Clases y Especialidades | Base para investidura |
| 3 | Flujo de Investidura | Depende de validacion |
| 4 | Camporees Completo (inscripcion + pagos + materiales) | |
| 5 | Carpeta Anual | |
| 6 | Reportes Mensuales | Consume datos de todo lo anterior |
| 7 | Cambio de Club + Asignacion de Cargos con Autorizacion | Independientes |

---

## Fase 1: Inscripcion Anual del Club (`club_enrollments`)

### Concepto

Cada ano eclesiastico, cada seccion de club debe inscribirse para quedar habilitada. Sin inscripcion activa, los demas procesos no operan.

### Modelo: `club_enrollments`

| Campo | Tipo | Descripcion |
|---|---|---|
| `club_enrollment_id` | UUID PK | |
| `club_section_id` | FK → `club_sections` | Seccion del club |
| `ecclesiastical_year_id` | FK → `ecclesiastical_years` | Ano eclesiastico |
| `status` | ENUM: `active`, `closed` | Sin draft — va directo a `active` |
| `address` | String? | Direccion del club ese ano |
| `meeting_days` | String? | Dias y horarios de reunion |
| `created_by` | FK → `users` | Director o secretario que la creo |
| `closed_at` | Timestamp? | Cierre automatico (proceso futuro) |
| `created_at` / `modified_at` | Timestamps | |

**Constraint unico**: (`club_section_id`, `ecclesiastical_year_id`)

### Endpoints

- `POST /clubs/:clubId/sections/:sectionId/enrollments` — crear inscripcion (director o secretario)
- `GET /clubs/:clubId/sections/:sectionId/enrollments` — listar por ano
- `GET /clubs/:clubId/sections/:sectionId/enrollments/current` — inscripcion activa

### Flujo

1. Director o secretario crea la inscripcion anual → status `active` inmediato.
2. Sistema verifica que no exista otra inscripcion activa para esa seccion + ano.
3. Directiva y miembros ya vinculados via `club_role_assignments` existente.
4. Endpoints del sistema validan inscripcion `active` para operar.

### Restricciones de Roles por Seccion

#### Modelo: `role_slot_limits`

| Campo | Tipo | Descripcion |
|---|---|---|
| `role_slot_limit_id` | UUID PK | |
| `role_id` | FK → `roles` | Que rol |
| `max_per_section` | Int? | Maximo permitido (`null` = sin limite) |

#### Limites por rol

| Rol | `max_per_section` |
|---|---|
| `director` | 1 |
| `deputy-director` | 2 |
| `secretary` | 1 |
| `treasurer` | 1 |
| `secretary-treasurer` | 1 |
| `counselor` | null |
| `member` | null |

**Regla de exclusion mutua**: `secretary` y `secretary-treasurer` son mutuamente excluyentes — si hay `secretary-treasurer`, no puede haber `secretary` ni `treasurer` separados, y viceversa.

**Validacion**: Al asignar un rol, el sistema verifica que no se exceda el limite. Aplica tanto para asignacion directa del director como para solicitudes del `assistant-lf`.

---

## Fase 2: Validacion de Clases y Especialidades

### Concepto

Cuando un miembro completa avance en una clase o especialidad, un coordinador debe validar formalmente. El consejero puede revisar y confirmar avance parcial pero NO valida.

### Roles en el proceso

- **Miembro**: registra avance.
- **Consejero**: revisa y confirma que el avance se va completando (visto bueno parcial, no validacion formal).
- **Coordinador**: valida formalmente clases y especialidades (`coordinador`, `zone-coordinator`, o `general-coordinator`).

### Estados de validacion

| Estado | Significado |
|---|---|
| `in_progress` | Miembro esta trabajando |
| `pending_review` | Miembro completo, espera validacion del coordinador |
| `approved` | Coordinador valido formalmente |
| `rejected` | Coordinador rechazo con motivo → vuelve a `in_progress` |

### Cambios a tablas existentes

- `users_classes`: agregar campo `validation_status` (enum).
- `users_honors`: agregar campo `validation_status` (enum).

### Modelo nuevo: `validation_logs`

| Campo | Tipo | Descripcion |
|---|---|---|
| `validation_log_id` | UUID PK | |
| `entity_type` | ENUM: `class`, `honor` | Que se valido |
| `entity_id` | UUID | FK al registro de `users_classes` o `users_honors` |
| `user_id` | FK → `users` | Miembro dueno del avance |
| `action` | ENUM: `submitted`, `approved`, `rejected` | Que paso |
| `performed_by` | FK → `users` | Quien realizo la accion |
| `comment` | String? | Motivo de rechazo u observacion |
| `created_at` | Timestamp | |

### Umbral de Aptitud para Investidura

Si el miembro tiene ≥ umbral configurable (default 80%) de requisitos aprobados → sistema lo marca como apto para investidura. Umbral se configura globalmente en `system_config`.

### Flujo

1. Miembro registra avance progresivo.
2. Consejero puede ver avance y confirmar parcialmente (sin cambiar estado formal).
3. Cuando miembro completa → `pending_review`.
4. Coordinador revisa y aprueba o rechaza con comentario.
5. Si rechaza → vuelve a `in_progress` con motivo visible.
6. Si aprueba → `approved`.

---

## Fase 3: Flujo de Investidura

### Concepto

Digitalizar el proceso actual: revision de cuadernillos → notificacion al campo local → autorizacion. Cadena de aprobacion de 4 niveles.

### Estados de la solicitud

| Estado | Quien actua |
|---|---|
| `eligible` | Sistema detecta automaticamente (≥ umbral) |
| `submitted` | Consejero envia solicitud |
| `club_approved` | Director de seccion aprueba |
| `coordinator_approved` | Coordinador (zona o campo local) valida |
| `field_approved` | Campo local (`assistant-lf` / `director-lf`) autoriza |
| `invested` | Miembro investido |
| `rejected` | Rechazado en cualquier nivel con motivo |

### Flujo

1. Sistema detecta miembros aptos automaticamente.
2. Consejero ve lista de miembros aptos de sus clases.
3. Consejero envia solicitud de investidura → `submitted`.
4. Director de seccion revisa y aprueba → `club_approved`.
5. Coordinador valida → `coordinator_approved`.
6. Campo local autoriza → `field_approved`.
7. Se marca al miembro como investido → `invested`.

Cualquier nivel puede rechazar con motivo → `rejected`.

### Requisito adicional

El sistema valida que la seccion tenga ≥ N reportes mensuales `submitted` (configurable, default 10) para permitir investidura.

---

## Fase 4: Camporees Completo

### Concepto

Completar el modulo de camporees existente con inscripcion a nivel de club y registro de pagos.

### 4a. Inscripcion a nivel de club

#### Modelo: `camporee_clubs` (tabla ya existe, activar)

| Campo | Tipo | Descripcion |
|---|---|---|
| `camporee_club_id` | PK | Ya existe |
| `camporee_id` | FK → `local_camporees` | |
| `club_section_id` | FK → `club_sections` | Que seccion se inscribe |
| `registered_by` | FK → `users` | Secretario que inscribio |
| `status` | ENUM: `registered`, `paid`, `cancelled` | Nuevo |
| `created_at` / `modified_at` | Timestamps | |

### 4b. Pagos

Sin pasarela online — registro manual con referencia a comprobante fisico. La persona paga al campo local y recibe comprobante.

#### Modelo nuevo: `camporee_payments`

| Campo | Tipo | Descripcion |
|---|---|---|
| `camporee_payment_id` | UUID PK | |
| `camporee_member_id` | FK → `camporee_members` | Quien pago |
| `amount` | Decimal | Monto pagado |
| `payment_type` | ENUM: `inscription`, `materials`, `other` | Tipo de pago |
| `reference` | String? | Numero de comprobante/recibo |
| `notes` | String? | Observaciones |
| `registered_by` | FK → `users` | Quien registro el pago |
| `paid_at` | Date | Fecha del pago |
| `created_at` / `modified_at` | Timestamps | |

### Flujo

1. Se crea el camporee (ya existe).
2. Secretario inscribe la seccion del club al camporee.
3. Se registran los miembros asistentes (ya existe, validando seguro).
4. Tesorero/secretario registra pagos individuales (inscripcion, materiales, otros).
5. Se puede consultar estado de pagos por miembro y totales.

---

## Fase 5: Carpeta Anual

### Concepto

Estructura fija de secciones con requisitos predefinidos por ano y tipo de club. Secretario sube evidencias. Carpeta se puede cerrar y no se edita despues.

### Modelo: `folder_templates`

| Campo | Tipo | Descripcion |
|---|---|---|
| `folder_template_id` | UUID PK | |
| `name` | String | "Carpeta Anual Conquistadores 2026" |
| `club_type_id` | FK → `club_types` | Para que tipo de club |
| `ecclesiastical_year_id` | FK → `ecclesiastical_years` | Ano |
| `active` | Boolean | |

### Modelo: `folder_template_sections`

| Campo | Tipo | Descripcion |
|---|---|---|
| `section_id` | UUID PK | |
| `folder_template_id` | FK | |
| `name` | String | "Acta constitutiva", "Plan de trabajo" |
| `description` | String? | Que se espera |
| `order` | Int | Orden de presentacion |
| `required` | Boolean | Obligatoria para cerrar |

### Modelo: `annual_folders`

| Campo | Tipo | Descripcion |
|---|---|---|
| `annual_folder_id` | UUID PK | |
| `club_enrollment_id` | FK → `club_enrollments` | Vinculada a inscripcion anual |
| `folder_template_id` | FK → `folder_templates` | Plantilla |
| `status` | ENUM: `open`, `submitted`, `closed` | |
| `submitted_at` | Timestamp? | |
| `closed_at` | Timestamp? | No mas ediciones |
| `created_at` / `modified_at` | Timestamps | |

### Modelo: `annual_folder_evidences`

| Campo | Tipo | Descripcion |
|---|---|---|
| `evidence_id` | UUID PK | |
| `annual_folder_id` | FK | |
| `section_id` | FK → `folder_template_sections` | A que seccion |
| `file_url` | String | URL en R2 |
| `file_name` | String | Nombre original |
| `uploaded_by` | FK → `users` | |
| `notes` | String? | |
| `created_at` / `modified_at` | Timestamps | |

### Flujo

1. Admin o campo local crea plantilla con secciones para el ano.
2. Al crear inscripcion anual del club, se genera carpeta automaticamente.
3. Secretario sube evidencias mientras status = `open`.
4. Envia → `submitted`.
5. Campo local cierra → `closed` (no mas ediciones).

---

## Fase 6: Reportes Mensuales

### Concepto

El sistema genera automaticamente el reporte mensual con datos existentes. El secretario completa secciones manuales (actividad misionera, servicio, juntas).

### Secciones del reporte

| Seccion | Fuente | Auto/Manual |
|---|---|---|
| Administracion — directiva, miembros, horarios, juntas | `club_role_assignments` + `club_enrollments` + captura | Mixto |
| Ensenanzas — especialidades impartidas/terminadas | `users_honors` approved en el mes | Auto |
| Actividades del Club — fecha, lugar, descripcion | activities del mes | Auto |
| Finanzas — ingresos, egresos, saldo | finances del mes + saldo anterior | Auto |
| Actividad Misionera — bautizos, estudios biblicos | Captura manual mensual | Manual |
| Servicio — descripcion servicio iglesia/comunidad | Captura manual mensual | Manual |

### Modelo: `monthly_reports`

| Campo | Tipo | Descripcion |
|---|---|---|
| `monthly_report_id` | UUID PK | |
| `club_enrollment_id` | FK → `club_enrollments` | |
| `month` | Int (1-12) | |
| `year` | Int | |
| `status` | ENUM: `draft`, `generated`, `submitted` | |
| `generated_at` | Timestamp? | |
| `submitted_at` | Timestamp? | |
| `submitted_by` | FK → `users`? | |
| `created_at` / `modified_at` | Timestamps | |

**Constraint unico**: (`club_enrollment_id`, `month`, `year`)

### Modelo: `monthly_report_manual_data`

| Campo | Tipo | Descripcion |
|---|---|---|
| `manual_data_id` | UUID PK | |
| `monthly_report_id` | FK | |
| `planning_meetings` | Int | Juntas de planeacion y evaluacion |
| `parent_meetings` | Int | Juntas con padres |
| `youth_council_attendance` | Int | Concilios Ministerio Juvenil del director |
| `church_board_attendance` | Int | Juntas directivas iglesia del director |
| `soul_target` | Int | Blanco de almas |
| `unbaptized_members` | Int | Miembros no bautizados |
| `bible_studies_receiving` | Int | Recibiendo estudios biblicos |
| `has_weekly_bible_instruction` | Boolean | Instruccion biblica semanal |
| `bible_studies_given` | Boolean | Estudios dados por miembros |
| `literature_distributed` | Boolean | Literatura distribuida |
| `baptized_this_month` | Int | Bautizados en el mes |
| `total_baptized` | Int | Total acumulado |
| `club_participation_description` | Text? | Descripcion participacion |
| `community_service_description` | Text? | Servicio iglesia/comunidad |
| `certificates_delivered` | Boolean | Se entregaron certificados |
| `members_have_booklet` | Boolean | Miembros tienen cuadernillo |
| `booklet_requirements_signed` | Boolean | Se firmaron requisitos |

### Flujo

1. Secretario puede ver vista previa en cualquier momento (datos auto-calculados en tiempo real).
2. Secretario completa campos manuales.
3. Al "generar" → se congela snapshot de datos automaticos → `generated`.
4. Secretario revisa y envia → `submitted`.
5. Campo local consulta y descarga PDF.

### Autogeneracion

- Cron job el dia 5 de cada mes (configurable via `system_config`).
- Genera automaticamente el reporte del mes anterior si no existe.
- Configurable: dia del mes y habilitado/deshabilitado.

### Generacion PDF

Backend genera PDF con el formato del informe mensual oficial usando datos congelados + manuales.

---

## Fase 7: Cambio de Club + Asignacion de Cargos con Autorizacion

### 7a. Solicitud de Cambio de Club

Para miembros Guia Mayor que cambian de seccion.

#### Modelo: `club_transfer_requests`

| Campo | Tipo | Descripcion |
|---|---|---|
| `transfer_request_id` | UUID PK | |
| `user_id` | FK → `users` | Miembro solicitante |
| `from_section_id` | FK → `club_sections` | Seccion actual |
| `to_section_id` | FK → `club_sections` | Seccion destino |
| `reason` | Text? | Motivo |
| `status` | ENUM: `pending`, `approved`, `rejected` | |
| `reviewed_by` | FK → `users`? | Director que aprobo/rechazo |
| `review_comment` | String? | |
| `reviewed_at` | Timestamp? | |
| `created_at` / `modified_at` | Timestamps | |

**Flujo**: Miembro solicita → Director de seccion aprueba → sistema mueve automaticamente.

### 7b. Asignacion de Cargos con Autorizacion

Cuando `assistant-lf` asigna roles desde campo local, requiere autorizacion.

#### Modelo: `role_assignment_requests`

| Campo | Tipo | Descripcion |
|---|---|---|
| `request_id` | UUID PK | |
| `club_section_id` | FK → `club_sections` | |
| `user_id` | FK → `users` | A quien se asigna |
| `role_id` | FK → `roles` | Que rol |
| `requested_by` | FK → `users` | `assistant-lf` |
| `status` | ENUM: `pending`, `approved`, `rejected` | |
| `approved_by` | FK → `users`? | `director-lf` |
| `comment` | String? | |
| `reviewed_at` | Timestamp? | |
| `created_at` / `modified_at` | Timestamps | |

**Flujo**: `assistant-lf` solicita → `director-lf` aprueba → se ejecuta `club_role_assignment`.

**Nota**: El director de seccion puede asignar/quitar roles directamente SIN este flujo de aprobacion (ya existe via `club_roles:assign/revoke`). Este modelo es solo para asignaciones que vienen desde campo local.

---

## Configuracion Global del Sistema

### Modelo: `system_config`

| Campo | Tipo | Descripcion |
|---|---|---|
| `config_key` | String PK | Clave unica |
| `config_value` | String | Valor (se parsea segun tipo) |
| `description` | String | Descripcion legible |
| `config_type` | ENUM: `int`, `boolean`, `string` | Tipo para parseo |
| `updated_at` | Timestamp | |

### Valores iniciales

| Key | Default | Fase |
|---|---|---|
| `investiture.min_approval_percentage` | `80` | F2 |
| `investiture.min_monthly_reports` | `10` | F6 |
| `reports.auto_generate_day` | `5` | F6 |
| `reports.auto_generate_enabled` | `true` | F6 |

---

## Resumen de Modelos

| Fase | Modelos nuevos | Modelos modificados |
|---|---|---|
| 1 | `club_enrollments`, `role_slot_limits` | — |
| 2 | `validation_logs` | `users_classes`, `users_honors` (+`validation_status`) |
| 3 | — (reusar `investiture_validation_history`) | Agregar estados multi-nivel |
| 4 | `camporee_payments` | `camporee_clubs` (activar) |
| 5 | `annual_folders`, `folder_templates`, `folder_template_sections`, `annual_folder_evidences` | — |
| 6 | `monthly_reports`, `monthly_report_manual_data` | — |
| 7 | `club_transfer_requests`, `role_assignment_requests` | — |
| — | `system_config` | — |

**Total**: ~13 modelos nuevos, ~3 modificados, 1 tabla de configuracion.
