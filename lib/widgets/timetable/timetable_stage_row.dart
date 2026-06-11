import 'package:flutter/material.dart';
import '../../models/timetable_item.dart';
import '../../services/app_data_manager.dart';
import 'timetable_dj_card.dart';
import 'timetable_constants.dart';

class TimetableStageRow extends StatelessWidget {
  final String stage;
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final void Function(TimetableItem) onToggleFavorite;
  final void Function(TimetableItem)? onTap;

  const TimetableStageRow({
    super.key,
    required this.stage,
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.onToggleFavorite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showFans = AppDataManager().showAllUsersFavorites;
    final tileH = showFans
        ? TimetableConstants.normalTileHeight + TimetableConstants.fanRowHeight
        : TimetableConstants.normalTileHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TimetableConstants.stageSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(stage, style: TimetableConstants.stageTextStyle),
        ),
        const SizedBox(height: TimetableConstants.stageSpacing),
        SizedBox(
          height: tileH,
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
                  height: tileH,
                  onTap: () => onTap?.call(item),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
