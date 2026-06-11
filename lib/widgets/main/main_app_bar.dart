import 'package:flutter/material.dart';
import 'profile_avatar.dart';
import '../../services/app_data_manager.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final int userId;
  final VoidCallback onMenuPressed;

  const MainAppBar({
    super.key,
    required this.username,
    required this.userId,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
      ),
      title: Text(AppDataManager().selectedFestival?.name ?? 'FestCompanion'),
      actions: [
        ProfileAvatar(
          userId: userId,
          username: username,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}