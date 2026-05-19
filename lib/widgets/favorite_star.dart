import 'package:flutter/material.dart';

class FavoriteStar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;
  final double size;

  const FavoriteStar({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // ← Remplace IconButton
      onTap: onPressed,
      child: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : Colors.grey,
        size: size,
      ),
    );
  }
}