import 'package:flutter/material.dart';
import '../../services/app_data_manager.dart';
import '../lineup/day_selector.dart';
import '../lineup/filter_mode_selector.dart';

class TimetableControls extends StatelessWidget {
  final String selectedDay;
  final List<String> days;
  final FavoriteFilterMode filterMode;
  final void Function(String?) onDayChanged;
  final void Function(FavoriteFilterMode) onFilterModeChanged;

  const TimetableControls({
    super.key,
    required this.selectedDay,
    required this.days,
    required this.filterMode,
    required this.onDayChanged,
    required this.onFilterModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          DaySelector(
            selectedDay: selectedDay,
            days: days,
            onChanged: onDayChanged,
          ),
          const Spacer(),
          FilterModeSelector(
            filterMode: filterMode,
            onChanged: onFilterModeChanged,
          ),
        ],
      ),
    );
  }
}
