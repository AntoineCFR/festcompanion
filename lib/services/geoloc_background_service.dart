import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/location_helper.dart';
import '../services/api_service.dart';

// ── Callback WorkManager ──────────────────────────────────────────────────────
// DOIT être une fonction TOP-LEVEL (pas dans une classe).
// WorkManager l'appelle dans un isolate séparé : toute méthode statique de classe
// peut ne pas être trouvée par le runtime en build release.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Obligatoire avant tout accès aux plugins Flutter dans un background isolate.
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != GeolocBackgroundService.taskName) return true;

    // Récupère l'userId depuis SharedPreferences (seul moyen de communiquer
    // avec le background isolate — AppDataManager n'est pas partagé).
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    try {
      // ── Vérification permission ─────────────────────────────────────────────
      // On NE demande PAS la permission ici (impossible sans UI en background).
      // Il faut obligatoirement LocationPermission.always pour accéder au GPS
      // depuis un background isolate sur Android 10+.
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) return false;

      // ── Récupération GPS ────────────────────────────────────────────────────
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // ── Envoi au backend ────────────────────────────────────────────────────
      await ApiService.updateGeoloc(
        userId: userId,
        lat: position.latitude,
        lng: position.longitude,
      );

      return true;
    } catch (e) {
      debugPrint('[GeolocBg] Erreur WorkManager: $e');
      return false;
    }
  });
}

class GeolocBackgroundService {
  // Nom public pour que callbackDispatcher (top-level) puisse y accéder.
  static const String taskName = 'geoloc_periodic_update';

  static const Duration _updateInterval = Duration(minutes: 15);

  /// Initialise WorkManager et reprend la planification si la localisation
  /// était activée lors de la dernière session.
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher, // top-level function
      isInDebugMode: false,
    );
    final isEnabled = await LocationHelper.isLocationEnabled();
    if (isEnabled) {
      await _scheduleUpdates();
    }
  }

  /// Sauvegarde l'userId dans SharedPreferences pour le background isolate.
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
      await Workmanager().cancelByTag(taskName);
    }
  }

  // ── Privés ──────────────────────────────────────────────────────────────────

  static Future<void> _scheduleUpdates() async {
    await Workmanager().cancelByTag(taskName);
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: _updateInterval,
      tag: taskName,
      initialDelay: Duration.zero,
      constraints: Constraints(
        networkType: NetworkType.connected, // n'envoie que si réseau dispo
      ),
    );
  }
}
