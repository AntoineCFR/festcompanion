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

  /// Liste les `userId` qui ont réellement une photo dans `user_photos/`.
  ///
  /// Un seul `listAll()` remplace un `getDownloadURL()` par utilisateur : on
  /// évite ainsi les 404 (et leur log natif `E/StorageException`) pour tous les
  /// users sans photo, et on réduit le nombre de requêtes au démarrage.
  ///
  /// Retourne `null` si le listing échoue (ex. : règles Storage n'autorisant pas
  /// `list`) → l'appelant retombe alors proprement sur l'ancien comportement.
  static Future<Set<int>?> listUserIdsWithPhoto() async {
    try {
      final result = await firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .listAll()
          .timeout(const Duration(seconds: 12));
      final ids = <int>{};
      for (final item in result.items) {
        final name = item.name; // ex : "12.jpg"
        final dot = name.lastIndexOf('.');
        final base = dot == -1 ? name : name.substring(0, dot);
        final id = int.tryParse(base);
        if (id != null) ids.add(id);
      }
      return ids;
    } catch (e) {
      return null;
    }
  }
}
