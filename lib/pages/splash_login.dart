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
      future: AppDataManager().loadFavorites(userId), // ← Utilise les données déjà chargées (ou charge depuis le serveur si besoin)
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

        // ✅ Redirige vers MainScreen (les données sont prêtes)
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
      },
    );
  }
}