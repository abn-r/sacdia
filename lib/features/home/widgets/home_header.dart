import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/user/bloc/user_bloc.dart';
import 'package:sacdia/features/user/bloc/user_state.dart';
import 'package:sacdia/features/user/models/user_profile_model.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onAvatarTap;

  const HomeHeader({
    super.key,
    required this.onAvatarTap,
  });

  /// Determina el tipo de club del usuario
  int? _determineClubType(UserProfileModel user) {
    if (user.clubAdvId != null) return 1; // Aventureros
    if (user.clubPathId != null) return 2; // Conquistadores
    if (user.clubMgId != null) return 3; // Guías Mayores
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.userProfile != current.userProfile,
      builder: (context, state) {
        final UserProfileModel? user = state.userProfile;

        // Si no hay usuario, mostrar un indicador de carga
        if (user == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Obtener el logo correspondiente según el tipo de club
        String logoPath = logoConqColor;
        final clubType = _determineClubType(user);
        switch (clubType) {
          case 1: // Aventureros
            logoPath = logoAVT;
            break;
          case 2: // Conquistadores
            logoPath = logoConqColor;
            break;
          case 3: // Guías Mayores
            logoPath = logoGM;
            break;
          default:
            logoPath = logoConqColor;
        }

        return Container(
          margin: const EdgeInsets.only(
            left: 40,
            right: 40,
            top: 25          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Texto de bienvenida y nombre del usuario
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '¡Hola!\n${user.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Avatar del usuario con logo del club
              Container(
                width: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo blanco de fondo
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),

                    // Foto del usuario
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: ClipOval(
                        child: user.userImage == null || user.userImage!.isEmpty
                            ? Container(
                                height: 60,
                                width: 60,
                                color: Colors.grey[350],
                                child: const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: sacBlack,
                                ),
                              )
                            : Container(
                                height: 60,
                                width: 60,
                                child: Image.network(
                                  'https://pfjdavhuriyhtqyifwky.supabase.co/storage/v1/object/public/profile-pictures//${user.userImage}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(
                                    color: Colors.grey[350],
                                    child: const Icon(
                                      Icons.error_outline,
                                      size: 30,
                                      color: sacBlack,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Logo del club
                    Positioned(
                      right: 2,
                      bottom: 0,
                      child: Image.asset(
                        logoPath,
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
