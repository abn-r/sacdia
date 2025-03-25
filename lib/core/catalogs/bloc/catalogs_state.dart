import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';
import 'package:sacdia/features/post_register/models/club_models.dart';

class CatalogsState {
  final List<Country> countries;
  final List<Union> unions;
  final List<LocalField> localFields;
  final List<Club> clubs;
  final List<ClubType> clubTypes;
  final List<Class> classes;

  CatalogsState({
    this.countries = const [],
    this.unions = const [],
    this.localFields = const [],
    this.clubs = const [],
    this.clubTypes = const [],
    this.classes = const []
  });
}

class CatalogsInitial extends CatalogsState {}

class CatalogsLoading extends CatalogsState {}

class CatalogsLoaded extends CatalogsState {
  CatalogsLoaded({
    required super.countries,
    required super.unions,
    required super.localFields,
    super.clubs = const [],
    super.clubTypes = const [],
    super.classes = const []
  });
}

class CatalogsError extends CatalogsState {
  final String message;
  CatalogsError({required this.message});
}



