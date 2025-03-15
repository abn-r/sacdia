import 'package:dio/dio.dart';
import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/constants.dart';

class CatalogsRepository {
  final Dio _dio;
  
  CatalogsRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<Country>> getCountries() async {
    final response = await _dio.get('$api/countries', queryParameters: {
      'skip': 0,
    });
    return (response.data as List)
        .map((json) => Country.fromJson(json))
        .toList();
  }

  Future<List<Union>> getUnions() async {
    final response = await _dio.get('$api/unions');
    return (response.data as List)
        .map((json) => Union.fromJson(json))
        .toList();
  }

  Future<List<LocalField>> getLocalFields() async {
    final response = await _dio.get('$api/local-fields');
    return (response.data as List)
        .map((json) => LocalField.fromJson(json))
        .toList();
  }
}