import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';
import 'package:sacdia/features/post_register/models/emergency_contact.dart';

class PostRegisterState extends Equatable {
  final File? selectedPhoto;
  final bool isUploading;
  final bool isUploaded;
  final String? errorMessage;
  final int currentStep;
  final bool canContinue;
  final DateTime? birthDate;
  final bool isBaptized;
  final DateTime? baptismDate;
  final String? gender;
  final String? selectedGender;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactEmail;
  final List<Disease> diseases;
  final List<Disease> userDiseases;
  final List<Allergy> allergies;
  final List<Allergy> userAllergies;
  final bool isLoading;
  final bool isSuccess;
  final List<EmergencyContact> emergencyContacts;
  final List<RelationshipType> relationshipTypes;
  final bool showEmergencyContactModal;

  const PostRegisterState({
    this.selectedPhoto,
    this.isUploading = false,
    this.isUploaded = false,
    this.errorMessage,
    this.currentStep = 0,
    this.canContinue = false,
    this.birthDate,
    this.isBaptized = false,
    this.baptismDate,
    this.gender,
    this.selectedGender,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactEmail,
    this.diseases = const [],
    this.userDiseases = const [],
    this.allergies = const [],
    this.userAllergies = const [],
    this.isLoading = false,
    this.isSuccess = false,
    this.emergencyContacts = const [],
    this.relationshipTypes = const [],
    this.showEmergencyContactModal = false,
  });

  PostRegisterState copyWith({
    File? selectedPhoto,
    bool? isUploading,
    bool? isUploaded,
    String? errorMessage,
    int? currentStep,
    bool? canContinue,
    DateTime? birthDate,
    bool? isBaptized,
    DateTime? baptismDate,
    String? gender,
    String? selectedGender,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactEmail,
    List<Disease>? diseases,
    List<Disease>? userDiseases,
    List<Allergy>? allergies,
    List<Allergy>? userAllergies,
    bool? isLoading,
    bool? isSuccess,
    List<EmergencyContact>? emergencyContacts,
    List<RelationshipType>? relationshipTypes,
    bool? showEmergencyContactModal,
  }) {
    return PostRegisterState(
      selectedPhoto: selectedPhoto ?? this.selectedPhoto,
      isUploading: isUploading ?? this.isUploading,
      isUploaded: isUploaded ?? this.isUploaded,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: errorMessage ?? this.errorMessage,
      canContinue: canContinue ?? this.canContinue,
      birthDate: birthDate ?? this.birthDate,
      isBaptized: isBaptized ?? this.isBaptized,
      baptismDate: baptismDate ?? this.baptismDate,
      gender: gender ?? this.gender,
      selectedGender: selectedGender ?? this.selectedGender,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactEmail: emergencyContactEmail ?? this.emergencyContactEmail,
      diseases: diseases ?? this.diseases,
      userDiseases: userDiseases ?? this.userDiseases,
      allergies: allergies ?? this.allergies,
      userAllergies: userAllergies ?? this.userAllergies,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      relationshipTypes: relationshipTypes ?? this.relationshipTypes,
      showEmergencyContactModal: showEmergencyContactModal ?? this.showEmergencyContactModal,
    );
  }

  @override
  List<Object?> get props => [
        selectedPhoto,
        isUploading,
        isUploaded,
        currentStep,
        errorMessage,
        canContinue,
        birthDate,
        isBaptized,
        baptismDate,
        gender,
        selectedGender,
        emergencyContactName,
        emergencyContactPhone,
        emergencyContactEmail,
        diseases,
        userDiseases,
        allergies,
        userAllergies,
        isLoading,
        isSuccess,
        emergencyContacts,
        relationshipTypes,
        showEmergencyContactModal,
      ];
}