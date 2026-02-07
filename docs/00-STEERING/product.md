# Product Overview

> Define la visión, objetivos y características clave del producto  
> Este archivo ayuda a la IA a entender el "por qué" detrás de las decisiones técnicas

---

## Visión del Producto

### Elevator Pitch

SACDIA es una plataforma que ayuda a los miembros del Ministerio Juvenil Adventistas enfocados en los clubes a tener un historial digital de su vida en los clubes además de una herramienta administrativa para la gestión de los clubes y sus miembros de manera clara, sencilla y de fácil acceso. A diferencia de aplicaciones básicas de consultas de materiales de clubes, nosotros generamos un perfil digital de cada miembro y club, lo que permite ver el paso del tiempo así como el registro de especialidades, clases, actividades, campamentos, etc.

---

## Problema que Resolvemos

### Pain Points del Usuario

1. **Falta de Registro Digital de Trayectoria**: Los miembros de los clubes del Ministerio Juvenil Adventista NO cuentan con un registro digital relacionado con su trayecto dentro de los clubes.
   - Impacto: Certificados, especialidades, cuadernillos o carpetas todo es físico, en el punto que estos documentos se pierden el miembro tiene que solicitar una carta al campo local para revalidar lo que tiene, pero también se da el caso de que no se pueda revalidar y el usuario necesite volver a cursar las clases del club.
   - Frecuencia: Cada vez que se pierden los documentos o se requiera consultar el historial de un miembro del club.

2. **Gestión Administrativa Manual**: Los clubes del Ministerio Juvenil Adventista NO cuentan con un registro digital de actividades, especialidades, miembros, unidades, campamentos, etc. Lo cual lleva a que todo se realice en papel, los reportes mensuales que se envían al campo local tienen que ser generados manualmente y siempre tratan de actividades, especialidades y demás cuestiones que ya se realizan en el club pero no existe un registro de ello.
   - Impacto: Administración del club consumida por burocracia en lugar de actividades formativas.
   - Frecuencia: Cada reunión del club y durante el mes.

3. **Procesos Institucionales Lentos**: La Iglesia Adventista del Séptimo Día no cuenta con una herramienta que agilice y permita gestionar la información tanto de los clubes como de los miembros, teniendo procesos administrativos lentos que requieren que las personas asistan a las oficinas en cada campo local.
   - Impacto: Todos los clubes y miembros de club enfrentan demoras y viajes innecesarios.
   - Frecuencia: En cada solicitud de validación, certificado o consulta histórica.

### Situación Actual (As-Is)

La Iglesia Adventista del Séptimo Día no cuenta con una herramienta que agilice y permita gestionar la información tanto de los clubes como de los miembros, teniendo procesos administrativos lentos que requieren que las personas asistan a las oficianas en cada campo local sin un panorama claro de la situación de los clubes y miembros.

---

## Nuestra Solución

### Propuesta de Valor

SACDIA es una plataforma que ayuda a los miembros del Ministerio Juvenil Adventista enfocados en los clubes a tener un historial digital de su vida en los clubes, además de una herramienta administrativa para la gestión de los clubes y sus miembros de manera clara, sencilla y de fácil acceso. A diferencia de aplicaciones básicas de consultas de materiales de clubes, nosotros generamos un perfil digital de cada miembro y club, lo que permite ver el paso del tiempo así como el registro de especialidades, clases, actividades, campamentos, etc.

En caso de perdida de certificados, especialidades, clases, insignias, etc, el usuario podrá solicitar un nuevo certificado o material a través de la plataforma el cual será expedido por los diferentes campos locales, presentando los documentos necesarios y cubriendo el costo correspondiente.

**Beneficios Clave**:
1. **Digitalización Completa**: Digitalización de la información de clubes y miembros, eliminando el riesgo de pérdida de documentos físicos.
2. **Reducción de Carga Administrativa**: Reducción de procesos administrativos manuales, liberando hasta 70% del tiempo para actividades formativas.
3. **Historial Digital Permanente**: Perfil digital de cada miembro y club que preserva el historial completo a lo largo de los años.
4. **Accesibilidad Universal**: Acceso a la información desde cualquier lugar con conexión a internet, sin necesidad de visitar oficinas.
5. **Reportes Automáticos**: Generación automática de reportes eliminando trabajo manual mensual.
6. **Trazabilidad Institucional**: Seguimiento administrativo al club por la unión, campo local y club con visibilidad en tiempo real.
7. **Validaciones Digitales**: Autorización digital de especialidades, investiduras, etc. con trazabilidad completa.
8. **Gestión de Campamentos**: Gestión eficiente de campamentos y sus actividades relacionadas con carpeta de evidencias digital.


### Diferenciadores

¿Qué nos hace únicos?

1. **Perfil Digital Histórico**: Perfil digital permanente de cada miembro y club que nunca se pierde, a diferencia del papel que se extravía.
2. **Reportes Automatizados**: Generación automática de reportes que elimina el trabajo manual mensual que consumen horas.
3. **Gestión Integral 360°**: Seguimiento administrativo completo del club, unidades, miembros, finanzas, inventarios, etc. en un solo lugar.
4. **Sistema de Validación Digital**: Autorización digital de especialidades, investiduras, etc. con flujo de aprobación por niveles (consejero → director → coordinador).
5. **Carpeta de Evidencias Digital para Campamentos**: Gestión digital de evidencias para campamentos y actividades con revisión previa, eliminando la dependencia del papel.
6. **Acceso Multiplataforma**: Acceso a la información desde cualquier lugar mediante app móvil y panel web, sin necesidad de visitar oficinas.

---
# Estructura Completa de Clubes SACDIA

## 1. Jerarquía Organizacional

```
División Interamericana
  ├── Uniones (ej: Unión Mexicana Interoceánica)
  │   ├── Campos Locales (ej: Campo del Sureste)
  │   │   ├── Distritos
  │   │   │   ├── Iglesias
  │   │   │   │   └── Clubes (ej: "Club Astro")
  │   │   │   │       ├── Club Astro de Aventureros (TIPO)
  │   │   │   │       ├── Club Astro de Conquistadores (TIPO)
  │   │   │   │       └── Club Astro de Guías Mayores (TIPO)
```

### Conceptos Clave:

**Club vs Tipo de Club**:
- Un **Club** (ej: "Club Astro") es la entidad principal con nombre, dirección, etc.
- Ese club se divide en **Tipos de Club**: Aventureros, Conquistadores, Guías Mayores
- Un club puede tener 1, 2 o 3 tipos activos
- **Guías Mayores puede estar inactivo** pero siempre permite registro de personas +16 años (se necesitan GMs para ocupar cargos en otros tipos)

**Ejemplos**:
- Club pequeño: Solo Conquistadores + Guías Mayores
- Club mediano: Aventureros + Conquistadores + Guías Mayores
- Club grande: Los 3 tipos activos con múltiples unidades cada uno

---

## 2. Tipos de Clubes y Sistema de Clases

### 2.1 Aventureros (4-9 años)

**Sistema de Clases**: 6 clases por edad
- **4 años**: Abejitas Laboriosas
- **5 años**: Rayitos de Sol
- **6 años**: Constructores
- **7 años**: Manos Ayudadoras
- **8 años**: Exploradores
- **9 años**: Caminantes

**Ciclo de Inscripción Anual**:
1. Al **inicio del año eclesiástico**, el niño se inscribe
2. Selecciona automáticamente la clase correspondiente a su edad **en ese momento**
3. Durante todo el año, realiza actividades y requisitos de ESA clase
4. Al **final del año**, el club solicita investidura para quienes completaron requisitos
5. La investidura ocurre en una fecha configurable por cada campo local

**Importante**: 
- NO cambian de clase al cumplir años durante el año
- Si un niño cumple 6 años en marzo pero se inscribió con 5 en enero, cursa "Rayitos de Sol" TODO ese año
- Al año siguiente se inscribe en "Constructores"

---

### 2.2 Conquistadores (10-15 años)

**Sistema de Clases**: 6 clases por edad
- **10 años**: Amigo
- **11 años**: Compañero
- **12 años**: Explorador
- **13 años**: Orientador
- **14 años**: Viajero
- **15 años**: Guía

**Ciclo de Inscripción Anual**: Igual que Aventureros
1. Inscripción al inicio del año eclesiástico
2. Clase determinada por edad en ese momento
3. Actividades durante todo el año
4. Investidura al final del año (fecha configurable)

**Restricciones**:
- Un Conquistador NO puede cursar clases de Aventureros o Guías Mayores (excepto si luego se vuelve GM investido)

---

### 2.3 Guías Mayores (16-99 años)

**Sistema de Clases**: 2 clases
1. **Guía Mayor** (clase activa)
2. **Guía Mayor Avanzado** (clase histórica - solo para registros de quienes la cursaron antes)

**Estados de un Guía Mayor**:
- **Aspirante (NO investido)**: Usuario que NO ha completado la clase "Guía Mayor"
- **Guía Mayor Investido**: Usuario que completó y se invistió de la clase "Guía Mayor"

**Ciclo de Inscripción**: 
- Inscripción al inicio del año eclesiástico
- Sin requisito de edad (cualquier persona +16 puede inscribirse)
- Puede inscribirse incluso si el tipo "Guías Mayores" está inactivo en el club

---

## 3. Proceso de Investidura (Crítico)

**Workflow de Investidura**:

1. **Durante el año**: Miembro completa requisitos de su clase, consejero valida
2. **Solicitud de investidura**: 
   - El director del club envía al miembro a **validación para investir**
   - Esto puede configurarse por campo local (ej: noviembre, diciembre)
3. **Validación pendiente**:
   - El miembro queda en estado "Enviado a validación"
   - **NO puede modificar** ningún requisito ingresado
   - El coordinador de campo revisa y **Aprueba o Rechaza**
4. **Si es Aprobado**: 
   - Queda confirmado para investidura
   - Se genera en el registro "Investido [Clase] [Año]"
5. **Si es Rechazado**: 
   - Vuelve a estado editable
   - El miembro puede corregir/completar lo que faltó
   - Puede volver a enviarse a validación

**Estado de requisitos**:
- ✅ **Editable**: Mientras no se ha enviado a validación
- 🔒 **Bloqueado**: Una vez enviado a validación para investir
- ✅ **Editable nuevamente**: Si fue rechazado en validación
- 🔒 **Permanente**: Una vez investido (pasa a histórico)

---

## 4. Roles de Guías Mayores en Tipos de Clubes

### Roles Disponibles:
- **Director** (requiere ser GM investido solo en tipo GM)
- **Subdirector(a)** (requiere ser GM investido solo en tipo GM)
- **Secretario(a)**
- **Tesorero(a)**
- **Consejero**

### Capacidad Multi-Tipo:

Un Guía Mayor (investido o NO) puede tener roles en **múltiples tipos de club simultáneamente**:

**Ejemplos válidos**:
1. María (GM Aspirante):
   - Miembro del club de Guías Mayores
   - Consejera de la clase "Amigo" en Conquistadores
   
2. Juan (GM Investido):
   - Miembro del club de Guías Mayores
   - Director del club de Aventureros
   
3. Pedro (GM Investido):
   - Director del club de Guías Mayores (requiere estar investido)
   - Consejero de "Exploradores" en Aventureros
   - Secretario en Conquistadores

**Restricción única**:
- Para ser **Director o Subdirector del club de Guías Mayores** SÍ se requiere estar **investido como Guía Mayor**
- Para cualquier otro rol en cualquier otro tipo, NO se requiere estar investido

---

## 5. Privilegio de Cursado Cruzado (Guías Mayores Investidos)

**Quién**: Solo Guías Mayores **Investidos**

**Qué pueden hacer**:
- Inscribirse en clases de Aventureros o Conquistadores que **NO tengan investidas**
- Bypass del requisito de edad (un GM de 30 puede cursar "Amigo" que normalmente es para 10 años)

**Restricciones**:
- Solo clases que NO estén en su historial de investiduras
- Siguen el mismo proceso anual de inscripción
- Validación por consejeros igual que miembros regulares

**Casos de uso**:
- Un GM que nunca fue Aventurero de niño puede cursar las 6 clases de Aventureros
- Un GM que solo cursó "Amigo" y "Compañero" de Conquistador puede completar las 4 restantes

---

## 6. Sistema de Certificaciones (Guías Mayores Investidos)

**Requisito**: Ser Guía Mayor Investido

**Características**:
- 6 certificaciones disponibles (nombres por definir)
- **Inscripción simultánea**: Puede cursar múltiples certificaciones al mismo tiempo
- No son secuenciales
- Sistema de requisitos igual que clases (módulos, apartados)
- Validación por consejeros/directores
- Ceremonia de reconocimiento por certificación completada

---

## 7. Reglas de Inscripción por Tipo

| Tipo de Usuario | Clases que puede cursar | Certificaciones | Roles que puede tener |
|------------------|-------------------------|-----------------|------------------------|
| **Aventurero** (4-9) | Solo su clase por edad en Aventureros | ❌ No | Miembro |
| **Conquistador** (10-15) | Solo su clase por edad en Conquistadores | ❌ No | Miembro |
| **GM Aspirante** (16+) | Solo clases de GM | ❌ No | Miembro GM, Consejero/Secretario/Tesorero en otros tipos |
| **GM Investido** (16+) | GM + Clases de otros tipos que no tenga | ✅ Sí (6 disponibles) | Cualquier rol en cualquier tipo |

---

## 8. Flujo de Años Eclesiásticos

```
Enero: Inicio de Año Eclesiástico
├── Inscripciones abiertas
├── Miembros seleccionan/se asigna clase por edad
├── Inicio de actividades

Febrero-Octubre: Desarrollo del Año
├── Miembros completan requisitos
├── Consejeros validan apartados
├── Estado: EDITABLE

Noviembre: Cierre de Requisitos (configurable)
├── Directores envían miembros a validación
├── Estado cambia a: BLOQUEADO
├── Coordinadores revisan y aprueban/rechazan

Diciembre: Investiduras (configurable)
├── Ceremonia de investidura
├── Registros pasan a histórico
├── Estado: PERMANENTE

Diciembre: Cierre de Año Eclesiástico
└── Todos los registros del año se marcan como históricos
    Nueva inscripción para siguiente año
```

---

## 9. Ejemplos Prácticos

### Caso 1: Niño Aventurero
- Juan tiene 5 años en enero 2026
- Se inscribe en "Rayitos de Sol"
- En abril cumple 6 años → Sigue en "Rayitos de Sol"
- Completa requisitos en octubre
- Noviembre: Director lo envía a validación
- Diciembre: Se inviste como "Rayitos de Sol 2026"
- Enero 2027: Se inscribe en "Constructores" (ahora tiene 6)

### Caso 2: GM con Múltiples Roles
- María es GM Investida
- Roles simultáneos:
  - Miembro del club de Guías Mayores
  - Directora del club de Aventureros del "Club Astro"
  - Consejera de "Amigo" en Conquistadores del "Club Astro"
  - Cursando certificación de "Instructor de Especialidades"
  - Cursando clase de "Abejitas Laboriosas" (nunca fue Aventurera)

### Caso 3: Club con Tipos Parciales
- "Club Estrella" tiene:
  - Conquistadores: ACTIVO (30 miembros)
  - Guías Mayores: INACTIVO (pero permite registro)
- Pedro (17 años) se puede inscribir como GM aunque el tipo esté inactivo
- Pedro se vuelve Consejero en Conquistadores
- El tipo GM permite tener GMs para roles en Conquistadores

---

**Última actualización**: 2026-01-20

## Usuarios Objetivo

### Personas (User Personas)

#### Persona 1: Miembro del club

**Demografía**:
- Edad: 4-99 años
- Ocupación: Personas que asistan al club desde niños de temprana edad hasta los 99 años.
- Ubicación: Latinoamérica
- Nivel técnico: Principiante

**Objetivos**:
- Tener un registro digital de su trayecto dentro de los clubes.
- Tener un registro digital de sus especialidades, clases, actividades, campamentos, etc.
- Tener un registro digital de sus insignias, clases, etc.
- Consultar los detalles de las actividades programadas para el club.
- Ir avanzando entre los diferentes tipos de club según su rango de edad.
- Cuando sea guía mayor o aspirante a guía mayor poder ser asignado como consejero y cambiar entre un tipo de club y otro según el rol que se tenga en cada tipo de club.
- Cuando sea un guía mayor o aspirante podrá ser asignado como un rol adminstrativo.

**Frustraciones**:
- Los procesos administrativos para recuperar insignias, especialidades, etc.
- El registro del paso por el club es en papel.

**Comportamiento**:
- Solo usan páginas y aplicaciones móviles de consultas.
- No usan aplicaciones móviles para gestionar su información.
- Todo el registro de clubes y miembros es en papel.

---

#### Persona 2: Consejero

**Demografía**:
- Edad: 16-99 años
- Ocupación: Personas que estan en las clases de aspirantes a guía mayor o como guía mayor (investido).
- Ubicación: Latinoamérica
- Nivel técnico: Principiante

**Objetivos**:
- Tener un registro digital de su trayecto dentro de los clubes.
- Tener un registro digital de sus especialidades, clases, actividades, campamentos, etc.
- Tener un registro digital de sus insignias, clases, etc.
- Consultar los detalles de las actividades programadas para el club.
- Consultar la información de los diferentes tipos de club en los cuales es consejero y son parte del club.
- Tener acceso al avance de las clases asignadas en su cuadernillo e investidura.
- Tener acceso al registros de unidades de miembros asignadas.
- Tener acceso a la información de contactos de emergencia de los miembros del club.

**Frustraciones**:
- Los procesos administrativos para recuperar insignias, especialidades, etc.
- El registro del paso por el club es en papel.
- La gestión del avance en las clases es en papel.
- La gestión de los miembros y unidades es en papel.

**Comportamiento**:
- Solo usan páginas y aplicaciones móviles de consultas.
- No usan aplicaciones móviles para gestionar su información.
- Todo el registro de clubes y miembros es en papel.

---

#### Persona 3: Directivo del club 

**Demografía**:
- Edad: 16-99 años
- Ocupación: Personas que estan en las clases de o guía mayor (investido).
- Ubicación: Latinoamérica
- Nivel técnico: Principiante

**Objetivos**:
- Tener un registro digital de su trayecto dentro de los clubes.
- Tener un registro digital de sus especialidades, clases, actividades, campamentos, etc.
- Tener un registro digital de sus insignias, clases, etc.
- Consultar los detalles de las actividades programadas para el club.
- Consultar la información de los diferentes tipos de club en los cuales es consejero y son parte del club.
- Tener acceso al avance de las clases asignadas en su cuadernillo e investidura.
- Tener acceso al registros de unidades de miembros asignadas.
- Tener acceso a la información de contactos de emergencia de los miembros del club.
- Administrar la información del club, miembros, finanzas, unidades, clases, campamentos, actividades, etc.
- Admitir / rechazar miembros del club.
- Generación de reportes.

**Frustraciones**:
- Los procesos administrativos para recuperar insignias, especialidades, etc.
- El registro del paso por el club es en papel.
- La gestión del avance en las clases es en papel.
- La gestión de los miembros y unidades es en papel.
- La gestión de las finanzas es en papel.
- La gestión de las actividades es en papel o por medios como whatsapp.
- La gestión de los campamentos es en papel.
- La gestión de los consejeros es en papel.
- La gestión de los directivos no se registra.

**Comportamiento**:
- Solo usan páginas y aplicaciones móviles de consultas.
- No usan aplicaciones móviles para gestionar su información.
- Todo el registro y administración de clubes y miembros es en papel.

---

#### Persona 4: Coordinadores 

**Demografía**:
- Edad: 22-65 años
- Ocupación: Guías Mayores de experiencia (+5 años en clubes)
- Ubicación: Latinoamérica
- Nivel técnico: Medio

**Objetivos**:
- Revisar y validar avances de miembros de clubes asignados.
- Dar seguimiento a clases de clubes.
- Autorizar o rechazar especialidades, clases investidas, etc.
- Generación de reportes.

**Frustraciones**:
- La gestión del avance en las clases es en papel.
- No existe un proceso para autorizar o rechazar especialidades, clases investidas, etc.

**Comportamiento**:
- Solo usan páginas y aplicaciones móviles de consultas.
- No usan aplicaciones móviles para gestionar su información.

---

#### Persona 5: Administrativos (Campos locales, Unión, División)

**Demografía**:
- Edad: 22-63 años
- Ocupación: Personal administrativo de la iglesia, son las asistentes y departamentales del ministerio juvenil adventista a nivel campo local, unión y división.
- Ubicación: Latinoamérica
- Nivel técnico: Medio

**Objetivos**:
- Consultar información de los clubes (actividades, miembros, unidades, registros, etc.).
- Administación de clubes de nivel campo local, unión y división (según sea el caso).
- Generación de reportes y estadísticas.

**Frustraciones**:
- Los procesos administrativos aún son en papel o hablados.
- La generación de reportes es manual.
- No existe un proceso para autorizar o rechazar especialidades, investiduras, etc.

**Comportamiento**:
- Solo usan páginas y aplicaciones móviles de consultas.
- No usan aplicaciones móviles para gestionar su información.
- La mayoría de la información es gestionada manualmente por los administrativos.

---

### Segmentos de Mercado

* Estimación solo a los miembros de la unión mexicana interoceanica.
| Segmento | Tamaño | Prioridad | Características |
|----------|--------|-----------|-----------------|
| Miembros de clubes y directivos | 8500 | Alta | Miembros de club de cada tipo. |
| Coordinadores | 40 | Media | Coordinadores de cada campo local. |
| Administrativos | 24 | Baja | Administrativos de cada campo local y unión. |

---

## Características Clave

### Features Core (MVP)

> Funcionalidades absolutamente esenciales sin las cuales el producto no funciona

1. **Módulo de autenticación**
   - **Descripción**: Permite a los usuarios autenticarse en el sistema.
   - **Por qué es core**: Es esencial para que el usuario pueda acceder al sistema.
   - **User Story**: Como usuario, quiero que pueda autenticarme, registrarme o recuperar mi contraseña para acceder al sistema.

2. **Post-registro**
   - **Descripción**: Permite a los usuarios completar su registro en el sistema con su información personal, sus datos de contacto y el club al que pertenezco para acceder y usar el sistema, este proceso solo se realiza una vez.
   - **Por qué es core**: Es esencial para que el usuario pueda acceder al sistema.
   - **User Story**: Como usuario, quiero que pueda completar mi registro con mi información personal, mis datos de contacto y el club al que pertenezco para acceder y usar el sistema.

3. **Perfil de usuario**
   - **Descripción**: Permite a los usuarios gestionar su perfil en el sistema. Permite al usuario actualizar su información personal, sus datos de contacto, el club al que pertenece, además de agregar sus especialidades, clases investidas y medallas. Otros usuarios pueden ver su perfil.
   - **Por qué es core**: Es esencial para que el usuario pueda crear su historial digital en el sistema.
   - **User Story**: Como usuario, quiero que pueda gestionar la información personal y de mi trayecto en los clubes dentro de mi perfil en el sistema.

4. **Actividades - Administrativos del club**
   - **Descripción**: Permite a los usuarios administrativos del club gestionar las actividades en el sistema. Permite al usuario agregar, editar y eliminar actividades. Los miembros de ese tipo de club pueden ver las actividades y confirmar asistencia..
   - **Por qué es core**: Es escencial para registrar las actividades de cada tipo de club a fin de mantener informados a todos los miembros.
   - **User Story**: Como usuario, quiero gestionar las actividades de mi club para que pueda mantener informados a todos los miembros.

5. **Actividades - Miembros de club**
   - **Descripción**: Permite a los usuarios miembros de club consultar las actividades en el sistema.
   - **Por qué es core**: Es escencial para que los miembros de club puedan ver las actividades y confirmar asistencia.
   - **User Story**: Como usuario, quiero ver las actividades de mi club para que pueda confirmar mi asistencia.

6. **Gestionar miembros del club - Administrativos del club**
   - **Descripción**: Permite a los usuarios administrativos del club gestionar los miembros del club en el sistema. Permite al usuario aceptar, rechazar y eliminar miembros del club.
   - **Por qué es core**: Es escencial para que los administrativos del club puedan gestionar los miembros del club.
   - **User Story**: Como usuario miembro del club, quiero gestionar los miembros del club para que pueda confirmar su asistencia en las actividades.

7. **Gestionar cargos del club - Administrativos del club**
   - **Descripción**: Permite a los usuarios administrativos del club gestionar los cargos que tendrá un usuario en el sistema. Esto solo aplica para aspirantes o guías mayores.
   - **Por qué es core**: Es escencial para asignar cargos a los guías mayores.
   - **User Story**: Como usuario administrativo del club, quiero gestionar las asignaciones de cargos del club para que pueda asignar a los guías mayores.

8. **Gestionar Finanzas del club - Administrativos del club**
   - **Descripción**: Permite a los usuarios administrativos del club gestionar las finanzas del club en el sistema. Permite al usuario agregar, editar finanzas del club. Solo el director del club podrá eliminar registros de gastos o ingresos pero deberá de ingresar un motivo para justificar la eliminación.
   - **Por qué es core**: Es escencial para gestionar las finanzas del club.
   - **User Story**: Como usuario administrativo del club, quiero gestionar las finanzas del club para registrar los ingresos y egresos del mismo.

9. **Gestionar Inventarios del club - Administrativos del club**
   - **Descripción**: Permite a los usuarios administrativos del club gestionar los inventarios del club en el sistema. Permite al usuario agregar, editar inventarios del club. Solo el director del club podrá eliminar registros de inventarios pero deberá de ingresar un motivo para justificar la eliminación.
   - **Por qué es core**: Es escencial para gestionar los inventarios del club.
   - **User Story**: Como usuario administrativo del club, quiero gestionar los inventarios del club para registrar los inventarios del mismo.

10. **Registro de avance en clases - Miembros del club**
   - **Descripción**: Permite a los usuarios miembros del club registrar el avance de los requisitos de su clase. El sistema está inspirado en Google Classroom/Microsoft Teams y organiza las clases en un catálogo estructurado con:
     - **Aventureros (4-9 años)**: 6 clases por edad (Abejitas Laboriosas 4años, Rayitos de Sol 5años, Constructores 6años, Manos Ayudadoras 7años, Exploradores 8años, Caminantes 9años)
     - **Conquistadores (10-15 años)**: 6 clases por edad (Amigo 10años, Compañero 11años, Explorador 12años, Orientador 13años, Viajero 14años, Guía 15años)
     - **Guías Mayores (16-99 años)**: 2 clases (Guía Mayor, Guía Mayor Avanzado [histórica])
   - **Reglas de inscripción**:
     - Aventureros/Conquistadores solo pueden cursar la clase correspondiente a su edad actual
     - Guías Mayores **investidos** pueden cursar clases de cualquier tipo de club que NO tengan investidas (sin requisito de edad)
   - Los miembros pueden subir evidencias (fotos, documentos) y marcar actividades como completadas.
   - **Por qué es core**: Es esencial para registrar el avance en la clase del miembro del club con reglas de edad y tipo de club correctas.
   - **User Story**: Como usuario miembro del club, quiero registrar las actividades y avance en los requisitos de mi clase correspondiente a mi edad (Aventureros/Conquistadores) o de las clases que no tenga investidas (Guías Mayores investidos).

11. **Registro de avance en clases - Consejeros del club**
   - **Descripción**: Permite a los usuarios consejeros del club registrar, revisar, autorizar y rechazar el avance de los miembros de la clase que tiene asignada. El sistema funciona de manera similar a Google Classroom:
     - **Catálogos**: Las clases se organizan según el tipo de club:
       - Aventureros: 6 clases por edad (4-9 años)
       - Conquistadores: 6 clases por edad (10-15 años)
       - Guías Mayores: 2 clases (Guía Mayor + GM Avanzado histórica)
     - **Inscripciones**: Los directores inscriben miembros en clases según:
       - Aventureros/Conquistadores: Edad actual del miembro (automático)
       - Guías Mayores: Manual, sin requisito de edad
       - Guías Mayores investidos: Pueden inscribirse en clases de otros tipos que NO tengan
     - **Evaluación**: El consejero puede aprobar/rechazar cada apartado. Los apartados suman al módulo y determinan si se completa
     - **Asistencias**: El consejero registra hasta 2 puntos de asistencia/conducta por semana
     - **Estado final**: Al completar todos los módulos, el miembro obtiene estado "Investido". Si no completa todos pero avanzó, obtiene "Avanzado"
     - **Histórico**: Al finalizar el año eclesiástico, todos los registros se marcan como históricos y se inhabilitan para edición
   - **Por qué es core**: Es esencial para gestionar clases con reglas de edad y tipo de club correctas.
   - **User Story**: Como consejero del club, quiero validar el avance en los requisitos de los miembros de mi clase, respetando que Aventureros/Conquistadores solo cursen su clase por edad y que Guías Mayores investidos puedan cursar clases de otros tipos.

12. **Recursos - Miembros del club**
   - **Descripción**: Permite a los usuarios miembros del club consultar los recursos del club.
   - **Por qué es core**: Es escencial para que los miembros del club puedan ver los recursos del club.
   - **User Story**: Como usuario miembro del club, quiero ver los recursos del club para que pueda acceder a ellos.

13. **Unidades**
   - **Descripción**: Permite a los usuarios administrativos del club gestionar las unidades del club en el sistema. Permite al usuario agregar, editar y eliminar unidades (siempre y cuando no tenga miembros asignados). Solo el director del club podrá eliminar unidades pero deberá de ingresar un motivo para justificar la eliminación.
   - **Por qué es core**: Es escencial para que los administrativos del club puedan gestionar las unidades del club.
   - **User Story**: Como usuario administrativo del club, quiero gestionar las unidades del club para que pueda registrar las unidades del club.

14. **Gestión de Altas/Bajas de Miembros - Administrativos del club**
   - **Descripción**: Permite a los usuarios registrarse en el sistema mediante la app móvil con correo, contraseña y datos personales (país, unión, campo local, edad, tipo de sangre, contactos de emergencia, etc.). Los nuevos usuarios deben ser validados por el director del club antes de poder participar. No existen bajas definitivas; los usuarios pasan a un estado "inactivo", permitiéndoles acceder al sistema pero no participar en actividades.
   - **Por qué es core**: Es esencial para controlar quién tiene acceso activo al club y mantener un historial completo de todos los miembros, incluso los inactivos.
   - **User Story**: Como director del club, quiero validar o rechazar nuevas solicitudes de registro y gestionar el estado activo/inactivo de los miembros para mantener control sobre la membresía del club.

15. **Sistema de Puntos Semanal - Consejeros y Administrativos**
   - **Descripción**: Permite a los consejeros registrar hasta 2 puntos de asistencia/conducta por semana para cada miembro de su unidad. El sistema acumula puntos para determinar el "miembro del mes" y otorgar la barra de buena conducta.
   - **Por qué es core**: Es esencial para motivar la participación activa de los miembros y reconocer su esfuerzo mediante un sistema gamificado.
   - **User Story**: Como consejero, quiero registrar los puntos semanales de mis miembros para reconocer su asistencia y buena conducta, y como miembro quiero ver mi progreso para obtener la barra de buena conducta.

16. **Gestión de Seguros - Administrativos del club**
   - **Descripción**: Permite a los administrativos del club controlar qué miembros cuentan con seguro activo para participar en actividades y camporees. El sistema debe alertar cuando un seguro esté próximo a vencer o cuando un miembro sin seguro intente registrarse a una actividad de riesgo.
   - **Por qué es core**: Es esencial para la seguridad legal del club y protección de los miembros durante actividades.
   - **User Story**: Como director del club, quiero gestionar los seguros de mis miembros para garantizar que todos estén protegidos durante las actividades y campamentos.

17. **Carpeta de Evidencias Digital - Miembros y Consejeros**
   - **Descripción**: Permite a los miembros y consejeros registrar evidencias (fotos, documentos, notas) de actividades realizadas en campamentos y actividades especiales. Los consejeros pueden revisar y validar estas evidencias antes del campamento para ahorrar tiempo y material físico.
   - **Por qué es core**: Es esencial para eliminar la dependencia del papel durante campamentos y agilizar las revisiones previas.
   - **User Story**: Como miembro del club, quiero subir evidencias digitales de mis actividades para que mi consejero las revise antes del campamento, y como consejero quiero validar evidencias de manera digital para optimizar el tiempo en el campamento.

18. **Gestión de Años Eclesiásticos - Administrativos**
   - **Descripción**: Permite a los administrativos de campo local, unión y división gestionar los períodos eclesiásticos (años de club). Al finalizar un año, todos los registros se marcan como históricos y se crea un nuevo período. Los miembros pueden inscribirse en clases según el año eclesiástico activo.
   - **Por qué es core**: Es esencial para organizar la información por períodos y permitir análisis históricos del club.
   - **User Story**: Como administrador de campo local, quiero gestionar los años eclesiásticos para mantener organizados los registros históricos y permitir nuevas inscripciones cada año.

19. **Selección de Tipo de Club - Miembros**
   - **Descripción**: Permite a los miembros navegar entre diferentes tipos de club (Aventureros, Conquistadores, Guías Mayores) si pertenecen a más de uno, ya sea como miembro regular o como consejero. La interfaz debe cambiar según el tipo de club seleccionado.
   - **Por qué es core**: Es esencial para soportar miembros que participan en múltiples clubes con diferentes roles.
   - **User Story**: Como miembro que es conquistador y consejero de aventureros, quiero poder cambiar fácilmente entre mis clubes para acceder a la información relevante de cada uno.

20. **Transiciones de Directivas - Administrativos del club**
   - **Descripción**: Permite facilitar el cambio de administración del club al final de cada período. El sistema debe generar reportes de inventarios, finanzas y estado general del club para entregar a la nueva directiva. Los roles administrativos se pueden transferir manteniendo un historial de quién tuvo cada cargo.
   - **Por qué es core**: Es esencial para asegurar continuidad en la administración del club y evitar pérdida de información durante cambios de liderazgo.
   - **User Story**: Como director saliente del club, quiero generar un reporte completo de inventarios, finanzas y estado del club para entregarlo a la nueva directiva de manera ordenada.

### Features Importantes (Nice-to-Have)

> Funcionalidades que mejoran significativamente la experiencia

1. **Sistema de Notificaciones Push**: Alertas para actividades próximas, validaciones pendientes, seguros por vencer, y mensajes del club.
2. **Estadísticas y Dashboard del Club**: Visualización gráfica de asistencias, avances en clases, estado financiero, y comparativas históricas.
3. **Exportación de Reportes en PDF**: Generación de reportes mensuales, anuales y de campamentos en formato PDF para imprimir o compartir.
4. **Sistema de Mensajería Interna**: Chat entre miembros del club, directiva y consejeros para coordinación de actividades.
5. **Galería de Fotos del Club**: Repositorio compartido de fotos de actividades y campamentos con capacidad de etiquetar miembros.
6. **Calendario Integrado**: Vista de calendario con todas las actividades, reuniones y campamentos del club.
7. **Modo Offline**: Capacidad de consultar información básica y registrar puntos/asistencias sin conexión a internet, con sincronización posterior.

### Features Futuras (Roadmap)

> Ideas para versiones posteriores

1. **Cambio de Club entre Campos Locales**: Permitir que los miembros soliciten transferencia de un club a otro, con validación de ambos directores. No es MVP porque requiere flujos de aprobación complejos entre múltiples campos.

2. **Catálogo de Instructores Externos**: Directorio de instructores certificados para especialidades específicas, con sistema de reservas y calificaciones. No es MVP porque es una funcionalidad avanzada que requiere gestión de terceros.

3. **Generación Automática de Reportes Mensuales**: El sistema genera automáticamente los reportes requeridos por el campo local basándose en la actividad registrada. No es MVP porque requiere conocer los formatos exactos de cada campo.

4. **Certificados de Camporee Automáticos**: Generación y firma digital de certificados de participación en camporees basados en evidencias validadas. No es MVP porque requiere integración con sistemas de firma digital.

5. **Ranking de Clubes por Niveles**: Sistema de gamificación donde los clubes pueden alcanzar niveles (Cobre, Plata, Oro, Platino, Diamante) basándose en métricas de participación, especialidades completadas y actividades realizadas. No es MVP porque requiere definir criterios complejos de evaluación.

6. **Maestrías de Especialidades**: Registro y validación de maestrías (versión avanzada) de especialidades para guías mayores. No es MVP porque es una funcionalidad para usuarios avanzados que representa un pequeño porcentaje.

7. **Certificaciones de Guías Mayores**: Sistema de gestión de certificaciones oficiales para instructores y líderes de clubes. No es MVP porque requiere integración con entes certificadores externos.

8. **Integración con Sistemas Financieros**: Conexión con pasarelas de pago para cuotas del club, compra de uniformes e inscripciones a campamentos. No es MVP porque agrega complejidad de compliance financiero.

9. **App para Padres/Tutores**: Aplicación complementaria para que los padres puedan ver el progreso de sus hijos, autorizar actividades y recibir notificaciones. No es MVP porque es un usuario adicional que duplica el esfuerzo de desarrollo.

10. **Sistema de Votaciones y Encuestas**: Herramienta para que los clubes realicen votaciones digitales para elección de directivas o toma de decisiones. No es MVP porque no es crítico para las operaciones básicas del club.

---

## Objetivos de Negocio

### Objetivos Corto Plazo (3-6 meses)

1. **Lanzar MVP en la Unión Mexicana Interoceánica**
   - Métrica de éxito: Número de clubes registrados en el sistema
   - Target: 50 clubes activos (20% de los 250 clubes estimados)

2. **Alcanzar adopción inicial de miembros**
   - Métrica de éxito: Usuarios activos mensuales (MAU)
   - Target: 1,500 miembros registrados (18% del mercado objetivo de 8,500)

3. **Validar funcionalidades core con usuarios reales**
   - Métrica de éxito: Tasa de retención semanal
   - Target: 60% de usuarios que regresan semana a semana

4. **Capacitar coordinadores de campo local**
   - Métrica de éxito: Número de coordinadores capacitados
   - Target: 30 coordinadores capacitados (75% de los 40 totales)

### Objetivos Mediano Plazo (6-12 meses)

1. **Expansión a toda la Unión Mexicana Interoceánica**: Alcanzar 200+ clubes registrados (80% del mercado objetivo) y 6,000+ miembros activos.

2. **Implementar features Nice-to-Have críticos**: Sistema de notificaciones push, dashboard con estadísticas, y exportación de reportes en PDF.

3. **Estabilidad y rendimiento**: Alcanzar 99.5% uptime, <300ms de latencia p95, y <0.5% error rate.

4. **Validar modelo operativo**: Generar procesos documentados para onboarding de nuevos clubes y capacitación de administradores.

5. **Preparar expansión regional**: Definir roadmap de expansión a otras uniones de la División Interamericana.

### Objetivos Largo Plazo (1-3 años)

1. **Expansión a toda la División Interamericana**: Alcanzar presencia en México, Centroamérica y el Caribe con 5,000+ clubes registrados.

2. **Convertirse en plataforma oficial**: Ser adoptado como sistema oficial de la División Interamericana para gestión de clubes adventistas.

3. **Ecosistema completo**: Implementar features avanzadas como ranking de clubes, maestrías de especialidades, y app para padres/tutores.

4. **Sostenibilidad financiera**: Alcanzar $500/mes en ingresos para cubrir costos de infraestructura y mantenimiento mediante donaciones o apoyo institucional.

5. **Impacto medible**: Reducir en 70% el tiempo dedicado a tareas administrativas en los clubes, permitiendo más tiempo para actividades formativas.

---

## Métricas de Éxito

### Métricas de Producto

| Métrica | Definición | Objetivo | Actual | Frecuencia |
|---------|------------|----------|--------|------------|
| DAU/MAU | Daily/Monthly Active Users | 300 | 1 | Diaria |
| Retention Rate | % usuarios que vuelven | 80% | 1% | Semanal |
| Feature Adoption | % que usa feature X | 100% | 1% | Mensual |
| NPS | Net Promoter Score | 100 | 1 | Trimestral |

### Métricas de Negocio

| Métrica | Definición | Objetivo | Actual | Frecuencia |
|---------|------------|----------|--------|------------|
| Revenue | Ingresos mensuales | $300 | $0 | Mensual |
| CAC | Customer Acquisition Cost | $50 | $0 | Mensual |
| LTV | Lifetime Value | $100 | $0 | Trimestral |
| Churn Rate | % cancelaciones | <10% | 0% | Mensual |

### Métricas Técnicas

| Métrica | Definición | Objetivo | Actual |
|---------|------------|----------|--------|
| Uptime | Disponibilidad del servicio | 99.9% | 60% |
| Response Time | p95 latencia API | <500ms | 1400ms |
| Error Rate | % requests con error | <1% | 10% |

---

## Competencia

### Análisis Competitivo

> **Nota Importante**: No existe una solución específica para clubes adventistas (Conquistadores, Aventureros, Guías Mayores) con gestión de especialidades, investiduras y años eclesiásticos. Los competidores listados son aplicaciones genéricas de gestión de ministerio juvenil cristiano que podrían adaptarse parcialmente.

#### Grow Youth Ministry App

**Fortalezas**:
- Sistema robusto de check-in y tracking de asistencia con múltiples métodos (QR, barcodes, tablets)
- Base de datos CRM completa para estudiantes, voluntarios y padres
- Funcionalidades de currículos y grupos pequeños bien desarrolladas
- Reportes automáticos de asistencia y estadísticas

**Debilidades**:
- **No especializado en clubes adventistas**: No tiene concepto de especialidades, clases progresivas, o investiduras
- Enfocado en ministerio juvenil general, no en clubes estructurados por edades
- No maneja años eclesiásticos ni históricos de trayectoria multi-año
- Modelo de suscripción costoso (~$50-100/mes) no viable para campos locales

**Cómo Nos Diferenciamos**:
- SACDIA es específico para clubes adventistas con 6 clases progresivas, especialidades, investiduras, y unidades
- Gestionamos carpeta de evidencias digital para campamentos
- Sistema gratuito con soporte institucional vs modelo de suscripción
- Flujo de validación de especialidades por niveles (consejero → director → coordinador → campo local)

---

#### MinHub Youth

**Fortalezas**:
- Automatización de tareas administrativas para pastores juveniles
- Gestión de eventos y tracking de estudiantes
- Grupos inteligentes (smart groups) para segmentación automática
- Interfaz moderna y fácil de usar

**Debilidades**:
- **No tiene gestión de inventarios ni finanzas**: Funcionalidades críticas para clubes adventistas
- No maneja sistema de puntos semanales, barra de buena conducta, o "miembro del mes"
- Sin concepto de transiciones de directivas o años eclesiásticos

**Cómo Nos Diferenciamos**:
- SACDIA integra finanzas, inventarios, seguros, y transiciones administrativas en una sola plataforma
- Sistema de puntos gamificado con reconocimientos
- Gestión completa de años eclesiásticos con generación automática de históricos

---

#### ChurchTrac (Módulo de Youth Ministry)

**Fortalezas**:
- Plataforma completa de gestión de iglesia con módulo juvenil incluido
- Check-in robusto con múltiples opciones
- Gestión de voluntarios y scheduling
- App móvil personalizable

**Debilidades**:
- **Demasiado genérico**: Sistema de gestión iglesia adaptado a juventud, no específico para clubes
- No tiene concepto de especialidades, clases progresivas, maestrías, o investiduras
- Sin gestión de campamentos ni carpeta de evidencias digital
- Caro ($50-150/mes según tamaño)

**Cómo Nos Diferenciamos**:
- SACDIA es 100% especializado en clubes adventistas vs módulo genérico
- Gestión completa de campamentos con evidencias digitales validadas
- Sistema de evaluación de clases inspirado en Google Classroom
- Modelo gratuito accesible para cualquier club

---

### Matriz Competitiva

| Feature | SACDIA | Grow Youth | MinHub | ChurchTrac |
|---------|--------|------------|--------|------------|
| Gestión de Asistencia | ✅ | ✅ | ✅ | ✅ |
| Base de Datos Miembros | ✅ | ✅ | ✅ | ✅ |
| Especialidades | ✅ | ❌ | ❌ | ❌ |
| Clases Progresivas | ✅ | ❌ | ❌ | ❌ |
| Investiduras | ✅ | ❌ | ❌ | ❌ |
| Gestión Finanzas | ✅ | ❌ | ❌ | ⚠️ |
| Gestión Inventarios | ✅ | ❌ | ❌ | ❌ |
| Gestión Seguros | ✅ | ❌ | ❌ | ❌ |
| Carpeta Evidencias | ✅ | ❌ | ❌ | ❌ |
| Sistema Puntos | ✅ | ❌ | ❌ | ❌ |
| Años Eclesiásticos | ✅ | ❌ | ❌ | ❌ |
| Transiciones Directivas | ✅ | ❌ | ❌ | ❌ |
| App Móvil + Web | ✅ | ✅ | ✅ | ✅ |
| Modo Offline | ✅ | ⚠️ | ❌ | ❌ |
| **Precio** | **Gratis** | $50-100/mes | $30-70/mes | $50-150/mes |

**Conclusión**: SACDIA no tiene competencia directa en el mercado de clubes adventistas.

---

## Modelo de Negocio

### Monetización

**Modelo**: **Gratuito con Soporte Institucional**

SACDIA es una plataforma diseñada para servir al Ministerio Juvenil Adventista, por lo tanto **NO tiene costo para los clubes ni para los miembros**. El modelo de sostenibilidad financiera está basado en:

#### Financiamiento Institucional
- **Responsable**: División Interamericana, Uniones, y Campos Locales
- **Cobertura**: Infraestructura en la nube (Supabase, Vercel, servicios de email)
- **Presupuesto estimado**: $20-50/mes para servir a 200+ clubes
- **Justificación**: Reduce significativamente los costos operativos de los campos locales al digitalizar procesos administrativos

#### Servicios Premium (Opcional - Futuro)
Para funcionalidades avanzadas que generan costos adicionales:

**Certificados Físicos Personalizados**:
- Costo: $3-5 USD por certificado impreso y enviado
- Target: Miembros que requieran duplicados físicos de certificados de investidura o especialidades
- Justificación: Cubre costos de impresión profesional y envío

**Reportes Personalizados Avanzados**:
- Costo: $10-20 USD por reporte
- Target: Clubes que requieran análisis estadísticos personalizados para presentaciones o auditorías
- Justificación: Tiempo de desarrollo personalizado

### Proyección de Costos e Ingresos

| Período | Usuarios/Clubes | Costo Infraestructura | Donaciones/Soporte Institucional | Balance |
|---------|------------------|----------------------|----------------------------------|---------|
| Mes 3   | 50 clubes / 1,500 usuarios | $18/mes | $0 (fase piloto) | -$18 |
| Mes 6   | 100 clubes / 3,000 usuarios | $25/mes | $50/mes (campo local) | +$25 |
| Año 1   | 200 clubes / 6,000 usuarios | $40/mes | $100/mes (unión) | +$60 |

**Sostenibilidad a Largo Plazo**:
- Presupuesto solicitado a la División Interamericana: $500/mes
- Cubre: Infraestructura para 5,000+ clubes, desarrollo continuo, y soporte técnico
- ROI para la iglesia: Ahorro estimado de $2,000+/mes en procesos administrativos manuales


---

## Restricciones y Consideraciones

### Restricciones de Negocio

1. **Presupuesto**: $0 para desarrollo inicial (proyecto de tesis/portafolio personal). Infraestructura cloud limitada a tier gratuito de Supabase y Vercel (~$0-20/mes).
2. **Timeline**: Lanzar MVP en 6 meses (Q1-Q2 2026). Beta con clubes piloto en abril 2026, lanzamiento público julio 2026.
3. **Equipo**: 3 personas disponibles:
   - 1 Product Owner / Tech Lead (desarrollo full-time)
   - 1 Designer (UX/UI part-time)
   - 1 Consultor de dominio (coordinador de campo local, asesoría sobre procesos de clubes)

### Consideraciones Regulatorias

- **GDPR (Europa)**: Aunque el enfoque inicial es Latinoamérica, consideraremos principios GDPR para buenas prácticas: consentimiento explícito para datos de menores, derecho al olvido (estado inactivo), y exportación de datos personales.

- **LFPDPPP (México)**: Ley Federal de Protección de Datos Personales en Posesión de Particulares.
  - Aviso de privacidad claro y accesible
  - Consentimiento para tratamiento de datos de menores (requiere autorización de padres/tutores para menores de 18)
  - Medidas de seguridad para datos sensibles (tipo de sangre, contactos de emergencia)
  - Derecho ARCO (Acceso, Rectificación, Cancelación, Oposición)

- **Protección de Menores**: Datos de contactos de emergencia, fotos, y evidencias de actividades requieren consentimiento de padres/tutores para menores de edad. Implementaremos flujo de autorización durante el registro.

### Consideraciones Éticas

- **Privacidad**: Datos de menores serán manejados con máxima seguridad. Fotos y evidencias solo visibles para miembros del club y consejeros asignados. No se compartirá información personal fuera del contexto del club sin consentimiento explícito. Encriptación en tránsito y en reposo.

- **Transparencia**: 
  - Los miembros pueden ver todo su historial y quién ha validado sus logros
  - Los padres/tutores tendrán acceso a ver el progreso de sus hijos menores
  - Auditoría completa de cambios administrativos (quién modificó qué y cuándo)
  - Política de privacidad en lenguaje claro, sin jerga legal

- **Accesibilidad**: 
  - Compromiso con WCAG 2.1 nivel AA mínimo
  - Contraste de colores adecuado para usuarios con daltonismo
  - Textos claros para usuarios con nivel técnico principiante
  - Soporte offline para áreas con conectividad limitada
  - Interfaz en español (idioma nativo de la audiencia)

---

## Principios de Producto

### Valores que Guían Nuestras Decisiones

1. **Simplicidad sobre Complejidad**
   - **En práctica**: Interfaces intuitivas que no requieren capacitación técnica. Un miembro de 10 años debe poder navegar el sistema sin ayuda.
   - **Trade-off**: Sacrificamos funcionalidades avanzadas si agregan complejidad innecesaria a la experiencia base.

2. **Accesibilidad para Todos los Niveles**
   - **En práctica**: Diseño pensado para usuarios con nivel técnico principiante. Textos claros, iconos descriptivos, y flujos guiados paso a paso.
   - **Trade-off**: Evitamos shortcuts avanzados o atajos de teclado que podrían confundir a usuarios principiantes.

3. **El Historial es Sagrado**
   - **En práctica**: Nunca eliminamos datos, solo marcamos como inactivos o históricos. Los registros de especialidades, clases e investiduras son permanentes.
   - **Trade-off**: Mayor complejidad en la base de datos y más espacio de almacenamiento, pero garantizamos integridad del historial del miembro.

4. **Offline-First cuando es Crítico**
   - **En práctica**: Las funciones más usadas (consultar actividades, ver perfiles, registrar puntos) deben funcionar sin conexión y sincronizar después.
   - **Trade-off**: Arquitectura más compleja con manejo de conflictos de sincronización, pero garantizamos uso en áreas con conectividad limitada.

5. **Validación sobre Automatización Total**
   - **En práctica**: Las acciones importantes (aprobar especialidades, investiduras, cambios de estado) requieren validación humana por roles autorizados.
   - **Trade-off**: Procesos menos automáticos, pero mayor control de calidad y prevención de errores.

6. **Transparencia en la Información**
   - **En práctica**: Los miembros pueden ver su propio historial completo. Los consejeros ven el progreso de sus unidades. Los directores ven todo el club.
   - **Trade-off**: Sistema de permisos más complejo, pero garantizamos confianza mediante transparencia.

---

## User Experience Principles

### UX Core Tenets

1. **Claridad sobre Brevedad**
   - Ejemplo: Mejor una explicación clara de 2 líneas que un texto corto confuso. "Sube una foto de tu actividad para que tu consejero la valide" es mejor que "Evidencia requerida".

2. **No más de 3 Taps para Acciones Críticas**
   - Ejemplo: Registrar puntos de un miembro debe ser: seleccionar unidad → seleccionar miembro → agregar puntos. Máximo 3 interacciones.

3. **Feedback Inmediato y Visual**
   - Ejemplo: Cuando un consejero aprueba una actividad, el miembro ve inmediatamente una actualización visual con animación de éxito.

4. **Accesibilidad y Contraste**
   - Ejemplo: Todos los textos deben tener un contraste mínimo de 4.5:1. Iconos acompañados de texto para usuarios con daltonismo.

### Tone of Voice

**Personalidad de la Marca**:
- **Amigable y Cercano**: Usamos un lenguaje cálido y familiar, como si habláramos con un amigo del club.
- **Motivador**: Celebramos logros y animamos el progreso. "¡Ya casi completas tu clase!" en lugar de "Te faltan 3 requisitos".
- **Respetuoso**: Reconocemos que hablamos de una institución religiosa y mantenemos un tono apropiado sin ser formal en exceso.

**Ejemplo de Copy**:
- ✅ Bien: "¡Felicidades! Tu consejero aprobó tu especialidad de Primeros Auxilios. Ya está en tu historial."
- ❌ Mal: "Requisito #43 completado. Estado: Aprobado."

---

## Roadmap de Alto Nivel

### Q1 2026 (Enero - Marzo)
- [ ] Completar diseño de UI/UX para app móvil y panel web
- [ ] Desarrollar MVP: Autenticación, perfiles, actividades, y gestión de miembros
- [ ] Implementar sistema de clases y evaluación inspirado en Google Classroom
- [ ] Configurar infraestructura en Supabase y Vercel
- [ ] **Objetivo**: Tener un MVP funcional listo para pruebas internas con 2-3 clubes piloto

### Q2 2026 (Abril - Junio)
- [ ] Desarrollar features core restantes: unidades, finanzas, inventarios, seguros
- [ ] Implementar sistema de puntos semanal y carpeta de evidencias digital
- [ ] Beta testing con 10-15 clubes de la Unión Mexicana Interoceánica
- [ ] Capacitación de coordinadores de campo local
- [ ] Ajustes basados en feedback de usuarios piloto
- [ ] **Objetivo**: Validar product-market fit y alcanzar 50 clubes registrados

### Q3 2026 (Julio - Septiembre)
- [ ] Lanzamiento público en Unión Mexicana Interoceánica
- [ ] Implementar features nice-to-have: notificaciones push, dashboard estadísticas
- [ ] Optimización de rendimiento y estabilidad (objetivo 99.5% uptime)
- [ ] Crear documentación de usuario y videos tutoriales
- [ ] Soporte activo y resolución de bugs reportados
- [ ] **Objetivo**: Alcanzar 150 clubes registrados y 4,000+ miembros activos

### Q4 2026 (Octubre - Diciembre)
- [ ] Análisis de datos de uso y métricas de adopción
- [ ] Implementar mejoras basadas en 6 meses de uso real
- [ ] Preparar expansión: traducción a inglés, adaptación para otras uniones
- [ ] Desarrollo de features para año eclesiástico 2027
- [ ] Cierre de año eclesiástico 2026 y generación de históricos
- [ ] **Objetivo**: Consolidar 200+ clubes, preparar roadmap 2027 de expansión regional

---

## Stakeholders

| Rol | Nombre | Responsabilidad | Contacto |
|-----|--------|-----------------|----------|
| Product Owner | Abner Reyes | Priorización, visión | abner.reyes03@gmail.com |
| Tech Lead | Abner Reyes | Decisiones técnicas | abner.reyes03@gmail.com |
| Designer | Ivette Zúñiga | UX/UI | bessgilmore@gmail.com |

---

## Notas para IA

> Este archivo te ayuda a entender el contexto de negocio al implementar features

**Al desarrollar una feature, considera**:
- ¿Cómo esta feature ayuda a alcanzar los objetivos de negocio?
- ¿Qué user persona se beneficia más?
- ¿Cómo se alinea con nuestros principios de producto?
- ¿Qué métricas deberíamos trackear para validar éxito?

**Si una implementación técnica entra en conflicto con un principio de producto**:
- Menciona el conflicto al usuario
- Sugiere alternativas
- Explica trade-offs

**Ejemplos de decisiones informadas por este contexto**:
- Si "Simplicidad sobre Features" es un principio, prefiere soluciones simples aunque sean menos feature-rich
- Si "Usuarios Objetivo" son no técnicos, evita jerga técnica en UI
- Si "Privacidad" es crítica, sugiere encriptación end-to-end aunque sea más complejo

---

**Última actualización**: [2026-01-13]  
**Próxima revisión**: [2026-02-13]
