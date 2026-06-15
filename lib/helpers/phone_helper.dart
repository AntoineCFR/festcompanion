/// Normalisation des numéros de téléphone français vers le format canonique
/// « +33 X XX XX XX XX ». Tolère les saisies courantes : `06 12 34 56 78`,
/// `0612345678`, `6 12 34 56 78`, `612345678`, `0033 6...`, `+33 6...`, avec
/// espaces, points ou tirets.
class PhoneHelper {
  PhoneHelper._();

  /// Retourne le numéro normalisé « +33 X XX XX XX XX », ou `null` si la saisie
  /// n'est pas un numéro français valide (9 chiffres nationaux, 1er chiffre 1-9).
  static String? normalizeFrench(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final hasPlus = s.startsWith('+');
    var digits = s.replaceAll(RegExp(r'\D'), ''); // ne garde que les chiffres

    // Retire l'indicatif international / le 0 national pour isoler les 9 chiffres.
    if (digits.startsWith('0033')) {
      digits = digits.substring(4);
    } else if (hasPlus && digits.startsWith('33')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }

    if (digits.length != 9) return null;
    if (!RegExp(r'^[1-9]').hasMatch(digits)) return null;

    return _format(digits);
  }

  /// `612345678` → `+33 6 12 34 56 78`.
  static String _format(String national9) {
    final b = StringBuffer('+33 ')..write(national9[0]);
    for (var i = 1; i < 9; i += 2) {
      b..write(' ')..write(national9.substring(i, i + 2));
    }
    return b.toString();
  }
}
