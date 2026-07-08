import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../widgets/shared/festival_background.dart';
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
    setState(() {});
  }

  void _onDayChanged(String? newValue) {
    if (newValue != null) {
      AppDataManager().setSelectedDay(newValue);
      setState(() {});
      _scrollToTop();
    }
  }

  void _onFilterModeChanged(FavoriteFilterMode mode) {
    AppDataManager().setFilterMode(mode);
    setState(() {});
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    final filterMode = AppDataManager().filterMode;
    final selectedDay = AppDataManager().selectedDay;
    final favoriteSetIds = AppDataManager().favoriteSetIds;
    final allFavoriteSetIds = AppDataManager().allUsersFavoriteSetIds;
    final timetable = AppDataManager().timetable;
    final days = AppDataManager().festivalDays;
    final isFiltered = filterMode != FavoriteFilterMode.normal;

    final displayItems = LineupHelper.filterAndSortTimetable(
      timetable: timetable,
      selectedDay: selectedDay,
      showFavoritesOnly: filterMode == FavoriteFilterMode.myFavorites,
      favoriteSetIds: favoriteSetIds.toList(),
      showAllUsersFavorites: filterMode == FavoriteFilterMode.teamFavorites,
      allFavoriteSetIds: allFavoriteSetIds.toList(),
    );

    return FestivalBackground(
      imageKey: 'featured',
      refreshDomains: const [LoadDomain.timetable],
      refreshLabel: 'Mise à jour du line-up…',
      child: Column(
        children: [
          LineupHeader(
            selectedDay: selectedDay,
            days: days,
            filterMode: filterMode,
            onDayChanged: _onDayChanged,
            onFilterModeChanged: _onFilterModeChanged,
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                if (displayItems.isEmpty) const EmptyLineupState(),
                // Mode filtré (mes favoris OU équipe) : liste plate triée par heure
                if (isFiltered)
                  Column(
                    children: displayItems
                        .map((item) => DJListTile(
                              item: item,
                              isFavorite: favoriteSetIds.contains(item.setId),
                              onToggleFavorite: () => _toggleFavorite(item),
                              onTap: () => _onDjTileTap(item),
                            ))
                        .toList(),
                  )
                else
                  // Mode normal : regroupé par scène
                  Column(
                    children: LineupHelper.groupByStage(displayItems)
                        .entries
                        .map((stageEntry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    TimetableItem.stageLabel(
                                      stageEntry.key,
                                      stageEntry.value.first.host,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                ...stageEntry.value.map(
                                  (item) => DJListTile(
                                    item: item,
                                    isFavorite: favoriteSetIds.contains(item.setId),
                                    onToggleFavorite: () => _toggleFavorite(item),
                                    onTap: () => _onDjTileTap(item),
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
