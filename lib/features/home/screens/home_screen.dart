import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/bloc/auth_state.dart';
import 'package:sacdia/features/home/bloc/home_bloc.dart';
import 'package:sacdia/features/home/widgets/club_type_selector.dart';
import 'package:sacdia/features/home/widgets/emergency_button.dart';
import 'package:sacdia/features/home/widgets/home_header.dart';
import 'package:sacdia/features/home/widgets/menu_option_card.dart';
import 'package:sacdia/features/user/bloc/user_bloc.dart';
import 'package:sacdia/features/user/bloc/user_event.dart';
import 'package:sacdia/features/user/bloc/user_state.dart';
import 'package:sacdia/features/user/models/menu_option_model.dart';
import 'package:sacdia/features/user/models/user_profile_model.dart';
import 'package:sacdia/features/club/cubit/user_clubs_cubit.dart';
import 'package:sacdia/features/club/models/user_club_model.dart';
import 'package:sacdia/features/club/extensions/club_extensions.dart';
import 'package:sacdia/features/club/widgets/club_info_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeBloc _homeBloc;
  UserClub? _userClub;

  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
    _homeBloc.add(LoadHomeData());
    
    // Cargar los clubes del usuario
    _loadUserClubs();
  }
  
  void _loadUserClubs() {
    // Cargar los clubes del usuario al iniciar la pantalla
    context.read<UserClubsCubit>().getUserClubs();
  }

  /// Determina el rol del usuario basado en sus clubes asignados
  String _determineUserRole(UserProfileModel user) {
    // Por defecto, todos los usuarios son miembros
    String role = 'miembro';
    
    // Si tiene algún club asignado, es director
    if (user.clubAdvId != null || user.clubMgId != null || user.clubPathId != null) {
      role = 'director';
    }
    
    return role;
  }

  /// Determina el tipo de club del usuario
  int? _determineClubType(UserProfileModel user) {
    if (user.clubAdvId != null) return 1; // Aventureros
    if (user.clubPathId != null) return 2; // Conquistadores
    if (user.clubMgId != null) return 3; // Guías Mayores
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.status == AuthStatus.authenticated) {
          // Cargar el perfil del usuario si aún no se ha cargado
          final userBloc = context.watch<UserBloc>();
          final userState = userBloc.state;
          
          if (userState.status == UserStatus.initial) {
            userBloc.add(const LoadUserProfile());
          }
          
          return Scaffold(
            backgroundColor: sacGreen,
            body: SafeArea(
              child: Column(
                children: [
                  // Header con información del usuario
                  HomeHeader(
                    onAvatarTap: () => _showClubTypeSelector(context),
                  ),
                  
                  // Grid de opciones
                  Expanded(
                    child: BlocBuilder<UserBloc, UserState>(
                      buildWhen: (previous, current) => 
                        previous.userProfile != current.userProfile,
                      builder: (context, state) {
                        // Mostrar loader mientras se carga el perfil
                        if (state.status == UserStatus.loading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          );
                        }
                        
                        // Mostrar mensaje de error si falla la carga
                        if (state.status == UserStatus.error) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.errorMessage ?? 'Error desconocido',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context.read<UserBloc>().add(
                                    const LoadUserProfile(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    'Reintentar',
                                    style: TextStyle(color: sacGreen),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // Si no hay perfil de usuario, mostrar mensaje
                        if (state.userProfile == null) {
                          return const Center(
                            child: Text(
                              'No se pudo cargar la información del usuario',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        
                        // Obtener opciones de menú según el rol del usuario
                        final role = _determineUserRole(state.userProfile!);
                        final options = MenuOptions.getOptionsForRole(role);
                        
                        // Mostrar la cuadrícula de opciones con información del club
                        return BlocBuilder<UserClubsCubit, UserClubsState>(
                          builder: (context, clubState) {
                            // Guardar la información del club
                            if (clubState is UserClubsLoaded && clubState.clubs.isNotEmpty) {
                              _userClub = clubState.clubs.first;
                            }
                            
                            // Panel informativo del club
                            Widget clubInfoPanel = const SizedBox.shrink();
                            
                            return Container(
                              color: sacGreen,
                              child: Column(
                                children: [
                                  // Mostrar el panel de información del club
                                  clubInfoPanel,
                                  
                                  // Grid de opciones
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: GridView.builder(
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 1.2,
                                          crossAxisSpacing: 4,
                                          mainAxisSpacing: 4,
                                        ),
                                        itemCount: options.length,
                                        itemBuilder: (context, index) => MenuOptionCard(
                                          option: options[index],
                                          onTap: () => _navigateToOption(
                                            context: context,
                                            route: options[index].route,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: EmergencyButton(
              onTap: () => _navigateToOption(
                context: context,
                route: '/emergency-contacts',
              ),
            ),
          );
        } else {
          // Si el estado no es AuthAuthenticated, mostramos algo básico
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inicio'),
            ),
            body: const Center(
              child: Text('No existe un usuario autenticado'),
            ),
          );
        }
      },
    );
  }
  
  // Método para mostrar el selector de tipo de club
  void _showClubTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => ClubTypeSelector(
        onClose: () => Navigator.pop(context),
      ),
    );
  }
  
  // Método para navegar a las opciones del menú
  void _navigateToOption({
    required BuildContext context,
    required String route,
  }) {
    Navigator.pushNamed(context, route);
  }
}
