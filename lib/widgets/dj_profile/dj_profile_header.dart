import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../widgets/favorite_star.dart'; // ← NOUVEAU

class DJProfileHeader extends StatelessWidget {
  final String imagePath;
  final String name;
  final String? district;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isFavorite; // ← NOUVEAU
  final VoidCallback onToggleFavorite; // ← NOUVEAU

  const DJProfileHeader({
    super.key,
    required this.imagePath,
    required this.name,
    this.district,
    this.startTime,
    this.endTime,
    required this.isFavorite, // ← NOUVEAU
    required this.onToggleFavorite, // ← NOUVEAU
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                imagePath,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
            // Bouton retour (à gauche)
            Positioned(
              top: 32,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            // ✅ Favorite star (à droite, symétrique)
            Positioned(
              top: 32,
              right: 16,
              child: FavoriteStar(
                isFavorite: isFavorite,
                onPressed: onToggleFavorite,
                size: 32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (district != null)
                Text(
                  district!,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              if (startTime != null && endTime != null)
                Text(
                  '${AppUtils.formatTime(startTime!)} - ${AppUtils.formatTime(endTime!)}',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ],
    );
  }
}