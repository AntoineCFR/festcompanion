import 'package:flutter/material.dart';
import 'timetable_controls.dart';

class EmptyTimetableState extends StatelessWidget {
  final List<String> days;
  final String selectedDay;
  final bool showFavoritesOnly;
  final void Function(String?) onDayChanged;
  final void Function(bool) onShowFavoritesOnlyChanged;

  const EmptyTimetableState({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.showFavoritesOnly,
    required this.onDayChanged,
    required this.onShowFavoritesOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimetableControls(
          selectedDay: selectedDay,
          days: days,
          showFavoritesOnly: showFavoritesOnly,
          onDayChanged: onDayChanged,
          onShowFavoritesOnlyChanged: onShowFavoritesOnlyChanged,
        ),
        const Expanded(child: Center(child: Text('Aucun DJ à afficher.'))),
      ],
    );
  }
}