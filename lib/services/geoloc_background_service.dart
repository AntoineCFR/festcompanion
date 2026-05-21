import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/location_helper.dart';
import '../services/api_service.dart';

class GeolocBackgroundService {
  static const String _geolocTask = 'geoloc_periodic_update';
  static const Duration _updateInterval = Duration(minutes: 15);

  /// Initialise WorkManager et reprend la planification si la localisation
  /// était activée lors de la dernière session.
  /// À appeler une fois par session (ex. depuis SplashLogin).
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    final isEnabled = await LocationHelper.isLocationEnabled();
    if (isEnabled) {
      await _scheduleUpdates();
    }
  }

  /// Sauvegarde l'userId dans SharedPreferences pour que le background isolate
  /// puisse le récupérer (l'AppDataManager du main isolate n'est pas partagé).
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  /// Active/désactive les mises à jour périodiques.
  static Future<void> setUpdatesEnabled(bool enabled, int userId) async {
    if (enabled) {
      await saveUserId(userId);
      await _scheduleUpdates();
    } else {
      await Workmanager().cancelByTag(_geolocTask);
    }
  }

  // ── Privés ─────────────────────────────────────────────────────────────────

  /// Planifie (ou replanifie) la tâche périodique.
  static Future<void> _scheduleUpdates() async {
    await Workmanager().cancelByTag(_geolocTask);
    await Workmanager().registerPeriodicTask(
      _geolocTask,
      _geolocTask,
      frequency: _updateInterval,
      tag: _geolocTask,
      initialDelay: Duration.zero,
    );
  }

  /// Récupère l'userId depuis SharedPreferences (disponible dans le background isolate).
  static Future<int?> _getUserIdFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // ── Callback WorkManager ────────────────────────────────────────────────────
  // Doit être une fonction statique annotée @pragma('vm:entry-point').
  // Tourne dans un isolate SÉPARÉ : aucun état du main isolate n'est accessible.

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    // Obligatoire dans le background isolate avant tout accès aux plugins Flutter.
    WidgetsFlutterBinding.ensureInitialized();

    Workmanager().executeTask((taskName, inputData) async {
      if (taskName != _geolocTask) return true;

      final userId = await _getUserIdFromStorage();
      if (userId == null) return false;

      try {
        final position = await LocationHelper.tryGetCurrentPosition();
        if (position == null) return false;

        await ApiService.updateGeoloc(
          userId: userId,
          lat: position.latitude,
          lng: position.longitude,
        );

        return true;
      } catch (e) {
        debugPrint('GeolocBackgroundService – erreur WorkManager: $e');
        return false;
      }
    });
  }
}
