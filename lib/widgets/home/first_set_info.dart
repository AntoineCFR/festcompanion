import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class FirstSetInfo extends StatelessWidget {
  final DateTime firstSetTime;

  const FirstSetInfo({
    super.key,
    required this.firstSetTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Premier set',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${AppUtils.formatFullDate(firstSetTime)} - ${AppUtils.formatTime(firstSetTime)}',
            style: const TextStyle(fontSize: 16, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}