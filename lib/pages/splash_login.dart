// lib/pages/splash_login.dart
import 'package:flutter/material.dart';
import '../services/app_data_manager.dart';
import '../services/geoloc_background_service.dart';
import '../services/fcm_service.dart';
import 'main_screen.dart';

class SplashLogin extends StatefulWidget {
  final int userId;
  final String username;

  const SplashLogin({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<SplashLogin> createState() => _SplashLoginState();
}

class _SplashLoginState extends State<SplashLogin> {
  // Stocké en champ pour éviter que FutureBuilder ne recrée le Future à chaque rebuild.
  late final Future<void> _initFuture;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  /// Charge les données de session :
  /// 1. Favoris et événements de l'utilisateur
  /// 2. Sauvegarde de l'userId pour le background isolate WorkManager
  /// 3. Initialisation de WorkManager (reprend la planification si elle était active)
  Future<void> _init() async {
    await AppDataManager().loadFavorites(widget.userId);
    await GeolocBackgroundService.saveUserId(widget.userId);
    await GeolocBackgroundService.init();
    await FcmService.init(); // permission + abonnement topic "all_users"
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Préparation de votre session...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Guard contre les navigations multiples en cas de rebuild
        if (!_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainScreen(
                    username: widget.username,
                    userId: widget.userId,
                  ),
                ),
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.grey[900],
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Prêt !',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
