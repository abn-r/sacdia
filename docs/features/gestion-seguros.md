# Gestion de Seguros (Insurance)
Estado: SIN CANON

## Que existe (verificado contra codigo)
- **Backend**: No hay modulo backend dedicado. No existe InsuranceModule en backend-audit. La tabla member_insurances existe en schema.prisma con enum insurance_type_enum (GENERAL_ACTIVITIES, CAMPOREE, HIGH_RISK).
- **Admin**: Placeholder — modulo planificado. No consume endpoints.
- **App**: 3 screens (InsuranceView, InsuranceDetailView, InsuranceFormSheet). Consume 4 endpoints: GET members/insurance listing, GET user insurance detail, POST create insurance, PATCH update insurance. Todos estos endpoints son FANTASMA (no aparecen en backend audit).
- **DB**: member_insurances (con relacion a users y camporee_members)

## Que define el canon
- Canon no define este dominio explicitamente

## Gap
- App tiene screens completas con datasource pero los endpoints que consume no existen en el backend
- No hay modulo backend — solo la tabla member_insurances existe en el schema
- Canon no menciona seguros como capacidad del sistema

## Prioridad
- A definir por el desarrollador
