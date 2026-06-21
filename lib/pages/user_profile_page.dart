import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user_model.dart';
import '../models/timetable_item.dart';
import '../models/dj_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/team_helper.dart';
import '../widgets/team/user_avatar.dart';
import '../widgets/ratings/rating_text.dart';
import '../widgets/shared/dj_photo.dart';
import '../widgets/shared/festival_background.dart';
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
    final hasLocation = AppUtils.hasValidLocation(user.lastLat, user.lastLng);
    final hasKnownLocation = user.lastLocation != '?';
    final hasTent = AppUtils.hasValidLocation(user.tentLat, user.tentLng);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(user.username),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FestivalBackground(
        imageKey: 'featured',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête : avatar (anneau accent) + nom + ID ─────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accent, width: 2.5),
                        ),
                        child: UserAvatar(user: user, radius: 46),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID ${user.id}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Contact (icône unique par action, plus de doublon) ──────
                _ContactTile(
                  icon: Icons.phone,
                  title: 'Téléphone',
                  value: hasPhone ? user.phoneNumber! : 'Non renseigné',
                  actionLabel: 'Appeler',
                  onTap: hasPhone
                      ? () => TeamHelper.callUser(user.phoneNumber!)
                      : null,
                ),
                const SizedBox(height: 12),
                _ContactTile(
                  icon: Icons.place,
                  title: 'Position',
                  value:
                      hasKnownLocation ? user.lastLocation : 'Position inconnue',
                  actionLabel: 'Itinéraire',
                  onTap: hasLocation
                      ? () => TeamHelper.locateUser(user.lastLat, user.lastLng)
                      : null,
                ),
                const SizedBox(height: 12),
                // Tente (campement) : icône dédiée pour ne pas confondre avec la
                // position courante. Grisée tant qu'aucune tente n'est enregistrée.
                _ContactTile(
                  icon: Icons.cabin, // repli ; iconWidget (FaIcon) est utilisé
                  iconWidget: FaIcon(FontAwesomeIcons.campground,
                      color: AppTheme.accent, size: 18),
                  title: 'Tente',
                  value: hasTent
                      ? 'Campement enregistré'
                      : 'Aucune tente enregistrée',
                  actionLabel: 'Rejoindre',
                  onTap: hasTent
                      ? () => TeamHelper.navigateToTent(
                          user.tentLat, user.tentLng)
                      : null,
                ),

                const SizedBox(height: 32),

                // ── Favoris classés ─────────────────────────────────────────
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
                      style: TextStyle(color: Colors.white70),
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
        ),
      ),
    );
  }
}

// ── Tuile de contact (téléphone / localisation) ─────────────────────────────
// Une seule icône par action (l'icône de gauche), tuile entièrement tappable :
// fini les icônes dupliquées (pin + flèche, combiné + appel).
class _ContactTile extends StatelessWidget {
  final IconData icon;
  /// Icône personnalisée (ex. FaIcon FontAwesome) ; si fournie, remplace [icon].
  final Widget? iconWidget;
  final String title;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    this.iconWidget,
    required this.title,
    required this.value,
    required this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: AppTheme.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.18),
                ),
                child: iconWidget ??
                    Icon(icon, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
              SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: DjPhoto(djName: item.dj),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
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
