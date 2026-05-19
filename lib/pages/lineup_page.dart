import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../widgets/lineup/lineup_header.dart';
import '../widgets/lineup/dj_list_tile.dart';
import '../widgets/lineup/empty_lineup_state.dart';
import '../helpers/lineup_helper.dart';
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

  // ✅ NOUVEAU : Fonction pour gérer le tap sur une tuile DJ
  Future<void> _onDjTileTap(TimetableItem item) async {
    await Navigator.push(
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
    setState(() {}); // ✅ Rafraîchit la page après retour
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

  @override
  Widget build(BuildContext context) {
    final selectedDay = AppDataManager().selectedDay;
    final showFavoritesOnly = AppDataManager().showFavoritesOnly;
    final favoriteSetIds = AppDataManager().favoriteSetIds;
    final timetable = AppDataManager().timetable;

    final displayItems = LineupHelper.filterAndSortTimetable(
      timetable: timetable,
      selectedDay: selectedDay,
      showFavoritesOnly: showFavoritesOnly,
      favoriteSetIds: favoriteSetIds.toList(),
    );

    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          LineupHeader(
            selectedDay: selectedDay,
            days: _days,
            showFavoritesOnly: showFavoritesOnly,
            onDayChanged: _onDayChanged,
            onShowFavoritesOnlyChanged: _onShowFavoritesOnlyChanged,
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                if (displayItems.isEmpty)
                  const EmptyLineupState(),
                showFavoritesOnly
                    ? Column(
                        children: displayItems
                            .map((item) => DJListTile(
                                  item: item,
                                  isFavorite: favoriteSetIds.contains(item.setId),
                                  onToggleFavorite: () => _toggleFavorite(item),
                                  onTap: () => _onDjTileTap(item), // ✅ NOUVEAU
                                ))
                            .toList(),
                      )
                    : Column(
                        children: LineupHelper.groupByDistrict(displayItems)
                            .entries
                            .map((districtEntry) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        districtEntry.key,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    ...districtEntry.value.map(
                                      (item) => DJListTile(
                                        item: item,
                                        isFavorite: favoriteSetIds.contains(item.setId),
                                        onToggleFavorite: () => _toggleFavorite(item),
                                        onTap: () => _onDjTileTap(item), // ✅ NOUVEAU
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}