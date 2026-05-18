import 'package:flutter/material.dart';
import 'day_selector.dart';
import 'favorites_toggle.dart';

class LineupHeader extends StatelessWidget {
  final String selectedDay;
  final List<String> days;
  final bool showFavoritesOnly;
  final void Function(String?) onDayChanged;
  final void Function(bool) onShowFavoritesOnlyChanged;

  const LineupHeader({
    super.key,
    required this.selectedDay,
    required this.days,
    required this.showFavoritesOnly,
    required this.onDayChanged,
    required this.onShowFavoritesOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          DaySelector(
            selectedDay: selectedDay,
            days: days,
            onChanged: onDayChanged,
          ),
          const SizedBox(width: 16),
          FavoritesToggle(
            value: showFavoritesOnly,
            onChanged: onShowFavoritesOnlyChanged,
          ),
        ],
      ),
    );
  }
}