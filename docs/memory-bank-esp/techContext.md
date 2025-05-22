# Contexto Técnico de la Aplicación SACDIA

## Tecnologías Utilizadas
- Flutter SDK: ^3.6.1
- Dart SDK: ^3.6.1
- API Backend: NestJS (framework de Node.js)
- Base de Datos: PostgreSQL (alojada en Supabase)
- ORM: Prisma (usado en la API NestJS)
- Proveedor de Autenticación: Supabase Auth (Correo/Contraseña, JWT)
- Cliente HTTP: Dio (^5.8.0+1)
- Gestión del Estado: flutter_bloc (^8.1.4)
- Enrutamiento: go_router (^14.7.2)
- Inyección de Dependencias: get_it (^8.0.3)
- Manejo de Imágenes: image_picker (^1.1.2), image_cropper (^9.0.0), flutter_image_compress (^2.4.0)
- Almacenamiento Local: shared_preferences (^2.5.1)
- Dependencias Principales: equatable (^2.0.7), http_parser (^4.1.2), intl (^0.19.0), flutter_localizations
- Bibliotecas de UI: google_fonts (^6.2.1), motion_tab_bar (^2.0.4), modal_bottom_sheet (^3.0.0), easy_date_timeline (^2.0.6), flutter_svg (^2.0.17), cupertino_icons (^1.0.8)
- Utilidad: url_launcher (^6.3.1)

## Configuración de Desarrollo
1. **Requisitos del Entorno**:
    * Flutter SDK >= 3.6.1
    * Dart SDK >= 3.6.1
    * Android Studio / VS Code con extensiones de Flutter/Dart
    * Acceso al endpoint de la API NestJS (actualmente `http://127.0.0.1:3000` en `constants.dart`)
    * URL del proyecto Supabase y Clave Anónima (configurados en `main.dart`)
2. **Estructura del Proyecto**:
    * `lib/`: Código principal de la aplicación.
        * `core/`: Utilidades compartidas, widgets, servicios, constantes, router.
        * `features/`: Módulos que representan las características de la aplicación (auth, home, profile, user, post_register, club, activities, theme, main_layout).
            * Cada característica típicamente contiene subdirectorios como `bloc`/`cubit`, `models`, `repository`/`services`, `screens`/`presentation`, `widgets`.
        * `main.dart`: Punto de entrada de la aplicación, inicialización de Supabase, DI manual (actualmente), configuración de MultiBlocProvider, configuración de MaterialApp.router.
    * `test/`: Pruebas unitarias, de widgets y de integración (implementación pendiente).
    * `assets/`: Activos estáticos (imágenes, SVGs, íconos).
    * `memory-bank/`: Documentación del proyecto.
    * `pubspec.yaml`: Gestión de dependencias.
    * `.cursorrules`: Directrices para el asistente de IA.
    * `analysis_options.yaml`: Reglas del linter (`flutter_lints`).
3. **Archivos/Carpetas Clave**:
    * `lib/main.dart`: Punto de entrada y configuración raíz.
    * `lib/core/router/app_router.dart`: Lógica de enrutamiento.
    * `lib/core/http/api_client.dart`: Cliente HTTP centralizado con interceptores robustos para JWT y manejo de errores.
    * `lib/core/di/injection_container.dart`: Contenedor central de inyección de dependencias.
    * `lib/core/constants.dart`: Constantes de toda la aplicación (colores, URL de la API, rutas de activos).
    * `features/*/bloc/ | cubit/`: Lógica de gestión del estado.
    * `features/*/repository/ | services/`: Lógica de acceso a datos.
    * `pubspec.yaml`: Dependencias.

## Restricciones Técnicas
1. **Soporte de Plataformas**: Android, iOS.
2. **Dependencia del Backend**: Requiere que la API NestJS esté en ejecución y accesible.
3. **Dependencia de Supabase**: Requiere Supabase para autenticación y alojamiento de la base de datos.
4. **Mezcla de Gestión del Estado**: Necesidad de gestionar la coexistencia de patrones BLoC y Cubit.
5. ~~**DI Manual**: El enfoque actual de inyección de dependencias es manual y propenso a errores; se necesita migrar a `get_it`.~~

## Herramientas de Desarrollo
1. **IDE**: Android Studio / VS Code.
2. **Pruebas**: flutter_test, bloc_test, mocktail (marcos en su lugar, se necesitan escribir pruebas).
3. **Calidad de Código**: flutter_lints.
4. **Control de Versiones**: Git.
5. **Pruebas de API**: Postman / Insomnia (recomendado para probar la API NestJS).

## Construcción y Despliegue
1. **Proceso de Construcción**: Estándar `flutter build apk` / `flutter build ipa`.
2. **Configuración**: El endpoint de la API en `constants.dart` necesita actualizarse para diferentes entornos (Desarrollo, Producción).
3. **Despliegue**: Procedimientos estándar de despliegue en App Store / Play Store.
4. **CI/CD**: Aún no implementado.