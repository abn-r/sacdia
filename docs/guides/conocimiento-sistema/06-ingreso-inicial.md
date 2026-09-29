# 06 · Ingreso inicial: cuenta, perfil, sección, membresía y clase

**Estado:** DRAFT · borrador ejecutivo basado en revisión documental y de código  
**Fecha de revisión:** 2026-09-14  
**Alcance:** ingreso inicial de una persona a SACDIA. El flujo anual de continuidad (`annual-continuations`) queda expresamente fuera de esta ficha.

## 1. Propósito y resultado

Esta ficha explica qué ocurre desde que una persona crea o inicia su cuenta hasta que queda registrada en una sección y una clase para el año eclesiástico vigente.

El resultado importante es doble:

1. **Post-registro completo:** la persona ya proporcionó foto, información personal y selección territorial/club/sección; la app deja de forzar el wizard y puede llevarla al inicio.
2. **Membresía inicial pendiente:** el sistema crea la asignación como `pending`. La inscripción anual de clase se registra en la misma transacción, pero eso **no equivale** a membresía activa. Una directiva con permisos debe aprobarla.

La separación evita presentar como “inscrito y activo” a alguien cuyo paso administrativo aún está pendiente.

## 2. Vocabulario operativo

- **Cuenta:** identidad autenticable (correo/contraseña o OAuth) y sesión.
- **Miembro:** persona de SACDIA. No es sinónimo de cuenta: puede autenticarse y completar su perfil antes de tener una membresía activa.
- **Club:** raíz institucional.
- **Sección:** unidad operativa de un club y un tipo de club; la sección disponible se muestra como club + tipo, no como un nombre libre.
- **Clase:** trayectoria formativa que el backend resuelve por tipo de club y edad al inicio del año eclesiástico; no se selecciona arbitrariamente.

La distinción club–sección–tipo–trayectoria está en [`docs/canon/dominio-sacdia.md`](../../canon/dominio-sacdia.md):21-47, 57-93 y 137-207. Las bandas de referencia documentadas son Aventureros 4–9, Conquistadores 10–15 y Guías Mayores 16+ (`docs/features/gestion-clubs.md`:7-15); la configuración vigente de clases es la autoridad efectiva.

## 3. Cómo leer la evidencia

- **Canon/contrato:** documentación normativa o referencia API.
- **Código:** ruta y lógica implementadas en backend/app; demuestra disponibilidad técnica, no despliegue productivo.
- **Pruebas leídas:** casos existentes en archivos de test; **no fueron ejecutados** en esta revisión.
- **Disponibilidad:** “conectado en código” no significa que se haya probado una cuenta real, un ambiente desplegado o un flujo E2E.

## 4. Flujo resumido

```text
Persona
  └─ crea cuenta o inicia OAuth
      └─ sesión + needsPostRegistration=true
          ├─ Paso 1: foto
          ├─ Paso 2: datos personales, emergencia y representante si aplica
          └─ Paso 3: territorio → club → sección
                ├─ backend calcula clase por edad/tipo/año
                ├─ crea membresía inicial PENDING (8 días)
                ├─ crea/reactiva enrollment del año
                └─ post-registro COMPLETE; notifica revisores
                         └─ directiva APRUEBA → membresía ACTIVE
```

## 5. Pasos numerados

### Paso 1 — Crear o iniciar la cuenta

**Actor:** persona interesada; la app/Better Auth ejecuta la autenticación.  
**Condiciones:** registro con nombre, apellidos, correo y contraseña; OAuth Google/Apple también está contemplado por el contrato.  
**Resultado:** se crea `users`, el estado granular `users_pr` y el rol global `user`. El registro devuelve sesión/tokens, `emailVerificationPending: true` y `needsPostRegistration: true` (`sacdia-backend/src/auth/auth.service.ts`:83-115, 154-200).

**Verificación de correo:** se envía el correo de verificación de forma asíncrona; el endpoint de verificación existe. En el login y el guard de navegación revisados no aparece un bloqueo por `email_verified`; el bloqueo observado es `needsPostRegistration`/`postRegisterComplete`. Por eso la presentación debe decir **“verificación disponible; requisito previo al wizard no confirmado”**, no “el correo verificado habilita el ingreso”. Contrato OAuth y verificación: `docs/canon/auth/runtime-auth.md`:190-227, 267-275.

**Rechazos trazados:** correo/credenciales inválidos o cuenta duplicada se rechazan sin revelar si un correo existe (`sacdia-backend/src/auth/auth.controller.ts`:41-70; `sacdia-backend/src/auth/dto/register.dto.ts`:5-30). No se usaron cuentas reales.

### Paso 2 — Acceder al post-registro

**Actor:** persona autenticada.  
**Condición:** `users_pr.complete = false`.  
**Resultado:** la app dirige a post-registro; si está completo, dirige al inicio (`sacdia-app/lib/core/config/router.dart`:244-275). El estado expone tres banderas y `nextStep` para reanudar (`sacdia-backend/src/post-registration/post-registration.service.ts`:61-107).

**Disponibilidad:** ruta protegida por JWT y permiso `registration:complete`; el propietario puede operar sobre su recurso (`sacdia-backend/src/post-registration/post-registration.controller.ts`:35-51, 87-176).

### Paso 3 — Foto de perfil

**Actor:** persona (o administración autorizada para asistencia).  
**Condición:** debe existir una foto cargada.  
**Resultado:** `profile_picture_complete = true`. Sin foto se devuelve `POST_REG_PHOTO_REQUIRED` (`sacdia-backend/src/post-registration/post-registration.service.ts`:121-158). La app dispone de carga y confirmación (`sacdia-app/lib/features/post_registration/data/datasources/post_registration_remote_data_source.dart`:62-106, 128-172).

### Paso 4 — Información personal y salvaguarda

**Actor:** persona; un adulto responsable interviene cuando la regla lo exige.  
**Datos requeridos para cerrar el paso:** género, fecha de nacimiento, valor de bautismo (puede ser `false`) y al menos un contacto de emergencia. Para una persona menor de 18 años se exige representante legal existente (`sacdia-backend/src/post-registration/post-registration.controller.ts`:115-133; `sacdia-backend/src/post-registration/post-registration.service.ts`:161-217).

**Resultado:** `personal_info_complete = true`. Faltas producen, respectivamente, `POST_REG_PERSONAL_INFO_INCOMPLETE`, `POST_REG_EMERGENCY_CONTACT_REQUIRED` o `POST_REG_LEGAL_REP_REQUIRED`. Los datos de salud adicionales aparecen en la app, pero no deben presentarse como condición adicional salvo que el backend los requiera (`sacdia-app/lib/features/post_registration/presentation/providers/personal_info_providers.dart`:672-770).

### Paso 5 — Territorio, club y sección

**Actor:** persona autenticada.  
**Condiciones:** país, unión, campo local y una sección activa válida. La app ofrece selectores encadenados país → unión → campo local → club → sección (`sacdia-app/lib/features/post_registration/data/datasources/club_selection_remote_data_source.dart`:13-33, 51-240). El tipo de club se deriva de la sección; el backend vuelve a validarlo. La app recomienda/autoelige cuando hay una sola opción y no es autoridad de negocio (`sacdia-app/lib/features/post_registration/presentation/providers/club_selection_providers.dart`:137-145, 146-272).

**Clase:** el backend calcula la edad en la fecha de inicio del año eclesiástico y busca la clase activa compatible con el tipo y la disponibilidad de ese año. Si no se envía `class_id`, la resuelve; si se envía uno no disponible, de otro tipo o distinto del esperado, rechaza (`sacdia-backend/src/common/services/class-assignment-resolver.service.ts`:12-108). En la UI inicial la clase aparece derivada y no es un selector manual (`sacdia-app/lib/features/post_registration/presentation/views/club_selection_step_view.dart`:358-444).

### Paso 6 — Cierre transaccional del paso 3

**Actor:** backend, en nombre de la persona.  
**Resultado atómico:**

1. actualiza país, unión y campo local;
2. crea o reactiva `club_role_assignments` para el rol miembro, estado `pending`, con vencimiento a ocho días;
3. desactiva otra inscripción anual operacional del mismo año/tipo y crea o reactiva el `enrollment` de la clase resuelta;
4. marca `club_selection_complete` y `complete` como verdaderos;
5. invalida el contexto de autorización y notifica a los revisores si es una solicitud nueva.

La implementación y su transacción están en `sacdia-backend/src/post-registration/post-registration.service.ts`:239-355 y 459-579. El contrato describe el paso como “membresía + inscripción anual antes de cerrar post-registro” (`sacdia-backend/src/post-registration/post-registration.controller.ts`:144-176).

**Clave ejecutiva:** “post-registro completo” significa que terminó el formulario; **no** significa que la directiva ya aprobó la membresía.

### Paso 7 — Confirmación administrativa de la membresía inicial

**Actor confirmador:** directiva/revisor con permiso `club_members:approve` y alcance sobre la sección destino. La API lista, aprueba o rechaza solicitudes pendientes (`sacdia-backend/src/membership-requests/membership-requests.controller.ts`:31-132). La guía funcional contempla director, subdirector, secretario y secretario-tesorero como destinatarios de la notificación (`docs/features/membership-requests.md`:19-35).

- **Aprobar:** cambia `pending → active`, elimina vencimiento, invalida autorización y actualiza clientes (`sacdia-backend/src/membership-requests/membership-requests.service.ts`:68-131).
- **Rechazar:** cambia `pending → rejected`, conserva motivo opcional y revoca el acceso operacional (`.../membership-requests.service.ts`:133-201).
- **Pendiente:** permite consultar perfil/detalle, pero no operar el club; se muestra “Pendiente de aprobación” (`docs/features/membership-requests.md`:37-51).
- **Cancelar por la persona:** `cancelled`, inactiva la asignación y reabre la selección de club (`sacdia-backend/src/membership-requests/membership-requests.service.ts`:204-277).
- **Vencimiento:** un proceso horario vence solicitudes después del plazo configurado, documentado por defecto como ocho días (`docs/features/membership-requests.md`:19-35).

La asignación inicial sí tiene decisión administrativa; el `enrollment` de clase se crea durante el paso 3 como registro operacional del año. No hay evidencia aquí de una segunda aprobación de clase.

## 6. Estados y rechazos relevantes

| Objeto | Estado inicial | Decisión/resultado | Nota |
|---|---|---|---|
| `users_pr` | incompleto | completo al cerrar paso 3 | Es el estado del wizard, no de membresía. |
| `club_role_assignments` | `pending` | `active`, `rejected`, `cancelled` o vencido | `active` es lo que habilita operación de club. |
| `enrollments` | creado/reactivado en año vigente | activo según registro anual | No sustituye la aprobación de membresía. |

Errores que la demo debe poder explicar: perfil incompleto, falta de emergencia/representante, año eclesiástico no activo, club/sección inexistente, membresía duplicada (`POST_REG_DUPLICATE_MEMBERSHIP`) y clase inexistente/no elegible (`POST_REG_CLASS_NOT_FOUND`, `POST_REG_CLASS_NOT_ELIGIBLE`). El código también impide otra solicitud pendiente o una membresía activa del mismo tipo (`sacdia-backend/src/post-registration/post-registration.service.ts`:470-507).

**No mezclar con continuidad anual:** `POST /users/:userId/membership/annual-enroll` está deliberadamente bloqueado con `ANNUAL_ENROLL_REQUIRES_DIRECTIVE`; la continuidad se realiza por una directiva específica y es otro flujo (`sacdia-backend/src/annual-membership/annual-membership.service.ts`:287-292; `docs/features/membership-requests.md`:93-106).

## 7. Disponibilidad por superficie

| Superficie | Qué está trazado | Nivel de evidencia |
|---|---|---|
| Backend/API | Registro/login/OAuth, estado, tres pasos, resolución de clase, creación de solicitud, aprobación/rechazo | Código y referencia API; no prueba de despliegue. |
| App móvil | Wizard completo, selectores encadenados, carga de foto, cancelación y redirección por estado | Código conectado; no E2E ejecutado. |
| Panel administrativo | Bandeja para revisar solicitudes y consulta/asistencia de post-registro | Documentación funcional y código del panel; la administración no crea la solicitud inicial por una ruta separada. |
| Pruebas | Hay casos para derivación de clase, reintentos, duplicados, notificación, aprobación/rechazo, cancelación y expiración | Archivos leídos, **no ejecutados**. |
| Producción | Cuenta real, correo, proveedores OAuth, permisos efectivos y disponibilidad del ambiente | Pendiente de verificación. |

No se infiere que el cargo de “director de jóvenes de la Unión Mexicana Interoceánica” otorgue permisos concretos: la autorización efectiva depende del rol/permisos y alcance registrados en SACDIA.

## 8. Cinco mensajes ejecutivos

1. **SACDIA separa identidad de pertenencia:** crear una cuenta no convierte automáticamente a la persona en miembro activo de un club.
2. **El ingreso inicial es guiado y reanudable:** foto, información personal y selección de club/sección quedan registrados por pasos.
3. **La clase no se asigna por preferencia libre:** se determina por edad al inicio del año, tipo de club y disponibilidad de la clase.
4. **La directiva conserva el control institucional:** el nuevo registro queda pendiente hasta que un revisor autorizado aprueba la membresía.
5. **La continuidad anual es otro proceso:** no debe confundirse con el alta inicial ni presentarse como autoinscripción.

## 9. Guion de demo ficticio (sin datos personales)

1. Mostrar un personaje “Participante Demo 01” con correo `demo-no-real@example.invalid`; aclarar que no es una cuenta real.
2. Registrar/iniciar sesión y señalar que recibe sesión, pero la app lo lleva al post-registro.
3. Completar foto y datos mínimos; para ilustrar salvaguarda, mencionar que una persona menor requiere representante legal sin mostrar nombres ni documentos.
4. Seleccionar opciones ficticias de territorio y un “Club Horizonte Demo”; elegir una sección activa de Conquistadores. Mostrar que la clase aparece calculada por edad/año.
5. Cerrar paso 3 y remarcar en pantalla: **post-registro completo + membresía pendiente**. Mostrar la notificación en la bandeja de solicitudes.
6. Como “Revisor Demo”, aprobar la solicitud dentro de la sección correcta y mostrar el cambio a `active`/acceso operacional.
7. Repetir verbalmente que este recorrido es un ejemplo controlado; no usar datos, correos, credenciales ni nombres de personas reales.

## 10. Brechas y comprobaciones pendientes

- Confirmar con producto si el correo debe verificarse antes o después del wizard; el runtime revisado no muestra ese bloqueo.
- Ejecutar un smoke/E2E en un ambiente autorizado para validar email/OAuth, permisos por sección, notificaciones y vencimiento; esta ficha no ejecutó tests ni builds.
- Resolver la trazabilidad del aprobador/rechazador: el servicio recibe esos identificadores, pero el propio código documenta que no persiste `approved_by/at` ni `rejected_by/at` (`sacdia-backend/src/membership-requests/membership-requests.service.ts`:76-78, 141-143).
- No prometer prerequisitos de clase, investiduras o progreso en el alta inicial: las políticas de inscripción explícita/anual son superficies distintas del `enrollment` creado por paso 3.

## Fuentes principales

- `docs/canon/dominio-sacdia.md`
- `docs/canon/auth/runtime-auth.md`
- `docs/features/gestion-clubs.md`
- `docs/features/membership-requests.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `sacdia-backend/src/auth/auth.service.ts`
- `sacdia-backend/src/post-registration/post-registration.controller.ts`
- `sacdia-backend/src/post-registration/post-registration.service.ts`
- `sacdia-backend/src/common/services/class-assignment-resolver.service.ts`
- `sacdia-backend/src/membership-requests/membership-requests.service.ts`
- `sacdia-app/lib/core/config/router.dart`
- `sacdia-app/lib/features/post_registration/`

