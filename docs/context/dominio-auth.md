# Dominio: Autenticación y autorización
## Estado
ACTIVE
## Objetivo
Definir cómo SACDIA identifica a un usuario, mantiene su acceso vigente y determina qué puede hacer según su alcance territorial y su contexto activo de club.
## Qué resuelve
Este dominio asegura que:
- solo ingresen usuarios autenticados válidos;
- cada acción protegida se evalúe con reglas consistentes;
- backend, admin y app compartan la misma semántica de acceso;
- el acceso de club dependa del contexto activo correcto y no de interpretaciones locales del cliente.
## Alcance
Este dominio incluye:
- identidad autenticable del usuario;
- inicio y cierre de sesión;
- refresh de sesión;
- OAuth con proveedores soportados;
- MFA/2FA;
- revocación y control operativo de sesiones;
- roles, permisos y autorización;
- contexto activo de club/instancia;
- consumo canónico del bloque `authorization`.
Este dominio no incluye:
- onboarding funcional completo del usuario;
- perfil extendido del miembro;
- gestión operativa de clubes, actividades o finanzas;
- catálogos de negocio, salvo los necesarios para resolver acceso.
## Actores
- usuario sin sesión;
- usuario autenticado;
- administradores y asistentes con alcance territorial;
- coordinadores con alcance territorial;
- miembros y cargos de club;
- servicios internos autorizados.
## Conceptos clave
- Usuario: identidad autenticable del sistema.
- Sesión: acceso vigente del usuario, emitido desde Supabase Auth y controlado operativamente por backend.
- Contexto activo: asignación de club e instancia seleccionada para la sesión actual.
- Rol global: responsabilidad con alcance territorial.
- Asignación de club: vínculo exacto entre usuario, rol, club, instancia y año eclesiástico.
- Permiso: capacidad concreta para ejecutar una acción.
- Autorización efectiva: permisos y scope ya resueltos por backend para la sesión actual.
## Reglas de negocio
- La autenticación prueba identidad; la autorización decide alcance y acciones permitidas.
- Ninguna acción protegida depende solo del frontend.
- El backend es la fuente de verdad de autorización por sesión.
- Un usuario puede tener múltiples grants, pero los permisos de club efectivos salen solo de la asignación activa.
- Los permisos globales y el alcance territorial pueden habilitar operaciones administrativas fuera de un club puntual.
- Los clientes deben consumir `authorization.effective.permissions` para gating de UX.
- Los campos legacy de autorización pueden existir temporalmente por compatibilidad, pero no son contrato nuevo.
- Si el usuario no tiene contexto suficiente para una acción, el acceso debe rechazarse explícitamente.
## Modelo actual del dominio
### Usuario
Representa la persona autenticable en SACDIA.
A nivel de negocio, el usuario puede:
- iniciar sesión con credenciales soportadas;
- tener roles globales;
- tener asignaciones de club;
- operar en más de un ámbito, pero con una sola asignación de club activa por sesión.
La identidad base está soportada por Supabase Auth y se relaciona con el registro de usuario del sistema.
### Sesión
La sesión es un concepto vigente del dominio.
En el estado actual:
- la autenticación base y los tokens dependen de Supabase Auth;
- el backend expone login, refresh, logout y `GET /auth/me`;
- existe control operativo adicional de sesiones para listar, cerrar sesiones remotas y limitar concurrencia;
- la revocación no depende solo de la expiración natural del token.
La sesión no se modela como tabla canónica propia en Prisma dentro de esta capa documental.
### Rol global
Representa responsabilidades administrativas o transversales con alcance territorial.
Su efecto depende de:
- el rol asignado;
- su scope territorial;
- las reglas de autorización del recurso solicitado.
### Asignación de club
Es la unidad canónica del acceso de club.
Una asignación vincula:
- usuario;
- rol;
- club;
- tipo de instancia;
- instancia específica;
- año eclesiástico;
- vigencia y estado.
Un usuario puede tener varias asignaciones, pero solo una puede estar activa en la sesión.
### Permiso
Es la capacidad concreta que el backend usa para autorizar acciones.
La convención vigente es `resource:action`.
Ejemplos:
- `users:read`
- `clubs:update`
- `club_roles:assign`
- `health:read`
## Autenticación vigente
El estado real vigente contempla:
- login con email y password;
- refresh con refresh token;
- logout best effort;
- OAuth con Google y Apple;
- MFA/2FA con TOTP;
- validación de JWT emitidos por Supabase.
## Autorización vigente
El estado real vigente es:
- RBAC con permisos granulares;
- resolución de autorización por backend;
- alcance territorial para grants globales;
- contexto activo exacto para permisos de club;
- consumo canónico del bloque `authorization` en `GET /auth/me`.
La autorización de club no se resuelve uniendo todas las asignaciones del usuario en cada request.
Solo aporta permisos de club la asignación activa.
## Contrato operativo que consumen los clientes
La sesión autenticada expone un bloque `authorization` con:
- `grants.global_roles`
- `grants.club_assignments`
- `active_assignment`
- `effective.permissions`
- `effective.scope`
Regla canónica:
- admin y app consumen autorización resuelta;
- no deben reconstruir RBAC desde campos legacy, metadata local o joins ad hoc.
## Estados relevantes
### Usuario
A nivel de negocio conviene reconocer al menos:
- habilitado para acceder;
- restringido o revocado;
- con acceso pendiente de completar procesos funcionales posteriores.
### Sesión
- activa;
- expirada;
- revocada;
- cerrada.
### Asignación de club
- pendiente;
- activa;
- inactiva;
- finalizada por vigencia o revocación.
## Casos borde
- usuario con varios grants globales;
- usuario con varias asignaciones de club;
- usuario con permiso global suficiente pero sin contexto de club activo;
- usuario con contexto activo inválido o vencido;
- token válido con sesión revocada;
- cambio de rol o asignación mientras la sesión sigue abierta;
- usuario autenticado con MFA habilitado;
- cierre remoto de sesiones por seguridad.
## Dependencias
Este dominio depende de:
- identidad y tokens provistos por Supabase Auth;
- catálogo de roles y permisos;
- modelo organizacional y territorial;
- modelo de asignaciones de club.
Dependen de este dominio:
- backend API;
- panel admin;
- app móvil;
- cualquier módulo protegido.
## Decisiones cerradas del estado actual
- La autenticación base usa Supabase Auth.
- OAuth soportado hoy: Google y Apple.
- MFA soportado hoy: TOTP.
- La autorización efectiva del cliente sale del bloque `authorization`.
- El acceso de club depende de la asignación activa de la sesión.
- Los campos legacy de autorización siguen solo como compatibilidad temporal.
- La validación final de acceso ocurre en backend.
## Riesgos a controlar
- mezclar autenticación con autorización;
- documentar como “futuro” algo que ya es runtime activo;
- permitir que clientes reconstruyan permisos por su cuenta;
- tratar todas las asignaciones de club como simultáneamente efectivas;
- sostener contratos paralelos entre docs de negocio, API y walkthroughs históricos.

## Referencias canónicas
- `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/01-FEATURES/auth/PERMISSIONS-SYSTEM.md`
- `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`
- `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/02-API/SECURITY-GUIDE.md`