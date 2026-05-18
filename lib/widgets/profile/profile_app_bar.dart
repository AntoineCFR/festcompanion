import 'package:flutter/material.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSavePressed;

  const ProfileAppBar({
    super.key,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Mon compte'),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSavePressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}