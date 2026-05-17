// lib/services/profile_service.dart
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ProfileService {
  static Future<String?> getPhotoUrl(int userId) async {
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_photos/$userId.jpg');
      final url = await ref.getDownloadURL();
      print('✅ URL générée: $url'); // ✅ Debug
      return url;
    } catch (e) {
      print('❌ Erreur getPhotoUrl: $e'); // ✅ Debug
      return null;
    }
  }
}