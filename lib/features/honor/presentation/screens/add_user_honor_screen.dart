import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/honor/cubit/user_honors_cubit.dart';
import 'package:sacdia/features/honor/models/honor_model.dart';
import 'package:sacdia/features/honor/models/user_honor_model.dart';
import 'package:intl/intl.dart';

class UserHonorFormScreen extends StatefulWidget {
  final Honor honor;
  final String honorImageUrl;
  final Color categoryColor;
  final String categoryName;
  final UserHonor? userHonor;
  final bool isEditMode;

  const UserHonorFormScreen({
    super.key,
    required this.honor,
    required this.honorImageUrl,
    required this.categoryColor,
    required this.categoryName,
    this.userHonor,
    this.isEditMode = false,
  });

  @override
  State<UserHonorFormScreen> createState() => _UserHonorFormScreenState();
}

class _UserHonorFormScreenState extends State<UserHonorFormScreen> {
  final List<File> _images = [];
  File? _certificateImage;
  bool _isLoading = false;
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  bool get _isNatureCategory =>
      widget.categoryName == naturaleza ||
      widget.categoryName == "Estudio de la naturaleza";

  Color get _textColor =>
      _isNatureCategory ? Colors.white : widget.categoryColor;

  Color get _buttonColor => _isNatureCategory ? sacBlack : widget.categoryColor;

  Color get _appBarTextColor => _isNatureCategory ? sacBlack : Colors.white;

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedImages = await picker.pickMultiImage();

      if (pickedImages.isNotEmpty) {
        setState(() {
          if (_images.length + pickedImages.length <= 10) {
            _images.addAll(pickedImages.map((xFile) => File(xFile.path)));
          } else {
            final int remainingSlots = 10 - _images.length;
            if (remainingSlots > 0) {
              _images.addAll(
                pickedImages
                    .take(remainingSlots)
                    .map((xFile) => File(xFile.path)),
              );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Solo se pueden agregar hasta 10 imágenes en total.'),
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imágenes: $e')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          if (_images.length < 10) {
            _images.add(File(photo.path));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ya has alcanzado el límite de 10 imágenes.'),
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar la foto: $e')),
      );
    }
  }

  Future<void> _takeCertificatePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          _certificateImage = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar la foto del certificado: $e')),
      );
    }
  }

  Future<void> _pickCertificateImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _certificateImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar la imagen: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _removeCertificateImage() {
    setState(() {
      _certificateImage = null;
    });
  }

  @override
  void initState() {
    super.initState();
    
    // Si estamos en modo edición, cargar los datos existentes
    if (widget.isEditMode && widget.userHonor != null) {
      // Establecer la fecha si está disponible
      if (widget.userHonor!.completionDate != null) {
        _selectedDate = widget.userHonor!.completionDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }
      
      // En modo edición no precargamos imágenes, ya que necesitamos que el usuario las suba de nuevo
      // La API no nos permite ver las imágenes actuales para edición, solo para visualización
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _buttonColor,
              onPrimary: Colors.white,
              onSurface: sacBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Método para mostrar modal de éxito
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isNatureCategory ? sacBlack.withOpacity(0.2) : widget.categoryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: _isNatureCategory ? sacBlack : widget.categoryColor,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              // Título
              Text(
                widget.isEditMode
                    ? '¡Actualizada con éxito!'
                    : '¡Registrada con éxito!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Mensaje
              Text(
                widget.isEditMode
                    ? 'La especialidad "${widget.honor.name}" ha sido actualizada correctamente en tu perfil.'
                    : 'La especialidad "${widget.honor.name}" ha sido registrada correctamente en tu perfil.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Botón
              ElevatedButton(
                onPressed: () {
                  // Cerrar diálogo actual y volver a pantalla principal con resultado éxito
                  Navigator.of(context).pop();
                  
                  // Cerrar pantalla actual con resultado true (esto regresará a AddHonorScreen)
                  Navigator.of(context).pop(true);
                  
                  // No hacer más pop aquí, deja que AddHonorScreen maneje la navegación de vuelta
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para mostrar modal de error
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              // Título
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Mensaje
              Text(
                'Ha ocurrido un error al registrar la especialidad "${widget.honor.name}".\n\n$errorMessage',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Botón
              ElevatedButton(
                onPressed: () {
                  // Solo cerrar el dialog para intentar de nuevo
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Intentar de nuevo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerHonor() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, agrega al menos una imagen de evidencia'),
        ),
      );
      return;
    }

    if (_certificateImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, agrega una imagen del certificado'),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona la fecha de término'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;
      
      // Si estamos en modo edición, actualizar la especialidad existente
      if (widget.isEditMode && widget.userHonor != null) {
        // Actualizar la especialidad existente
        await context.read<UserHonorsCubit>().updateUserHonor(
              userHonorId: widget.userHonor!.userHonorId,
              certificateFile: _certificateImage,
              images: _images,
              completionDate: _selectedDate,
            );
        success = true;
      } else {
        // Crear una nueva especialidad
        await context.read<UserHonorsCubit>().createUserHonor(
              honorId: widget.honor.honorId,
              certificateFile: _certificateImage,
              images: _images,
              completionDate: _selectedDate,
            );
        success = true;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        // Mostrar dialog de éxito
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      // Mostrar dialog de error
      _showErrorDialog(e.toString());
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isNatureCategory ? sacBlack.withOpacity(0.2) : widget.categoryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: _isNatureCategory ? sacBlack : Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              // Título
              const Text(
                '¿Está seguro?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Mensaje
              Column(
                children: [
                  Text(
                    widget.isEditMode 
                      ? 'Estás a punto de actualizar la especialidad "${widget.honor.name}" en tu perfil. ¿Deseas confirmar los cambios?' 
                      : 'Estás a punto de registrar una nueva especialidad en tu perfil. Por favor confirma si deseas registrar la especialidad "${widget.honor.name}".',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Botones
              Row(
                children: [
                  // Botón Cancelar
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        overlayColor: sacBlack,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón Confirmar
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _registerHonor();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.categoryColor,
        elevation: 0,
        title: Text(
          widget.isEditMode ? 'EDITAR ESPECIALIDAD' : 'REGISTRAR ESPECIALIDAD',
          style: TextStyle(
            color: _appBarTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: _appBarTextColor,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: _isNatureCategory
                  ? sacBlack.withOpacity(0.1)
                  : widget.categoryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  // Imagen de la especialidad - usando la URL precargada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: widget.honorImageUrl.isNotEmpty 
                      ? Image.network(
                          widget.honorImageUrl, // Usar la URL precargada
                          height: 150,
                          width: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            log('❌ Error cargando imagen precargada: $error');
                            return Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey[300],
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.image_not_supported, size: 40, color: sacBlack),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.honor.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: sacBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      // Mostrar un placeholder si no hay URL disponible
                      : Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.image_not_supported, size: 40, color: sacBlack),
                                const SizedBox(height: 8),
                                Text(
                                  widget.honor.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: sacBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.honor.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isNatureCategory ? sacBlack : _textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha de término',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isNatureCategory ? sacBlack : _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: _buttonColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _buttonColor,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dateController.text.isEmpty
                                  ? 'Selecciona fecha'
                                  : _dateController.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: _dateController.text.isEmpty
                                    ? Colors.grey[600]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Imagen del certificado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isNatureCategory ? sacBlack : _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickCertificateImage,
                          icon: Icon(Icons.photo_library, color: Colors.white),
                          label: Text(
                            'Galería',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor.withOpacity(0.8),
                            foregroundColor:
                                _isNatureCategory ? sacBlack : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takeCertificatePhoto,
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          label: Text(
                            'Cámara',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor,
                            foregroundColor:
                                _isNatureCategory ? sacBlack : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_certificateImage != null) ...[
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: _buttonColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _certificateImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: _removeCertificateImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _buttonColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color:
                                    _isNatureCategory ? sacBlack : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Imágenes de evidencia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isNatureCategory ? sacBlack : _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: Icon(Icons.photo_library, color: Colors.white),
                          label: Text(
                            'Galería',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor.withOpacity(0.8),
                            foregroundColor:
                                _isNatureCategory ? sacBlack : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takePicture,
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          label: Text(
                            'Cámara',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor,
                            foregroundColor:
                                _isNatureCategory ? sacBlack : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Imágenes seleccionadas:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _buttonColor.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _images[index],
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _buttonColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: _isNatureCategory
                                        ? sacBlack
                                        : Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isNatureCategory ? sacBlack.withOpacity(0.1) : widget.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _buttonColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Para registrar esta especialidad, necesitas:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Una imagen del certificado o comprobante',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '• Entre 1 y 10 fotografías como evidencia',
                      style: TextStyle(fontSize: 14),
                    ),                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _showConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? CupertinoActivityIndicator(
                  color: _isNatureCategory ? sacBlack : widget.categoryColor,
                  radius: 16,
                  )
              : Text(
                  widget.isEditMode ? 'Actualizar' : 'Registrar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// Alias para mantener compatibilidad con el código existente
// Este alias permite que el código que antes usaba AddUserHonorScreen siga funcionando
class AddUserHonorScreen extends UserHonorFormScreen {
  const AddUserHonorScreen({
    super.key,
    required super.honor,
    required super.honorImageUrl,
    required super.categoryColor,
    required super.categoryName,
    super.userHonor,
    super.isEditMode = false,
  });
}
