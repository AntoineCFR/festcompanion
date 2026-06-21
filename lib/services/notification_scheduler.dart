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
      // Tap sur un rappel local (app vivante) : le payload porte l'onglet cible
      // (ex. 'live' pour un rappel de set) → consommé par MainScreen.
      onDidReceiveNotificationResponse: (response) {
        final p = response.payload;
        if (p != null && p.isNotEmpty) pendingTabIntent.value = p;
      },
    );

    // App LANCÉE depuis l'état terminé en tapant un rappel local : le callback
    // ci-dessus ne se déclenche pas dans ce cas → on lit les détails de lancement.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final p = launch?.notificationResponse?.payload;
        if (p != null && p.isNotEmpty) pendingTabIntent.value = p;
      }
    } catch (_) {}

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
            '⏰ Get ready',
            'Le set de ${item.dj} va bientôt débuter sur ${item.stage}.',
            when,
            high: true,
            payload: 'live', // tap → onglet Live (now/next)
          );
        }
      }

      // ── (E) Hydratation : toutes les 2 h, message thématique par jour ────
      // Chaque jour suit sa liste (chameau / cactus / fruits), du sérieux au
      // délire ; le dernier message se répète si la journée a plus de créneaux.
      for (final slot in _hydrationSlots(location)) {
        if (slot.when.isAfter(now)) {
          await _schedule(
            id++,
            slot.title,
            slot.body,
            slot.when,
            high: false,
            payload: 'events', // tap → onglet Events (déclarer sa conso)
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
    String? payload,
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
      payload: payload,
    );
  }

  /// Créneaux d'hydratation : pour chaque jour de festival, du 1er set + 2 h
  /// jusqu'au dernier set, par pas de 2 h. Chaque créneau porte son message
  /// thématique (selon le rang du jour + sa position dans la journée).
  static List<({tz.TZDateTime when, String title, String body})> _hydrationSlots(
      tz.Location loc) {
    final result = <({tz.TZDateTime when, String title, String body})>[];

    // Grouper par jour + retenir day_int pour ordonner les jours (ordinal 0/1/2).
    final byDay = <String, List<TimetableItem>>{};
    final dayInt = <String, int>{};
    for (final t in AppDataManager().timetable) {
      byDay.putIfAbsent(t.day, () => []).add(t);
      dayInt.putIfAbsent(t.day, () => t.dayInt);
    }
    final days = byDay.keys.toList()
      ..sort((a, b) => dayInt[a]!.compareTo(dayInt[b]!));

    for (var ordinal = 0; ordinal < days.length; ordinal++) {
      final items = byDay[days[ordinal]]!;
      if (items.isEmpty) continue;
      final firstStart =
          items.map((t) => t.startTime).reduce((a, b) => a.isBefore(b) ? a : b);
      final lastEnd =
          items.map((t) => t.endTime).reduce((a, b) => a.isAfter(b) ? a : b);
      final messages = _hydrationMessages(ordinal);

      var slot = firstStart.add(const Duration(hours: 2));
      var i = 0;
      while (!slot.isAfter(lastEnd)) {
        // Plus de créneaux que de messages → on répète le dernier (la chute).
        final msg = messages[i < messages.length ? i : messages.length - 1];
        result.add((when: _wallClock(loc, slot), title: msg.$1, body: msg.$2));
        slot = slot.add(const Duration(hours: 2));
        i++;
      }
    }
    return result;
  }

  /// Messages d'hydratation par jour de festival (ordinal 0/1/2) : du sérieux
  /// au délire. Chameau (vendredi), cactus (samedi), fun facts fruités
  /// (dimanche). Au-delà de 3 jours → on réutilise la liste fruits.
  static List<(String, String)> _hydrationMessages(int ordinal) {
    switch (ordinal) {
      case 0:
        return _hydrationCamel;
      case 1:
        return _hydrationCactus;
      default:
        return _hydrationFruits;
    }
  }

  static const List<(String, String)> _hydrationCamel = [
    ('Hydratation 💧',
        'Pensez à vous hydrater. Un verre d\'eau maintenant, c\'est la base.'),
    ('Hydratation 💧',
        'Petit rappel : alterne l\'eau et… le reste. Ton réveil te dira merci.'),
    ('Toujours pas bu ? 💧',
        'Allez, un verre d\'eau. Tu vas pas fondre… quoique, vu le dancefloor.'),
    ('Check hydrique 💦',
        'Ton cerveau est à 75 % d\'eau. Là, surtout à 75 % de kick. Rééquilibre.'),
    ('Mode chameau activé 🐪',
        'Un chameau tient 15 jours sans boire. Toi, jusqu\'au prochain drop ? Triche : bois de l\'eau.'),
    ('🐫 Dépêche',
        'Un chameau refuse de te suivre, jugeant ton hydratation « irresponsable ». Répare ça.'),
    ('🐫💧 Le mot du chameau',
        '« Même MOI je bois plus que toi. » — signé : le chameau. File boire.'),
  ];

  static const List<(String, String)> _hydrationCactus = [
    ('Hydratation 💧',
        'Jour 2, on n\'oublie pas l\'essentiel : un grand verre d\'eau.'),
    ('Rappel hydrique 💧',
        'La nuit est longue. Une gorgée d\'eau entre deux sets, et ça repart.'),
    ('Petit point sécheresse 🌵',
        'Tu commences à piquer comme un cactus. Un verre d\'eau, vite.'),
    ('Alerte épines 🌵',
        'À ce rythme tu vas faire des fleurs jaunes. Arrose-toi (de l\'eau, hein).'),
    ('Niveau désertique 🏜️',
        'Même le cactus a soif en te regardant. Bois, par solidarité.'),
    ('🌵 Le cactus s\'inquiète',
        '« Lui au moins il stocke l\'eau », soupire le cactus, déçu. Prouve-lui le contraire.'),
    ('🌵💧 Conseil de cactus',
        '« J\'ai tenu 100 ans dans le désert, toi tu tiens pas un samedi ? » Bois.'),
    ('🌵💀 Le cactus a renoncé',
        '« 16 h que j\'attends que tu boives. J\'ai mes limites. » Il s\'en va en roulant comme un fagot de western. Sauve l\'honneur : un verre d\'eau.'),
  ];

  static const List<(String, String)> _hydrationFruits = [
    ('Hydratation 💧',
        'Dernier jour, on tient la distance : un grand verre d\'eau, régulièrement.'),
    ('Le saviez-vous ? 🍉',
        'La pastèque, c\'est 92 % d\'eau ! Dommage, pas un seul stand pastèque sur le site. Va pour de l\'eau.'),
    ('On raconte… 🍓',
        'Il paraît qu\'il y aurait un carré de fraises (91 % d\'eau !) quelque part du côté du Comfort Camping… Beaucoup trop loin. Un verre d\'eau fera l\'affaire.'),
    ('Fun fact 🍈',
        'Le melon, champion de l\'hydratation. Encore faut-il en trouver un. Spoiler : non. → de l\'eau.'),
    ('Le saviez-vous ? 🥥',
        'L\'eau de coco, reine de la récup\' ! Mais bon, le cocotier aux Pays-Bas… on attend toujours. → de l\'eau.'),
    ('Édition collector 🐉',
        'Le fruit du dragon : 90 % d\'eau, 100 % introuvable sur ce continent un dimanche. Tu connais la chanson : de l\'eau.'),
    ('Conclusion scientifique 💧',
        'Bilan du week-end : 0 fruit trouvé. La science tranche — bois de l\'eau, c\'est juste plus simple.'),
  ];

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
