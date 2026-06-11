import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/timetable_item.dart';
import '../models/user_model.dart';
import '../models/user_favorite.dart';
import '../models/stage_model.dart';
import '../models/festival_model.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

// ✅ Clé globale pour precacheImage
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Mode de filtrage de la liste des DJs (lineup & timetable).
enum FavoriteFilterMode {
  normal,       // Tous les DJs
  myFavorites,  // Uniquement mes favoris
  teamFavorites // Favoris d'au moins un utilisateur de l'équipe
}

class AppDataManager {
  // Singleton
  static final AppDataManager _instance = AppDataManager._internal();
  factory AppDataManager() => _instance;
  AppDataManager._internal() {
    _timetable = [];
    _users = [];
    _photoUrls = {};
    _userFavorites = {};
    _allUserFavorites = {};
    _allFavoritesLoaded = false;
    _userEvents = [];
  }

  // Festival sélectionné (état de session, partagé par toutes les pages)
  Festival? _selectedFestival;

  // Données globales (indépendantes de l'utilisateur)
  List<TimetableItem> _timetable = [];
  List<User> _users = [];
  Map<int, String?> _photoUrls = {};

  // Données utilisateur (dépendent de l'utilisateur connecté)
  Map<int, UserFavorite> _userFavorites = {};
  Map<int, Map<int, UserFavorite>> _allUserFavorites = {};
  bool _allFavoritesLoaded = false;
  int? _userId;
  String _selectedDay = 'friday';
  FavoriteFilterMode _filterMode = FavoriteFilterMode.normal;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  // Données scènes (ex-districts)
  List<Stage> _stages = [];
  bool _isLoadingStages = false;

  // Données événements (typées avec Event)
  List<Event> _userEvents = [];
  bool _isLoadingEvents = false;

  // Setter pour le GlobalKey
  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  // Setter pour userId (utile pour events_page)
  void setUserId(int userId) {
    _userId = userId;
  }

  void showSnackBar(String message) {
    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Affiche un message d'erreur
  void _showErrorMessage(String message) {
    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    debugPrint('⚠️ [AppDataManager] $message');
  }

  // ========== FESTIVAL ==========

  Festival? get selectedFestival => _selectedFestival;
  int? get selectedFestivalId => _selectedFestival?.festivalId;

  /// Restaure le festival sélectionné depuis le stockage (appelé au démarrage).
  Future<void> restoreSelectedFestival() async {
    final festival = await LocalStorageService().getSelectedFestival();
    if (festival != null) {
      _selectedFestival = festival;
      ApiService.currentFestivalId = festival.festivalId;
    }
  }

  /// Sélectionne un festival et le persiste (+ propage à ApiService).
  Future<void> setSelectedFestival(Festival festival) async {
    _selectedFestival = festival;
    ApiService.currentFestivalId = festival.festivalId;
    AppTheme.onFestivalChanged(festival.slug);  // thème auto = suit le festival
    await LocalStorageService().saveSelectedFestival(festival);
  }

  /// Désélectionne le festival courant et purge les données associées.
  Future<void> clearSelectedFestival() async {
    _selectedFestival = null;
    ApiService.currentFestivalId = null;
    AppTheme.onFestivalChanged(null);
    await LocalStorageService().clearSelectedFestival();
    reset();
    _stages = [];
  }

  /// Jours du festival, déduits de la timetable et triés par day_int.
  List<String> get festivalDays {
    final dayOrder = <String, int>{};
    for (final item in _timetable) {
      dayOrder.putIfAbsent(item.day, () => item.dayInt);
    }
    final days = dayOrder.keys.toList()
      ..sort((a, b) => dayOrder[a]!.compareTo(dayOrder[b]!));
    return days;
  }

  void _ensureValidSelectedDay() {
    final days = festivalDays;
    if (days.isEmpty) return;
    if (!days.contains(_selectedDay)) {
      _selectedDay = days.first;
      LocalStorageService().saveSelectedDay(_selectedDay);
    }
  }

  // Getters pour les données globales
  List<TimetableItem> get timetable => _timetable;
  List<User> get users => _users;
  Map<int, String?> get photoUrls => _photoUrls;

  // Getter pour tous les favoris
  Map<int, Map<int, UserFavorite>> get allUserFavorites => _allUserFavorites;

  /// Tous les setIds qu'au moins un utilisateur a en favori.
  Set<int> get allUsersFavoriteSetIds {
    final result = <int>{};
    for (final userFavs in _allUserFavorites.values) {
      for (final entry in userFavs.entries) {
        if (entry.value.isFavorite) result.add(entry.key);
      }
    }
    return result;
  }

  /// Liste des utilisateurs ayant mis [setId] en favori.
  List<User> getUsersWhoFavorited(int setId) {
    final result = <User>[];
    for (final entry in _allUserFavorites.entries) {
      if (entry.value[setId]?.isFavorite == true) {
        result.add(_users.firstWhere(
          (u) => u.id == entry.key,
          orElse: () => User(id: entry.key, username: '?'),
        ));
      }
    }
    return result;
  }

  // Getters pour les données utilisateur
  Set<int> get favoriteSetIds => _userFavorites.entries
      .where((entry) => entry.value.isFavorite)
      .map((entry) => entry.key)
      .toSet();

  String get selectedDay => _selectedDay;
  FavoriteFilterMode get filterMode => _filterMode;
  /// Alias pour la compatibilité des vues existantes.
  bool get showFavoritesOnly => _filterMode == FavoriteFilterMode.myFavorites;
  bool get showAllUsersFavorites => _filterMode == FavoriteFilterMode.teamFavorites;
  int? get userId => _userId;

  // Getters pour les scènes
  List<Stage> get stages => _stages;
  bool get isLoadingStages => _isLoadingStages;

  // Getters pour les événements (typé)
  List<Event> get userEvents => _userEvents;
  bool get isLoadingEvents => _isLoadingEvents;

  // Récupère UserFavorite pour un set_id
  UserFavorite? getUserFavorite(int setId) => _userFavorites[setId];

  // Charge les données GLOBALES (timetable + utilisateurs + TOUS les favoris).
  // Les trois requêtes sont indépendantes → on les lance EN PARALLÈLE pour
  // raccourcir nettement le temps de chargement au lancement.
  Future<void> loadAllData() async {
    try {
      await Future.wait([
        loadTimetable(),
        loadUsers(),
        loadAllUserFavorites(),
      ]);
    } catch (e) {
      _showErrorMessage('Erreur lors du chargement des données globales : $e');
      rethrow;
    }
  }

  // Charge la timetable du festival sélectionné
  Future<void> loadTimetable() async {
    final fid = selectedFestivalId;
    if (fid == null) throw Exception('Aucun festival sélectionné.');
    try {
      _timetable = await ApiService.fetchTimetable();
      await LocalStorageService().saveTimetable(_timetable, fid);
    } catch (e) {
      _showErrorMessage('Impossible de charger la timetable depuis le serveur.');
      _timetable = await LocalStorageService().getTimetable(fid);
      rethrow;
    } finally {
      _ensureValidSelectedDay();
    }
  }

  // Charge les utilisateurs présents sur le festival
  Future<void> loadUsers() async {
    try {
      _users = (await ApiService.fetchUsers()).map((map) => User.fromMap(map)).toList();
      _photoUrls.clear();

      // Récupère les URLs de photos EN PARALLÈLE (auparavant : une requête
      // Firebase Storage séquentielle par utilisateur → très lent au lancement).
      await Future.wait(_users.map((user) async {
        final photoUrl = await ProfileService.getPhotoUrl(user.id);
        _photoUrls[user.id] = photoUrl;

        if (photoUrl != null && navigatorKey.currentContext != null) {
          precacheImage(CachedNetworkImageProvider(photoUrl), navigatorKey.currentContext!);
        }
      }));
    } catch (e) {
      _showErrorMessage('Impossible de charger les utilisateurs : $e');
      _users = [];
      _photoUrls.clear();
      rethrow;
    }
  }

  // Charge TOUS les favoris de TOUS les utilisateurs
  Future<void> loadAllUserFavorites() async {
    if (_allFavoritesLoaded) return;

    try {
      final allFavorites = await ApiService.fetchUserFavorites();
      if (allFavorites is Map<int, Map<int, UserFavorite>>) {
        _allUserFavorites = allFavorites;
      } else {
        final favoritesMap = allFavorites as Map<int, UserFavorite>;
        _allUserFavorites = {};
        for (final entry in favoritesMap.entries) {
          final userId = entry.key;
          final userFav = entry.value;
          _allUserFavorites.putIfAbsent(userId, () => {});
          _allUserFavorites[userId]![userFav.setId] = userFav;
        }
      }
      _allFavoritesLoaded = true;
    } catch (e) {
      _showErrorMessage('Impossible de charger les favoris des utilisateurs : $e');
      _allFavoritesLoaded = false;
    }
  }

  // Charge les favoris de l'utilisateur connecté
  Future<void> loadFavorites(int userId) async {
    final fid = selectedFestivalId;
    try {
      _userId = userId;

      if (_allFavoritesLoaded && _allUserFavorites.containsKey(userId)) {
        // Copie shallow pour éviter l'aliasing.
        _userFavorites = Map.from(_allUserFavorites[userId]!);
      } else {
        final serverFavorites = await ApiService.fetchUserFavorites(userId) as Map<int, UserFavorite>;
        _userFavorites = serverFavorites;
      }

      if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);
    } catch (e) {
      _showErrorMessage('Impossible de charger les favoris depuis le serveur.');
      if (fid != null) _userFavorites = await LocalStorageService().getUserFavorites(fid);
      rethrow;
    }
  }

  // Met à jour la photo d'un utilisateur
  void updateUserPhoto(int userId, String? photoUrl) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(photoUrl: photoUrl);
    }
  }

  // Met à jour la localisation d'un utilisateur + scène
  void updateUserLocation(int userId, double lat, double lng, {String? stage}) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        lastLat: lat,
        lastLng: lng,
        lastLocation: stage ?? _users[index].lastLocation,
      );
    }
  }

  // Met à jour le téléphone d'un utilisateur
  void updateUserPhone(int userId, String phoneNumber) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(phoneNumber: phoneNumber);
    }
  }

  // Réinitialisation des données (utilisateur). Conserve le festival sélectionné.
  void reset() {
    _timetable = [];
    _userFavorites = {};
    _allUserFavorites = {};
    _allFavoritesLoaded = false;
    _userId = null;
    _selectedDay = 'friday';
    _filterMode = FavoriteFilterMode.normal;
    _users = [];
    _userEvents = [];
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    LocalStorageService().saveSelectedDay(day);
  }

  void setFilterMode(FavoriteFilterMode mode) {
    _filterMode = mode;
  }

  // Alias pour la compatibilité ascendante (helpers, etc.)
  void setShowFavoritesOnly(bool value) =>
      setFilterMode(value ? FavoriteFilterMode.myFavorites : FavoriteFilterMode.normal);

  void setShowAllUsersFavorites(bool value) =>
      setFilterMode(value ? FavoriteFilterMode.teamFavorites : FavoriteFilterMode.normal);

  // Toggle favori pour un set_id
  Future<void> toggleFavorite(int setId) async {
    final fid = selectedFestivalId;
    final current = _userFavorites[setId];
    final newIsFavorite = current == null ? true : !current.isFavorite;

    _userFavorites[setId] = UserFavorite(
      setId: setId,
      isFavorite: newIsFavorite,
      notation: current?.notation,
    );

    if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);

    if (_userId != null) {
      try {
        final result = await ApiService.toggleUserFavorite(_userId!, setId);
        _userFavorites[setId] = _userFavorites[setId]!.copyWith(isFavorite: result);
        if (_allUserFavorites.containsKey(_userId)) {
          _allUserFavorites[_userId]![setId] = _userFavorites[setId]!;
        }
      } catch (e) {
        _showErrorMessage('Impossible de synchroniser avec le serveur.');
      }
    }
  }

  // Met à jour la notation
  Future<void> rateFavorite(int setId, int? notation) async {
    final fid = selectedFestivalId;
    bool currentIsFavorite = false;
    if (_allUserFavorites.containsKey(_userId) && _allUserFavorites[_userId]!.containsKey(setId)) {
      currentIsFavorite = _allUserFavorites[_userId]![setId]!.isFavorite;
    } else if (_userFavorites.containsKey(setId)) {
      currentIsFavorite = _userFavorites[setId]!.isFavorite;
    }

    // Reconstruction explicite pour pouvoir effacer la notation (null).
    _userFavorites[setId] = UserFavorite(
      setId: setId,
      isFavorite: currentIsFavorite,
      notation: notation,
    );

    if (_userId != null) {
      _allUserFavorites.putIfAbsent(_userId!, () => {})[setId] = _userFavorites[setId]!;
    }

    if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);

    if (_userId != null) {
      try {
        await ApiService.rateUserFavorite(_userId!, setId, notation);
      } catch (e) {
        _showErrorMessage('Impossible de synchroniser la notation.');
      }
    }
  }

  // Synchronise les notations en arrière-plan
  Future<void> syncFavorites() async {
    if (_userId == null) return;
    final fid = selectedFestivalId;
    try {
      for (final entry in _userFavorites.entries) {
        final setId = entry.key;
        final fav = entry.value;
        if (fav.notation != null) {
          await ApiService.rateUserFavorite(_userId!, setId, fav.notation);
        }
      }
      if (_allUserFavorites.containsKey(_userId!)) {
        _allUserFavorites[_userId!] = Map.from(_userFavorites);
      }
      if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);
    } catch (e) {
      _showErrorMessage('Impossible de synchroniser les favoris avec le serveur.');
    }
  }

  // Charge les scènes
  Future<void> loadStages() async {
    if (_stages.isNotEmpty) return;
    final fid = selectedFestivalId;
    if (fid == null) throw Exception('Aucun festival sélectionné.');

    _isLoadingStages = true;
    try {
      _stages = await ApiService.fetchStages();
      await LocalStorageService().saveStages(_stages, fid);
    } catch (e) {
      _showErrorMessage('Impossible de charger les scènes depuis le serveur.');
      _stages = await LocalStorageService().getStages(fid);
      rethrow;
    } finally {
      _isLoadingStages = false;
    }
  }

  // Met à jour une scène
  Future<void> updateStage(String stageName, Map<String, dynamic> coordinates) async {
    final fid = selectedFestivalId;
    try {
      final index = _stages.indexWhere((s) => s.stage == stageName);
      if (index != -1) {
        _stages[index] = _stages[index].copyWith(
          latAvg: coordinates['lat_avg']?.toDouble(),
          lonAvg: coordinates['lon_avg']?.toDouble(),
          latAvd: coordinates['lat_avd']?.toDouble(),
          lonAvd: coordinates['lon_avd']?.toDouble(),
          latArg: coordinates['lat_arg']?.toDouble(),
          lonArg: coordinates['lon_arg']?.toDouble(),
          latArd: coordinates['lat_ard']?.toDouble(),
          lonArd: coordinates['lon_ard']?.toDouble(),
          latRallyPoint: coordinates['lat_rally_point']?.toDouble(),
          lonRallyPoint: coordinates['lon_rally_point']?.toDouble(),
        );
      }

      await ApiService.updateStage(stageName, coordinates);
      if (fid != null) await LocalStorageService().saveStages(_stages, fid);
    } catch (e) {
      _showErrorMessage('Impossible de mettre à jour la scène.');
      rethrow;
    }
  }

  // ========== EVENT MANAGEMENT ==========
  Future<void> loadUserEvents(int userId) async {
    _isLoadingEvents = true;
    try {
      _userEvents = (await ApiService.fetchUserEvents(userId))
          .map((e) => Event.fromJson(e))
          .toList();
    } catch (e) {
      _showErrorMessage('Impossible de charger les événements : $e');
      rethrow;
    } finally {
      _isLoadingEvents = false;
    }
  }

  /// Crée l'événement côté serveur. L'affichage optimiste (insertion immédiate
  /// dans la liste) est géré par l'appelant (EventsPage) pour un retour
  /// instantané ; ici on ne fait que l'I/O réseau + les effets de bord.
  /// Pour "perdu", recharge les utilisateurs (le backend a recalculé les scènes).
  Future<void> createEventRemote(int userId, String eventType) async {
    await ApiService.createEvent(userId: userId, eventType: eventType);
    if (eventType == 'perdu') {
      await loadUsers();
    }
  }

  /// Supprime le dernier événement côté serveur (l'optimisme est géré par l'appelant).
  Future<void> deleteLastEventRemote(int userId) async {
    await ApiService.deleteLastEvent(userId);
  }

  // ========== GÉOLOCALISATION ==========
  Future<void> updateGeoloc({
    required int userId,
    required double lat,
    required double lng,
    String? stage,
  }) async {
    try {
      await ApiService.updateGeoloc(
        userId: userId,
        lat: lat,
        lng: lng,
        stage: stage,
      );
      updateUserLocation(userId, lat, lng, stage: stage);
    } catch (e) {
      _showErrorMessage('Impossible de mettre à jour la géolocalisation : $e');
      rethrow;
    }
  }
}
