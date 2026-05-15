import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // ✅ Pour jsonEncode/jsonDecode
import '../models/timetable_item.dart'; // ✅ Import de TimetableItem

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _favoritesKey = 'favorites';
  static const String _timetableKey = 'timetable';
  static const String _selectedDayKey = 'selectedDay';
  static const String _showFavoritesOnlyKey = 'showFavoritesOnly';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favoris
  Future<void> saveFavorites(Set<int> favorites) async {
    await _prefs.setStringList(_favoritesKey, favorites.map((e) => e.toString()).toList());
  }

  Future<Set<int>> getFavorites() async {
    final List<String>? favorites = _prefs.getStringList(_favoritesKey);
    return favorites?.map((e) => int.parse(e)).toSet() ?? {};
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