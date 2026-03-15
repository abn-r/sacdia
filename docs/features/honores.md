# Honores (Especialidades)
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: HonorsModule — 12 endpoints. Catalogo: list, categories, grouped-by-category, detail (OptionalJwtAuthGuard). User honors: list, stats, register, bulk register, file upload, start, update progress, abandon (OwnerOrAdminGuard). Controllers: HonorsController, UserHonorsController.
- **Admin**: 2 pages funcionales (honors list con CRUD, honors/[honorId] detail). Consume GET /honors, GET /honors/categories, GET /catalogs/club-types, POST /honors, PATCH /honors/:id. CRUD de categorias de especialidades en catalogs/honor-categories (5 endpoints FANTASMA — no en backend audit).
- **App**: 4 screens (HonorsCatalogView, HonorDetailView, MyHonorsView, AddHonorView). Consume 10 endpoints incluyendo catalogo, categorias, grouped-by-category, user honors CRUD con progreso y evidencias.
- **DB**: honors, honors_categories, master_honors, users_honors

## Que define el canon
- Canon menciona honores como parte del proceso formativo (formacion)
- No hay definicion canon detallada del modelo de honores mas alla de su rol en la trayectoria formativa

## Gap
- Admin consume CRUD completo de /admin/honor-categories que son endpoints FANTASMA (no existen en backend audit) — pendiente de implementacion en backend
- 3 endpoints de user honors sin documentacion API (POST bulk, POST files, POST register)
- GET /honors/grouped-by-category existe en backend pero sin documentacion API

## Prioridad
- Alta para honor-categories CRUD — admin depende de endpoints que no existen en backend
