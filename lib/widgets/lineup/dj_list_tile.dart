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

  const DJListTile({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap, // ✅ NOUVEAU
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isFavorite ? AppTheme.accent : null,
      child: InkWell(
        onTap: onTap, // ✅ MODIFIÉ : Utilise le callback passé (ou null)
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // 1️⃣ PHOTO (à gauche)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: DjPhoto(djName: item.dj),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 2️⃣ INFOS DJ (au centre)
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
                        Text(
                          '${AppUtils.formatTime(item.startTime)} - ${AppUtils.formatTime(item.endTime)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (AppDataManager().showFavoritesOnly ||
                            AppDataManager().showAllUsersFavorites)
                          Text(
                            item.stage,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 3️⃣ ÉTOILE + NOTE (à droite)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FavoriteStar(
                        isFavorite: isFavorite,
                        onPressed: onToggleFavorite,
                      ),
                      RatingText(
                        rating: AppDataManager().getUserFavorite(item.setId)?.notation,
                      ),
                    ],
                  ),
                ],
              ),
              // 4️⃣ FANS — uniquement en mode "Favoris équipe"
              if (AppDataManager().showAllUsersFavorites)
                Builder(builder: (_) {
                  final fans = AppDataManager().getUsersWhoFavorited(item.setId);
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
      ),
    );
  }
}