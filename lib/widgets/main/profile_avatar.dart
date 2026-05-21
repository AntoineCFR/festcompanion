import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/app_data_manager.dart';
import '../../services/profile_service.dart';
import '../../pages/profile_page.dart';

/// Avatar affiché dans l'AppBar.
///
/// Utilise d'abord le cache [AppDataManager.photoUrls] (déjà chargé au
/// démarrage). Si la clé est absente (ex. : photo uploadée après le chargement
/// initial), fait un seul appel Firebase Storage via [ProfileService].
class ProfileAvatar extends StatefulWidget {
  final int userId;
  final String username;

  const ProfileAvatar({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  late Future<String?> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = _resolvePhotoUrl();
  }

  Future<String?> _resolvePhotoUrl() async {
    // Utilise le cache si disponible (évite un appel réseau inutile)
    final cached = AppDataManager().photoUrls[widget.userId];
    if (AppDataManager().photoUrls.containsKey(widget.userId)) {
      return cached;
    }
    return ProfileService.getPhotoUrl(widget.userId);
  }

  /// Appelé depuis [ProfilePage] après une mise à jour de photo.
  void refreshPhoto() {
    setState(() {
      _photoFuture = ProfileService.getPhotoUrl(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        final photoUrl = snapshot.data;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  username: widget.username,
                  userId: widget.userId,
                ),
              ),
            ).then((_) {
              // Rafraîchit l'avatar si l'utilisateur a mis à jour sa photo
              if (mounted) refreshPhoto();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[800],
              backgroundImage: photoUrl != null
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl == null
                  ? const Icon(Icons.account_circle, color: Colors.white)
                  : null,
            ),
          ),
        );
      },
    );
  }
}