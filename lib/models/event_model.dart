import 'package:flutter/material.dart';

class Event {
  final int userId;
  final DateTime timestamp;
  final String eventType;

  Event({
    required this.userId,
    required this.timestamp,
    required this.eventType,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      userId: json['user_id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventType: json['event_type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'timestamp': timestamp.toIso8601String(),
        'event_type': eventType,
      };

  // Constantes pour les types d'événements
  static const List<String> alcoholTypes = ['demi_alcool', 'alcool'];
  static const List<String> energyTypes = ['quart_energie', 'demi_energie', 'pleine_energie'];
  static const List<String> hydrationTypes = ['eau'];
  static const List<String> hypeTypes = ['hype'];
  static const List<String> specialTypes = ['perdu', 'sos'];

  static const Map<String, String> labels = {
    'demi_alcool': 'Demi alcool',
    'alcool': 'Alcool',
    'quart_energie': 'Quart d\'énergie',
    'demi_energie': 'Demi énergie',
    'pleine_energie': 'Pleine énergie',
    'eau': 'Eau',
    'hype': 'Hype !',
    'perdu': 'Je me suis perdu',
    'sos': 'SOS',
  };

  static const Map<String, IconData> icons = {
    'demi_alcool': Icons.sports_bar,
    'alcool': Icons.liquor,
    'quart_energie': Icons.battery_2_bar,
    'demi_energie': Icons.battery_4_bar,
    'pleine_energie': Icons.battery_full,
    'eau': Icons.water_drop,
    'hype': Icons.whatshot,
    'perdu': Icons.wrong_location,
    'sos': Icons.sos,
  };
}