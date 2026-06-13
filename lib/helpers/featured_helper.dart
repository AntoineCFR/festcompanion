import '../models/timetable_item.dart';
import '../services/app_data_manager.dart';

/// Logique de la page « Live » : ce qui joue maintenant, ce qui enchaîne,
/// et la détection de la période « festival en cours ».
///
/// ⚠️ Convention temporelle (identique au countdown de l'accueil) : les heures
/// des sets sont en heure locale du festival, comparées à `DateTime.now()` de
/// l'appareil. C'est correct quand on est sur place (fuseau du festival).
class FeaturedHelper {
  /// Tri « Live » : d'abord par heure de début, puis par ordre de scène
  /// (`stage_order`). Deux sets qui démarrent en même temps suivent l'ordre des
  /// scènes voulu par le festival.
  static int _compareByStartThenStage(TimetableItem a, TimetableItem b) {
    final t = a.startTime.compareTo(b.startTime);
    if (t != 0) return t;
    return TimetableItem.compareByStage(a, b);
  }

  /// Sets en cours de diffusion, triés par heure de début puis ordre de scène.
  static List<TimetableItem> nowPlaying() {
    final now = DateTime.now();
    return AppDataManager().timetable
        .where((t) => !now.isBefore(t.startTime) && now.isBefore(t.endTime))
        .toList()
      ..sort(_compareByStartThenStage);
  }

  /// Prochain set de CHAQUE scène (qui « enchaîne »), trié par heure de début
  /// puis ordre de scène. Pas de plafond : toutes les scènes ayant un set à
  /// venir apparaissent (avant, un cap à 8 en masquait certaines, ex. Area S).
  static List<TimetableItem> nextUp() {
    final now = DateTime.now();
    final upcoming = AppDataManager().timetable
        .where((t) => t.startTime.isAfter(now))
        .toList()
      ..sort(_compareByStartThenStage);

    // Un seul prochain set par scène.
    final seenStages = <String>{};
    final perStage = <TimetableItem>[];
    for (final t in upcoming) {
      if (seenStages.add(t.stage)) perStage.add(t);
    }
    return perStage;
  }

  /// Le festival est-il « en cours » ? = de 15 min avant le tout premier set
  /// jusqu'à la fin du dernier set.
  static bool isFestivalLive() {
    final tt = AppDataManager().timetable;
    if (tt.isEmpty) return false;
    final now = DateTime.now();
    final firstStart =
        tt.map((t) => t.startTime).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastEnd =
        tt.map((t) => t.endTime).reduce((a, b) => a.isAfter(b) ? a : b);
    return !now.isBefore(firstStart.subtract(const Duration(minutes: 15))) &&
        now.isBefore(lastEnd);
  }
}
