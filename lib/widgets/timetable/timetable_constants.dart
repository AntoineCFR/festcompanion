import 'package:flutter/material.dart';

class TimetableConstants {
  static const double pixelsPerMinute = 3.0;
  static const double pixelsPerHour = pixelsPerMinute * 60;
  static const double normalTileHeight = 63.0;
  static const double favoriteTileHeight = 80.0;
  static const double timeScaleHeight = 40.0;
  static const double districtSpacing = 2.0;
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 5, horizontal: 2);
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);

  static const TextStyle timeScaleTextStyle = TextStyle(fontSize: 14, color: Colors.white);
  static const TextStyle djTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle timeTextStyle = TextStyle(fontSize: 12, color: Colors.white70);
  static const TextStyle districtTextStyle = TextStyle(fontSize: 12, color: Colors.white);
  static const TextStyle districtSubtitleStyle = TextStyle(fontSize: 12, color: Colors.white54);
}