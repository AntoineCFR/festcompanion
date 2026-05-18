import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../services/app_data_manager.dart';
import 'timetable_dj_card.dart';
import 'timetable_constants.dart';

class TimetableDistrictRow extends StatelessWidget {
  final String district;
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final void Function(TimetableItem) onToggleFavorite;

  const TimetableDistrictRow({
    super.key,
    required this.district,
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TimetableConstants.districtSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(district, style: TimetableConstants.districtTextStyle),
        ),
        const SizedBox(height: TimetableConstants.districtSpacing),
        SizedBox(
          height: TimetableConstants.normalTileHeight,
          width: totalWidth,
          child: Stack(
            children: items.map((item) {
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
                  height: TimetableConstants.normalTileHeight,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}