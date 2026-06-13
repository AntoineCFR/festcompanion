/// Tag collaboratif posé par un utilisateur sur un set (DJ).
/// Rattaché au `setId`, au même titre que les favoris/notes → propre au festival.
class DjTag {
  final int userId;
  final int setId;
  final String tag; // normalisé : sans espace, sans « # », minuscule

  const DjTag({
    required this.userId,
    required this.setId,
    required this.tag,
  });

  factory DjTag.fromJson(Map<String, dynamic> json) {
    return DjTag(
      userId: json['user_id'] as int,
      setId: json['set_id'] as int,
      tag: (json['tag'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'set_id': setId,
        'tag': tag,
      };

  /// Normalise un tag. Règle IDENTIQUE au backend (`normalize_tag` en Python) :
  /// retire un éventuel « # » de tête, supprime tous les espaces, passe en
  /// minuscule. Retourne '' si le résultat est vide (saisie à rejeter).
  static String normalize(String raw) {
    var t = raw.trim();
    if (t.startsWith('#')) t = t.substring(1);
    t = t.replaceAll(RegExp(r'\s+'), '');
    return t.toLowerCase();
  }
}
