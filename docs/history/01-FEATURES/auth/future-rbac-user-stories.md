# Historias de Usuario y Casos de Uso Futuros - RBAC

**Fecha**: 6 de marzo de 2026  
**Status**: Draft  
**Scope**: Evolución futura del sistema de autorización SACDIA

---

## Resumen

Este documento define historias de usuario y casos de uso futuros para continuar la evolución del RBAC de SACDIA a partir del contrato canónico de autorización ya introducido en backend.

El objetivo es que backend, `sacdia-admin` y `sacdia-app` converjan hacia un modelo consistente donde:

- los roles globales operan con alcance territorial real
- los roles de club operan sobre asignaciones exactas por instancia
- la autorización efectiva se resuelve en backend
- los clientes consumen permisos y contexto resueltos, no heurísticas propias

---

## Actores

- **Super Admin**: autoridad máxima con alcance total
- **Admin / Assistant Admin**: autoridad territorial sobre unión o campo local
- **Coordinator**: autoridad territorial operativa a nivel campo local
- **Director de instancia**: responsable operativo de una instancia específica de club
- **Tesorero de instancia**: responsable financiero de una instancia específica
- **Secretario / Subdirector / Consejero**: cargos operativos de club
- **Miembro autenticado**: usuario regular del sistema
- **Sistema Backend**: fuente de verdad de autorización
- **sacdia-admin**: cliente administrativo web
- **sacdia-app**: cliente móvil

---

## Principios de Negocio

1. Un usuario puede tener roles globales y múltiples asignaciones de club al mismo tiempo.
2. Las acciones globales deben respetar alcance territorial.
3. Las acciones de club deben respetar la asignación exacta activa.
4. Las instancias de club no se deben mezclar entre sí.
5. El backend debe resolver la autorización efectiva; los clientes solo la consumen.

---

## Épicas Futuras

### Épica 1: Contexto activo de autorización

Permitir que el usuario cambie de manera explícita la asignación exacta con la que opera en un momento dado.

### Épica 2: Autorización territorial global

Hacer que los roles globales operen con permisos reales y alcance territorial validado en backend.

### Épica 3: Autorización exacta por instancia de club

Asegurar que las acciones de club se ejecuten según la instancia activa correcta: Aventureros, Conquistadores o Guías Mayores.

### Épica 4: Consumo uniforme en clientes

Lograr que `sacdia-admin` y `sacdia-app` usen el mismo contrato de autorización resuelto por backend.

### Épica 5: Auditoría y trazabilidad

Registrar con qué rol, qué alcance y qué asignación exacta se autorizó cada operación relevante.

---

## Historias de Usuario

### HU-01 Selección de contexto activo

**Como** usuario con múltiples cargos de club  
**quiero** seleccionar mi asignación exacta activa  
**para** operar con el rol correcto en la instancia correcta.

**Criterios esperados**

- El sistema debe mostrar todas mis asignaciones activas disponibles.
- Debo poder elegir una sola asignación activa a la vez.
- El backend debe reflejar la selección en la autorización efectiva.
- El cliente debe actualizar permisos y contexto visible tras el cambio.

### HU-02 Operación territorial de admin

**Como** `assistant_admin` o `admin` territorial  
**quiero** gestionar clubes dentro de mi alcance  
**para** supervisar, corregir y acompañar la operación local.

**Criterios esperados**

- El backend debe permitir operaciones sobre clubes dentro del territorio asignado.
- El backend debe rechazar operaciones fuera de ese territorio.
- El cliente debe reflejar que el acceso viene de un rol global con scope territorial.

### HU-03 Separación estricta entre instancias

**Como** director de una instancia específica  
**quiero** que mis permisos apliquen solo a esa instancia  
**para** evitar mezclar facultades entre Aventureros, Conquistadores y Guías Mayores.

**Criterios esperados**

- Una asignación en una instancia no debe autorizar acciones en otra.
- El backend debe usar `assignment_id` como unidad de contexto.
- El cliente debe mostrar claramente la instancia activa.

### HU-04 Ayuda operativa sin pertenencia directa

**Como** admin territorial  
**quiero** poder editar información de un club al que no pertenezco directamente  
**para** destrabar procesos o corregir incidencias dentro de mi territorio.

**Criterios esperados**

- El backend debe distinguir entre pertenencia directa y autoridad territorial.
- Debe existir una forma clara de auditar cuándo se actuó por alcance global.
- El sistema no debe exigir una asignación de club si el rol global ya cubre el recurso.

### HU-05 Consumo confiable en admin web

**Como** usuario de `sacdia-admin`  
**quiero** que la navegación y las acciones del panel usen permisos efectivos reales  
**para** evitar inconsistencias entre lo que veo y lo que backend permite.

**Criterios esperados**

- El panel debe leer `authorization.effective.permissions`.
- El panel debe leer `authorization.grants` para vistas detalladas o matrices.
- El panel no debe depender de combinaciones legacy ambiguas.

### HU-06 Consumo confiable en app móvil

**Como** usuario de `sacdia-app`  
**quiero** que la app reconozca mi asignación activa y mis permisos efectivos  
**para** ver solo las acciones que realmente puedo ejecutar.

**Criterios esperados**

- La app debe dejar de inferir cargos de club desde `metadata.roles`.
- La app debe usar `authorization.effective.scope.club`.
- La app debe usar `authorization.grants.club_assignments` para selector de contexto.

### HU-07 Permisos finos por acción

**Como** producto/backend  
**quiero** que la autorización final se base en permisos asociados a roles  
**para** evitar depender solo del nombre del rol como criterio de acceso.

**Criterios esperados**

- El backend debe validar permisos efectivos, no solo roles nominales.
- Las rutas deben declarar qué permiso requieren.
- Debe existir estrategia clara para recursos globales y recursos de club.

### HU-08 Trazabilidad de autorización

**Como** auditor técnico o administrador del sistema  
**quiero** saber con qué contexto se autorizó una acción  
**para** investigar incidentes, soporte y uso indebido.

**Criterios esperados**

- Debe registrarse rol global, alcance territorial y/o asignación activa.
- Debe poder distinguirse si el acceso fue por bypass territorial o por rol de club.

---

## Casos de Uso

### UC-01 Consultar autorización resuelta

**Actor principal**: Usuario autenticado  
**Objetivo**: Obtener su autorización efectiva y sus grants disponibles.

**Precondiciones**

- El usuario tiene sesión válida.

**Flujo principal**

1. El cliente llama `GET /auth/me`.
2. Backend resuelve grants globales.
3. Backend resuelve asignaciones de club activas.
4. Backend identifica la asignación activa.
5. Backend construye `authorization.effective`.
6. Cliente recibe perfil + autorización canónica.

**Postcondiciones**

- El cliente conoce permisos efectivos y contexto actual.

### UC-02 Cambiar asignación activa

**Actor principal**: Usuario con múltiples asignaciones  
**Objetivo**: Cambiar el contexto operativo actual.

**Precondiciones**

- El usuario tiene más de una asignación activa válida.

**Flujo principal**

1. Cliente muestra lista de `authorization.grants.club_assignments`.
2. Usuario selecciona una asignación.
3. Cliente envía `PATCH /auth/me/context` con `assignment_id`.
4. Backend valida que la asignación pertenece al usuario y está activa.
5. Backend persiste la asignación activa.
6. Backend devuelve autorización actualizada.

**Flujos alternos**

- Si la asignación no pertenece al usuario, backend responde error.
- Si la asignación está inactiva, backend responde error.

**Postcondiciones**

- La nueva asignación activa gobierna acciones de club posteriores.

### UC-03 Admin territorial gestiona un club

**Actor principal**: `assistant_admin` o `admin`  
**Objetivo**: Modificar datos de un club dentro de su alcance territorial.

**Precondiciones**

- El usuario tiene rol global con alcance territorial válido.
- El club pertenece al territorio permitido.

**Flujo principal**

1. Usuario solicita editar un recurso de club.
2. Backend evalúa alcance territorial global.
3. Backend confirma que el club cae dentro del scope del actor.
4. Backend autoriza la operación aunque no exista asignación directa al club.

**Flujo alterno**

- Si el club está fuera del alcance, backend rechaza.

**Postcondiciones**

- La operación queda registrada como acceso por alcance global.

### UC-04 Director opera su instancia activa

**Actor principal**: Director de club  
**Objetivo**: Gestionar recursos de la instancia donde tiene cargo.

**Precondiciones**

- Tiene una asignación activa exacta para esa instancia.

**Flujo principal**

1. Usuario intenta crear o actualizar recurso de club.
2. Backend valida si existe bypass global.
3. Si no aplica, backend toma `active_assignment`.
4. Backend valida que el club del recurso coincide con el club de la asignación activa.
5. Backend valida que el rol o permiso activo satisface la acción.
6. Backend autoriza.

**Postcondiciones**

- La acción se autoriza con base en la asignación exacta activa.

### UC-05 Tesorero intenta acción no permitida

**Actor principal**: Tesorero de instancia  
**Objetivo**: Intentar una acción reservada a otro rol.

**Precondiciones**

- Tiene sesión válida y asignación activa válida.

**Flujo principal**

1. Usuario intenta una acción reservada a director.
2. Backend resuelve contexto activo.
3. Backend detecta que el rol/permisos efectivos no satisfacen la acción.
4. Backend responde `403`.

**Postcondiciones**

- No se ejecuta la operación.

### UC-06 Mismo club padre, distinta instancia

**Actor principal**: Usuario con múltiples cargos en un mismo club  
**Objetivo**: Operar sin mezclar permisos entre instancias.

**Precondiciones**

- El usuario tiene cargos en más de una instancia del mismo club.

**Flujo principal**

1. Usuario tiene activa una asignación de `Conquistadores`.
2. Intenta una operación de `Aventureros`.
3. Backend evalúa la asignación activa exacta.
4. Backend detecta que la instancia activa no corresponde.
5. Backend rechaza o exige cambio de contexto.

**Postcondiciones**

- No se mezclan permisos entre instancias.

### UC-07 Frontend renderiza UX por autorización efectiva

**Actor principal**: `sacdia-admin` o `sacdia-app`  
**Objetivo**: Mostrar acciones y navegación según autorización backend.

**Precondiciones**

- El cliente ya consultó `GET /auth/me`.

**Flujo principal**

1. Cliente lee `authorization.effective.permissions`.
2. Cliente lee `authorization.effective.scope.club`.
3. Cliente habilita o deshabilita UI según esos datos.
4. Cliente usa `authorization.grants` para selector de contexto o detalle de roles.

**Postcondiciones**

- La UX refleja el backend real y reduce inconsistencias.

---

## Backlog Recomendado por Prioridad

### Prioridad Alta

- Selector de contexto activo consumido por ambos clientes
- Migración de clientes a `authorization.effective`
- Guards backend basados en permisos efectivos
- Endurecimiento de endpoints hoy protegidos solo con JWT

### Prioridad Media

- Auditoría de autorizaciones por contexto
- Visualización clara de alcance territorial en admin
- Mensajes de error orientados a contexto faltante o insuficiente

### Prioridad Baja

- Simulador visual de permisos por actor
- Reportes de cobertura RBAC por módulo
- Herramientas de soporte para cambio temporal de contexto en incidencias

---

## Notas de Implementación Futura

- Este documento no sustituye el contrato API ni los guards concretos.
- Debe usarse como backlog funcional y referencia de comportamiento esperado.
- Cada historia aquí descrita debería terminar en:
  - cambios de contrato backend cuando aplique
  - tests de autorización
  - validación en `sacdia-admin`
  - validación en `sacdia-app`
