class User {
  final int id;
  final String username;
  final String? phoneNumber;
  final double? lastLat;
  final double? lastLng;
  final double? tentLat; // emplacement de la tente (campement), par festival
  final double? tentLng;
  final String? photoUrl;
  final String userRole;
  final String lastLocation; // NOUVEAU
  /// Horodatage de la dernière position connue (pour "il y a X minutes" sur
  /// la carte). Null si jamais localisé.
  final DateTime? lastSeenAt;

  User({
    required this.id,
    required this.username,
    this.phoneNumber,
    this.lastLat,
    this.lastLng,
    this.tentLat,
    this.tentLng,
    this.photoUrl,
    this.userRole = 'user',
    this.lastLocation = '?', // Par défaut
    this.lastSeenAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String? ?? 'Inconnu',
      phoneNumber: map['phone_number']?.toString(),
      lastLat: map['last_lat'] != null ? (map['last_lat'] as num).toDouble() : null,
      lastLng: map['last_lng'] != null ? (map['last_lng'] as num).toDouble() : null,
      tentLat: map['tent_lat'] != null ? (map['tent_lat'] as num).toDouble() : null,
      tentLng: map['tent_lng'] != null ? (map['tent_lng'] as num).toDouble() : null,
      photoUrl: map['photo_url'],
      userRole: map['user_role'] as String? ?? 'user',
      lastLocation: map['last_location'] as String? ?? '?',
      lastSeenAt: map['last_seen_at'] != null
          ? DateTime.tryParse(map['last_seen_at'] as String)
          : null,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? phoneNumber,
    double? lastLat,
    double? lastLng,
    double? tentLat,
    double? tentLng,
    String? photoUrl,
    String? userRole,
    String? lastLocation, // NOUVEAU
    DateTime? lastSeenAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      tentLat: tentLat ?? this.tentLat,
      tentLng: tentLng ?? this.tentLng,
      photoUrl: photoUrl ?? this.photoUrl,
      userRole: userRole ?? this.userRole,
      lastLocation: lastLocation ?? this.lastLocation,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'phone_number': phoneNumber,
      'last_lat': lastLat,
      'last_lng': lastLng,
      'tent_lat': tentLat,
      'tent_lng': tentLng,
      'photo_url': photoUrl,
      'user_role': userRole,
      'last_location': lastLocation,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }
}