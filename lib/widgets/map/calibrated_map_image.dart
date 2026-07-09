import 'package:flutter/material.dart';

/// Affiche [assetPath] à son ratio naturel (résolu à l'exécution — pas besoin
/// de connaître les dimensions du fichier à l'avance, donc pas de distorsion
/// même si l'image est remplacée) et délègue à [overlayBuilder] la
/// construction de ce qui est posé dessus, avec la taille réellement rendue
/// (pour convertir des coordonnées fractionnaires 0-1 en pixels). Partagé par
/// `MapPage` (marqueurs des avatars) et l'écran de calibration admin (ancre +
/// rayon d'exclusion éditables).
class CalibratedMapImage extends StatefulWidget {
  final String assetPath;
  final Widget Function(Size imageSize) overlayBuilder;

  const CalibratedMapImage({
    super.key,
    required this.assetPath,
    required this.overlayBuilder,
  });

  @override
  State<CalibratedMapImage> createState() => _CalibratedMapImageState();
}

class _CalibratedMapImageState extends State<CalibratedMapImage> {
  Size? _naturalSize;

  @override
  void initState() {
    super.initState();
    final stream = AssetImage(widget.assetPath).resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _naturalSize =
            Size(info.image.width.toDouble(), info.image.height.toDouble());
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    final natural = _naturalSize;
    if (natural == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      );
    }
    return AspectRatio(
      aspectRatio: natural.width / natural.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final renderedSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(widget.assetPath, fit: BoxFit.fill),
              widget.overlayBuilder(renderedSize),
            ],
          );
        },
      ),
    );
  }
}
