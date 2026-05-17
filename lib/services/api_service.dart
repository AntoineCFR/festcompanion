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

  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final url = Uri.parse('$_baseUrl/users');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((user) => {
          'id': user['id'],
          'username': user['username'] ?? '',
          'phone_number': user['phone_number']?.toString() ?? '',
          'last_lat': user['last_lat'] ?? 0.0,
          'last_lng': user['last_lng'] ?? 0.0,
        }).toList();
      } else {
        throw Exception(
          'Échec fetchUsers: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec du chargement des utilisateurs: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUserPhone(int userId, String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/phone');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Retourne la réponse du backend
      } else {
        throw Exception('Erreur: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
  static Future<Map<String, dynamic>> updateUserLocation(int userId, double lat, double lng) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/location');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}