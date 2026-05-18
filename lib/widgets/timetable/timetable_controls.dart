import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class TimetableControls extends StatelessWidget {
  final String selectedDay;
  final List<String> days;
  final bool showFavoritesOnly;
  final void Function(String?) onDayChanged;
  final void Function(bool) onShowFavoritesOnlyChanged;

  const TimetableControls({
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
          Expanded(
            child: DropdownButton<String>(
              value: selectedDay,
              items: days.map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(AppUtils.getDayName(day)),
                );
              }).toList(),
              onChanged: onDayChanged,
              hint: const Text('Choisir un jour'),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              const Text('Favoris uniquement', style: TextStyle(color: Colors.white)),
              Switch(
                value: showFavoritesOnly,
                onChanged: onShowFavoritesOnlyChanged,
                activeThumbColor: const Color(0xFF7851A9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}