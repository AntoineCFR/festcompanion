import 'package:flutter/material.dart';

class RatingText extends StatelessWidget {
  final int? rating;

  const RatingText({
    super.key,
    this.rating,
  });

  // Détermine la couleur en fonction de la note
  Color _getColor() {
    if (rating == null || rating! < 0 || rating! > 10) {
      return Colors.transparent;
    }
    if (rating! < 2) return Colors.red[700]!;
    if (rating! < 4) return Colors.orange[700]!;
    if (rating! < 6) return Colors.yellow[700]!;
    if (rating! < 8) return Colors.lightGreen[300]!;
    return Colors.green[700]!;
  }

  @override
  Widget build(BuildContext context) {
    final bool isTransparent = _getColor() == Colors.transparent;
    return Container(
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        rating != null ? '$rating/10' : '-',
        style: TextStyle(
          fontSize: 12,
          color: isTransparent ? Colors.grey : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}