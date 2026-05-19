import 'package:flutter/material.dart';

class RatingLegend extends StatelessWidget {
  const RatingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Légende des notes :',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _LegendItem(value: 0, label: 'Veto'),
              _LegendItem(value: 1, label: 'Non'),
              _LegendItem(value: 2, label: 'Faute de mieux...'),
              _LegendItem(value: 3, label: 'Probablement pas fou'),
              _LegendItem(value: 4, label: 'Peut surprendre'),
              _LegendItem(value: 5, label: 'Peut être pas mal'),
              _LegendItem(value: 6, label: 'Plutôt bon'),
              _LegendItem(value: 7, label: 'Bon'),
              _LegendItem(value: 8, label: 'Très bon'),
              _LegendItem(value: 9, label: 'Excellent'),
              _LegendItem(value: 10, label: 'Immanquable'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final int value;
  final String label;

  const _LegendItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value: $label',
      style: const TextStyle(fontSize: 12),
    );
  }
}