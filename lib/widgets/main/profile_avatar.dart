import '../../theme/app_theme.dart';
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
  late final VoidCallback _photosListener;

  @override
  void initState() {
    super.initState();
    _photoFuture = _resolvePhotoUrl();
    // Re-résout depuis le cache quand les photos de fond arrivent.
    // ⚠️ Corps de bloc (et non flèche) : `setState(() => _photoFuture = …)`
    // RENVOIE le Future assigné → Flutter loggue « setState() callback argument
    // returned a Future ». Ici la closure ne retourne rien (void).
    _photosListener = () {
      if (mounted) {
        setState(() {
          _photoFuture = _resolvePhotoUrl();
        });
      }
    };
    AppDataManager().photosRevision.addListener(_photosListener);
  }

  @override
  void dispose() {
    AppDataManager().photosRevision.removeListener(_photosListener);
    super.dispose();
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
              backgroundColor: AppTheme.surface,
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