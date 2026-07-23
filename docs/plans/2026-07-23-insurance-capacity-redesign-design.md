# Diseño: Rediseño de seguros por compras, cupos y asignaciones

**Estado**: DRAFT aprobado como dirección de producto  
**Fecha**: 2026-07-23  
**Alcance**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`, ranking anual y documentación canónica  
**Reemplaza conceptualmente**: el modelo centrado únicamente en `member_insurances`

## 1. Problema

El runtime actual crea un registro de seguro directamente para un usuario. Ese
modelo no representa la operación real:

1. Cada sección compra una cantidad de seguros en una plataforma externa.
2. El Campo Local confirma y administra esas compras.
3. Los seguros comprados se convierten en cupos disponibles.
4. Los cupos pueden asignarse después a miembros.
5. Los cupos libres pueden transferirse entre secciones del mismo club.
6. Campamentos y camporees pueden requerir seguros para miembros o personal
   externo que no tiene cuenta en SACDIA.
7. Cada asignación debe conservar el comprobante individual emitido por la
   plataforma externa.

El modelo actual tampoco conserva un libro completo de compras, traspasos,
liberaciones y reasignaciones, y confunde `active=true` con vigencia real.

## 2. Objetivos

- Registrar y controlar compras confirmadas en la plataforma externa.
- Mantener la plataforma externa como autoridad de emisión y pago.
- Representar cada seguro comprado como un cupo individual trazable.
- Conservar propiedad económica, custodia actual y uso de cada cupo.
- Mantener historial inmutable por sección.
- Soportar miembros SACDIA y personal externo único por evento.
- Configurar costo, vigencia y fecha límite por Campo Local.
- Integrar compras extraordinarias al ranking anual de forma proporcional.
- Preservar comprobantes, actores, motivos y fechas de cada transición.

## 3. Fuera de alcance

- Vender seguros o procesar pagos dentro de SACDIA.
- Sustituir o sincronizar automáticamente la plataforma externa.
- Crear cuentas de usuario para personal externo.
- Compartir seguros entre clubes.
- Modificar retroactivamente compras o asignaciones confirmadas.
- Rediseñar visualmente el panel administrativo dentro de este trabajo.

## 4. Reglas de negocio aprobadas

### 4.1 Propiedad y compras

- Cada compra pertenece a una sola sección.
- Compras sucesivas se acumulan únicamente dentro de la misma sección.
- La sección que pagó conserva permanentemente la atribución económica y de
  ranking.
- El Campo Local es el único actor que confirma o rechaza una compra.
- La fecha del comprobante externo determina si la compra fue ordinaria o
  extraordinaria.

Ejemplo:

```text
Aventureros:    30
Conquistadores: 20 + 10 = 30
Guías Mayores:  15
```

Los totales anteriores no se mezclan para el ranking.

### 4.2 Transferencias

- Solo pueden transferirse cupos libres.
- El origen y destino deben pertenecer al mismo club principal.
- El traspaso cambia la sección custodio, pero no la sección compradora.
- El ranking permanece atribuido a la sección que pagó.
- Debe existir historial de origen, destino, cantidad, responsable, motivo y
  fecha.

### 4.3 Asignaciones y reasignaciones

- Un cupo puede asignarse a un miembro SACDIA o a una persona externa del
  evento.
- Cada asignación requiere un comprobante individual.
- Solo el Campo Local puede confirmar el comprobante.
- Una reasignación de un seguro ocupado es extraordinaria y solo puede
  ejecutarla el Campo Local.
- La reasignación se permite cuando el miembro deja de asistir o causa baja
  permanente.
- La asignación anterior se cierra; nunca se cambia su `user_id`.
- La persona receptora requiere un comprobante nuevo.

### 4.4 Vigencia

- El seguro general usa una vigencia configurable, inicialmente 12 meses.
- El seguro de evento cubre las fechas del campamento o camporee.
- Las reglas se configuran en SACDIA, pero cada compra y asignación conserva un
  snapshot de las reglas aplicadas.
- Cambiar una configuración futura no altera registros históricos.

### 4.5 Personal externo

- El personal externo es un registro único por evento.
- No crea una cuenta ni un perfil global reutilizable.
- Se conserva históricamente con su función: apoyo, invitado, personal extra u
  otra categoría configurada.
- Solo deben almacenarse los datos mínimos necesarios para identificación,
  seguro y auditoría.

## 5. Alternativas evaluadas

### A. Cupos individuales trazables — seleccionada

Cada compra confirmada genera N cupos. Cada cupo tiene identidad propia,
propiedad inmutable, custodio actual, estado e historial.

**Ventajas**:

- trazabilidad directa;
- transferencias y asignaciones simples;
- evita sobreasignación;
- facilita auditoría y explicación al usuario.

**Costo**: más filas, sin impacto relevante para el volumen esperado de SACDIA.

### B. Lotes y contadores

Mantener compras agregadas y derivar saldos con cantidades.

**Ventaja**: menos filas.

**Desventajas**: concurrencia, asignación parcial, reasignación y procedencia son
considerablemente más difíciles de explicar y verificar.

### C. Extender `member_insurances`

Agregar campos de compra y sección a la tabla actual.

**Desventaja decisiva**: continúa mezclando compra, capacidad, persona,
comprobante y vigencia. No cubre adecuadamente personal externo ni traspasos.

## 6. Arquitectura de dominio

```text
Producto configurable
  └── Configuración de ciclo por Campo/año/tipo de sección
        └── Compra de una sección
              └── Cupos individuales
                    ├── movimientos de custodia
                    └── asignaciones históricas
                          ├── miembro SACDIA
                          └── participante externo del evento
```

### 6.1 `insurance_products`

Catálogo administrado por Campo Local.

Campos lógicos:

- `insurance_product_id`
- `local_field_id`
- `name`
- `coverage_scope`: `GENERAL` | `EVENT`
- `validity_mode`: `FIXED_MONTHS` | `EVENT_DATES`
- `default_duration_months`
- `active`
- auditoría

No se usa un enum cerrado para los productos visibles. Los enums solo expresan
comportamiento técnico.

### 6.2 `insurance_cycle_configs`

Configuración efectiva para un ciclo:

- `insurance_cycle_config_id`
- `insurance_product_id`
- `local_field_id`
- `ecclesiastical_year_id`
- `club_type_id`
- `unit_cost`
- `purchase_deadline`
- `timezone`
- `active`
- auditoría

Unicidad:

```text
insurance_product_id
+ local_field_id
+ ecclesiastical_year_id
+ club_type_id
```

### 6.3 `insurance_purchases`

Representa una operación confirmable de la plataforma externa:

- `insurance_purchase_id`
- `insurance_cycle_config_id`
- `owner_club_id`
- `purchasing_section_id`
- `quantity`
- `unit_cost_snapshot`
- `total_amount`
- `external_reference`
- `receipt_date`
- `applied_deadline`
- `classification`: `ORDINARY` | `EXTRAORDINARY` | `LEGACY_UNCLASSIFIED`
- `status`: `PENDING_CONFIRMATION` | `CONFIRMED` | `REJECTED` | `REVERSED`
- `submitted_by_id`
- `reviewed_by_id`
- `reviewed_at`
- `rejection_reason`
- auditoría

`owner_club_id`, `purchasing_section_id`, `receipt_date`,
`applied_deadline` y `classification` son inmutables después de confirmar.

### 6.4 `insurance_coverage_slots`

Una fila por cupo comprado:

- `insurance_coverage_slot_id`
- `insurance_purchase_id`
- `sequence_number`
- `owner_club_id` — inmutable
- `purchasing_section_id` — inmutable
- `current_section_id` — cambia por traspaso
- `status`: `AVAILABLE` | `ASSIGNED` | `VOID`
- auditoría

Restricciones:

- `current_section_id` debe pertenecer a `owner_club_id`;
- solo compras `CONFIRMED` generan cupos;
- una compra genera exactamente `quantity` cupos;
- un cupo no puede tener más de una asignación activa.

### 6.5 `insurance_slot_movements`

Libro inmutable de movimientos:

- `insurance_slot_movement_id`
- `insurance_coverage_slot_id`
- `movement_type`
- `from_section_id`
- `to_section_id`
- `assignment_id`
- `reason`
- `performed_by_id`
- `created_at`
- `correlation_id` para agrupar transferencias múltiples

Tipos iniciales:

```text
PURCHASE_CONFIRMED
TRANSFERRED
ASSIGNED
RELEASED
REASSIGNED
VOIDED
CORRECTED
```

No se actualizan ni eliminan movimientos. Una corrección genera otro movimiento.

### 6.6 `insurance_assignments`

Historial de utilización de un cupo:

- `insurance_assignment_id`
- `insurance_coverage_slot_id`
- `subject_type`: `MEMBER` | `EVENT_EXTERNAL`
- `user_id` nullable
- `event_external_participant_id` nullable
- `valid_from`
- `valid_until`
- `status`: `PENDING_CONFIRMATION` | `ACTIVE` | `REJECTED` | `RELEASED` | `EXPIRED`
- `release_reason`
- `assigned_by_id`
- `confirmed_by_id`
- `confirmed_at`
- auditoría

Debe cumplirse exactamente una referencia de sujeto:

```text
MEMBER         → user_id requerido
EVENT_EXTERNAL → event_external_participant_id requerido
```

### 6.7 `insurance_evidence_files`

Evidencias de compra y comprobantes individuales:

- `insurance_evidence_file_id`
- `insurance_purchase_id` nullable
- `insurance_assignment_id` nullable
- `evidence_type`: `PURCHASE_PROOF` | `INDIVIDUAL_RECEIPT`
- `file_key`
- `file_name`
- `mime_type`
- `file_size`
- `external_reference`
- `receipt_date`
- `uploaded_by_id`
- auditoría

Debe pertenecer a una compra o a una asignación, nunca a ambas.

Los archivos permanecen privados en R2 y se entregan mediante URL firmada.

### 6.8 `camporee_external_participants`

Personal no registrado en SACDIA:

- `camporee_external_participant_id`
- `local_camporee_id` nullable
- `union_camporee_id` nullable
- `full_name`
- datos mínimos de identificación aprobados
- `role_type`
- `role_description`
- `active`
- auditoría

Debe referenciar exactamente un camporee local o de Unión.

## 7. Máquinas de estado

### 7.1 Compra

```text
PENDING_CONFIRMATION
  ├── CONFIRMED ──> REVERSED
  └── REJECTED
```

Confirmar crea los cupos en una sola transacción. Rechazar no crea capacidad.

### 7.2 Asignación

```text
PENDING_CONFIRMATION
  ├── ACTIVE ──> EXPIRED
  │          └─> RELEASED
  └── REJECTED
```

Solo el Campo Local activa una asignación después de verificar el comprobante
individual.

### 7.3 Reasignación extraordinaria

```text
ACTIVE anterior
  └── RELEASED con motivo y actor
        └── cupo AVAILABLE
              └── nueva asignación PENDING_CONFIRMATION
                    └── nuevo comprobante
                          └── ACTIVE
```

El proceso debe ser transaccional donde corresponda, pero conserva dos
asignaciones históricas.

## 8. Fecha límite y ranking anual

### 8.1 Clasificación

Al confirmar una compra:

```text
receipt_date <= purchase_deadline → ORDINARY
receipt_date >  purchase_deadline → EXTRAORDINARY
```

La comparación usa fecha de calendario en la zona configurada. El día límite es
inclusivo.

### 8.2 Componente

Nuevo componente administrativo:

```text
insurance_purchase_timeliness
```

Fórmula aprobada por sección:

```text
ordinary_quantity = SUM(quantity de compras CONFIRMED + ORDINARY)
extraordinary_quantity = SUM(quantity de compras CONFIRMED + EXTRAORDINARY)
total_quantity = ordinary_quantity + extraordinary_quantity

score_pct =
  total_quantity == 0
    ? 0
    : ordinary_quantity / total_quantity * 100
```

Conversión existente del ranking:

```text
earned_points = ROUND(score_pct / 100 * component.max_points)
```

Ejemplo:

```text
20 ordinarios + 10 extraordinarios = 30
score_pct = 20 / 30 = 66.67%

Componente de 300 puntos:
earned_points = 200
```

Los traspasos no modifican la fórmula ni la sección a la que se atribuye la
compra.

### 8.3 Integración

El componente se agrega al eje `administrative` del ranking configurable. El
calculador se registra en:

`sacdia-backend/src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.ts`

No se restan puntos arbitrarios después del cálculo final.

## 9. API propuesta

### 9.1 Configuración

```text
GET    /api/v1/insurance/products
POST   /api/v1/insurance/products
PATCH  /api/v1/insurance/products/:productId

GET    /api/v1/insurance/cycles
POST   /api/v1/insurance/cycles
PATCH  /api/v1/insurance/cycles/:cycleId
```

### 9.2 Compras

```text
POST   /api/v1/club-sections/:sectionId/insurance/purchases
GET    /api/v1/club-sections/:sectionId/insurance/purchases
GET    /api/v1/insurance/purchases/:purchaseId
POST   /api/v1/insurance/purchases/:purchaseId/confirm
POST   /api/v1/insurance/purchases/:purchaseId/reject
POST   /api/v1/insurance/purchases/:purchaseId/reverse
```

### 9.3 Cupos y movimientos

```text
GET    /api/v1/club-sections/:sectionId/insurance/balance
GET    /api/v1/club-sections/:sectionId/insurance/movements
POST   /api/v1/insurance/transfers
GET    /api/v1/insurance/transfers/:correlationId
```

### 9.4 Asignaciones

```text
POST   /api/v1/insurance/slots/:slotId/assignments
POST   /api/v1/insurance/assignments/:assignmentId/confirm
POST   /api/v1/insurance/assignments/:assignmentId/reject
POST   /api/v1/insurance/assignments/:assignmentId/release
GET    /api/v1/users/:userId/insurance-history
```

### 9.5 Personal externo

```text
POST   /api/v1/camporees/:camporeeId/external-participants
GET    /api/v1/camporees/:camporeeId/external-participants
PATCH  /api/v1/camporees/:camporeeId/external-participants/:participantId
```

Las rutas de camporee de Unión deben mantener su superficie equivalente.

## 10. Autorización

### Sección

- consultar saldo e historial propios;
- registrar solicitudes de compra;
- proponer asignaciones usando cupos bajo su custodia;
- consultar comprobantes autorizados dentro de su alcance.

### Campo Local

- administrar productos y ciclos;
- confirmar, rechazar o revertir compras;
- confirmar o rechazar comprobantes individuales;
- ejecutar transferencias;
- ejecutar liberaciones y reasignaciones extraordinarias;
- consultar todas las secciones bajo su jurisdicción.

### Invariantes de seguridad

- permisos globales no sustituyen validación de territorio;
- toda mutación valida sección, club y Campo Local efectivo;
- archivos privados se exponen solo con URL firmada de corta duración;
- las respuestas nunca incluyen documentos personales innecesarios;
- toda operación sensible registra actor y contexto institucional.

## 11. Concurrencia e integridad

- Confirmar una compra y crear sus cupos ocurre en una transacción.
- Asignar un cupo bloquea o condiciona el registro para impedir doble uso.
- Una constraint parcial garantiza como máximo una asignación activa por cupo.
- Una transferencia valida todos los cupos antes de mover cualquiera.
- Si un cupo falla, la transferencia completa se revierte.
- Los saldos se derivan de cupos y movimientos; no existe un contador editable.

## 12. Migración desde `member_insurances`

No se debe inventar procedencia que el modelo actual no guarda.

Estrategia:

1. Crear el nuevo modelo en paralelo.
2. Mantener `member_insurances` temporalmente en lectura.
3. Auditar cada registro legacy y resolver sección/año cuando exista evidencia.
4. Importar registros confiables como compra/cupo/asignación
   `LEGACY_UNCLASSIFIED`.
5. Excluir `LEGACY_UNCLASSIFIED` del componente de puntualidad.
6. Conservar sin mutación los registros ambiguos para consulta histórica.
7. Cambiar escrituras al modelo nuevo.
8. Retirar el contrato legacy solo después de verificar backend, admin y app.

No se hará una migración destructiva automática.

## 13. Clientes

### Admin

El panel debe ofrecer:

- bandeja de compras pendientes para Campo Local;
- historial por sección;
- saldo comprado, recibido, transferido, asignado y libre;
- confirmación/rechazo con evidencia;
- traspaso de cupos libres;
- reasignación extraordinaria;
- configuración de productos, costos y fechas límite;
- historial de personal externo por evento;
- desglose del componente de ranking.

La composición visual corresponde al ownership de Cursor Composer. Codex define
y valida contratos, estados, permisos y criterios de aceptación.

### App móvil

- consultar seguro vigente e historial propio autorizado;
- mostrar evidencia mediante URL firmada;
- consumir la asignación válida al registrar un miembro en camporee;
- permitir a roles de sección registrar solicitudes/asignaciones cuando sus
  permisos lo autoricen;
- no administrar confirmaciones exclusivas de Campo Local.

## 14. Riesgos y controles

| Riesgo | Control |
|---|---|
| Sobreasignación | transacciones + unicidad de asignación activa |
| Transferencia fuera del club | `owner_club_id` inmutable + validación |
| Manipulación de fecha | usar fecha del comprobante y conservar evidencia |
| Cambio retroactivo de deadline | snapshot en la compra confirmada |
| Pérdida de procedencia | sección compradora inmutable |
| Evidencia privada expuesta | R2 privado + URL firmada |
| Migración inventa datos | `LEGACY_UNCLASSIFIED` + auditoría previa |
| Perfil externo reutilizado por error | registro ligado a un único evento |
| Ranking opaco | desglose ordinario/extraordinario y fórmula visible |

## 15. Criterios de aceptación

- Una compra confirmada genera exactamente la cantidad declarada de cupos.
- Una compra rechazada no genera cupos.
- El Campo Local es el único que confirma comprobantes.
- Cada sección puede consultar su historial completo.
- Los cupos libres pueden moverse solo dentro del mismo club.
- La sección compradora y la atribución de ranking nunca cambian.
- No puede existir más de una asignación activa por cupo.
- Una reasignación conserva ambas asignaciones y exige comprobante nuevo.
- El personal externo pertenece a un solo evento y queda en su historial.
- El seguro general y de evento usan vigencias configurables.
- Las compras extraordinarias producen el porcentaje proporcional aprobado.
- El ranking muestra el componente y su desglose.
- Los archivos de evidencia se sirven mediante URL firmada.
- El contrato legacy permanece compatible durante la transición.
