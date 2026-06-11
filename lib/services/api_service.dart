import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/timetable_item.dart';
import '../models/user_favorite.dart';
import '../models/stage_model.dart';
import '../models/festival_model.dart';

class ApiService {
  static const String _baseUrl = 'https://extremalineup.onrender.com';

  /// Festival actuellement sélectionné. Défini une seule fois à la sélection
  /// du festival (et au démarrage depuis le stockage). Injecté automatiquement
  /// dans tous les appels propres à un festival.
  ///
  /// ⚠️ Les statics ne sont PAS partagés entre isolates : le background isolate
  /// de géoloc (WorkManager) doit passer explicitement [festivalId] (relu depuis
  /// SharedPreferences).
  static int? currentFestivalId;

  static int _requireFestival(int? override) {
    final id = override ?? currentFestivalId;
    if (id == null) {
      throw Exception('Aucun festival sélectionné (festival_id manquant).');
    }
    return id;
  }

  // ========== FESTIVALS ==========

  static Future<List<Festival>> fetchFestivals() async {
    try {
      final url = Uri.parse('$_baseUrl/api/festivals');
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Festival.fromJson(json)).toList();
      } else {
        throw Exception('Échec fetchFestivals: Status ${response.statusCode} - Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Échec du chargement des festivals: $e');
    }
  }

  // ========== TIMETABLE ==========

  static Future<List<TimetableItem>> fetchTimetable({int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/timetable?festival_id=$fid');
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

  // ========== UTILISATEURS ==========

  // Vérifie si l'utilisateur existe (compte global, indépendant du festival)
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

  static Future<List<Map<String, dynamic>>> fetchUsers({int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/users?festival_id=$fid');
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
        body: json.encode({'phone_number': phoneNumber}),
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

  static Future<Map<String, dynamic>> updateUserLocation(int userId, double lat, double lng, {int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/users/$userId/location');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'festival_id': fid, 'lat': lat, 'lng': lng}),
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

  // ========== FAVORIS ==========

  // Récupère les favoris (d'un utilisateur si userId fourni, sinon tous)
  static Future<dynamic> fetchUserFavorites([int? userId, int? festivalId]) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = userId != null
          ? Uri.parse('$_baseUrl/api/user-favorites?festival_id=$fid&user_id=$userId')
          : Uri.parse('$_baseUrl/api/user-favorites?festival_id=$fid');

      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final favoritesList = data['favorites'] as List;

        if (userId != null) {
          return Map<int, UserFavorite>.fromEntries(
            favoritesList.map((fav) {
              final uf = UserFavorite.fromJson(fav);
              return MapEntry(uf.setId, uf);
            }),
          );
        } else {
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

  static Future<bool> toggleUserFavorite(int userId, int setId, {int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/user-favorites/toggle');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'festival_id': fid, 'user_id': userId, 'set_id': setId}),
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

  static Future<void> rateUserFavorite(int userId, int setId, int? notation, {int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/user-favorites/rate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'festival_id': fid,
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

  // ========== SCÈNES (ex-districts) ==========

  static Future<List<Stage>> fetchStages({int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/stages?festival_id=$fid');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Stage.fromJson(json)).toList();
      } else {
        throw Exception(
          'Échec fetchStages: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec du chargement des scènes: $e');
    }
  }

  static Future<Map<String, dynamic>> updateStage(String stageName, Map<String, dynamic> coordinates, {int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/stages/$stageName');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'festival_id': fid, ...coordinates}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Échec updateStage: Status ${response.statusCode} - Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Échec de la mise à jour de la scène: $e');
    }
  }

  // ========== GÉOLOC ==========

  static Future<Map<String, dynamic>> updateGeoloc({
    required int userId,
    required double lat,
    required double lng,
    String? stage,
    int? festivalId,
  }) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/geoloc');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'festival_id': fid,
          'user_id': userId,
          'lat': lat,
          'lng': lng,
          'stage': stage,
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

  // ========== ÉVÉNEMENTS ==========

  static Future<List<dynamic>> fetchUserEvents(int userId, {int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/events?festival_id=$fid&user_id=$userId');
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

  static Future<dynamic> createEvent({
    required int userId,
    required String eventType,
    int? festivalId,
  }) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/events');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'festival_id': fid,
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

  static Future<void> deleteLastEvent(int userId, {int? festivalId}) async {
    try {
      final fid = _requireFestival(festivalId);
      final url = Uri.parse('$_baseUrl/api/events/last?festival_id=$fid&user_id=$userId');
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
}
