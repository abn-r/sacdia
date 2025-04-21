import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sacRed,
        title: const Text('CONFIGURACIÓN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Contenido principal
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSettingsOption(
                  icon: Icons.person,
                  title: 'Mi cuenta',
                  subtitle: 'Gestiona tu información personal',
                  onTap: () {
                    // Navegar a la pantalla de gestión de cuenta
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.lock,
                  title: 'Cambiar contraseña',
                  subtitle: 'Actualiza tu contraseña',
                  onTap: () {
                    // Navegar a la pantalla de cambio de contraseña
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Configura tus preferencias de notificaciones',
                  onTap: () {
                    // Navegar a la pantalla de notificaciones
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.language,
                  title: 'Idioma',
                  subtitle: 'Cambia el idioma de la aplicación',
                  onTap: () {
                    // Navegar a la pantalla de idioma
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.help,
                  title: 'Ayuda',
                  subtitle: 'Preguntas frecuentes y soporte',
                  onTap: () {
                    // Navegar a la pantalla de ayuda
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.info,
                  title: 'Acerca de',
                  subtitle: 'Información sobre la aplicación',
                  onTap: () {
                    // Navegar a la pantalla de información
                  },
                ),
                _buildSettingsOption(
                  icon: Icons.logout,
                  title: 'Cerrar sesión',
                  subtitle: 'Salir de tu cuenta',
                  onTap: () {
                    // Cerrar sesión
                  },
                  color: sacRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = sacBlack,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 