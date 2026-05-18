import 'package:flutter/material.dart';
import 'time_unit.dart';

class CountdownTimer extends StatelessWidget {
  final Duration difference;

  const CountdownTimer({
    super.key,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TimeUnit(label: 'Jours', value: days),
        const Text(
          ' : ',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        TimeUnit(label: 'Heures', value: hours),
        const Text(
          ' : ',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        TimeUnit(label: 'Minutes', value: minutes),
        const Text(
          ' : ',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        TimeUnit(label: 'Secondes', value: seconds),
      ],
    );
  }
}