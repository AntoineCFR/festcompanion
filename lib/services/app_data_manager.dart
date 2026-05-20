import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/timetable_item.dart';
import '../models/user_model.dart';
import '../models/user_favorite.dart';
import '../models/district_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/profile_service.dart';

// ✅ Clé globale pour precacheImage
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  bool _showFavoritesOnly = false;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  // Données districts
  List<District> _districts = [];
  bool _isLoadingDistricts = false;

  // Setter pour le GlobalKey
  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
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

  // Getters pour les données utilisateur
  Set<int> get favoriteSetIds => _userFavorites.entries
      .where((entry) => entry.value.isFavorite)
      .map((entry) => entry.key)
      .toSet();

  String get selectedDay => _selectedDay;
  bool get showFavoritesOnly => _showFavoritesOnly;
  int? get userId => _userId;

  // Getters pour les districts
  List<District> get districts => _districts;
  bool get isLoadingDistricts => _isLoadingDistricts;

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
        _userFavorites = _allUserFavorites[userId]!;
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

  // Met à jour la localisation d'un utilisateur
  void updateUserLocation(int userId, double lat, double lng) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(lastLat: lat, lastLng: lng);
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
    _showFavoritesOnly = false;
    _users = [];
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    LocalStorageService().saveSelectedDay(day);
  }

  void setShowFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
    LocalStorageService().saveShowFavoritesOnly(value);
  }

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
    // ✅ 1. Récupère l'état favori ACTUEL (pour éviter de l'écraser)
    bool currentIsFavorite = false;
    if (_allUserFavorites.containsKey(_userId) && _allUserFavorites[_userId]!.containsKey(setId)) {
      currentIsFavorite = _allUserFavorites[_userId]![setId]!.isFavorite;
    } else if (_userFavorites.containsKey(setId)) {
      currentIsFavorite = _userFavorites[setId]!.isFavorite;
    }

    // ✅ 2. Met à jour _userFavorites avec le bon état favori
    if (!_userFavorites.containsKey(setId)) {
      _userFavorites[setId] = UserFavorite(
        setId: setId,
        isFavorite: currentIsFavorite, // ✅ Conserve l'état favori existant
        notation: notation,
      );
    } else {
      _userFavorites[setId] = _userFavorites[setId]!.copyWith(notation: notation);
    }

    // ✅ 3. Met à jour _allUserFavorites IMMEDIATEMENT
    if (_userId != null) {
      _allUserFavorites.putIfAbsent(_userId!, () => {})[setId] = _userFavorites[setId]!;
    }

    // 4. Sauvegarde en local
    await LocalStorageService().saveUserFavorites(_userFavorites);

    // 5. Appel API en background
    if (_userId != null) {
      try {
        await ApiService.rateUserFavorite(_userId!, setId, notation ?? -1);
      } catch (e) {
        _showErrorMessage('Impossible de synchroniser la notation.');
      }
    }
  }

  // Synchronise tous les favoris
  Future<void> syncFavorites() async {
    if (_userId == null) return;
    try {
      for (final entry in _userFavorites.entries) {
        final setId = entry.key;
        final fav = entry.value;
        if (fav.isFavorite) {
          await ApiService.toggleUserFavorite(_userId!, setId);
        }
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
}