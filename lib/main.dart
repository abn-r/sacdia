import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_bloc.dart';
import 'package:sacdia/core/catalogs/respository/catalogs_repository.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://pfjdavhuriyhtqyifwky.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmamRhdmh1cml5aHRxeWlmd2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg2MjY0MDAsImV4cCI6MjAyNDIwMjQwMH0.OlIfWioRlPSdK_h_CAEB0WPzBKyXl6GrfVaShPHB-NM',
      debug: false);

  // Repositorios
  final themeRepository = ThemeRepository();
  final authRepository = AuthRepository(
    dio: Dio(),
    supabaseClient: Supabase.instance.client,
  );
  final postRegisterRepository = PostRegisterRepository(
    dio: Dio(),
    supabaseClient: Supabase.instance.client,
    //authRepository: authRepository,
  );
  final catalogsRepository = CatalogsRepository(dio: Dio());

  final themeBloc = ThemeBloc(themeRepository: themeRepository);
  final authBloc = AuthBloc(authRepository: authRepository);
  final postRegisterBloc = PostRegisterBloc(
    repository: postRegisterRepository,
  );
  final catalogsBloc = CatalogsBloc(repository: catalogsRepository);
  final appRouter = AppRouter(authBloc).router;

  runApp(MyApp(
    themeBloc: themeBloc,
    authBloc: authBloc,
    postRegisterBloc: postRegisterBloc,
    catalogsBloc: catalogsBloc,
    router: appRouter,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeBloc themeBloc;
  final AuthBloc authBloc;
  final PostRegisterBloc postRegisterBloc;
  final CatalogsBloc catalogsBloc;
  final GoRouter router;

  const MyApp({
    super.key,
    required this.themeBloc,
    required this.authBloc,
    required this.postRegisterBloc,
    required this.catalogsBloc,
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
        BlocProvider<CatalogsBloc>(create: (context) => catalogsBloc)
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
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
          );
        },
      ),
    );
  }
}
