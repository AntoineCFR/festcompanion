import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../services/app_data_manager.dart';
import 'timetable_dj_card.dart';
import 'timetable_constants.dart';

class TimetableFavoritesView extends StatelessWidget {
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final void Function(TimetableItem) onToggleFavorite;
  final void Function(TimetableItem)? onTap; // ✅ NOUVEAU

  const TimetableFavoritesView({
    super.key,
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.onToggleFavorite,
    this.onTap, // ✅ NOUVEAU
  });

  List<List<TimetableItem>> _assignToLines(List<TimetableItem> items) {
    List<List<TimetableItem>> lines = [];
    for (var item in items) {
      bool placed = false;
      for (var line in lines) {
        bool overlap = line.any((existingItem) => _hasOverlap(item, existingItem));
        if (!overlap) {
          line.add(item);
          placed = true;
          break;
        }
      }
      if (!placed) {
        lines.add([item]);
      }
    }
    return lines;
  }

  bool _hasOverlap(TimetableItem a, TimetableItem b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  @override
  Widget build(BuildContext context) {
    final showFans = AppDataManager().showAllUsersFavorites;
    final tileH = showFans
        ? TimetableConstants.favoriteTileHeight + TimetableConstants.fanRowHeight
        : TimetableConstants.favoriteTileHeight;

    final lines = _assignToLines(items);
    return Column(
      children: lines.map((line) {
        return SizedBox(
          height: tileH,
          width: totalWidth,
          child: Stack(
            children: line.map((item) {
              final startMinutes = item.startTime.difference(minStartTime).inMinutes;
              final left = startMinutes * TimetableConstants.pixelsPerMinute;
              final endMinutes = item.endTime.difference(minStartTime).inMinutes;
              final width = (endMinutes - startMinutes) * TimetableConstants.pixelsPerMinute;

              return Positioned(
                left: left,
                child: TimetableDjCard(
                  item: item,
                  isFavorite: AppDataManager().favoriteSetIds.contains(item.setId),
                  onToggleFavorite: () => onToggleFavorite(item),
                  width: width,
                  height: tileH,
                  showDistrict: true,
                  onTap: () => onTap?.call(item),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}