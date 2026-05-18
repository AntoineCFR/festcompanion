import 'package:flutter/material.dart';

class TeamAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefreshPressed;

  const TeamAppBar({
    super.key,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Équipe'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: onRefreshPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}