import 'package:flutter/material.dart';

class FavoriteStar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const FavoriteStar({
    super.key,
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : Colors.grey,
      ),
      onPressed: onPressed,
    );
  }
}