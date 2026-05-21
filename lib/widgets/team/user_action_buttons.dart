import 'package:flutter/material.dart';

class UserActionButtons extends StatelessWidget {
  final String? phoneNumber;
  final double? latitude;  // <-- Typage explicite
  final double? longitude; // <-- Typage explicite
  final void Function(String) onCallPressed;
  final void Function(double?, double?) onLocatePressed;  // <-- Typage mis à jour

  const UserActionButtons({
    super.key,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    required this.onCallPressed,
    required this.onLocatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final canCall = phoneNumber?.isNotEmpty == true;
    final canLocate = latitude != null && longitude != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.phone, size: 22,
              color: canCall ? Colors.white : Colors.white24),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          onPressed: canCall ? () => onCallPressed(phoneNumber!) : null,
        ),
        IconButton(
          icon: Icon(Icons.near_me, size: 22,
              color: canLocate ? Colors.white : Colors.white24),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.only(left: 6, right: 0),
          onPressed: canLocate ? () => onLocatePressed(latitude, longitude) : null,
        ),
      ],
    );
  }
}