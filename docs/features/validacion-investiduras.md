# Validacion de Investiduras
Estado: FANTASMA

## Que existe (verificado contra codigo)
- **Backend**: No hay modulo backend dedicado. No hay endpoints de validacion ni investidura.
- **Admin**: No implementado. No hay pages de validacion.
- **App**: No implementado. No hay screens de validacion.
- **DB**: investiture_validation_history, investiture_config, enrollments (con investiture_status_enum: IN_PROGRESS, SUBMITTED_FOR_VALIDATION, APPROVED, REJECTED, INVESTIDO). Tambien existe investiture_action_enum (SUBMITTED, APPROVED, REJECTED, REINVESTITURE_REQUESTED) y evidence_validation_enum (PENDING, VALIDATED, REJECTED).

## Que define el canon
- Canon define validacion como acto institucional mediante el cual un registro recibe reconocimiento formal (dominio-sacdia.md)
- Canon define investidura como acto institucional de reconocimiento asociado al cierre exitoso de una etapa
- Decision 6: registrar y validar son actos distintos — el canon separa captura operativa, revision y validacion
- Canon define efectos de validacion: al entrar en validacion, el registro deja de ser editable y pasa a revision institucional

## Gap
- Tablas y enums existen en schema pero no hay ningun runtime que los exponga (cero endpoints, cero pages, cero screens)
- Canon define este dominio como pieza central de la trayectoria institucional pero no hay implementacion visible
- Gap critico: el sistema puede registrar avance formativo pero no puede validarlo ni investir institucionalmente

## Prioridad
- A definir por el desarrollador
