// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/app_data_manager.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';
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
  // ⚠️ DOIT être la toute première instruction : dotenv.load et l'accès aux
  // assets passent par rootBundle, qui exige le binding initialisé. L'appeler
  // après provoquait une exception au démarrage sur iOS → écran blanc.
  WidgetsFlutterBinding.ensureInitialized();

  // .env : un échec (asset absent, etc.) ne doit JAMAIS bloquer le lancement.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[main] .env non chargé (on continue) : $e');
  }

  await LocalStorageService().init(); // SharedPreferences avant tout

  // Restaure le festival sélectionné (définit ApiService.currentFestivalId).
  await AppDataManager().restoreSelectedFestival();

  // Restaure et applique le thème (mode auto = suit le festival).
  await AppTheme.init(AppDataManager().selectedFestival?.slug);

  // Firebase : si l'init échoue, on démarre quand même l'app (UI dégradée)
  // plutôt que de rester bloqué sur un écran blanc.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Handler des messages reçus app fermée/en fond. Doit être appelé avant runApp().
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    // Souscription au topic "all_users" en TÂCHE DE FOND (non awaité) : sur un
    // réseau capricieux en festival, l'awaiter ici pouvait retarder runApp()
    // et figer l'app sur un écran blanc. On réessaie à chaque démarrage.
    FirebaseMessaging.instance.subscribeToTopic('all_users').ignore();
  } catch (e) {
    debugPrint('[main] Initialisation Firebase échouée (on continue) : $e');
  }

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
    // Rebuild toute l'app quand le thème change OU quand les données chargées en
    // arrière-plan (équipe, favoris de tous, tags) arrivent → les vues qui en
    // dépendent (Tendances, Tags, mode équipe) se peuplent sans action de l'user.
    return ListenableBuilder(
      listenable: Listenable.merge(
          [AppTheme.revision, AppDataManager().dataRevision]),
      builder: (context, _) {
        return MaterialApp(
          title: AppDataManager().selectedFestival?.name ?? 'FestCompanion',
          theme: AppTheme.themeData(),
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
        );
      },
    );
  }
}
