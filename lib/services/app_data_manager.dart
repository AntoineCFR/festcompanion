import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/timetable_item.dart';
import '../models/user_model.dart';
import '../models/user_favorite.dart';
import '../models/district_model.dart';
import '../models/event_model.dart'; // ✅ Ajouté pour typer les événements
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/profile_service.dart';

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
    _userEvents = []; // Initialisation
  }

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

  // Données districts
  List<District> _districts = [];
  bool _isLoadingDistricts = false;

  // Données événements (typées avec Event)
  List<Event> _userEvents = [];
  bool _isLoadingEvents = false;

  // (remplacé par _filterMode — plus de champ séparé)

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

  // Getters pour les districts
  List<District> get districts => _districts;
  bool get isLoadingDistricts => _isLoadingDistricts;

  // Getters pour les événements (typé)
  List<Event> get userEvents => _userEvents;
  bool get isLoadingEvents => _isLoadingEvents;

  // Récupère UserFavorite pour un set_id
  UserFavorite? getUserFavorite(int setId) => _userFavorites[setId];

  // Charge les données GLOBALES (timetable + utilisateurs + TOUS les favoris)
  Future<void> loadAllData() async {
    try {
      await loadTimetable();
      await loadUsers();
      await loadAllUserFavorites();
    } catch (e) {
      _showErrorMessage('Erreur lors du chargement des données globales : $e');
      rethrow;
    }
  }

  // Charge la timetable (globale)
  Future<void> loadTimetable() async {
    try {
      _timetable = await ApiService.fetchTimetable();
      await LocalStorageService().saveTimetable(_timetable);
    } catch (e) {
      _showErrorMessage('Impossible de charger la timetable depuis le serveur.');
      _timetable = await LocalStorageService().getTimetable();
      rethrow;
    }
  }

  // Charge les utilisateurs (globaux)
  Future<void> loadUsers() async {
    try {
      _users = (await ApiService.fetchUsers()).map((map) => User.fromMap(map)).toList();
      _photoUrls.clear();

      for (final user in _users) {
        final int userId = user.id;
        final photoUrl = await ProfileService.getPhotoUrl(userId);
        _photoUrls[userId] = photoUrl;

        if (photoUrl != null && navigatorKey.currentContext != null) {
          precacheImage(CachedNetworkImageProvider(photoUrl), navigatorKey.currentContext!);
        }
      }
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
    try {
      _userId = userId;

      if (_allFavoritesLoaded && _allUserFavorites.containsKey(userId)) {
        // Copie shallow pour éviter l'aliasing : modifier _userFavorites
        // ne doit pas altérer silencieusement _allUserFavorites et vice-versa.
        _userFavorites = Map.from(_allUserFavorites[userId]!);
      } else {
        final serverFavorites = await ApiService.fetchUserFavorites(userId) as Map<int, UserFavorite>;
        _userFavorites = serverFavorites;
      }

      await LocalStorageService().saveUserFavorites(_userFavorites);
    } catch (e) {
      _showErrorMessage('Impossible de charger les favoris depuis le serveur.');
      _userFavorites = await LocalStorageService().getUserFavorites();
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

  // Met à jour la localisation d'un utilisateur + district
  void updateUserLocation(int userId, double lat, double lng, {String? district}) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        lastLat: lat,
        lastLng: lng,
        lastLocation: district ?? _users[index].lastLocation,
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

  // Réinitialisation des données
  void reset() {
    _timetable = [];
    _userFavorites = {};
    _allUserFavorites = {};
    _allFavoritesLoaded = false;
    _userId = null;
    _selectedDay = 'friday';
    _filterMode = FavoriteFilterMode.normal;
    _users = [];
    _userEvents = []; // ✅ Réinitialisation des événements
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
    final current = _userFavorites[setId];
    final newIsFavorite = current == null ? true : !current.isFavorite;

    _userFavorites[setId] = UserFavorite(
      setId: setId,
      isFavorite: newIsFavorite,
      notation: current?.notation,
    );

    await LocalStorageService().saveUserFavorites(_userFavorites);

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
    bool currentIsFavorite = false;
    if (_allUserFavorites.containsKey(_userId) && _allUserFavorites[_userId]!.containsKey(setId)) {
      currentIsFavorite = _allUserFavorites[_userId]![setId]!.isFavorite;
    } else if (_userFavorites.containsKey(setId)) {
      currentIsFavorite = _userFavorites[setId]!.isFavorite;
    }

    // Reconstruction explicite pour pouvoir effacer la notation (null).
    // On ne passe pas par copyWith(notation: notation) car null serait ignoré
    // si l'utilisateur veut supprimer sa note.
    _userFavorites[setId] = UserFavorite(
      setId: setId,
      isFavorite: currentIsFavorite,
      notation: notation,
    );

    if (_userId != null) {
      _allUserFavorites.putIfAbsent(_userId!, () => {})[setId] = _userFavorites[setId]!;
    }

    await LocalStorageService().saveUserFavorites(_userFavorites);

    if (_userId != null) {
      try {
        await ApiService.rateUserFavorite(_userId!, setId, notation);
      } catch (e) {
        _showErrorMessage('Impossible de synchroniser la notation.');
      }
    }
  }

  // Synchronise les notations en arrière-plan (ne re-toggle PAS les favoris
  // car l'API toggle inverse l'état côté serveur — dangereux si appelé en boucle)
  Future<void> syncFavorites() async {
    if (_userId == null) return;
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
      await LocalStorageService().saveUserFavorites(_userFavorites);
    } catch (e) {
      _showErrorMessage('Impossible de synchroniser les favoris avec le serveur.');
    }
  }

  // Charge les districts
  Future<void> loadDistricts() async {
    if (_districts.isNotEmpty) return;

    _isLoadingDistricts = true;
    try {
      _districts = await ApiService.fetchDistricts();
      await LocalStorageService().saveDistricts(_districts);
    } catch (e) {
      _showErrorMessage('Impossible de charger les districts depuis le serveur.');
      _districts = await LocalStorageService().getDistricts();
      rethrow;
    } finally {
      _isLoadingDistricts = false;
    }
  }

  // Met à jour un district
  Future<void> updateDistrict(String districtName, Map<String, dynamic> coordinates) async {
    try {
      final index = _districts.indexWhere((d) => d.district == districtName);
      if (index != -1) {
        final updatedDistrict = _districts[index].copyWith(
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
        _districts[index] = updatedDistrict;
      }

      await ApiService.updateDistrict(districtName, coordinates);
      await LocalStorageService().saveDistricts(_districts);
    } catch (e) {
      _showErrorMessage('Impossible de mettre à jour le district.');
      rethrow;
    }
  }

  // ========== EVENT MANAGEMENT ==========
  // Charge les événements d'un utilisateur (avec userId explicite pour events_page)
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

  // Ajoute un événement (avec userId explicite)
  Future<void> addEvent(int userId, String eventType) async {
    try {
      await ApiService.createEvent(
        userId: userId,
        eventType: eventType,
      );
      // On construit l'Event localement : la réponse API est un Map brut,
      // pas un Event. Le timestamp serveur n'est pas critique ici.
      _userEvents.insert(0, Event(
        userId: userId,
        timestamp: DateTime.now(),
        eventType: eventType,
      ));

      // Si "perdu", recharge les utilisateurs pour refléter les districts
      // mis à jour côté serveur (le backend s'en charge lui-même dans create_event).
      if (eventType == 'perdu') {
        await loadUsers();
      }
    } catch (e) {
      _showErrorMessage('Impossible d\'ajouter l\'événement : $e');
      rethrow;
    }
  }

  Future<void> deleteLastEvent(int userId) async {
    if (_userEvents.isEmpty) return;
    try {
      await ApiService.deleteLastEvent(userId);
      // Retire optimistement le premier élément (le plus récent)
      _userEvents.removeAt(0);
    } catch (e) {
      _showErrorMessage('Impossible de supprimer l\'événement : $e');
      rethrow;
    }
  }

  // ========== GÉOLOCALISATION ==========
  // Met à jour la géolocalisation + district pour un utilisateur
  Future<void> updateGeoloc({
    required int userId,
    required double lat,
    required double lng,
    String? district,
  }) async {
    try {
      // 1. Met à jour en backend
      await ApiService.updateGeoloc(
        userId: userId,
        lat: lat,
        lng: lng,
        district: district,
      );

      // 2. Met à jour localement
      updateUserLocation(userId, lat, lng, district: district);
    } catch (e) {
      _showErrorMessage('Impossible de mettre à jour la géolocalisation : $e');
      rethrow;
    }
  }
}