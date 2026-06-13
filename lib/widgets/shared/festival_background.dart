import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/app_data_manager.dart';

/// Fond d'écran propre au festival sélectionné, avec un voile dégradé pour
/// préserver la lisibilité du contenu posé dessus.
///
/// Image attendue : `lib/assets/backgrounds/<festivalId>_<imageKey>.jpg`
/// (ex. `1_home.jpg`, `2_featured.jpg`). Si l'image est absente, on retombe
/// proprement sur le fond uni du thème — aucun crash.
class FestivalBackground extends StatelessWidget {
  final String imageKey; // 'home' | 'featured'
  final Widget child;

  const FestivalBackground({
    super.key,
    required this.imageKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fid = AppDataManager().selectedFestivalId;
    final path =
        fid != null ? 'lib/assets/backgrounds/${fid}_$imageKey.jpg' : '';

    // Décode l'image à la largeur réelle de l'écran (et non en pleine
    // résolution) : le fond est désormais présent sur quasiment toutes les
    // pages, et décoder une grande JPEG plein format à chaque page coûte cher en
    // mémoire et en raster (jank au démarrage / changement de page). `cacheWidth`
    // borne le bitmap décodé → coût quasi constant quelle que soit la source.
    final media = MediaQuery.of(context);
    final cacheWidth = (media.size.width * media.devicePixelRatio).round();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond uni du thème (fallback systématique).
        Container(color: AppTheme.background),
        // Image de fond (si présente).
        if (path.isNotEmpty)
          Image.asset(
            path,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth > 0 ? cacheWidth : null,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        // Voile dégradé : assombrit l'image pour garder le contenu lisible.
        // Renforcé volontairement (le fond couvre aussi des pages denses :
        // listes Équipe/Scènes, formulaire profil) → un voile trop léger gênait
        // la lecture. Le haut reste un peu plus clair que le bas pour conserver
        // de la profondeur sans noyer le visuel.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.80),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}
