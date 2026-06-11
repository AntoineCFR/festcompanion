import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';

class RatingNumbers extends StatefulWidget {
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
  State<RatingNumbers> createState() => _RatingNumbersState();
}

class _RatingNumbersState extends State<RatingNumbers> {
  int? _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  // ✅ Met à jour si le parent change la note (ex: depuis une autre page)
  @override
  void didUpdateWidget(RatingNumbers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      setState(() => _currentRating = widget.rating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(widget.maxRating + 1, (index) {
        final value = index;
        final isSelected = value == _currentRating;

        return GestureDetector(
          onTap: () {
            final newRating = value == _currentRating ? null : value;
            setState(() => _currentRating = newRating); // ✅ Met à jour l'UI IMMEDIATEMENT
            widget.onRatingChanged(newRating); // Sync avec le parent
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber : AppTheme.surface,
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