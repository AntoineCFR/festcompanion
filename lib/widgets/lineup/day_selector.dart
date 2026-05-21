import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final String selectedDay;
  final List<String> days;
  final void Function(String?) onChanged;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.days,
    required this.onChanged,
  });

  String _shortName(String day) {
    switch (day) {
      case 'friday':
        return 'Ven.';
      case 'saturday':
        return 'Sam.';
      case 'sunday':
        return 'Dim.';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: days.map((d) => d == selectedDay).toList(),
      onPressed: (i) => onChanged(days[i]),
      constraints: const BoxConstraints(minHeight: 34, minWidth: 52),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white54,
      selectedColor: Colors.white,
      fillColor: const Color(0xFF7851A9),
      borderColor: Colors.white24,
      selectedBorderColor: const Color(0xFF7851A9),
      children: days
          .map((day) => Text(_shortName(day),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))
          .toList(),
    );
  }
}
