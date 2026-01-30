# SACDIA

## MÓDULO: Autenticación

**Descripción:** Este módulo gestiona y verifica que cada usuario esté autenticado en la plataforma, de lo contrario gestiona que se registre o actualice sus datos de acceso.

---

## PROCESO 1: Inicio de Sesión
**Objetivo:** Permitir al usuario ingresar al sistema con credenciales propias.

**PASOS:**
1. El usuario ingresa a la aplicación.
2. La aplicación verifica si existe una sesión existente.
	1. Si la sesión existe se redirigie al usuario a la la validación del `post-registro`.
	2. Si la sesión no existe continúa el proceso.
3. El usuario ingresa su `correo` y `contraseña`
4. La app valida las credenciales usando los servicios de `supabase`.
5. La sesión que otorga `supabase` es almacenada en el dispositivo al igual que el token, este mismo servirá para usarlo en cada petición que se realice al la ==RESTAPI==.
6. En la aplicación y el panel web se deberán de almacenar el  `token`y el `uuid` del usuario en un almacenamiento seguro.

### Validaciones:
- Si en el navegador o la aplicación móvil no es posible resguardar los datos en un almacenamiento seguro esta funcionalidad deberá ser omitida para no comprometer los datos críticos del usuario.
- El backend valida al iniciar sesión si el usuario ya completo el post-registro, si no se ha completado (registro en la tabla users_pr al `user_id` del usuario el campo relacionado `complete` es `false`) se redirige al proceso de [post-registro], si ya esta completado la app redirige al usuario a la pantalla principal. La app recibe en ambos casos la respuesta del backend.

---

## PROCESO 2: Registro de usuarios
**Objetivo:** que los nuevos usuarios se puedan registrar con sus datos.

**PASOS:**
1. El usuario ingresa a la aplicación en la pantalla de login y selecciona la opción `Regístrate aquí!`
2. Se muestra un formulario donde se tendrá que ingresar los siguientes campos:
	1. Nombre
	2. Apellido paterno
	3. Apellido materno
	4. Correo
	5. Contraseña
	6. Confirmar contraseña
3. Deberá presionar el botón `Registrar`para activar la llamada al endpoint de registro.
4. El endpoint de registro sigue los siguientes pasos:
	1. Toma los datos y usa el método de supabase para crear un nuevo usuario.
	2. Toma el dato de `uuid` junto a los demás datos y ejecuta un procedimiento almacenado que guarda la información ingresada por el usuario, estos se almacenan de la siguiente manera:
		1. Tabla users: Se almacena los datos de `uuid, nombre, apellido paterno, apellido materno y correo`.
		2. Tabla users_pr: Se almacena el registro del `uuid` del usuario y se pone el valor `complete` como `false`.
		3. Tabla users_roles: Se consulta el listado de roles y se consigue el `uuid`del rol `user`. Se crea en esta tabla el registro de relación entre el `uuid` del usuario y el `uuid` del rol seleccionado.
5. El servicio retorna el resultado de las operaciones.

### Validaciones
- Si el procedimiento para registrar al usuario falla en algún punto o no se logra almacenar en alguna de las tablas mencionadas se debe de revertir todas las acciones realizadas y confirmar que no quede rastro en las tablas y en supabase de este registro fallido.
- Se deberá de registrar en una tabla de `log`los fallos del registro y sus detalles.

---

## PROCESO 3: Recuperar Contraseña
**Objetivo:** 

**PASOS:**
1. 1. El usuario ingresa a la aplicación en la pantalla de login y selecciona la opción `Recuperala aquí!`
2. Se muestra un formulario donde se tendrá que ingresar su correo electrónico.
3. Deberá presionar el botón `Recuperar`para activar la llamada al endpoint de recuperar contraseña.
4. La aplicación llamará al servicio nativo de supabase para recuperar contraseña.
5. El servicio de supabase envía un correo de recuperación al usuario el cual deberá de seguir los pasos.
6. Se debe de almacenar en un `log` en base de datos todas las solicitudes de correos para recuperar contraseña.

---

## PROCESO 4: Cerrar sesión
**Objetivo:** 

**PASOS:**
1. El usuario en las configuraciones del `perfil`selecciona la opción `Cerrar sesión`.
2. La app sistema usará el servicio nativo de supabase para terminar la sesión del usuario.
3. Al realizar el cierre de sesión se deberá de borrar del almacenamiento seguro los datos de `token y uuid'.
4. Al cerrar la sesión se deberá de redirigir siempre al inicio de sesión.

---

# MÓDULO: Post-registro

**Descripción:** Este módulo solo se puede acceder después de que el usuario se registra. Este módulo tiene la funcionalidad de permitir al usuario cargar toda la información extra como su foto de perfil, datos personales, datos de contacto, datos de enfermedades o alergias, la selección del pais, unión, campo local, club y clase actual.

La idea es que sea un proceso tipo onboarding para ir paso a paso en los procesos de llenado.

Esta sección siempre deberá de contar con una sección siempre y enfatizo siempre en la parte inferior de la pantalla (sección estática) con los botones de `Regresar`y `Continuar`. Solo no se mostrará `Regresar`si estamos en la primer pantalla del proceso y no se mostrará `Continuar`si el proceso ya ha terminado.

**Considere**: Este proceso solo aplica para la aplicación móvil.

---

## PROCESO 1: Fotografía de perfil
**Objetivo:** Que el usuario cargue su fotografía usando su uniforme de gala de los clubes del Ministerio Juvenil Adventista.

Fotografía de perfil, aquí el usuario puede subir una foto o tomarla, la foto se debe de comprimir para que pese menos y recortarla en formato cuadrada.

**PASOS:**
1. La app solicitará al backend la información de:
	1. Si el usuario ya lleno la información de esta sección
	2. Si ya completo la sección la app muestra la siguiente sección de proceso 2 [Proceso 2: Información Personal]
2. La app bloquea la opción de `Continuar`.
3. La app muestra la primer pantalla del proceso que es la Fotografía de perfil.
4. El usuario selecciona la única opción `Elegir fotografía de perfil`
5. El app muestra al usuario las opciones:
	1. Tomar fotografía
	2. Seleccionar fotográfia
6. Si el usuario selecciono la opción `Tomar fotografìa`la app ejecutará el módulo de cámara del dispositivo (la aplicación deberá de tener los permisos del usuario para acceder a la cámara).
	1. Se procederá a tomar la fotografía. 
	2. La app mostrará la funcionalidad de `image_cropper` para comprimir la imagen a un 70% y recortarla con forma cuadrada.
7. Si el usuario selecciono la opción `Seleccionar fotografìa`la app ejecutará el módulo de `image_picker` (la aplicación deberá de tener los permisos del usuario para acceder a la biblioteca de imágenes del dispositivo) donde deberá de seleccionar una imagen a usar.
	1. La app tomará la imagen. 
	2. La app mostrará la funcionalidad de `image_cropper` para comprimir la imagen a un 70% y recortarla con forma cuadrada.
8. El usuario seleccionará la opción de `Confirmar imagen`, esta acción enviará al backend la solicitud de almacenar la fotografía (deberá de enviarse también en token y el uuid del usuario) en el bucket `profile-pictures` con el nombre en la siguiente estructura `photo-{uuid del usuario}`.`{extensión}`.
9. El backend regresara la respuesta del servicio y la app tomará la respuesta para mostrar si la fotografía fue o no almacenada correctamente.
10. Si la respuesta fue exitosa se desbloqueará la opción `Continuar`para que el usuario continue con la siguiente sección junto con esto la app envía al backend una solicitud para que registre que el usuario completo la primer parte del post-registro y no tenga que volver a llenarla si se sale de la aplicación o pierde conexión.
11. Si la respuesta fue con error el usuario deberá de volver a iniciar el proceso.
12. Al presionar `Continuar`el proceso termina y se da paso al proceso 2 [Proceso 2: Información Personal]

---

## PROCESO 2: Información Personal
**Objetivo:** Que el usuario ingrese su información personal, contactos de emergencia y seleccione si tiene enfermedades o alergias.

**PASOS:**
1. La app solicitará al backend la información de:
	1. Si el usuario ya lleno la información de esta sección 
	2. Si ya completo la sección la app muestra la siguiente sección de proceso 3 [Proceso 3: Selección Club]
	3. Contactos de emergencia de la tabla `emergency_contacts`
	4. Listado de enfermedades de la table `users_diseases`
	5. Listado de alergias de la tabla `users_allergies`
2. La app bloquea la opción de `Continuar`.
3. La app mostrará el formulario solicitando los siguientes datos personales: 
	1. Genero: El usuario selecciona su genero.
	2. Fecha de nacimiento: Selecciona la fecha.
		1. Si el usuario es menor de edad, se debe de agregar un `representante legal` (se espera que pueda seleccionar un tipo de representante legal, como `padre, madre, tutor`) y se almacene en una tabla de la base de datos aún por definir.
	3. Bautismo (booleano): Selecciona si es o no
		1. Fecha de bautismo: si selecciono que si es bautizado selecciona la fecha de bautismo.
	4. Contactos de emergencia: 
		1. Si el usuario ya tenía contactos de emergencia registrados se muestran en un listado dentro del formulario en dicha sección.
		2. Si requiere agregar más contactos 
		3. Al presionar esta opción se muestra una pantalla emergente en donde la app consulta al backend los tipos de relaciones de la tabla `relationship_type`.
		4. La app muestra el listado de contactos de emergencia registrados, se muestran las opciones de Agregar nuevo contacto al fondo de la pantalla (anclado) y en cada registro la opción de "Editar" y "Eliminar".
		5. Cuando se Agregue un nuevo contacto la app mostrará un formulario con los campos de `nombre`, `tipo de relación` y `teléfono`.
			1. Una vez ingresados podrá dar en la opción "Almacenar" para que la app envíe al Backend la solicitud para registrar al contacto de emergencia en la tabla `emergency_contacts`, depende del resultado será el mensaje que se muestre en la app.
		6. Cuando se elimine un contacto de emergencia la app solicitará la confirmación del usuario, la app enviará al Backend la solicitud para eliminar el contacto de emergencia, depende del resultado será el mensaje que se muestre en la app.
		7. Cuando se edite o actualice un  contacto la app mostrará un formulario con los campos de `nombre`, `tipo de relación` y `teléfono` mostrando la información que ya se tenía del contacto.
			1. Una vez ingresados los nuevos podrá dar en la opción "Almacenar" para que la app envíe al Backend la solicitud para registrar al contacto de emergencia, depende del resultado será el mensaje que se muestre en la app.
	5. Enfermedades: Se consultará del backend los datos de la tabla `diseases`, la app mostrará la información de las enfermedades en una lista pero deberá de agregar hasta arriba de la lista una opción `Ninguna`, además de incorporar un buscador para que se muestre hasta arriba de la pantalla. El usuario puede seleccionar una o más enfermedades, en el caso de seleccionar la opción de `Ninguna` se des seleccionaran los registros previamente seleccionados y si se selecciona alguna enfermedad esta opción se desactivará permitiendo seleccionar otras opciones.
		1. Una vez seleccionados los registros necesarios deberá de presionar la opción `Guardar`lo cual enviará al backend una solicitud a la tabla `users_diseases`.
		2. La app recibirá el mensaje de error o confirmación al registrar las enfermedades.
	6. Alergias: Se consultará del backend los datos de la tabla `allergies`, la app mostrará la información de las alergias en una lista pero deberá de agregar hasta arriba de la lista una opción `Ninguna`, además de incorporar un buscador para que se muestre hasta arriba de la pantalla. El usuario puede seleccionar una o más alergias, en el caso de seleccionar la opción de `Ninguna` se des seleccionaran los registros previamente seleccionados y si se selecciona alguna alergia esta opción se desactivará permitiendo seleccionar otras opciones.
		1. Una vez seleccionados los registros necesarios deberá de presionar la opción `Guardar`lo cual enviará al backend una solicitud a la tabla `users_allergies`.
		2. La app recibirá el mensaje de error o confirmación al registrar las alergias.
4. Si se ha registrado información en cada parte del formulario se desbloqueará la opción `Continuar` al presionar esta opción se envía al backend la solicitud para que se almacene la información en las siguientes tablas:
	1. Para el `genero, fecha de nacimiento, bautismo y fecha de bautismo` se almacenan en la tabla `users`.
	2. Los contactos de emergencia se almacenan en la tabla `emergency_contacts`.
	3. Las enfermedades se almacenan en la tabla  `users_diseases`.
	4. Las alergias se almacenan en la tabla  `users_allergies`.
5. Para que el usuario continue con la siguiente sección junto con esto la app envía al backend una solicitud para que registre que el usuario completo la segunda parte del post-registro y no tenga que volver a llenarla si se sale de la aplicación o pierde conexión.
6. Si la respuesta fue con error el usuario deberá de volver a iniciar el proceso.
7. Al presionar `Continuar`el proceso termina y se da paso al proceso 2 [Proceso 2: Información Personal]
### Validaciones:
- Los géneros solo serán 'Masculino' o 'Femenino'.
- En la fecha de nacimiento el usuario deberá de tener una edad mínima de 3 años y una edad máxima de 99 años, el sistema evaluara esto, no es un dato que se deba almacenar en base de datos.
- El formato de las fechas de será `YYYY-MM-DD`.
- Se espera que el usuario pueda agregar hasta 5 contactos de emergencia. Esto se debe de validar en el backend. 
- El usuario no podrá agregar contactos de emergencia que ya estén agregados y relacionados a el previamente. 
- Los contactos de emergencia podrán ser editados y eliminados (se necesita que se muestre un dialogo de confirmación y el backend realice un borrado lógico).

---

## PROCESO 3: Selección club
**Objetivo:** 

**PASOS:**
1. Al acceder a esta sección se consulta el listado de países, si solo existe un país se auto selecciona el único registro y el campo se deshabilitar para que el usuario no intente seleccionar otro, si existe más de un registro, el usuario tendrá la oportunidad de seleccionar el país.
2. Si el país fue auto seleccionado, se consultará automáticamente las uniones asociadas o relacionadas al país al igual que con los registros del país. Si el resultado sólo arroja un registro de unión sea auto seleccionará este registro el campo se deshabilitar para que los usuarios no intenta seleccionar otro, si existe más de un registro y usuario tendrá la oportunidad de seleccionar la unión. En el caso de qué si se haya seleccionado el registro del país, de igual manera se tendrá que consultar los registros de las uniones relacionadas del país y aplicar los mismos parámetros.
3. Si la unión fue auto seleccionada, se consultará automáticamente los campos locales asociadas o relacionadas a la unión al igual que con los registros de las uniones. Si el resultado sólo arroja un registro de campos locales sea auto seleccionará este registro el campo se deshabilitar para que los usuarios no intenta seleccionar otro, si existe más de un registro y usuario tendrá la oportunidad de seleccionar el campo local. En el caso de qué si se haya seleccionado el registro de la unión, de igual manera se tendrá que consultar los registros de los campos locales relacionados a la unión y aplicar los mismos parámetros.
4. Si el campo local fue auto seleccionado, se consultará automáticamente los clubes  asociados o relacionadas al campo local al igual que con los registros de los campos locales. Si el resultado sólo arroja un registro de clubes  se auto seleccionará este registro el campo se deshabilitara para que los usuarios no intenta seleccionar otro, si existe más de un registro y usuario tendrá la oportunidad de seleccionar el club. En el caso de qué si se haya seleccionado el registro del campo local, de igual manera se tendrá que consultar los registros de los clubes relacionados al campo local y aplicar los mismos parámetros.
5. Al seleccionar el club, el sistema consultará los tipos de club que tiene el club que ha seleccionado (aventureros, conquistadores o guías mayores) el usuario seleccionará el tipo de club a cual se requiere unir. En este diálogo de selección se deberá preseleccionar el tipo de club al que pertenece el usuario, es decir, si el usuario tiene de tres a nueve años de edad, se deberá preseleccionar el club de aventureros, si el usuario tiene de 10 a 15 años, deberá preseleccionar el club de conquistadores, y el usuario tiene más de 16 años, se verá preseleccionar el club de guías mayores, de igual manera se deberá demostrar un mensaje aconsejando en base a su edad, qué tipo de club debería seleccionar comentando que su aprobación estará sujeta a los directivos de cada club.
6. En base al tipo de club seleccionado, la aplicación consultará con el backend las clases que tiene relacionada el tipo de club que está seleccionado, de igual manera aplicarán los mismos condicionantes que en el tipo de club, se recomendará la clase en base a la edad a la que el usuario debería pertenecer.
7. Una vez registrado sólo los datos y habilitará la opción de continuar.
8. La aplicación enviará la solicitud al backend para que procede la información, ingresada.
	1. La información del país, unión, campo local en la tabla de `users`.
	2. La relación del usuario con el club se almacenará también en las tablas correspondientes.
	3. La inscripción del usuario en la tabla user_classes con los identificadores de la clase y el identificador único del usuario.
	4. Si los tres pasos anteriores se ejecutan correctamente el sistema, actualizar el estatus de la tabla users_pr en el campo Complete será `true`.
9. El backend enviará un mensaje confirmando si la acción fue terminada correctamente o hubo errores. Si terminó correctamente la aplicación redirigirá el usuario a la pantalla principal del sistema, y si hubo error, la aplicación permanecerá la pantalla actual, hasta que el usuario pueda terminar el proceso.
10. Una vez que el usuario ha completado el proceso de post registro en la base de datos, se guardará que el usuario completado el paso tres, para que no necesite repetirlo, al igual que los otros dos pasos.

### Validaciones:
- El usuario debe de seleccionar un club.
- El usuario debe de seleccionar un tipo de club.
- El usuario debe de seleccionar una clase.
- El usuario debe de seleccionar un campo local.
- El usuario debe de seleccionar una unión.
- El usuario debe de seleccionar un país.
- Si la consulta de países solo arroja un resultado este deberá de auto seleccionarse y bloquearse para que no pueda ser modificado.
- Si la consulta de uniones solo arroja un resultado este deberá de auto seleccionarse y bloquearse para que no pueda ser modificado.
- Si la consulta de campos locales solo arroja un resultado este deberá de auto seleccionarse y bloquearse para que no pueda ser modificado.
- El usuario solo podrá seleccionar un club.
- El usuario solo podrá seleccionar un tipo de club.
- El usuario solo podrá seleccionar una clase.
- El usuario solo podrá seleccionar un campo local.
- El usuario solo podrá seleccionar una unión.
- El usuario solo podrá seleccionar un pais.

Solo hasta que termina el post-registro el campo `complete` en la tabla `users_pr` se marca como `true`.