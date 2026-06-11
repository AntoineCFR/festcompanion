import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../models/dj_model.dart';
import '../../models/user_model.dart';
import '../../widgets/favorite_star.dart';
import '../ratings/rating_text.dart';
import '../shared/fan_avatars_row.dart';
import '../shared/dj_photo.dart';
import '../../utils/utils.dart';
import '../../pages/djprofilepage.dart';
import '../../services/app_data_manager.dart';
import 'timetable_constants.dart';

class TimetableDjCard extends StatelessWidget {
  final TimetableItem item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final double width;
  final double height;
  final VoidCallback? onTap;

  /// Affiche le nom de la scène sous le nom du DJ (utile en vue "favoris"
  /// où les sets de scènes différentes sont mélangés sur la même ligne).
  final bool showStage;

  const TimetableDjCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.width,
    required this.height,
    this.onTap,
    this.showStage = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<User> fans = AppDataManager().showAllUsersFavorites && width >= 80
        ? AppDataManager().getUsersWhoFavorited(item.setId)
        : const [];

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DJProfilePage(
                userId: AppDataManager().userId!,
                setId: item.setId,
                dj: DJ(
                  name: item.dj,
                  bio: item.bio ?? '',
                  stage: item.stage,
                  startTime: item.startTime,
                  endTime: item.endTime,
                  spotifyLink: item.spotifyLink,
                  soundcloudLink: item.soundcloudLink,
                  instagramLink: item.instagramLink,
                ),
              ),
            ),
          );
        },
        child: Card(
          margin: TimetableConstants.cardMargin,
          color: isFavorite ? AppTheme.accent : null,
          child: Padding(
            padding: TimetableConstants.cardPadding,
            child: Row(
              // La photo et la colonne droite s'étirent sur toute la hauteur.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Photo DJ : largeur fixe, pleine hauteur ───────────────────
                if (width >= 60)
                  SizedBox(
                    width: TimetableConstants.photoWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: DjPhoto(djName: item.dj),
                    ),
                  ),
                if (width >= 60) const SizedBox(width: 8),

                // ── Colonne droite : [infos + étoile] en haut, fans en bas ────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Partie haute : nom/heure/district à gauche, ⭐/note à droite
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Infos textuelles
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.dj,
                                    style: TimetableConstants.djTextStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${AppUtils.formatTime(item.startTime)} - ${AppUtils.formatTime(item.endTime)}',
                                    style: TimetableConstants.timeTextStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (showStage)
                                    Text(
                                      item.stage,
                                      style: TimetableConstants.stageSubtitleStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            // Étoile + note
                            Column(
                              mainAxisSize: MainAxisSize.min,
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
                      ),

                      // Partie basse : fans (uniquement en mode équipe)
                      if (fans.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        FanAvatarsRow(fans: fans, radius: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
