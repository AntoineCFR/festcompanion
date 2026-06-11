import '../theme/app_theme.dart';
// lib/pages/splash_login.dart
import 'package:flutter/material.dart';
import '../services/app_data_manager.dart';
import '../services/fcm_service.dart';
import '../helpers/profile_helper.dart';
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
  /// 1. Favoris de l'utilisateur
  /// 2. Initialisation FCM (permissions + écouteurs de notifications)
  /// 3. MAJ de position à l'ouverture (best-effort, si le partage est activé)
  Future<void> _init() async {
    await AppDataManager().loadFavorites(widget.userId);
    await FcmService.init();
    // Fire-and-forget : ne bloque pas l'entrée dans l'app.
    ProfileHelper.refreshLocationIfEnabled(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.background,
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
          backgroundColor: AppTheme.background,
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
