import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_card.dart';

class TeamList extends StatelessWidget {
  final List<User> users;
  final void Function(String) onCallPressed;
  final void Function(double?, double?) onLocatePressed;  // <-- Typage mis à jour

  const TeamList({
    super.key,
    required this.users,
    required this.onCallPressed,
    required this.onLocatePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];  // user est déjà un User

        return UserCard(
          user: user,  // <-- Passe directement l'objet User
          onCallPressed: onCallPressed,
          onLocatePressed: onLocatePressed,
        );
      },
    );
  }
}