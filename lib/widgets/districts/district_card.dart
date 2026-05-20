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
            // Titre du district
            Text(
              district.district,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Représentation visuelle du carré
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: Stack(
                  children: [
                    // Points des coins
                    _buildCornerPoint(
                      context,
                      'AVG',
                      district.latAvg,
                      district.lonAvg,
                      Alignment.topLeft,
                      isAdmin,
                      () => onSetCoordinates(district.district, 'avg'),
                      () => onOpenInMaps(district.latAvg, district.lonAvg),
                    ),
                    _buildCornerPoint(
                      context,
                      'AVD',
                      district.latAvd,
                      district.lonAvd,
                      Alignment.topRight,
                      isAdmin,
                      () => onSetCoordinates(district.district, 'avd'),
                      () => onOpenInMaps(district.latAvd, district.lonAvd),
                    ),
                    _buildCornerPoint(
                      context,
                      'ARG',
                      district.latArg,
                      district.lonArg,
                      Alignment.bottomLeft,
                      isAdmin,
                      () => onSetCoordinates(district.district, 'arg'),
                      () => onOpenInMaps(district.latArg, district.lonArg),
                    ),
                    _buildCornerPoint(
                      context,
                      'ARD',
                      district.latArd,
                      district.lonArd,
                      Alignment.bottomRight,
                      isAdmin,
                      () => onSetCoordinates(district.district, 'ard'),
                      () => onOpenInMaps(district.latArd, district.lonArd),
                    ),
                    // Point de ralliement au centre
                    Center(
                      child: _buildRallyPoint(
                        context,
                        district.latRallyPoint,
                        district.lonRallyPoint,
                        isAdmin,
                        () => onSetCoordinates(district.district, 'rally'),
                        () => onOpenInMaps(district.latRallyPoint, district.lonRallyPoint),
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
            const Divider(color: Colors.white54),
            _buildCoordinateRow('Point de ralliement', district.latRallyPoint, district.lonRallyPoint),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerPoint(
    BuildContext context,
    String label,
    double lat,
    double lng,
    Alignment alignment,
    bool isAdmin,
    VoidCallback onSetCoordinates,
    VoidCallback onOpenInMaps,
  ) {
    return Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.settings, size: 20, color: Colors.blue),
                  onPressed: onSetCoordinates,
                  tooltip: 'Définir ma position',
                ),
              IconButton(
                icon: const Icon(Icons.pin_drop, size: 20, color: Colors.red),
                onPressed: onOpenInMaps,
                tooltip: 'Voir sur Google Maps',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRallyPoint(
    BuildContext context,
    double lat,
    double lng,
    bool isAdmin,
    VoidCallback onSetCoordinates,
    VoidCallback onOpenInMaps,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ralliement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.settings, size: 20, color: Colors.blue),
                onPressed: onSetCoordinates,
                tooltip: 'Définir ma position',
              ),
            IconButton(
              icon: const Icon(Icons.pin_drop, size: 20, color: Colors.green),
              onPressed: onOpenInMaps,
              tooltip: 'Voir sur Google Maps',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordinateRow(String label, double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            'Lat: ${lat.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'Lon: ${lng.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}