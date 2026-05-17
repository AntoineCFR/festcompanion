// lib/services/app_data_manager.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/timetable_item.dart';
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
  }

  // Données globales (indépendantes de l'utilisateur)
  List<TimetableItem> _timetable = [];
  List<Map<String, dynamic>> _users = [];
  Map<int, String?> _photoUrls = {};

  // Données utilisateur (dépendent de l'utilisateur connecté)
  Set<int> _favoriteSetIds = {};
  int? _userId;
  String _selectedDay = 'friday';
  bool _showFavoritesOnly = false;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  // Setter pour le GlobalKey
  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
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
  List<Map<String, dynamic>> get users => _users;
  String? getPhotoUrl(int userId) => _photoUrls[userId];

  // Getters pour les données utilisateur
  Set<int> get favoriteSetIds => _favoriteSetIds;
  String get selectedDay => _selectedDay;
  bool get showFavoritesOnly => _showFavoritesOnly;
  int? get userId => _userId;

  // ✅ Charge les données GLOBALES (timetable + utilisateurs + photos)
  Future<void> loadAllData() async {  // ✅ Plus de paramètre userId
    try {
      await loadTimetable();
      await loadUsers();  // ✅ Charge les utilisateurs et leurs photos
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

  // ✅ Charge les utilisateurs et leurs photos (globales)
  Future<void> loadUsers() async {
    try {
      _users = await ApiService.fetchUsers();
      _photoUrls.clear();

      for (final user in _users) {
        final int userId = user['id'] as int;
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

  // ✅ Charge les favoris (spécifiques à l'utilisateur)
  Future<void> loadFavorites(int userId) async {  // ✅ Prend userId en paramètre
    try {
      _userId = userId;
      final serverFavorites = await ApiService.fetchFavorites(userId);
      _favoriteSetIds = serverFavorites;
      await LocalStorageService().saveFavorites(_favoriteSetIds);
    } catch (e) {
      _showErrorMessage('Impossible de charger les favoris depuis le serveur.');
      _favoriteSetIds = await LocalStorageService().getFavorites();
      rethrow;
    }
  }

  // Méthode d'initialisation (pour compatibilité)
  Future<void> init(int userId) async {
    await loadTimetable();
    await loadFavorites(userId);  // ✅ Charge les favoris de l'utilisateur
    _selectedDay = await LocalStorageService().getSelectedDay();
    _showFavoritesOnly = await LocalStorageService().getShowFavoritesOnly();
  }

  // ✅ Met à jour la photo d'un utilisateur
  void updateUserPhoto(int userId, String? photoUrl) {
    _photoUrls[userId] = photoUrl;
    final userIndex = _users.indexWhere((u) => u['id'] == userId);
    if (userIndex != -1) {
      _users[userIndex]['photo_url'] = photoUrl;
    }
  }

  // ✅ Met à jour la localisation d'un utilisateur
  void updateUserLocation(int userId, double lat, double lng) {
    final userIndex = _users.indexWhere((u) => u['id'] == userId);
    if (userIndex != -1) {
      _users[userIndex]['last_lat'] = lat;
      _users[userIndex]['last_lng'] = lng;
    }
  }

  // ✅ Met à jour le téléphone d'un utilisateur
  void updateUserPhone(int userId, String phoneNumber) {
    final userIndex = _users.indexWhere((u) => u['id'] == userId);
    if (userIndex != -1) {
      _users[userIndex]['phone_number'] = phoneNumber;
    }
  }

  // Réinitialisation des données
  void reset() {
    _timetable = [];
    _favoriteSetIds = {};
    _userId = null;
    _selectedDay = 'friday';
    _showFavoritesOnly = false;
    _users = [];
    _photoUrls = {};
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    LocalStorageService().saveSelectedDay(day);
  }

  void setShowFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
    LocalStorageService().saveShowFavoritesOnly(value);
  }

  Future<void> toggleFavorite(int setId) async {
    if (_favoriteSetIds.contains(setId)) {
      _favoriteSetIds.remove(setId);
    } else {
      _favoriteSetIds.add(setId);
    }

    await LocalStorageService().saveFavorites(_favoriteSetIds);

    if (_userId != null) {
      try {
        await ApiService.saveFavorites(_userId!, _favoriteSetIds);
      } catch (e) {
        _showErrorMessage('Impossible de synchroniser avec le serveur. Les données sont sauvegardées localement.');
      }
    }
  }

  Future<void> syncFavorites() async {
    if (_userId == null) return;
    try {
      await ApiService.saveFavorites(_userId!, _favoriteSetIds);
      await LocalStorageService().saveFavorites(_favoriteSetIds);
    } catch (e) {
      _showErrorMessage('Impossible de synchroniser les favoris avec le serveur.');
    }
  }
}