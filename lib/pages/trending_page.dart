import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/trending_helper.dart';
import '../utils/utils.dart';
import '../widgets/ratings/rating_score_box.dart';
import '../widgets/shared/dj_photo.dart';
import '../widgets/shared/festival_background.dart';
import 'djprofilepage.dart';

/// Page plein écran « Tendances » (utilisée hors bottom-nav si besoin).
class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tendances'),
        backgroundColor: AppTheme.surface,
      ),
      body: const TrendingView(),
    );
  }
}

/// Contenu « Tendances » (sans Scaffold) → réutilisable comme onglet du bottom-nav.
/// Classement des DJs les mieux notés (moyenne bayésienne — voir [TrendingHelper]).
class TrendingView extends StatefulWidget {
  const TrendingView({super.key});

  @override
  State<TrendingView> createState() => _TrendingViewState();
}

class _TrendingViewState extends State<TrendingView> {
  /// Jour sélectionné dans le filtre (clé anglaise minuscule, ex. 'friday').
  /// `null` = « Tous ». Initialisé à null → comme le PageView recrée la vue à
  /// chaque arrivée sur l'onglet, le filtre repart TOUJOURS sur « Tous ».
  String? _selectedDay;

  Future<void> _openDj(TimetableItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DJProfilePage(
          userId: AppDataManager().userId!,
          setId: item.setId,
          dj: DJ(
            name: item.dj,
            bio: item.bio ?? '',
            stage: item.stage,
            startTime: item.startTime,
            endTime: item.endTime,
            spotifyLink: item.spotifyLink,
            soundcloudLink: item.soundcloudLink,
            instagramLink: item.instagramLink,
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Comment ça marche ?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Le classement utilise une moyenne pondérée (bayésienne) : un set avec '
          'beaucoup de bonnes notes passe devant un set avec très peu de notes, '
          'même excellentes.\n\n'
          'Le grand chiffre est la moyenne réelle des notes /10. En dessous, le '
          'score « pondéré » est celui qui sert réellement au classement (il tient '
          'compte du nombre de notes), suivi du nombre de notes.',
          style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranking = TrendingHelper.computeRanking(
      timetable: AppDataManager().timetable,
      allUserFavorites: AppDataManager().allUserFavorites,
    );

    if (ranking.isEmpty) {
      // Classement vide : soit les notes chargent encore en arrière-plan
      // (afficher un loader), soit il n'y a réellement aucune note (état vide).
      final child = AppDataManager().isLoadingAllFavorites
          ? const Center(child: CircularProgressIndicator())
          : _buildEmptyState();
      return FestivalBackground(imageKey: 'featured', child: child);
    }

    // Filtre par jour : le classement (et son score bayésien) reste calculé sur
    // TOUTES les notes du festival ; on ne fait que masquer les sets des autres
    // jours et renuméroter les rangs sur la liste affichée.
    final days = AppDataManager().festivalDays;
    final visible = _selectedDay == null
        ? ranking
        : ranking
            .where((e) => e.item.day.toLowerCase() == _selectedDay)
            .toList();

    return FestivalBackground(
      imageKey: 'featured',
      refreshDomains: const [LoadDomain.trending],
      refreshLabel: 'Mise à jour des tendances…',
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        // +1 pour l'en-tête ; si le jour filtré n'a aucun set noté, on réserve
        // une ligne pour le message « aucune note ce jour-là ».
        itemCount: visible.isEmpty ? 2 : visible.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(days);
          }
          if (visible.isEmpty) {
            return _buildEmptyDayState();
          }
          final entry = visible[index - 1];
          return _TrendingTile(
            rank: index,
            entry: entry,
            onTap: () => _openDj(entry.item),
          );
        },
      ),
    );
  }

  /// En-tête : ligne d'intro + bouton info, puis le filtre par jour (s'il y a
  /// plus d'un jour au programme).
  Widget _buildHeader(List<String> days) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Les DJs les mieux notés par le groupe',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white70),
                tooltip: 'Comment est calculé ce classement ?',
                onPressed: _showInfo,
              ),
            ],
          ),
          if (days.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: _TrendingDayFilter(
                days: days,
                selectedDay: _selectedDay,
                onChanged: (d) => setState(() => _selectedDay = d),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 48, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          const Text(
            'Aucune note ce jour-là',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Les sets de ce jour n\'ont pas encore été notés.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined,
                size: 56, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            const Text(
              'Pas encore de classement',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dès que des sets seront notés, les meilleurs apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filtre par jour (« Tous » + chaque jour du festival) ─────────────────────
// Sélecteur segmenté ; `null` = « Tous ». Scrollable horizontalement au cas où
// un festival aurait beaucoup de jours.
class _TrendingDayFilter extends StatelessWidget {
  final List<String> days; // clés anglaises ('friday'…), triées par day_int
  final String? selectedDay; // null = Tous
  final void Function(String?) onChanged;

  const _TrendingDayFilter({
    required this.days,
    required this.selectedDay,
    required this.onChanged,
  });

  /// Libellé court d'une clé jour ('friday' → 'Ven.').
  static String _shortName(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Lun.';
      case 'tuesday':
        return 'Mar.';
      case 'wednesday':
        return 'Mer.';
      case 'thursday':
        return 'Jeu.';
      case 'friday':
        return 'Ven.';
      case 'saturday':
        return 'Sam.';
      case 'sunday':
        return 'Dim.';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Options : « Tous » (clé null, représentée par '') puis chaque jour.
    final options = <String?>[null, ...days];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ToggleButtons(
        isSelected: options.map((d) => d == selectedDay).toList(),
        onPressed: (i) => onChanged(options[i]),
        constraints: const BoxConstraints(minHeight: 32, minWidth: 50),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white54,
        selectedColor: Colors.white,
        fillColor: AppTheme.accent,
        borderColor: Colors.white24,
        selectedBorderColor: AppTheme.accent,
        children: options
            .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    d == null ? 'Tous' : _shortName(d),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Tuile d'un DJ classé ─────────────────────────────────────────────────────
// Rang à GAUCHE, hors de la carte. Carte épurée (ni étoile ni surbrillance
// favori, qui chargeaient trop la tuile) : la photo **remplit toute la hauteur**
// de la tuile (recadrage `cover`, comme la timetable), nom + ligne
// « scène · jour · début - fin », et à droite la note moyenne + nombre de notes.
class _TrendingTile extends StatelessWidget {
  static const double _tileHeight = 62;

  final int rank;
  final TrendingEntry entry;
  final VoidCallback onTap;

  const _TrendingTile({
    required this.rank,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: _tileHeight,
                  // stretch → la photo et la colonne note prennent toute la hauteur.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo : largeur fixe, PLEINE HAUTEUR de la tuile.
                      SizedBox(
                        width: 58,
                        child: DjPhoto(djName: item.dj),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.dj,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.stage} · ${AppUtils.getWeekdayName(item.startTime)} · '
                              '${AppUtils.formatTime(item.startTime)} - ${AppUtils.formatTime(item.endTime)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Note moyenne + nombre de notes
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Chiffre principal = moyenne réelle (intuitif).
                            RatingScoreBox(score: entry.average),
                            const SizedBox(height: 3),
                            // Score PONDÉRÉ (bayésien) : celui qui sert au
                            // classement → affiché en petit sous la moyenne.
                            Text(
                              'pondéré ${entry.bayesian.toStringAsFixed(1)}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10),
                            ),
                            Text(
                              '${entry.count} note${entry.count > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pastille de rang (médaille pour le top 3), hors de la carte ──────────────
class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD24A);
    const silver = Color(0xFFCFD8DC);
    const bronze = Color(0xFFD08B5B);
    final medal = switch (rank) {
      1 => gold,
      2 => silver,
      3 => bronze,
      _ => null,
    };

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medal ?? AppTheme.surfaceAlt,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          color: medal != null ? Colors.black87 : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
