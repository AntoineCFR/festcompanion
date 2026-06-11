import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/stage_model.dart';

class StageCard extends StatelessWidget {
  final Stage stage;
  final bool isAdmin;
  final Function(String, String) onSetCoordinates;
  final Function(double, double) onOpenInMaps;

  const StageCard({
    super.key,
    required this.stage,
    required this.isAdmin,
    required this.onSetCoordinates,
    required this.onOpenInMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              stage.stage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Carré avec les 4 coins + point de ralliement
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: Stack(
                  children: [
                    // AVG — Avant-Gauche (haut-gauche)
                    Align(
                      alignment: Alignment.topLeft,
                      child: _buildCornerPoint(
                        'AVG',
                        () => onSetCoordinates(stage.stage, 'avg'),
                      ),
                    ),
                    // AVD — Avant-Droit (haut-droite)
                    Align(
                      alignment: Alignment.topRight,
                      child: _buildCornerPoint(
                        'AVD',
                        () => onSetCoordinates(stage.stage, 'avd'),
                      ),
                    ),
                    // ARG — Arrière-Gauche (bas-gauche)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: _buildCornerPoint(
                        'ARG',
                        () => onSetCoordinates(stage.stage, 'arg'),
                      ),
                    ),
                    // ARD — Arrière-Droit (bas-droite)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _buildCornerPoint(
                        'ARD',
                        () => onSetCoordinates(stage.stage, 'ard'),
                      ),
                    ),
                    // Point de ralliement — centre
                    Center(
                      child: _buildRallyPoint(
                        stage.latRallyPoint,
                        stage.lonRallyPoint,
                        () => onSetCoordinates(stage.stage, 'rally'),
                        () => onOpenInMaps(
                          stage.latRallyPoint,
                          stage.lonRallyPoint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Coordonnées textuelles
            _buildCoordinateRow('Avant-Gauche', stage.latAvg, stage.lonAvg),
            _buildCoordinateRow('Avant-Droit', stage.latAvd, stage.lonAvd),
            _buildCoordinateRow('Arrière-Gauche', stage.latArg, stage.lonArg),
            _buildCoordinateRow('Arrière-Droit', stage.latArd, stage.lonArd),
            const Divider(color: Colors.white38),
            _buildCoordinateRow(
                'Point de ralliement', stage.latRallyPoint, stage.lonRallyPoint),
          ],
        ),
      ),
    );
  }

  /// Coin AVG / AVD / ARG / ARD :
  /// - Icône réglage visible uniquement pour l'admin
  /// - Pas d'icône Maps (pas besoin pour les coins)
  Widget _buildCornerPoint(String label, VoidCallback onSet) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings, size: 20, color: Colors.blue),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              onPressed: onSet,
              tooltip: 'Définir ma position ici',
            ),
        ],
      ),
    );
  }

  /// Point de ralliement :
  /// - Icône localisation (tous) → ouvre Google Maps
  /// - Icône réglage (admin seulement) → définit la position actuelle
  Widget _buildRallyPoint(
    double lat,
    double lng,
    VoidCallback onSet,
    VoidCallback onOpenMaps,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ralliement',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.near_me, size: 22, color: Colors.green),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              onPressed: onOpenMaps,
              tooltip: 'Voir sur Google Maps',
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.settings, size: 22, color: Colors.blue),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: onSet,
                tooltip: 'Définir ma position ici',
              ),
          ],
        ),
      ],
    );
  }

  /// Ligne de coordonnées — deux lignes pour éviter l'overflow horizontal
  Widget _buildCoordinateRow(String label, double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            'Lat ${lat.toStringAsFixed(6)}   Lon ${lng.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
