import 'package:flutter/material.dart';
import 'package:sacdia/features/profile/presentation/widgets/status_circle_widget.dart';

/// Widget que muestra una sección de círculos de estado organizados en filas.
/// 
/// Este widget agrupa varios [StatusCircleWidget] y los organiza de manera
/// responsiva usando un [Wrap].
/// 
/// Propiedades:
/// - [circlesData]: Lista de datos para cada círculo de estado.
/// - [circleSize]: Tamaño de cada círculo (por defecto 60.0).
/// - [spacing]: Espacio entre círculos (por defecto 10.0).
/// - [padding]: Padding alrededor de la sección (por defecto 20.0 horizontal).
class StatusCirclesSection extends StatelessWidget {
  final List<StatusCircleData> circlesData;
  final double circleSize;
  final double spacing;
  final EdgeInsets padding;

  const StatusCirclesSection({
    super.key,
    required this.circlesData,
    this.circleSize = 60.0,
    this.spacing = 10.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: circlesData.length <= 3 
          ? Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: circlesData.map((data) => StatusCircleWidget(
                isActive: data.isActive,
                activeColor: data.color,
                icon: data.icon,
                imagePath: data.imagePath,
                svgPath: data.svgPath,
                size: circleSize,
                onTap: data.onTap,
              )).toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: circlesData.map((data) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: StatusCircleWidget(
                  isActive: data.isActive,
                  activeColor: data.color,
                  icon: data.icon,
                  imagePath: data.imagePath,
                  svgPath: data.svgPath,
                  size: circleSize,
                  onTap: data.onTap,
                ),
              )).toList(),
            ),
    );
  }
}

/// Clase de datos para configurar un círculo de estado.
/// 
/// Esta clase contiene toda la información necesaria para configurar
/// un [StatusCircleWidget].
/// 
/// Propiedades básicas:
/// - [isActive]: Si el círculo está activo o no.
/// - [color]: El color para el círculo activo.
/// - [icon]: El icono en el centro del círculo.
/// - [imagePath]: Ruta de la imagen a mostrar (opcional, tiene prioridad sobre el icono).
/// - [svgPath]: Ruta de la imagen SVG a mostrar (opcional, tiene prioridad sobre imagePath e icono).
/// - [onTap]: La función al tocar el círculo.
/// 
/// Incluye varios constructores de fábrica para casos de uso comunes:
/// - [baptism]: Para estado de bautismo.
/// - [investiture]: Para estado de investidura de clase.
/// - [custom]: Para casos personalizados.
/// - [imageCircle]: Para crear círculos con imágenes personalizadas.
/// - [svgCircle]: Para crear círculos con imágenes SVG.
class StatusCircleData {
  final bool isActive;
  final Color color;
  final IconData icon;
  final String? imagePath;
  final String? svgPath;
  final VoidCallback? onTap;

  StatusCircleData({
    required this.isActive,
    required this.color,
    required this.icon,
    this.imagePath,
    this.svgPath,
    this.onTap,
  });

  /// Constructor para círculo de bautismo
  factory StatusCircleData.baptism({
    required bool isBaptized,
    required Color color,
    String? imagePath,
    String? svgPath,
    VoidCallback? onTap,
  }) {
    return StatusCircleData(
      isActive: isBaptized,
      color: color,
      icon: Icons.water_drop,
      imagePath: imagePath,
      svgPath: svgPath,
      onTap: onTap,
    );
  }

  /// Constructor para círculo de investidura de clase
  factory StatusCircleData.investiture({
    required bool isInvested,
    required Color color,
    required String className,
    String? imagePath,
    String? svgPath,
    VoidCallback? onTap,
  }) {
    return StatusCircleData(
      isActive: isInvested,
      color: color,
      icon: Icons.school,
      imagePath: imagePath,
      svgPath: svgPath,
      onTap: onTap,
    );
  }

  /// Constructor genérico para cualquier caso personalizado
  factory StatusCircleData.custom({
    required bool isActive,
    required Color color,
    required IconData icon,
    String? imagePath,
    String? svgPath,
    VoidCallback? onTap,
  }) {
    return StatusCircleData(
      isActive: isActive,
      color: color,
      icon: icon,
      imagePath: imagePath,
      svgPath: svgPath,
      onTap: onTap,
    );
  }

  /// Constructor para círculo con imagen personalizada
  factory StatusCircleData.imageCircle({
    required bool isActive,
    required Color color,
    required String imagePath,
    VoidCallback? onTap,
  }) {
    return StatusCircleData(
      isActive: isActive,
      color: color,
      icon: Icons.image, // Icono por defecto, aunque no se usará
      imagePath: imagePath,
      svgPath: null,
      onTap: onTap,
    );
  }
  
  /// Constructor para círculo con imagen SVG personalizada
  factory StatusCircleData.svgCircle({
    required bool isActive,
    required Color color,
    required String svgPath,
    VoidCallback? onTap,
  }) {
    return StatusCircleData(
      isActive: isActive,
      color: color,
      icon: Icons.image, // Icono por defecto, aunque no se usará
      imagePath: null,
      svgPath: svgPath,
      onTap: onTap,
    );
  }
} 