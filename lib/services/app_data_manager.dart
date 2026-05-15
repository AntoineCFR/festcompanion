// lib/services/app_data_manager.dart
import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AppDataManager {
  // Singleton
  static final AppDataManager _instance = AppDataManager._internal();
  factory AppDataManager() => _instance;
  AppDataManager._internal() {
    _timetable = [];
  }

  // Données globales
  List<TimetableItem> _timetable = [];
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

  // Getters
  List<TimetableItem> get timetable => _timetable;
  Set<int> get favoriteSetIds => _favoriteSetIds;
  String get selectedDay => _selectedDay;
  bool get showFavoritesOnly => _showFavoritesOnly;
  int? get userId => _userId;

  // Méthodes de chargement séparées
  Future<void> loadTimetable() async {
    try {
      _timetable = await ApiService.fetchTimetable();
      await LocalStorageService().saveTimetable(_timetable);
    } catch (e) {
      _showErrorMessage('Impossible de charger la timetable depuis le serveur.');
      _timetable = await LocalStorageService().getTimetable();
      rethrow; // ✅ Relance l'erreur pour que SplashScreen l'attrape
    }
  }

  Future<void> loadFavorites(int userId) async {
    try {
      _userId = userId;
      final serverFavorites = await ApiService.fetchFavorites(userId);
      _favoriteSetIds = serverFavorites;
      await LocalStorageService().saveFavorites(_favoriteSetIds);
    } catch (e) {
      _showErrorMessage('Impossible de charger les favoris depuis le serveur.');
      _favoriteSetIds = await LocalStorageService().getFavorites();
      rethrow; // ✅ Relance l'erreur pour que SplashLogin l'attrape
    }
  }

  // Initialisation (pour compatibilité)
  Future<void> init(int userId) async {
    await loadTimetable();
    await loadFavorites(userId);
    _selectedDay = await LocalStorageService().getSelectedDay();
    _showFavoritesOnly = await LocalStorageService().getShowFavoritesOnly();
  }

  // Réinitialisation des données
  void reset() {
    _timetable = [];
    _favoriteSetIds = {};
    _userId = null;
    _selectedDay = 'friday';
    _showFavoritesOnly = false;
  }

  // Méthodes pour modifier les données
  void setSelectedDay(String day) {
    _selectedDay = day;
    LocalStorageService().saveSelectedDay(day);
  }

  void setShowFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
    LocalStorageService().saveShowFavoritesOnly(value);
  }

  // Synchronisation immédiate des favoris
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

  // Synchronisation de secours
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