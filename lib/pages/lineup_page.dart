// lib/pages/lineup_page.dart
import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/app_data_manager.dart';
import '../widgets/favorite_star.dart';
import '../utils/utils.dart';
import 'djprofilepage.dart';

class LineupPage extends StatefulWidget {
  final String username;
  final int userId;

  const LineupPage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<LineupPage> createState() => _LineupPageState();
}

class _LineupPageState extends State<LineupPage> {
  final List<String> _days = const ['friday', 'saturday', 'sunday'];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _toggleFavorite(TimetableItem item) {
    AppDataManager().toggleFavorite(item.setId);
    setState(() => item.isFavorite = AppDataManager().favoriteSetIds.contains(item.setId));
  }

  void _onDayChanged(String? newValue) {
    if (newValue != null) {
      AppDataManager().setSelectedDay(newValue);
      setState(() {});
      _scrollToTop();
    }
  }

  void _onShowFavoritesOnlyChanged(bool value) {
    AppDataManager().setShowFavoritesOnly(value);
    setState(() {});
    _scrollToTop();
  }

  Widget _buildDjTile(TimetableItem item, BuildContext context) {
    final favoriteSetIds = AppDataManager().favoriteSetIds;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: favoriteSetIds.contains(item.setId) ? const Color(0xFF7851A9) : null,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DJProfilePage(
                djData: {
                  'name': item.dj,
                  'bio': item.bio,
                  'district': item.district,
                  'startTime': item.startTime,
                  'endTime': item.endTime,
                  'spotify_link': item.spotifyLink,
                  'soundcloud_link': item.soundcloudLink,
                  'instagram_link': item.instagramLink,
                  'image_link': AppUtils.getDjImagePath(item.dj),
                },
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
          isFavorite: favoriteSetIds.contains(item.setId),
          onPressed: () => _toggleFavorite(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = AppDataManager().selectedDay;
    final favoriteSetIds = AppDataManager().favoriteSetIds;
    final showFavoritesOnly = AppDataManager().showFavoritesOnly;
    final timetable = AppDataManager().timetable;

    final filteredTimetable = timetable.where((item) => item.day == selectedDay).toList();
    final displayItems = showFavoritesOnly
        ? filteredTimetable.where((item) => favoriteSetIds.contains(item.setId)).toList()
        : filteredTimetable;

    displayItems.sort((a, b) {
      if (showFavoritesOnly) {
        int startCompare = a.startTime.compareTo(b.startTime);
        if (startCompare != 0) return startCompare;
        int endCompare = a.endTime.compareTo(b.endTime);
        if (endCompare != 0) return endCompare;
        return a.district.compareTo(b.district);
      } else {
        int districtCompare = a.district.compareTo(b.district);
        if (districtCompare != 0) return districtCompare;
        return a.startTime.compareTo(b.startTime);
      }
    });

    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedDay,
                    items: _days.map((day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(AppUtils.getDayName(day)),
                      );
                    }).toList(),
                    onChanged: _onDayChanged,
                    hint: const Text('Choisir un jour'),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text(
                      'Favoris uniquement',
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: showFavoritesOnly,
                      onChanged: _onShowFavoritesOnlyChanged,
                      activeThumbColor: const Color(0xFF7851A9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                if (displayItems.isEmpty)
                  const Center(child: Text('Aucun DJ à afficher.')),
                showFavoritesOnly
                    ? Column(
                        children: displayItems.map((item) => _buildDjTile(item, context)).toList(),
                      )
                    : Column(
                        children: [
                          for (var districtEntry in {
                            for (var item in displayItems)
                              item.district: displayItems.where((i) => i.district == item.district).toList()
                          }.entries)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    districtEntry.key,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                ...districtEntry.value.map((item) => _buildDjTile(item, context)),
                              ],
                            ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}