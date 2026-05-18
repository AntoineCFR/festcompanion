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
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppDataManager().photoUrls[user.id];  // ✅ Utilise _photoUrls
    if (photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[700],
        backgroundImage: CachedNetworkImageProvider(
          '$photoUrl?${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[700],
      child: const Icon(Icons.account_circle, color: Colors.white),
    );
  }
}