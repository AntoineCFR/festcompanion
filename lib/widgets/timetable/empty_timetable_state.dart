import 'package:flutter/material.dart';
import '../../services/app_data_manager.dart';
import 'timetable_controls.dart';

class EmptyTimetableState extends StatelessWidget {
  final List<String> days;
  final String selectedDay;
  final FavoriteFilterMode filterMode;
  final void Function(String?) onDayChanged;
  final void Function(FavoriteFilterMode) onFilterModeChanged;

  const EmptyTimetableState({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.filterMode,
    required this.onDayChanged,
    required this.onFilterModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimetableControls(
          selectedDay: selectedDay,
          days: days,
          filterMode: filterMode,
          onDayChanged: onDayChanged,
          onFilterModeChanged: onFilterModeChanged,
        ),
        const Expanded(child: Center(child: Text('Aucun DJ à afficher.'))),
      ],
    );
  }
}
