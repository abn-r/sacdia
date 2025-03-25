import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_event.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_state.dart';
import 'package:sacdia/core/catalogs/respository/catalogs_repository.dart';

class CatalogsBloc extends Bloc<CatalogsEvent, CatalogsState> {
  final ICatalogsRepository _repository;

  CatalogsBloc({required ICatalogsRepository repository}) 
    : _repository = repository,
      super(CatalogsInitial()) {
    on<LoadCatalogs>(_onLoadCatalogs);
    on<LoadClubsRequested>(_onLoadClubsRequested);
    on<LoadClubTypesRequested>(_onLoadClubTypesRequested);
    on<LoadClassesRequested>(_onLoadClassesRequested);
    on<LoadCountriesRequested>(_onLoadCountriesRequested);
  }

  Future<void> _onLoadCatalogs(
    LoadCatalogs event,
    Emitter<CatalogsState> emit
  ) async {
    emit(CatalogsLoading());
    
    try {
      final countries = await _repository.getCountries();
      final unions = await _repository.getUnions();
      final localFields = await _repository.getLocalFields();
      final clubTypes = await _repository.getClubTypes();
      
      emit(CatalogsLoaded(
        countries: countries,
        unions: unions,
        localFields: localFields,
        clubTypes: clubTypes
      ));
    } catch (e) {
      emit(CatalogsError(message: e.toString()));
    }
  }

  Future<void> _onLoadClubsRequested(
    LoadClubsRequested event,
    Emitter<CatalogsState> emit
  ) async {
    if (state is! CatalogsLoaded) return;
    
    try {
      final currentState = state as CatalogsLoaded;
      final clubs = await _repository.getClubs(event.localFieldId);
      
      emit(CatalogsLoaded(
        countries: currentState.countries,
        unions: currentState.unions,
        localFields: currentState.localFields,
        clubs: clubs,
        clubTypes: currentState.clubTypes,
        classes: currentState.classes
      ));
    } catch (e) {
      // No cambiamos el estado en caso de error para mantener los datos previos
      print('Error al cargar clubes: ${e.toString()}');
    }
  }
  
  Future<void> _onLoadClubTypesRequested(
    LoadClubTypesRequested event,
    Emitter<CatalogsState> emit
  ) async {
    if (state is! CatalogsLoaded) return;
    
    try {
      final currentState = state as CatalogsLoaded;
      final clubTypes = await _repository.getClubTypes();
      
      emit(CatalogsLoaded(
        countries: currentState.countries,
        unions: currentState.unions,
        localFields: currentState.localFields,
        clubs: currentState.clubs,
        clubTypes: clubTypes,
        classes: currentState.classes
      ));
    } catch (e) {
      print('Error al cargar tipos de club: ${e.toString()}');
    }
  }
  
  Future<void> _onLoadClassesRequested(
    LoadClassesRequested event,
    Emitter<CatalogsState> emit
  ) async {
    if (state is! CatalogsLoaded) return;
    
    try {
      final currentState = state as CatalogsLoaded;
      final classes = await _repository.getClasses(event.clubTypeId);
      
      emit(CatalogsLoaded(
        countries: currentState.countries,
        unions: currentState.unions,
        localFields: currentState.localFields,
        clubs: currentState.clubs,
        clubTypes: currentState.clubTypes,
        classes: classes
      ));
    } catch (e) {
      print('Error al cargar clases: ${e.toString()}');
    }
  }

  Future<void> _onLoadCountriesRequested(
    LoadCountriesRequested event,
    Emitter<CatalogsState> emit,
  ) async {
    if (state is! CatalogsLoaded) {
      // Si no hay estado cargado, cargamos todos los catálogos
      add(LoadCatalogs());
      return;
    }
    
    try {
      final currentState = state as CatalogsLoaded;
      final countries = await _repository.getCountries();

      emit(CatalogsLoaded(
        countries: countries,
        unions: currentState.unions,
        localFields: currentState.localFields,
        clubs: currentState.clubs,
        clubTypes: currentState.clubTypes,
        classes: currentState.classes
      ));
    } catch (e) {
      print('Error al cargar países: ${e.toString()}');
    }
  }
}