// lib/pages/splash_login.dart
import 'package:flutter/material.dart';
import '../services/app_data_manager.dart';
import 'main_screen.dart';

class SplashLogin extends StatelessWidget {
  final int userId;
  final String username;

  const SplashLogin({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppDataManager().loadFavorites(userId), // ✅ Charge UNIQUEMENT les favoris
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
                    'Chargement des favoris...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // ✅ Fallback : utilise les favoris locaux si erreur, puis redirige vers MainScreen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  username: username,
                  userId: userId,
                ),
              ),
            );
          });
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 40),
                  SizedBox(height: 20),
                  Text(
                    'Impossible de charger les favoris.\nUtilisation des données locales.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else {
          // ✅ Redirige vers MainScreen une fois les favoris chargés
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  username: username,
                  userId: userId,
                ),
              ),
            );
          });
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
        }
      },
    );
  }
}