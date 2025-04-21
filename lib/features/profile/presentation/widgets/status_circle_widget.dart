import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget que muestra un círculo de estado con un icono central o una imagen.
/// 
/// Este widget es utilizado para representar diferentes tipos de estados del usuario,
/// como bautismo, investidura, reconocimientos, etc.
/// 
/// Propiedades:
/// - [isActive]: Determina si el círculo está activo (true) o inactivo (false).
/// - [activeColor]: Color que se usará cuando el círculo esté activo.
/// - [icon]: Icono que se mostrará en el centro del círculo (si no se especifica imagePath o svgPath).
/// - [imagePath]: Ruta de la imagen de asset que se mostrará (tiene prioridad sobre el icono).
/// - [svgPath]: Ruta de la imagen SVG que se mostrará (tiene prioridad sobre imagePath e icon).
/// - [size]: Tamaño del círculo (el icono/imagen se ajustará proporcionalmente).
/// - [onTap]: Función que se ejecutará cuando se toque el círculo.
/// 
/// Cuando [isActive] es false, el círculo se mostrará en gris con opacidad reducida.
class StatusCircleWidget extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final String? imagePath;
  final String? svgPath;
  final double size;
  final VoidCallback? onTap;

  const StatusCircleWidget({
    super.key,
    required this.isActive,
    required this.activeColor,
    required this.icon,
    this.imagePath,
    this.svgPath,
    this.size = 60.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isActive 
                ? activeColor 
                : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _getContentWidget(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _getContentWidget() {
    // Prioridad: SVG > Imagen > Icono
    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath!,
        width: size * 1,
        height: size * 1,
      );
    } else if (imagePath != null) {
      return Image.asset(
        imagePath!,
        color: Colors.white,
        width: size * 0.6,
        height: size * 0.6,
      );
    } else {
      return Icon(
        icon,
        color: isActive ? Colors.white : Colors.grey[600],
        size: size * 0.5,
      );
    }
  }
} 