import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../services/app_data_manager.dart';

/// Photo(s) d'un set, qui remplit le cadre qu'on lui donne.
/// - Solo : une seule image.
/// - B2B ("Artiste A & Artiste B") : les photos individuelles côte à côte,
///   chacune sur une part égale de la largeur (séparées d'un fin trait).
class DjPhoto extends StatelessWidget {
  final String djName;
  final BoxFit fit;

  /// Alignement du recadrage `cover`. Par défaut on le déduit du festival :
  /// les photos Awakenings sont en **portrait** (plus hautes que larges) → un
  /// recadrage centré dans une vignette ~carrée coupe régulièrement le haut du
  /// crâne. On biaise alors légèrement vers le haut pour garder le visage.
  /// Les photos Extrema étant souvent déjà bien cadrées, on les laisse centrées.
  /// Léger décalage seulement (l'user a prévenu : ne pas trop décaler les
  /// photos déjà centrées).
  final Alignment? alignment;

  const DjPhoto({
    super.key,
    required this.djName,
    this.fit = BoxFit.cover,
    this.alignment,
  });

  /// Alignement effectif : explicite si fourni, sinon festival-dépendant.
  Alignment get _effectiveAlignment {
    if (alignment != null) return alignment!;
    final slug = (AppDataManager().selectedFestival?.slug ?? '').toLowerCase();
    // Biais vers le haut (révèle le crâne) pour les portraits Awakenings.
    if (slug.contains('awakenings')) return const Alignment(0, -0.35);
    return Alignment.center;
  }

  Widget _image(String path) => Image.asset(
        path,
        fit: fit,
        alignment: _effectiveAlignment,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.surfaceAlt,
          child: const Icon(Icons.person, color: Colors.white54, size: 18),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final paths = AppUtils.getDjImagePaths(djName);
    if (paths.length <= 1) {
      return _image(paths.isNotEmpty ? paths.first : '');
    }
    return Row(
      children: [
        for (int i = 0; i < paths.length; i++) ...[
          Expanded(child: _image(paths[i])),
          if (i < paths.length - 1) const SizedBox(width: 1),
        ],
      ],
    );
  }
}
