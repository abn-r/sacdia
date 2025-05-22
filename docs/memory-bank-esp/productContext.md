# Contexto del Producto de la Aplicación SACDIA

## Por Qué Existe Este Proyecto
SACDIA existe para proporcionar una herramienta digital para los clubes de jóvenes adventistas (Aventureros, Conquistadores, Guías Mayores) y su administración. Su objetivo es reemplazar los procesos manuales basados en papel con un sistema eficiente y centralizado.

## Problemas Que Resuelve
- Falta de sistemas de información centralizados para los clubes de jóvenes Adventistas.
- Pérdida de información actualmente gestionada en papel.
- Dificultad para unificar criterios para evaluar el progreso de los miembros (especialidades, clases, asistencia, desarrollo de clases, entre otros aspectos administrativos de los clubes).
- Tareas administrativas que consumen tiempo y distraen de las actividades principales del club.

## Cómo Debería Funcionar
La aplicación sigue un patrón de Arquitectura Limpia (aunque no se aplica estrictamente en todas partes todavía):
- **Capa de Presentación**: Interfaz de usuario de Flutter (Pantallas, Widgets).
- **Capa de Lógica de Negocio**: BLoC/Cubit (la idea es migrar todo a cubit) para la gestión del estado.
- **Capa de Datos**: Repositorios que abstraen las fuentes de datos.
- **Backend**: API personalizada de NestJS que interactúa con una base de datos PostgreSQL de Supabase.
- **Autenticación**: Supabase Auth para inicio de sesión con correo/contraseña y gestión de JWT.
- **Navegación**: GoRouter maneja el enrutamiento y la redirección basada en el estado de autenticación/post-registro.
- **Características Principales**: 
  - Registro de usuarios
  - Recopilación de datos post-registro
  - Visualización del perfil de usuario (incluyendo clases, roles, especialidades)
  - Tablero de inicio con opciones de menú basadas en roles.
  - Actividades

## Objetivos de Experiencia del Usuario
- Interfaz intuitiva, con animaciones y amigable para cada uno de los roles de la aplicación.
- Rendimiento rápido y receptivo.
- Navegación clara y jerarquía de información.
- Lenguaje de diseño consistente (basado en Material Design y Cupertino Desing con marca personalizada de SACDIA).
- Accesible para todos los usuarios.
- Contenido localizado (actualmente español - México, se espera que con el tiempo se agreguen más idiomas pero es muy a futuro).

## Características Clave (Implementadas y Planeadas)
- Autenticación de Usuario (Inicio de Sesión, Registro, Olvidé Contraseña y Cierre de Sesión)
- Stepper Post-Registro (Foto, Información Personal, Información del Club) importante para la construcción del perfil del usuario.
- *En proceso:* Visualización del Perfil de Usuario (Información Básica, Club, Rol, Clase, Estado de Bautismo, Estado de Investidura, clases cursadas, especialidades, información médica)
- *En proceso:*Tablero de Inicio con Menú Basado en Roles (mostrando opciiones para gestionar las partes de la aplicación)
- Cambio de Tema (Claro/Oscuro)
- *En proceso:*Selección de Tipo de Club (para que un usuario pueda manejar la información de distintos tipos de club a la vez en base a un rol de club) 
- *En Progreso:* Gestión de Actividades, Seguimiento de Especialidades, Edición Completa del Perfil, Opciones de Configuración, Gestión de Contactos de Emergencia (UI existe, lógica necesaria), la administración de los miembros del club, la gestión de finanzas, inventario, unidades y miembros de las mismas, progresión de clases.

## Audiencia Objetivo
- Miembros de Clubes de Jóvenes Adventistas (Aventureros, Conquistadores, Guías Mayores).
- Directores y diferentes cargos directivos de estos clubes.
- Administración de la Iglesia por campos locales, uniones y divisiones que supervisa los clubes.