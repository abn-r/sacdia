import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/club/cubit/user_clubs_cubit.dart';

/// Widget reutilizable para mostrar la información del club del usuario
class ClubInfoText extends StatelessWidget {
  final TextStyle? style;
  final String prefix;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  
  const ClubInfoText({
    super.key, 
    this.style,
    this.prefix = 'Club: ',
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserClubsCubit, UserClubsState>(
      builder: (context, state) {
        if (state is UserClubsLoading) {
          return loadingWidget ?? Text(
            '$prefix Cargando...',
            style: style,
          );
        } else if (state is UserClubsError) {
          return errorWidget ?? Text(
            '$prefix No disponible',
            style: style,
          );
        } else if (state is UserClubsLoaded) {
          return Text(
            '$prefix${context.read<UserClubsCubit>().getPrimaryClubName()}',
            style: style,
          );
        }
        
        return Text(
          '$prefix No asignado',
          style: style,
        );
      },
    );
  }
}

/// Widget para mostrar un card con la información completa del club
class ClubInfoCard extends StatelessWidget {
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  
  const ClubInfoCard({
    super.key,
    this.backgroundColor,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserClubsCubit, UserClubsState>(
      builder: (context, state) {
        if (state is UserClubsLoading) {
          return Card(
            color: backgroundColor ?? Colors.grey[100],
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: const Center(
                child: CupertinoActivityIndicator(color: sacRed),
              ),
            ),
          );
        } else if (state is UserClubsError) {
          return Card(
            color: backgroundColor ?? Colors.grey[100],
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: sacRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error al cargar la información del club: ${state.message}',
                      style: const TextStyle(color: sacRed),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is UserClubsLoaded && state.clubs.isNotEmpty) {
          final club = state.clubs.first;
          return Card(
            color: backgroundColor ?? Colors.grey[100],
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.groups,
                        color: sacRed,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        club.clubName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (club.clubAdvId != null || club.clubPathfId != null || club.clubMgId != null)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (club.clubAdvId != null)
                          _buildChip('Aventureros', sacBlue),
                        if (club.clubPathfId != null)
                          _buildChip('Conquistadores', sacRed),
                        if (club.clubMgId != null)
                          _buildChip('Guías Mayores', colorGuiaMayor),
                      ],
                    ),
                ],
              ),
            ),
          );
        } else {
          return Card(
            color: backgroundColor ?? Colors.grey[100],
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: sacGrey),
                  SizedBox(width: 8),
                  Text('No hay información de club disponible'),
                ],
              ),
            ),
          );
        }
      },
    );
  }
  
  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(0),
    );
  }
} 