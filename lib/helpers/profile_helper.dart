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

  // Rafraîchissement de la localisation + scène
  static Future<void> refreshLocation(int userId) async {
    final position = await LocationHelper.getCurrentPosition();

    // Envoie au backend avec des paramètres NOMMÉS
    final response = await ApiService.updateGeoloc(
      userId: userId,
      lat: position.latitude,
      lng: position.longitude,
    );

    // Met à jour le modèle local avec la scène
    final stage = response['stage'] as String?;
    AppDataManager().updateUserLocation(
      userId,
      position.latitude,
      position.longitude,
      stage: stage,
    );
  }

  /// Rafraîchit la position SI l'utilisateur a activé le partage, sans jamais
  /// lever d'exception (échec silencieux). Utilisé à l'ouverture de l'app et
  /// sur réception d'une demande "perdu". Respecte le consentement de partage.
  static Future<void> refreshLocationIfEnabled(int userId) async {
    try {
      if (!await LocationHelper.isLocationEnabled()) return;
      final position = await LocationHelper.tryGetCurrentPosition();
      if (position == null) return;
      final response = await ApiService.updateGeoloc(
        userId: userId,
        lat: position.latitude,
        lng: position.longitude,
      );
      final stage = response['stage'] as String?;
      AppDataManager().updateUserLocation(
        userId,
        position.latitude,
        position.longitude,
        stage: stage,
      );
    } catch (_) {
      // Best-effort : on n'interrompt rien si la position n'est pas dispo.
    }
  }

  // Sauvegarde du numéro de téléphone
  static Future<void> saveProfile(int userId, String phoneNumber) async {
    await ApiService.updateUserPhone(userId, phoneNumber);
    AppDataManager().updateUserPhone(userId, phoneNumber);
  }
}