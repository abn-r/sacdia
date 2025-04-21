import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/honor/cubit/honor_categories_cubit.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/honor/models/honor_category_model.dart';
import 'package:sacdia/features/honor/models/honor_model.dart';

class AddHonorScreen extends StatefulWidget {
  const AddHonorScreen({Key? key}) : super(key: key);

  @override
  State<AddHonorScreen> createState() => _AddHonorScreenState();
}

class _AddHonorScreenState extends State<AddHonorScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HonorCategory> _filteredCategories = [];
  Honor? _selectedHonor;
  File? _certificateFile;
  List<File> _images = [];
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

  Future<void> _pickCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _certificateFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar el certificado: $e')),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedImages = await picker.pickMultiImage();

      if (pickedImages.isNotEmpty) {
        setState(() {
          _images.addAll(pickedImages.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imágenes: $e')),
      );
    }
  }

  Future<void> _saveHonor() async {
    if (_selectedHonor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione una especialidad'),
        ),
      );
      return;
    }

    if (_certificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, adjunte el certificado en PDF'),
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, adjunte al menos una imagen'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<UserHonorsCubit>().createUserHonor(
            honorId: _selectedHonor!.honorId,
            certificateFile: _certificateFile,
            images: _images,
          );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la especialidad: $e'),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sacRed,
        elevation: 0,
        title: const Text(
          'AGREGAR ESPECIALIDAD',
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
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onChanged: _filterHonors,
              ),
            ),

            // Especialidad seleccionada
            if (_selectedHonor != null)
              SelectedHonorWidget(
                honor: _selectedHonor!,
                onRemove: () {
                  setState(() {
                    _selectedHonor = null;
                  });
                },
              ),

            // Archivos adjuntos
            if (_selectedHonor != null)
              AttachmentSection(
                certificateFile: _certificateFile,
                images: _images,
                onPickCertificate: _pickCertificate,
                onPickImages: _pickImages,
                onRemoveCertificate: () {
                  setState(() {
                    _certificateFile = null;
                  });
                },
                onRemoveImage: (int index) {
                  setState(() {
                    _images.removeAt(index);
                  });
                },
              ),

            // Lista de especialidades
            Expanded(
              child: BlocBuilder<HonorCategoriesCubit, HonorCategoriesState>(
                builder: (context, state) {
                  if (state is HonorCategoriesLoading && _allCategories.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: sacRed),
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
                      return CategorySection(
                        category: category,
                        signedUrlCache: _signedUrlCache,
                        getSignedImageUrl: _getSignedImageUrl,
                        selectedHonorId: _selectedHonor?.honorId,
                        onHonorSelected: (honor) {
                          setState(() {
                            _selectedHonor = honor;
                          });
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
      bottomNavigationBar: _selectedHonor != null
          ? Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveHonor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sacRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar Especialidad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            )
          : null,
    );
  }
}

// Widget para mostrar la especialidad seleccionada
class SelectedHonorWidget extends StatelessWidget {
  final Honor honor;
  final VoidCallback onRemove;

  const SelectedHonorWidget({
    Key? key,
    required this.honor,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: sacYellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  honor.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (honor.description != null)
                  Text(
                    honor.description!,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// Widget para la sección de archivos adjuntos
class AttachmentSection extends StatelessWidget {
  final File? certificateFile;
  final List<File> images;
  final VoidCallback onPickCertificate;
  final VoidCallback onPickImages;
  final VoidCallback onRemoveCertificate;
  final Function(int) onRemoveImage;

  const AttachmentSection({
    Key? key,
    required this.certificateFile,
    required this.images,
    required this.onPickCertificate,
    required this.onPickImages,
    required this.onRemoveCertificate,
    required this.onRemoveImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Archivos Adjuntos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPickCertificate,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Certificado PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sacBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPickImages,
                  icon: const Icon(Icons.image),
                  label: const Text('Imágenes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sacGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (certificateFile != null)
            ListTile(
              leading: const Icon(Icons.file_present),
              title: Text(
                certificateFile!.path.split('/').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onRemoveCertificate,
              ),
            ),
          if (images.isNotEmpty) ...[
            const Text(
              'Imágenes seleccionadas:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.file(
                          images[index],
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget para cada sección de categoría
class CategorySection extends StatelessWidget {
  final HonorCategory category;
  final Map<String, String> signedUrlCache;
  final Future<String> Function(String?) getSignedImageUrl;
  final int? selectedHonorId;
  final Function(Honor) onHonorSelected;

  const CategorySection({
    Key? key,
    required this.category,
    required this.signedUrlCache,
    required this.getSignedImageUrl,
    required this.selectedHonorId,
    required this.onHonorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          title: Text(
            category.categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
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
                );
              },
            ),
          ],
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

  const HonorItem({
    Key? key,
    required this.honor,
    required this.signedUrlCache,
    required this.getSignedImageUrl,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSelected,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isSelected
                      ? sacRed
                      : const Color(0xFFFCD34D),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: honor.honorImage != null && honor.honorImage!.isNotEmpty
                  ? _buildHonorImage()
                  : const Center(
                      child: Text(
                        "Imagen",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => _buildErrorWidget(),
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: sacRed,
              ),
            ),
          );
        }
        
        final imageUrl = snapshot.data ?? '';
        if (imageUrl.isEmpty) {
          return _buildErrorWidget();
        }
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => _buildErrorWidget(),
          ),
        );
      },
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[350],
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
