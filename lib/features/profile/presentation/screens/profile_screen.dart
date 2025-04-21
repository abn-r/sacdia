import 'package:flutter/material.dart';
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
import 'package:sacdia/features/club/models/user_club_model.dart';
import 'package:sacdia/features/club/extensions/club_extensions.dart';
import 'package:sacdia/features/club/widgets/club_info_widget.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/honor/models/user_honor_category_model.dart';
import 'package:sacdia/features/honor/presentation/screens/add_honor_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:sacdia/features/honor/services/honor_service.dart';
import 'package:sacdia/features/honor/cubit/honor_categories_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar los clubes del usuario al iniciar la pantalla
    _loadUserClubs();
    // Cargar las clases del usuario
    _loadUserClasses();
    // Cargar los roles del usuario
    _loadUserRoles();
    // Método vacío para cargar especialidades (para futura implementación)
    _loadUserSpecialities();
  }

  void _loadUserClubs() {
    // Cargar los clubes del usuario
    context.read<UserClubsCubit>().getUserClubs();
  }

  void _loadUserClasses() {
    // Cargar las clases del usuario
    context.read<UserClassesCubit>().getUserClasses();
  }

  void _loadUserRoles() {
    // Cargar los roles del usuario
    context.read<UserRolesCubit>().getUserRoles();
  }

  void _loadUserSpecialities() {
    // Cargar las especialidades del usuario
    if (!GetIt.I.isRegistered<HonorService>()) {
      GetIt.I.registerSingleton<HonorService>(HonorService());
    }
    
    if (!GetIt.I.isRegistered<UserHonorsCubit>()) {
      GetIt.I.registerSingleton<UserHonorsCubit>(
        UserHonorsCubit(honorService: GetIt.I<HonorService>()),
      );
    }
    
    if (!GetIt.I.isRegistered<HonorCategoriesCubit>()) {
      GetIt.I.registerSingleton<HonorCategoriesCubit>(
        HonorCategoriesCubit(honorService: GetIt.I<HonorService>()),
      );
    }
    
    context.read<UserHonorsCubit>().getUserHonors();
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
                    CircularProgressIndicator(
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

                        // Creamos primero los círculos de la fila superior
                        List<StatusCircleData> topRowCircles = [
                          // Círculo azul fuerte para Guía Mayor
                          StatusCircleData.imageCircle(
                            isActive: userClasses
                                .any((c) => c.className == 'Guía Mayor'),
                            color: colorGuiaMayor,
                            imagePath: 'assets/img/logos-clases/G1_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Clase: Guía Mayor'),
                                ),
                              );
                            },
                          ),

                          // // Círculo negro para bautismo con SVG
                          // StatusCircleData.svgCircle(
                          //   isActive: user.baptism ?? false,
                          //   color: sacBlack,
                          //   svgPath: 'assets/img/bautismo.svg',
                          //   onTap: () {
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       SnackBar(
                          //         content: Text(user.baptism ?? false
                          //             ? 'Usuario bautizado'
                          //             : 'Usuario no bautizado'),
                          //       ),
                          //     );
                          //   },
                          // ),
                        ];

                        // Ahora los círculos de la fila inferior
                        List<StatusCircleData> bottomRowCircles = [
                          StatusCircleData.imageCircle(
                            isActive: userClasses
                                .any((c) => c.className == 'Amigo'),
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
                                .any((c) => c.className == 'Compañero'),
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
                                .any((c) => c.className == 'Explorador'),
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
                                .any((c) => c.className == 'Orientador'),
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
                                .any((c) => c.className == 'Viajero'),
                            color: colorViajero,
                            imagePath: 'assets/img/logos-clases/C3_NEGRO.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Clase: Viajero')),
                              );
                            },
                          ),
                          StatusCircleData.imageCircle(
                            isActive: userClasses
                                .any((c) => c.className == 'Guía'),
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
                                // StatusCirclesSection(
                                //   circlesData: topRowCircles,
                                //   circleSize: 60,
                                //   spacing: 20,
                                //   padding: const EdgeInsets.symmetric(
                                //       horizontal: 20.0),
                                // ),
                                // ss
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            userClasses.any((c) => c.className == "Guía Mayor")
                                            ? 'El usuario está investido de la clase de Guías Mayores'
                                            : 'El usuario no está investido de la clase de Guías Mayores'),
                                      ),
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    'assets/svg/logo-gm.svg',
                                    colorFilter: 
                                        userClasses.any((c) => c.className == "Guía Mayor")
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
                                        content: Text(user.baptism ?? false
                                            ? 'Usuario bautizado'
                                            : 'Usuario no bautizado'),
                                      ),
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    'assets/svg/bautismo.svg',
                                    colorFilter: (user.baptism ?? false)
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

                  // Clases
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Clases',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: sacBlack,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Carrusel de clases
                  SizedBox(
                    height: 120,
                    child: BlocBuilder<UserClassesCubit, UserClassesState>(
                      builder: (context, state) {
                        if (state is UserClassesLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: sacRed),
                          );
                        } else if (state is UserClassesError) {
                          return Center(
                            child: Text(
                              'Error: ${state.message}',
                              style: const TextStyle(color: sacRed),
                            ),
                          );
                        } else if (state is UserClassesLoaded &&
                            state.classes.isNotEmpty) {
                          // Mostrar las clases del usuario
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: state.classes.length,
                            itemBuilder: (context, index) {
                              final UserClass userClass = state.classes[index];
                              // Determinar el color según el tipo de club
                              Color cardColor = sacBlue;
                              String logoPath = logoAVT;
                              
                              if (userClass.clubTypeName == "Guías Mayores") {
                                cardColor = colorGuiaMayor;
                                logoPath = logoGM;
                              } else if (userClass.clubTypeName == "Conquistadores") {
                                cardColor = sacRed;
                                logoPath = logoConqColor;
                              }

                              return _buildClassCard(
                                userClass.className,
                                cardColor,
                                logoPath,
                                userClass.advanced,
                              );
                            },
                          );
                        } else {
                          // Si no hay clases o el estado es inicial, mostrar ejemplos predeterminados
                          return ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            children: [
                              _buildClassCard('Amigo', sacBlue, logoAVT, false),
                              _buildClassCard(
                                  'Compañero', sacGreen, logoConqColor, false),
                              _buildClassCard('Guía', sacRed, logoGM, false),
                            ],
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

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
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: sacRed, size: 30),
                          onPressed: () {
                            // Navegar a la pantalla de agregar especialidad
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(
                                      value: GetIt.I<UserHonorsCubit>(),
                                    ),
                                    BlocProvider.value(
                                      value: GetIt.I<HonorCategoriesCubit>(),
                                    ),
                                  ],
                                  child: const AddHonorScreen(),
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                // Recargar especialidades si se agregó una nueva
                                context.read<UserHonorsCubit>().getUserHonors();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Carrusel de especialidades
                  SizedBox(
                    height: 120,
                    child: BlocProvider.value(
                      value: GetIt.I<UserHonorsCubit>(),
                      child: BlocBuilder<UserHonorsCubit, UserHonorsState>(
                        builder: (context, state) {
                          if (state is UserHonorsLoading) {
                            return const Center(
                              child: CircularProgressIndicator(color: sacRed),
                            );
                          } else if (state is UserHonorsError) {
                            return Center(
                              child: Text(
                                'Error: ${state.message}',
                                style: const TextStyle(color: sacRed),
                              ),
                            );
                          } else if (state is UserHonorsLoaded && state.categories.isNotEmpty) {
                            // Mostrar las categorías de especialidades
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: state.categories.length,
                              itemBuilder: (context, index) {
                                final UserHonorCategory category = state.categories[index];
                                return _buildSpecialityCard(
                                  category.categoryName,
                                  _getCategoryColor(category.categoryId),
                                  _getCategoryIcon(category.categoryId),
                                  category.honors.length.toString(),
                                );
                              },
                            );
                          } else {
                            // Si no hay especialidades o estado inicial, mostrar ejemplos predeterminados
                            return ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              children: [
                                _buildSpecialityCard(
                                    'ADRA', sacBlue, Icons.volunteer_activism, '0'),
                                _buildSpecialityCard(
                                    'Naturaleza', sacGreen, Icons.nature, '0'),
                                _buildSpecialityCard(
                                    'Recreativas', sacYellow, Icons.sports_handball, '0'),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Secciones de especialidades por categoría
                  BlocProvider.value(
                    value: GetIt.I<UserHonorsCubit>(),
                    child: BlocBuilder<UserHonorsCubit, UserHonorsState>(
                      builder: (context, state) {
                        if (state is UserHonorsLoaded && state.categories.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: state.categories.map((category) {
                              return _buildCategorySection(category);
                            }).toList(),
                          );
                        }
                        return const SizedBox();
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

  Widget _buildSpecialityCard(String title, Color color, IconData icon, String count) {
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
                  Text(
                    '$count especialidades',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.7),
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int categoryId) {
    switch (categoryId % 5) {
      case 0:
        return sacRed;
      case 1:
        return sacBlue;
      case 2:
        return sacGreen;
      case 3:
        return sacYellow;
      case 4:
        return Colors.purple;
      default:
        return sacBlack;
    }
  }

  IconData _getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case 1:
        return Icons.volunteer_activism; // ADRA
      case 2:
        return Icons.agriculture; // Agrícolas
      case 3:
        return Icons.medical_services; // Ciencias de la Salud
      case 4:
        return Icons.home; // Domésticas
      case 5:
        return Icons.handyman; // Habilidades Manuales
      case 6:
        return Icons.public; // Misioneras
      case 7:
        return Icons.nature; // Naturaleza
      case 8:
        return Icons.work; // Profesionales
      case 9:
        return Icons.sports_handball; // Recreativas
      default:
        return Icons.star; // Icono por defecto
    }
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
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: sacRed,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(UserHonorCategory category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la categoría
          Text(
            category.categoryName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: sacBlack,
            ),
          ),
          const SizedBox(height: 15),
          // Cuadrícula de especialidades en formato oval
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 15,
            ),
            itemCount: category.honors.length,
            itemBuilder: (context, index) {
              final honor = category.honors[index];
              return Column(
                children: [
                  // Contenedor oval para la imagen
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Mostrar detalles de la especialidad
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(honor.honorName),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estado: ${honor.validate ? 'Validado' : 'Pendiente'}'),
                                  const SizedBox(height: 8),
                                  if (honor.certificate != null) ...[
                                    const Text('Certificado:'),
                                    TextButton.icon(
                                      icon: const Icon(Icons.description),
                                      label: const Text('Ver certificado'),
                                      onPressed: () {
                                        // Lógica para abrir el PDF
                                      },
                                    ),
                                  ],
                                  if (honor.images.isNotEmpty) ...[
                                    const Text('Imágenes:'),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: honor.images.length,
                                        itemBuilder: (context, imgIndex) {
                                          return Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Image.network(
                                              honor.images[imgIndex],
                                              height: 80,
                                              width: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3), // Color amarillo claro uniforme
                          borderRadius: BorderRadius.circular(50), // Forma ovalada
                          border: Border.all(
                            color: const Color(0xFFFCD34D), // Borde amarillo más oscuro
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: honor.images.isNotEmpty || honor.honorImage != null
                              ? const Text(
                                  "Imagen",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Text(
                                  "Imagen",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Nombre de la especialidad
                  Text(
                    honor.honorName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sacBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
