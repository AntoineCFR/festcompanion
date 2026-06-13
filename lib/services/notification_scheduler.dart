import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/timetable_item.dart';
import 'app_data_manager.dart';

/// Notifications LOCALES programmées (aucun serveur, fonctionne hors-ligne et
/// app fermée) :
///  - (D) rappel ~10 min avant chaque set que l'utilisateur a mis en favori ;
///  - (E) rappel d'hydratation toutes les 2 h, du 1er au dernier set de chaque
///        jour de festival.
///
/// On planifie aux heures « murales » du festival (via son fuseau IANA), ce qui
/// reste correct quel que soit le fuseau de l'appareil. Mode Android « inexact »
/// → pas besoin de la permission d'alarme exacte (déclenchement à quelques
/// minutes près, sans conséquence pour des rappels festival).
class NotificationScheduler {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> _ensureInit() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _ready = true;
  }

  /// Annule puis replanifie tous les rappels pour [userId]. À appeler après le
  /// chargement des données et à chaque changement de favoris.
  static Future<void> rescheduleAll(int userId) async {
    try {
      await _ensureInit();

      final festival = AppDataManager().selectedFestival;
      if (festival == null) return;
      final location = _safeLocation(festival.timezone);
      if (location == null) return;

      // Ardoise propre : évite d'accumuler des rappels obsolètes.
      await _plugin.cancelAll();

      final now = tz.TZDateTime.now(location);
      var id = 1000000;

      // ── (D) Sets favoris : ~10 min avant le début ────────────────────────
      final favIds = AppDataManager().favoriteSetIds;
      final byId = {for (final t in AppDataManager().timetable) t.setId: t};
      for (final setId in favIds) {
        final item = byId[setId];
        if (item == null) continue;
        final when = _wallClock(
          location,
          item.startTime.subtract(const Duration(minutes: 10)),
        );
        if (when.isAfter(now)) {
          await _schedule(
            id++,
            'Ça commence bientôt !',
            'Le set de ${item.dj} va bientôt débuter sur ${item.stage}.',
            when,
            high: true,
          );
        }
      }

      // ── (E) Hydratation : toutes les 2 h, par jour ───────────────────────
      for (final slot in _hydrationSlots(location)) {
        if (slot.isAfter(now)) {
          await _schedule(
            id++,
            'Hydratation 💧',
            'Pense à boire de l\'eau !',
            slot,
            high: false,
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationScheduler] reschedule échoué : $e');
    }
  }

  /// Annule tous les rappels (ex. à la déconnexion / changement de festival).
  static Future<void> cancelAll() async {
    try {
      await _ensureInit();
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static Future<void> _schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when, {
    required bool high,
  }) async {
    final android = high
        ? const AndroidNotificationDetails(
            'set_reminders',
            'Rappels de sets',
            channelDescription: 'Rappels avant tes sets favoris',
            importance: Importance.high,
            priority: Priority.high,
          )
        : const AndroidNotificationDetails(
            'hydration',
            'Hydratation',
            channelDescription: 'Rappels d\'hydratation',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(android: android, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Créneaux d'hydratation : pour chaque jour de festival, du 1er set + 2 h
  /// jusqu'au dernier set, par pas de 2 h.
  static List<tz.TZDateTime> _hydrationSlots(tz.Location loc) {
    final slots = <tz.TZDateTime>[];
    final byDay = <String, List<TimetableItem>>{};
    for (final t in AppDataManager().timetable) {
      byDay.putIfAbsent(t.day, () => []).add(t);
    }
    for (final items in byDay.values) {
      if (items.isEmpty) continue;
      final firstStart =
          items.map((t) => t.startTime).reduce((a, b) => a.isBefore(b) ? a : b);
      final lastEnd =
          items.map((t) => t.endTime).reduce((a, b) => a.isAfter(b) ? a : b);
      var slot = firstStart.add(const Duration(hours: 2));
      while (!slot.isAfter(lastEnd)) {
        slots.add(_wallClock(loc, slot));
        slot = slot.add(const Duration(hours: 2));
      }
    }
    return slots;
  }

  /// Convertit une DateTime « heure murale du festival » en TZDateTime dans le
  /// fuseau du festival (on ne garde que les composantes y/m/j/h/min).
  static tz.TZDateTime _wallClock(tz.Location loc, DateTime dt) {
    return tz.TZDateTime(loc, dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  static tz.Location? _safeLocation(String name) {
    try {
      return tz.getLocation(name);
    } catch (_) {
      return null;
    }
  }
}
