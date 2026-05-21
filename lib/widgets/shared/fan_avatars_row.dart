import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../team/user_avatar.dart';

/// Ligne de petits avatars des utilisateurs qui ont mis un DJ en favori.
/// S'affiche en bas des tuiles lineup / timetable.
class FanAvatarsRow extends StatelessWidget {
  final List<User> fans;

  /// Rayon de chaque avatar (default : 10 → diamètre 20 dp).
  final double radius;

  /// Nombre maximum d'avatars affichés avant le badge "+N".
  final int maxVisible;

  const FanAvatarsRow({
    super.key,
    required this.fans,
    this.radius = 10,
    this.maxVisible = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (fans.isEmpty) return const SizedBox.shrink();

    final visible = fans.take(maxVisible).toList();
    final overflow = fans.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((user) => Padding(
              padding: const EdgeInsets.only(right: 3),
              child: UserAvatar(user: user, radius: radius),
            )),
        if (overflow > 0)
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '+$overflow',
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
