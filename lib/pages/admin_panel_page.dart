import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/stage_model.dart';
import '../models/timetable_item.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/app_data_manager.dart';
import '../utils/utils.dart';
import '../widgets/shared/festival_background.dart';
import 'lineup_preview_page.dart';

/// Écran admin (scènes + sets manuels). Visible depuis le drawer pour tout le
/// monde — comme "Scènes" — mais le contenu est filtré par rôle À L'INTÉRIEUR
/// de la page (même convention que StagesPage), pas au niveau du drawer.
class AdminPanelPage extends StatefulWidget {
  final String username;
  final int userId;

  const AdminPanelPage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  bool _isLoading = true;
  String? _userRole;
  // Garde anti-réentrance (même pattern que StagesPage) : empêche les
  // écritures concurrentes (clics répétés → dialogs empilés / doublons).
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await AppDataManager().loadStages();
    } catch (_) {
      // Échec sans cache : on retombera sur une liste vide.
    }
    try {
      await AppDataManager().loadTimetable();
    } catch (_) {
      // Idem.
    }
    if (mounted) _applyData();

    AppDataManager().loadUsers().then((_) {
      if (mounted) _applyData();
    }).catchError((_) {});
  }

  void _applyData() {
    final user = AppDataManager().users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => User(id: -1, username: '', userRole: 'user'),
    );
    setState(() {
      _userRole = user.userRole;
      _isLoading = false;
    });
  }

  bool get _isAdmin => _userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Administration'),
          backgroundColor: AppTheme.surface,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Administration'),
          backgroundColor: AppTheme.surface,
        ),
        body: FestivalBackground(
          imageKey: 'featured',
          child: _buildRestricted(),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Administration'),
          backgroundColor: AppTheme.surface,
          bottom: const TabBar(
            tabs: [Tab(text: 'Scènes'), Tab(text: 'Sets')],
          ),
        ),
        body: FestivalBackground(
          imageKey: 'featured',
          refreshDomains: const [LoadDomain.stages, LoadDomain.timetable],
          child: TabBarView(
            children: [_buildStagesTab(), _buildSetsTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildRestricted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 56, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            const Text(
              'Accès réservé aux administrateurs',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ========== SCÈNES ==========

  Widget _buildStagesTab() {
    final stages = AppDataManager().stages;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _createStageDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une scène'),
            ),
          ),
        ),
        Expanded(
          child: stages.isEmpty
              ? const Center(
                  child: Text('Aucune scène',
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: stages.length,
                  itemBuilder: (context, index) =>
                      _buildStageRow(stages[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildStageRow(Stage stage) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(stage.stage, style: const TextStyle(color: Colors.white)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: _busy ? null : () => _deleteStage(stage.stage),
        ),
      ),
    );
  }

  Future<void> _createStageDialog() async {
    final nameCtrl = TextEditingController();
    String? error;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Nouvelle scène',
              style: TextStyle(color: Colors.white, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nom de la scène',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final trimmed = nameCtrl.text.trim();
                if (trimmed.isEmpty) {
                  setDialogState(() => error = 'Nom requis');
                  return;
                }
                Navigator.pop(ctx, trimmed);
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    if (name == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ApiService.createStage(name, userId: widget.userId);
      await AppDataManager().refreshStagesForced();
      if (mounted) AppDataManager().showSnackBar('Scène « $name » créée.');
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteStage(String stageName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer la scène « $stageName » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ApiService.deleteStage(stageName, userId: widget.userId);
      await AppDataManager().refreshStagesForced();
      if (mounted) {
        AppDataManager().showSnackBar('Scène « $stageName » supprimée.');
      }
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ========== SETS ==========

  Widget _buildSetsTab() {
    final sets = List<TimetableItem>.from(AppDataManager().timetable)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _previewLineupChanges,
                  icon: const Icon(Icons.sync),
                  label: const Text('Prévisualiser mise à jour line-up'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _busy ? null : () => _setFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        Expanded(
          child: sets.isEmpty
              ? const Center(
                  child: Text('Aucun set',
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: sets.length,
                  itemBuilder: (context, index) => _buildSetRow(sets[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSetRow(TimetableItem item) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.dj, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '${TimetableItem.stageLabel(item.stage, item.host)} · '
          '${AppUtils.getDayName(item.day)} '
          '${AppUtils.formatTime(item.startTime)}-${AppUtils.formatTime(item.endTime)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: _busy ? null : () => _setFormDialog(existing: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _busy ? null : () => _deleteSet(item),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _setFormDialog({TimetableItem? existing}) async {
    final stages = AppDataManager().stages;
    if (stages.isEmpty) {
      AppDataManager()
          .showSnackBar('Aucune scène disponible — créez-en une d\'abord.');
      return;
    }

    final djCtrl = TextEditingController(text: existing?.dj);
    final hostCtrl = TextEditingController(text: existing?.host);
    final dayCtrl = TextEditingController(text: existing?.day);
    final dayIntCtrl =
        TextEditingController(text: existing?.dayInt.toString());
    final bioCtrl = TextEditingController(text: existing?.bio);
    // Repli sur la 1re scène si celle du set édité n'existe plus (renommée /
    // supprimée depuis) : évite un crash du Dropdown (valeur hors liste).
    String selectedStage = stages.any((s) => s.stage == existing?.stage)
        ? existing!.stage
        : stages.first.stage;
    DateTime? start = existing?.startTime;
    DateTime? end = existing?.endTime;
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(existing == null ? 'Nouveau set' : 'Modifier le set',
              style: const TextStyle(color: Colors.white, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: djCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'DJ',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedStage,
                  isExpanded: true,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: Colors.white),
                  items: stages
                      .map((s) => DropdownMenuItem(
                            value: s.stage,
                            child: Text(s.stage),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedStage = v);
                  },
                ),
                TextField(
                  controller: hostCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Collectif (optionnel)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: dayCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Jour',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: dayIntCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Jour n° (0 = premier)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: bioCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Bio (optionnel)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    start == null
                        ? 'Début'
                        : 'Début : ${AppUtils.formatTime(start!)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing:
                      const Icon(Icons.schedule, color: Colors.white70),
                  onTap: () async {
                    final picked = await _pickDateTime(start);
                    if (picked != null) setDialogState(() => start = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    end == null ? 'Fin' : 'Fin : ${AppUtils.formatTime(end!)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing:
                      const Icon(Icons.schedule, color: Colors.white70),
                  onTap: () async {
                    final picked = await _pickDateTime(end);
                    if (picked != null) setDialogState(() => end = picked);
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (djCtrl.text.trim().isEmpty ||
                    dayCtrl.text.trim().isEmpty ||
                    int.tryParse(dayIntCtrl.text.trim()) == null ||
                    start == null ||
                    end == null) {
                  setDialogState(() => error =
                      'DJ, jour, jour n° et horaires sont requis (jour n° = nombre).');
                  return;
                }
                if (!end!.isAfter(start!)) {
                  setDialogState(
                      () => error = 'La fin doit être après le début.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(existing == null ? 'Créer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final data = <String, dynamic>{
      'dj': djCtrl.text.trim(),
      'stage': selectedStage,
      'host': hostCtrl.text.trim(),
      'day': dayCtrl.text.trim(),
      'day_int': int.parse(dayIntCtrl.text.trim()),
      'bio': bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
      'start_time': start!.toUtc().toIso8601String(),
      'end_time': end!.toUtc().toIso8601String(),
    };

    setState(() => _busy = true);
    try {
      if (existing == null) {
        await ApiService.createSet(data, userId: widget.userId);
      } else {
        await ApiService.updateSet(existing.setId, data, userId: widget.userId);
      }
      await AppDataManager().refreshTimetableForced();
      if (mounted) {
        AppDataManager()
            .showSnackBar(existing == null ? 'Set créé.' : 'Set mis à jour.');
      }
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteSet(TimetableItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer le set de « ${item.dj} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ApiService.deleteSet(item.setId, userId: widget.userId);
      await AppDataManager().refreshTimetableForced();
      if (mounted) AppDataManager().showSnackBar('Set supprimé.');
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Lance le dry-run puis ouvre l'écran d'aperçu détaillé (avant/après,
  /// sélection par case à cocher) — l'application réelle se fait depuis cet
  /// écran, pas ici.
  Future<void> _previewLineupChanges() async {
    setState(() => _busy = true);
    Map<String, dynamic>? result;
    try {
      result = await ApiService.previewLineupChanges(userId: widget.userId);
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (result == null || !mounted) return;

    if (result['skipped'] != null) {
      AppDataManager().showSnackBar('Aperçu indisponible : ${result['skipped']}');
      return;
    }

    final detail = ((result['detail'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    if (detail.isEmpty) {
      AppDataManager().showSnackBar('Aucun changement détecté.');
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LineupPreviewPage(userId: widget.userId, changes: detail),
      ),
    );
  }
}
