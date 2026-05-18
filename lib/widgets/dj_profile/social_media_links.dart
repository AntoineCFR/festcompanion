import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../helpers/url_launcher_helper.dart';

class SocialMediaItem {
  final String name;
  final FaIconData icon;  // <-- Changé de IconData à FaIconData
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Réseaux sociaux :',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IconButton(
                  icon: FaIcon(item.icon),  // item.icon est maintenant de type FaIconData
                  iconSize: 32,
                  onPressed: () => launchUrlWithFallback(context, item.url),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}