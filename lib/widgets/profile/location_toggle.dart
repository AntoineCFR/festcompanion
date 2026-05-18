import 'package:flutter/material.dart';

class LocationToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Future<void> Function() onLocationRefresh;

  const LocationToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onLocationRefresh,
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
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: onLocationRefresh,
        ),
      ],
    );
  }
}