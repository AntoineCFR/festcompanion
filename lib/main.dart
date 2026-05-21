// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/app_data_manager.dart';
import 'services/local_storage_service.dart';
import 'pages/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── Handler FCM background ────────────────────────────────────────────────────
// Doit être une fonction TOP-LEVEL (pas une méthode de classe) annotée vm:entry-point.
// Appelée dans un isolate séparé quand l'app est fermée ou en arrière-plan et
// qu'un message FCM arrive. La notification est affichée automatiquement par l'OS
// à partir du payload — aucun traitement supplémentaire nécessaire ici.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: type=${message.data['event_type']}');
}

// ── Clés globales ─────────────────────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService().init(); // SharedPreferences avant tout

  // Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enregistre le handler pour les messages reçus quand l'app est fermée/en fond.
  // Doit être appelé avant runApp().
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Souscrit immédiatement au topic "all_users" — sans attendre le login.
  // Fait ici car : (1) ne dépend pas de l'utilisateur, (2) doit être actif
  // même si l'app est fermée, (3) se réessaie à chaque démarrage si ça a
  // raté la fois précédente.
  await FirebaseMessaging.instance.subscribeToTopic('all_users');

  AppDataManager().setScaffoldMessengerKey(scaffoldMessengerKey);

  runApp(const MyApp());
}

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
    // Le listener foreground FCM est géré dans FcmService.init()
    // (appelé depuis SplashLogin._init() après connexion).
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AppDataManager().syncFavorites().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Extrema Outdoor 2026',
      theme: ThemeData.dark(),
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
