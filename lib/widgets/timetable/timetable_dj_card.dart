import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../models/dj_model.dart';
import '../../widgets/favorite_star.dart';
import '../ratings/rating_text.dart';
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

  const TimetableDjCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DJProfilePage(
                userId: AppDataManager().userId!,
                setId: item.setId,
                dj: DJ(
                  name: item.dj,
                  bio: item.bio ?? '',
                  district: item.district,
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
          color: isFavorite ? const Color(0xFF7851A9) : null,
          child: Padding(
            padding: TimetableConstants.cardPadding,
            child: Row(
              children: [
                if (width >= 60)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: height - 8), // ← Limite la largeur de l'image
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.asset(
                        AppUtils.getDjImagePath(item.dj),
                        width: height - 8,
                        height: height - 8,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Colors.white54, size: 20),
                      ),
                    ),
                  ),
                if (width >= 60) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.dj,
                        style: TimetableConstants.djTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // ← Tronque si trop long
                      ),
                      Text(
                        '${AppUtils.formatTime(item.startTime)} - ${AppUtils.formatTime(item.endTime)}',
                        style: TimetableConstants.timeTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // ← Tronque si trop long
                      ),
                      if (height == TimetableConstants.favoriteTileHeight)
                        Text(
                          item.district,
                          style: TimetableConstants.districtSubtitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // ← Tronque si trop long
                        ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}