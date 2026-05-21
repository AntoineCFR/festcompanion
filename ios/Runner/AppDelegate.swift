import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ── APNs registration ──────────────────────────────────────────────────────
    // Obligatoire pour que FCM puisse envoyer des push sur iOS.
    // La demande de permission (dialog utilisateur) est gérée côté Flutter
    // via FcmService.init() → FirebaseMessaging.requestPermission().
    application.registerForRemoteNotifications()

    // Note : WorkManager (background geoloc) n'est pas configuré sur iOS car
    // le plugin workmanager_apple ne supporte pas encore SPM (Swift Package Manager).
    // Le background geoloc fonctionne sur Android via WorkManager.
    // Sur iOS, seule la mise à jour manuelle (bouton rafraîchir) est disponible.

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // ── Affichage des notifications en avant-plan (iOS) ────────────────────────
  // Quand l'app est ouverte et qu'une notification arrive, iOS l'affiche
  // normalement en silence. Cette méthode force l'affichage en bannière + son.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound])
  }
}
