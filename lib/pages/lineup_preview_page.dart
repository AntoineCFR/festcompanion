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

  static const _typeOrder = [
    'added',
    'rescheduled',
    'restored',
    'cancelled',
    'updated',
  ];
  static const _typeLabels = {
    'added': 'Ajouté',
    'rescheduled': 'Reprogrammé',
    'restored': 'Restauré',
    'cancelled': 'Annulé',
    'updated': 'Modifié',
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
    'host': 'Collectif',
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

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final c in widget.changes) {
      map.putIfAbsent(c['type'] as String? ?? '?', () => []).add(c);
    }
    return map;
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

  void _toggleType(List<Map<String, dynamic>> items, bool select) {
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
    final types = _typeOrder.where((t) => grouped.containsKey(t)).toList();
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
            for (final type in types) ..._buildTypeSection(type, grouped[type]!),
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

  List<Widget> _buildTypeSection(String type, List<Map<String, dynamic>> items) {
    final allSelected = items.every((c) => !_isExcluded(c));
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_typeLabels[type] ?? type} (${items.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _toggleType(items, !allSelected),
              child: Text(allSelected ? 'Tout décocher' : 'Tout cocher'),
            ),
          ],
        ),
      ),
      for (final c in items) _buildRow(c),
    ];
  }

  Widget _buildRow(Map<String, dynamic> c) {
    final selected = !_isExcluded(c);
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
          '${c['stage'] ?? ''} · ${AppUtils.getDayName(c['day'] as String? ?? '')} · '
          '${_timeRangeLabel(c)}',
          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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
