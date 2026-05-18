import 'package:flutter/material.dart';
import '../../utils/utils.dart';

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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DropdownButton<String>(
        value: selectedDay,
        items: days.map((day) {
          return DropdownMenuItem<String>(
            value: day,
            child: Text(AppUtils.getDayName(day)),
          );
        }).toList(),
        onChanged: onChanged,
        hint: const Text('Choisir un jour'),
      ),
    );
  }
}