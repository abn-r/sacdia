import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/user/cubit/user_allergies_cubit.dart';
import 'package:sacdia/features/user/models/user_allergy_model.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';

class UserAllergiesScreen extends StatelessWidget {
  const UserAllergiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cargar las alergias del usuario cuando se construye la pantalla
    context.read<UserAllergiesCubit>().getUserAllergies();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: sacRed,
        title: const Text(
          'ALERGIAS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddAllergyDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<UserAllergiesCubit, UserAllergiesState>(
          listener: (context, state) {
            if (state is AllergyAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alergia agregada correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AllergyAddError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is AllergyDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alergia eliminada correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AllergyDeleteError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is UserAllergiesLoading) {
              return const Center(
                child: CupertinoActivityIndicator(color: sacRed),
              );
            } else if (state is UserAllergiesLoaded) {
              if (state.allergies.isEmpty) {
                return _buildEmptyState(context);
              } else {
                return _buildAllergiesList(context, state.allergies);
              }
            } else if (state is UserAllergiesError) {
              return _buildErrorState(context, state.message);
            } else {
              return const Center(
                child: CupertinoActivityIndicator(color: sacRed),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes alergias registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tus alergias para que el equipo médico esté informado',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddAllergyDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: sacBlue,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar alergia'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: sacRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar las alergias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<UserAllergiesCubit>().getUserAllergies();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: sacBlue,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesList(
      BuildContext context, List<UserAllergy> allergies) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allergies.length,
      itemBuilder: (context, index) {
        final allergy = allergies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: sacRed.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sacRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_food,
                color: sacRed,
              ),
            ),
            title: Text(
              allergy.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            // subtitle: Text(
            //   allergy.description ?? '',
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: Colors.grey[600],
            //   ),
            // ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: sacRed,
              ),
              onPressed: () {
                _showDeleteAllergyDialog(context, allergy);
              },
            ),
            isThreeLine: false,
          ),
        );
      },
    );
  }

  void _showAddAllergyDialog(BuildContext context) {
    // Cargar el catálogo de alergias cuando se abre el diálogo
    context.read<UserAllergiesCubit>().getCatalogAllergies();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddAllergyDialog();
      },
    );
  }

  void _showDeleteAllergyDialog(BuildContext context, UserAllergy allergy) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar alergia'),
          content: Text('¿Estás seguro que deseas eliminar la alergia "${allergy.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Llamar al método del cubit para eliminar la alergia
                context.read<UserAllergiesCubit>().deleteUserAllergy(allergy.id);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: sacRed),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}

class _AddAllergyDialog extends StatefulWidget {
  @override
  _AddAllergyDialogState createState() => _AddAllergyDialogState();
}

class _AddAllergyDialogState extends State<_AddAllergyDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Allergy> _filteredAllergies = [];
  Allergy? _selectedAllergy;
  bool _isManualEntry = false;
  final TextEditingController _manualNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterAllergies);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAllergies);
    _searchController.dispose();
    _manualNameController.dispose();
    super.dispose();
  }

  void _filterAllergies() {
    final String query = _searchController.text.toLowerCase();
    
    final state = context.read<UserAllergiesCubit>().state;
    if (state is CatalogAllergiesLoaded) {
      setState(() {
        if (query.isEmpty) {
          _filteredAllergies = state.allergies;
        } else {
          _filteredAllergies = state.allergies
              .where((allergy) => allergy.name.toLowerCase().contains(query))
              .toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar alergia'),
      content: SizedBox(
        width: double.maxFinite,
        child: BlocBuilder<UserAllergiesCubit, UserAllergiesState>(
          builder: (context, state) {
            if (state is CatalogAllergiesLoading) {
              return const Center(
                child: CupertinoActivityIndicator(color: sacRed),
              );
            } else if (state is CatalogAllergiesLoaded) {
              // Inicializar la lista filtrada si aún no se ha hecho
              if (_filteredAllergies.isEmpty && _searchController.text.isEmpty) {
                _filteredAllergies = state.allergies;
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle entre catálogo y entrada manual
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Catálogo'),
                              icon: Icon(Icons.list),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Manual'),
                              icon: Icon(Icons.edit),
                            ),
                          ],
                          selected: {_isManualEntry},
                          onSelectionChanged: (Set<bool> selection) {
                            setState(() {
                              _isManualEntry = selection.first;
                              _selectedAllergy = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isManualEntry) ...[
                    TextField(
                      controller: _manualNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la alergia *',
                        hintText: 'Ej. Nueces, Látex, Penicilina',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar alergia',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _filteredAllergies.length,
                        itemBuilder: (context, index) {
                          final allergy = _filteredAllergies[index];
                          final isSelected = _selectedAllergy == allergy;
                          
                          return ListTile(
                            title: Text(allergy.name),
                            selected: isSelected,
                            selectedTileColor: sacRed.withOpacity(0.1),
                            trailing: isSelected 
                                ? const Icon(Icons.check_circle, color: sacRed)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedAllergy = allergy;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            } else if (state is CatalogAllergiesError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: sacRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<UserAllergiesCubit>().getCatalogAllergies();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sacBlue,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Text('Ocurrió un error inesperado'),
              );
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            // Validar y agregar la alergia
            if (_isManualEntry) {
              final name = _manualNameController.text.trim();
              if (name.isNotEmpty) {
                // Crear una nueva alergia con ID 0 para indicar que es manual
                final manualAllergy = Allergy(
                  allergyId: 0,
                  name: name,
                );
                context.read<UserAllergiesCubit>().addUserAllergy(manualAllergy);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes ingresar un nombre para la alergia'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else if (_selectedAllergy != null) {
              context.read<UserAllergiesCubit>().addUserAllergy(_selectedAllergy!);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debes seleccionar una alergia del catálogo'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: sacBlue),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
