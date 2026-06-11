import 'package:flutter/material.dart';
import '../../services/app_data_manager.dart';

class EventHeader extends StatelessWidget {
  const EventHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AppDataManager().selectedFestival?.name ?? 'FestCompanion';
    return Column(
      children: [
        const SizedBox(height: 100),
        Text(
          name,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
