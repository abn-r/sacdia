import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  SharedPreferences? _prefs;

  static const String _keyClubTypeSelect = 'clubTypeSelect';
  static const String _keyClubId = 'clubId';
  static const String _keyClubAdvId = 'clubAdvId';
  static const String _keyClubPathfId = 'clubPathfId';
  static const String _keyClubGmId = 'clubGmId';

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Club Type Select
  Future<void> saveClubTypeSelect(int value) async {
    await _initPrefs();
    await _prefs!.setInt(_keyClubTypeSelect, value);
  }

  Future<int> getClubTypeSelect() async {
    await _initPrefs();
    return _prefs!.getInt(_keyClubTypeSelect) ?? 2; // Default to 2 (Pathfinders)
  }

  // Club ID
  Future<void> saveClubId(int? value) async {
    await _initPrefs();
    if (value == null) {
      await _prefs!.remove(_keyClubId);
    } else {
      await _prefs!.setInt(_keyClubId, value);
    }
  }

  Future<int?> getClubId() async {
    await _initPrefs();
    return _prefs!.getInt(_keyClubId);
  }

  // Club Adventurer ID
  Future<void> saveClubAdvId(int? value) async {
    await _initPrefs();
    if (value == null) {
      await _prefs!.remove(_keyClubAdvId);
    } else {
      await _prefs!.setInt(_keyClubAdvId, value);
    }
  }

  Future<int?> getClubAdvId() async {
    await _initPrefs();
    return _prefs!.getInt(_keyClubAdvId);
  }

  // Club Pathfinder ID
  Future<void> saveClubPathfId(int? value) async {
    await _initPrefs();
    if (value == null) {
      await _prefs!.remove(_keyClubPathfId);
    } else {
      await _prefs!.setInt(_keyClubPathfId, value);
    }
  }

  Future<int?> getClubPathfId() async {
    await _initPrefs();
    return _prefs!.getInt(_keyClubPathfId);
  }

  // Club Master Guide ID
  Future<void> saveClubGmId(int? value) async {
    await _initPrefs();
    if (value == null) {
      await _prefs!.remove(_keyClubGmId);
    } else {
      await _prefs!.setInt(_keyClubGmId, value);
    }
  }

  Future<int?> getClubGmId() async {
    await _initPrefs();
    return _prefs!.getInt(_keyClubGmId);
  }
} 