import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_bloc.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_event.dart' as catalog_events;
import 'package:sacdia/core/catalogs/bloc/catalogs_state.dart';
import 'package:sacdia/features/auth/bloc/auth_bloc.dart';
import 'package:sacdia/features/auth/bloc/auth_event.dart';
import 'package:sacdia/features/auth/repository/auth_repository.dart';
import 'package:sacdia/features/post_register/bloc/post_register_event.dart';
import 'package:sacdia/features/post_register/bloc/post_register_state.dart';
import 'package:sacdia/features/post_register/models/emergency_contact.dart';
import 'package:sacdia/features/post_register/repository/post_register_repository.dart';
import 'package:sacdia/features/post_register/models/personal_info_user_model.dart';
import 'package:sacdia/features/post_register/models/club_models.dart';

class PostRegisterBloc extends Bloc<PostRegisterEvent, PostRegisterState> {
  final _picker = ImagePicker();
  final _cropper = ImageCropper();
  final PostRegisterRepository _repository;
  final AuthRepository _authRepository;
  final AuthBloc _authBloc;
  final CatalogsBloc _catalogsBloc;

  PostRegisterBloc({
    required PostRegisterRepository repository,
    required AuthRepository authRepository,
    required AuthBloc authBloc,
    required CatalogsBloc catalogsBloc,
  })  : _repository = repository,
        _authRepository = authRepository,
        _authBloc = authBloc,
        _catalogsBloc = catalogsBloc,
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
    on<BloodTypeChanged>(_onBloodTypeChanged);
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
    // Club Info
    on<LoadCountriesRequested>(_onLoadCountriesRequested);
    on<CountrySelected>(_onCountrySelected);
    on<LoadUnionsRequested>(_onLoadUnionsRequested);
    on<UnionSelected>(_onUnionSelected);
    on<LoadLocalFieldsRequested>(_onLoadLocalFieldsRequested);
    on<LocalFieldSelected>(_onLocalFieldSelected);
    on<LoadClubsRequested>(_onLoadClubsRequested);
    on<ClubSelected>(_onClubSelected);
    on<ClubTypeSelected>(_onClubTypeSelected);
    on<ClassSelected>(_onClassSelected);
    on<SaveClubInfoRequested>(_onSaveClubInfoRequested);
    on<CompletePostRegisterRequested>(_onCompletePostRegisterRequested);
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
    // Si estamos en el paso 2 (información personal) y vamos a volver al paso 1,
    // no necesitamos hacer nada con isPersonalInfoSaved
    
    // Si estamos en el paso 3 (último paso) y volvemos al paso 2 (información personal),
    // resetear isPersonalInfoSaved para permitir editar nuevamente
    final bool resetInfoSaved = state.currentStep == 2;
    
    emit(state.copyWith(
      currentStep: state.currentStep - 1,
      isPersonalInfoSaved: resetInfoSaved ? false : state.isPersonalInfoSaved,
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
            state.bloodType != null &&
            state.bloodType!.isNotEmpty &&
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

  void _onBloodTypeChanged(
    BloodTypeChanged event,
    Emitter<PostRegisterState> emit,
  ) {
    emit(state.copyWith(bloodType: event.bloodType));
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
        bloodType: state.bloodType ?? '',
        diseases: state.userDiseases,
        allergies: state.userAllergies,
      );

      await _repository.updateUserInfo(user);
      emit(state.copyWith(
        isLoading: false,
        isPersonalInfoSaved: true,
        canContinue: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isPersonalInfoSaved: false,
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
        errorMessage: null,
      ));
    } catch (e) {
      print('❌ Error al agregar contacto: ${e.toString()}');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al agregar contacto: ${e.toString()}',
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

  // Añadir estos métodos manejadores para eventos de información del club
  void _onClubSelected(ClubSelected event, Emitter<PostRegisterState> emit) {
    emit(state.copyWith(selectedClub: event.club));
  }

  void _onClubTypeSelected(ClubTypeSelected event, Emitter<PostRegisterState> emit) {
    emit(state.copyWith(selectedClubType: event.clubType));
  }

  void _onClassSelected(ClassSelected event, Emitter<PostRegisterState> emit) {
    emit(state.copyWith(selectedClass: event.selectedClass));
  }

  Future<void> _onSaveClubInfoRequested(
    SaveClubInfoRequested event, 
    Emitter<PostRegisterState> emit
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      print('📝 Datos seleccionados:');
      print('País: ${state.selectedCountry?.name}');
      print('País ID: ${state.selectedCountry?.countryId}');
      print('Unión: ${state.selectedUnion?.name}');
      print('Unión ID: ${state.selectedUnion?.unionId}');
      print('Campo Local: ${state.selectedLocalField?.name}');
      print('Campo Local ID: ${state.selectedLocalField?.localFieldId}');
      print('Club: ${state.selectedClub?.name}');
      print('Club ID: ${state.selectedClub?.clubId}');
      print('Tipo de Club: ${state.selectedClubType?.name}');
      print('Tipo de Club ID: ${state.selectedClubType?.clubTypeId}');
      print('Clase: ${state.selectedClass?.name}');
      print('Clase ID: ${state.selectedClass?.classId}');
      
      // Verificar que se seleccionaron todos los datos necesarios
      if (state.selectedCountry == null ||
          state.selectedUnion == null ||
          state.selectedLocalField == null ||
          state.selectedClub == null || 
          state.selectedClubType == null || 
          state.selectedClass == null) {
        throw Exception('Debe seleccionar todos los campos requeridos');
      }
      
      // Llamada al repositorio para guardar la información
      print('📝 Llamando al repositorio para guardar la información');
      await _repository.addUserClubInfo(
        state.selectedCountry!.countryId,
        state.selectedUnion!.unionId,
        state.selectedLocalField!.localFieldId,
        state.selectedClub!.clubId,
        state.selectedClass!.classId
      );

      print('📝 Información guardada exitosamente');
      emit(state.copyWith(
        isLoading: false,
        isClubInfoSaved: true,
        canContinue: true,
        errorMessage: null,
      ));
      
      // Si todo va bien, lanzamos el evento para completar el post-registro
      if (state.isPersonalInfoSaved && state.isUploaded && state.isClubInfoSaved) {
        add(const CompletePostRegisterRequested());
      }
    } catch (e) {
      // Formatear el mensaje de error para hacerlo más amigable
      String errorMessage = e.toString();
      
      // Verificar si es un error de usuario ya registrado
      if (errorMessage.contains('ya está registrado') || 
          errorMessage.contains('already exists')) {
        
        // Determinar si es sobre club o clase
        if (errorMessage.toLowerCase().contains('club')) {
          errorMessage = 'El usuario ya está registrado en este club.';
        } else if (errorMessage.toLowerCase().contains('clase') || 
                 errorMessage.toLowerCase().contains('class')) {
          errorMessage = 'El usuario ya está registrado en esta clase.';
        } else {
          errorMessage = 'El usuario ya está registrado en este club o clase.';
        }
        
        // Si a pesar del error de usuario ya registrado, podemos marcar como exitoso el proceso
        emit(state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
          isClubInfoSaved: true, // A pesar del error, consideramos que se guardó
          canContinue: true,
        ));
        
        // En este caso también consideramos que se ha completado el paso
        if (state.isPersonalInfoSaved && state.isUploaded) {
          add(const CompletePostRegisterRequested());
        }
      } else {
        // Para otros errores, no marcamos como exitoso
        emit(state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
          isClubInfoSaved: false,
        ));
      }
    }
  }
  
  // Método para completar el post-registro
  Future<void> _onCompletePostRegisterRequested(
    CompletePostRegisterRequested event,
    Emitter<PostRegisterState> emit
  ) async {
    try {
      // Verificar que todos los pasos se hayan completado
      if (!state.isPersonalInfoSaved || !state.isUploaded || !state.isClubInfoSaved) {
        print('❌ No se puede completar el post-registro porque no todos los pasos están completos');
        print('isPersonalInfoSaved: ${state.isPersonalInfoSaved}');
        print('isUploaded: ${state.isUploaded}');
        print('isClubInfoSaved: ${state.isClubInfoSaved}');
        return;
      }
      
      // Actualizar estado para mostrar que estamos completando el post-registro
      emit(state.copyWith(
        isCompletingPostRegister: true,
        completePostRegisterError: null,
      ));
      
      print('🔄 Completando post-registro...');
      
      // Obtener el ID del usuario actual desde Supabase
      final userId = _authRepository.supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }
      
      // Llamar al método completePostRegister del AuthRepository
      await _authRepository.completePostRegister(userId);
      
      print('✅ Post-registro completado exitosamente');
      
      // Actualizar estado para mostrar que el post-registro está completo
      emit(state.copyWith(
        isCompletingPostRegister: false,
        isPostRegisterCompleted: true,
      ));
      
      // Notificar al AuthBloc que el post-registro está completo
      _authBloc.add(PostRegisterCompleted());
      
    } catch (e) {
      print('❌ Error al completar post-registro: ${e.toString()}');
      
      // Actualizar estado para mostrar el error
      emit(state.copyWith(
        isCompletingPostRegister: false,
        isPostRegisterCompleted: false,
        completePostRegisterError: 'Error al completar el registro: ${e.toString()}',
      ));
      
      // Notificar al AuthBloc que hubo un error al completar el post-registro
      _authBloc.add(PostRegisterFailed(e.toString()));
    }
  }

  // Métodos para País, Unión y Campo Local

  Future<void> _onLoadCountriesRequested(
    LoadCountriesRequested event, 
    Emitter<PostRegisterState> emit
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      // Cargar países usando el repositorio
      final countries = await _repository.getCountries();
      
      print('📊 Países cargados: ${countries.length}');
      
      emit(state.copyWith(
        countries: countries,
        isLoading: false,
        errorMessage: null,
      ));
      
      // Si solo hay un país disponible, seleccionarlo automáticamente
      if (countries.length == 1) {
        print('🔄 Seleccionando automáticamente el único país disponible: ${countries[0].name}');
        add(CountrySelected(countries[0]));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar países: ${e.toString()}',
      ));
    }
  }
  
  void _onCountrySelected(
    CountrySelected event, 
    Emitter<PostRegisterState> emit
  ) {
    emit(state.copyWith(
      selectedCountry: event.country,
      // Limpiar selecciones dependientes
      selectedUnion: null,
      unions: const [],
      selectedLocalField: null,
      localFields: const [],
      selectedClub: null,
      clubs: const [],
    ));
    
    // Cargar las uniones para el país seleccionado
    add(LoadUnionsRequested(event.country.countryId));
  }
  
  Future<void> _onLoadUnionsRequested(
    LoadUnionsRequested event, 
    Emitter<PostRegisterState> emit
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      // Cargar uniones usando el repositorio
      final unions = await _repository.getUnions(event.countryId);
      
      print('📊 Uniones cargadas: ${unions.length} para countryId: ${event.countryId}');
      
      emit(state.copyWith(
        unions: unions,
        isLoading: false,
        errorMessage: null,
      ));
      
      // Si solo hay una unión disponible, seleccionarla automáticamente
      if (unions.length == 1) {
        print('🔄 Seleccionando automáticamente la única unión disponible: ${unions[0].name}');
        add(UnionSelected(unions[0]));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar uniones: ${e.toString()}',
      ));
    }
  }
  
  void _onUnionSelected(
    UnionSelected event, 
    Emitter<PostRegisterState> emit
  ) {
    emit(state.copyWith(
      selectedUnion: event.union,
      // Limpiar selecciones dependientes
      selectedLocalField: null,
      localFields: const [],
      selectedClub: null,
      clubs: const [],
    ));
    
    // Cargar los campos locales para la unión seleccionada
    add(LoadLocalFieldsRequested(event.union.unionId));
  }
  
  Future<void> _onLoadLocalFieldsRequested(
    LoadLocalFieldsRequested event, 
    Emitter<PostRegisterState> emit
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      // Cargar campos locales usando el repositorio
      final localFields = await _repository.getLocalFields(event.unionId);
      
      print('📊 Campos locales cargados: ${localFields.length} para unionId: ${event.unionId}');
      
      emit(state.copyWith(
        localFields: localFields,
        isLoading: false,
        errorMessage: null,
      ));
      
      // Si solo hay un campo local disponible, seleccionarlo automáticamente
      if (localFields.length == 1) {
        print('🔄 Seleccionando automáticamente el único campo local disponible: ${localFields[0].name}');
        add(LocalFieldSelected(localFields[0]));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar campos locales: ${e.toString()}',
      ));
    }
  }
  
  void _onLocalFieldSelected(
    LocalFieldSelected event, 
    Emitter<PostRegisterState> emit
  ) async {
    emit(state.copyWith(
      selectedLocalField: event.localField,
      // Limpiar selecciones dependientes
      selectedClub: null,
      clubs: const [],
    ));
    
    // Cargar los clubes para el campo local seleccionado desde el PostRegisterBloc
    add(LoadClubsRequested(event.localField.localFieldId));
    
    // Cargar los clubes también desde el CatalogsBloc para asegurar que los datos estén disponibles
    _catalogsBloc.add(catalog_events.LoadClubsRequested(event.localField.localFieldId));
    
    // Esperar un momento y volver a intentar cargar los clubes si están vacíos
    Future.delayed(const Duration(milliseconds: 1000), () {
      print('🕒 Verificando si los clubes se cargaron correctamente');
      final catalogsState = _catalogsBloc.state;
      
      if (catalogsState is CatalogsLoaded) {
        final clubs = catalogsState.clubs
            .where((club) => club.localFieldId == event.localField.localFieldId)
            .toList();
            
        print('📊 Clubes disponibles después de delay: ${clubs.length}');
        
        if (clubs.isEmpty) {
          print('⚠️ No se encontraron clubes, intentando cargar nuevamente...');
          _catalogsBloc.add(catalog_events.LoadClubsRequested(event.localField.localFieldId));
          
          // Emitir un nuevo estado para forzar la actualización de la UI
          add(LoadClubsRequested(event.localField.localFieldId));
        }
      }
    });
  }
  
  Future<void> _onLoadClubsRequested(
    LoadClubsRequested event, 
    Emitter<PostRegisterState> emit
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      print('🔍 Consultando clubes para el campo local ID: ${event.localFieldId} directamente desde el repositorio');
      
      // Obtener los clubes como datos brutos del repositorio
      final rawClubs = await _repository.getClubs(event.localFieldId);
      
      // Convertir los datos a objetos Club
      final clubs = rawClubs.map((json) => Club.fromJson(json)).toList();
      
      print('📊 Clubes encontrados desde el repositorio: ${clubs.length} para localFieldId: ${event.localFieldId}');
      
      if (clubs.isNotEmpty) {
        print('📋 Detalles de los clubes obtenidos:');
        for (var club in clubs) {
          print('   - ${club.name} (ID: ${club.clubId})');
        }
      } else {
        print('⚠️ No se encontraron clubes para el campo local ${event.localFieldId}');
      }
      
      // Actualizar el estado con los clubes
      emit(state.copyWith(
        clubs: clubs,
        isLoading: false,
        errorMessage: null,
      ));
      
      // También actualizar el CatalogsBloc para mantener sincronización
      if (clubs.isNotEmpty) {
        print('🔄 Actualizando también el CatalogsBloc con los clubes obtenidos');
        _catalogsBloc.add(catalog_events.LoadClubsRequested(event.localFieldId));
      }
      
      // Si solo hay un club disponible, seleccionarlo automáticamente
      if (clubs.length == 1) {
        print('🔄 Seleccionando automáticamente el único club disponible: ${clubs[0].name}');
        add(ClubSelected(clubs[0]));
      }
    } catch (e) {
      print('❌ Error al cargar clubes: ${e.toString()}');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar clubes: ${e.toString()}',
      ));
    }
  }
}
