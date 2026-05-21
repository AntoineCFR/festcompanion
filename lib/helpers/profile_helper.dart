import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../services/api_service.dart';
import 'location_helper.dart';

class ProfileHelper {
  // Chargement de l'état de la localisation
  static Future<bool> loadLocationEnabled() async {
    return await LocationHelper.isLocationEnabled();
  }

  // Sauvegarde de l'état de la localisation
  static Future<void> saveLocationEnabled(bool value) async {
    await LocationHelper.setLocationEnabled(value);
  }

  // Initialisation des données utilisateur
  static User initUserData(List<User> users, int userId, String username) {
    return users.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(id: userId, username: username),
    );
  }

  // Rafraîchissement de la localisation + district
  static Future<void> refreshLocation(int userId) async {
    final position = await LocationHelper.getCurrentPosition();

    // Envoie au backend avec des paramètres NOMMÉS
    final response = await ApiService.updateGeoloc(
      userId: userId,
      lat: position.latitude,
      lng: position.longitude,
    );

    // Met à jour le modèle local avec le district
    final district = response['district'] as String?;
    AppDataManager().updateUserLocation(
      userId,
      position.latitude,
      position.longitude,
      district: district,
    );
  }

  // Sauvegarde du numéro de téléphone
  static Future<void> saveProfile(int userId, String phoneNumber) async {
    await ApiService.updateUserPhone(userId, phoneNumber);
    AppDataManager().updateUserPhone(userId, phoneNumber);
  }
}