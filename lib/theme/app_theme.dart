import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Palette d'un thème (tous sombres : le texte clair reste valide partout).
class AppPalette {
  final String id;
  final String name;
  final Color background;  // fond d'écran (scaffold)
  final Color surface;     // cartes, app bars
  final Color surfaceAlt;  // surfaces secondaires (bandeaux, pickers)
  final Color accent;      // couleur de marque (sélection, favoris, boutons)
  final Color onAccent;    // texte/icône posé sur l'accent

  const AppPalette({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.onAccent,
  });
}

/// Gestion centralisée du thème de l'app.
///
/// - `apply` change la palette courante et notifie l'app (rebuild via [revision]).
/// - Le choix est persisté : `'auto'` = suit le festival, sinon un id de palette.
class AppTheme {
  AppTheme._();

  // ── Palettes ────────────────────────────────────────────────────────────
  static const extrema = AppPalette(
    id: 'extrema',
    name: 'Extrema Outdoor 2026',
    background: Color(0xFF212121), // ~ grey[900] (look actuel)
    surface: Color(0xFF424242),    // ~ grey[800]
    surfaceAlt: Color(0xFF303030), // ~ grey[850]
    accent: Color(0xFF7851A9),     // améthyste
    onAccent: Colors.white,
  );

  static const awakenings = AppPalette(
    id: 'awakenings',
    name: 'Awakenings Festival 2026',
    background: Color(0xFF0E0E0E),
    surface: Color(0xFF1C1C1C),
    surfaceAlt: Color(0xFF262626),
    accent: Color(0xFFE10600), // rouge Awakenings
    onAccent: Colors.white,
  );

  static const minimaliste = AppPalette(
    id: 'minimaliste',
    name: 'Minimaliste',
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceAlt: Color(0xFF2A2A2A),
    accent: Color(0xFF546E7A), // ardoise neutre (peu de couleur)
    onAccent: Colors.white,
  );

  static const techno = AppPalette(
    id: 'techno',
    name: 'Techno',
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF161616),
    surfaceAlt: Color(0xFF1F1F1F),
    accent: Color(0xFF2E7D32), // vert sombre
    onAccent: Colors.white,
  );

  static const List<AppPalette> all = [extrema, awakenings, minimaliste, techno];

  // ── État courant ──────────────────────────────────────────────────────────
  static AppPalette _current = extrema;
  static String _choice = 'auto';            // 'auto' ou un id de palette
  static String? _festivalSlug;              // festival courant (pour le mode auto)

  static AppPalette get current => _current;
  static String get choice => _choice;

  // Getters de commodité (utilisés dans toute l'UI)
  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get surfaceAlt => _current.surfaceAlt;
  static Color get accent => _current.accent;
  static Color get onAccent => _current.onAccent;

  /// Incrémenté à chaque changement de thème → déclenche le rebuild de l'app.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => extrema);

  /// Thème par défaut associé à un festival (déduit du slug).
  static String defaultThemeIdForSlug(String? slug) {
    final s = (slug ?? '').toLowerCase();
    if (s.contains('awakenings')) return awakenings.id;
    if (s.contains('extrema')) return extrema.id;
    return extrema.id;
  }

  static void _applyFromChoice() {
    final target = _choice == 'auto'
        ? byId(defaultThemeIdForSlug(_festivalSlug))
        : byId(_choice);
    if (target.id != _current.id) {
      _current = target;
      revision.value++;
    }
  }

  /// À appeler au démarrage : charge le choix persisté et applique le thème.
  static Future<void> init(String? festivalSlug) async {
    _festivalSlug = festivalSlug;
    final prefs = await SharedPreferences.getInstance();
    _choice = prefs.getString('themeChoice') ?? 'auto';
    _applyFromChoice();
  }

  /// À appeler quand le festival sélectionné change (mode auto).
  static void onFestivalChanged(String? festivalSlug) {
    _festivalSlug = festivalSlug;
    _applyFromChoice();
  }

  /// Choix utilisateur depuis le menu Thème ('auto' ou un id de palette).
  static Future<void> setChoice(String choice) async {
    _choice = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeChoice', choice);
    _applyFromChoice();
  }

  /// ThemeData Material dérivé de la palette (défauts cohérents même pour les
  /// widgets qui s'appuient sur Theme.of(context)).
  static ThemeData themeData() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: _current.background,
      canvasColor: _current.background,
      colorScheme: base.colorScheme.copyWith(
        primary: _current.accent,
        secondary: _current.accent,
        surface: _current.surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _current.surface,
        foregroundColor: Colors.white,
      ),
    );
  }
}
