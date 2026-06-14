import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/festival_model.dart';
import '../services/api_service.dart';
import '../services/app_data_manager.dart';
import 'splash_login.dart';

/// Porte d'entrée post-authentification :
/// 1. Si aucun festival n'est sélectionné → affiche la liste des festivals.
/// 2. Une fois un festival choisi → charge les données globales puis enchaîne
///    vers SplashLogin (session utilisateur).
class FestivalGate extends StatefulWidget {
  final int userId;
  final String username;

  /// Force l'écran de sélection même si un festival est déjà sélectionné
  /// (utilisé pour « changer de festival » depuis le drawer).
  final bool forceSelection;

  const FestivalGate({
    super.key,
    required this.userId,
    required this.username,
    this.forceSelection = false,
  });

  @override
  State<FestivalGate> createState() => _FestivalGateState();
}

class _FestivalGateState extends State<FestivalGate> {
  Festival? _selected;
  // ⚠️ Le Future DOIT être stocké en champ (pas recréé inline dans le
  // FutureBuilder) : MaterialApp se reconstruit à chaque `dataRevision++`
  // (chargements de fond), ce qui rebâtit FestivalGate. Un future inline
  // relancerait loadEssentialData à chaque rebuild → boucle infinie de
  // requêtes (request storm sur /timetable). Cf. incident 2026-06-14.
  Future<void>? _loadFuture;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.forceSelection ? null : AppDataManager().selectedFestival;
    if (_selected != null) {
      _loadFuture = AppDataManager().loadEssentialData();
    }
  }

  Future<void> _onFestivalChosen(Festival festival) async {
    await AppDataManager().setSelectedFestival(festival);
    if (mounted) {
      setState(() {
        _selected = festival;
        _loadFuture = AppDataManager().loadEssentialData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selected == null || _loadFuture == null) {
      return _FestivalPicker(onChosen: _onFestivalChosen);
    }

    // Festival choisi → charge les données puis va à SplashLogin.
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CenteredLoader(message: 'Chargement des données...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 20),
                  const Text(
                    'Impossible de charger les données',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _loadFuture = AppDataManager().loadEssentialData();
                    }),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SplashLogin(
                      userId: widget.userId,
                      username: widget.username,
                    ),
                  ),
                );
              }
            });
          }
          return const _CenteredLoader(message: 'Prêt !');
        },
      ),
    );
  }
}

class _FestivalPicker extends StatelessWidget {
  final Future<void> Function(Festival) onChosen;

  const _FestivalPicker({required this.onChosen});

  String _dateRange(Festival f) {
    String d(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';
    return '${d(f.startDate)} → ${d(f.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Choisir un festival'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Festival>>(
        future: ApiService.fetchFestivals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CenteredLoader(message: 'Chargement des festivals...');
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur : ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final festivals = snapshot.data ?? [];
          if (festivals.isEmpty) {
            return const Center(
              child: Text(
                'Aucun festival disponible',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: festivals.length,
            itemBuilder: (context, index) {
              final f = festivals[index];
              return Card(
                color: AppTheme.surfaceAlt,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.festival, color: AppTheme.accent),
                  title: Text(f.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${f.city} · ${_dateRange(f)}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () => onChosen(f),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  final String message;
  const _CenteredLoader({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
