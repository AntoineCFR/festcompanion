import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../widgets/shared/festival_background.dart';
import '../widgets/timetable/timetable_controls.dart';
import '../widgets/timetable/empty_timetable_state.dart';
import '../widgets/timetable/time_scale.dart';
import '../widgets/timetable/vertical_time_lines.dart';
import '../widgets/timetable/timetable_stage_view.dart';
import '../widgets/timetable/timetable_favorites_view.dart';
import '../helpers/timetable_helper.dart';
import 'djprofilepage.dart';

class TimetablePage extends StatefulWidget {
  final String username;
  final int userId;

  const TimetablePage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
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

  Future<void> _onDjCardTap(TimetableItem item) async {
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
    final timetable = AppDataManager().timetable;
    TimetableHelper.updateFavoriteStatus(timetable);

    final filterMode = AppDataManager().filterMode;
    final selectedDay = AppDataManager().selectedDay;
    final days = AppDataManager().festivalDays;
    final isFiltered = filterMode != FavoriteFilterMode.normal;

    final displayItems = TimetableHelper.filterAndSortTimetable(
      timetable: timetable,
      selectedDay: selectedDay,
      showFavoritesOnly: filterMode == FavoriteFilterMode.myFavorites,
      favoriteSetIds: AppDataManager().favoriteSetIds.toList(),
      showAllUsersFavorites: filterMode == FavoriteFilterMode.teamFavorites,
      allFavoriteSetIds: AppDataManager().allUsersFavoriteSetIds.toList(),
    );

    if (displayItems.isEmpty) {
      return FestivalBackground(
        imageKey: 'featured',
        child: EmptyTimetableState(
          days: days,
          selectedDay: selectedDay,
          filterMode: filterMode,
          onDayChanged: _onDayChanged,
          onFilterModeChanged: _onFilterModeChanged,
        ),
      );
    }

    final minStartTime = TimetableHelper.getMinStartTime(displayItems);
    final maxEndTime = TimetableHelper.getMaxEndTime(displayItems);
    final totalWidth = maxEndTime.difference(minStartTime).inMinutes * 3.0;
    final offsetInPixels = TimetableHelper.calculateOffset(minStartTime);

    return FestivalBackground(
      imageKey: 'featured',
      child: Column(
        children: [
          TimetableControls(
            selectedDay: selectedDay,
            days: days,
            filterMode: filterMode,
            onDayChanged: _onDayChanged,
            onFilterModeChanged: _onFilterModeChanged,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: VerticalTimeLines(
                          totalWidth: totalWidth,
                          offset: offsetInPixels,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TimeScale(
                            minStartTime: minStartTime,
                            maxEndTime: maxEndTime,
                            offset: offsetInPixels,
                          ),
                          const SizedBox(height: 10),
                          // Mode filtré (mes favoris OU équipe) → vue plate,
                          // scène affichée sur la tuile.
                          // Mode normal → vue par scène (lignes séparées).
                          isFiltered
                              ? TimetableFavoritesView(
                                  items: displayItems,
                                  totalWidth: totalWidth,
                                  minStartTime: minStartTime,
                                  onToggleFavorite: _toggleFavorite,
                                  onTap: _onDjCardTap,
                                )
                              : TimetableStageView(
                                  items: displayItems,
                                  totalWidth: totalWidth,
                                  minStartTime: minStartTime,
                                  onToggleFavorite: _toggleFavorite,
                                  onTap: _onDjCardTap,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
