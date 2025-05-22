import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/honor/cubit/honor_categories_cubit.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/honor/models/honor_category_model.dart';
import 'package:sacdia/features/honor/models/honor_model.dart';
import 'package:sacdia/features/honor/presentation/screens/add_user_honor_screen.dart';

class AddHonorScreen extends StatefulWidget {
  const AddHonorScreen({super.key});

  @override
  State<AddHonorScreen> createState() => _AddHonorScreenState();
}

class _AddHonorScreenState extends State<AddHonorScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HonorCategory> _filteredCategories = [];
  Honor? _selectedHonor;
  bool _isLoading = false;
  
  // Caché para las URLs firmadas
  final Map<String, String> _signedUrlCache = {};
  
  // Lista completa de categorías
  List<HonorCategory> _allCategories = [];

  @override
  void initState() {
    super.initState();
    // Cargar las categorías de especialidades al iniciar la pantalla
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cubit = context.read<HonorCategoriesCubit>();
    
    // Si ya están cargadas, usarlas
    if (cubit.state is HonorCategoriesLoaded) {
      final state = cubit.state as HonorCategoriesLoaded;
      setState(() {
        _allCategories = state.categories;
        _filteredCategories = state.categories;
      });
      // Precargar URLs de imágenes
      _precacheImages();
    } else {
      // Si no, cargarlas y esperar
      await cubit.getHonorCategories();
      if (cubit.state is HonorCategoriesLoaded) {
        final state = cubit.state as HonorCategoriesLoaded;
        setState(() {
          _allCategories = state.categories;
          _filteredCategories = state.categories;
        });
        // Precargar URLs de imágenes
        _precacheImages();
      }
    }
  }
  
  // Precargar las URLs firmadas de todas las imágenes
  Future<void> _precacheImages() async {
    final cubit = context.read<HonorCategoriesCubit>();
    
    for (var category in _allCategories) {
      for (var honor in category.honors) {
        if (honor.honorImage != null && honor.honorImage!.isNotEmpty) {
          final url = await cubit.getHonorImageSignedUrl(honor.honorImage);
          _signedUrlCache[honor.honorImage!] = url;
        }
      }
    }
  }
  
  // Obtener URL firmada de la caché o solicitarla si no existe
  Future<String> _getSignedImageUrl(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Si ya está en caché, devolverla inmediatamente
    if (_signedUrlCache.containsKey(imagePath)) {
      return _signedUrlCache[imagePath]!;
    }
    
    // Si no, obtenerla y guardarla en caché
    final url = await context.read<HonorCategoriesCubit>().getHonorImageSignedUrl(imagePath);
    _signedUrlCache[imagePath] = url;
    return url;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHonors(String query) {
    setState(() {
      if (query.isEmpty) {
        // Si no hay búsqueda, mostrar todas las categorías
        _filteredCategories = _allCategories;
      } else {
        // Filtrar por nombre de especialidad
        _filteredCategories = _allCategories
            .map((category) {
              // Filtrar las especialidades dentro de cada categoría
              final filteredHonors = category.honors
                  .where((honor) =>
                      honor.name.toLowerCase().contains(query.toLowerCase()))
                  .toList();

              // Crear una nueva categoría con las especialidades filtradas
              return HonorCategory(
                categoryId: category.categoryId,
                categoryName: category.categoryName,
                categoryDescription: category.categoryDescription,
                categoryIcon: category.categoryIcon,
                honors: filteredHonors,
              );
            })
            .where((category) => category.honors.isNotEmpty)
            .toList();
      }
    });
  }

  // Método para obtener el color de una categoría según su id o nombre
  Color getCategoryColor(HonorCategory category) {
    switch (category.categoryName) {
      case adra:
        return catAdra;
      case agropecuarias:
        return catagropecuarias;
      case cienciaSalud:
        return catCienciasSalud;
      case domesticas:
        return catDomesticas;
      case habilidadesManuales:
        return catHabilidadesManuales;
      case misioneras:
        return catMisioneras;
      case naturaleza:
        return catNaturaleza;
      case profesionales:
        return catProfesionales;
      case recreativas:
        return catRecreativas;
      default:
        // Usar ID como respaldo para asignar un color
        switch (category.categoryId) {
          case 1:
            return catAdra;
          case 2:
            return catagropecuarias;
          case 3:
            return catCienciasSalud;
          case 4:
            return catDomesticas;
          case 5:
            return catHabilidadesManuales;
          case 6:
            return catMisioneras;
          case 7:
            return catNaturaleza;
          case 8:
            return catProfesionales;
          case 9:
            return catRecreativas;
          default:
            return sacBlack; // Color por defecto
        }
    }
  }

  // Método para obtener el icono de una categoría
  IconData getCategoryIcon(HonorCategory category) {
    switch (category.categoryName) {
      case adra:
        return Icons.volunteer_activism;
      case agropecuarias:
        return Icons.agriculture;
      case cienciaSalud:
        return Icons.medical_services;
      case domesticas:
        return Icons.home;
      case habilidadesManuales:
        return Icons.handyman;
      case misioneras:
        return Icons.public;
      case naturaleza:
        return Icons.forest;
      case profesionales:
        return Icons.work;
      case recreativas:
        return Icons.sports_handball;
      default:
        // Usar ID como respaldo
        switch (category.categoryId) {
          case 1:
            return Icons.volunteer_activism;
          case 2:
            return Icons.agriculture;
          case 3:
            return Icons.medical_services;
          case 4:
            return Icons.home;
          case 5:
            return Icons.handyman;
          case 6:
            return Icons.public;
          case 7:
            return Icons.forest;
          case 8:
            return Icons.work;
          case 9:
            return Icons.sports_handball;
          default:
            return Icons.star; // Icono por defecto
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sacRed,
        elevation: 0,
        title: const Text(
          'ESPECIALIDADES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar especialidad...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: sacGrey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onChanged: _filterHonors,
              ),
            ),

            // Lista de especialidades
            Expanded(
              child: BlocBuilder<HonorCategoriesCubit, HonorCategoriesState>(
                builder: (context, state) {
                  if (state is HonorCategoriesLoading && _allCategories.isEmpty) {
                    return const Center(
                      child: CupertinoActivityIndicator(color: sacBlack),
                    );
                  } else if (state is HonorCategoriesError && _allCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: sacRed,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<HonorCategoriesCubit>()
                                  .getHonorCategories();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: sacRed),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_filteredCategories.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron especialidades',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      final categoryColor = getCategoryColor(category);
                      final categoryIcon = getCategoryIcon(category);
                      
                      return CategorySection(
                        category: category,
                        signedUrlCache: _signedUrlCache,
                        getSignedImageUrl: _getSignedImageUrl,
                        selectedHonorId: _selectedHonor?.honorId,
                        categoryColor: categoryColor,
                        categoryIcon: categoryIcon,
                        onHonorSelected: (honor) async {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          // Mostrar indicador de carga mientras se obtiene la URL
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CupertinoActivityIndicator(radius: 16),
                                      const SizedBox(height: 15),
                                      const Text("Cargando imagen...", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                          
                          String imageUrl = '';
                          
                          try {
                            // Primero verificar si ya tenemos la URL en caché
                            if (honor.honorImage != null && _signedUrlCache.containsKey(honor.honorImage!)) {
                              imageUrl = _signedUrlCache[honor.honorImage!]!;
                              print("✅ Usando URL de caché para ${honor.name}: ${imageUrl.substring(0, 50)}...");
                            } 
                            // Si no está en caché, solicitarla explícitamente y esperar
                            else if (honor.honorImage != null && honor.honorImage!.isNotEmpty) {
                              print("⏳ Obteniendo URL firmada para ${honor.name}...");
                              imageUrl = await _getSignedImageUrl(honor.honorImage);
                              print("✅ URL obtenida para ${honor.name}: ${imageUrl.isEmpty ? 'VACÍA' : imageUrl.substring(0, 50) + '...'}");
                            }
                          } catch (e) {
                            print("❌ Error obteniendo URL: $e");
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                          
                          // Cerrar diálogo de carga
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          
                          // Solo navegar si el contexto aún está montado
                          if (context.mounted) {
                            // Navegar a la pantalla de agregar especialidad detallada
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                  value: context.read<UserHonorsCubit>(),
                                  child: AddUserHonorScreen(
                                    honor: honor,
                                    honorImageUrl: imageUrl,
                                    categoryColor: categoryColor,
                                    categoryName: category.categoryName,
                                  ),
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                // Si se registró exitosamente, regresar a la pantalla anterior
                                Navigator.pop(context, true);
                              }
                            });
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar la sección de categoría
class CategorySection extends StatelessWidget {
  final HonorCategory category;
  final Map<String, String> signedUrlCache;
  final Future<String> Function(String?) getSignedImageUrl;
  final int? selectedHonorId;
  final Function(Honor) onHonorSelected;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategorySection({
    Key? key,
    required this.category,
    required this.signedUrlCache,
    required this.getSignedImageUrl,
    required this.selectedHonorId,
    required this.onHonorSelected,
    required this.categoryColor,
    required this.categoryIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: category.categoryName == "Estudio de la Naturaleza" ? sacBlack : categoryColor,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: category.categoryName == "Estudio de la Naturaleza" ? sacBlack : categoryColor,
            ),
            unselectedWidgetColor: category.categoryName == "Estudio de la Naturaleza" ? sacBlack : categoryColor,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: category.categoryName == "Estudio de la Naturaleza" 
                      ? sacBlack.withOpacity(0.5) 
                      : categoryColor.withOpacity(0.5),
                  width: 1.5,
                ),
                bottom: BorderSide(
                  color: category.categoryName == "Estudio de la Naturaleza" 
                      ? sacBlack.withOpacity(0.5) 
                      : categoryColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: ExpansionTile(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: category.categoryName != "Estudio de la Naturaleza" ? Colors.white : sacBlack,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: category.categoryName != "Estudio de la Naturaleza" ? categoryColor : sacBlack,
                      ),
                    ),
                  ),
                ],
              ),
              collapsedBackgroundColor: categoryColor.withOpacity(0.1),
              backgroundColor: categoryColor.withOpacity(0.05),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: category.honors.length,
                  itemBuilder: (context, index) {
                    final honor = category.honors[index];
                    return HonorItem(
                      honor: honor,
                      signedUrlCache: signedUrlCache,
                      getSignedImageUrl: getSignedImageUrl,
                      isSelected: selectedHonorId == honor.honorId,
                      onSelected: () => onHonorSelected(honor),
                      categoryColor: categoryColor,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Widget para cada especialidad individual
class HonorItem extends StatelessWidget {
  final Honor honor;
  final Map<String, String> signedUrlCache;
  final Future<String> Function(String?) getSignedImageUrl;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color categoryColor;

  const HonorItem({
    Key? key,
    required this.honor,
    required this.signedUrlCache,
    required this.getSignedImageUrl,
    required this.isSelected,
    required this.onSelected,
    required this.categoryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSelected,
            child: honor.honorImage != null && honor.honorImage!.isNotEmpty
                ? _buildHonorImage()
                : const Center(
                    child: CupertinoActivityIndicator(
                      color: sacBlack,
                      radius: 10,
                      animating: true,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        
        Text(
          honor.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? categoryColor : sacBlack,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildHonorImage() {
    // Si ya tenemos la URL en caché, mostrar la imagen directamente
    if (honor.honorImage != null && signedUrlCache.containsKey(honor.honorImage!)) {
      final imageUrl = signedUrlCache[honor.honorImage!]!;
      return Container(
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: categoryColor, width: 3) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            errorBuilder: (context, _, __) => _buildErrorWidget(),
          ),
        ),
      );
    }
    
    // Si no, usar FutureBuilder pero guardando en caché
    return FutureBuilder<String>(
      future: getSignedImageUrl(honor.honorImage),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CupertinoActivityIndicator(
                color: sacRed,
              ),
            ),
          );
        }
        
        final imageUrl = snapshot.data ?? '';
        if (imageUrl.isEmpty) {
          return _buildErrorWidget();
        }
        
        return Container(
          decoration: BoxDecoration(
            border: isSelected ? Border.all(color: categoryColor, width: 3) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => _buildErrorWidget(),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        border: isSelected ? Border.all(color: categoryColor, width: 3) : null,
        color: Colors.grey[350],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.error_outline,
          size: 30,
          color: sacBlack,
        ),
      ),
    );
  }
}
