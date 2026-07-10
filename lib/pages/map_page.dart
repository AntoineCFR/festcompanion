import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../helpers/profile_helper.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../theme/app_theme.dart';
import '../utils/utils.dart';
import '../widgets/map/calibrated_map_image.dart';
import '../widgets/team/user_avatar.dart';

/// Illustration de la carte du festival, par `festival_id`. Asset embarqué
/// (comme `FestivalBackground`) : un seul festival concerné pour l'instant,
/// pas besoin d'aller chercher ça en base. Absence d'entrée → onglet Map en
/// repli ("carte indisponible"), pas de crash.
const Map<int, String> festivalMapAssets = {
  2: 'lib/assets/maps/2_map.jpg',
};

/// Rayon d'exclusion (fraction de la largeur image) appliqué si une scène n'a
/// pas encore de `mapExclusionRadius` calibré individuellement.
const double _defaultExclusionRadius = 0.025;

/// Écart angulaire minimal entre deux avatars sur un même anneau, et entre
/// deux anneaux (fractions de la largeur image).
const double _avatarRingSpacing = 0.028;
const double _ringGap = 0.022;

const double _avatarRadius = 12;

/// Liseret autour de chaque avatar pour le repérer facilement sur la carte
/// (jaune électrique : contraste fort avec le vert/bleu de l'illustration et
/// avec le rouge déjà utilisé pour les pictogrammes de scène).
const Color _avatarHighlightColor = Color(0xFFFFEA00);

/// Page plein écran « Map » (utilisée hors bottom-nav si besoin).
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: AppTheme.surface,
      ),
      body: const MapView(),
    );
  }
}

/// Contenu « Map » (sans Scaffold) → onglet du bottom-nav. Avatars des users
/// positionnés autour de leur scène courante sur l'illustration du festival.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (AppDataManager().stages.isNotEmpty) _isLoading = false;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await AppDataManager().loadStages();
      await AppDataManager().loadUsers();
    } catch (e) {
      if (mounted && AppDataManager().stages.isEmpty) {
        AppDataManager().showSnackBar('Erreur chargement de la carte : $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // Rafraîchit MA position en arrière-plan (fix GPS potentiellement lent) :
    // ne bloque pas l'affichage, met juste à jour mon propre avatar ensuite.
    final myId = AppDataManager().userId;
    if (myId != null) {
      ProfileHelper.refreshLocationIfEnabled(myId).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Bulle d'info flottante ancrée au-dessus du point tapé, plutôt qu'une
  /// pop-up plein écran : se ferme en tapant n'importe où ailleurs.
  void _showUserBubble(User user, Offset globalPosition) {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    late OverlayEntry entry;

    final stageLabel =
        user.lastLocation == '?' ? 'position inconnue' : user.lastLocation;
    final seen = user.lastSeenAt != null
        ? AppUtils.relativeTime(user.lastSeenAt!)
        : 'jamais localisé';

    const bubbleWidth = 220.0;
    final left = (globalPosition.dx - bubbleWidth / 2)
        .clamp(8.0, math.max(8.0, screenSize.width - bubbleWidth - 8.0))
        .toDouble();
    final bottom = screenSize.height - globalPosition.dy + _avatarRadius + 10;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Zone transparente plein écran : un tap n'importe où ailleurs
          // referme la bulle sans interagir avec la carte en dessous.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => entry.remove(),
            ),
          ),
          Positioned(
            left: left,
            bottom: bottom,
            width: bubbleWidth,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * t,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$stageLabel — $seen',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  /// Décalages (fractions de la largeur image) d'un anneau d'avatars autour
  /// d'une scène : répartis équitablement en angle, un anneau supplémentaire
  /// (rayon croissant) si le nombre d'avatars dépasse ce qui tient sur le
  /// premier. Précision volontairement approximative (cf. demande initiale).
  List<Offset> _ringOffsets(int count, double baseRadius) {
    final offsets = <Offset>[];
    var remaining = count;
    var ring = 0;
    while (remaining > 0) {
      final ringRadius = baseRadius + ring * _ringGap;
      final slots = math.max(
          1, (2 * math.pi * ringRadius / _avatarRingSpacing).floor());
      final onThisRing = math.min(remaining, slots);
      for (var i = 0; i < onThisRing; i++) {
        final angle = (2 * math.pi * i / onThisRing) - math.pi / 2;
        offsets.add(Offset(ringRadius * math.cos(angle), ringRadius * math.sin(angle)));
      }
      remaining -= onThisRing;
      ring++;
    }
    return offsets;
  }

  /// Un `Positioned` par avatar, groupés par scène courante (`lastLocation`),
  /// en excluant les positions inconnues et les scènes pas encore calibrées.
  List<Widget> _buildMarkers(Size imageSize) {
    final stages = AppDataManager().stages;
    final byStageName = {for (final s in stages) s.stage: s};

    final byStage = <String, List<User>>{};
    for (final user in AppDataManager().users) {
      if (user.lastLocation == '?') continue;
      final stage = byStageName[user.lastLocation];
      if (stage == null || !stage.hasMapAnchor) continue;
      byStage.putIfAbsent(user.lastLocation, () => []).add(user);
    }

    final markers = <Widget>[];
    for (final entry in byStage.entries) {
      final stage = byStageName[entry.key]!;
      final users = entry.value;
      final baseRadius = (stage.mapExclusionRadius != null &&
              stage.mapExclusionRadius! > 0)
          ? stage.mapExclusionRadius!
          : _defaultExclusionRadius;
      final offsets = _ringOffsets(users.length, baseRadius);

      for (var i = 0; i < users.length; i++) {
        final anchorPx =
            Offset(stage.mapAnchorX! * imageSize.width, stage.mapAnchorY! * imageSize.height);
        // La composante Y utilise aussi imageSize.width (pas .height) pour
        // que l'anneau reste un cercle visuel, indépendamment du ratio de
        // l'image (cf. `map_exclusion_radius` = fraction de la LARGEUR).
        final offsetPx = Offset(
          offsets[i].dx * imageSize.width,
          offsets[i].dy * imageSize.width,
        );
        final center = anchorPx + offsetPx;
        final user = users[i];
        markers.add(Positioned(
          left: center.dx - _avatarRadius,
          top: center.dy - _avatarRadius,
          child: GestureDetector(
            onTapUp: (details) => _showUserBubble(user, details.globalPosition),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _avatarHighlightColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _avatarHighlightColor.withValues(alpha: 0.6),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: UserAvatar(user: user, radius: _avatarRadius),
            ),
          ),
        ));
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final festivalId = AppDataManager().selectedFestivalId;
    final assetPath = festivalId != null ? festivalMapAssets[festivalId] : null;

    return Container(
      color: AppTheme.background,
      child: _isLoading && AppDataManager().stages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : assetPath == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Carte indisponible pour ce festival.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: CalibratedMapImage(
                      assetPath: assetPath,
                      overlayBuilder: (size) => Stack(children: _buildMarkers(size)),
                    ),
                  ),
                ),
    );
  }
}
