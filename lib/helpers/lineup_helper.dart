import '../models/timetable_item.dart';

class LineupHelper {
  static List<TimetableItem> filterAndSortTimetable({
    required List<TimetableItem> timetable,
    required String selectedDay,
    required bool showFavoritesOnly,
    required List<int> favoriteSetIds,
  }) {
    final filteredByDay = timetable.where((item) => item.day == selectedDay).toList();
    final displayItems = showFavoritesOnly
        ? filteredByDay.where((item) => favoriteSetIds.contains(item.setId)).toList()
        : filteredByDay;

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

    return displayItems;
  }

  static Map<String, List<TimetableItem>> groupByDistrict(List<TimetableItem> items) {
    final Map<String, List<TimetableItem>> grouped = {};
    for (var item in items) {
      grouped.putIfAbsent(item.district, () => []).add(item);
    }
    return grouped;
  }
}