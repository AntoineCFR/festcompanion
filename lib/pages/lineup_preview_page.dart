import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_data_manager.dart';
import '../utils/utils.dart';
import '../widgets/shared/festival_background.dart';

/// Aperçu détaillé des changements de line-up détectés par le scraper (dry-run),
/// avec avant/après et sélection (case à cocher) de ce qui doit être appliqué.
/// Tout est coché par défaut ; décocher une entrée l'exclut de l'application —
/// utile par ex. pour les sets ajoutés à la main pas encore repris par le site
/// scrapé, qui remontent à tort en "Annulé".
class LineupPreviewPage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> changes;

  const LineupPreviewPage({
    super.key,
    required this.userId,
    required this.changes,
  });

  @override
  State<LineupPreviewPage> createState() => _LineupPreviewPageState();
}

class _LineupPreviewPageState extends State<LineupPreviewPage> {
  final Set<String> _excludedKeys = {};
  bool _busy = false;

  static const _typeLabels = {
    'added': 'Ajouté',
    'rescheduled': 'Reprogrammé',
    'restored': 'Restauré',
    'cancelled': 'Annulé',
    'updated': 'Modifié',
  };

  /// Icône de la partie droite de la ligne, ramenée aux 3 catégories
  /// visuelles ajout / modification / annulation (`restored` = un set
  /// redevenu actif après une annulation, regroupé avec "ajout").
  static const _typeIcons = {
    'added': (Icons.add_circle, Colors.greenAccent),
    'restored': (Icons.add_circle, Colors.greenAccent),
    'rescheduled': (Icons.edit, Colors.orangeAccent),
    'updated': (Icons.edit, Colors.orangeAccent),
    'cancelled': (Icons.cancel, Colors.redAccent),
  };

  /// `.isoformat()` côté backend ne porte pas de timezone alors que la valeur
  /// est en réalité déjà en UTC (convention `_to_naive_utc`) — on force le
  /// suffixe pour que `DateTime.parse` l'interprète correctement (sinon Dart
  /// le prendrait pour une heure locale, décalée par rapport à la vraie heure).
  DateTime? _parseUtc(dynamic iso) {
    if (iso is! String) return null;
    return DateTime.parse(iso.endsWith('Z') ? iso : '${iso}Z');
  }

  String _timeRangeLabel(Map<String, dynamic> c) {
    final oldStart = _parseUtc(c['old_start']);
    final newStart = _parseUtc(c['new_start']);
    final oldEnd = _parseUtc(c['old_end']);
    final newEnd = _parseUtc(c['new_end']);
    switch (c['type']) {
      case 'added':
        return '→ ${AppUtils.formatTime(newStart!)}-${AppUtils.formatTime(newEnd!)}';
      case 'restored':
        return 'Maintenu ${AppUtils.formatTime(newStart!)}-${AppUtils.formatTime(newEnd!)}';
      case 'rescheduled':
        return '${AppUtils.formatTime(oldStart!)}-${AppUtils.formatTime(oldEnd!)} → '
            '${AppUtils.formatTime(newStart!)}-${AppUtils.formatTime(newEnd!)}';
      case 'cancelled':
        return '${AppUtils.formatTime(oldStart!)} → annulé';
      default:
        return _attrDiffsLabel(c);
    }
  }

  static const _fieldLabels = {
    'host': 'Stage host',
    'stage_order': 'Ordre scène',
    'dj': 'DJ',
    'stage': 'Scène',
    'day': 'Jour',
  };

  /// Détail d'un changement de type "updated" (pas d'horaire) : quel(s)
  /// champ(s) ont changé et leur ancienne/nouvelle valeur (`attr_diffs`,
  /// cf. bigquery.py `sync_timetable_festival`).
  String _attrDiffsLabel(Map<String, dynamic> c) {
    final diffs = c['attr_diffs'] as Map<String, dynamic>?;
    if (diffs == null || diffs.isEmpty) {
      return 'Détails modifiés (horaire inchangé)';
    }
    return diffs.entries.map((e) {
      final label = _fieldLabels[e.key] ?? e.key;
      final v = e.value as Map<String, dynamic>;
      final oldV = v['old']?.toString();
      final newV = v['new']?.toString();
      final oldDisplay = (oldV == null || oldV.isEmpty) ? '(vide)' : oldV;
      final newDisplay = (newV == null || newV.isEmpty) ? '(vide)' : newV;
      return '$label : $oldDisplay → $newDisplay';
    }).join(' · ');
  }

  /// Heure de passage d'origine : l'ancien horaire pour tout ce qui existait
  /// déjà (reprogrammé/restauré/annulé/modifié), le nouvel horaire pour un
  /// ajout pur (pas d'"origine" au sens propre).
  DateTime _originalTime(Map<String, dynamic> c) =>
      _parseUtc(c['old_start']) ?? _parseUtc(c['new_start']) ?? DateTime(0);

  /// jour -> scène -> changements, triés par heure de passage d'origine.
  Map<String, Map<String, List<Map<String, dynamic>>>> get _grouped {
    final byDay = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final c in widget.changes) {
      final day = c['day'] as String? ?? '?';
      final stage = c['stage'] as String? ?? '?';
      byDay
          .putIfAbsent(day, () => {})
          .putIfAbsent(stage, () => [])
          .add(c);
    }
    for (final stages in byDay.values) {
      for (final items in stages.values) {
        items.sort((a, b) => _originalTime(a).compareTo(_originalTime(b)));
      }
    }
    return byDay;
  }

  /// Jours triés chronologiquement (day_int connu via la timetable actuelle) ;
  /// un jour tout neuf (pas encore dans la timetable) est ajouté à la suite,
  /// par ordre alphabétique.
  List<String> _dayOrder(Set<String> present) {
    final known =
        AppDataManager().festivalDays.where(present.contains).toList();
    final extra = present.difference(known.toSet()).toList()..sort();
    return [...known, ...extra];
  }

  /// Scènes triées par ordre explicite (`Stage.stageOrder`, posé dans l'admin
  /// panel) si disponible, sinon ordre alphabétique.
  List<String> _stageOrder(Set<String> present) {
    final explicitOrder = AppDataManager().explicitStageOrder;
    final stages = present.toList()
      ..sort((a, b) {
        final ao = explicitOrder[a];
        final bo = explicitOrder[b];
        if (ao != null && bo != null) return ao.compareTo(bo);
        if (ao != null) return -1;
        if (bo != null) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return stages;
  }

  bool _isExcluded(Map<String, dynamic> c) => _excludedKeys.contains(c['key']);

  void _toggleOne(Map<String, dynamic> c, bool select) {
    setState(() {
      final key = c['key'] as String;
      if (select) {
        _excludedKeys.remove(key);
      } else {
        _excludedKeys.add(key);
      }
    });
  }

  void _toggleGroup(List<Map<String, dynamic>> items, bool select) {
    setState(() {
      for (final c in items) {
        final key = c['key'] as String;
        if (select) {
          _excludedKeys.remove(key);
        } else {
          _excludedKeys.add(key);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final days = _dayOrder(grouped.keys.toSet());
    final total = widget.changes.length;
    final selectedCount = total - _excludedKeys.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Aperçu line-up ($selectedCount/$total)'),
        backgroundColor: AppTheme.surface,
      ),
      body: FestivalBackground(
        imageKey: 'featured',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            for (final day in days) ..._buildDaySection(day, grouped[day]!),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _busy || selectedCount == 0 ? null : _apply,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Appliquer la sélection ($selectedCount)'),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDaySection(
      String day, Map<String, List<Map<String, dynamic>>> byStage) {
    final dayItems = byStage.values.expand((l) => l).toList();
    final allSelected = dayItems.every((c) => !_isExcluded(c));
    final stages = _stageOrder(byStage.keys.toSet());
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${AppUtils.getDayName(day)} (${dayItems.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _toggleGroup(dayItems, !allSelected),
              child: Text(allSelected ? 'Tout décocher' : 'Tout cocher'),
            ),
          ],
        ),
      ),
      for (final stage in stages) ..._buildStageSection(stage, byStage[stage]!),
    ];
  }

  List<Widget> _buildStageSection(
      String stage, List<Map<String, dynamic>> items) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2, left: 4),
        child: Text(
          stage,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
      for (final c in items) _buildRow(c),
    ];
  }

  Widget _buildRow(Map<String, dynamic> c) {
    final selected = !_isExcluded(c);
    final type = c['type'] as String? ?? '';
    final iconSpec = _typeIcons[type];
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 6),
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => _toggleOne(c, v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        title: Text(c['dj'] as String? ?? '',
            style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          _timeRangeLabel(c),
          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
        secondary: iconSpec == null
            ? null
            : Tooltip(
                message: _typeLabels[type] ?? type,
                child: Icon(iconSpec.$1, color: iconSpec.$2),
              ),
      ),
    );
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      final result = await ApiService.previewLineupChanges(
        userId: widget.userId,
        apply: true,
        exclude: _excludedKeys.toList(),
      );
      await AppDataManager().refreshTimetableForced();
      await AppDataManager().refreshStagesForced();
      if (mounted) {
        final pushed = result['pushed'] ?? 0;
        final excludedCount = result['excluded_count'] ?? 0;
        Navigator.of(context).pop();
        AppDataManager().showSnackBar(
            'Line-up mis à jour ($pushed notification(s) envoyée(s), '
            '$excludedCount rejetée(s)).');
      }
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
