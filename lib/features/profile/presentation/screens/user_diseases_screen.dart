import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/user/cubit/user_diseases_cubit.dart';
import 'package:sacdia/features/user/models/disease_model.dart';
import 'package:sacdia/features/user/models/user_disease_model.dart';
import 'package:sacdia/features/post_register/widgets/improved_selection_modal.dart';

class UserDiseasesScreen extends StatefulWidget {
  const UserDiseasesScreen({super.key});

  @override
  State<UserDiseasesScreen> createState() => _UserDiseasesScreenState();
}

class _UserDiseasesScreenState extends State<UserDiseasesScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar las enfermedades del usuario cuando se construye la pantalla
    context.read<UserDiseasesCubit>().getUserDiseases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sacRed,
        title: const Text(
          'ENFERMEDADES',
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
              _showAddDiseaseDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<UserDiseasesCubit, UserDiseasesState>(
          builder: (context, state) {
            if (state is UserDiseasesLoading) {
              return const Center(
                child: CircularProgressIndicator(color: sacRed),
              );
            } else if (state is UserDiseasesLoaded) {
              if (state.diseases.isEmpty) {
                return _buildEmptyState(context);
              } else {
                return _buildDiseasesList(context, state.diseases);
              }
            } else if (state is UserDiseasesError) {
              return _buildErrorState(context, state.message);
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: sacBlack, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text('Cargando enfermedades...',
                        style: TextStyle(color: sacBlack, fontSize: 16)),
                  ],
                ),
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
            Icons.medical_information_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes enfermedades registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tus enfermedades para que el equipo médico esté informado',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddDiseaseDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: sacRed,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 25),
            label: const Text('Agregar Enfermedad',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
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
            'Error al cargar las enfermedades',
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
              context.read<UserDiseasesCubit>().getUserDiseases();
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

  Widget _buildDiseasesList(BuildContext context, List<UserDisease> diseases) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: diseases.length,
      itemBuilder: (context, index) {
        final disease = diseases[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: sacRed.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
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
                Icons.medical_information,
                color: sacRed,
              ),
            ),
            title: Text(
              disease.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (disease.description != null &&
                    disease.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      disease.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Registrada: ${_formatDate(disease.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                if (!disease.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Estado: Inactivo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: sacRed,
              ),
              onPressed: () {
                _showDeleteDiseaseDialog(context, disease);
              },
            ),
            // isThreeLine: true,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddDiseaseDialog(BuildContext context) {
    // Cargar el catálogo de enfermedades
    context.read<UserDiseasesCubit>().loadDiseaseCatalog();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<UserDiseasesCubit, UserDiseasesState>(
        builder: (context, state) {
          if (state is UserDiseasesError) {
            return Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${state.message}',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Incluso cuando está cargando, mostrar el modal con un indicador de carga dentro
          final isLoading = state is UserDiseasesLoading || 
                           (state is DiseaseCatalogLoaded && state.isLoading);
          
          final List<Disease> catalogDiseases = state is DiseaseCatalogLoaded 
              ? state.catalogDiseases 
              : [];
              
          final List<Disease> selectedDiseases = state is DiseaseCatalogLoaded 
              ? state.selectedDiseases 
              : [];

          return ImprovedSelectionModal<Disease>(
            title: 'Seleccionar enfermedades',
            subtitle: 'Selecciona las enfermedades que padeces para que el equipo médico esté informado.',
            items: catalogDiseases,
            selectedItems: selectedDiseases,
            itemBuilder: (disease) => Text(disease.name),
            searchStringBuilder: (disease) => disease.name,
            isLoading: isLoading,
            onConfirm: (selected) {
              if (state is DiseaseCatalogLoaded) {
                final cubit = context.read<UserDiseasesCubit>();
                // Actualizar selección en el cubit
                cubit.updateSelectedDiseases(selected);
                // Guardar enfermedades
                cubit.saveSelectedDiseases().then((success) {
                  if (success && mounted) {
                    // Si el guardado fue exitoso y el widget sigue montado
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enfermedades guardadas correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                });
              }
            },
          );
        },
      ),
    );
  }

  void _showDeleteDiseaseDialog(BuildContext context, UserDisease disease) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Enfermedad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Estás seguro de que deseas eliminar esta enfermedad?',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_information,
                          color: sacRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            disease.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (disease.description != null &&
                        disease.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 26),
                        child: Text(
                          disease.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 26),
                      child: Text(
                        'Registrado: ${_formatDate(disease.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar',
                  style: TextStyle(color: sacBlack, fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  
                  // Usar un ScaffoldMessenger provisional para mayor seguridad
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  
                  // Mostrar indicador de carga
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Eliminando enfermedad...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Llamar al servicio para eliminar la enfermedad
                  final userDiseasesCubit = context.read<UserDiseasesCubit>();
                  final result = await userDiseasesCubit.deleteUserDisease(disease.id);
                  
                  // Verificar si el widget todavía está montado antes de mostrar mensajes
                  if (!mounted) return;
                  
                  // Mostrar el resultado
                  if (result) {
                    // Limpiar snackbars anteriores
                    scaffoldMessenger.clearSnackBars();
                    // Mostrar mensaje de éxito
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Enfermedad "${disease.name}" eliminada correctamente'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // Limpiar snackbars anteriores
                    scaffoldMessenger.clearSnackBars();
                    // Mostrar mensaje de error
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('Error al eliminar la enfermedad'),
                        backgroundColor: sacRed,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Si ocurre un error, asegurarse de cerrar el diálogo
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                  
                  // Registrar el error pero no intentar mostrar UI si hay problemas
                  print('Error al procesar eliminación de enfermedad: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: sacRed,
              ),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
