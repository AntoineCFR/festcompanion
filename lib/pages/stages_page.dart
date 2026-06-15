import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/stage_model.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/location_helper.dart';
import '../widgets/stages/stage_card.dart';
import '../widgets/shared/festival_background.dart';

class StagesPage extends StatefulWidget {
  final String username;
  final int userId;

  const StagesPage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<StagesPage> createState() => _StagesPageState();
}

class _StagesPageState extends State<StagesPage> {
  List<Stage> _stages = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1) Scènes en premier : loadStages affiche le cache local immédiatement
    //    (puis rafraîchit en fond → pastille). On applique dès qu'on a les
    //    scènes, SANS attendre le réseau utilisateurs.
    try {
      await AppDataManager().loadStages();
    } catch (_) {
      // Échec sans cache : on retombera sur l'état vide via _applyData.
    }
    if (mounted) _applyData();

    // 2) Utilisateurs en arrière-plan : ne sert qu'au rôle admin → ne doit pas
    //    retarder l'affichage des scènes.
    AppDataManager().loadUsers().then((_) {
      if (mounted) _applyData();
    }).catchError((_) {});
  }

  /// Trie les scènes selon `stage_order` du festival et rafraîchit l'UI.
  /// Idempotent (appelé pour les scènes puis pour le rôle utilisateur).
  void _applyData() {
    // Ordre d'affichage = `stage_order` du festival. La table `stages`
    // (géoloc) ne le porte pas, mais la timetable si → on en dérive un ordre
    // par nom de scène, avec repli alphabétique insensible à la casse pour les
    // scènes absentes de la timetable.
    final orderByStage = <String, int>{};
    for (final item in AppDataManager().timetable) {
      final o = item.stageOrder;
      if (o != null) orderByStage.putIfAbsent(item.stage, () => o);
    }
    final stages = List<Stage>.from(AppDataManager().stages)
      ..sort((a, b) {
        final oa = orderByStage[a.stage];
        final ob = orderByStage[b.stage];
        if (oa != null && ob != null && oa != ob) return oa.compareTo(ob);
        if (oa != null && ob == null) return -1;
        if (oa == null && ob != null) return 1;
        return a.stage.toLowerCase().compareTo(b.stage.toLowerCase());
      });

    final user = AppDataManager().users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => User(id: -1, username: '', userRole: 'user'),
    );

    setState(() {
      _stages = stages;
      _userRole = user.userRole;
      _isLoading = false;
    });
  }

  bool get _isAdmin => _userRole == 'admin';

  Future<void> _setCoordinates(String stageName, String corner) async {
    // Vérifie que le widget est toujours monté AVANT toute opération async
    if (!mounted) return;

    try {
      final currentLocation = await LocationHelper.tryGetCurrentPosition();
      if (currentLocation == null) {
        AppDataManager().showSnackBar('Impossible de récupérer votre position.');
        return;
      }

      // Vérifie à nouveau avant d'ouvrir la dialog
      if (!mounted) return;

      // Demande de confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Confirmer'),
          content: Text(
            'Voulez-vous définir la position actuelle pour le $corner de $stageName ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      // Vérifie une dernière fois avant de modifier l'état
      if (confirm != true || !mounted) return;

      final stageIndex = _stages.indexWhere((s) => s.stage == stageName);
      if (stageIndex == -1) return;

      final stage = _stages[stageIndex];
      final coordinates = <String, dynamic>{
        'lat_avg': stage.latAvg,
        'lon_avg': stage.lonAvg,
        'lat_avd': stage.latAvd,
        'lon_avd': stage.lonAvd,
        'lat_arg': stage.latArg,
        'lon_arg': stage.lonArg,
        'lat_ard': stage.latArd,
        'lon_ard': stage.lonArd,
        'lat_rally_point': stage.latRallyPoint,
        'lon_rally_point': stage.lonRallyPoint,
      };

      // Met à jour selon le coin
      switch (corner) {
        case 'avd':
          coordinates['lat_avd'] = currentLocation.latitude;
          coordinates['lon_avd'] = currentLocation.longitude;
          break;
        case 'avg':
          coordinates['lat_avg'] = currentLocation.latitude;
          coordinates['lon_avg'] = currentLocation.longitude;
          break;
        case 'arg':
          coordinates['lat_arg'] = currentLocation.latitude;
          coordinates['lon_arg'] = currentLocation.longitude;
          break;
        case 'ard':
          coordinates['lat_ard'] = currentLocation.latitude;
          coordinates['lon_ard'] = currentLocation.longitude;
          break;
        case 'rally':
          coordinates['lat_rally_point'] = currentLocation.latitude;
          coordinates['lon_rally_point'] = currentLocation.longitude;
          break;
      }

      await AppDataManager().updateStage(stageName, coordinates);

      // Vérifie une dernière fois avant setState
      if (!mounted) return;

      setState(() {
        _stages[stageIndex] = stage.copyWith(
          latAvg: corner == 'avg' ? currentLocation.latitude : stage.latAvg,
          lonAvg: corner == 'avg' ? currentLocation.longitude : stage.lonAvg,
          latAvd: corner == 'avd' ? currentLocation.latitude : stage.latAvd,
          lonAvd: corner == 'avd' ? currentLocation.longitude : stage.lonAvd,
          latArg: corner == 'arg' ? currentLocation.latitude : stage.latArg,
          lonArg: corner == 'arg' ? currentLocation.longitude : stage.lonArg,
          latArd: corner == 'ard' ? currentLocation.latitude : stage.latArd,
          lonArd: corner == 'ard' ? currentLocation.longitude : stage.lonArd,
          latRallyPoint: corner == 'rally' ? currentLocation.latitude : stage.latRallyPoint,
          lonRallyPoint: corner == 'rally' ? currentLocation.longitude : stage.lonRallyPoint,
        );
      });
      AppDataManager().showSnackBar('Coordonnées mises à jour !');
    } catch (e) {
      if (mounted) {
        AppDataManager().showSnackBar('Erreur: $e');
      }
    }
  }

  void _openInGoogleMaps(double lat, double lng) async {
    final success = await LocationHelper.openInGoogleMaps(
      latitude: lat,
      longitude: lng,
    );
    if (!success && mounted) {
      AppDataManager().showSnackBar('Impossible d\'ouvrir Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Scènes'),
        backgroundColor: AppTheme.surface,
      ),
      body: FestivalBackground(
        imageKey: 'featured',
        refreshDomains: const [LoadDomain.stages],
        refreshLabel: 'Mise à jour des scènes…',
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stages.isEmpty
                ? _buildEmptyState()
                : _buildStageList(),
      ),
    );
  }

  Widget _buildStageList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _stages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildIntro();
        final stage = _stages[index - 1];
        return StageCard(
          key: ValueKey(stage.stage),
          stage: stage,
          isAdmin: _isAdmin,
          onSetCoordinates: _setCoordinates,
          onOpenInMaps: _openInGoogleMaps,
        );
      },
    );
  }

  Widget _buildIntro() {
    final count = _stages.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 2),
      child: Row(
        children: [
          Icon(Icons.place_outlined, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            '$count scène${count > 1 ? 's' : ''} · touche pour le point de ralliement',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
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
            Icon(Icons.location_off_outlined,
                size: 56, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            const Text(
              'Aucune scène disponible',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Les scènes de ce festival n\'ont pas encore été ajoutées.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
