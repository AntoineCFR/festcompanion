import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';

/// Page « À propos » : affiche la version RÉELLEMENT installée de l'app (lue via
/// package_info_plus côté plateforme), pour vérifier que les utilisateurs sont
/// bien à jour.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: AppTheme.surface,
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final info = snapshot.data;
          final version = info == null
              ? 'inconnue'
              : 'Version ${info.version} (build ${info.buildNumber})';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.festival, size: 64, color: AppTheme.accent),
                  const SizedBox(height: 16),
                  Text(
                    info?.appName.isNotEmpty == true
                        ? info!.appName
                        : 'FestCompanion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    version,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ton compagnon de festival.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
