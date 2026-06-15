import 'package:flutter/material.dart';

class LocationToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LocationToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Activer la localisation',
          style: TextStyle(color: Colors.white),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.blue,
        ),
      ],
    );
  }
}