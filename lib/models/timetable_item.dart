import 'package:intl/intl.dart';

class TimetableItem {
  final int setId;
  final String dj;
  final String stage;   // lieu géolocalisé (ex-"district")
  final String host;    // collectif qui anime la scène (ex-"stage")
  final String day;
  final int dayInt;
  final int? stageOrder;  // ordre d'affichage de la scène (null = fallback alpha)
  final DateTime startTime;
  final DateTime endTime;
  bool isFavorite;
  int? notation;
  final String? bio;
  final String? spotifyLink;
  final String? soundcloudLink;
  final String? instagramLink;

  TimetableItem({
    required this.setId,
    required this.dj,
    required this.stage,
    required this.host,
    required this.day,
    required this.dayInt,
    this.stageOrder,
    required this.startTime,
    required this.endTime,
    this.isFavorite = false,
    this.notation,
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
      'stage': stage,
      'host': host,
      'day': day,
      'day_int': dayInt,
      'stage_order': stageOrder,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_favorite': isFavorite,
      'notation': notation,
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
      stage: json['stage'] ?? '',
      host: json['host'] ?? '',
      day: json['day'] ?? '',
      dayInt: json['day_int'] ?? json['dayInt'] ?? 0,
      stageOrder: json['stage_order'] ?? json['stageOrder'],
      startTime: parseDateTime(json['start_time'] ?? json['startTime']),
      endTime: parseDateTime(json['end_time'] ?? json['endTime']),
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      notation: json['notation'] as int?,
      bio: json['bio'],
      spotifyLink: json['spotify_link'] ?? json['spotifyLink'],
      soundcloudLink: json['soundcloud_link'] ?? json['soundcloudLink'],
      instagramLink: json['instagram_link'] ?? json['instagramLink'],
    );
  }

  /// Ordre d'affichage des scènes :
  /// - par `stageOrder` (ordre voulu du festival, fourni par le scraper) si dispo ;
  /// - sinon repli alphabétique INSENSIBLE à la casse (ex. anciennes données
  ///   sans stage_order), ce qui évite que les noms en MAJUSCULES remontent en tête.
  static int compareByStage(TimetableItem a, TimetableItem b) {
    final ao = a.stageOrder;
    final bo = b.stageOrder;
    if (ao != null && bo != null) {
      if (ao != bo) return ao.compareTo(bo);
    } else if (ao != null) {
      return -1;
    } else if (bo != null) {
      return 1;
    }
    return a.stage.toLowerCase().compareTo(b.stage.toLowerCase());
  }

  /// Libellé affiché pour une scène : "{stage}" si aucun collectif ne
  /// l'anime, "{stage} - {host}" sinon (ex. une même scène tenue par un
  /// collectif différent selon le jour du festival).
  static String stageLabel(String stage, String host) =>
      host.trim().isEmpty ? stage : '$stage - ${host.trim()}';
}
