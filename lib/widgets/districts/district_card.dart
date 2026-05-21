import 'package:flutter/material.dart';
import '../../models/district_model.dart';

class DistrictCard extends StatelessWidget {
  final District district;
  final bool isAdmin;
  final Function(String, String) onSetCoordinates;
  final Function(double, double) onOpenInMaps;

  const DistrictCard({
    super.key,
    required this.district,
    required this.isAdmin,
    required this.onSetCoordinates,
    required this.onOpenInMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              district.district,
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
                        () => onSetCoordinates(district.district, 'avg'),
                      ),
                    ),
                    // AVD — Avant-Droit (haut-droite)
                    Align(
                      alignment: Alignment.topRight,
                      child: _buildCornerPoint(
                        'AVD',
                        () => onSetCoordinates(district.district, 'avd'),
                      ),
                    ),
                    // ARG — Arrière-Gauche (bas-gauche)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: _buildCornerPoint(
                        'ARG',
                        () => onSetCoordinates(district.district, 'arg'),
                      ),
                    ),
                    // ARD — Arrière-Droit (bas-droite)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _buildCornerPoint(
                        'ARD',
                        () => onSetCoordinates(district.district, 'ard'),
                      ),
                    ),
                    // Point de ralliement — centre
                    Center(
                      child: _buildRallyPoint(
                        district.latRallyPoint,
                        district.lonRallyPoint,
                        () => onSetCoordinates(district.district, 'rally'),
                        () => onOpenInMaps(
                          district.latRallyPoint,
                          district.lonRallyPoint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Coordonnées textuelles
            _buildCoordinateRow('Avant-Gauche', district.latAvg, district.lonAvg),
            _buildCoordinateRow('Avant-Droit', district.latAvd, district.lonAvd),
            _buildCoordinateRow('Arrière-Gauche', district.latArg, district.lonArg),
            _buildCoordinateRow('Arrière-Droit', district.latArd, district.lonArd),
            const Divider(color: Colors.white38),
            _buildCoordinateRow(
                'Point de ralliement', district.latRallyPoint, district.lonRallyPoint),
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
