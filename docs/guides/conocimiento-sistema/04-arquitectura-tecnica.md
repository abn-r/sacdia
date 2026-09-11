# Arquitectura técnica de SACDIA

**Corte:** 2026-09-10 · **Estado:** entrega parcial, 2 de 4 diagramas validados.

Estos mapas describen la organización lógica observada en el código local, no
una topología de producción certificada. No se inspeccionaron secretos ni cuentas,
no se ejecutaron builds y no se modificó comportamiento del producto.

## Diagramas

| Vista | Artefacto | Estado |
|---|---|---|
| General | [Fuente editable](diagramas/03-arquitectura-general.architecture.json) | Borrador: etiqueta cruza una conexión; sin HTML entregado |
| Backend | [Abrir diagrama](diagramas/04-arquitectura-backend.html) | Validado y revisado visualmente |
| App móvil | [Abrir diagrama](diagramas/05-arquitectura-app.html) | Validado y revisado visualmente |
| Panel | [Fuente editable](diagramas/06-arquitectura-panel.architecture.json) | Borrador: coordenadas de ruta no perpendiculares; sin HTML entregado |

Los HTML son autónomos. Contenido en español; controles fijos y atributo de idioma
del visor usan el fallback inglés de Archify. En el mapa móvil, la categoría
visual «Backend» identifica lógica interna: dominio, datos y Dio **ejecutan dentro
de la app**, no son servidores independientes.

## 1. Vista general

Dos clientes —Flutter y Next.js— consumen una API NestJS. El backend centraliza
reglas, autorización y persistencia PostgreSQL mediante Prisma y el adaptador pg.
El código contiene integración R2 para archivos, FCM para notificaciones y Resend
para correo. La existencia de esos adaptadores no prueba su disponibilidad real.

Redis participa en caché y colas. BullMQ se registra condicionalmente; el caché
compartido exige Redis en producción. Pino y Sentry cubren aspectos de
observabilidad, con activación/configuración según el componente.

Fuentes: [AppModule](../../../sacdia-backend/src/app.module.ts),
[CommonModule](../../../sacdia-backend/src/common/common.module.ts),
[PrismaService](../../../sacdia-backend/src/prisma/prisma.service.ts).

## 2. Backend: monolito modular

Lectura principal: entrada y guards → controllers/DTOs → servicios de dominio →
PrismaService → PostgreSQL. Las flechas muestran colaboración lógica resumida,
no el orden exhaustivo del pipeline Nest ni todos los caminos de cada endpoint.
Las conexiones sin etiqueta en esa cadena representan invocación ordinaria entre
capas, ya expresada por sus nombres.

AppModule integra módulos por dominio; no hay evidencia en ese archivo de un
microservicio independiente por módulo. Auth integra Better Auth. ScheduleModule
y los processors atienden trabajo programado/asíncrono; no se infiere por ello
un despliegue separado de workers. «Límites» en la entrada resume rate limiting.

Fuentes: [arranque](../../../sacdia-backend/src/main.ts),
[registro BullMQ](../../../sacdia-backend/src/config/bullmq.config.ts),
[política de caché](../../../sacdia-backend/src/config/cache.config.ts),
[AuthModule](../../../sacdia-backend/src/auth/auth.module.ts).

## 3. App: funcionalidades y separación de responsabilidades

La estructura observada es `features/<dominio>/{presentation,domain,data}`.
Riverpod compone dependencias y estado; los casos de uso dependen de contratos
de repositorio. Actividades sirve como recorrido concreto, no como garantía de
que todas las funcionalidades tengan exactamente la misma implementación.

La flecha dominio → datos representa ejecución a través del contrato; **no**
una dependencia de importación del dominio sobre RepositoryImpl. La flecha
vistas → providers expresa el consumo de estado, sin protocolo externo adicional.

Dio centraliza HTTP e interceptores. Los tokens están en FlutterSecureStorage;
SharedPreferences y Hive cubren persistencia local selectiva. No se afirma un
modo offline completo. La invalidación silenciosa basada en FCM tiene
`REALTIME_INVALIDATION_ENABLED=false` como valor predeterminado, distinto de
afirmar que todo push esté desactivado.

Fuentes: [providers de actividades](../../../sacdia-app/lib/features/activities/presentation/providers/activities_providers.dart),
[caso de uso](../../../sacdia-app/lib/features/activities/domain/usecases/get_club_activities.dart),
[AppAuthService](../../../sacdia-app/lib/core/auth/app_auth_service.dart),
[Dio](../../../sacdia-app/lib/core/network/dio_client.dart),
[flag realtime](../../../sacdia-app/lib/core/realtime/feature_flags.dart).

## 4. Panel: acceso dual a la API

El panel Next.js tiene dos caminos: Axios desde el navegador hacia el backend,
y fetch desde el servidor Next. El cliente obtiene el JWT desde `/api/auth/token`
del mismo origen y lo conserva temporalmente en memoria. Aunque las cookies son
httpOnly, ese endpoint entrega el token al código JavaScript del navegador: no
corresponde describirlo como un BFF exclusivo ni como un token inaccesible a JS.

Los layouts y `proxy.ts` controlan navegación y acceso al dashboard; la
autorización de las operaciones permanece en el backend. Algunas rutas Next
actúan como proxy autenticado para PDFs. TanStack Query participa en consultas
cliente, y preferencias/idioma son responsabilidades diferentes de los datos
remotos. La flecha UI → consultas resume ese consumo de estado.

Fuentes: [cliente API](../../../sacdia-admin/src/lib/api/client.ts),
[relay de token](../../../sacdia-admin/src/app/api/auth/token/route.ts),
[cookies](../../../sacdia-admin/src/lib/auth/cookies.ts),
[layout](../../../sacdia-admin/src/app/(dashboard)/layout.tsx),
[proxy PDF](../../../sacdia-admin/src/app/api/evidence-review/pdf/route.ts).

## Evidencia y pendientes

Consultar [verificación técnica](evidencias/ARQUITECTURA-VERIFICACION.md) y
[corte de fuentes](evidencias/fuentes-arquitectura-2026-09-10.json).
El código prevalece sobre contextos antiguos que describían tokens en Hive o
un panel vacío. Esas descripciones no se usaron como arquitectura efectiva.

Pendiente inmediato: corregir y volver a validar el trazado del general y del
panel antes de generar sus HTML. Después, contrastar estos mapas con el entorno
que se mostrará a clientes; estas comprobaciones documentales no sustituyen
pruebas funcionales, de seguridad, capacidad ni disponibilidad.
