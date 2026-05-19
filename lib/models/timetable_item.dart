import 'package:intl/intl.dart';

class TimetableItem {
  final int setId;
  final String dj;
  final String district;
  final String stage;
  final String day;
  final int dayInt;
  final DateTime startTime;
  final DateTime endTime;
  bool isFavorite;
  int? notation;  // ← NOUVEAU
  final String? bio;
  final String? spotifyLink;
  final String? soundcloudLink;
  final String? instagramLink;

  TimetableItem({
    required this.setId,
    required this.dj,
    required this.district,
    required this.stage,
    required this.day,
    required this.dayInt,
    required this.startTime,
    required this.endTime,
    this.isFavorite = false,
    this.notation,  // ← NOUVEAU
    this.bio,
    this.spotifyLink,
    this.soundcloudLink,
    this.instagramLink,
  });

  // Méthode pour convertir en Map (sérialisation)
  Map<String, dynamic> toJson() {
    return {
      'set_id': setId,
      'dj': dj,
      'district': district,
      'stage': stage,
      'day': day,
      'day_int': dayInt,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_favorite': isFavorite,
      'notation': notation,  // ← NOUVEAU
      'bio': bio,
      'spotify_link': spotifyLink,
      'soundcloud_link': soundcloudLink,
      'instagram_link': instagramLink,
    };
  }

  // Méthode pour créer un TimetableItem depuis un Map (désérialisation)
  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    // Gère les deux formats de date (API et local)
    DateTime parseDateTime(dynamic date) {
      if (date is String) {
        try {
          // Format de l'API (ex: "Fri, 21 Jun 2024 14:00:00 GMT")
          final apiFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
          return apiFormat.parse(date);
        } catch (e) {
          // Format ISO (pour le stockage local)
          return DateTime.parse(date);
        }
      }
      return DateTime.now();
    }

    return TimetableItem(
      setId: json['set_id'] ?? json['setId'] ?? 0,
      dj: json['dj'] ?? '',
      district: json['district'] ?? '',
      stage: json['stage'] ?? '',
      day: json['day'] ?? '',
      dayInt: json['day_int'] ?? json['dayInt'] ?? 0,
      startTime: parseDateTime(json['start_time'] ?? json['startTime']),
      endTime: parseDateTime(json['end_time'] ?? json['endTime']),
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      notation: json['notation'] as int?,  // ← NOUVEAU
      bio: json['bio'],
      spotifyLink: json['spotify_link'] ?? json['spotifyLink'],
      soundcloudLink: json['soundcloud_link'] ?? json['soundcloudLink'],
      instagramLink: json['instagram_link'] ?? json['instagramLink'],
    );
  }
}