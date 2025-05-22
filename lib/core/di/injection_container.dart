import 'package:get_it/get_it.dart';
import 'package:sacdia/core/auth_events/auth_event_service.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_bloc.dart';
import 'package:sacdia/core/catalogs/respository/catalogs_repository.dart';
import 'package:sacdia/core/http/api_client.dart';
import 'package:sacdia/core/services/preferences_service.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/repository/auth_repository.dart';
import 'package:sacdia/features/club/cubit/user_clubs_cubit.dart';
import 'package:sacdia/features/home/bloc/home_bloc.dart';
import 'package:sacdia/features/honor/cubit/honor_categories_cubit.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/honor/services/honor_service.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/features/post_register/repository/post_register_repository.dart';
import 'package:sacdia/features/theme/bloc/theme_bloc.dart';
import 'package:sacdia/features/theme/bloc/theme_event.dart';
import 'package:sacdia/features/theme/theme_repository.dart';
import 'package:sacdia/features/user/bloc/user_bloc.dart';
import 'package:sacdia/features/user/cubit/user_allergies_cubit.dart';
import 'package:sacdia/features/user/cubit/user_classes_cubit.dart';
import 'package:sacdia/features/user/cubit/user_diseases_cubit.dart';
import 'package:sacdia/features/user/cubit/user_emergency_contacts_cubit.dart';
import 'package:sacdia/features/user/cubit/user_roles_cubit.dart';
import 'package:sacdia/features/user/repository/user_repository.dart';
import 'package:sacdia/features/user/services/user_service.dart';

final getIt = GetIt.instance;

/// Configura todas las dependencias de la aplicación
Future<void> initDependencies() async {
  // Registrar Core
  _registerCore();
  
  // Registrar Servicios
  _registerServices();
  
  // Registrar Repositorios
  _registerRepositories();
  
  // Registrar Blocs
  _registerBlocs();
  
  // Registrar Cubits
  _registerCubits();
}

void _registerCore() {
  // Registrar componentes core como singleton para asegurar una única instancia
  getIt.registerSingleton<ApiClient>(ApiClient(
    enableDetailedLogs: false, // Cambiar a true para logs detallados en desarrollo
  ));
}

void _registerServices() {
  // Registrar como singleton para compartir una única instancia
  getIt.registerSingleton<AuthEventService>(AuthEventService());
  getIt.registerSingleton<UserService>(UserService());
  getIt.registerSingleton<HonorService>(HonorService());
  getIt.registerSingleton<PreferencesService>(PreferencesService());
}

void _registerRepositories() {
  // Registrar como singleton para compartir una única instancia
  getIt.registerSingleton<ThemeRepository>(ThemeRepository());
  getIt.registerSingleton<AuthRepository>(AuthRepository());
  getIt.registerSingleton<PostRegisterRepository>(PostRegisterRepository());
  getIt.registerSingleton<CatalogsRepository>(CatalogsRepository());
  getIt.registerSingleton<UserRepository>(UserRepository());
}

void _registerBlocs() {
  // Registrar como lazySingleton para que solo se creen cuando se necesiten
  getIt.registerLazySingleton<ThemeBloc>(
    () => ThemeBloc(themeRepository: getIt<ThemeRepository>())..add(LoadThemeEvent()),
  );
  
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
      authEventService: getIt<AuthEventService>(),
    ),
  );
  
  getIt.registerLazySingleton<CatalogsBloc>(
    () => CatalogsBloc(repository: getIt<CatalogsRepository>()),
  );
  
  getIt.registerLazySingleton<UserBloc>(
    () => UserBloc(userRepository: getIt<UserRepository>()),
  );
  
  // Dependencias de otros Blocs
  getIt.registerLazySingleton<HomeBloc>(
    () => HomeBloc(userBloc: getIt<UserBloc>()),
  );
  
  getIt.registerLazySingleton<PostRegisterBloc>(
    () => PostRegisterBloc(
      repository: getIt<PostRegisterRepository>(),
      authRepository: getIt<AuthRepository>(),
      authBloc: getIt<AuthBloc>(),
      catalogsBloc: getIt<CatalogsBloc>(),
    ),
  );
}

void _registerCubits() {
  // Registrar como lazySingleton para que solo se creen cuando se necesiten
  getIt.registerLazySingleton<UserAllergiesCubit>(
    () => UserAllergiesCubit(userService: getIt<UserService>()),
  );
  
  getIt.registerLazySingleton<UserDiseasesCubit>(
    () => UserDiseasesCubit(userService: getIt<UserService>()),
  );
  
  getIt.registerLazySingleton<UserEmergencyContactsCubit>(
    () => UserEmergencyContactsCubit(userService: getIt<UserService>()),
  );
  
  getIt.registerLazySingleton<UserClubsCubit>(
    () => UserClubsCubit(userService: getIt<UserService>()),
  );
  
  getIt.registerLazySingleton<UserClassesCubit>(
    () => UserClassesCubit(userService: getIt<UserService>()),
  );
  
  getIt.registerLazySingleton<UserRolesCubit>(
    () => UserRolesCubit(userService: getIt<UserService>()),
  );
  
  getIt.registerLazySingleton<UserHonorsCubit>(
    () => UserHonorsCubit(honorService: getIt<HonorService>()),
  );
  
  getIt.registerLazySingleton<HonorCategoriesCubit>(
    () => HonorCategoriesCubit(honorService: getIt<HonorService>()),
  );
} 