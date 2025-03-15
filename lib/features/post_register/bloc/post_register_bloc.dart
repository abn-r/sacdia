import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:sacdia/features/post_register/bloc/post_register_event.dart';
import 'package:sacdia/features/post_register/bloc/post_register_state.dart';
import 'package:sacdia/features/post_register/models/emergency_contact.dart';
import 'package:sacdia/features/post_register/repository/post_register_repository.dart';
import 'package:sacdia/features/post_register/models/personal_info_user_model.dart';

class PostRegisterBloc extends Bloc<PostRegisterEvent, PostRegisterState> {
  final _picker = ImagePicker();
  final _cropper = ImageCropper();
  final PostRegisterRepository _repository;

  PostRegisterBloc({required PostRegisterRepository repository})
      : _repository = repository,
        super(const PostRegisterState()) {
    on<NextStepRequested>(_onNextStepRequested);
    on<PreviousStepRequested>(_onPreviousStepRequested);
    // Upload Photo
    on<PhotoSelected>(_onPhotoSelected);
    on<PickPhotoRequested>(_onPickPhotoRequested);
    on<UploadPhotoRequested>(_onUploadPhoto);
    on<ResetPhotoRequested>(_onResetPhoto);
    // Personal Info
    on<BirthDateChanged>(_onBirthDateChanged);
    on<BaptismStatusChanged>(_onBaptismStatusChanged);
    on<BaptismDateChanged>(_onBaptismDateChanged);
    on<GenderChanged>(_onGenderChanged);
    on<EmergencyContactChanged>(_onEmergencyContactChanged);
    on<DiseasesChanged>(_onDiseasesChanged);
    on<AllergiesChanged>(_onAllergiesChanged);
    on<SavePersonalInfoRequested>(_onSavePersonalInfoRequested);
    on<LoadDiseasesRequested>(_onLoadDiseasesRequested);
    on<LoadAllergiesRequested>(_onLoadAllergiesRequested);
    on<LoadEmergencyContactsRequested>(_onLoadEmergencyContactsRequested);
    on<LoadRelationshipTypesRequested>(_onLoadRelationshipTypesRequested);
    on<AddEmergencyContactRequested>(_onAddEmergencyContactRequested);
    on<AddEmergencyContactSilent>(_onAddEmergencyContactSilent);
    on<ClearErrorMessagesRequested>(_onClearErrorMessagesRequested);
  }

  void _onNextStepRequested(
      NextStepRequested event, Emitter<PostRegisterState> emit) {
    if (state.currentStep >= 2 || !state.canContinue) {
      return;
    }

    emit(state.copyWith(
      currentStep: state.currentStep + 1,
    ));

    _validateStep();
  }

  void _onPreviousStepRequested(
      PreviousStepRequested event, Emitter<PostRegisterState> emit) {
    emit(state.copyWith(
      currentStep: state.currentStep - 1,
    ));
  }

  void _validateStep() {
    switch (state.currentStep) {
      case 0:
        emit(state.copyWith(canContinue: state.isUploaded));
        break;
      case 1:
        // Verificamos todos los campos requeridos del formulario personal
        final bool isPersonalInfoComplete = state.gender != null &&
            state.gender!.isNotEmpty &&
            state.birthDate != null &&
            (state.isBaptized == false ||
                (state.isBaptized == true && state.baptismDate != null)) &&
            state.emergencyContactName != null &&
            state.emergencyContactName!.isNotEmpty &&
            state.emergencyContactPhone != null &&
            state.emergencyContactPhone.toString().length == 10;

        emit(state.copyWith(canContinue: isPersonalInfoComplete));
        break;
      case 2:
        // Validación del paso 3
        break;
    }
  }

  // *****************************************************
  // Upload Photo
  Future<void> _onPickPhotoRequested(
    PickPhotoRequested event,
    Emitter<PostRegisterState> emit,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final croppedFile = await _cropper.cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxHeight: 800,
        maxWidth: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar foto',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black,
          ),
          IOSUiSettings(
            title: 'Recortar foto',
            cancelButtonTitle: 'Cancelar',
            doneButtonTitle: 'Confirmar',
          ),
        ],
      );

      if (croppedFile == null) return;

      add(PhotoSelected(File(croppedFile.path)));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Error al seleccionar o recortar la foto'));
    }
  }

  void _onPhotoSelected(PhotoSelected event, Emitter<PostRegisterState> emit) {
    emit(state.copyWith(
      selectedPhoto: event.photo,
      isUploaded: false,
      errorMessage: null,
    ));
  }

  Future<void> _onUploadPhoto(
      UploadPhotoRequested event, Emitter<PostRegisterState> emit) async {
    try {
      emit(state.copyWith(isUploading: true, errorMessage: null));

      final result =
          await _repository.uploadProfilePicture(state.selectedPhoto!);

      emit(state.copyWith(
        isUploading: false,
        isUploaded: true,
        errorMessage: null,
      ));

      _validateStep();
    } catch (error) {
      emit(state.copyWith(
          isUploading: false,
          isUploaded: false,
          errorMessage: 'Error al subir la foto: ${error.toString()}'));
    }
  }

  void _onResetPhoto(
      ResetPhotoRequested event, Emitter<PostRegisterState> emit) async {
    emit(state.copyWith(
      selectedPhoto: null,
      isUploaded: false,
      isUploading: false,
      errorMessage: null,
    ));
    add(const PickPhotoRequested());
  }

  // *****************************************************
  // Personal Info
  // *****************************************************

  void _onBirthDateChanged(
    BirthDateChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(birthDate: event.birthDate));
    _validateStep();
  }

  void _onBaptismStatusChanged(
    BaptismStatusChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(
      isBaptized: event.isBaptized,
      baptismDate: event.isBaptized ? state.baptismDate : null,
    ));
    _validateStep();
  }

  void _onBaptismDateChanged(
    BaptismDateChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(baptismDate: event.baptismDate));
    _validateStep();
  }

  void _onGenderChanged(
    GenderChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(
      gender: event.gender,
      selectedGender: event.selectedGender,
    ));
    _validateStep();
  }

  void _onEmergencyContactChanged(
    EmergencyContactChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(
      emergencyContactName: event.name,
      emergencyContactPhone: event.phone,
    ));
    _validateStep();
  }

  void _onDiseasesChanged(
    DiseasesChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(userDiseases: event.diseases));
  }

  void _onAllergiesChanged(
    AllergiesChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(userAllergies: event.allergies));
  }

  Future<void> _onSavePersonalInfoRequested(
    SavePersonalInfoRequested event,
    Emitter<PostRegisterState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final user = PersonalInfoUser(        
        gender: state.selectedGender!,
        birthDate: state.birthDate,
        isBaptized: state.isBaptized,
        baptismDate: state.baptismDate,
        diseases: state.userDiseases,
        allergies: state.userAllergies,
      );

      await _repository.updateUserInfo(user);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isSuccess: false,
      ));
    }
  }

  Future<void> _onLoadDiseasesRequested(
    LoadDiseasesRequested event,
    Emitter<PostRegisterState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final diseases = await _repository.getDiseases();

      emit(state.copyWith(
        diseases: diseases,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar enfermedades: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadAllergiesRequested(
    LoadAllergiesRequested event,
    Emitter<PostRegisterState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      print('loadAllergiesRequested');

      final allergies = await _repository.getAllergies();

      emit(state.copyWith(
        allergies: allergies,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar alergias: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadEmergencyContactsRequested(
    LoadEmergencyContactsRequested event,
    Emitter<PostRegisterState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final contacts = await _repository.getEmergencyContacts();
      
      print('📲 Contactos de emergencia cargados: ${contacts.length}');
      if (contacts.isNotEmpty) {
        for (var contact in contacts) {
          print('   - ${contact.name} (Tel: ${contact.phone})');
        }
      }

      // Verificar si los contactos están vacíos
      bool shouldShowModal = contacts.isEmpty;

      emit(state.copyWith(
        emergencyContacts: contacts,
        isLoading: false,
        showEmergencyContactModal: shouldShowModal,
        errorMessage: null,
      ));
    } catch (e) {
      print('❌ Error al cargar contactos: ${e.toString()}');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar contactos: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadRelationshipTypesRequested(
    LoadRelationshipTypesRequested event,
    Emitter<PostRegisterState> emit,
  ) async {
    try {
      // Si ya tenemos tipos de relación, no mostrar el estado de carga
      if (state.relationshipTypes.isNotEmpty) {
        emit(state.copyWith(isLoading: false, errorMessage: null));
        return;
      }

      emit(state.copyWith(isLoading: true, errorMessage: null));

      final types = await _repository.getRelationshipTypes();

      emit(state.copyWith(
        relationshipTypes: types,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      print('Error al cargar tipos de relación: ${e.toString()}');
      
      // Si ya tenemos datos, no mostramos el error
      if (state.relationshipTypes.isNotEmpty) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: null, // No mostramos error si ya hay datos
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Error al cargar tipos de relación',
        ));
      }
    }
  }

  Future<void> _onAddEmergencyContactRequested(
    AddEmergencyContactRequested event,
    Emitter<PostRegisterState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final newContact = await _repository.addEmergencyContact(
          event.name, event.phone, event.relationshipTypeId);

      print('✅ Contacto agregado exitosamente: ${newContact.name}');
      
      // Crear una nueva lista con todos los contactos existentes más el nuevo
      final updatedContacts = List<EmergencyContact>.from(state.emergencyContacts)
        ..add(newContact);
      
      print('📋 Lista actualizada: ${updatedContacts.length} contactos');

      emit(state.copyWith(
        emergencyContacts: updatedContacts,
        isLoading: false,
        isSuccess: true,
        errorMessage: null,
      ));
    } catch (e) {
      print('❌ Error al agregar contacto: ${e.toString()}');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al agregar contacto: ${e.toString()}',
        isSuccess: false,
      ));
    }
  }

  Future<void> _onAddEmergencyContactSilent(
    AddEmergencyContactSilent event,
    Emitter<PostRegisterState> emit,
  ) async {
    // Aquí no actualizamos el estado con el error, solo con éxito
    try {
      emit(state.copyWith(isLoading: true));

      final newContact = await _repository.addEmergencyContact(
          event.name, event.phone, event.relationshipTypeId);

      print('✅ [Silencioso] Contacto agregado exitosamente: ${newContact.name}');
      
      // Crear una nueva lista con todos los contactos existentes más el nuevo
      final updatedContacts = List<EmergencyContact>.from(state.emergencyContacts)
        ..add(newContact);
      
      print('📋 Lista actualizada: ${updatedContacts.length} contactos');

      emit(state.copyWith(
        emergencyContacts: updatedContacts,
        isLoading: false,
      ));

      // Notificar éxito mediante callback
      if (event.onSuccess != null) {
        event.onSuccess!(newContact);
      }
    } catch (e) {
      print('❌ [Silencioso] Error al agregar contacto: ${e.toString()}');
      
      // Solo notificar el error mediante callback, sin cambiar el estado
      emit(state.copyWith(isLoading: false));
      
      if (event.onError != null) {
        event.onError!(e.toString());
      }
    }
  }

  void _onClearErrorMessagesRequested(
    ClearErrorMessagesRequested event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }

  @override
  void onTransition(
      Transition<PostRegisterEvent, PostRegisterState> transition) {
    super.onTransition(transition);
    // print(transition);
  }

  String getRelationshipName(int? relationshipId) {
    if (relationshipId == null) return 'No especificada';
    
    // Buscar en la lista de tipos de relación
    final relationshipType = state.relationshipTypes.firstWhere(
      (type) => type.relationshipTypeId == relationshipId,
      orElse: () => RelationshipType(relationshipTypeId: 0, name: 'Desconocida'),
    );
    
    return relationshipType.name;
  }
}
