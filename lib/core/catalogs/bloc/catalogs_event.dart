abstract class CatalogsEvent {}

class LoadCatalogs extends CatalogsEvent {}

class LoadCountriesRequested extends CatalogsEvent {}

class LoadClubsRequested extends CatalogsEvent {
  final int localFieldId;
  
  LoadClubsRequested(this.localFieldId);
}

class LoadClubTypesRequested extends CatalogsEvent {}

class LoadClassesRequested extends CatalogsEvent {
  final int clubTypeId;
  
  LoadClassesRequested(this.clubTypeId);
}