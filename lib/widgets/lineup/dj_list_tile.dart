import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../widgets/favorite_star.dart';
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
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DJProfilePage(
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
        leading: AspectRatio(
          aspectRatio: 1,
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
        title: Text(
          item.dj,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        trailing: FavoriteStar(
          isFavorite: isFavorite,
          onPressed: onToggleFavorite,
        ),
      ),
    );
  }
}