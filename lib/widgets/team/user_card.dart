import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_avatar.dart';
import 'user_action_buttons.dart';

class UserCard extends StatelessWidget {
  final User user;  // <-- Uniquement User
  final void Function(String) onCallPressed;
  final void Function(double?, double?) onLocatePressed;

  const UserCard({
    super.key,
    required this.user,
    required this.onCallPressed,
    required this.onLocatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[800],
      child: ListTile(
        leading: UserAvatar(user: user, radius: 20),  // <-- user.photoUrl
        title: Text(
          user.username,  // <-- user.username
          style: const TextStyle(color: Colors.white),
        ),
        trailing: UserActionButtons(
          phoneNumber: user.phoneNumber,  // <-- user.phoneNumber
          latitude: user.lastLat,         // <-- user.lastLat
          longitude: user.lastLng,        // <-- user.lastLng
          onCallPressed: onCallPressed,
          onLocatePressed: onLocatePressed,
        ),
      ),
    );
  }
}