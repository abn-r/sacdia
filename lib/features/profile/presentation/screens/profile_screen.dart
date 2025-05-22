import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/profile/presentation/screens/configuration_screen.dart';
import 'package:sacdia/features/profile/presentation/screens/user_personal_info_screen.dart';
import 'package:sacdia/features/profile/presentation/widgets/status_circle_widget.dart';
import 'package:sacdia/features/profile/presentation/widgets/status_circles_section.dart';
import 'package:sacdia/features/user/bloc/user_bloc.dart';
import 'package:sacdia/features/user/bloc/user_event.dart';
import 'package:sacdia/features/user/bloc/user_state.dart';
import 'package:sacdia/features/user/cubit/user_classes_cubit.dart';
import 'package:sacdia/features/user/cubit/user_roles_cubit.dart';
import 'package:sacdia/features/user/models/user_class_model.dart';
import 'package:sacdia/features/user/models/user_profile_model.dart';
import 'package:sacdia/features/club/cubit/user_clubs_cubit.dart';
import 'package:sacdia/features/club/widgets/club_info_widget.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/honor/models/user_honor_category_model.dart';
import 'package:sacdia/features/honor/models/user_honor_model.dart';
import 'package:sacdia/features/honor/presentation/screens/add_honor_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:sacdia/features/honor/cubit/honor_categories_cubit.dart';
import 'package:intl/intl.dart';
import 'package:sacdia/features/honor/presentation/screens/user_honor_detail.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserClubs(); // Cargar los clubes del usuario al iniciar la pantalla
    _loadUserClasses(); // Cargar las clases del usuario
    _loadUserRoles(); // Cargar los roles del usuario
    _loadUserSpecialities(); // Cargar las especialidades del usuario
  }

  void _loadUserClubs() {
    context.read<UserClubsCubit>().getUserClubs(); // Cargar los clubes del usuario
  }

  void _loadUserClasses() {
    context.read<UserClassesCubit>().getUserClasses(); // Cargar las clases del usuario
  }

  void _loadUserRoles() {
    context.read<UserRolesCubit>().getUserRoles(); // Cargar los roles del usuario
  }

  void _loadUserSpecialities() {
    // Cargar las especialidades del usuario - get_it ya tiene las dependencias registradas
    final honorsCubit = context.read<UserHonorsCubit>();

    // Solo cargar desde API si no hay datos en caché
    if (!honorsCubit.hasCachedData) {
      honorsCubit.getUserHonors();
    }
  }

  // Método para forzar recarga de especialidades
  void _refreshUserSpecialities() {
    final honorsCubit = context.read<UserHonorsCubit>();
    // Primero limpiar la caché para asegurar que se consulte la API
    honorsCubit.clearCache();
    // Luego solicitar nueva carga con forceRefresh=true
    honorsCubit.getUserHonors(forceRefresh: true);
    log('🔄 Forzando recarga de especialidades desde API (caché limpiada)');
  }

  // Método para obtener la clase actual del usuario
  String _getCurrentClassName(BuildContext context) {
    final state = context.watch<UserClassesCubit>().state;
    if (state is UserClassesLoaded && state.classes.isNotEmpty) {
      final userClass = state.classes.first;
      String className = userClass.className;
      if (userClass.advanced) {
        className += ' Avanzado';
      }
      return className;
    }
    return 'No disponible';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sacRed,
        elevation: 0,
        title: const Text(
          'PERFIL',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 24, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfigurationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<UserBloc, UserState>(
          buildWhen: (previous, current) =>
              previous.userProfile != current.userProfile ||
              previous.status != current.status,
          builder: (context, state) {
            // Mostrar loader mientras se carga el perfil
            if (state.status == UserStatus.loading ||
                state.userProfile == null) {
              return const Center(
                child: Column(
                  children: [
                    CupertinoActivityIndicator(
                      color: sacRed,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando perfil...',
                      style: TextStyle(
                        fontSize: 16,
                        color: sacBlack,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Si hay error, mostrar mensaje
            if (state.status == UserStatus.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: sacRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'Error al cargar el perfil',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<UserBloc>().add(const LoadUserProfile());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sacRed,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            // Mostrar la información del perfil
            final UserProfileModel user = state.userProfile!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto de perfil y nombre
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // Información básica del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: sacBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Usar el widget reutilizable para mostrar el nombre del club
                              ClubInfoText(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Mostrar el cargo del usuario en función de su rol
                              BlocBuilder<UserRolesCubit, UserRolesState>(
                                builder: (context, state) {
                                  String roleName = 'Usuario';

                                  if (state is UserRolesLoaded &&
                                      state.roles.isNotEmpty) {
                                    roleName = state.roles.first.roleName;
                                    // Capitalizar primera letra
                                    roleName =
                                        roleName.substring(0, 1).toUpperCase() +
                                            roleName.substring(1);
                                  }

                                  return Text(
                                    'Rol: $roleName',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // Mostrar la clase del usuario
                              BlocBuilder<UserClassesCubit, UserClassesState>(
                                builder: (context, state) {
                                  String className = 'No disponible';

                                  if (state is UserClassesLoaded &&
                                      state.classes.isNotEmpty) {
                                    final userClass = state.classes.first;
                                    className = userClass.className;
                                    if (userClass.advanced) {
                                      className += ' Avanzado';
                                    }
                                  }

                                  return Text(
                                    'Clase: $className',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Foto de perfil
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sacGrey,
                              width: 2,
                            ),
                          ),
                          child: user.userImage == null ||
                                  user.userImage!.isEmpty
                              ? const CircleAvatar(
                                  backgroundImage: AssetImage(userPlaceholder),
                                )
                              : CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/public/profile-pictures//${user.userImage}',
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Botones para actualizar perfil
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Obtener la clase principal del usuario si está disponible
                              String className = 'No disponible';
                              final classState =
                                  context.read<UserClassesCubit>().state;
                              if (classState is UserClassesLoaded &&
                                  classState.classes.isNotEmpty) {
                                final userClass = classState.classes.first;
                                className = userClass.className;
                                if (userClass.advanced) {
                                  className += ' Avanzado';
                                }
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserPersonalInfoScreen(
                                    user: user,
                                    className: className,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sacBlack,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Por ahora, mostraremos un diálogo indicando que esta funcionalidad está en desarrollo
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('En desarrollo'),
                                  content: const Text(
                                      'La funcionalidad para actualizar el perfil estará disponible próximamente.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Aceptar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sacYellow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Actualizar perfil',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sección de círculos de estado
                  SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<UserClassesCubit, UserClassesState>(
                      builder: (context, state) {
                        // Obtener las clases del usuario
                        List<UserClass> userClasses = [];
                        if (state is UserClassesLoaded) {
                          userClasses = state.classes;
                        }

                        // Ahora los círculos de la fila inferior
                        List<StatusCircleData> bottomRowCircles = [
                          StatusCircleData.imageCircle(
                            isActive:
                                userClasses.any((c) => c.className == 'Amigo' && c.investiture),
                            color: sacRed,
                            imagePath: 'assets/img/logos-clases/C3_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Clase: Amigo')),
                              );
                            },
                          ),
                          StatusCircleData.imageCircle(
                            isActive: userClasses
                                .any((c) => c.className == 'Compañero' && c.investiture),
                            color: colorCompanero,
                            imagePath: 'assets/img/logos-clases/C3_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Clase: Compañero')),
                              );
                            },
                          ),
                          StatusCircleData.imageCircle(
                            isActive: userClasses
                                .any((c) => c.className == 'Explorador' && c.investiture),
                            color: colorExplorador,
                            imagePath: 'assets/img/logos-clases/C3_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Clase: Explorador')),
                              );
                            },
                          ),
                          StatusCircleData.imageCircle(
                            isActive: userClasses
                                .any((c) => c.className == 'Orientador' && c.investiture),
                            color: colorOrientador,
                            imagePath: 'assets/img/logos-clases/C3_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Clase: Orientador')),
                              );
                            },
                          ),
                          StatusCircleData.imageCircle(
                            isActive: userClasses
                                .any((c) => c.className == 'Viajero' && c.investiture),
                            color: colorViajero,
                            imagePath: 'assets/img/logos-clases/C3_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Clase: Viajero')),
                              );
                            },
                          ),
                          StatusCircleData.imageCircle(
                            isActive:
                                userClasses.any((c) => c.className == 'Guía' && c.investiture),
                            color: colorGuia,
                            imagePath: 'assets/img/logos-clases/C3_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Clase: Guía')),
                              );
                            },
                          ),
                        ];

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(userClasses.any((c) =>
                                                c.className == "Guía Mayor" && c.investiture)
                                            ? 'El usuario está investido de la clase de Guías Mayores'
                                            : 'El usuario no está investido de la clase de Guías Mayores'),
                                      ),
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    'assets/svg/logo-gm.svg',
                                    colorFilter: userClasses.any(
                                            (c) => c.className == "Guía Mayor" && c.investiture)
                                        ? null // Usar color original del SVG
                                        : ColorFilter.mode(
                                            Colors.grey.withAlpha(30),
                                            BlendMode.srcIn),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(user.baptism == true
                                            ? 'Usuario bautizado'
                                            : 'Usuario no bautizado'),
                                      ),
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    'assets/svg/bautismo.svg',
                                    colorFilter: (user.baptism == true)
                                        ? ColorFilter.mode(
                                            Colors.black, BlendMode.srcIn)
                                        : ColorFilter.mode(
                                            Colors.grey.withAlpha(30),
                                            BlendMode.srcIn),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Fila inferior
                            StatusCirclesSection(
                              circlesData: bottomRowCircles,
                              circleSize:
                                  50, // Tamaño ligeramente más pequeño para que quepan bien en el Row
                              spacing:
                                  8, // El espaciado lo maneja Row.spaceEvenly
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Especialidades
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Especialidades',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: sacBlack,
                          ),
                        ),
                        Row(
                          children: [
                            BlocBuilder<UserHonorsCubit, UserHonorsState>(
                              builder: (context, state) {
                                // Mostrar fecha de última actualización
                                if (state is UserHonorsLoaded) {
                                  final lastUpdate = context
                                      .read<UserHonorsCubit>()
                                      .lastUpdateTime;
                                  if (lastUpdate != null && state.fromCache) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        'Actualizado: ${_formatDate(lastUpdate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const SizedBox();
                              },
                            ),
                            // Botón para refrescar especialidades
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: sacBlack, size: 30),
                              onPressed: _refreshUserSpecialities,
                              tooltip: 'Actualizar especialidades',
                            ),
                            // Botón para agregar especialidad
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: sacRed, size: 30),
                              tooltip: 'Agregar especialidad',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MultiBlocProvider(
                                      providers: [
                                        BlocProvider.value(
                                          value: GetIt.I<UserHonorsCubit>(),
                                        ),
                                        BlocProvider.value(
                                          value:
                                              GetIt.I<HonorCategoriesCubit>(),
                                        ),
                                      ],
                                      child: const AddHonorScreen(),
                                    ),
                                  ),
                                ).then((result) {
                                  // Si se agregó una especialidad, recargar las especialidades
                                  if (result == true) {
                                    log('✅ Se registró una nueva especialidad, recargando datos...');
                                    _refreshUserSpecialities();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secciones de especialidades por categoría
                  BlocProvider.value(
                    value: GetIt.I<UserHonorsCubit>(),
                    child: BlocBuilder<UserHonorsCubit, UserHonorsState>(
                      builder: (context, state) {
                        if (state is UserHonorsLoading) {
                          return const Center(
                            child: CupertinoActivityIndicator(color: sacRed),
                          );
                        } else if (state is UserHonorsError) {
                          log('❌ Error cargando honores: ${state.message}');
                          return Center(
                            child: Text(
                              'Error: ${state.message}',
                              style: const TextStyle(color: sacRed),
                            ),
                          );
                        } else if (state is UserHonorsLoaded) {
                          if (state.categories.isEmpty) {
                            return const Center(
                              child: Text('No hay especialidades disponibles'),
                            );
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: state.categories.map((category) {
                              return _buildCategorySection(category);
                            }).toList(),
                          );
                        }
                        return const Center(
                          child: Text('Cargando especialidades...'),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassCard(
      String title, Color color, String logoPath, bool isAdvanced) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (isAdvanced)
                    const Text(
                      'Avanzado',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Image.asset(
                logoPath,
                width: 40,
                height: 40,
                color: Colors.white.withAlpha(70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(UserHonorCategory category) {
    Color categoryColor = sacBlack;
    IconData categoryIcon = Icons.star;

    switch (category.categoryName) {
      case adra:
        categoryColor = catAdra;
        categoryIcon = Icons.volunteer_activism;
        break;
      case agropecuarias:
        categoryColor = catagropecuarias;
        categoryIcon = Icons.agriculture;
        break;
      case cienciaSalud:
        categoryColor = catCienciasSalud;
        categoryIcon = Icons.medical_services;
        break;
      case domesticas:
        categoryColor = catDomesticas;
        categoryIcon = Icons.home;
        break;
      case habilidadesManuales:
        categoryColor = catHabilidadesManuales;
        categoryIcon = Icons.handyman;
        break;
      case misioneras:
        categoryColor = catMisioneras;
        categoryIcon = Icons.public;
        break;
      case naturaleza:
        categoryColor = catNaturaleza;
        categoryIcon = Icons.forest;
        break;
      case profesionales:
        categoryColor = catProfesionales;
        categoryIcon = Icons.work;
        break;
      case recreativas:
        categoryColor = catRecreativas;
        categoryIcon = Icons.sports_handball;
        break;
    }

    bool isNatureCategory = category.categoryName == naturaleza ||
        category.categoryName == "Estudio de la naturaleza";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la categoría
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isNatureCategory
                      ? sacBlack.withAlpha(100)
                      : categoryColor.withAlpha(100),
                  width: 1.5,
                ),
                bottom: BorderSide(
                  color: isNatureCategory
                      ? sacBlack.withAlpha(100)
                      : categoryColor.withAlpha(100),
                  width: 1.5,
                ),
              ),
              color: categoryColor.withAlpha(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: isNatureCategory ? sacBlack : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isNatureCategory ? sacBlack : categoryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Grid de especialidades
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: category.honors.length,
            itemBuilder: (context, index) {
              final honor = category.honors[index];
              return _buildHonorItem(honor, categoryColor);
            },
          ),
        ],
      ),
    );
  }

  // Widget para cada especialidad individual
  Widget _buildHonorItem(UserHonor honor, Color categoryColor) {
    // Calcular las iniciales de la especialidad para mostrar como fallback
    final String initials = honor.honorName
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join('');

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Navegar a la pantalla de detalle de especialidad
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserHonorDetailScreen(
                    honor: honor,
                    categoryColor: categoryColor,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: honor.honorImage != null && honor.honorImage!.isNotEmpty
                ? FutureBuilder<String>(
                    future: context.read<UserHonorsCubit>().getHonorImageSignedUrl(honor.honorImage),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: CupertinoActivityIndicator(
                              color: sacBlack,
                              radius: 10,
                            ),
                          ),
                        );
                      }
                      
                      final imageUrl = snapshot.data ?? '';
                      return imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              errorBuilder: (context, error, stackTrace) {
                                log('❌ Error al cargar imagen de honor ${honor.honorName}: $error');
                                return _buildInitialsContainer(initials, categoryColor);
                              },
                            )
                          : _buildInitialsContainer(initials, categoryColor);
                    },
                  )
                : _buildInitialsContainer(initials, categoryColor),
            ),
          ),
        ),
        Text(
          honor.honorName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: sacBlack,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Widget para mostrar un contenedor con iniciales
  Widget _buildInitialsContainer(String initials, Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        color: categoryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: categoryColor.withAlpha(50), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: categoryColor,
          ),
        ),
      ),
    );
  }

  // Método para formatear fecha
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  // Método auxiliar para convertir honor a JSON para logs
  String _honorToJson(UserHonor honor) {
    final Map<String, dynamic> json = {
      'honorId': honor.honorId,
      'honorName': honor.honorName,
      'honorImage': honor.honorImage,
      'images': honor.images,
      'certificate': honor.certificate,
      'validate': honor.validate,
    };
    return json.toString();
  }
}
