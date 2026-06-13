import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'timetable_constants.dart';

class TimeScale extends StatelessWidget {
  final DateTime minStartTime;
  final DateTime maxEndTime;
  final double offset;

  const TimeScale({
    super.key,
    required this.minStartTime,
    required this.maxEndTime,
    required this.offset,
  });

  DateTime _nextFullHour(DateTime date) {
    return date.minute == 0 ? date : DateTime(date.year, date.month, date.day, date.hour + 1);
  }

  List<Widget> _buildTimeLabels(DateTime start, DateTime end, double offset) {
    final List<Widget> labels = [];
    final firstFullHour = _nextFullHour(start);
    final minutesToFirstFullHour = firstFullHour.difference(start).inMinutes;

    if (minutesToFirstFullHour > 0) {
      labels.add(SizedBox(width: minutesToFirstFullHour * TimetableConstants.pixelsPerMinute));
    }

    DateTime current = firstFullHour;
    while (current.isBefore(end)) {
      // La dernière heure peut être partielle (set finissant à XX:30) : on borne
      // la largeur de la case au temps réellement restant, sinon elle réclame une
      // heure pleine (180px) et déborde de la timetable.
      final double boxWidth = (current.difference(end).inMinutes.abs() *
              TimetableConstants.pixelsPerMinute)
          .clamp(0.0, TimetableConstants.pixelsPerHour);
      labels.add(
        SizedBox(
          width: boxWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text('${current.hour}:00', style: TimetableConstants.timeScaleTextStyle),
            ),
          ),
        ),
      );
      current = current.add(const Duration(hours: 1));
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TimetableConstants.timeScaleHeight,
      color: AppTheme.background,
      child: Row(children: _buildTimeLabels(minStartTime, maxEndTime, offset)),
    );
  }
}