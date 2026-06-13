import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/app_data_manager.dart';
import '../../pages/user_profile_page.dart';
import '../team/user_avatar.dart';
import 'rating_numbers.dart';
import 'rating_text.dart';
import 'rating_legend.dart';

// Données combinées favori + note pour un utilisateur donné.
class _UserSetInfo {
  final int userId;
  final bool isFavorite;
  final int? notation;
  const _UserSetInfo({
    required this.userId,
    required this.isFavorite,
    required this.notation,
  });
}

class RatingsSection extends StatefulWidget {
  final int userId;
  final int setId;
  final VoidCallback? onRatingChanged;

  const RatingsSection({
    super.key,
    required this.userId,
    required this.setId,
    this.onRatingChanged,
  });

  @override
  State<RatingsSection> createState() => _RatingsSectionState();
}

class _RatingsSectionState extends State<RatingsSection> {
  List<_UserSetInfo> _infos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInfos();
  }

  void _loadInfos() {
    try {
      final allFavorites = AppDataManager().allUserFavorites;
      final result = <_UserSetInfo>[];

      for (final userEntry in allFavorites.entries) {
        final uid = userEntry.key;
        final userFavs = userEntry.value;
        final fav = userFavs[widget.setId];
        if (fav != null && (fav.isFavorite || fav.notation != null)) {
          result.add(_UserSetInfo(
            userId: uid,
            isFavorite: fav.isFavorite,
            notation: fav.notation,
          ));
        }
      }

      // S'assurer que l'utilisateur courant apparaît (même si absent de allFavorites)
      final currentInAll = result.any((i) => i.userId == widget.userId);
      if (!currentInAll) {
        final myFav = AppDataManager().getUserFavorite(widget.setId);
        if (myFav != null && (myFav.isFavorite || myFav.notation != null)) {
          result.add(_UserSetInfo(
            userId: widget.userId,
            isFavorite: myFav.isFavorite,
            notation: myFav.notation,
          ));
        }
      }

      setState(() {
        _infos = result;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _infos = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AppDataManager().users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => User(id: widget.userId, username: 'Toi'),
    );
    final currentInfo = _infos.firstWhere(
      (i) => i.userId == widget.userId,
      orElse: () =>
          _UserSetInfo(userId: widget.userId, isFavorite: false, notation: null),
    );

    // Autres utilisateurs : favoris OU notés, triés par nom
    final others = _infos.where((i) => i.userId != widget.userId).toList()
      ..sort((a, b) {
        final ua = AppDataManager().users.firstWhere(
          (u) => u.id == a.userId,
          orElse: () => User(id: a.userId, username: '?'),
        );
        final ub = AppDataManager().users.firstWhere(
          (u) => u.id == b.userId,
          orElse: () => User(id: b.userId, username: '?'),
        );
        return ua.username.compareTo(ub.username);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre ───────────────────────────────────────────────────────────
        const Text(
          'Notation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          // ── Autres utilisateurs (Wrap inline) ───────────────────────────
          if (others.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: others.map((info) {
                final user = AppDataManager().users.firstWhere(
                  (u) => u.id == info.userId,
                  orElse: () => User(id: info.userId, username: '?'),
                );
                return _UserFanChip(
                  user: user,
                  info: info,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(user: user),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],

          // ── Utilisateur courant ─────────────────────────────────────────
          Row(
            children: [
              UserAvatar(user: currentUser, radius: 14),
              const SizedBox(width: 8),
              Text(
                '${currentUser.username} (toi)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (currentInfo.isFavorite) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 16),
              ],
              const SizedBox(width: 8),
              RatingText(rating: currentInfo.notation),
            ],
          ),
          const SizedBox(height: 10),
          RatingNumbers(
            rating: currentInfo.notation,
            onRatingChanged: (newRating) async {
              setState(() {
                final idx = _infos.indexWhere((i) => i.userId == widget.userId);
                final updated = _UserSetInfo(
                  userId: widget.userId,
                  isFavorite: currentInfo.isFavorite,
                  notation: newRating,
                );
                if (idx != -1) {
                  _infos[idx] = updated;
                } else {
                  _infos.add(updated);
                }
              });
              await AppDataManager().rateFavorite(widget.setId, newRating);
              _loadInfos();
              widget.onRatingChanged?.call();
            },
          ),
        ],

        const SizedBox(height: 20),
        const RatingLegend(),
      ],
    );
  }
}

// ── Chip compact pour un utilisateur (Wrap) ─────────────────────────────────
class _UserFanChip extends StatelessWidget {
  final User user;
  final _UserSetInfo info;
  final VoidCallback? onTap;

  const _UserFanChip({required this.user, required this.info, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(user: user, radius: 12),
          const SizedBox(width: 6),
          Text(
            user.username,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
          if (info.isFavorite) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Colors.amber, size: 13),
          ],
          if (info.notation != null) ...[
            const SizedBox(width: 6),
            RatingText(rating: info.notation),
          ],
        ],
      ),      // ferme Row
    ),         // ferme Container
    );         // ferme GestureDetector
  }
}
