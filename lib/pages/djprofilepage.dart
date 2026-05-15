import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/utils.dart'; // Import pour AppUtils.formatTime

class DJProfilePage extends StatelessWidget {
  final Map<String, dynamic> djData;

  const DJProfilePage({super.key, required this.djData});

  static String getDjImagePath(String djName) {
    final normalized = djName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'[^\w]'), '');
    return 'lib/assets/$normalized.jpg';
  }

  @override
  Widget build(BuildContext context) {
    String imagePath = getDjImagePath(djData['name']);

    final socialMedia = [
      {'name': 'spotify', 'icon': FontAwesomeIcons.spotify, 'url': djData['spotify_link']},
      {'name': 'soundcloud', 'icon': FontAwesomeIcons.soundcloud, 'url': djData['soundcloud_link']},
      {'name': 'instagram', 'icon': FontAwesomeIcons.instagram, 'url': djData['instagram_link']},
    ];

    // Filtre les réseaux sociaux avec URL valide
    final validSocialMedia = socialMedia
        .where((social) => social['url'] != null && social['url']!.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(djData['name'])),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                imagePath,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (djData['district'] != null)
                    Text(
                      '${djData['district']}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  if (djData['startTime'] != null && djData['endTime'] != null)
                    Text(
                      '${AppUtils.formatTime(djData['startTime'])} - ${AppUtils.formatTime(djData['endTime'])}',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                djData['bio'] ?? 'Aucune bio disponible.',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // Affiche le titre et les icônes UNIQUEMENT si des réseaux sont disponibles
            if (validSocialMedia.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Réseaux sociaux :',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: validSocialMedia.map((social) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: FaIcon(social['icon']),  // ✅ Crée un Widget FaIcon à partir de FaIconData
                        iconSize: 32,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          final uri = Uri.parse(social['url']!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication, // <--- Ajoute ça
                            );
                          } else if (messenger != null) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Impossible d\'ouvrir ${social['url']!}')),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}