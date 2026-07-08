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
  // Garde anti-réentrance : empêche les acquisitions/écritures concurrentes
  // (clics répétés → dialogs empilés / sauvegardes en double).
  bool _busy = false;

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

  /// Trie les scènes selon leur ordre d'affichage et rafraîchit l'UI.
  /// Idempotent (appelé pour les scènes puis pour le rôle utilisateur).
  void _applyData() {
    // Ordre d'affichage : `stage.stageOrder` explicite (posé par un admin
    // dans l'admin panel) prime s'il existe. Sinon repli sur l'ordre dérivé
    // de la timetable (posé par les sets — la table `stages` géoloc ne le
    // portait pas jusqu'à l'ajout de la colonne explicite), puis alphabétique
    // insensible à la casse pour les scènes sans aucun des deux.
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

  /// Tournure lisible du coin pour le message de confirmation.
  String _cornerPhrase(String corner) {
    switch (corner) {
      case 'avg':
        return 'le coin avant-gauche';
      case 'avd':
        return 'le coin avant-droit';
      case 'arg':
        return 'le coin arrière-gauche';
      case 'ard':
        return 'le coin arrière-droit';
      case 'rally':
        return 'le point de ralliement';
    }
    return 'ce point';
  }

  Future<void> _setCoordinates(String stageName, String corner) async {
    if (_busy) return; // un clic à la fois

    // Confirmation AVANT l'acquisition GPS : le dialog s'ouvre instantanément
    // (réactif) et sa barrière modale empêche les clics suivants → plus de
    // dialogs empilés. L'acquisition (lente) n'a lieu qu'APRÈS confirmation.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(
          'Voulez-vous définir la position actuelle pour '
          '${_cornerPhrase(corner)} de la scène $stageName ?',
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
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    AppDataManager().showSnackBar('Acquisition de votre position…');
    try {
      final currentLocation = await LocationHelper.tryGetCurrentPosition();
      if (currentLocation == null) {
        AppDataManager().showSnackBar('Impossible de récupérer votre position.');
        return;
      }
      await _applyCorner(stageName, corner, currentLocation.latitude,
          currentLocation.longitude);
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Saisie manuelle (admin) : applique directement les coordonnées tapées (le
  /// dialog de saisie tient lieu de confirmation).
  Future<void> _setCoordinatesManual(
      String stageName, String corner, double lat, double lng) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _applyCorner(stageName, corner, lat, lng);
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Écrit la paire (lat, lng) sur un coin/ralliement d'une scène : persiste via
  /// l'API puis met à jour l'état local. Commun aux deux saisies (GPS / manuelle).
  Future<void> _applyCorner(
      String stageName, String corner, double lat, double lng) async {
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
        coordinates['lat_avd'] = lat;
        coordinates['lon_avd'] = lng;
        break;
      case 'avg':
        coordinates['lat_avg'] = lat;
        coordinates['lon_avg'] = lng;
        break;
      case 'arg':
        coordinates['lat_arg'] = lat;
        coordinates['lon_arg'] = lng;
        break;
      case 'ard':
        coordinates['lat_ard'] = lat;
        coordinates['lon_ard'] = lng;
        break;
      case 'rally':
        coordinates['lat_rally_point'] = lat;
        coordinates['lon_rally_point'] = lng;
        break;
    }

    await AppDataManager().updateStage(stageName, coordinates);

    if (!mounted) return;

    setState(() {
      _stages[stageIndex] = stage.copyWith(
        latAvg: corner == 'avg' ? lat : stage.latAvg,
        lonAvg: corner == 'avg' ? lng : stage.lonAvg,
        latAvd: corner == 'avd' ? lat : stage.latAvd,
        lonAvd: corner == 'avd' ? lng : stage.lonAvd,
        latArg: corner == 'arg' ? lat : stage.latArg,
        lonArg: corner == 'arg' ? lng : stage.lonArg,
        latArd: corner == 'ard' ? lat : stage.latArd,
        lonArd: corner == 'ard' ? lng : stage.lonArd,
        latRallyPoint: corner == 'rally' ? lat : stage.latRallyPoint,
        lonRallyPoint: corner == 'rally' ? lng : stage.lonRallyPoint,
      );
    });
    AppDataManager().showSnackBar('Coordonnées mises à jour !');
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
          onSetCoordinatesManual: _setCoordinatesManual,
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
