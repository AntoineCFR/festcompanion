import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/app_data_manager.dart';
import 'rating_numbers.dart';
import 'rating_legend.dart';

class RatingsSection extends StatefulWidget {
  final int userId;
  final int setId;
  final VoidCallback? onRatingChanged; // ✅ NOUVEAU : Callback pour notifier le parent

  const RatingsSection({
    super.key,
    required this.userId,
    required this.setId,
    this.onRatingChanged, // ✅ NOUVEAU
  });

  @override
  State<RatingsSection> createState() => _RatingsSectionState();
}

class _RatingsSectionState extends State<RatingsSection> {
  List<MapEntry<int, int?>> _ratings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  void _loadRatings() {
    try {
      final allFavorites = AppDataManager().allUserFavorites;
      final ratingsForSet = <MapEntry<int, int?>>[];

      for (final userEntry in allFavorites.entries) {
        final userId = userEntry.key;
        final userFavs = userEntry.value;
        if (userFavs.containsKey(widget.setId)) {
          ratingsForSet.add(MapEntry(userId, userFavs[widget.setId]!.notation));
        }
      }
      setState(() {
        _ratings = ratingsForSet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _ratings = [];
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
    final currentUserRating = _ratings
        .firstWhere((entry) => entry.key == widget.userId, orElse: () => MapEntry(widget.userId, null))
        .value;

    final otherUsersWithRatings = _ratings
        .where((entry) => entry.key != widget.userId && entry.value != null)
        .toList()
      ..sort((a, b) {
        final userA = AppDataManager().users.firstWhere((u) => u.id == a.key);
        final userB = AppDataManager().users.firstWhere((u) => u.id == b.key);
        return userA.username.compareTo(userB.username);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notation et tags',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_ratings.isEmpty && currentUserRating == null)
          const Text('Aucune notation pour ce set.')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${currentUser.username} (toi):'),
                    const SizedBox(height: 4),
                    RatingNumbers(
                      rating: currentUserRating,
                      onRatingChanged: (newRating) async {
                        // ✅ Met à jour l'UI localement immédiatement
                        setState(() {
                          final index = _ratings.indexWhere((entry) => entry.key == widget.userId);
                          if (index != -1) {
                            _ratings[index] = MapEntry(widget.userId, newRating);
                          } else {
                            _ratings.add(MapEntry(widget.userId, newRating));
                          }
                        });
                        await AppDataManager().rateFavorite(widget.setId, newRating ?? -1);
                        _loadRatings();
                        widget.onRatingChanged?.call(); // ✅ NOUVEAU : Notifie DJProfilePage
                      },
                    ),
                  ],
                ),
              ),
              ...otherUsersWithRatings.map((entry) {
                final userId = entry.key;
                final notation = entry.value!;
                final user = AppDataManager().users.firstWhere((u) => u.id == userId);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${user.username}: $notation'),
                );
              }),
            ],
          ),
        const SizedBox(height: 16),
        const RatingLegend(),
      ],
    );
  }
}