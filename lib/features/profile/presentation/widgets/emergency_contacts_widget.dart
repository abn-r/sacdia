import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/profile/presentation/widgets/emergency_contact_modal.dart';
import 'package:sacdia/features/user/cubit/user_emergency_contacts_cubit.dart';
import 'package:sacdia/features/user/models/emergency_contact_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsWidget extends StatefulWidget {
  const EmergencyContactsWidget({super.key});

  @override
  State<EmergencyContactsWidget> createState() => _EmergencyContactsWidgetState();
}

class _EmergencyContactsWidgetState extends State<EmergencyContactsWidget> {
  // Lista local de contactos que se mantendrá durante toda la vida del widget
  List<EmergencyContact> _currentContacts = [];

  // Función para obtener las iniciales del nombre
  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }

    return '';
  }

  // Función para generar un color basado en el nombre
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    // Usar una simple función hash basada en el nombre
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  @override
  void initState() {
    super.initState();
    // Cargar los contactos iniciales si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserEmergencyContactsCubit>().getEmergencyContacts();
    });
  }

  void _showAddContactModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: EmergencyContactModal(
            onConfirm: (name, phone, relationshipTypeId) async {
              // Cerrar el modal
              Navigator.pop(modalContext);

              // Mostrar indicador de carga
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Guardando contacto...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                    backgroundColor: sacBlue,
                  ),
                );
              }

              // Añadir el contacto sin recargar toda la lista
              await context.read<UserEmergencyContactsCubit>().addEmergencyContact(
                name: name,
                phone: phone,
                relationshipTypeId: relationshipTypeId,
              );

              // Mostrar confirmación
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Contacto de emergencia añadido exitosamente!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  void _showDeleteContactDialog(
      BuildContext context, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Contacto'),
        content: Text('¿Estás seguro que deseas eliminar a ${contact.name} de tus contactos de emergencia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<UserEmergencyContactsCubit>().deleteEmergencyContact(contact.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: sacRed)),
          ),
        ],
      ),
    );
  }

  // Método para realizar llamadas telefónicas
  void _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo realizar la llamada'),
            backgroundColor: sacRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserEmergencyContactsCubit, UserEmergencyContactsState>(
      listener: (context, state) {
        // Manejamos los estados de las operaciones
        if (state is ContactAdded) {
          _currentContacts = [..._currentContacts, state.contact];
        } else if (state is ContactDeleted) {
          _currentContacts.removeWhere((contact) => contact.id == state.contactId);
        } else if (state is UserEmergencyContactsLoaded) {
          _currentContacts = state.contacts;
        } else if (state is ContactOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // Verificamos si es el estado inicial y no tenemos contactos
        bool isInitialLoading = state is UserEmergencyContactsInitial || 
                               (state is UserEmergencyContactsLoading && _currentContacts.isEmpty);
        
        // Si estamos en carga inicial, mostramos el indicador de carga
        if (isInitialLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: sacRed),
            ),
          );
        }
        
        // Si hay un error y no tenemos contactos, mostramos el error
        if (state is UserEmergencyContactsError && _currentContacts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: sacRed,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: const TextStyle(color: sacRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<UserEmergencyContactsCubit>()
                      .getEmergencyContacts(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sacRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // En todos los demás casos, mostramos la lista de contactos
        // incluso durante operaciones de carga para mantener la UI estable
        return _buildContactsList(context);
      },
    );
  }

  Widget _buildContactsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentContacts.isEmpty)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.contact_emergency_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No se han registrado contactos de emergencia aún.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._currentContacts.map((contact) => _buildContactItem(context, contact)).toList(),
          
        // Agregamos un indicador de carga superpuesto cuando hay operaciones en curso
        BlocBuilder<UserEmergencyContactsCubit, UserEmergencyContactsState>(
          builder: (context, state) {
            if (state is UserEmergencyContactsLoading && _currentContacts.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
        
        // Agregamos el botón para añadir contactos
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showAddContactModal(context),
          icon: const Icon(Icons.add, size: 25, color: Colors.white),
          label: const Text('Agregar Contacto', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: sacRed,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, EmergencyContact contact) {
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
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(contact.name),
              child: Text(
                _getInitials(contact.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.relationshipTypeName ??
                        context
                            .read<UserEmergencyContactsCubit>()
                            .getRelationshipName(
                                contact.relationshipTypeId) ??
                        'Relación no especificada',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => _makePhoneCall(context, contact.phone),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 18,
                          color: sacBlack,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          contact.phone,
                          style: const TextStyle(
                            color: sacBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: sacRed,
                size: 22,
              ),
              onPressed: () =>
                  _showDeleteContactDialog(context, contact),
            ),
          ],
        ),
      ),
    );
  }
}
