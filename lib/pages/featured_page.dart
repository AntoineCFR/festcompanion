import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/featured_helper.dart';
import '../utils/utils.dart';
import '../widgets/shared/dj_photo.dart';
import '../widgets/shared/festival_background.dart';
import 'djprofilepage.dart';

/// Page « Live » : ce qui se passe MAINTENANT au festival.
class FeaturedPage extends StatefulWidget {
  final String username;
  final int userId;

  const FeaturedPage({super.key, required this.username, required this.userId});

  @override
  State<FeaturedPage> createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rafraîchit « now playing / next up » régulièrement (les sets défilent).
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openDj(TimetableItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DJProfilePage(
          userId: widget.userId,
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

  @override
  Widget build(BuildContext context) {
    final festivalName = AppDataManager().selectedFestival?.name ?? 'Festival';
    final nowPlaying = FeaturedHelper.nowPlaying();
    final nextUp = FeaturedHelper.nextUp();

    return FestivalBackground(
      imageKey: 'featured',
      refreshDomains: const [LoadDomain.timetable],
      refreshLabel: 'Mise à jour du programme…',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                festivalName,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ── Now playing ──────────────────────────────────────────────
              _sectionTitle('Now playing', Icons.graphic_eq),
              const SizedBox(height: 8),
              if (nowPlaying.isEmpty)
                _emptyHint('Aucun set en cours pour le moment.')
              else
                ...nowPlaying.map((item) => _NowPlayingCard(
                      item: item,
                      onTap: () => _openDj(item),
                    )),

              const SizedBox(height: 20),

              // ── Next up ──────────────────────────────────────────────────
              _sectionTitle('Next up', Icons.skip_next),
              const SizedBox(height: 8),
              if (nextUp.isEmpty)
                _emptyHint('Plus de sets programmés.')
              else
                ...nextUp.map((item) => _NextUpRow(
                      item: item,
                      onTap: () => _openDj(item),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      );
}

/// Libellé date/heure d'un set à venir, selon son éloignement :
/// - jour J → juste l'horaire (« 14:00 ») ;
/// - < 1 semaine → jour + horaire (« vendredi · 14:00 ») ;
/// - ≥ 1 semaine → date complète + horaire (« vendredi 11/07 · 14:00 »).
String _whenLabel(DateTime start) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(start.year, start.month, start.day);
  final daysDiff = startDay.difference(today).inDays;
  final time = AppUtils.formatTime(start);

  if (daysDiff <= 0) return time; // jour J
  final weekday = AppUtils.getWeekdayName(start);
  if (daysDiff >= 7) {
    final d = start.day.toString().padLeft(2, '0');
    final m = start.month.toString().padLeft(2, '0');
    return '$weekday $d/$m · $time';
  }
  return '$weekday · $time';
}

/// Formate une durée en français en n'affichant que les unités non nulles :
/// « 12 min », « 1 h et 5 min », « 27 jours, 6 h et 30 min », « < 1 min ».
/// Gère les grandes échéances (sets à plusieurs jours avant le festival) — sans
/// ça, l'affichage retombait en heures cumulées (ex. « 654 h »).
String _formatDuration(Duration d) {
  if (d.inMinutes < 1) return '< 1 min';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final mins = d.inMinutes % 60;

  final parts = <String>[];
  if (days > 0) parts.add('$days jour${days > 1 ? 's' : ''}');
  if (hours > 0) parts.add('$hours h');
  if (mins > 0) parts.add('$mins min');

  if (parts.length == 1) return parts.first;
  // « a, b et c » : virgules sauf « et » devant le dernier élément.
  return '${parts.sublist(0, parts.length - 1).join(', ')} et ${parts.last}';
}

// ── Carte d'un set en cours ───────────────────────────────────────────────────
class _NowPlayingCard extends StatelessWidget {
  final TimetableItem item;
  final VoidCallback onTap;

  const _NowPlayingCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Progression du set (temps écoulé / durée totale), bornée [0, 1].
    final total = item.endTime.difference(item.startTime).inSeconds;
    final elapsed = now.difference(item.startTime).inSeconds;
    final progress = total <= 0 ? 0.0 : (elapsed / total).clamp(0.0, 1.0);
    final remaining = item.endTime.difference(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: DjPhoto(djName: item.dj),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.place, size: 13, color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.stage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.dj,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'jusqu\'à ${AppUtils.formatTime(item.endTime)} · '
                          'encore ${_formatDuration(remaining)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
              const SizedBox(height: 10),
              // Barre de progression du set (couleur du thème).
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ligne « next up » ─────────────────────────────────────────────────────────
class _NextUpRow extends StatelessWidget {
  final TimetableItem item;
  final VoidCallback onTap;

  const _NextUpRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final until = item.startTime.difference(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Photo DJ.
              SizedBox(
                width: 46,
                height: 46,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: DjPhoto(djName: item.dj),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dj,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.stage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Jour · heure de début (texte simple, sans cadre) + « dans X ».
              // Colonne non contrainte → le tout tient sur UNE ligne (c'est le
              // nom du DJ, en Expanded, qui tronque si besoin).
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _whenLabel(item.startTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'dans ${_formatDuration(until)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
