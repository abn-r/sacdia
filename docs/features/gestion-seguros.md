# Gestion de Seguros (Insurance)
Estado: EN BACKEND

## Que existe (verificado contra codigo)
- **Backend**: Ya existe `InsuranceModule` con endpoints runtime para listado por sección, detalle por miembro, creación multipart y actualización multipart. La tabla `member_insurances` existe en `schema.prisma` con enum `insurance_type_enum` (GENERAL_ACTIVITIES, CAMPOREE, HIGH_RISK) y campos de evidencia/auditoría.
- **Admin**: Placeholder — modulo planificado. No consume endpoints.
- **App**: 3 screens (InsuranceView, InsuranceDetailView, InsuranceFormSheet). Consume 4 endpoints ahora disponibles en backend:
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/members/insurance`
  - `GET /api/v1/users/:memberId/insurance`
  - `POST /api/v1/users/:memberId/insurance`
  - `PATCH /api/v1/insurance/:insuranceId`
- **DB**: `member_insurances` con relación a `users`, `camporee_members` y auditoría (`created_by_id`, `modified_by_id`).

## Que define el canon
- El seguro institucional es parte de la trayectoria del miembro (`docs/canon/dominio-sacdia.md`): documenta la cobertura de seguros vinculada a la participacion institucional
- Los seguros forman parte de la dimension administrativa de la trayectoria

## Gap
- App tiene screens completas con datasource pero los endpoints que consume no existen en el backend — pendiente de implementacion
- El módulo backend vive en `src/insurance/` y usa evidencia multipart opcional en el campo `evidence`.
- La evidencia se guarda en R2 con el bucket `INSURANCE_EVIDENCE`.
- El contrato móvil espera `evidence_file_url` y `evidence_file_name`, ya reflejados en backend.

## Prioridad
- Media — canon reconocido, backend pendiente de implementacion
