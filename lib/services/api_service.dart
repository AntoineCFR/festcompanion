import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/timetable_item.dart';

class ApiService {
  static const String _baseUrl = 'https://extremalineup.onrender.com';

  // 1. Récupère la timetable
  static Future<List<TimetableItem>> fetchTimetable() async {
    try {
      final url = Uri.parse('$_baseUrl/timetable');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TimetableItem.fromJson(json)).toList();
      } else {
        throw Exception(
          'Échec fetchTimetable: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec du chargement de la timetable: $e');
    }
  }

  // 2. Vérifie si l'utilisateur existe et récupère son user_id
  static Future<int?> checkUserExists(String username) async {
    try {
      final url = Uri.parse('$_baseUrl/users/check?username=$username');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ? data['user_id'] as int : null;
      } else {
        throw Exception(
          'Échec checkUserExists: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec de la vérification de l\'utilisateur: $e');
    }
  }

  // 3. Récupère les favoris avec user_id (corrigé pour lever une exception)
  static Future<Set<int>> fetchFavorites(int userId) async {
    try {
      final url = Uri.parse('$_baseUrl/favorites?user_id=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Set<int>.from(
          (data['favorites'] as List).map((fav) => fav['set_id'] as int),
        );
      } else {
        throw Exception(
          'Échec fetchFavorites: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec du chargement des favoris: $e');
    }
  }

  // 4. Sauvegarde les favoris avec user_id
  static Future<void> saveFavorites(int userId, Set<int> favorites) async {
    try {
      final url = Uri.parse('$_baseUrl/favorites');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'favorites': favorites.toList(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Échec saveFavorites: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec de la sauvegarde des favoris: $e');
    }
  }
}