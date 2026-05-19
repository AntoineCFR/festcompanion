import 'package:flutter/material.dart';

class FavoriteStar extends StatefulWidget {
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
  State<FavoriteStar> createState() => _FavoriteStarState();
}

class _FavoriteStarState extends State<FavoriteStar> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  // ✅ Met à jour si le parent change l'état (ex: depuis une autre page)
  @override
  void didUpdateWidget(FavoriteStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _isFavorite = widget.isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isFavorite = !_isFavorite); // ✅ Met à jour l'UI IMMEDIATEMENT
        widget.onPressed(); // Sync avec le parent
      },
      child: Icon(
        _isFavorite ? Icons.star : Icons.star_border,
        color: _isFavorite ? Colors.amber : Colors.grey,
        size: widget.size,
      ),
    );
  }
}