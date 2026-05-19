import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../helpers/url_launcher_helper.dart';

class SocialMediaItem {
  final String name;
  final FaIconData icon;
  final String url;

  SocialMediaItem({
    required this.name,
    required this.icon,
    required this.url,
  });
}

class SocialMediaLinks extends StatelessWidget {
  final List<SocialMediaItem> items;

  const SocialMediaLinks({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // Si aucun réseau social, retourne un widget vide
    if (items.isEmpty) return const SizedBox.shrink();

    // ✅ Retourne un Row avec UNIQUEMENT les icônes (sans texte "Réseaux sociaux")
    return Row(
      mainAxisSize: MainAxisSize.min, // Prend seulement l'espace nécessaire
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            icon: FaIcon(item.icon),
            iconSize: 32,
            onPressed: () => launchUrlWithFallback(context, item.url),
          ),
        );
      }).toList(),
    );
  }
}