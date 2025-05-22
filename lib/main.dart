import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_bloc.dart';
import 'package:sacdia/core/di/injection_container.dart';
import 'package:sacdia/core/widgets/auth_event_listener.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart' as app_auth;
import 'package:sacdia/features/club/cubit/user_clubs_cubit.dart';
import 'package:sacdia/features/home/bloc/home_bloc.dart';
import 'package:sacdia/features/honor/cubit/honor_categories_cubit.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/core/router/app_router.dart';
import 'package:sacdia/features/theme/bloc/theme_bloc.dart';
import 'package:sacdia/features/theme/bloc/theme_state.dart';
import 'package:sacdia/features/theme/theme_data.dart';
import 'package:sacdia/features/user/bloc/user_bloc.dart';
import 'package:sacdia/features/user/cubit/user_allergies_cubit.dart';
import 'package:sacdia/features/user/cubit/user_classes_cubit.dart';
import 'package:sacdia/features/user/cubit/user_diseases_cubit.dart';
import 'package:sacdia/features/user/cubit/user_emergency_contacts_cubit.dart';
import 'package:sacdia/features/user/cubit/user_roles_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://pfjdavhuriyhtqyifwky.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmamRhdmh1cml5aHRxeWlmd2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg2MjY0MDAsImV4cCI6MjAyNDIwMjQwMH0.OlIfWioRlPSdK_h_CAEB0WPzBKyXl6GrfVaShPHB-NM',
      debug: false);

  // Inicializar todas las dependencias con get_it
  await initDependencies();
  
  // Router
  final appRouter = AppRouter(GetIt.I<AuthBloc>()).router;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
            create: (context) => GetIt.I<ThemeBloc>()),
        BlocProvider<AuthBloc>(create: (context) => GetIt.I<AuthBloc>()),
        BlocProvider<PostRegisterBloc>(create: (context) => GetIt.I<PostRegisterBloc>()),
        BlocProvider<CatalogsBloc>(create: (context) => GetIt.I<CatalogsBloc>()),
        BlocProvider<UserBloc>(create: (context) => GetIt.I<UserBloc>()),
        BlocProvider<HomeBloc>(create: (context) => GetIt.I<HomeBloc>()),
        BlocProvider<UserAllergiesCubit>(create: (context) => GetIt.I<UserAllergiesCubit>()),
        BlocProvider<UserDiseasesCubit>(create: (context) => GetIt.I<UserDiseasesCubit>()),
        BlocProvider<UserEmergencyContactsCubit>(create: (context) => GetIt.I<UserEmergencyContactsCubit>()),
        BlocProvider<UserClubsCubit>(create: (context) => GetIt.I<UserClubsCubit>()),
        BlocProvider<UserClassesCubit>(create: (context) => GetIt.I<UserClassesCubit>()),
        BlocProvider<UserRolesCubit>(create: (context) => GetIt.I<UserRolesCubit>()),
        BlocProvider<UserHonorsCubit>(create: (context) => GetIt.I<UserHonorsCubit>()),
        BlocProvider<HonorCategoriesCubit>(create: (context) => GetIt.I<HonorCategoriesCubit>()),
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
                  routerDelegate: GetIt.I<GoRouter>().routerDelegate,
                  routeInformationParser: GetIt.I<GoRouter>().routeInformationParser,
                  routeInformationProvider: GetIt.I<GoRouter>().routeInformationProvider,
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
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              state.errorMessage ?? 'Ha ocurrido un error de autenticación',
              style: const TextStyle(fontSize: 14.0),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
