import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_data_manager.dart';
import '../pages/journal_page.dart';
import '../helpers/profile_helper.dart';

/// Centralise l'initialisation FCM et l'affichage des notifications.
///
/// - Demande les permissions système (iOS 13+ / Android 13+)
/// - Abonne l'appareil au topic "all_users"
/// - Affiche une notification locale (bannière système) même quand l'app
///   est au premier plan, via flutter_local_notifications.
///   Cela garantit un comportement cohérent sur Android ET iOS.
///
/// À appeler une fois par session, après la connexion de l'utilisateur
/// (ex. depuis SplashLogin._init()).
class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Demande la permission d'afficher des notifications.
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── DEBUG token FCM ───────────────────────────────────────────────────────
    // Affiche le token dans la console pour tester depuis Firebase Console.
    // À SUPPRIMER avant la release publique.
    try {
      final token = await messaging.getToken();
      debugPrint('╔══════════════════════════════════════════════════════╗');
      debugPrint('║  FCM TOKEN (pour test Firebase Console)              ║');
      debugPrint('║  $token');
      debugPrint('╚══════════════════════════════════════════════════════╝');
    } catch (e) {
      debugPrint('[FCM] Impossible de récupérer le token: $e');
    }
    // ─────────────────────────────────────────────────────────────────────────

    // Note : subscribeToTopic('all_users') est fait dans main() au démarrage,
    // avant même le login, pour garantir la souscription même app fermée.

    // On désactive l'affichage automatique iOS en foreground car on gère
    // nous-mêmes l'affichage via flutter_local_notifications (Android + iOS).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Initialise le plugin de notifications locales.
    await _initLocalNotifications();

    // Écoute les messages FCM reçus quand l'app est au premier plan.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Quand l'utilisateur TAPE une notification (app en fond) → on traite
    // la demande de position. C'est le chemin fiable sur iOS.
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    // App lancée depuis l'état terminé en tapant une notification.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpened(initialMessage);
    }
  }

  /// Une alerte "perdu" (ou un flag explicite) demande à chacun de remonter
  /// sa position. On ne le fait que si l'app est active/ouverte (pas de
  /// localisation en arrière-plan) et si le partage est activé.
  static bool _wantsLocation(RemoteMessage message) {
    return message.data['request_location'] == 'true' ||
        message.data['event_type'] == 'perdu';
  }

  static Future<void> _reportLocationIfRequested(RemoteMessage message) async {
    if (!_wantsLocation(message)) return;
    final userId = AppDataManager().userId;
    if (userId != null) {
      await ProfileHelper.refreshLocationIfEnabled(userId);
    }
  }

  static void _onMessageOpened(RemoteMessage message) {
    _reportLocationIfRequested(message);
    final eventType = message.data['event_type'];
    if (eventType == 'perdu') {
      AppDataManager().loadUsers().ignore();
    } else if (eventType == 'journal') {
      // Notif programmée (push quotidienne, vanne, décompte, clôture) → Journal.
      _openJournal();
    }
  }

  /// Ouvre la page Journal via le navigateur global. Différé d'une frame :
  /// au lancement depuis l'état terminé (getInitialMessage), le navigateur peut
  /// ne pas être encore monté à l'instant du tap.
  static void _openJournal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const JournalPage()),
      );
    });
  }

  static Future<void> _initLocalNotifications() async {
    // Android : utilise l'icône du launcher comme icône de notification.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS : pas de configuration spéciale à l'init — les options sont
    // passées à chaque show() via DarwinNotificationDetails.
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      // Tap sur une notif AFFICHÉE AU PREMIER PLAN (notif locale) : le payload
      // porte l'event_type → on route vers le Journal pour les notifs programmées.
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'journal') _openJournal();
      },
    );
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final eventType = message.data['event_type'] ?? '';

    // ── Logique métier ────────────────────────────────────────────────────────
    // Si une MAJ de position est demandée (alerte "perdu"), on remonte la nôtre
    // (app au premier plan → fix possible sans permission background).
    await _reportLocationIfRequested(message);

    // Quand quelqu'un se déclare "perdu", on rafraîchit la liste des utilisateurs
    // pour afficher les positions à jour.
    if (eventType == 'perdu') {
      AppDataManager().loadUsers().ignore();
    }

    // ── Affichage notification locale ─────────────────────────────────────────
    // Visible même app au premier plan, sur Android et iOS.
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final isSos = eventType == 'sos';

    await _localNotifications.show(
      // ID unique basé sur le hash du message (évite les doublons).
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          // Réutilise les channels déjà créés dans MainActivity.kt.
          isSos ? 'sos_channel' : 'festival_channel',
          isSos ? 'SOS & Urgences' : 'Événements Festival',
          importance: isSos ? Importance.high : Importance.defaultImportance,
          priority: isSos ? Priority.high : Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Payload = event_type → permet au tap (onDidReceiveNotificationResponse)
      // de router vers le Journal pour les notifs programmées.
      payload: eventType,
    );
  }
}
