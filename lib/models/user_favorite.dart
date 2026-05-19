class UserFavorite {
  final int setId;
  final bool isFavorite;
  final int? notation;

  UserFavorite({
    required this.setId,
    required this.isFavorite,
    this.notation,
  });

  UserFavorite copyWith({
    int? setId,
    bool? isFavorite,
    int? notation,
  }) {
    return UserFavorite(
      setId: setId ?? this.setId,
      isFavorite: isFavorite ?? this.isFavorite,
      notation: notation ?? this.notation,
    );
  }

  factory UserFavorite.fromJson(Map<String, dynamic> json) {
    return UserFavorite(
      setId: json['set_id'] as int,
      isFavorite: json['isfavorite'] as bool,
      notation: json['notation'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_id': setId,
      'isfavorite': isFavorite,
      'notation': notation,
    };
  }
}