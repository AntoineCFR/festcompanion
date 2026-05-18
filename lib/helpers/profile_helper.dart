import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../services/api_service.dart';

class ProfileHelper {
  // Chargement de l'état de la localisation
  static Future<bool> loadLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('location_enabled') ?? false;
  }

  // Sauvegarde de l'état de la localisation
  static Future<void> saveLocationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_enabled', value);
  }

  // Initialisation des données utilisateur
  static User initUserData(List<User> users, int userId, String username) {
    return users.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(id: userId, username: username),
    );
  }

  // Rafraîchissement de la localisation (corrigé : plus de return)
  static Future<void> refreshLocation(int userId) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Autorisation de localisation refusée.');
      }
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // Met à jour l'API et AppDataManager
    await ApiService.updateUserLocation(
      userId,
      position.latitude,
      position.longitude,
    );
    AppDataManager().updateUserLocation(
      userId,
      position.latitude,
      position.longitude,
    );
  }

  // Sauvegarde du numéro de téléphone
  static Future<void> saveProfile(int userId, String phoneNumber) async {
    await ApiService.updateUserPhone(userId, phoneNumber);
    AppDataManager().updateUserPhone(userId, phoneNumber);
  }
}