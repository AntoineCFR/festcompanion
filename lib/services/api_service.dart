import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/timetable_item.dart';
import '../models/user_favorite.dart';
import '../models/district_model.dart';

class ApiService {
  static const String _baseUrl = 'https://extremalineup.onrender.com';

  // 1. Récupère la timetable
  static Future<List<TimetableItem>> fetchTimetable() async {
    try {
      final url = Uri.parse('$_baseUrl/timetable');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

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
      final response = await http.get(url).timeout(const Duration(seconds: 30));

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

  // ========== NOUVELLES MÉTHODES POUR LES FAVORIS ==========

  // Récupère les favoris d'un utilisateur (ou tous si userId=null)
  static Future<dynamic> fetchUserFavorites([int? userId]) async {
    try {
      final url = userId != null
          ? Uri.parse('$_baseUrl/api/user-favorites?user_id=$userId')
          : Uri.parse('$_baseUrl/api/user-favorites');

      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final favoritesList = data['favorites'] as List;

        if (userId != null) {
          // Retourne Map<set_id, UserFavorite> pour UN utilisateur
          return Map<int, UserFavorite>.fromEntries(
            favoritesList.map((fav) {
              final uf = UserFavorite.fromJson(fav);
              return MapEntry(uf.setId, uf);
            }),
          );
        } else {
          // Retourne Map<user_id, Map<set_id, UserFavorite>> pour TOUS les utilisateurs
          final allFavorites = <int, Map<int, UserFavorite>>{};
          for (final fav in favoritesList) {
            final userId = fav['user_id'] as int;
            final setId = fav['set_id'] as int;
            final uf = UserFavorite.fromJson(fav);

            allFavorites.putIfAbsent(userId, () => {});
            allFavorites[userId]![setId] = uf;
          }
          return allFavorites;
        }
      } else {
        throw Exception('Échec fetchUserFavorites: Status ${response.statusCode} - Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Échec du chargement des favoris: $e');
    }
  }

  // Toggle favori pour un set_id
  static Future<bool> toggleUserFavorite(int userId, int setId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/user-favorites/toggle');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'set_id': setId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isfavorite'] as bool;
      } else {
        throw Exception('Échec toggleUserFavorite: Status ${response.statusCode} - Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Échec du toggle favori: $e');
    }
  }

  // Met à jour la notation
  static Future<void> rateUserFavorite(int userId, int setId, int? notation) async {
    try {
      final url = Uri.parse('$_baseUrl/api/user-favorites/rate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'set_id': setId,
          'notation': notation,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec rateUserFavorite: Status ${response.statusCode} - Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Échec de la mise à jour de la notation: $e');
    }
  }

  // ========== ANCIENNES MÉTHODES (À GARDER) ==========

  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final url = Uri.parse('$_baseUrl/users');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((user) => {
          'id': user['id'],
          'username': user['username'] ?? '',
          'phone_number': user['phone_number']?.toString() ?? '',
          'last_lat': user['last_lat'] ?? 0.0,
          'last_lng': user['last_lng'] ?? 0.0,
          'last_location': user['last_location'] ?? '?',
          'user_role': user['user_role'] ?? 'user',
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
        return json.decode(response.body);
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

  // Récupère tous les districts
  static Future<List<District>> fetchDistricts() async {
    try {
      final url = Uri.parse('$_baseUrl/api/districts');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => District.fromJson(json)).toList();
      } else {
        throw Exception(
          'Échec fetchDistricts: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec du chargement des districts: $e');
    }
  }

  // Met à jour un district
  static Future<Map<String, dynamic>> updateDistrict(String districtName, Map<String, dynamic> coordinates) async {
    try {
      final url = Uri.parse('$_baseUrl/api/districts/$districtName');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(coordinates),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Échec updateDistrict: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec de la mise à jour du district: $e');
    }
  }

  // ========== NOUVELLES MÉTHODES POUR LA GÉOLOC ==========

  // Met à jour la géolocalisation (avec district)
  static Future<Map<String, dynamic>> updateGeoloc({
    required int userId,
    required double lat,
    required double lng,
    String? district,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/geoloc');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'lat': lat,
          'lng': lng,
          'district': district,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Échec updateGeoloc: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec de la mise à jour de la géolocalisation: $e');
    }
  }

  // ========== NOUVELLES MÉTHODES POUR LES ÉVÉNEMENTS ==========

  // Récupère les événements d'un utilisateur
  static Future<List<dynamic>> fetchUserEvents(int userId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/events?user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return List<dynamic>.from(json.decode(response.body));
      } else {
        throw Exception(
          'Échec fetchUserEvents: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec du chargement des événements: $e');
    }
  }

  // Crée un nouvel événement
  static Future<dynamic> createEvent({
    required int userId,
    required String eventType,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/events');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'event_type': eventType,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Échec createEvent: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec de la création de l\'événement: $e');
    }
  }

  // Supprime le dernier événement d'un utilisateur
  static Future<void> deleteLastEvent(int userId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/events/last?user_id=$userId');
      final response = await http.delete(url).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Échec deleteLastEvent: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec de la suppression de l\'événement: $e');
    }
  }

  // Note : la mise à jour des districts de tous les utilisateurs (event "perdu")
  // est gérée directement côté backend dans POST /api/events — aucun appel séparé nécessaire.
}