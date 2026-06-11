import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/timetable_item.dart';
import '../models/user_favorite.dart';
import '../models/stage_model.dart';
import '../models/festival_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _userFavoritesKey = 'userFavorites';
  static const String _timetableKey = 'timetable';
  static const String _stagesKey = 'stages';
  static const String _selectedDayKey = 'selectedDay';
  static const String _showFavoritesOnlyKey = 'showFavoritesOnly';
  static const String _selectedFestivalKey = 'selectedFestival';
  // Clé int lue aussi par le background isolate de géoloc (WorkManager).
  static const String _festivalIdKey = 'festivalId';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== FESTIVAL SÉLECTIONNÉ ==========

  Future<void> saveSelectedFestival(Festival festival) async {
    await _prefs.setString(_selectedFestivalKey, jsonEncode(festival.toJson()));
    await _prefs.setInt(_festivalIdKey, festival.festivalId);
  }

  Future<Festival?> getSelectedFestival() async {
    final raw = _prefs.getString(_selectedFestivalKey);
    if (raw == null) return null;
    try {
      return Festival.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSelectedFestival() async {
    await _prefs.remove(_selectedFestivalKey);
    await _prefs.remove(_festivalIdKey);
  }

  // ========== FAVORIS (namespacés par festival) ==========

  Future<void> saveUserFavorites(Map<int, UserFavorite> favorites, int festivalId) async {
    final jsonList = favorites.entries
        .map((e) => jsonEncode({'set_id': e.key, ...e.value.toJson()}))
        .toList();
    await _prefs.setStringList('${_userFavoritesKey}_$festivalId', jsonList);
  }

  Future<Map<int, UserFavorite>> getUserFavorites(int festivalId) async {
    final List<String>? jsonList = _prefs.getStringList('${_userFavoritesKey}_$festivalId');
    if (jsonList == null) return {};

    return Map<int, UserFavorite>.fromEntries(
      jsonList.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return MapEntry(
          data['set_id'] as int,
          UserFavorite.fromJson(data),
        );
      }),
    );
  }

  // ========== TIMETABLE (namespacée par festival) ==========

  Future<void> saveTimetable(List<TimetableItem> timetable, int festivalId) async {
    final List<String> timetableJson = timetable.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList('${_timetableKey}_$festivalId', timetableJson);
  }

  Future<List<TimetableItem>> getTimetable(int festivalId) async {
    final List<String>? timetableJson = _prefs.getStringList('${_timetableKey}_$festivalId');
    if (timetableJson == null) return [];
    return timetableJson
        .map((json) => TimetableItem.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  // ========== JOUR SÉLECTIONNÉ ==========

  Future<void> saveSelectedDay(String day) async {
    await _prefs.setString(_selectedDayKey, day);
  }

  Future<String?> getSelectedDay() async {
    return _prefs.getString(_selectedDayKey);
  }

  // ========== MODE "FAVORIS UNIQUEMENT" ==========

  Future<void> saveShowFavoritesOnly(bool value) async {
    await _prefs.setBool(_showFavoritesOnlyKey, value);
  }

  Future<bool> getShowFavoritesOnly() async {
    return _prefs.getBool(_showFavoritesOnlyKey) ?? false;
  }

  // ========== SCÈNES (namespacées par festival) ==========

  Future<void> saveStages(List<Stage> stages, int festivalId) async {
    final stagesJson = stages.map((s) => json.encode(s.toJson())).toList();
    await _prefs.setStringList('${_stagesKey}_$festivalId', stagesJson);
  }

  Future<List<Stage>> getStages(int festivalId) async {
    final stagesJson = _prefs.getStringList('${_stagesKey}_$festivalId') ?? [];
    return stagesJson
        .map((jsonStr) => Stage.fromJson(json.decode(jsonStr)))
        .toList();
  }
}
