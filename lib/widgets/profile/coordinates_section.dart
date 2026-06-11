import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'profile_text_field.dart';

class CoordinatesSection extends StatelessWidget {
  final double? latitude;
  final double? longitude;

  const CoordinatesSection({
    super.key,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ProfileTextField(
            labelText: 'Latitude',
            labelStyle: const TextStyle(color: Colors.white70),
            fillColor: AppTheme.surface,
            controller: TextEditingController(
              text: latitude?.toStringAsFixed(6) ?? '',
            ),
            enabled: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ProfileTextField(
            labelText: 'Longitude',
            labelStyle: const TextStyle(color: Colors.white70),
            fillColor: AppTheme.surface,
            controller: TextEditingController(
              text: longitude?.toStringAsFixed(6) ?? '',
            ),
            enabled: false,
          ),
        ),
      ],
    );
  }
}