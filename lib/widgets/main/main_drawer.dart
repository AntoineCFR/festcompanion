import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../pages/profile_page.dart';
import '../../pages/team_page.dart';
import '../../pages/stages_page.dart';
import '../../pages/festival_selection_page.dart';
import '../../pages/theme_page.dart';
import '../../services/app_data_manager.dart';

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
      backgroundColor: AppTheme.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.surface,
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
          // Entrée pour les scènes (ex-districts)
          ListTile(
            leading: const Icon(Icons.location_city, color: Colors.white),
            title: const Text(
              'Scènes',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StagesPage(
                    username: username,
                    userId: userId,
                  ),
                ),
              );
            },
          ),
          // Changer de festival
          ListTile(
            leading: const Icon(Icons.festival, color: Colors.white),
            title: const Text(
              'Changer de festival',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              // Purge les données du festival courant puis relance la sélection.
              await AppDataManager().clearSelectedFestival();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => FestivalGate(
                    userId: userId,
                    username: username,
                    forceSelection: true,
                  ),
                ),
                (route) => false,
              );
            },
          ),
          // Thème
          ListTile(
            leading: const Icon(Icons.palette, color: Colors.white),
            title: const Text(
              'Thème',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemePage()),
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