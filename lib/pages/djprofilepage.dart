import 'package:flutter/material.dart';
import '../models/dj_model.dart';
import '../widgets/dj_profile/dj_profile_header.dart';
import '../widgets/dj_profile/dj_bio.dart';
import '../widgets/dj_profile/social_media_links.dart';
import '../widgets/ratings/ratings_section.dart';
import '../helpers/social_media_helper.dart';
import '../utils/utils.dart';
import '../services/app_data_manager.dart';

class DJProfilePage extends StatefulWidget {
  final DJ dj;
  final int userId;
  final int setId;

  const DJProfilePage({
    super.key,
    required this.dj,
    required this.userId,
    required this.setId,
  });

  @override
  State<DJProfilePage> createState() => _DJProfilePageState();
}

class _DJProfilePageState extends State<DJProfilePage> {
  @override
  Widget build(BuildContext context) {
    final socialMediaItems = buildSocialMediaItems(
      spotifyLink: widget.dj.spotifyLink,
      soundcloudLink: widget.dj.soundcloudLink,
      instagramLink: widget.dj.instagramLink,
    );

    final isFavorite = AppDataManager().favoriteSetIds.contains(widget.setId);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            DJProfileHeader(
              imagePath: AppUtils.getDjImagePath(widget.dj.name),
              name: widget.dj.name,
              district: widget.dj.district,
              startTime: widget.dj.startTime,
              endTime: widget.dj.endTime,
              isFavorite: isFavorite,
              onToggleFavorite: () async {
                await AppDataManager().toggleFavorite(widget.setId);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            if (socialMediaItems.isNotEmpty) ...[
              SocialMediaLinks(items: socialMediaItems),
              const SizedBox(height: 16),
            ],
            RatingsSection(
              userId: widget.userId,
              setId: widget.setId,
              onRatingChanged: () => setState(() {}), // ✅ NOUVEAU : Rafraîchit l'UI après notation
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'BIO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            DJBio(bio: widget.dj.bio.isNotEmpty ? widget.dj.bio : 'Aucune bio disponible.'),
            // Espace de sécurité : compense la barre de navigation virtuelle
            // du téléphone pour que le contenu ne se retrouve pas derrière.
            SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}