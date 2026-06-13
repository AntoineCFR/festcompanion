import 'package:flutter/material.dart';

/// Encadré coloré affichant un score **moyen** sur 10, avec décimales.
/// Même code couleur que [RatingText] (qui gère les notes entières), mais pensé
/// pour les moyennes (ex. classement Tendances) → 1 à 2 décimales.
class RatingScoreBox extends StatelessWidget {
  final double score; // attendu dans [0, 10]
  final int fractionDigits;

  const RatingScoreBox({
    super.key,
    required this.score,
    this.fractionDigits = 2,
  });

  Color _color() {
    if (score < 0 || score > 10) return Colors.transparent;
    if (score < 2) return Colors.red[700]!;
    if (score < 4) return Colors.orange[700]!;
    if (score < 6) return Colors.yellow[700]!;
    if (score < 8) return Colors.lightGreen[300]!;
    return Colors.green[700]!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color(),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        score.toStringAsFixed(fractionDigits),
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
