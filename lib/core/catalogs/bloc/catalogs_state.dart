import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';


class CatalogsState {
  final List<Country> countries;
  final List<Union> unions;
  final List<LocalField> localFields;

  CatalogsState({
    this.countries = const [],
    this.unions = const [],
    this.localFields = const []
  });
}

class CatalogsInitial extends CatalogsState {}

class CatalogsLoading extends CatalogsState {}

class CatalogsLoaded extends CatalogsState {
  CatalogsLoaded({
    required super.countries,
    required super.unions,
    required super.localFields
  });
}
class CatalogsError extends CatalogsState {
  final String message;
  CatalogsError({required this.message});
}