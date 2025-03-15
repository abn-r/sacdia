import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_event.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_state.dart';
import 'package:sacdia/core/catalogs/respository/catalogs_repository.dart';

class CatalogsBloc extends Bloc<CatalogsEvent, CatalogsState> {
  final CatalogsRepository _repository;

  CatalogsBloc({required CatalogsRepository repository}) 
    : _repository = repository,
      super(CatalogsInitial()) {
    on<LoadCatalogs>(_onLoadCatalogs);
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
      
      emit(CatalogsLoaded(
        countries: countries,
        unions: unions,
        localFields: localFields
      ));
    } catch (e) {
      emit(CatalogsError(message: e.toString()));
    }
  }
}