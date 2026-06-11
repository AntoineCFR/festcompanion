import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/team_helper.dart';
import '../widgets/team/user_avatar.dart';
import '../widgets/ratings/rating_text.dart';
import '../utils/utils.dart';
import 'djprofilepage.dart';

// ── Données d'un set favori classé ──────────────────────────────────────────
class _RankedSet {
  final TimetableItem item;
  final int? notation;
  const _RankedSet({required this.item, required this.notation});
}

/// Page de profil d'un utilisateur, en lecture seule.
/// Affiche : avatar, nom, ID, téléphone, localisation, favoris classés.
class UserProfilePage extends StatelessWidget {
  final User user;

  const UserProfilePage({super.key, required this.user});

  List<_RankedSet> _buildRankedFavorites() {
    final userFavs = AppDataManager().allUserFavorites[user.id] ?? {};
    final timetable = AppDataManager().timetable;
    final result = <_RankedSet>[];

    for (final entry in userFavs.entries) {
      if (!entry.value.isFavorite) continue;
      final matches = timetable.where((t) => t.setId == entry.key);
      if (matches.isEmpty) continue;
      result.add(_RankedSet(item: matches.first, notation: entry.value.notation));
    }

    // Tri : notation décroissante (null en dernier), puis ordre alphabétique
    result.sort((a, b) {
      if (a.notation == null && b.notation == null) {
        return a.item.dj.compareTo(b.item.dj);
      }
      if (a.notation == null) return 1;
      if (b.notation == null) return -1;
      final cmp = b.notation!.compareTo(a.notation!);
      return cmp != 0 ? cmp : a.item.dj.compareTo(b.item.dj);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _buildRankedFavorites();
    final hasPhone = user.phoneNumber?.isNotEmpty == true;
    final hasLocation = user.lastLat != null && user.lastLng != null;
    final hasKnownLocation = user.lastLocation != '?';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(user.username),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : avatar + nom + ID ──────────────────────────────
            Center(
              child: Column(
                children: [
                  UserAvatar(user: user, radius: 48),
                  const SizedBox(height: 12),
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID : ${user.id}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Téléphone ────────────────────────────────────────────────
            _InfoRow(
              icon: Icons.phone,
              label: hasPhone ? user.phoneNumber! : 'Non renseigné',
              available: hasPhone,
              actionIcon: hasPhone ? Icons.call : null,
              onAction: hasPhone ? () => TeamHelper.callUser(user.phoneNumber!) : null,
            ),
            const SizedBox(height: 12),

            // ── Localisation ─────────────────────────────────────────────
            _InfoRow(
              icon: Icons.location_on,
              label: hasKnownLocation ? user.lastLocation : 'Position inconnue',
              available: hasKnownLocation,
              actionIcon: hasLocation ? Icons.near_me : null,
              onAction: hasLocation
                  ? () => TeamHelper.locateUser(user.lastLat, user.lastLng)
                  : null,
            ),

            const SizedBox(height: 32),

            // ── Favoris classés ──────────────────────────────────────────
            const Text(
              'Favoris',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (ranked.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aucun favori enregistré.',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              ...ranked.map(
                (r) => _FavoriteSetTile(item: r.item, notation: r.notation),
              ),

            SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ── Ligne d'info (téléphone / localisation) ─────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool available;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.available,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: available ? Colors.white70 : Colors.white24, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: available ? Colors.white : Colors.white38,
              fontSize: 15,
            ),
          ),
        ),
        if (actionIcon != null)
          IconButton(
            icon: Icon(actionIcon, color: Colors.white),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 8),
            onPressed: onAction,
          ),
      ],
    );
  }
}

// ── Tuile d'un set favori classé ─────────────────────────────────────────────
class _FavoriteSetTile extends StatelessWidget {
  final TimetableItem item;
  final int? notation;

  const _FavoriteSetTile({required this.item, required this.notation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DJProfilePage(
              userId: AppDataManager().userId!,
              setId: item.setId,
              dj: DJ(
                name: item.dj,
                bio: item.bio ?? '',
                stage: item.stage,
                startTime: item.startTime,
                endTime: item.endTime,
                spotifyLink: item.spotifyLink,
                soundcloudLink: item.soundcloudLink,
                instagramLink: item.instagramLink,
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Photo DJ
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  AppUtils.getDjImagePath(item.dj),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 48,
                    height: 48,
                    color: AppTheme.surfaceAlt,
                    child: const Icon(Icons.person, color: Colors.white54, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Infos DJ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dj,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.stage} · '
                      '${AppUtils.formatTime(item.startTime)} – '
                      '${AppUtils.formatTime(item.endTime)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge de notation (absent si non noté)
              RatingText(rating: notation),
            ],
          ),
        ),
      ),
    );
  }
}
