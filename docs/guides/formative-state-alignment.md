# Formative State Alignment

**Estado**: ACTIVE

Lectura previa obligatoria:

- `docs/canon/dominio-sacdia.md`
- `docs/canon/runtime-sacdia.md`
- `docs/canon/decisiones-clave.md`

## Proposito

Este documento alinea el estado formativo de clases con el canon vigente y con el schema runtime actual.

Es un documento subordinado al canon. No redefine el dominio ni el runtime; traduce la decision canonica a reglas operativas para nuevas implementaciones.

## Estado runtime vigente

El runtime actual usa una unica fuente de verdad formativa:

- `enrollments`

La tabla legacy `users_classes` y su archivo historico `users_classes_archive` fueron retirados del schema runtime actual. No deben usarse como fuente operativa, historica ni transicional en nuevas implementaciones.

## Modelo objetivo actual

- `enrollments` representa el cursado anual operativo de una clase dentro de un año eclesiastico.
- La trayectoria historica consolidada se consulta desde `enrollments` usando año eclesiastico, clase, estado de investidura/progreso y filtros historicos.
- `class_module_progress` y `class_section_progress` proyectan avance sobre el `enrollment` correspondiente.
- Post-registro, cambios de club y transferencias deben resolver la clase operacional desde `enrollments`, no desde tablas legacy.

## Reglas de post-registro y transferencia

La clase no es una decision libre del cliente.

El backend debe derivar la clase esperada usando:

1. `users.birthday`;
2. fecha de inicio del año eclesiastico activo;
3. `club_type_id` de la seccion seleccionada o destino;
4. `classes.minimum_age`;
5. ventana de disponibilidad de la clase, si existe.

Si el cliente envia `class_id`, solo funciona como confirmacion. Si no coincide con la clase derivada, el backend debe rechazar la operacion con `POST_REG_CLASS_NOT_ELIGIBLE`.

## Puntos de desalineacion cerrados

- Post-registro ya no debe escribir ni leer `users_classes`.
- La seleccion manual de clase en cliente no debe permitir saltarse la regla de edad.
- La transferencia aprobada debe recalcular/reactivar el `enrollment` del año activo para el tipo de club destino.
- Documentos que digan que `users_classes` es trayectoria consolidada vigente estan obsoletos frente al canon y deben actualizarse o moverse a `docs/history/`.

## Cambios backend requeridos para nuevas features

- Leer clase actual desde `enrollments` activos del año eclesiastico correspondiente.
- Leer historial desde `enrollments`, no desde `users_classes`.
- Mantener idempotencia al crear/reactivar enrollments por la llave `user_id + class_id + ecclesiastical_year_id`.
- Desactivar otras inscripciones **regulares** activas del mismo usuario/año cuando se resuelve una nueva clase operacional. No desactivar el slot cruzado (`cross_type_enrollment = true`) de un Guía Mayor investido.
- Rechazar clases que no correspondan por edad, tipo de club o ventana de disponibilidad.

## Cambios admin requeridos para nuevas features

- Distinguir explicitamente entre clase operacional actual e historial de enrollments.
- No mostrar ni consultar `users_classes`.
- No permitir acciones administrativas que creen una clase operacional incompatible con la edad/año/tipo de club.

## Cambios mobile requeridos para nuevas features

- Tratar la clase del post-registro como asignacion automatica del backend.
- Enviar `class_id` solo si el flujo necesita confirmacion explicita; debe ser opcional.
- No bloquear el avance por falta de seleccion manual de clase.
- Mostrar copy de ayuda si se necesita explicar que la clase se asigna por edad.

## Criterio de cierre

Este alineamiento se considera vigente mientras:

- el ciclo anual operativo viva en `enrollments`;
- el historial se consulte desde `enrollments`;
- post-registro y transferencias deriven la clase por edad/tipo de club;
- no queden docs activas que presenten `users_classes` como tabla runtime.
