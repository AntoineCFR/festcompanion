import Flutter
import UIKit
import workmanager
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

    // ── WorkManager ────────────────────────────────────────────────────────────
    WorkManagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkManagerPlugin.setConstraints(
      requiresNetworkType: .connected,
      requiresBatteryNotLow: true,
      requiresStorageNotLow: true,
      requiresCharging: false,
      requiresDeviceIdle: false
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // ── Affichage des notifications en avant-plan (iOS) ────────────────────────
  // Quand l'app est ouverte et qu'une notification arrive, iOS l'affiche
  // normalement en silence. Cette méthode force l'affichage en bannière + son.
  // Note : firebase_messaging définit lui-même le delegate via method swizzling ;
  // `super` transmet l'appel au plugin.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound])
  }
}
