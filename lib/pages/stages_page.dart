import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/stage_model.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/location_helper.dart';
import '../widgets/stages/stage_card.dart';

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
  String? _selectedStage;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Charge scènes et utilisateurs en parallèle
      await Future.wait([
        AppDataManager().loadStages(),
        AppDataManager().loadUsers(),
      ]);

      if (!mounted) return;

      final stages = List<Stage>.from(AppDataManager().stages)
        ..sort((a, b) => a.stage.compareTo(b.stage));

      final user = AppDataManager().users.firstWhere(
        (u) => u.id == widget.userId,
        orElse: () => User(id: -1, username: '', userRole: 'user'),
      );

      setState(() {
        _stages = stages;
        _selectedStage = stages.isNotEmpty ? stages.first.stage : null;
        _userRole = user.userRole;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _showStagePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceAlt,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: _stages
            .map(
              (s) => ListTile(
                title: Text(
                  s.stage,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: s.stage == _selectedStage
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: s.stage == _selectedStage
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _selectedStage = s.stage);
                  Navigator.pop(ctx);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _selectedStage != null
        ? _stages.where((s) => s.stage == _selectedStage).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Scènes'),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bandeau sélecteur — cliquable
                GestureDetector(
                  onTap: _stages.isNotEmpty ? _showStagePicker : null,
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.surfaceAlt,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedStage ?? 'Aucune scène',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                // Carte de la scène sélectionnée
                if (current != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: StageCard(
                        stage: current,
                        isAdmin: _isAdmin,
                        onSetCoordinates: _setCoordinates,
                        onOpenInMaps: _openInGoogleMaps,
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Aucune scène disponible',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
