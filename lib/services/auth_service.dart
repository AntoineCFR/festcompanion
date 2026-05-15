import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'userId';

  // Sauvegarde le login
  static Future<void> saveLogin(String username, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setInt(_userIdKey, userId);
  }

  // Récupère le login sauvegardé
  static Future<Map<String, dynamic>?> getSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final userId = prefs.getInt(_userIdKey);
    if (username != null && userId != null) {
      return {'username': username, 'userId': userId};
    }
    return null;
  }

  // Supprime le login (pour la déconnexion)
  static Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
  }
}