import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/user/cubit/user_diseases_cubit.dart';
import 'package:sacdia/features/user/cubit/user_roles_cubit.dart';
import 'package:sacdia/features/user/models/user_profile_model.dart';
import 'package:sacdia/features/profile/presentation/screens/user_allergies_screen.dart';
import 'package:sacdia/features/profile/presentation/screens/user_diseases_screen.dart';
import 'package:sacdia/features/user/cubit/user_allergies_cubit.dart';
import 'package:sacdia/features/user/cubit/user_emergency_contacts_cubit.dart';
import 'package:sacdia/features/profile/presentation/widgets/emergency_contacts_widget.dart';
import 'package:sacdia/features/club/cubit/user_clubs_cubit.dart';

class UserPersonalInfoScreen extends StatefulWidget {
  final UserProfileModel user;
  final String className;

  const UserPersonalInfoScreen(
      {super.key, required this.user, required this.className});

  @override
  State<UserPersonalInfoScreen> createState() => _UserPersonalInfoScreenState();
}

class _UserPersonalInfoScreenState extends State<UserPersonalInfoScreen> {
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (!_dataLoaded) {
      // Cargar los datos solo una vez al inicializar el widget
      Future.microtask(() {
        context.read<UserDiseasesCubit>().getUserDiseases();
        context.read<UserAllergiesCubit>().getUserAllergies();
        context.read<UserEmergencyContactsCubit>().getEmergencyContacts();
        context.read<UserClubsCubit>().getUserClubs();
        context.read<UserRolesCubit>().getUserRoles();
        setState(() {
          _dataLoaded = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sacRed,
      appBar: AppBar(
        backgroundColor: sacRed,
        title: const Text(
          'INFORMACIÓN PERSONAL',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Foto de perfil y nombre
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: widget.user.userImage == null ||
                              widget.user.userImage!.isEmpty
                          ? const CircleAvatar(
                              backgroundImage: AssetImage(userPlaceholder),
                            )
                          : CircleAvatar(
                              backgroundImage: NetworkImage(
                                'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/public/profile-pictures//${widget.user.userImage}',
                              ),
                            ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.user.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido principal con fondo blanco
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de información básica
                    _buildSectionTitle('Información Básica', Icons.person),

                    // Género y fecha de nacimiento en la misma línea
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.transgender,
                            title: 'Género',
                            value: widget.user.gender ?? 'No registrado',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.cake,
                            title: 'Fecha de Nacimiento',
                            value: widget.user.birthday != null
                                ? '${widget.user.birthday!.day}/${widget.user.birthday!.month}/${widget.user.birthday!.year}'
                                : 'No registrada',
                          ),
                        ),
                      ],
                    ),

                    // Tipo de sangre y bautismo en la misma línea
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.bloodtype,
                            title: 'Tipo de Sangre',
                            value: _formatBloodType(widget.user.blood),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.church,
                            title: 'Bautizado',
                            value: widget.user.baptism == true ? 'Sí' : 'No',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sección de información del club
                    _buildSectionTitle('Información del Club', Icons.groups),

                    // Club y cargo en la misma línea
                    // Club en una fila completa
                    BlocBuilder<UserClubsCubit, UserClubsState>(
                      builder: (context, state) {
                        String clubName = 'Cargando...';

                        if (state is UserClubsLoading) {
                          clubName = 'Cargando...';
                        } else if (state is UserClubsError) {
                          clubName = 'No disponible';
                        } else if (state is UserClubsLoaded &&
                            state.clubs.isNotEmpty) {
                          clubName = state.clubs.first.clubName;
                        }

                        return _buildInfoCard(
                          icon: Icons.people,
                          title: 'Club',
                          value: clubName,
                        );
                      },
                    ),

                    // Cargo y clase en la misma línea
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<UserRolesCubit, UserRolesState>(
                            builder: (context, state) {
                              String roleName = 'Usuario';
                              
                              if (state is UserRolesLoaded && state.roles.isNotEmpty) {
                                roleName = state.roles.first.roleName;
                                // Capitalizar primera letra
                                roleName = roleName.substring(0, 1).toUpperCase() + roleName.substring(1);
                              }
                              
                              return _buildInfoCard(
                                icon: Icons.work,
                                title: 'Rol',
                                value: roleName,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.school,
                            title: 'Clase',
                            value: widget.className,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sección de información médica
                    _buildSectionTitle(
                        'Información Médica', Icons.medical_services),

                    // Mostrar enfermedades usando el Cubit
                    BlocBuilder<UserDiseasesCubit, UserDiseasesState>(
                      builder: (context, state) {
                        if (state is UserDiseasesLoading) {
                          return _buildInfoCard(
                            icon: Icons.medical_information,
                            title: 'Enfermedades',
                            value: 'Cargando...',
                            isEditable: true,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserDiseasesScreen(),
                                ),
                              );
                            },
                          );
                        } else if (state is UserDiseasesLoaded) {
                          if (state.diseases.isEmpty) {
                            return _buildInfoCard(
                              icon: Icons.medical_information,
                              title: 'Enfermedades',
                              value: 'Ninguna enfermedad registrada',
                              isEditable: true,
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UserDiseasesScreen(),
                                  ),
                                );
                              },
                            );
                          } else {
                            // Filtrar solo enfermedades activas
                            final activeDiseases =
                                state.diseases.where((d) => d.active).toList();

                            // Mostrar resumen de enfermedades
                            return _buildInfoCard(
                              icon: Icons.medical_information,
                              title: 'Enfermedades',
                              value:
                                  '${activeDiseases.length} ${activeDiseases.length == 1 ? 'enfermedad activa' : 'enfermedades activas'}',
                              isEditable: true,
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UserDiseasesScreen(),
                                  ),
                                );
                              },
                            );
                          }
                        } else if (state is UserDiseasesError) {
                          return _buildInfoCard(
                            icon: Icons.error_outline,
                            title: 'Error',
                            value: 'No se pudieron cargar las enfermedades',
                            isEditable: true,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserDiseasesScreen(),
                                ),
                              );
                            },
                          );
                        } else {
                          return _buildInfoCard(
                            icon: Icons.medical_information,
                            title: 'Enfermedades',
                            value: 'Cargando...',
                            isEditable: true,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserDiseasesScreen(),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),

                    _buildInfoCard(
                      icon: Icons.health_and_safety,
                      title: 'Medicamentos',
                      value: 'Ninguno registrado',
                      isEditable: true,
                      onEdit: () {
                        // Implementar edición de medicamentos
                      },
                    ),

                    // Mostrar alergias usando el Cubit
                    BlocBuilder<UserAllergiesCubit, UserAllergiesState>(
                      builder: (context, state) {
                        if (state is UserAllergiesLoading) {
                          return _buildInfoCard(
                            icon: Icons.no_food,
                            title: 'Alergias',
                            value: 'Cargando...',
                            isEditable: true,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserAllergiesScreen(),
                                ),
                              );
                            },
                          );
                        } else if (state is UserAllergiesLoaded) {
                          return _buildInfoCard(
                            icon: Icons.no_food,
                            title: 'Alergias',
                            value: state.allergies.isEmpty
                                ? 'Ninguna alergia registrada'
                                : '${state.allergies.length} ${state.allergies.length == 1 ? 'alergia registrada' : 'alergias registradas'}',
                            isEditable: true,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserAllergiesScreen(),
                                ),
                              );
                            },
                          );
                        } else if (state is UserAllergiesError) {
                          return _buildInfoCard(
                            icon: Icons.error_outline,
                            title: 'Alergias',
                            value: 'Error al cargar las alergias',
                            isEditable: true,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserAllergiesScreen(),
                                ),
                              );
                            },
                          );
                        } else {
                          return _buildInfoCard(
                            icon: Icons.no_food,
                            title: 'Alergias',
                            value: 'Ninguna registrada',
                            isEditable: true,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserAllergiesScreen(),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Sección de contactos de emergencia
                    _buildSectionTitle(
                        'Contactos de Emergencia', Icons.emergency),
                    const EmergencyContactsWidget(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para formatear el tipo de sangre
  String _formatBloodType(String? bloodType) {
    if (bloodType == null || bloodType.isEmpty) {
      return 'No registrado';
    }

    final Map<String, String> bloodTypeMap = {
      'O_POSITIVE': 'O+',
      'O_NEGATIVE': 'O-',
      'A_POSITIVE': 'A+',
      'A_NEGATIVE': 'A-',
      'B_POSITIVE': 'B+',
      'B_NEGATIVE': 'B-',
      'AB_POSITIVE': 'AB+',
      'AB_NEGATIVE': 'AB-',
    };

    return bloodTypeMap[bloodType] ?? bloodType;
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: sacRed,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: sacBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool isEditable = false,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              icon,
              color: sacRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isEditable)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: sacRed, size: 20),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String name,
    required String relation,
    required String phone,
    bool isPlaceholder = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isPlaceholder
            ? Center(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: sacBlue.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: sacBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          relation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: sacBlue,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: sacBlue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: sacBlue,
                          size: 20,
                        ),
                        onPressed: () {
                          // Implementar edición de contacto
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: sacRed,
                          size: 20,
                        ),
                        onPressed: () {
                          // Implementar eliminación de contacto
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
