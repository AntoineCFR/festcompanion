import 'package:flutter/material.dart';

class FavoritesToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  final String label;

  const FavoritesToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Favoris uniquement',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF7851A9),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}