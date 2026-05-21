// Sentinel used by copyWith to distinguish "not provided" from explicit null.
const _notationUnset = Object();

class UserFavorite {
  final int setId;
  final bool isFavorite;
  final int? notation;

  UserFavorite({
    required this.setId,
    required this.isFavorite,
    this.notation,
  });

  /// [notation] accepts explicit null to clear the value.
  /// Omit it entirely to keep the current value.
  UserFavorite copyWith({
    int? setId,
    bool? isFavorite,
    Object? notation = _notationUnset,
  }) {
    return UserFavorite(
      setId: setId ?? this.setId,
      isFavorite: isFavorite ?? this.isFavorite,
      notation: identical(notation, _notationUnset) ? this.notation : notation as int?,
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