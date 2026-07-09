import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/festival_model.dart';
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

  /// Scènes triées par ordre d'affichage : `stage.stageOrder` explicite
  /// (posé par l'admin) prime s'il existe, sinon repli sur l'ordre dérivé de
  /// la timetable (posé par les sets), sinon alphabétique insensible à la
  /// casse — même logique que StagesPage._applyData.
  List<Stage> get _sortedStages {
    final derivedOrderByStage = <String, int>{};
    for (final item in AppDataManager().timetable) {
      final o = item.stageOrder;
      if (o != null) derivedOrderByStage.putIfAbsent(item.stage, () => o);
    }
    int? effectiveOrder(Stage s) => s.stageOrder ?? derivedOrderByStage[s.stage];
    final stages = List<Stage>.from(AppDataManager().stages)
      ..sort((a, b) {
        final oa = effectiveOrder(a);
        final ob = effectiveOrder(b);
        if (oa != null && ob != null && oa != ob) return oa.compareTo(ob);
        if (oa != null && ob == null) return -1;
        if (oa == null && ob != null) return 1;
        return a.stage.toLowerCase().compareTo(b.stage.toLowerCase());
      });
    return stages;
  }

  Widget _buildStagesTab() {
    final stages = _sortedStages;
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: _busy ? null : () => _renameStageDialog(stage),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _busy ? null : () => _deleteStage(stage.stage),
            ),
          ],
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

  /// Modifie le nom et/ou l'ordre d'affichage d'une scène. Identifiée par
  /// `stage.stageId` (pas par le nom courant) : c'est justement ce que
  /// `stage_id` permet — le renommage propage vers les sets déjà liés sans
  /// casser leur lien. L'ordre explicite prime sur celui dérivé des sets
  /// (utile pour une scène toute neuve, qui n'a encore aucun set).
  Future<void> _renameStageDialog(Stage stage) async {
    final stageId = stage.stageId;
    if (stageId == null) {
      AppDataManager().showSnackBar(
          'Cette scène n\'a pas encore de stage_id (migration pas appliquée '
          'ou scène créée avant) — modification indisponible.');
      return;
    }
    final nameCtrl = TextEditingController(text: stage.stage);
    final orderCtrl =
        TextEditingController(text: stage.stageOrder?.toString() ?? '');
    String? error;

    final result = await showDialog<(String, int?)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Modifier la scène',
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
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ordre d\'affichage (optionnel, vide = auto)',
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
                final orderText = orderCtrl.text.trim();
                int? order;
                if (orderText.isNotEmpty) {
                  order = int.tryParse(orderText);
                  if (order == null) {
                    setDialogState(
                        () => error = 'Ordre d\'affichage : nombre entier');
                    return;
                  }
                }
                Navigator.pop(ctx, (trimmed, order));
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final (newName, newOrder) = result;
    if (newName == stage.stage && newOrder == stage.stageOrder) return;

    setState(() => _busy = true);
    try {
      await ApiService.updateStageDetails(stage.stage, stageId, newName, newOrder,
          userId: widget.userId);
      await AppDataManager().refreshStagesForced();
      await AppDataManager().refreshTimetableForced();
      if (mounted) {
        AppDataManager().showSnackBar('Scène « $newName » mise à jour.');
      }
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

  /// Sets groupés par jour (ordre chronologique via `dayInt`), puis par
  /// scène au sein du jour (`stage.stageOrder` explicite en priorité, repli
  /// sur l'ordre dérivé de la timetable, puis alphabétique — même dérivation
  /// que [_sortedStages]), triés par horaire au sein de chaque sous-groupe
  /// jour/scène.
  List<Widget> _buildGroupedSetItems() {
    final allSets = AppDataManager().timetable;
    if (allSets.isEmpty) return const [];

    final dayIntByDay = <String, int>{};
    final derivedOrderByStage = <String, int>{};
    for (final item in allSets) {
      dayIntByDay.putIfAbsent(item.day, () => item.dayInt);
      final o = item.stageOrder;
      if (o != null) derivedOrderByStage.putIfAbsent(item.stage, () => o);
    }
    final explicitOrderByStage = AppDataManager().explicitStageOrder;
    final days = dayIntByDay.keys.toList()
      ..sort((a, b) => dayIntByDay[a]!.compareTo(dayIntByDay[b]!));

    int? orderFor(String stage) =>
        explicitOrderByStage[stage] ?? derivedOrderByStage[stage];
    int compareStages(String a, String b) {
      final oa = orderFor(a);
      final ob = orderFor(b);
      if (oa != null && ob != null && oa != ob) return oa.compareTo(ob);
      if (oa != null && ob == null) return -1;
      if (oa == null && ob != null) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    }

    final widgets = <Widget>[];
    for (final day in days) {
      final daySets = allSets.where((s) => s.day == day).toList();
      final stages = daySets.map((s) => s.stage).toSet().toList()
        ..sort(compareStages);

      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          AppUtils.getDayName(day),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ));
      for (final stage in stages) {
        final stageSets = daySets.where((s) => s.stage == stage).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
          child: Text(
            stage,
            style: TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ));
        for (final item in stageSets) {
          widgets.add(_buildSetRow(item));
        }
      }
    }
    return widgets;
  }

  Widget _buildSetsTab() {
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
          child: AppDataManager().timetable.isEmpty
              ? const Center(
                  child: Text('Aucun set',
                      style: TextStyle(color: Colors.white70)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: _buildGroupedSetItems(),
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
        // Jour et scène sont déjà les en-têtes du groupe/sous-groupe — pas
        // besoin de les répéter ici.
        subtitle: Text(
          item.host.trim().isEmpty
              ? '${AppUtils.formatTime(item.startTime)}-${AppUtils.formatTime(item.endTime)}'
              : '${item.host} · ${AppUtils.formatTime(item.startTime)}-'
                  '${AppUtils.formatTime(item.endTime)}',
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

  static const _weekdayNamesEn = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  /// Seuil afterparty : un set dont le début est avant 9h est rattaché à la
  /// nuit précédente. Même règle que le scraper backend
  /// (extremalineup-api/scrapers/awakenings.py) — à garder synchronisée.
  static const _afterpartyCutoffHour = 9;

  /// Jours calendaires du festival (bornes inclusives), à minuit. Étendu d'1
  /// jour après `end_date` : l'after de la dernière nuit peut déborder sur le
  /// calendrier du lendemain (ex. Awakenings termine le dimanche mais des
  /// sets d'after démarrent le lundi matin).
  List<DateTime> _festivalDays(Festival festival) {
    final start = DateTime(
        festival.startDate.year, festival.startDate.month, festival.startDate.day);
    final end = DateTime(
            festival.endDate.year, festival.endDate.month, festival.endDate.day)
        .add(const Duration(days: 1));
    return [
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) d,
    ];
  }

  /// Déduit le jour festival (nom + n°) à partir du jour calendaire et de
  /// l'heure de DÉBUT choisis : avant [_afterpartyCutoffHour] -> nuit
  /// précédente (afterparty), sinon jour même. Borné au 1er jour du festival
  /// (pas de nuit avant l'ouverture).
  ({String day, int dayInt}) _festivalDayInfo(
      DateTime calendarDay, int hour, Festival festival) {
    final firstDay = DateTime(
        festival.startDate.year, festival.startDate.month, festival.startDate.day);
    var nightDate = hour < _afterpartyCutoffHour
        ? calendarDay.subtract(const Duration(days: 1))
        : calendarDay;
    if (nightDate.isBefore(firstDay)) nightDate = firstDay;
    final dayInt = nightDate.difference(firstDay).inDays + 1;
    return (day: _weekdayNamesEn[nightDate.weekday - 1], dayInt: dayInt);
  }

  /// Ligne "jour / heure / minute" bornée aux jours du festival (heure et
  /// minute non bornées, un set peut débuter/finir à n'importe quelle heure).
  Widget _dayHourMinuteRow({
    required String label,
    required List<DateTime> days,
    required DateTime selectedDay,
    required int selectedHour,
    required int selectedMinute,
    required void Function(DateTime) onDayChanged,
    required void Function(int) onHourChanged,
    required void Function(int) onMinuteChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButton<DateTime>(
                value: selectedDay,
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: days
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child:
                              Text('${AppUtils.getWeekdayName(d)} ${d.day}/${d.month}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onDayChanged(v);
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: DropdownButton<int>(
                value: selectedHour,
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  for (var h = 0; h < 24; h++)
                    DropdownMenuItem(
                        value: h, child: Text('${h.toString().padLeft(2, '0')}h')),
                ],
                onChanged: (v) {
                  if (v != null) onHourChanged(v);
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: DropdownButton<int>(
                value: selectedMinute,
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  for (var m = 0; m < 60; m++)
                    DropdownMenuItem(
                        value: m, child: Text(m.toString().padLeft(2, '0'))),
                ],
                onChanged: (v) {
                  if (v != null) onMinuteChanged(v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _setFormDialog({TimetableItem? existing}) async {
    final stages = AppDataManager().stages;
    if (stages.isEmpty) {
      AppDataManager()
          .showSnackBar('Aucune scène disponible — créez-en une d\'abord.');
      return;
    }
    final festival = AppDataManager().selectedFestival;
    if (festival == null) {
      AppDataManager().showSnackBar('Aucun festival sélectionné.');
      return;
    }
    // Le backend renvoie déjà start_time/end_time décalés de l'offset du
    // festival (`GET /timetable` fait `df['start_time'] += offset`, cf.
    // app.py) : ces champs sont donc déjà "heure locale festival" telle
    // quelle, jamais de l'UTC brut à reconvertir ici. Le front reste en
    // heure de l'appareil (identique à l'ancien comportement) — la
    // conversion UTC ne se fait qu'entre le front et le backend, jamais dans
    // ce formulaire : voir `_to_naive_utc` côté API pour le sens inverse.
    final festivalDays = _festivalDays(festival);
    DateTime calendarDayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    DateTime clampToFestival(DateTime day) =>
        festivalDays.any((d) => d == day) ? day : festivalDays.first;

    final djCtrl = TextEditingController(text: existing?.dj);
    final hostCtrl = TextEditingController(text: existing?.host);
    final bioCtrl = TextEditingController(text: existing?.bio);
    // Repli sur la 1re scène si celle du set édité n'existe plus (renommée /
    // supprimée depuis) : évite un crash du Dropdown (valeur hors liste).
    String selectedStage = stages.any((s) => s.stage == existing?.stage)
        ? existing!.stage
        : stages.first.stage;

    DateTime startDay = existing != null
        ? clampToFestival(calendarDayOf(existing.startTime))
        : festivalDays.first;
    int startHour = existing?.startTime.hour ?? 20;
    int startMinute = existing?.startTime.minute ?? 0;
    DateTime endDay = existing != null
        ? clampToFestival(calendarDayOf(existing.endTime))
        : festivalDays.first;
    int endHour = existing?.endTime.hour ?? 21;
    int endMinute = existing?.endTime.minute ?? 0;
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dayInfo = _festivalDayInfo(startDay, startHour, festival);
          return AlertDialog(
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
                  const Text('Scène',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                      labelText: 'Stage host (optionnel)',
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
                  const SizedBox(height: 12),
                  _dayHourMinuteRow(
                    label: 'Début',
                    days: festivalDays,
                    selectedDay: startDay,
                    selectedHour: startHour,
                    selectedMinute: startMinute,
                    onDayChanged: (v) => setDialogState(() => startDay = v),
                    onHourChanged: (v) => setDialogState(() => startHour = v),
                    onMinuteChanged: (v) => setDialogState(() => startMinute = v),
                  ),
                  const SizedBox(height: 12),
                  _dayHourMinuteRow(
                    label: 'Fin',
                    days: festivalDays,
                    selectedDay: endDay,
                    selectedHour: endHour,
                    selectedMinute: endMinute,
                    onDayChanged: (v) => setDialogState(() => endDay = v),
                    onHourChanged: (v) => setDialogState(() => endHour = v),
                    onMinuteChanged: (v) => setDialogState(() => endMinute = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jour festival : ${AppUtils.getDayName(dayInfo.day)} (n°${dayInfo.dayInt})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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
                  if (djCtrl.text.trim().isEmpty) {
                    setDialogState(() => error = 'Le DJ est requis.');
                    return;
                  }
                  final start = DateTime(startDay.year, startDay.month,
                      startDay.day, startHour, startMinute);
                  final end = DateTime(endDay.year, endDay.month, endDay.day,
                      endHour, endMinute);
                  if (!end.isAfter(start)) {
                    setDialogState(
                        () => error = 'La fin doit être après le début.');
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: Text(existing == null ? 'Créer' : 'Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;

    final start = DateTime(
        startDay.year, startDay.month, startDay.day, startHour, startMinute);
    final end =
        DateTime(endDay.year, endDay.month, endDay.day, endHour, endMinute);
    final dayInfo = _festivalDayInfo(startDay, startHour, festival);

    final data = <String, dynamic>{
      'dj': djCtrl.text.trim(),
      'stage': selectedStage,
      'host': hostCtrl.text.trim(),
      'day': dayInfo.day,
      'day_int': dayInfo.dayInt,
      'bio': bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
      'start_time': start.toUtc().toIso8601String(),
      'end_time': end.toUtc().toIso8601String(),
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
    // Le tri/l'exclusion par entrée dépend de `change['key']`, ajouté au
    // backend en même temps que le support de l'apply partiel. Si le serveur
    // tourne encore sur une version antérieure (redéploiement pas terminé),
    // cette clé est absente : on le signale clairement plutôt que de laisser
    // les cases à cocher échouer silencieusement (exception avalée par le
    // gestionnaire de gestes Flutter, aucun retour visuel).
    if (detail.any((c) => c['key'] == null)) {
      AppDataManager().showSnackBar(
          'Le serveur ne renvoie pas encore les infos nécessaires à la '
          'sélection — le redéploiement backend n\'est probablement pas '
          'terminé. Réessaie dans une minute.');
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
