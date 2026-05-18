class User {
  final int id;
  final String username;
  final String? phoneNumber;
  final double? lastLat;
  final double? lastLng;
  final String? photoUrl;

  User({
    required this.id,
    required this.username,
    this.phoneNumber,
    this.lastLat,
    this.lastLng,
    this.photoUrl,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String? ?? 'Inconnu',
      phoneNumber: map['phone_number']?.toString(),
      lastLat: map['last_lat'] != null ? (map['last_lat'] as num).toDouble() : null,
      lastLng: map['last_lng'] != null ? (map['last_lng'] as num).toDouble() : null,
      photoUrl: map['photo_url'],
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? phoneNumber,
    double? lastLat,
    double? lastLng,
    String? photoUrl,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'phone_number': phoneNumber,
      'last_lat': lastLat,
      'last_lng': lastLng,
      'photo_url': photoUrl,
    };
  }
}