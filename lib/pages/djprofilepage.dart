import 'package:flutter/material.dart';
import '../models/dj_model.dart';
import '../widgets/dj_profile/dj_profile_header.dart';
import '../widgets/dj_profile/dj_bio.dart';
import '../widgets/dj_profile/social_media_links.dart';
import '../helpers/social_media_helper.dart';
import '../utils/utils.dart';

class DJProfilePage extends StatelessWidget {
  final DJ dj;

  const DJProfilePage({super.key, required this.dj});

  @override
  Widget build(BuildContext context) {
    final socialMediaItems = buildSocialMediaItems(
      spotifyLink: dj.spotifyLink,
      soundcloudLink: dj.soundcloudLink,
      instagramLink: dj.instagramLink,
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            DJProfileHeader(
              imagePath: AppUtils.getDjImagePath(dj.name),
              name: dj.name,
              district: dj.district,
              startTime: dj.startTime,
              endTime: dj.endTime,
            ),
            const SizedBox(height: 16),
            DJBio(bio: dj.bio.isNotEmpty ? dj.bio : 'Aucune bio disponible.'),
            if (socialMediaItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              SocialMediaLinks(items: socialMediaItems),
            ],
          ],
        ),
      ),
    );
  }
}