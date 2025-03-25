import 'package:flutter/material.dart';

/// Representa una característica o funcionalidad de la aplicación
class AppFeature {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String route;
  final List<String> requiredRoles;
  final Color? backgroundColor;
  final bool isEnabled;

  const AppFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    required this.requiredRoles,
    this.backgroundColor,
    this.isEnabled = true,
  });

  /// Verifica si el usuario con los roles dados puede acceder a esta característica
  bool canAccess(List<String> userRoles) {
    return requiredRoles.any((role) => userRoles.contains(role));
  }

  /// Crea una copia de esta característica con algunos campos modificados
  AppFeature copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    String? route,
    List<String>? requiredRoles,
    Color? backgroundColor,
    bool? isEnabled,
  }) {
    return AppFeature(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      requiredRoles: requiredRoles ?? this.requiredRoles,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
} 