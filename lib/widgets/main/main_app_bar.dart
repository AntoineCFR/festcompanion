import 'package:flutter/material.dart';
import 'profile_avatar.dart';

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
      title: const Text('Extrema Outdoor 2026'),
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