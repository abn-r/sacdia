import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_bloc.dart';
import 'package:sacdia/core/catalogs/respository/catalogs_repository.dart';
import 'package:sacdia/core/http/api_client.dart';
import 'package:sacdia/core/widgets/auth_event_listener.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart' as app_auth;
import 'package:sacdia/features/auth/repository/auth_repository.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/features/post_register/repository/post_register_repository.dart';
import 'package:sacdia/core/router/app_router.dart';
import 'package:sacdia/features/theme/bloc/theme_bloc.dart';
import 'package:sacdia/features/theme/bloc/theme_event.dart';
import 'package:sacdia/features/theme/bloc/theme_state.dart';
import 'package:sacdia/features/theme/theme_data.dart';
import 'package:sacdia/features/theme/theme_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sacdia/features/home/bloc/home_bloc.dart';
import 'package:sacdia/features/home/data/repositories/feature_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://pfjdavhuriyhtqyifwky.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmamRhdmh1cml5aHRxeWlmd2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg2MjY0MDAsImV4cCI6MjAyNDIwMjQwMH0.OlIfWioRlPSdK_h_CAEB0WPzBKyXl6GrfVaShPHB-NM',
      debug: false);

  // Inicializar ApiClient para renovación automática de tokens
  final apiClient = ApiClient();
  
  // Servicios
  final authEventService = AuthEventService();
  
  // Repositorios
  final themeRepository = ThemeRepository();
  final authRepository = AuthRepository();
  final postRegisterRepository = PostRegisterRepository();
  final catalogsRepository = CatalogsRepository();
  final featureRepository = FeatureRepositoryImpl(authRepository: authRepository);

  // Blocs
  final themeBloc = ThemeBloc(themeRepository: themeRepository);
  final authBloc = AuthBloc(
    authRepository: authRepository,
    authEventService: authEventService,
  );
  final catalogsBloc = CatalogsBloc(repository: catalogsRepository);
  final postRegisterBloc = PostRegisterBloc(
    repository: postRegisterRepository,
    authRepository: authRepository,
    authBloc: authBloc,
    catalogsBloc: catalogsBloc,
  );
  final homeBloc = HomeBloc(featureRepository: featureRepository);
  
  // Router
  final appRouter = AppRouter(authBloc).router;

  runApp(MyApp(
    themeBloc: themeBloc,
    authBloc: authBloc,
    postRegisterBloc: postRegisterBloc,
    catalogsBloc: catalogsBloc,
    homeBloc: homeBloc,
    router: appRouter,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeBloc themeBloc;
  final AuthBloc authBloc;
  final PostRegisterBloc postRegisterBloc;
  final CatalogsBloc catalogsBloc;
  final HomeBloc homeBloc;
  final GoRouter router;

  const MyApp({
    super.key,
    required this.themeBloc,
    required this.authBloc,
    required this.postRegisterBloc,
    required this.catalogsBloc,
    required this.homeBloc,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
            create: (context) => themeBloc..add(LoadThemeEvent())),
        BlocProvider<AuthBloc>(create: (context) => authBloc),
        BlocProvider<PostRegisterBloc>(create: (context) => postRegisterBloc),
        BlocProvider<CatalogsBloc>(create: (context) => catalogsBloc),
        BlocProvider<HomeBloc>(create: (context) => homeBloc),
      ],
      child: BlocConsumer<AuthBloc, app_auth.AuthState>(
        listener: (context, authState) {
          // Mostrar notificaciones cuando hay errores de autenticación
          if (authState.hasAuthError && authState.errorMessage != null) {
            _showAuthErrorSnackbar(context, authState);
          }
          
          // Manejar la expiración de sesión (ya manejado automáticamente por el bloc)
        },
        builder: (context, authState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return AuthEventListener(
                onSessionExpired: () {
                  print('🔐 Sesión expirada, redirigiendo al login...');
                  // El AuthEventListener se encargará de redirigir al login
                },
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'SACDIA',
                  theme: AppThemeData.lightTheme,
                  darkTheme: AppThemeData.darkTheme,
                  themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('es', 'MX'),
                  ],
                  routerDelegate: router.routerDelegate,
                  routeInformationParser: router.routeInformationParser,
                  routeInformationProvider: router.routeInformationProvider,
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _showAuthErrorSnackbar(BuildContext context, app_auth.AuthState state) {
    // Determinar el tipo de error para seleccionar el color adecuado
    bool isError = state.authEventType == AuthEventType.sessionExpired;
    bool isWarning = state.authEventType == AuthEventType.renewalFailed || 
                     state.authEventType == AuthEventType.unauthorized;
                     
    Color backgroundColor = isError 
        ? Colors.red.shade800 
        : (isWarning ? Colors.orange.shade800 : Colors.blue.shade800);
        
    String title = 'Aviso';
    if (state.authEventType == AuthEventType.sessionExpired) {
      title = 'Sesión expirada';
    } else if (state.authEventType == AuthEventType.renewalFailed) {
      title = 'Error de renovación';
    } else if (state.authEventType == AuthEventType.unauthorized) {
      title = 'Acceso denegado';
    }
    
    // Mostrar Snackbar con el mensaje de error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(state.errorMessage ?? 'Error de autenticación'),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: isError || isWarning ? SnackBarAction(
          label: 'Iniciar sesión',
          textColor: Colors.white,
          onPressed: () => _handleSessionExpired(context),
        ) : null,
      ),
    );
    
    // Limpiar el error después de mostrarlo
    Future.delayed(const Duration(seconds: 5), () {
      if (context.mounted) {
        context.read<AuthBloc>().add(ClearAuthErrorsRequested());
      }
    });
  }
  
  void _handleSessionExpired(BuildContext context) async {
    context.read<AuthBloc>().add(SignOutRequested());
    router.go('/login');
  }
}
