# Resumen del Proyecto de la Aplicación SACDIA

## Descripción General del Proyecto
SACDIA (Sistema Administrativo de Clubes del Ministerio Juvenil Adventista) es una aplicación móvil basada en Flutter diseñada para apoyar a los miembros, directores y administración de los clubes juveniles adventistas (Aventureros, Conquistadores, Guías Mayores). Centraliza la información, optimiza los procesos administrativos y de gestión, y tiene como objetivo liberar tiempo para actividades de desarrollo.

## Requisitos Principales
- Versión del SDK de Flutter: >=3.6.1
- Plataformas objetivo: Android, iOS
- Repositorio centralizado de información para los miembros del club.
- Procesos administrativos y de gestión optimizados.
- Acceso y funciones basadas en roles (Director/a, Sub director/a, Secretario/a, Tesorero/a, Secretario/a-Tesorero/a, Consejero, Miembro y Coordinador).
- Proceso post-registro para recopilar datos esenciales del usuario.
- Gestión de la jerarquía del club (País > Unión > Campo Local > Club).
- Gestión del perfil de usuario (información personal, información médica, afiliación al club, clases, especialidades, roles).
- Cambio de tema (Claro/Oscuro).
- Localización en español (México).

## Arquitectura y Stack Técnico

- **Lenguaje**: Dart
- **Framework**: Flutter 3.19
- **Estilo de Arquitectura**: Clean Architecture + BLoC
- **Gestión de Estado**: flutter_bloc 9.0.0 (BLoC/Cubit)
- **API Client**: Dio 5.8.0+1
- **Autenticación**: Supabase Auth
- **Almacenamiento**: Supabase Storage
- **Base de Datos**: Supabase (PostgreSQL)
- **Enrutamiento**: go_router 14.7.2
- **Inyección de Dependencias**: get_it 8.0.3
- **Manejo de Imágenes**: image_picker (^1.1.2), image_cropper (^9.0.0), flutter_image_compress (^2.4.0)
- **Componentes de UI**: motion_tab_bar (^2.0.4), modal_bottom_sheet (^3.0.0), easy_date_timeline (^2.0.6), flutter_svg (^2.0.17)
- **Tipografía**: google_fonts (^6.2.1)
- **Localización**: intl (^0.19.0), flutter_localizations
- **Pruebas** (Dependencias presentes, implementación pendiente): flutter_test, bloc_test (^10.0.0), mocktail (^1.0.4)
- **Linting**: flutter_lints (^5.0.0)

## Objetivos del Proyecto
- Proporcionar una plataforma unificada para la gestión del club.
- Reducir la sobrecarga administrativa para los líderes del club.
- Mejorar la consistencia y accesibilidad de los datos.
- Ofrecer una experiencia móvil moderna y amigable para el usuario.

## Criterios de Éxito
- Alta tasa de adopción entre los clubes objetivo.
- Retroalimentación positiva de los usuarios (miembros y directores) sobre facilidad de uso y ahorro de tiempo.
- Reducción medible en tareas administrativas manuales.
- Aplicación estable y de alto rendimiento en las plataformas soportadas.
- Datos completos disponibles para informes y toma de decisiones (objetivo futuro).