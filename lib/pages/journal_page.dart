import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/journal_entry.dart';
import '../services/app_data_manager.dart';
import '../utils/utils.dart';
import '../widgets/shared/festival_background.dart';

/// Thème des changements de line-up (ajout / horaire / annulation / rétabli).
const String kProgrammationTheme = 'programmation';

/// Libellés lisibles par thème (pour les puces de filtre). Fallback : le thème
/// brut capitalisé.
const Map<String, String> _kThemeLabels = {
  'programmation': 'Programmation',
  'trending': 'Tendances',
  'palmares': 'Palmarès',
  'closing': 'Clôture',
  'countdown': 'Décompte',
  'hype': 'Hype',
  'sos': 'SOS',
  'lost': 'Perdu',
  'bar': 'Bar',
  'hydration': 'Hydratation',
  'energy': 'Énergie',
  'tent': 'Tente',
  'location': 'Localisation',
  'jure': 'Jury',
  'fomo': 'FOMO',
};

String _themeLabel(String theme) {
  final known = _kThemeLabels[theme];
  if (known != null) return known;
  return theme.isEmpty ? 'Autre' : theme[0].toUpperCase() + theme.substring(1);
}

/// Page « Journal » (accessible depuis le drawer) : la timeline de TOUTES les
/// notifications du festival (push quotidiennes, vannes, décompte, clôture,
/// changements de programmation…), avec un filtre par thème. Le serveur est la
/// source de vérité → le journal est identique pour tout le groupe.
class JournalPage extends StatefulWidget {
  /// Thème pré-sélectionné à l'ouverture (ex. un push de programmation ouvre le
  /// journal filtré sur « Programmation »). null = « Tout ».
  final String? initialTheme;
  const JournalPage({super.key, this.initialTheme});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  // null = aucun filtre (toutes les notifs).
  String? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.initialTheme;
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
            final all = AppDataManager().journal;

            // Thèmes proposés au filtre = ceux présents dans les données (+ le
            // thème pré-sélectionné, même absent, pour rester cohérent).
            final themes = <String>{
              for (final e in all)
                if (e.theme != null && e.theme!.isNotEmpty) e.theme!,
              ?_selectedTheme,
            }.toList()
              ..sort((a, b) => _themeLabel(a).compareTo(_themeLabel(b)));

            final entries = _selectedTheme == null
                ? all
                : all.where((e) => e.theme == _selectedTheme).toList();

            return Column(
              children: [
                if (themes.isNotEmpty)
                  _ThemeFilterBar(
                    themes: themes,
                    selected: _selectedTheme,
                    onSelected: (t) => setState(() => _selectedTheme = t),
                  ),
                Expanded(
                  child: entries.isEmpty
                      ? _EmptyState(
                          onRefresh: _refresh,
                          filtered: _selectedTheme != null,
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: _buildList(entries),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<JournalEntry> entries) {
    // Entrées déjà triées du serveur (récentes d'abord). On insère un en-tête de
    // date à chaque changement de jour (date locale de création).
    final items = <Widget>[];
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
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: items,
    );
  }
}

/// Rangée horizontale de puces de filtre : « Tout » + un thème par puce.
class _ThemeFilterBar extends StatelessWidget {
  final List<String> themes;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _ThemeFilterBar({
    required this.themes,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _chip(label: 'Tout', value: null),
          for (final t in themes) _chip(label: _themeLabel(t), value: t),
        ],
      ),
    );
  }

  Widget _chip({required String label, required String? value}) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppTheme.surface.withValues(alpha: 0.6),
        selectedColor: AppTheme.accent.withValues(alpha: 0.85),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        // Re-sélectionner « Tout » (value null) revient à tout afficher.
        onSelected: (_) => onSelected(value),
      ),
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
      case kProgrammationTheme:
        return Icons.edit_calendar;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Heure affichée : l'heure prévue si dispo (créneaux), sinon l'heure de
    // création (clôture/palmarès/programmation).
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
  final bool filtered;
  const _EmptyState({required this.onRefresh, this.filtered = false});

  @override
  Widget build(BuildContext context) {
    // ListView (même vide) pour que le pull-to-refresh fonctionne.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(
            filtered ? Icons.filter_alt_off_outlined : Icons.auto_stories_outlined,
            size: 56,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              filtered
                  ? 'Aucune notif pour ce filtre'
                  : 'Le journal est vide pour l\'instant',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              filtered
                  ? 'Choisis « Tout » pour revoir l\'ensemble des notifications.'
                  : 'Les notifications du festival apparaîtront ici au fil des jours.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
