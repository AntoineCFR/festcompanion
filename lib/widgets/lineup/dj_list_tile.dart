import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../widgets/favorite_star.dart';
import '../ratings/rating_text.dart';
import '../shared/fan_avatars_row.dart';
import '../shared/dj_photo.dart';
import '../../utils/utils.dart';
import '../../services/app_data_manager.dart';

class DJListTile extends StatelessWidget {
  final TimetableItem item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap; // ✅ NOUVEAU

  /// Contenu optionnel ajouté sous la ligne principale (ex. ligne de tags dans
  /// la vue « DJ par tag »). Non fourni ailleurs → aucune incidence.
  final Widget? footer;

  /// Affiche l'horaire du set sous le nom. Désactivé dans la vue « DJ par tag »
  /// où l'horaire n'apporte rien et alourdit la tuile.
  final bool showTime;

  const DJListTile({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap, // ✅ NOUVEAU
    this.footer,
    this.showTime = true,
  });

  // Largeur de la photo et écart photo↔texte. La photo est posée en Positioned
  // (pleine hauteur), donc le contenu doit être décalé de `_photoWidth + _gap`.
  static const double _photoWidth = 58;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isFavorite ? AppTheme.accent : null,
      // La Card découpe la photo flush à son bord arrondi (look « Tendances »).
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap, // ✅ Utilise le callback passé (ou null)
        // C'est le CONTENU (texte, ligne de fans…) qui fixe la hauteur de la
        // tuile ; la photo est posée en Positioned (top/bottom = 0) → elle
        // REMPLIT cette hauteur sans jamais la déterminer.
        child: Stack(
          children: [
            // 1️⃣ CONTENU — décalé à droite de la photo ; dimensionne la tuile.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  _photoWidth + _gap, 8.0, 12.0, 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Infos DJ (au centre)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.dj,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (showTime)
                              Text(
                                '${AppUtils.formatTime(item.startTime)} - ${AppUtils.formatTime(item.endTime)}',
                                // Sur une tuile favorite (fond accentué), le gris
                                // est peu lisible → on remonte le contraste.
                                style: TextStyle(
                                  color: isFavorite
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            if (AppDataManager().showFavoritesOnly ||
                                AppDataManager().showAllUsersFavorites)
                              Text(
                                item.stage,
                                style: TextStyle(
                                  color: isFavorite
                                      ? Colors.white70
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            // Contenu additionnel optionnel (ex. ligne de tags) :
                            // SOUS le nom, DANS la colonne d'infos → il partage la
                            // hauteur avec la colonne étoile/note au lieu de
                            // s'empiler dessous (tuile plus compacte).
                            ?footer,
                          ],
                        ),
                      ),
                      // Étoile + note (à droite)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FavoriteStar(
                            isFavorite: isFavorite,
                            onPressed: onToggleFavorite,
                          ),
                          RatingText(
                            rating: AppDataManager()
                                .getUserFavorite(item.setId)
                                ?.notation,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Fans — uniquement en mode "Favoris équipe"
                  if (AppDataManager().showAllUsersFavorites)
                    Builder(builder: (_) {
                      final fans =
                          AppDataManager().getUsersWhoFavorited(item.setId);
                      if (fans.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FanAvatarsRow(fans: fans),
                        ),
                      );
                    }),
                ],
              ),
            ),
            // 2️⃣ PHOTO — flush à gauche, remplit toute la hauteur de la tuile.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _photoWidth,
              child: DjPhoto(djName: item.dj),
            ),
          ],
        ),
      ),
    );
  }
}