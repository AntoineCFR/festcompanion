import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/utils.dart';

class UserActionButtons extends StatelessWidget {
  final String? phoneNumber;
  final double? latitude;  // <-- Typage explicite
  final double? longitude; // <-- Typage explicite
  final double? tentLat;   // emplacement de la tente (campement)
  final double? tentLng;
  final void Function(String) onCallPressed;
  final void Function(double?, double?) onLocatePressed;  // <-- Typage mis à jour
  final void Function(double?, double?) onTentPressed;

  const UserActionButtons({
    super.key,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.tentLat,
    this.tentLng,
    required this.onCallPressed,
    required this.onLocatePressed,
    required this.onTentPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canCall = phoneNumber?.isNotEmpty == true;
    final canLocate = AppUtils.hasValidLocation(latitude, longitude);
    final canTent = AppUtils.hasValidLocation(tentLat, tentLng);

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
          icon: Icon(Icons.place, size: 22,
              color: canLocate ? Colors.white : Colors.white24),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onPressed: canLocate ? () => onLocatePressed(latitude, longitude) : null,
        ),
        IconButton(
          icon: FaIcon(FontAwesomeIcons.campground, size: 18,
              color: canTent ? Colors.white : Colors.white24),
          tooltip: 'Rejoindre la tente',
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.only(left: 6, right: 0),
          onPressed: canTent ? () => onTentPressed(tentLat, tentLng) : null,
        ),
      ],
    );
  }
}