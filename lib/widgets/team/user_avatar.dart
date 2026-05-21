import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/app_data_manager.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppDataManager().photoUrls[user.id];
    if (photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[700],
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }
    // Fallback : première lettre du prénom
    final initial = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[600],
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}