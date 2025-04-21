import 'package:flutter/material.dart';

class MenuOptionModel {
  final String id;
  final String title;
  final String iconPath;
  final String route;
  final List<String> allowedRoles;
  
  const MenuOptionModel({
    required this.id,
    required this.title,
    required this.iconPath,
    required this.route,
    this.allowedRoles = const ['all'],
  });
  
  /// Comprueba si esta opción de menú está disponible para un rol específico
  bool isAvailableForRole(String? role) {
    if (allowedRoles.contains('all')) {
      return true;
    }
    
    if (role == null) {
      return false;
    }
    
    return allowedRoles.contains(role.toLowerCase());
  }
}

/// Clase para definir las constantes de opciones del menú
class MenuOptions {
  static const MenuOptionModel members = MenuOptionModel(
    id: 'members',
    title: 'Miembros',
    iconPath: 'assets/img/Miembros.png',
    route: '/members',
    allowedRoles: ['director', 'sub-director', 'secretario - tesorero'],
  );
  
  static const MenuOptionModel club = MenuOptionModel(
    id: 'club',
    title: 'Club',
    iconPath: 'assets/img/AdminClub.png',
    route: '/club',
    allowedRoles: ['director', 'sub-director', 'secretario - tesorero'],
  );
  
  static const MenuOptionModel evidenceFolder = MenuOptionModel(
    id: 'evidence_folder',
    title: 'Carpeta de Evidencias',
    iconPath: 'assets/img/CarpetaEvidencias.png',
    route: '/evidence-folder',
    allowedRoles: ['director', 'sub-director', 'secretario - tesorero'],
  );
  
  static const MenuOptionModel finances = MenuOptionModel(
    id: 'finances',
    title: 'Finanzas',
    iconPath: 'assets/img/Finanzas.png',
    route: '/finances',
    allowedRoles: ['director', 'sub-director', 'secretario - tesorero'],
  );
  
  static const MenuOptionModel units = MenuOptionModel(
    id: 'units',
    title: 'Unidades',
    iconPath: 'assets/img/Unidades.png',
    route: '/units',
    allowedRoles: ['director', 'sub-director', 'secretario - tesorero', 'consejero'],
  );
  
  static const MenuOptionModel groupClass = MenuOptionModel(
    id: 'group_class',
    title: 'Clase Agrupada',
    iconPath: 'assets/img/ClaseAgrupada.png',
    route: '/group-class',
    allowedRoles: ['all'],
  );
  
  static const MenuOptionModel clubInsurance = MenuOptionModel(
    id: 'club_insurance',
    title: 'Seguros del Club',
    iconPath: 'assets/img/SeguroClub.png',
    route: '/club-insurance',
    allowedRoles: ['director', 'sub-director', 'secretario - tesorero'],
  );
  
  static const MenuOptionModel inventory = MenuOptionModel(
    id: 'inventory',
    title: 'Inventario',
    iconPath: 'assets/img/Inventario.png',
    route: '/inventory',
    allowedRoles: ['director', 'sub-director', 'secretario - tesorero'],
  );
  
  static const MenuOptionModel resources = MenuOptionModel(
    id: 'resources',
    title: 'Recursos',
    iconPath: 'assets/img/RecursosClub.png',
    route: '/resources',
    allowedRoles: ['all'],
  );
  
  static const MenuOptionModel emergencyContacts = MenuOptionModel(
    id: 'emergency_contacts',
    title: 'Contacto de Emergencia',
    iconPath: 'assets/img/ContactoEmergencia.png',
    route: '/emergency-contacts',
    allowedRoles: ['all'],
  );
  
  /// Lista completa de todas las opciones de menú disponibles
  static final List<MenuOptionModel> allOptions = [
    members,
    club,
    evidenceFolder,
    finances,
    units,
    groupClass,
    clubInsurance,
    inventory,
    resources,
    emergencyContacts,
  ];
  
  /// Obtiene las opciones de menú filtradas por el rol del usuario
  static List<MenuOptionModel> getOptionsForRole(String? role) {
    return allOptions.where((option) => option.isAvailableForRole(role)).toList();
  }
} 