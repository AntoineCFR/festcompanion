import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_card.dart';

class TeamList extends StatelessWidget {
  final List<User> users;
  final void Function(String) onCallPressed;
  final void Function(double?, double?) onLocatePressed;
  /// Appelé quand l'utilisateur tape sur une carte (navigation vers le profil).
  final void Function(User)? onTap;

  const TeamList({
    super.key,
    required this.users,
    required this.onCallPressed,
    required this.onLocatePressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserCard(
          user: user,
          onCallPressed: onCallPressed,
          onLocatePressed: onLocatePressed,
          onTap: onTap != null ? () => onTap!(user) : null,
        );
      },
    );
  }
}
