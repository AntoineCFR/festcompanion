import 'package:flutter/material.dart';
import '../../pages/profile_page.dart';
import '../../pages/team_page.dart';
import '../../pages/districts_page.dart'; // NOUVEAU

class MainDrawer extends StatelessWidget {
  final String username;
  final int userId;
  final VoidCallback onLogout;

  const MainDrawer({
    super.key,
    required this.username,
    required this.userId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey[800],
            ),
            child: Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.white),
            title: const Text(
              'Mon compte',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    username: username,
                    userId: userId,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.white),
            title: const Text(
              'Équipe',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeamPage(),
                ),
              );
            },
          ),
          // NOUVEAU: Entrée pour les districts
          ListTile(
            leading: const Icon(Icons.location_city, color: Colors.white),
            title: const Text(
              'Districts',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DistrictsPage(
                    username: username,
                    userId: userId,
                  ),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}