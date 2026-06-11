import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../widgets/favorite_star.dart';

class DJProfileHeader extends StatelessWidget {
  /// Une entrée par artiste : 1 pour un solo, 2+ pour un b2b (affichées côte à côte).
  final List<String> imagePaths;
  final String name;
  final String? stage;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const DJProfileHeader({
    super.key,
    required this.imagePaths,
    required this.name,
    this.stage,
    this.startTime,
    this.endTime,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  Widget _fallback() => Container(
        color: AppTheme.surface,
        child: const Center(
          child: Icon(Icons.person, color: Colors.white54, size: 64),
        ),
      );

  Widget _buildHeaderImage() {
    // Solo : image pleine largeur (comportement d'origine).
    if (imagePaths.length <= 1) {
      return SizedBox(
        width: double.infinity,
        child: Image.asset(
          imagePaths.isNotEmpty ? imagePaths.first : '',
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => SizedBox(height: 200, child: _fallback()),
        ),
      );
    }

    // B2B : photos côte à côte. On donne aux cases un ratio PORTRAIT (plus
    // hautes que larges) pour que le recadrage rogne les côtés et non le haut
    // (sinon les têtes sont coupées), et on aligne en haut par sécurité.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / imagePaths.length;
        return SizedBox(
          width: double.infinity,
          height: cellWidth * 1.25,
          child: Row(
            children: imagePaths
                .map((path) => Expanded(
                      child: Image.asset(
                        path,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) => _fallback(),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            _buildHeaderImage(),
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
            // Favorite star (à droite, symétrique)
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
              if (stage != null)
                Text(
                  stage!,
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
