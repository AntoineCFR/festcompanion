import '../theme/app_theme.dart';
// lib/pages/splash_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'festival_selection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getSavedLogin(),
        builder: (context, savedUserSnapshot) {
          if (savedUserSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Vérification de la connexion...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (savedUserSnapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showSnackBar('Erreur de connexion : ${savedUserSnapshot.error}');
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 20),
                  Text(
                    'Erreur de connexion',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final savedUser = savedUserSnapshot.data;
          if (savedUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            });
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Redirection vers la page de connexion...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // ✅ Utilisateur connu → FestivalGate (sélection festival si besoin,
          //    puis chargement des données globales, puis SplashLogin).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => FestivalGate(
                    userId: savedUser['userId'] as int,
                    username: savedUser['username'] as String,
                  ),
                ),
              );
            }
          });

          return const Center(
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
          );
        },
      ),
    );
  }
}