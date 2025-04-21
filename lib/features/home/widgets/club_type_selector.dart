import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/user/bloc/user_bloc.dart';
import 'package:sacdia/features/user/bloc/user_event.dart';

class ClubTypeSelector extends StatelessWidget {
  final VoidCallback onClose;
  
  const ClubTypeSelector({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          const Text(
            'Seleccione el club con el que desea interactuar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: sacBlack,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Opción Aventureros
          _buildClubOption(
            context: context,
            logoPath: logoAVT,
            title: 'Aventureros',
            clubTypeId: 1,
          ),
          
          const SizedBox(height: 16),
          
          // Opción Conquistadores
          _buildClubOption(
            context: context,
            logoPath: logoConqColor,
            title: 'Conquistadores',
            clubTypeId: 2,
          ),
          
          const SizedBox(height: 16),
          
          // Opción Guías Mayores
          _buildClubOption(
            context: context,
            logoPath: logoGM,
            title: 'Guías Mayores',
            clubTypeId: 3,
          ),
          
          const SizedBox(height: 24),
          
          // Botón para cerrar
          ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: sacRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClubOption({
    required BuildContext context,
    required String logoPath,
    required String title,
    required int clubTypeId,
  }) {
    return GestureDetector(
      onTap: () {
        // Disparar evento para cambiar el tipo de club
        context.read<UserBloc>().add(ChangeClubType(clubTypeId));
        onClose();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.asset(
              logoPath,
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: sacBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 