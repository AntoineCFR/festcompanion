import 'package:flutter/material.dart';

class RatingNumbers extends StatelessWidget {
  final int? rating;
  final ValueChanged<int?> onRatingChanged;
  final int maxRating;

  const RatingNumbers({
    super.key,
    this.rating,
    required this.onRatingChanged,
    this.maxRating = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(maxRating + 1, (index) {
        final value = index;
        final isSelected = value == rating;

        return GestureDetector(
          onTap: () {
            final newRating = value == rating ? null : value;
            onRatingChanged(newRating);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber : Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.grey.shade800,
                width: 1.5,
              ),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    );
  }
}