import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import 'timetable_district_row.dart';

class TimetableDistrictView extends StatelessWidget {
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final void Function(TimetableItem) onToggleFavorite;
  final void Function(TimetableItem)? onTap; // ✅ NOUVEAU

  const TimetableDistrictView({
    super.key,
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.onToggleFavorite,
    this.onTap, // ✅ NOUVEAU
  });

  Map<String, List<TimetableItem>> _groupItemsByDistrict(List<TimetableItem> items) {
    final Map<String, List<TimetableItem>> grouped = {};
    for (var item in items) {
      grouped.putIfAbsent(item.district, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByDistrict(items);
    return Column(
      children: groupedItems.entries.map((entry) {
        return TimetableDistrictRow(
          district: entry.key,
          items: entry.value,
          totalWidth: totalWidth,
          minStartTime: minStartTime,
          onToggleFavorite: onToggleFavorite,
          onTap: onTap, // ✅ NOUVEAU : Passe le callback
        );
      }).toList(),
    );
  }
}