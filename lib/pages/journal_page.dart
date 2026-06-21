import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/journal_entry.dart';
import '../services/app_data_manager.dart';
import '../utils/utils.dart';
import '../widgets/shared/festival_background.dart';

/// Page « Journal » (accessible depuis le drawer) : la timeline de toutes les
/// notifications programmées du festival (push quotidiennes, vannes horaires,
/// clôture, palmarès). Le serveur est la source de vérité → le journal est
/// identique pour tout le groupe, même si une push a été manquée.
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  @override
  void initState() {
    super.initState();
    // Stale-while-revalidate : affiche le cache puis rafraîchit (bandeau non
    // bloquant via FestivalBackground). force:true → on retente même si déjà
    // chargé une fois dans la session (le journal s'enrichit en cours de journée).
    AppDataManager().loadJournal(force: true);
  }

  Future<void> _refresh() => AppDataManager().loadJournal(force: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Journal'),
        backgroundColor: AppTheme.surface,
      ),
      body: FestivalBackground(
        imageKey: 'featured',
        refreshDomains: const [LoadDomain.journal],
        refreshLabel: 'Mise à jour du journal…',
        child: ValueListenableBuilder<int>(
          valueListenable: AppDataManager().dataRevision,
          builder: (context, _, _) {
            final entries = AppDataManager().journal;
            if (entries.isEmpty) {
              return _EmptyState(onRefresh: _refresh);
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _buildList(entries),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<JournalEntry> entries) {
    // Entrées déjà triées du serveur (récentes d'abord). On insère un en-tête de
    // date à chaque changement de jour (date locale de création).
    final items = <Widget>[
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Text(
          'Toutes les notifs du festival, les plus récentes en premier.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    ];

    String? lastDateLabel;
    for (final e in entries) {
      final dateLabel = AppUtils.formatFullDate(e.createdAt);
      if (dateLabel != lastDateLabel) {
        items.add(_DateHeader(label: dateLabel));
        lastDateLabel = dateLabel;
      }
      items.add(_JournalTile(entry: e));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: items,
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppTheme.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _JournalTile extends StatelessWidget {
  final JournalEntry entry;
  const _JournalTile({required this.entry});

  static IconData _iconFor(String? theme) {
    switch (theme) {
      case 'trending':
        return Icons.trending_up;
      case 'lost':
        return Icons.location_searching;
      case 'bar':
        return Icons.local_bar;
      case 'hydration':
        return Icons.water_drop;
      case 'energy':
        return Icons.bolt;
      case 'hype':
        return Icons.whatshot;
      case 'sos':
        return Icons.sos;
      case 'tent':
        return Icons.cabin;
      case 'location':
        return Icons.location_on;
      case 'jure':
        return Icons.headphones;
      case 'fomo':
        return Icons.star;
      case 'countdown':
        return Icons.hourglass_bottom;
      case 'closing':
        return Icons.celebration;
      case 'palmares':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Heure affichée : l'heure prévue si dispo (créneaux), sinon l'heure de
    // création (clôture/palmarès).
    final timeLabel = entry.scheduledLocal ?? AppUtils.formatTime(entry.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.surface.withValues(alpha: 0.92),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.20),
                child: Icon(_iconFor(entry.theme), color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.body,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13.5, height: 1.35),
                    ),
                    if (!entry.pushed) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            'Journal seulement',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // ListView (même vide) pour que le pull-to-refresh fonctionne.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Icon(Icons.auto_stories_outlined,
              size: 56, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Le journal est vide pour l\'instant',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Les notifications du festival apparaîtront ici au fil des jours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
