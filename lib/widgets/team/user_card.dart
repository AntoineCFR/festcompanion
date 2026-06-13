import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_avatar.dart';
import 'user_action_buttons.dart';

class UserCard extends StatelessWidget {
  final User user;
  final void Function(String) onCallPressed;
  final void Function(double?, double?) onLocatePressed;
  /// Navigation vers le profil de l'utilisateur (optionnel).
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.onCallPressed,
    required this.onLocatePressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = user.phoneNumber?.isNotEmpty == true;
    final stageName = user.lastLocation == '?' ? null : user.lastLocation;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo ou initiale
              UserAvatar(user: user, radius: 24),
              const SizedBox(width: 14),
              // Nom / Téléphone / District
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    if (hasPhone)
                      Text(
                        user.phoneNumber!,
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    Text(
                      'Position : ${stageName ?? 'autre'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Boutons d'action
              UserActionButtons(
                phoneNumber: user.phoneNumber,
                latitude: user.lastLat,
                longitude: user.lastLng,
                onCallPressed: onCallPressed,
                onLocatePressed: onLocatePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
