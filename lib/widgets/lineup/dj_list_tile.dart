import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../widgets/favorite_star.dart';
import '../ratings/rating_text.dart';
import '../../utils/utils.dart';
import '../../pages/djprofilepage.dart';
import '../../models/dj_model.dart';
import '../../services/app_data_manager.dart';

class DJListTile extends StatelessWidget {
  final TimetableItem item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const DJListTile({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isFavorite ? const Color(0xFF7851A9) : null,
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 1️⃣ PHOTO (à gauche) - CORRIGÉ
              SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Image.asset(
                    AppUtils.getDjImagePath(item.dj),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.white54),
                  ),
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
                    if (AppDataManager().showFavoritesOnly)
                      Text(
                        item.district,
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
        ),
      ),
    );
  }
}