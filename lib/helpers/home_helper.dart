import '../models/timetable_item.dart';
import '../services/app_data_manager.dart';

class HomeHelper {
  static TimetableItem? getFirstSetItem() {
    final timetable = AppDataManager().timetable;
    if (timetable.isEmpty) return null;
    return timetable.reduce((a, b) => a.startTime.isBefore(b.startTime) ? a : b);
  }

  static Duration calculateTimeDifference(DateTime firstSetTime) {
    final now = DateTime.now();
    return firstSetTime.difference(now);
  }
}