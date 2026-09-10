# 03 · Personas, roles, permisos y contexto

**Estado**: DRAFT · **Revisión documental**: 2026-09-10

Este capítulo explica el modelo documentado de autorización. No es todavía un
catálogo exhaustivo de roles configurados ni una auditoría de permisos efectivos.

## La regla central

**Poder entrar al sistema no significa poder hacer cualquier operación.**
Hay que distinguir identidad, rol, permiso, recurso, territorio y contexto anual.
El backend decide; ocultar un botón en la app o el panel no sustituye ese control.

## Qué significa cada término

| Término | Pregunta que responde | Ejemplo |
|---|---|---|
| Identidad | ¿Quién eres? | Cuenta autenticada de una persona |
| Rol global | ¿Qué responsabilidad administrativa/territorial tienes? | `director-union` |
| Cargo en sección | ¿Qué responsabilidad ejerces en una sección? | Director o tesorero en una sección y año |
| Permiso | ¿Qué acción está autorizada? | `finances:read` permite lectura, no creación por sí solo |
| Recurso | ¿Sobre qué objeto quieres actuar? | Club, sección, evidencia o datos personales |
| Alcance | ¿En qué territorio o contexto vale la autorización? | Unión asignada o sección exacta |
| Contexto activo | ¿Con cuál de tus asignaciones operas ahora? | Una asignación de sección seleccionada |

«Global» es una categoría técnica: **no equivale necesariamente a todo el mundo**.
Un rol territorial puede ser global en el modelo de permisos y estar limitado a
una unión o campo. No normalizar automáticamente nombres legacy de documentos.

Fuentes: [Contrato de autorización](../../features/auth/AUTHORIZATION-CANONICAL-CONTRACT.md)
y [Matriz operativa](../../features/auth/RBAC-ENFORCEMENT-MATRIX.md).

## Cómo se determina el acceso, explicado sin código

1. El sistema identifica a la persona.
2. Considera sus responsabilidades globales y permisos directos excepcionales.
3. Para operaciones de sección, utiliza su **asignación activa exacta**, no suma
   indiscriminadamente los cargos que haya tenido en otras secciones.
4. Comprueba el permiso exigido y, cuando corresponde, el rol admitido por la ruta.
5. Comprueba que el objeto y el territorio estén dentro del alcance autorizado.
6. Aplica las reglas particulares del proceso; un permiso no elimina sus requisitos.

Es una explicación conceptual, no una promesa de que todos los endpoints ejecuten
estos controles en idéntico orden. La matriz reconoce diferencias por recurso y
excepciones explícitas.

## Ejemplos que importan para entender SACDIA

### Director de Unión

El contrato indica que `director-union` y `assistant-union` conservan alcance de
unión aunque el perfil tenga un campo local de origen. Ese campo de origen no debe
reducir indebidamente su responsabilidad institucional.

Tampoco se amplía el territorio por enviar otro identificador desde una pantalla.
La documentación distingue el catálogo geográfico —con una política propia— de
la lectura operativa de clubes. Poder seleccionar o ver un nombre en un catálogo
no prueba autorización para gestionar todos sus clubes.

No hemos comprobado qué rol, permisos o territorio tendrá la cuenta del director
de jóvenes de la Unión Mexicana Interoceánica. El cargo humano no se asigna por
inferencia ni requiere convertirlo en `admin` para hacer la demostración.

### Una persona con más de una responsabilidad

El inventario de asignaciones describe lo que tiene asignado; el contexto activo
describe con qué asignación trabaja en ese momento. Cambiar de contexto no crea
un cargo ni concede una autorización que no exista.

### Datos sensibles

Los recursos de salud, contactos de emergencia y representante legal tienen
reglas específicas. Un permiso de club no abre por sí solo todos los datos
personales de terceros. La documentación conserva compatibilidad con ciertos
permisos antiguos; por eso no debe prometerse aislamiento perfecto a partir de
los nombres de los permisos. Esa cobertura requiere comprobación específica.

### Permiso de revisión y cargo institucional

El contrato de evidencias exige roles concretos más `validation:review`.
La existencia de un cargo territorial no prueba que pueda revisar esa cola.
Consultar, aprobar, configurar y administrar permisos son capacidades diferentes.

## Matriz inicial de acciones documentadas

| Acción | Condiciones descritas en la fuente | Lo que NO se deduce |
|---|---|---|
| Ver un club | `clubs:read` y alcance territorial o contexto compatible | Ver todos los clubes del sistema |
| Crear un movimiento financiero | `finances:create`, cargo admitido o autorización territorial compatible | Que poder leer finanzas permita registrar movimientos |
| Revisar evidencias | Rol `admin`/`super-admin`/`coordinator` y `validation:review` | Acceso universal por ser director de Unión |
| Inscribir miembros en el año vigente | `club_members:approve` en la sección destino; reglas de elegibilidad | Que ser dueño del perfil permita autoinscribirse |
| Modificar permisos de un rol | `super-admin` y `permissions:assign` en las rutas correspondientes | Que cualquier administrador institucional pueda hacerlo |

Fuentes: [Matriz operativa](../../features/auth/RBAC-ENFORCEMENT-MATRIX.md),
[API](../../api/ENDPOINTS-LIVE-REFERENCE.md), secciones evidence-review,
annual-membership y rbac. Son resúmenes de condiciones documentadas, no una lista
exhaustiva de bypasses, filtros internos o configuración real de las cuentas.

## Actualización del ciclo anual al retomar el trabajo

Las fuentes locales cambiaron entre el corte inicial y esta continuación.
La referencia API y Gestión de clubes ahora coinciden en estos puntos:

- La directiva autorizada inscribe a los no inscritos del **año vigente** en la
  sección destino; no es simplemente copiar la lista del año pasado.
- La inscripción anual no copia cargos ni convierte a un director de otra sección
  en miembro ya inscrito en esta.
- El endpoint de autoinscripción devuelve `403 ANNUAL_ENROLL_REQUIRES_DIRECTIVE`
  y no escribe datos; D01 sigue marcado pendiente en la fuente.
- Hay casos de clase bloqueados con `ANNUAL_CLASS_POLICY_UNRESOLVED`; no se debe
  presentar como automático todo cruce de tipo o caso de Guías Mayores.

Esta conciliación **documental** actualiza H03 del capítulo 01. No acredita todavía
que backend, app, panel y despliegue estén sincronizados. La próxima ficha de ciclo
anual deberá contrastar precisamente esas cuatro superficies.

## Qué falta para cerrar este bloque

- Inventario exacto de roles vigentes y traducciones humanas, sin mezclar aliases.
- Matriz rol × acción × alcance contrastada con configuración y código.
- Comprobación de contexto anual y cambio de sección en app/panel.
- Escenarios de acceso permitido y denegado con datos ficticios.
- Separación documentada entre responsable institucional, administrador técnico,
  consejero, responsable pedagógico y validador.
