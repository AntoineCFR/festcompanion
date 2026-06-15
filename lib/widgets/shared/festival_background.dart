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

  /// Domaines de données dont dépend la page (cf. [LoadDomain]). Si l'un d'eux
  /// est en cours de rafraîchissement en arrière-plan, un bandeau non bloquant
  /// (« mise à jour en cours ») apparaît en haut, par-dessus le contenu — qui
  /// reste affiché et navigable. Vide = aucun bandeau.
  final List<String> refreshDomains;

  /// Libellé du bandeau (ex. « Mise à jour des tendances… »). Requis si
  /// [refreshDomains] est non vide.
  final String? refreshLabel;

  const FestivalBackground({
    super.key,
    required this.imageKey,
    required this.child,
    this.refreshDomains = const [],
    this.refreshLabel,
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
        // Bandeau « mise à jour en cours » (non bloquant), si la page suit des
        // domaines de données rafraîchis en arrière-plan.
        if (refreshDomains.isNotEmpty && refreshLabel != null)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: _RefreshBanner(domains: refreshDomains, label: refreshLabel!),
          ),
      ],
    );
  }
}

/// Pastille flottante non intrusive signalant un rafraîchissement de fond.
/// Observe [AppDataManager.backgroundLoads] et s'affiche/efface seule en fondu ;
/// `IgnorePointer` → ne capture aucun tap (la page reste pleinement navigable).
class _RefreshBanner extends StatelessWidget {
  final List<String> domains;
  final String label;

  const _RefreshBanner({required this.domains, required this.label});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: AppDataManager().backgroundLoads,
        builder: (context, loads, _) {
          final active = domains.any(loads.contains);
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !active
                ? const SizedBox.shrink()
                : Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
