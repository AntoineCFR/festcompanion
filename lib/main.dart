// lib/main.dart
import 'package:flutter/material.dart';
import 'services/app_data_manager.dart';
import 'services/local_storage_service.dart'; // ✅ Ajoute cet import
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService().init(); // ✅ Initialise SharedPreferences AVANT tout
  runApp(const MyApp());
}

// ✅ Crée un GlobalKey pour ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppDataManager().setScaffoldMessengerKey(scaffoldMessengerKey);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      AppDataManager().syncFavorites().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Extrema Outdoor 2026',
      theme: ThemeData.dark(),
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const SplashScreen(),
    );
  }
}