import '../../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../pages/profile_page.dart';
import '../../pages/team_page.dart';
import '../../pages/stages_page.dart';
import '../../pages/admin_panel_page.dart';
import '../../pages/journal_page.dart';
import '../../pages/festival_selection_page.dart';
import '../../pages/theme_page.dart';
import '../../pages/about_page.dart';
import '../../services/app_data_manager.dart';

class MainDrawer extends StatelessWidget {
  final String username;
  final int userId;
  final VoidCallback onLogout;

  /// Bascule l'onglet d'accueil sur la page « Accueil » (countdown).
  final VoidCallback onShowHome;

  /// Bascule l'onglet d'accueil sur la page « Live ».
  final VoidCallback onShowFeatured;

  const MainDrawer({
    super.key,
    required this.username,
    required this.userId,
    required this.onLogout,
    required this.onShowHome,
    required this.onShowFeatured,
  });

  ListTile _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête compact : avatar + pseudo (réduit l'espace vide d'un DrawerHeader).
          Container(
            width: double.infinity,
            color: AppTheme.surface,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 14,
              16,
              14,
            ),
            child: Row(
              children: [
                _DrawerAvatar(username: username, userId: userId),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Navigation ───────────────────────────────────────────────────
          _tile(context,
              icon: Icons.home,
              label: 'Accueil',
              onTap: () {
                Navigator.pop(context);
                onShowHome();
              }),
          _tile(context,
              icon: Icons.sensors,
              label: 'Live',
              onTap: () {
                Navigator.pop(context);
                onShowFeatured();
              }),
          _tile(context,
              icon: Icons.auto_stories,
              label: 'Journal',
              onTap: () => _push(context, const JournalPage())),
          _tile(context,
              icon: Icons.group,
              label: 'Équipe',
              onTap: () => _push(context, const TeamPage())),
          _tile(context,
              icon: Icons.location_city,
              label: 'Scènes',
              onTap: () =>
                  _push(context, StagesPage(username: username, userId: userId))),
          _tile(context,
              icon: Icons.admin_panel_settings,
              label: 'Administration',
              onTap: () => _push(context,
                  AdminPanelPage(username: username, userId: userId))),

          const Divider(color: Colors.white24),

          // ── Compte & préférences ─────────────────────────────────────────
          _tile(context,
              icon: Icons.account_circle,
              label: 'Mon compte',
              onTap: () => _push(
                  context, ProfilePage(username: username, userId: userId))),
          _tile(context,
              icon: Icons.palette,
              label: 'Thème',
              onTap: () => _push(context, const ThemePage())),
          _tile(context,
              icon: Icons.info_outline,
              label: 'À propos',
              onTap: () => _push(context, const AboutPage())),

          const Divider(color: Colors.white24),

          // ── Session ──────────────────────────────────────────────────────
          _tile(context,
              icon: Icons.festival,
              label: 'Changer de festival',
              onTap: () async {
                Navigator.pop(context);
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
              }),
          _tile(context,
              icon: Icons.logout,
              label: 'Se déconnecter',
              onTap: () {
                Navigator.pop(context);
                onLogout();
              }),
        ],
      ),
    );
  }
}

/// Avatar de l'en-tête du drawer : la photo du compte si elle existe (cache
/// [AppDataManager.photoUrls], rempli en arrière-plan au démarrage), sinon la
/// pastille accent avec l'initiale. Réactif à l'arrivée tardive des photos.
class _DrawerAvatar extends StatelessWidget {
  final String username;
  final int userId;

  const _DrawerAvatar({required this.username, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppDataManager().photosRevision,
      builder: (context, _, _) {
        final photoUrl = AppDataManager().photoUrls[userId];
        return CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.accent,
          backgroundImage:
              photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppTheme.onAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        );
      },
    );
  }
}
