import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/dj_profile/social_media_links.dart';

List<SocialMediaItem> buildSocialMediaItems({
  String? spotifyLink,
  String? soundcloudLink,
  String? instagramLink,
}) {
  return [
    if (spotifyLink != null && spotifyLink.isNotEmpty)
      SocialMediaItem(name: 'spotify', icon: FontAwesomeIcons.spotify, url: spotifyLink),
    if (soundcloudLink != null && soundcloudLink.isNotEmpty)
      SocialMediaItem(name: 'soundcloud', icon: FontAwesomeIcons.soundcloud, url: soundcloudLink),
    if (instagramLink != null && instagramLink.isNotEmpty)
      SocialMediaItem(name: 'instagram', icon: FontAwesomeIcons.instagram, url: instagramLink),
  ];
}