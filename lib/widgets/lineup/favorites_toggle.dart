import 'package:flutter/material.dart';

class FavoritesToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const FavoritesToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Favoris uniquement',
          style: TextStyle(color: Colors.white),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF7851A9),
        ),
      ],
    );
  }
}