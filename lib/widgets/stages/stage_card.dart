import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/stage_model.dart';
import '../../services/app_data_manager.dart';

/// Carte d'une scène, présentée comme une tuile élégante et extensible.
///
/// - Repliée : pastille de la scène, nom, statut (point de ralliement défini ?)
///   et un bouton « itinéraire » direct.
/// - Dépliée : mini-plan schématique de la zone (4 coins + ralliement au centre),
///   bouton « Ouvrir dans Google Maps », et — pour les admins seulement — les
///   boutons de configuration des coins et le détail des coordonnées.
class StageCard extends StatefulWidget {
  final Stage stage;
  final bool isAdmin;
  final Function(String, String) onSetCoordinates;
  /// Saisie manuelle : (nom de scène, coin, latitude, longitude).
  final Function(String, String, double, double) onSetCoordinatesManual;
  final Function(double, double) onOpenInMaps;
  final bool initiallyExpanded;

  const StageCard({
    super.key,
    required this.stage,
    required this.isAdmin,
    required this.onSetCoordinates,
    required this.onSetCoordinatesManual,
    required this.onOpenInMaps,
    this.initiallyExpanded = false,
  });

  @override
  State<StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<StageCard> {
  late bool _expanded = widget.initiallyExpanded;

  Stage get stage => widget.stage;

  bool get _rallyConfigured =>
      stage.latRallyPoint != 0 || stage.lonRallyPoint != 0;

  /// Abréviation de la scène pour la pastille. La règle dépend du festival :
  /// - **Awakenings** : les scènes sont toutes « Area X » → on garde la 1re
  ///   lettre du 2e mot (V, B, C, H…).
  /// - **Extrema** (et défaut) : initiales des deux premiers mots
  ///   (« District 4 » → « D4 », « Area Sud » → « AS »), ou les 2 premières
  ///   lettres d'un nom en un seul mot.
  String get _initial {
    final name = stage.stage.trim();
    if (name.isEmpty) return '?';
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final slug = (AppDataManager().selectedFestival?.slug ?? '').toLowerCase();
    if (slug.contains('awakenings')) {
      return (words.length >= 2 ? words[1][0] : words[0][0]).toUpperCase();
    }

    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: _buildExpanded(),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }

  // ── En-tête (toujours visible) ──────────────────────────────────────────────
  Widget _buildHeader() {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _avatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.stage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _rallyConfigured
                            ? const Color(0xFF4CAF50)
                            : Colors.white24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _rallyConfigured
                            ? 'Point de ralliement défini'
                            : 'Pas encore configurée',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_rallyConfigured)
              _RoundIconButton(
                icon: Icons.near_me,
                tooltip: 'Itinéraire vers le point de ralliement',
                background: AppTheme.accent,
                foreground: AppTheme.onAccent,
                onTap: () =>
                    widget.onOpenInMaps(stage.latRallyPoint, stage.lonRallyPoint),
              ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accent,
            Color.alphaBlend(Colors.black38, AppTheme.accent),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: AppTheme.onAccent,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  // ── Contenu déplié ──────────────────────────────────────────────────────────
  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildZoneMap(),
          const SizedBox(height: 16),
          if (_rallyConfigured)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => widget.onOpenInMaps(
                    stage.latRallyPoint, stage.lonRallyPoint),
                icon: const Icon(Icons.directions),
                label: const Text('Ouvrir dans Google Maps'),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Cette scène n\'a pas encore de point de ralliement.',
                style: TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 18),
            _buildAdminSection(),
          ],
        ],
      ),
    );
  }

  // ── Mini-plan schématique de la zone ────────────────────────────────────────
  Widget _buildZoneMap() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceAlt,
              Color.alphaBlend(Colors.black38, AppTheme.surfaceAlt),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // La zone (rectangle teinté accent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.accent.withValues(alpha: 0.06),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Align(alignment: Alignment.topLeft, child: _corner('AVG')),
            Align(alignment: Alignment.topRight, child: _corner('AVD')),
            Align(alignment: Alignment.bottomLeft, child: _corner('ARG')),
            Align(alignment: Alignment.bottomRight, child: _corner('ARD')),
            Center(child: _rallyMarker()),
          ],
        ),
      ),
    );
  }

  Widget _corner(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _rallyMarker() {
    final color = _rallyConfigured ? AppTheme.accent : Colors.white30;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place, color: color, size: 30),
        Text(
          'Ralliement',
          style: TextStyle(
            color: _rallyConfigured ? Colors.white : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Section admin (configuration) ───────────────────────────────────────────
  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              'Configuration (admin)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Place-toi à l\'endroit voulu puis enregistre-le, ou saisis les '
          'coordonnées manuellement.',
          style: TextStyle(color: Colors.white38, fontSize: 11.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _setChip('Avant-G.', 'avg'),
            _setChip('Avant-D.', 'avd'),
            _setChip('Arrière-G.', 'arg'),
            _setChip('Arrière-D.', 'ard'),
            _setChip('Ralliement', 'rally', highlight: true),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _openManualEntry,
            icon: const Icon(Icons.edit_location_alt, size: 16),
            label: const Text('Saisie manuelle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildCoordTable(),
      ],
    );
  }

  Widget _setChip(String label, String corner, {bool highlight = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => widget.onSetCoordinates(stage.stage, corner),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.accent.withValues(alpha: 0.18)
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight ? AppTheme.accent : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.my_location,
                size: 14, color: highlight ? AppTheme.accent : Colors.white60),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  /// Coordonnées actuelles d'un coin/ralliement (pour pré-remplir la saisie).
  (double, double) _cornerValue(String corner) {
    switch (corner) {
      case 'avg':
        return (stage.latAvg, stage.lonAvg);
      case 'avd':
        return (stage.latAvd, stage.lonAvd);
      case 'arg':
        return (stage.latArg, stage.lonArg);
      case 'ard':
        return (stage.latArd, stage.lonArd);
      case 'rally':
        return (stage.latRallyPoint, stage.lonRallyPoint);
    }
    return (0, 0);
  }

  /// Dialog de saisie manuelle : choix du coin + latitude/longitude tapées.
  /// Pré-remplit avec la valeur existante du coin si elle est définie.
  Future<void> _openManualEntry() async {
    String corner = 'rally';
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    String? error;

    void prefill() {
      final (lat, lng) = _cornerValue(corner);
      final isSet = lat != 0 || lng != 0;
      latCtrl.text = isSet ? lat.toStringAsFixed(6) : '';
      lngCtrl.text = isSet ? lng.toStringAsFixed(6) : '';
    }

    prefill();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            'Saisie manuelle · ${stage.stage}',
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: corner,
                  isExpanded: true,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'avg', child: Text('Avant-Gauche')),
                    DropdownMenuItem(value: 'avd', child: Text('Avant-Droit')),
                    DropdownMenuItem(
                        value: 'arg', child: Text('Arrière-Gauche')),
                    DropdownMenuItem(value: 'ard', child: Text('Arrière-Droit')),
                    DropdownMenuItem(value: 'rally', child: Text('Ralliement')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    corner = v;
                    prefill();
                    setDialogState(() => error = null);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: lngCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final lat =
                    double.tryParse(latCtrl.text.trim().replaceAll(',', '.'));
                final lng =
                    double.tryParse(lngCtrl.text.trim().replaceAll(',', '.'));
                if (lat == null ||
                    lng == null ||
                    lat < -90 ||
                    lat > 90 ||
                    lng < -180 ||
                    lng > 180) {
                  setDialogState(() => error =
                      'Coordonnées invalides (lat ∈ [-90, 90], lng ∈ [-180, 180]).');
                  return;
                }
                Navigator.pop(ctx);
                widget.onSetCoordinatesManual(stage.stage, corner, lat, lng);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    latCtrl.dispose();
    lngCtrl.dispose();
  }

  Widget _buildCoordTable() {
    Widget row(String label, double lat, double lng, {bool divider = false}) {
      final isSet = lat != 0 || lng != 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
            ),
            Expanded(
              child: Text(
                isSet
                    ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                    : '—',
                style: TextStyle(
                  color: isSet ? Colors.white : Colors.white30,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          row('Avant-G.', stage.latAvg, stage.lonAvg),
          row('Avant-D.', stage.latAvd, stage.lonAvd),
          row('Arrière-G.', stage.latArg, stage.lonArg),
          row('Arrière-D.', stage.latArd, stage.lonArd),
          const Divider(color: Colors.white12, height: 16),
          row('Ralliement', stage.latRallyPoint, stage.lonRallyPoint),
        ],
      ),
    );
  }
}

// ── Bouton rond compact ───────────────────────────────────────────────────────
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}
