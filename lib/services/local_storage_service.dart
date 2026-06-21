import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/timetable_item.dart';
import '../models/user_model.dart';
import '../models/user_favorite.dart';
import '../models/dj_tag.dart';
import '../models/journal_entry.dart';
import '../models/stage_model.dart';
import '../models/festival_model.dart';
import '../models/event_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _userFavoritesKey = 'userFavorites';
  static const String _allUserFavoritesKey = 'allUserFavorites';
  static const String _djTagsKey = 'djTags';
  static const String _journalKey = 'journal';
  static const String _photoUrlsKey = 'photoUrls';
  static const String _usersKey = 'users';
  static const String _timetableKey = 'timetable';
  static const String _timetableTsKey = 'timetable_ts';
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

  // ========== FAVORIS DE TOUS (Tendances / mode équipe ; par festival) ==========
  // Map<userId, Map<setId, UserFavorite>> aplatie en liste de {user_id, ...fav}.

  Future<void> saveAllUserFavorites(
      Map<int, Map<int, UserFavorite>> data, int festivalId) async {
    final list = <String>[];
    for (final userEntry in data.entries) {
      for (final fav in userEntry.value.values) {
        list.add(jsonEncode({'user_id': userEntry.key, ...fav.toJson()}));
      }
    }
    await _prefs.setStringList('${_allUserFavoritesKey}_$festivalId', list);
  }

  Future<Map<int, Map<int, UserFavorite>>> getAllUserFavorites(
      int festivalId) async {
    final list = _prefs.getStringList('${_allUserFavoritesKey}_$festivalId');
    if (list == null) return {};
    final result = <int, Map<int, UserFavorite>>{};
    for (final s in list) {
      final data = jsonDecode(s) as Map<String, dynamic>;
      final userId = data['user_id'] as int;
      final fav = UserFavorite.fromJson(data);
      result.putIfAbsent(userId, () => {})[fav.setId] = fav;
    }
    return result;
  }

  // ========== TAGS COLLABORATIFS (namespacés par festival) ==========

  Future<void> saveDjTags(List<DjTag> tags, int festivalId) async {
    final list = tags.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList('${_djTagsKey}_$festivalId', list);
  }

  Future<List<DjTag>> getDjTags(int festivalId) async {
    final list = _prefs.getStringList('${_djTagsKey}_$festivalId');
    if (list == null) return [];
    return list
        .map((s) => DjTag.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ========== JOURNAL (notifications programmées ; par festival) ==========

  Future<void> saveJournal(List<JournalEntry> entries, int festivalId) async {
    final list = entries.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('${_journalKey}_$festivalId', list);
  }

  Future<List<JournalEntry>> getJournal(int festivalId) async {
    final list = _prefs.getStringList('${_journalKey}_$festivalId');
    if (list == null) return [];
    return list
        .map((s) => JournalEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ========== ÉQUIPE / UTILISATEURS (globaux : pas par festival) ==========
  // Persistés pour un affichage instantané de l'équipe au lancement (et pour que
  // le numéro de téléphone survive à un redémarrage avant le 1er fetch réseau).

  Future<void> saveUsers(List<User> users) async {
    final list = users.map((u) => jsonEncode(u.toMap())).toList();
    await _prefs.setStringList(_usersKey, list);
  }

  Future<List<User>> getUsers() async {
    final list = _prefs.getStringList(_usersKey);
    if (list == null) return [];
    return list
        .map((s) => User.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ========== URLS DE PHOTOS (globales : les users sont globaux) ==========
  // Mémorise les URLs Firebase Storage résolues pour éviter de relancer
  // listAll() + getDownloadURL() à chaque lancement. Les octets, eux, sont déjà
  // mis en cache disque par cached_network_image → photos affichées instantanément.

  Future<void> savePhotoUrls(Map<int, String?> urls) async {
    // Ne persiste que les entrées NON nulles (users ayant réellement une photo).
    final map = <String, String>{};
    urls.forEach((id, url) {
      if (url != null) map['$id'] = url;
    });
    await _prefs.setString(_photoUrlsKey, jsonEncode(map));
  }

  Future<Map<int, String?>> getPhotoUrls() async {
    final raw = _prefs.getString(_photoUrlsKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(int.parse(k), v as String?));
    } catch (_) {
      return {};
    }
  }

  // ========== TIMETABLE (namespacée par festival) ==========

  Future<void> saveTimetable(List<TimetableItem> timetable, int festivalId) async {
    final List<String> timetableJson = timetable.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList('${_timetableKey}_$festivalId', timetableJson);
    // Horodatage du fetch → permet de savoir si le cache est encore frais
    // (cf. créneaux de rafraîchissement de la timetable).
    await _prefs.setString(
        '${_timetableTsKey}_$festivalId', DateTime.now().toIso8601String());
  }

  /// Date du dernier enregistrement de la timetable (null si jamais).
  DateTime? getTimetableTimestamp(int festivalId) {
    final s = _prefs.getString('${_timetableTsKey}_$festivalId');
    return s == null ? null : DateTime.tryParse(s);
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

  // ========== ÉVÉNEMENTS (namespacés par festival + utilisateur) ==========

  Future<void> saveUserEvents(
      List<Event> events, int festivalId, int userId) async {
    final list = events.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('events_${festivalId}_$userId', list);
  }

  Future<List<Event>> getUserEvents(int festivalId, int userId) async {
    final list = _prefs.getStringList('events_${festivalId}_$userId');
    if (list == null) return [];
    return list
        .map((s) => Event.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
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
