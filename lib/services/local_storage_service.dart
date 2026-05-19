import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/timetable_item.dart';
import '../models/user_favorite.dart'; // ← NOUVEAU

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _userFavoritesKey = 'userFavorites';
  static const String _timetableKey = 'timetable';
  static const String _selectedDayKey = 'selectedDay';
  static const String _showFavoritesOnlyKey = 'showFavoritesOnly';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== NOUVELLES MÉTHODES POUR UserFavorite ==========

  // Sauvegarde tous les favoris avec notation
  Future<void> saveUserFavorites(Map<int, UserFavorite> favorites) async {
    final jsonList = favorites.entries
        .map((e) => jsonEncode({'set_id': e.key, ...e.value.toJson()}))
        .toList();
    await _prefs.setStringList(_userFavoritesKey, jsonList);
  }

  // Récupère tous les favoris avec notation
  Future<Map<int, UserFavorite>> getUserFavorites() async {
    final List<String>? jsonList = _prefs.getStringList(_userFavoritesKey);
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

  // Timetable
  Future<void> saveTimetable(List<TimetableItem> timetable) async {
    final List<String> timetableJson = timetable.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_timetableKey, timetableJson);
  }

  Future<List<TimetableItem>> getTimetable() async {
    final List<String>? timetableJson = _prefs.getStringList(_timetableKey);
    if (timetableJson == null) return [];
    return timetableJson
        .map((json) => TimetableItem.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  // Jour sélectionné
  Future<void> saveSelectedDay(String day) async {
    await _prefs.setString(_selectedDayKey, day);
  }

  Future<String> getSelectedDay() async {
    return _prefs.getString(_selectedDayKey) ?? 'friday';
  }

  // Mode "Favoris uniquement"
  Future<void> saveShowFavoritesOnly(bool value) async {
    await _prefs.setBool(_showFavoritesOnlyKey, value);
  }

  Future<bool> getShowFavoritesOnly() async {
    return _prefs.getBool(_showFavoritesOnlyKey) ?? false;
  }
}