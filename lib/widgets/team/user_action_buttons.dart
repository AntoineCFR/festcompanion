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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.white),
          onPressed: (phoneNumber?.isNotEmpty == true)
              ? () => onCallPressed(phoneNumber!)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.location_on, color: Colors.white),
          onPressed: (latitude != null && longitude != null)
              ? () => onLocatePressed(latitude, longitude)
              : null,
        ),
      ],
    );
  }
}