import '../models/timetable_item.dart';
import '../models/user_favorite.dart';

/// Une entrée du classement : le set, son score bayésien (critère de tri) et
/// les chiffres « bruts » (moyenne réelle + nombre de notes) affichés à l'user.
class TrendingEntry {
  final TimetableItem item;
  final double bayesian; // score pondéré (sert au classement)
  final double average; // moyenne brute des notes
  final int count; // nombre de notes

  const TrendingEntry({
    required this.item,
    required this.bayesian,
    required this.average,
    required this.count,
  });
}

/// Classement des sets les mieux notés via une **moyenne bayésienne**.
///
/// score = (C · m + Σ notes) / (C + n)
///   • n = nombre de notes du set
///   • Σ notes = somme des notes du set
///   • m = moyenne globale de toutes les notes (le « prior »)
///   • C = constante de confiance, exprimée en nombre de votes virtuels à m
///
/// Un set avec peu de notes est tiré vers la moyenne globale ; il faut accumuler
/// plusieurs bonnes notes pour passer devant. Ça évite qu'un seul 5★ propulse un
/// DJ en tête.
class TrendingHelper {
  /// Constante de confiance C.
  ///
  /// Contexte : ~15 utilisateurs, dont ~1/3 à 1/2 notent → un set populaire
  /// atteint au mieux ~5–8 notes. C = 3 demande qu'un set rassemble quelques
  /// bonnes notes avant de dominer, sans écraser les sets peu notés.
  /// 👉 Ajustable ici : ↑ C = classement plus prudent (favorise le volume de
  /// notes) ; ↓ C = plus réactif aux moyennes élevées sur peu de votes.
  static const double confidence = 3.0;

  static List<TrendingEntry> computeRanking({
    required List<TimetableItem> timetable,
    required Map<int, Map<int, UserFavorite>> allUserFavorites,
  }) {
    // 1) Regroupe les notes par set + calcule la moyenne globale m.
    final ratingsBySet = <int, List<int>>{};
    int totalSum = 0;
    int totalCount = 0;

    for (final userFavs in allUserFavorites.values) {
      for (final entry in userFavs.entries) {
        final notation = entry.value.notation;
        if (notation != null) {
          ratingsBySet.putIfAbsent(entry.key, () => []).add(notation);
          totalSum += notation;
          totalCount++;
        }
      }
    }

    if (totalCount == 0) return [];
    final double globalMean = totalSum / totalCount;

    // 2) Index set_id → TimetableItem (pour le nom du DJ, la navigation, etc.).
    final byId = {for (final t in timetable) t.setId: t};

    // 3) Construit les entrées.
    final entries = <TrendingEntry>[];
    ratingsBySet.forEach((setId, ratings) {
      final item = byId[setId];
      if (item == null) return; // note orpheline (set absent de la timetable)

      final n = ratings.length;
      final sum = ratings.reduce((a, b) => a + b);
      final average = sum / n;
      final bayesian = (confidence * globalMean + sum) / (confidence + n);

      entries.add(TrendingEntry(
        item: item,
        bayesian: bayesian,
        average: average,
        count: n,
      ));
    });

    // 4) Tri : score bayésien décroissant, puis nb de notes, puis moyenne brute,
    //    puis nom du DJ (départage déterministe — le tri Dart n'est pas stable,
    //    donc sans ce dernier critère deux ex-aequo parfaits auraient un ordre
    //    arbitraire qui pourrait changer d'un build à l'autre).
    entries.sort((a, b) {
      final byScore = b.bayesian.compareTo(a.bayesian);
      if (byScore != 0) return byScore;
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      final byAvg = b.average.compareTo(a.average);
      if (byAvg != 0) return byAvg;
      return a.item.dj.toLowerCase().compareTo(b.item.dj.toLowerCase());
    });

    return entries;
  }
}
