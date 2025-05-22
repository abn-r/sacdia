import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/honor/models/honor_model.dart';
import 'package:sacdia/features/honor/models/user_honor_model.dart';
import 'package:sacdia/features/honor/presentation/screens/add_user_honor_screen.dart';

class UserHonorDetailScreen extends StatelessWidget {
  final UserHonor honor;
  final Color categoryColor;
  final String?
      preloadedImageUrl; // URL de la imagen ya cargada desde la pantalla anterior

  const UserHonorDetailScreen({
    super.key,
    required this.honor,
    required this.categoryColor,
    this.preloadedImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Verificar si es la categoría "Estudio de la Naturaleza"
    final bool isNatureCategory = categoryColor == catNaturaleza;

    final Color textColor = isNatureCategory ? sacBlack : Colors.white;

    // Obtener el cubit desde GetIt
    final userHonorsCubit = GetIt.I<UserHonorsCubit>();

    return BlocProvider.value(
      value: userHonorsCubit,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: categoryColor,
          elevation: 0,
          title: Text(
            honor.honorName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: textColor),
          actions: [
            // Botón de edición
            IconButton(
              icon: Icon(Icons.edit, color: textColor),
              tooltip: 'Editar especialidad',
              onPressed: () {
                // Navegar a la pantalla de edición
                _navigateToEditScreen(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner superior con color de la categoría
              Container(
                width: double.infinity,
                color: categoryColor,
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 5, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: preloadedImageUrl != null &&
                                preloadedImageUrl!.isNotEmpty
                            // Usar la URL precargada si está disponible (evita una nueva descarga)
                            ? Image.network(
                                preloadedImageUrl!,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  log('❌ Error cargando imagen precargada: $error');
                                  return const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          size: 60, color: Colors.grey),
                                    ),
                                  );
                                },
                              )
                            // Si no hay URL precargada pero hay honor.honorImage, usar método con URL firmada
                            : honor.honorImage != null &&
                                    honor.honorImage!.isNotEmpty
                                ? FutureBuilder<String>(
                                    future: context
                                        .read<UserHonorsCubit>()
                                        .getHonorImageSignedUrl(honor.honorImage),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: Center(
                                            child: CupertinoActivityIndicator(
                                                color: sacBlack),
                                          ),
                                        );
                                      }

                                      final imageUrl = snapshot.data ?? '';
                                      return imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              height: 120,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                log('❌ Error cargando imagen principal: $error');
                                                return const SizedBox(
                                                  height: 120,
                                                  child: Center(
                                                    child: Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                        size: 60,
                                                        color: Colors.grey),
                                                  ),
                                                );
                                              },
                                            )
                                          : const SizedBox(
                                              height: 120,
                                              child: Center(
                                                child: Icon(Icons.image_not_supported,
                                                    size: 60, color: Colors.grey),
                                              ),
                                            );
                                    },
                                  )
                                // Si no hay honor.honorImage ni preloadedImageUrl, mostrar un icono de "No hay imagen"
                                : const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Icon(Icons.image_not_supported,
                                          size: 60, color: Colors.grey),
                                    ),
                                  ),
                      ),
                    ),
                    // Mostrar fecha de obtención si está disponible
                    if (honor.completionDate != null)
                      Center(
                        child: Text(
                          'Especialidad obtenida el ${DateFormat('dd/MM/yyyy').format(honor.completionDate!)}',
                          style: TextStyle(
                            color: textColor.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    // Mostrar estado (validada o pendiente)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: isNatureCategory
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Estado: ${honor.validate ? 'Validada' : 'Pendiente de validación'}',
                          style: TextStyle(
                            color: honor.validate
                                ? sacBlack
                                : Colors.orange[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Imagen principal de la especialidad

              // Certificado (si existe)
              if (honor.certificate != null &&
                  honor.certificate!.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.file_present,
                        color: sacBlack,
                        size: 24,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Certificado',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: sacBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<String>(
                    future: context
                        .read<UserHonorsCubit>()
                        .getUserHonorImageSignedUrl(honor.certificate),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CupertinoActivityIndicator(color: sacBlack),
                        );
                      }

                      final certificateUrl = snapshot.data ?? '';
                      return certificateUrl.isNotEmpty
                          ? _buildImageWithFullscreenOption(
                              context,
                              certificateUrl,
                              'Certificado',
                              height: 200,
                            )
                          : const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No se pudo cargar el certificado'),
                            );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 30),
              // Imágenes de evidencia (si existen)
              if (honor.images.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.image,
                            color: sacBlack,
                            size: 24,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Evidencias',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: sacBlack,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${honor.images.length} ${honor.images.length == 1 ? 'imagen' : 'imágenes'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Grid de imágenes de evidencia
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FutureBuilder<List<String>>(
                    future: context
                        .read<UserHonorsCubit>()
                        .getSignedEvidenceImageUrls(honor.images),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 120,
                          child: Center(
                            child: CupertinoActivityIndicator(color: sacBlack),
                          ),
                        );
                      }

                      final urls =
                          snapshot.data ?? List.filled(honor.images.length, '');

                      // Si hay solo 1 o 2 imágenes, mostrar más grandes
                      if (urls.length <= 2) {
                        return Column(
                          children: urls.map((url) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: _buildImageWithFullscreenOption(
                                context,
                                url,
                                'Evidencia',
                                height: 200,
                              ),
                            );
                          }).toList(),
                        );
                      }

                      // Si hay más de 2 imágenes, mostrar en grid
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: urls.length,
                        itemBuilder: (context, index) {
                          final url = urls[index];
                          return _buildImageWithFullscreenOption(
                            context,
                            url,
                            'Evidencia ${index + 1}',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Sección de estado
              const SizedBox(height: 30),

              // Mostrar material PDF si está disponible
              if (honor.honorMaterial != null && honor.honorMaterial!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        color: sacRed,
                        size: 24,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Material de Estudio',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: sacBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Material PDF'),
                    onPressed: () async {
                      if (honor.honorMaterial != null && honor.honorMaterial!.isNotEmpty) {
                        try {
                          // Obtener la URL firmada del material PDF
                          final pdfUrl = await context
                              .read<UserHonorsCubit>()
                              .getHonorImageSignedUrl(honor.honorMaterial, bucketName: bucketHonorsPdf);
                          
                          if (pdfUrl.isNotEmpty) {
                            // Mostrar la URL (en una app real se lanzaría con url_launcher)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('URL del material: $pdfUrl'),
                                action: SnackBarAction(
                                  label: 'Aceptar',
                                  onPressed: () {},
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo obtener la URL del material'),
                              ),
                            );
                          }
                        } catch (e) {
                          log('❌ Error al obtener URL del PDF: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al obtener material PDF'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sacRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar una imagen con opción de ver a pantalla completa
  Widget _buildImageWithFullscreenOption(
    BuildContext context,
    String imageUrl,
    String title, {
    double? height,
  }) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Mostrar imagen a pantalla completa
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(10),
                  minScale: 0.5,
                  maxScale: 6,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      log('❌ Error cargando imagen a pantalla completa: $error');
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image,
                                size: 60, color: Colors.white54),
                            SizedBox(height: 16),
                            Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Imagen
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    log('❌ Error cargando imagen: $error');
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

              // Icono de pantalla completa
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) async {
    // Obtener la URL firmada de la imagen de la especialidad
    String honorImageUrl = preloadedImageUrl ?? '';
    
    // Si no tenemos la URL precargada pero tenemos la referencia a la imagen, obtenerla
    if (honorImageUrl.isEmpty && honor.honorImage != null && honor.honorImage!.isNotEmpty) {
      try {
        honorImageUrl = await context.read<UserHonorsCubit>().getHonorImageSignedUrl(honor.honorImage);
      } catch (e) {
        log('❌ Error al obtener URL de imagen para edición: $e');
      }
    }
    
    // Determinar si es categoría de naturaleza
    final bool isNatureCategory = categoryColor == catNaturaleza;
    
    // Crear un objeto Honor básico a partir de los datos de UserHonor
    final honorData = Honor(
      honorId: honor.honorId,
      name: honor.honorName,
      honorImage: honor.honorImage,
      honorsCategoryId: 0, // No tenemos esta información en UserHonor, usamos un valor por defecto
    );
    
    // Mostrar un diálogo de carga mientras se prepara la navegación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: 20),
              const Text('Preparando para edición...'),
            ],
          ),
        ),
      ),
    );
    
    // Dar tiempo para que se muestre el diálogo
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Cerrar el diálogo y navegar
    if (context.mounted) {
      Navigator.pop(context); // Cerrar diálogo de carga
      
      // Navegar a la pantalla de edición
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<UserHonorsCubit>(),
            child: AddUserHonorScreen(
              honor: honorData,
              userHonor: honor,
              honorImageUrl: honorImageUrl,
              categoryColor: categoryColor,
              categoryName: isNatureCategory ? 'Estudio de la Naturaleza' : 'Otra Categoría',
              isEditMode: true, // Indicar que estamos en modo edición
            ),
          ),
        ),
      ).then((result) {
        // Si se actualizó correctamente la especialidad, refrescar la pantalla
        if (result == true && context.mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Especialidad actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Volver a la pantalla de perfil para que se recarguen los datos
          Navigator.pop(context, true);
        }
      });
    }
  }
}
