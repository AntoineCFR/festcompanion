import '../models/timetable_item.dart';
import '../services/app_data_manager.dart';

class TimetableHelper {
  static List<TimetableItem> filterAndSortTimetable({
    required List<TimetableItem> timetable,
    required String selectedDay,
    required bool showFavoritesOnly,
    required List<int> favoriteSetIds,
    bool showAllUsersFavorites = false,
    List<int> allFavoriteSetIds = const [],
  }) {
    final filteredByDay = timetable.where((item) => item.day == selectedDay).toList();

    final List<TimetableItem> displayItems;
    if (showFavoritesOnly && showAllUsersFavorites) {
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
        return a.district.compareTo(b.district);
      } else {
        int districtCompare = a.district.compareTo(b.district);
        if (districtCompare != 0) return districtCompare;
        return a.startTime.compareTo(b.startTime);
      }
    });

    return displayItems;
  }

  static DateTime getMinStartTime(List<TimetableItem> items) {
    return items.map((item) => item.startTime).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  static DateTime getMaxEndTime(List<TimetableItem> items) {
    return items.map((item) => item.endTime).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static DateTime nextFullHour(DateTime date) {
    return date.minute == 0 ? date : DateTime(date.year, date.month, date.day, date.hour + 1);
  }

  static double calculateOffset(DateTime minStartTime) {
    final nextHour = TimetableHelper.nextFullHour(minStartTime);
    return nextHour.difference(minStartTime).inMinutes * 3.0;
  }

  static void updateFavoriteStatus(List<TimetableItem> timetable) {
    final favoriteSetIds = AppDataManager().favoriteSetIds;
    for (var item in timetable) {
      item.isFavorite = favoriteSetIds.contains(item.setId);
    }
  }
}