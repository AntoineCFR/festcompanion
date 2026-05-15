// lib/pages/splash_screen.dart
import 'package:flutter/material.dart';
import '../services/app_data_manager.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'splash_login.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppDataManager().loadTimetable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.grey,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Chargement de la timetable...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 20),
                  Text(
                    'Erreur de chargement : ${snapshot.error}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SplashScreen()),
                      );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        } else {
          // ✅ Utilise FutureBuilder pour gérer AuthService.getSavedLogin()
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService.getSavedLogin(),
            builder: (context, savedUserSnapshot) {
              if (savedUserSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.grey,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final savedUser = savedUserSnapshot.data;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (savedUser != null) {
                  // ✅ Accède aux valeurs via les clés du Map
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => SplashLogin(
                        userId: savedUser['userId'] as int,
                        username: savedUser['username'] as String,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              });

              return const Scaffold(
                backgroundColor: Colors.grey,
                body: Center(
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
      },
    );
  }
}