import 'package:firebase_messaging/firebase_messaging.dart';

/// Centralise l'initialisation FCM :
/// demande de permission, abonnement au topic "all_users" (requis pour recevoir
/// les notifications SOS / perdu / hype envoyées à tous les utilisateurs),
/// et configuration de l'affichage en avant-plan sur iOS.
///
/// À appeler une fois par session, après la connexion de l'utilisateur
/// (ex. depuis SplashLogin._init()).
class FcmService {
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Demande la permission d'afficher des notifications.
    // → Affiche le dialog système sur iOS et Android 13+.
    // → No-op sur Android ≤ 12 (permission accordée par défaut).
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Abonne l'appareil au topic FCM "all_users".
    // Le backend envoie SOS / perdu / hype à ce topic → tous les appareils abonnés reçoivent.
    await messaging.subscribeToTopic('all_users');

    // iOS : affiche les notifications (bannière + son + badge) même quand l'app est au premier plan.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
