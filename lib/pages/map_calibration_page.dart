import 'package:flutter/material.dart';

import '../models/stage_model.dart';
import '../pages/map_page.dart' show festivalMapAssets;
import '../services/app_data_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/map/calibrated_map_image.dart';

/// Écran admin : place l'ancre de [stage] sur la carte illustrée (tap) et
/// règle son rayon d'exclusion (slider), pour l'onglet Map (positionnement
/// des avatars des users autour de la scène). Accessible depuis la section
/// admin de `StageCard`.
class MapCalibrationPage extends StatefulWidget {
  final Stage stage;

  const MapCalibrationPage({super.key, required this.stage});

  @override
  State<MapCalibrationPage> createState() => _MapCalibrationPageState();
}

class _MapCalibrationPageState extends State<MapCalibrationPage> {
  late Offset _anchor = widget.stage.hasMapAnchor
      ? Offset(widget.stage.mapAnchorX!, widget.stage.mapAnchorY!)
      : const Offset(0.5, 0.5);
  late double _radius = (widget.stage.mapExclusionRadius != null &&
          widget.stage.mapExclusionRadius! > 0)
      ? widget.stage.mapExclusionRadius!
      : 0.025;
  bool _saving = false;

  void _onTapUp(TapUpDetails details, Size imageSize) {
    setState(() {
      _anchor = Offset(
        (details.localPosition.dx / imageSize.width).clamp(0.0, 1.0),
        (details.localPosition.dy / imageSize.height).clamp(0.0, 1.0),
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final stage = widget.stage;
      final coordinates = <String, dynamic>{
        'lat_avg': stage.latAvg,
        'lon_avg': stage.lonAvg,
        'lat_avd': stage.latAvd,
        'lon_avd': stage.lonAvd,
        'lat_arg': stage.latArg,
        'lon_arg': stage.lonArg,
        'lat_ard': stage.latArd,
        'lon_ard': stage.lonArd,
        'lat_rally_point': stage.latRallyPoint,
        'lon_rally_point': stage.lonRallyPoint,
        'map_anchor_x': _anchor.dx,
        'map_anchor_y': _anchor.dy,
        'map_exclusion_radius': _radius,
      };
      await AppDataManager().updateStage(stage.stage, coordinates);
      if (mounted) {
        AppDataManager().showSnackBar('Calibration enregistrée !');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final festivalId = AppDataManager().selectedFestivalId;
    final assetPath = festivalId != null ? festivalMapAssets[festivalId] : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Calibrer · ${widget.stage.stage}'),
        backgroundColor: AppTheme.surface,
      ),
      body: assetPath == null
          ? const Center(
              child: Text(
                'Carte indisponible pour ce festival.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Tape sur la carte pour placer la scène, puis ajuste le '
                    'rayon à ne pas recouvrir avec le curseur.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: CalibratedMapImage(
                        assetPath: assetPath,
                        overlayBuilder: (size) => GestureDetector(
                          onTapUp: (details) => _onTapUp(details, size),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Zone d'exclusion (fraction de la LARGEUR pour
                              // les deux axes → cercle non déformé par le
                              // ratio de l'image, cf. CalibratedMapImage).
                              Positioned(
                                left: _anchor.dx * size.width - _radius * size.width,
                                top: _anchor.dy * size.height - _radius * size.width,
                                width: _radius * size.width * 2,
                                height: _radius * size.width * 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accent.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: AppTheme.accent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: _anchor.dx * size.width - 9,
                                top: _anchor.dy * size.height - 9,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accent,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked,
                          color: Colors.white54, size: 18),
                      Expanded(
                        child: Slider(
                          value: _radius,
                          min: 0.01,
                          max: 0.15,
                          activeColor: AppTheme.accent,
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
