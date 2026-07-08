import '../models/timetable_item.dart';
import '../services/app_data_manager.dart';

class LineupHelper {
  static List<TimetableItem> filterAndSortTimetable({
    required List<TimetableItem> timetable,
    required String selectedDay,
    required bool showFavoritesOnly,
    required List<int> favoriteSetIds,
    bool showAllUsersFavorites = false,
    List<int> allFavoriteSetIds = const [],
  }) {
    final explicitOrder = AppDataManager().explicitStageOrder;
    final filteredByDay = timetable.where((item) => item.day == selectedDay).toList();

    final List<TimetableItem> displayItems;
    if (showFavoritesOnly && showAllUsersFavorites) {
      // Union : mes favoris OU favoris d'un autre utilisateur
      displayItems = filteredByDay
          .where((item) =>
              favoriteSetIds.contains(item.setId) ||
              allFavoriteSetIds.contains(item.setId))
          .toList();
    } else if (showFavoritesOnly) {
      displayItems = filteredByDay
          .where((item) => favoriteSetIds.contains(item.setId))
          .toList();
    } else if (showAllUsersFavorites) {
      displayItems = filteredByDay
          .where((item) => allFavoriteSetIds.contains(item.setId))
          .toList();
    } else {
      displayItems = filteredByDay;
    }

    final isFiltered = showFavoritesOnly || showAllUsersFavorites;
    displayItems.sort((a, b) {
      if (isFiltered) {
        int startCompare = a.startTime.compareTo(b.startTime);
        if (startCompare != 0) return startCompare;
        int endCompare = a.endTime.compareTo(b.endTime);
        if (endCompare != 0) return endCompare;
        return TimetableItem.compareByStage(a, b, explicitOrder: explicitOrder);
      } else {
        int stageCompare =
            TimetableItem.compareByStage(a, b, explicitOrder: explicitOrder);
        if (stageCompare != 0) return stageCompare;
        return a.startTime.compareTo(b.startTime);
      }
    });

    return displayItems;
  }

  static Map<String, List<TimetableItem>> groupByStage(List<TimetableItem> items) {
    final Map<String, List<TimetableItem>> grouped = {};
    for (var item in items) {
      grouped.putIfAbsent(item.stage, () => []).add(item);
    }
    return grouped;
  }
}