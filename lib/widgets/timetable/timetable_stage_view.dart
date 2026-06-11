import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import 'timetable_stage_row.dart';

class TimetableStageView extends StatelessWidget {
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final void Function(TimetableItem) onToggleFavorite;
  final void Function(TimetableItem)? onTap;

  const TimetableStageView({
    super.key,
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.onToggleFavorite,
    this.onTap,
  });

  Map<String, List<TimetableItem>> _groupItemsByStage(List<TimetableItem> items) {
    final Map<String, List<TimetableItem>> grouped = {};
    for (var item in items) {
      grouped.putIfAbsent(item.stage, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByStage(items);
    return Column(
      children: groupedItems.entries.map((entry) {
        return TimetableStageRow(
          stage: entry.key,
          items: entry.value,
          totalWidth: totalWidth,
          minStartTime: minStartTime,
          onToggleFavorite: onToggleFavorite,
          onTap: onTap,
        );
      }).toList(),
    );
  }
}
