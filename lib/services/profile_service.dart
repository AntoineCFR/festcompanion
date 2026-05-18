// Dans profile_service.dart
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ProfileService {
  static Future<String?> getPhotoUrl(int userId) async {
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_photos/$userId.jpg');  // ✅ Chemin vers le fichier
      return await ref.getDownloadURL();  // ✅ Génère une URL avec token
    } catch (e) {
      return null;
    }
  }
}