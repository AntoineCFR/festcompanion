import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/app_data_manager.dart';
import '../widgets/timetable/timetable_controls.dart';
import '../widgets/timetable/empty_timetable_state.dart';
import '../widgets/timetable/time_scale.dart';
import '../widgets/timetable/vertical_time_lines.dart';
import '../widgets/timetable/timetable_district_view.dart';
import '../widgets/timetable/timetable_favorites_view.dart';
import '../helpers/timetable_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    final timetable = AppDataManager().timetable;
    TimetableHelper.updateFavoriteStatus(timetable);

    final selectedDay = AppDataManager().selectedDay;
    final showFavoritesOnly = AppDataManager().showFavoritesOnly;
    final displayItems = TimetableHelper.filterAndSortTimetable(
      timetable: timetable,
      selectedDay: selectedDay,
      showFavoritesOnly: showFavoritesOnly,
      favoriteSetIds: AppDataManager().favoriteSetIds.toList(),
    );

    if (displayItems.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: EmptyTimetableState(
          days: _days,
          selectedDay: selectedDay,
          showFavoritesOnly: showFavoritesOnly,
          onDayChanged: _onDayChanged,
          onShowFavoritesOnlyChanged: _onShowFavoritesOnlyChanged,
        ),
      );
    }

    final minStartTime = TimetableHelper.getMinStartTime(displayItems);
    final maxEndTime = TimetableHelper.getMaxEndTime(displayItems);
    final totalWidth = maxEndTime.difference(minStartTime).inMinutes * 3.0; // pixelsPerMinute
    final offsetInPixels = TimetableHelper.calculateOffset(minStartTime);

    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          TimetableControls(
            selectedDay: selectedDay,
            days: _days,
            showFavoritesOnly: showFavoritesOnly,
            onDayChanged: _onDayChanged,
            onShowFavoritesOnlyChanged: _onShowFavoritesOnlyChanged,
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
                        top: 40, // timeScaleHeight
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
                          showFavoritesOnly
                              ? TimetableFavoritesView(
                                  items: displayItems,
                                  totalWidth: totalWidth,
                                  minStartTime: minStartTime,
                                  onToggleFavorite: _toggleFavorite,
                                )
                              : TimetableDistrictView(
                                  items: displayItems,
                                  totalWidth: totalWidth,
                                  minStartTime: minStartTime,
                                  onToggleFavorite: _toggleFavorite,
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