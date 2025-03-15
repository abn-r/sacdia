import 'dart:io';

class PhotoUploadData {
  final File? selectedPhoto;
  final bool isUploading;
  final bool isUploaded;
  final String? errorMessage;

  PhotoUploadData({
    this.selectedPhoto,
    required this.isUploading,
    required this.isUploaded,
    this.errorMessage,
  });
}