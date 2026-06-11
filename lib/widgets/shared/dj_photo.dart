import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// Photo(s) d'un set, qui remplit le cadre qu'on lui donne.
/// - Solo : une seule image.
/// - B2B ("Artiste A & Artiste B") : les photos individuelles côte à côte,
///   chacune sur une part égale de la largeur (séparées d'un fin trait).
class DjPhoto extends StatelessWidget {
  final String djName;
  final BoxFit fit;

  const DjPhoto({super.key, required this.djName, this.fit = BoxFit.cover});

  Widget _image(String path) => Image.asset(
        path,
        fit: fit,
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
