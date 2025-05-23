import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';
import 'package:sacdia/features/post_register/models/emergency_contact.dart';
import 'package:sacdia/features/post_register/models/club_models.dart';
import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';

abstract class PostRegisterEvent extends Equatable {
  const PostRegisterEvent();

  @override
  List<Object?> get props => [];
}

// General
class NextStepRequested extends PostRegisterEvent {
  const NextStepRequested();
}

class PreviousStepRequested extends PostRegisterEvent {
  const PreviousStepRequested();
}

// PhotoUpload
class PhotoSelected extends PostRegisterEvent {
  final File photo;
  const PhotoSelected(this.photo);

  @override
  List<Object?> get props => [photo];
}

class PickPhotoRequested extends PostRegisterEvent {
  const PickPhotoRequested();
}

class UploadPhotoRequested extends PostRegisterEvent {
  const UploadPhotoRequested();
}

class ResetPhotoRequested extends PostRegisterEvent {
  const ResetPhotoRequested();
}

// Personal Info
class BirthDateChanged extends PostRegisterEvent {
  final DateTime birthDate;
  const BirthDateChanged(this.birthDate);

  @override
  List<Object> get props => [birthDate];
}

class BaptismStatusChanged extends PostRegisterEvent {
  final bool isBaptized;
  const BaptismStatusChanged(this.isBaptized);

  @override
  List<Object> get props => [isBaptized];
}

class BaptismDateChanged extends PostRegisterEvent {
  final DateTime baptismDate;
  const BaptismDateChanged(this.baptismDate);

  @override
  List<Object> get props => [baptismDate];
}

class GenderChanged extends PostRegisterEvent {
  final String gender;
  final String selectedGender;
  const GenderChanged(this.gender, this.selectedGender);

  @override
  List<Object> get props => [gender, selectedGender];
}

class EmergencyContactChanged extends PostRegisterEvent {
  final String name;
  final String phone;
  
  const EmergencyContactChanged({
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, phone];
}

class DiseasesChanged extends PostRegisterEvent {
  final List<Disease> diseases;
  const DiseasesChanged(this.diseases);

  @override
  List<Object> get props => [diseases];
}

class AllergiesChanged extends PostRegisterEvent {
  final List<Allergy> allergies;
  const AllergiesChanged(this.allergies);

  @override
  List<Object> get props => [allergies];
}

class SavePersonalInfoRequested extends PostRegisterEvent {
  const SavePersonalInfoRequested();
}

class LoadDiseasesRequested extends PostRegisterEvent {
  const LoadDiseasesRequested();
}

class LoadAllergiesRequested extends PostRegisterEvent {
  const LoadAllergiesRequested();
}

class LoadEmergencyContactsRequested extends PostRegisterEvent {
  const LoadEmergencyContactsRequested();
}

class LoadRelationshipTypesRequested extends PostRegisterEvent {
  const LoadRelationshipTypesRequested();
}

class AddEmergencyContactRequested extends PostRegisterEvent {
  final String name;
  final String phone;
  final int? relationshipTypeId;
  
  const AddEmergencyContactRequested({
    required this.name,
    required this.phone,
    this.relationshipTypeId,
  });
  
  @override
  List<Object?> get props => [name, phone, relationshipTypeId];
}

// Versión silenciosa que no propaga errores al estado global
class AddEmergencyContactSilent extends PostRegisterEvent {
  final String name;
  final String phone;
  final int? relationshipTypeId;
  final Function(EmergencyContact)? onSuccess;
  final Function(String)? onError;
  
  const AddEmergencyContactSilent({
    required this.name,
    required this.phone,
    this.relationshipTypeId,
    this.onSuccess,
    this.onError,
  });
}

class ClearErrorMessagesRequested extends PostRegisterEvent {
  const ClearErrorMessagesRequested();
}

// Club Info Events
class LoadCountriesRequested extends PostRegisterEvent {
  const LoadCountriesRequested();
}

class CountrySelected extends PostRegisterEvent {
  final Country country;
  
  const CountrySelected(this.country);
  
  @override
  List<Object> get props => [country];
}

class LoadUnionsRequested extends PostRegisterEvent {
  final int countryId;
  
  const LoadUnionsRequested(this.countryId);
  
  @override
  List<Object> get props => [countryId];
}

class UnionSelected extends PostRegisterEvent {
  final Union union;
  
  const UnionSelected(this.union);
  
  @override
  List<Object> get props => [union];
}

class LoadLocalFieldsRequested extends PostRegisterEvent {
  final int unionId;
  
  const LoadLocalFieldsRequested(this.unionId);
  
  @override
  List<Object> get props => [unionId];
}

class LocalFieldSelected extends PostRegisterEvent {
  final LocalField localField;
  
  const LocalFieldSelected(this.localField);
  
  @override
  List<Object> get props => [localField];
}

class LoadClubsRequested extends PostRegisterEvent {
  final int localFieldId;
  
  const LoadClubsRequested(this.localFieldId);
  
  @override
  List<Object> get props => [localFieldId];
}

class ClubSelected extends PostRegisterEvent {
  final Club club;
  
  const ClubSelected(this.club);
  
  @override
  List<Object> get props => [club];
}

class LoadClubTypesRequested extends PostRegisterEvent {
  const LoadClubTypesRequested();
}

class ClubTypeSelected extends PostRegisterEvent {
  final ClubType clubType;
  
  const ClubTypeSelected(this.clubType);
  
  @override
  List<Object> get props => [clubType];
}

class LoadClassesRequested extends PostRegisterEvent {
  final int clubTypeId;
  
  const LoadClassesRequested(this.clubTypeId);
  
  @override
  List<Object> get props => [clubTypeId];
}

class ClassSelected extends PostRegisterEvent {
  final Class selectedClass;
  
  const ClassSelected(this.selectedClass);
  
  @override
  List<Object> get props => [selectedClass];
}

class SaveClubInfoRequested extends PostRegisterEvent {
  const SaveClubInfoRequested();
}

// Evento para completar el post-registro
class CompletePostRegisterRequested extends PostRegisterEvent {
  const CompletePostRegisterRequested();
}

// Evento para cambiar el tipo de sangre
class BloodTypeChanged extends PostRegisterEvent {
  final String bloodType;
  
  const BloodTypeChanged(this.bloodType);
  
  @override
  List<Object> get props => [bloodType];
}

