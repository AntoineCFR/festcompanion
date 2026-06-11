import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper centralisé pour TOUTES les opérations de localisation
/// Utilise ce helper pour :
/// - Récupérer la position GPS
/// - Gérer les permissions
/// - Ouvrir Google Maps
/// - Formater/valider les coordonnées
class LocationHelper {
  // ========== CONSTANTES ==========
  static const String _locationEnabledKey = 'location_enabled';

  // Coordonnées du festival (Parking Camping)
  static const double festivalLatitude = 51.026997;
  static const double festivalLongitude = 5.443735;

  // ========== PERMISSIONS ==========

  /// Vérifie si le service de localisation est activé sur l'appareil
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Vérifie les permissions de localisation actuelles
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Demande les permissions de localisation
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Vérifie et demande les permissions si nécessaire
  /// Retourne true si OK, lance une exception sinon
  static Future<bool> ensurePermissions({bool requestIfDenied = true}) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Service de localisation désactivé');
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      if (requestIfDenied) {
        permission = await requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw const LocationException('Permissions refusées');
      }
    } else if (permission == LocationPermission.deniedForever) {
      throw const LocationException('Permissions définitivement refusées');
    }

    return true;
  }

  // ========== POSITION ==========

  /// Récupère la position actuelle (lance une exception si échec)
  static Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    await ensurePermissions();
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );
  }

  /// Récupère la position actuelle (retourne null si échec)
  static Future<Position?> tryGetCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      return await getCurrentPosition(accuracy: accuracy);
    } catch (_) {
      return null;
    }
  }

  // ========== ÉTAT DE LA LOCALISATION ==========

  /// Charge si la localisation est activée pour l'utilisateur
  static Future<bool> isLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationEnabledKey) ?? false;
  }

  /// Sauvegarde l'état d'activation de la localisation
  static Future<void> setLocationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, value);
  }

  // ========== GOOGLE MAPS ==========

  /// Ouvre Google Maps avec des coordonnées
  static Future<bool> openInGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final url = label != null
        ? 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$label'
        : 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: mode);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur Google Maps: $e');
      return false;
    }
  }

  /// Ouvre Google Maps sur une requête libre : adresse ("Leisenweg, Hilvarenbeek")
  /// ou coordonnées ("51.02,5.44"). Utilisé pour le parking propre à chaque festival.
  static Future<bool> openMapsQuery(
    String query, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: mode);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur Google Maps (query): $e');
      return false;
    }
  }

  /// Ouvre le parking du festival dans Google Maps (fallback Extrema codé en dur)
  static Future<bool> openFestivalLocation() async {
    return await openInGoogleMaps(
      latitude: festivalLatitude,
      longitude: festivalLongitude,
      label: 'Parking Camping Extrema',
    );
  }

  // ========== UTILITAIRES ==========

  /// Formate des coordonnées pour affichage
  static String formatCoordinates(double? lat, double? lng, {int decimals = 6}) {
    if (lat == null || lng == null) return 'Non disponible';
    return 'Lat: ${lat.toStringAsFixed(decimals)}, Lon: ${lng.toStringAsFixed(decimals)}';
  }

  /// Vérifie si des coordonnées sont valides
  static bool areValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Calcule la distance entre deux points (en mètres)
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

/// Exception personnalisée pour les erreurs de localisation
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}