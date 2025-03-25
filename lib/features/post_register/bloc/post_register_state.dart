import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';
import 'package:sacdia/features/post_register/models/emergency_contact.dart';
import 'package:sacdia/features/post_register/models/club_models.dart';
import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';

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
  final String? bloodType;
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
  final bool isPersonalInfoSaved;
  
  // Club info properties
  final List<Country> countries;
  final Country? selectedCountry;
  final List<Union> unions;
  final Union? selectedUnion;
  final List<LocalField> localFields;
  final LocalField? selectedLocalField;
  final List<Club> clubs;
  final Club? selectedClub;
  final List<ClubType> clubTypes;
  final ClubType? selectedClubType;
  final List<Class> classes;
  final Class? selectedClass;
  final bool isClubInfoSaved;
  
  // Post-registro completo
  final bool isPostRegisterCompleted;
  final bool isCompletingPostRegister;
  final String? completePostRegisterError;

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
    this.bloodType,
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
    this.isPersonalInfoSaved = false,
    // Club info defaults
    this.countries = const [],
    this.selectedCountry,
    this.unions = const [],
    this.selectedUnion,
    this.localFields = const [],
    this.selectedLocalField,
    this.clubs = const [],
    this.selectedClub,
    this.clubTypes = const [],
    this.selectedClubType,
    this.classes = const [],
    this.selectedClass,
    this.isClubInfoSaved = false,
    // Post-registro completo
    this.isPostRegisterCompleted = false,
    this.isCompletingPostRegister = false,
    this.completePostRegisterError,
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
    String? bloodType,
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
    bool? isPersonalInfoSaved,
    // Club info parameters
    List<Country>? countries,
    Country? selectedCountry,
    List<Union>? unions,
    Union? selectedUnion,
    List<LocalField>? localFields,
    LocalField? selectedLocalField,
    List<Club>? clubs,
    Club? selectedClub,
    List<ClubType>? clubTypes,
    ClubType? selectedClubType,
    List<Class>? classes,
    Class? selectedClass,
    bool? isClubInfoSaved,
    // Post-registro completo
    bool? isPostRegisterCompleted,
    bool? isCompletingPostRegister,
    String? completePostRegisterError,
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
      bloodType: bloodType ?? this.bloodType,
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
      isPersonalInfoSaved: isPersonalInfoSaved ?? this.isPersonalInfoSaved,
      // Club info
      countries: countries ?? this.countries,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      unions: unions ?? this.unions,
      selectedUnion: selectedUnion ?? this.selectedUnion,
      localFields: localFields ?? this.localFields,
      selectedLocalField: selectedLocalField ?? this.selectedLocalField,
      clubs: clubs ?? this.clubs,
      selectedClub: selectedClub ?? this.selectedClub,
      clubTypes: clubTypes ?? this.clubTypes,
      selectedClubType: selectedClubType ?? this.selectedClubType,
      classes: classes ?? this.classes,
      selectedClass: selectedClass ?? this.selectedClass,
      isClubInfoSaved: isClubInfoSaved ?? this.isClubInfoSaved,
      // Post-registro completo
      isPostRegisterCompleted: isPostRegisterCompleted ?? this.isPostRegisterCompleted,
      isCompletingPostRegister: isCompletingPostRegister ?? this.isCompletingPostRegister,
      completePostRegisterError: completePostRegisterError ?? this.completePostRegisterError,
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
        bloodType,
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
        isPersonalInfoSaved,
        // Club info props
        countries,
        selectedCountry,
        unions,
        selectedUnion,
        localFields,
        selectedLocalField,
        clubs,
        selectedClub,
        clubTypes,
        selectedClubType,
        classes,
        selectedClass,
        isClubInfoSaved,
        // Post-registro completo
        isPostRegisterCompleted,
        isCompletingPostRegister,
        completePostRegisterError,
      ];
}