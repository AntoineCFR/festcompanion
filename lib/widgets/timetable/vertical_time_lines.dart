import 'package:flutter/material.dart';
import 'timetable_constants.dart';

class VerticalTimeLines extends StatelessWidget {
  final double totalWidth;
  final double offset;

  const VerticalTimeLines({
    super.key,
    required this.totalWidth,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    const interval = TimetableConstants.pixelsPerHour;
    const lineWidth = 0.5;
    final lineCount = (totalWidth / interval).floor();
    final availableWidth = totalWidth - offset;
    final lastLineWidth = availableWidth - (lineCount - 1) * interval;

    return SizedBox(
      width: totalWidth,
      child: Row(
        children: [
          SizedBox(width: offset),
          ...List.generate(
            lineCount,
            (index) => Container(
              width: index == lineCount - 1 ? lastLineWidth : interval,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white24, width: lineWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}