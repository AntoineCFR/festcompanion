class DJ {
  final String name;
  final String? district;
  final DateTime? startTime;
  final DateTime? endTime;
  final String bio;
  final String? spotifyLink;
  final String? soundcloudLink;
  final String? instagramLink;

  DJ({
    required this.name,
    this.district,
    this.startTime,
    this.endTime,
    required this.bio,
    this.spotifyLink,
    this.soundcloudLink,
    this.instagramLink,
  });

  factory DJ.fromMap(Map<String, dynamic> map) {
    return DJ(
      name: map['name'] ?? '',
      district: map['district'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      bio: map['bio'] ?? '',
      spotifyLink: map['spotify_link'],
      soundcloudLink: map['soundcloud_link'],
      instagramLink: map['instagram_link'],
    );
  }
}