import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/timetable_item.dart';
import '../models/user_model.dart';
import '../models/user_favorite.dart';
import '../models/dj_tag.dart';
import '../models/stage_model.dart';
import '../models/festival_model.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/profile_service.dart';
import '../services/notification_scheduler.dart';
import '../theme/app_theme.dart';

// ✅ Clé globale pour precacheImage
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Mode de filtrage de la liste des DJs (lineup & timetable).
enum FavoriteFilterMode {
  normal,       // Tous les DJs
  myFavorites,  // Uniquement mes favoris
  teamFavorites // Favoris d'au moins un utilisateur de l'équipe
}

/// Clés des domaines de données suivis par [AppDataManager.backgroundLoads].
/// Une page passe le(s) domaine(s) qui l'alimentent à [FestivalBackground] pour
/// afficher un bandeau « mise à jour en cours » non bloquant.
class LoadDomain {
  LoadDomain._();
  static const String timetable = 'timetable'; // line-up / horaires / accueil
  static const String team = 'team';           // membres de l'équipe
  static const String trending = 'trending';   // favoris/notes de tous (Tendances)
  static const String tags = 'tags';           // tags collaboratifs
  static const String stages = 'stages';       // scènes
  static const String events = 'events';        // événements
}

class AppDataManager {
  // Singleton
  static final AppDataManager _instance = AppDataManager._internal();
  factory AppDataManager() => _instance;
  AppDataManager._internal() {
    _timetable = [];
    _users = [];
    _photoUrls = {};
    _userFavorites = {};
    _allUserFavorites = {};
    _allFavoritesLoaded = false;
    _userEvents = [];
    _djTags = [];
    _djTagsLoaded = false;
  }

  // Festival sélectionné (état de session, partagé par toutes les pages)
  Festival? _selectedFestival;

  // Données globales (indépendantes de l'utilisateur)
  List<TimetableItem> _timetable = [];
  List<User> _users = [];
  Map<int, String?> _photoUrls = {};

  /// Incrémenté quand des photos chargées en arrière-plan deviennent
  /// disponibles → les avatars (qui l'écoutent) se redessinent sans recharger.
  final ValueNotifier<int> photosRevision = ValueNotifier<int>(0);

  /// Vrai une fois les URLs de photos résolues (1×/session). Évite de relancer
  /// les requêtes Firebase Storage à chaque `loadUsers()` (ex. ouverture de la
  /// page Équipe) → supprime le flot de `StorageUtil/getToken` dans les logs.
  bool _photosLoaded = false;

  // Données utilisateur (dépendent de l'utilisateur connecté)
  Map<int, UserFavorite> _userFavorites = {};
  Map<int, Map<int, UserFavorite>> _allUserFavorites = {};
  bool _allFavoritesLoaded = false;

  // Tags collaboratifs (tous utilisateurs, tout le festival)
  List<DjTag> _djTags = [];
  bool _djTagsLoaded = false;

  int? _userId;
  String _selectedDay = 'friday';
  FavoriteFilterMode _filterMode = FavoriteFilterMode.normal;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  // Données scènes (ex-districts)
  List<Stage> _stages = [];
  bool _isLoadingStages = false;

  // Données événements (typées avec Event)
  List<Event> _userEvents = [];
  bool _isLoadingEvents = false;

  // Setter pour le GlobalKey
  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  // Setter pour userId (utile pour events_page)
  void setUserId(int userId) {
    _userId = userId;
  }

  void showSnackBar(String message) {
    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Affiche un message d'erreur
  void _showErrorMessage(String message) {
    if (_scaffoldMessengerKey?.currentState != null) {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    debugPrint('⚠️ [AppDataManager] $message');
  }

  // ========== FESTIVAL ==========

  Festival? get selectedFestival => _selectedFestival;
  int? get selectedFestivalId => _selectedFestival?.festivalId;

  /// Restaure le festival sélectionné depuis le stockage (appelé au démarrage).
  Future<void> restoreSelectedFestival() async {
    final festival = await LocalStorageService().getSelectedFestival();
    if (festival != null) {
      _selectedFestival = festival;
      ApiService.currentFestivalId = festival.festivalId;
    }
  }

  /// Sélectionne un festival et le persiste (+ propage à ApiService).
  Future<void> setSelectedFestival(Festival festival) async {
    _selectedFestival = festival;
    ApiService.currentFestivalId = festival.festivalId;
    AppTheme.onFestivalChanged(festival.slug);  // thème auto = suit le festival
    await LocalStorageService().saveSelectedFestival(festival);
  }

  /// Désélectionne le festival courant et purge les données associées.
  Future<void> clearSelectedFestival() async {
    _selectedFestival = null;
    ApiService.currentFestivalId = null;
    AppTheme.onFestivalChanged(null);
    await LocalStorageService().clearSelectedFestival();
    NotificationScheduler.cancelAll().ignore();
    reset();
    _stages = [];
  }

  /// Jours du festival, déduits de la timetable et triés par day_int.
  List<String> get festivalDays {
    final dayOrder = <String, int>{};
    for (final item in _timetable) {
      dayOrder.putIfAbsent(item.day, () => item.dayInt);
    }
    final days = dayOrder.keys.toList()
      ..sort((a, b) => dayOrder[a]!.compareTo(dayOrder[b]!));
    return days;
  }

  /// Clé jour en anglais minuscule ('monday'..'sunday') à partir d'une date.
  static String _weekdayKey(DateTime d) {
    const keys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    return keys[d.toLocal().weekday - 1];
  }

  void _ensureValidSelectedDay() {
    final days = festivalDays;
    if (days.isEmpty) return;

    // Si on est PENDANT le festival et qu'aujourd'hui figure au line-up, on
    // sélectionne le jour courant par défaut (ex. un samedi de festival ouvre
    // directement sur « samedi »).
    final f = _selectedFestival;
    final now = DateTime.now();
    final withinFestival = f != null &&
        !now.isBefore(f.startDate) &&
        now.isBefore(f.endDate.add(const Duration(days: 1)));
    final todayKey = _weekdayKey(now);
    if (withinFestival && days.contains(todayKey)) {
      if (_selectedDay != todayKey) {
        _selectedDay = todayKey;
        LocalStorageService().saveSelectedDay(_selectedDay);
      }
      return;
    }

    // Sinon : garder le jour stocké s'il est valide, sinon le premier.
    if (!days.contains(_selectedDay)) {
      _selectedDay = days.first;
      LocalStorageService().saveSelectedDay(_selectedDay);
    }
  }

  // Getters pour les données globales
  List<TimetableItem> get timetable => _timetable;
  List<User> get users => _users;
  Map<int, String?> get photoUrls => _photoUrls;

  // Getter pour tous les favoris
  Map<int, Map<int, UserFavorite>> get allUserFavorites => _allUserFavorites;

  /// Tous les setIds qu'au moins un utilisateur a en favori.
  Set<int> get allUsersFavoriteSetIds {
    final result = <int>{};
    for (final userFavs in _allUserFavorites.values) {
      for (final entry in userFavs.entries) {
        if (entry.value.isFavorite) result.add(entry.key);
      }
    }
    return result;
  }

  /// Liste des utilisateurs ayant mis [setId] en favori.
  List<User> getUsersWhoFavorited(int setId) {
    final result = <User>[];
    for (final entry in _allUserFavorites.entries) {
      if (entry.value[setId]?.isFavorite == true) {
        result.add(_users.firstWhere(
          (u) => u.id == entry.key,
          orElse: () => User(id: entry.key, username: '?'),
        ));
      }
    }
    return result;
  }

  // ── Tags ──────────────────────────────────────────────────────────────────
  List<DjTag> get djTags => _djTags;

  /// Tags posés sur un set donné (tous utilisateurs confondus).
  List<DjTag> tagsForSet(int setId) =>
      _djTags.where((t) => t.setId == setId).toList();

  /// Libellés de tags distincts du festival, triés alphabétiquement.
  List<String> get allTagLabels {
    final labels = _djTags.map((t) => t.tag).toSet().toList()..sort();
    return labels;
  }

  /// set_ids ayant ce tag (posé par au moins un utilisateur).
  Set<int> setIdsForTag(String tag) =>
      _djTags.where((t) => t.tag == tag).map((t) => t.setId).toSet();

  // Getters pour les données utilisateur
  Set<int> get favoriteSetIds => _userFavorites.entries
      .where((entry) => entry.value.isFavorite)
      .map((entry) => entry.key)
      .toSet();

  String get selectedDay => _selectedDay;
  FavoriteFilterMode get filterMode => _filterMode;
  /// Alias pour la compatibilité des vues existantes.
  bool get showFavoritesOnly => _filterMode == FavoriteFilterMode.myFavorites;
  bool get showAllUsersFavorites => _filterMode == FavoriteFilterMode.teamFavorites;
  int? get userId => _userId;

  // Getters pour les scènes
  List<Stage> get stages => _stages;
  bool get isLoadingStages => _isLoadingStages;

  // Getters pour les événements (typé)
  List<Event> get userEvents => _userEvents;
  bool get isLoadingEvents => _isLoadingEvents;

  // Récupère UserFavorite pour un set_id
  UserFavorite? getUserFavorite(int setId) => _userFavorites[setId];

  /// Bumpé quand les données SECONDAIRES (équipe, favoris de tous, tags),
  /// chargées en arrière-plan, deviennent disponibles → l'app se redessine pour
  /// les afficher (cf. `main.dart`).
  final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);
  bool _secondaryLoading = false;

  /// Vrai tant que le chargement de fond des favoris/notes de TOUS les
  /// utilisateurs n'a pas abouti. Permet à la vue Tendances d'afficher un
  /// indicateur de chargement plutôt qu'un état « vide » trompeur au démarrage
  /// (les données arrivent en tâche de fond → cf. [loadSecondaryData]).
  bool get isLoadingAllFavorites => _secondaryLoading && !_allFavoritesLoaded;

  /// Idem pour les tags collaboratifs (vue « DJ par tag »).
  bool get isLoadingDjTags => _secondaryLoading && !_djTagsLoaded;

  /// Domaines de données actuellement rafraîchis EN ARRIÈRE-PLAN
  /// (stale-while-revalidate). Les pages observent ce notifier (via
  /// [FestivalBackground]) pour afficher un bandeau « mise à jour en cours »
  /// non bloquant : les données locales restent affichées et navigables, le
  /// bandeau disparaît seul à la fin du rafraîchissement.
  final ValueNotifier<Set<String>> backgroundLoads =
      ValueNotifier<Set<String>>(const {});

  void _beginLoad(String domain) {
    if (backgroundLoads.value.contains(domain)) return;
    backgroundLoads.value = {...backgroundLoads.value, domain};
  }

  void _endLoad(String domain) {
    if (!backgroundLoads.value.contains(domain)) return;
    backgroundLoads.value = {...backgroundLoads.value}..remove(domain);
  }

  // Données ESSENTIELLES au 1er écran (Accueil/Live = countdown, now/next) : la
  // timetable seule. On bloque uniquement dessus (souvent servie depuis le cache
  // créneaux), et on lance le RESTE en arrière-plan → l'app s'ouvre tout de suite.
  // Garde anti-concurrence : si plusieurs appelants (rebuilds) lancent
  // loadEssentialData pendant qu'un chargement est déjà en cours, ils partagent
  // le MÊME Future au lieu de déclencher des fetchs parallèles (request storm).
  Future<void>? _essentialInFlight;
  Future<void> loadEssentialData() => _essentialInFlight ??= _loadEssentialDataOnce();

  Future<void> _loadEssentialDataOnce() async {
    try {
      await loadTimetable();
    } catch (e) {
      _showErrorMessage('Erreur lors du chargement des données : $e');
      rethrow;
    } finally {
      // Le reste (équipe, favoris de tous, tags) n'est pas requis pour l'accueil.
      loadSecondaryData().ignore();
      _essentialInFlight = null;
    }
  }

  // Données SECONDAIRES chargées EN TÂCHE DE FOND : utilisateurs (Équipe + fans),
  // favoris/notes de tous (Tendances, mode équipe), tags collaboratifs (vue Tags,
  // fiche DJ). Notifie [dataRevision] à la fin → les vues se rafraîchissent.
  // Best-effort : chaque chargeur gère déjà ses erreurs/cache.
  Future<void> loadSecondaryData() async {
    if (_secondaryLoading) return;
    _secondaryLoading = true;
    // 'team' est marqué/démarqué par loadUsers lui-même (appelé aussi ailleurs).
    _beginLoad(LoadDomain.trending);
    _beginLoad(LoadDomain.tags);
    try {
      await Future.wait([
        loadUsers(),
        loadAllUserFavorites(),
        loadDjTags(),
      ]);
    } catch (_) {
      // ignoré : non bloquant pour l'usage principal
    } finally {
      _secondaryLoading = false;
      _endLoad(LoadDomain.trending);
      _endLoad(LoadDomain.tags);
      dataRevision.value++;
    }
  }

  /// Créneaux de rafraîchissement de la timetable (heures locales). Le line-up
  /// bouge très rarement → inutile de le re-télécharger entre deux créneaux.
  static const List<int> timetableRefreshHours = [12, 18, 22];

  /// Dernier créneau de rafraîchissement atteint à [now] (avant 12h = 22h veille).
  static DateTime _latestTimetableSlot(DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day);
    DateTime? slot;
    for (final h in timetableRefreshHours) {
      final b = midnight.add(Duration(hours: h));
      if (!b.isAfter(now)) slot = b;
    }
    return slot ??
        midnight.subtract(const Duration(days: 1)).add(const Duration(hours: 22));
  }

  // Charge la timetable du festival sélectionné.
  //
  // Par défaut, **réutilise le cache local** tant qu'aucun créneau de
  // rafraîchissement (12/18/22h) n'est passé depuis le dernier fetch → pas de
  // requête réseau superflue au démarrage (le line-up change rarement). Passer
  // [force] pour ignorer le cache (ex. pull-to-refresh).
  // Garde anti-concurrence : un seul chargement timetable en vol à la fois ;
  // les appels concurrents partagent le même Future (évite N téléchargements
  // parallèles du gros payload bios → request storm).
  Future<void>? _timetableInFlight;
  Future<void> loadTimetable({bool force = false}) {
    final existing = _timetableInFlight;
    if (existing != null) return existing;
    final f = _loadTimetableImpl(force: force);
    _timetableInFlight = f;
    return f.whenComplete(() {
      if (identical(_timetableInFlight, f)) _timetableInFlight = null;
    });
  }

  Future<void> _loadTimetableImpl({bool force = false}) async {
    final fid = selectedFestivalId;
    if (fid == null) throw Exception('Aucun festival sélectionné.');

    if (!force) {
      // Stale-while-revalidate : si on a un cache local, on l'affiche
      // IMMÉDIATEMENT (zéro réseau sur le chemin critique de démarrage). On ne
      // re-télécharge le gros payload (bios) qu'en ARRIÈRE-PLAN, et seulement si
      // un créneau (12/18/22h) est passé depuis le dernier fetch.
      final cached = await LocalStorageService().getTimetable(fid);
      if (cached.isNotEmpty) {
        _timetable = cached;
        _ensureValidSelectedDay();
        final ts = LocalStorageService().getTimetableTimestamp(fid);
        final stale =
            ts == null || ts.isBefore(_latestTimetableSlot(DateTime.now()));
        if (stale) _refreshTimetableInBackground(fid);
        return;
      }
    }

    // Aucun cache (tout 1er lancement) ou refresh forcé → fetch bloquant.
    try {
      _timetable = await ApiService.fetchTimetable();
      await LocalStorageService().saveTimetable(_timetable, fid);
    } catch (e) {
      _showErrorMessage('Impossible de charger la timetable depuis le serveur.');
      _timetable = await LocalStorageService().getTimetable(fid);
      rethrow;
    } finally {
      _ensureValidSelectedDay();
    }
  }

  bool _timetableRefreshing = false;

  // Rafraîchit la timetable en arrière-plan (stale-while-revalidate). Ne bloque
  // jamais l'UI, avale les erreurs (le cache déjà affiché reste valable), et
  // notifie [dataRevision] si de nouvelles données arrivent → Live/Accueil se
  // redessinent. Abandonne si l'utilisateur a changé de festival entre-temps.
  Future<void> _refreshTimetableInBackground(int fid) async {
    if (_timetableRefreshing) return;
    _timetableRefreshing = true;
    _beginLoad(LoadDomain.timetable);
    try {
      final fresh = await ApiService.fetchTimetable();
      if (fid != selectedFestivalId) return;
      _timetable = fresh;
      await LocalStorageService().saveTimetable(_timetable, fid);
      _ensureValidSelectedDay();
      dataRevision.value++;
    } catch (_) {
      // best-effort : le cache déjà affiché reste valable
    } finally {
      _timetableRefreshing = false;
      _endLoad(LoadDomain.timetable);
    }
  }

  // Charge les utilisateurs (stale-while-revalidate). Affiche le cache local
  // IMMÉDIATEMENT (équipe + URLs de photos), puis rafraîchit depuis le serveur
  // en arrière-plan (positions à jour) → pastille « mise à jour de l'équipe ».
  Future<void> loadUsers() async {
    // Seed depuis le cache local → équipe + photos affichées tout de suite (les
    // octets sont déjà en cache disque via cached_network_image). Évite le
    // spinner central et le « pop » des photos à chaque lancement.
    if (_users.isEmpty) {
      final cached = await LocalStorageService().getUsers();
      if (cached.isNotEmpty) {
        _users = cached;
        final cachedUrls = await LocalStorageService().getPhotoUrls();
        for (final u in _users) {
          _photoUrls[u.id] = cachedUrls[u.id]; // URL cachée, ou null (initiale)
        }
        dataRevision.value++;
        photosRevision.value++;
      }
    }

    _beginLoad(LoadDomain.team);
    try {
      _users = (await ApiService.fetchUsers()).map((map) => User.fromMap(map)).toList();

      // Pré-remplit le cache à null pour les users SANS écraser une URL déjà
      // résolue : `photoUrls` reste la source de vérité (ProfileAvatar teste
      // `containsKey`) et les avatars affichent l'initiale en attendant.
      for (final user in _users) {
        _photoUrls.putIfAbsent(user.id, () => null);
      }

      // ⚡ Photos en ARRIÈRE-PLAN, mais UNE SEULE FOIS par session : on ne
      // rejoue pas les requêtes Firebase Storage à chaque loadUsers (sinon la
      // page Équipe les relance à chaque ouverture → flot de StorageUtil/getToken).
      if (!_photosLoaded) {
        _loadPhotosInBackground();
      }

      // Persiste l'équipe pour un affichage instantané au prochain lancement
      // (et pour que le numéro de téléphone survive à un redémarrage).
      await LocalStorageService().saveUsers(_users);
    } catch (e) {
      _showErrorMessage('Impossible de charger les utilisateurs : $e');
      if (_users.isEmpty) rethrow; // pas de cache → on propage ; sinon on le garde
    } finally {
      _endLoad(LoadDomain.team);
    }
  }

  /// Charge les URLs de photos en tâche de fond : un seul `listAll()` pour savoir
  /// qui a une photo (évite les 404), puis les URLs en parallèle. Best-effort :
  /// un échec ne casse rien. Notifie les avatars à la fin via [photosRevision].
  /// Marque [_photosLoaded] pour ne pas rejouer ces requêtes la session durant.
  Future<void> _loadPhotosInBackground() async {
    // Seed depuis le cache local AVANT toute requête réseau → les photos
    // s'affichent immédiatement (octets déjà en cache disque via
    // cached_network_image), sans le « initiale puis photo qui apparaît » à
    // chaque lancement. La résolution réseau ci-dessous ne fait que valider/MAJ.
    try {
      final cachedUrls = await LocalStorageService().getPhotoUrls();
      if (cachedUrls.isNotEmpty) {
        cachedUrls.forEach((id, url) => _photoUrls[id] = url);
        photosRevision.value++;
      }
    } catch (_) {
      // cache best-effort
    }

    try {
      final withPhoto = await ProfileService.listUserIdsWithPhoto();
      final targets = withPhoto == null
          ? _users
          : _users.where((u) => withPhoto.contains(u.id)).toList();
      await Future.wait(targets.map((user) async {
        final photoUrl = await ProfileService.getPhotoUrl(user.id);
        _photoUrls[user.id] = photoUrl;
        if (photoUrl != null && navigatorKey.currentContext != null) {
          precacheImage(
              CachedNetworkImageProvider(photoUrl), navigatorKey.currentContext!);
        }
      }));
      _photosLoaded = true; // succès → on ne rejoue plus (cache valable la session)
      // Persiste la map résolue pour un affichage instantané au prochain lancement.
      await LocalStorageService().savePhotoUrls(_photoUrls);
    } catch (_) {
      // Photos best-effort : on ignore les erreurs (avatars = initiales) et on
      // laisse _photosLoaded à false pour retenter au prochain loadUsers.
    } finally {
      photosRevision.value++;
    }
  }

  // Charge TOUS les favoris de TOUS les utilisateurs (Tendances / mode équipe).
  // Stale-while-revalidate : on affiche d'abord le cache local (la vue Tendances
  // s'affiche INSTANTANÉMENT), puis on rafraîchit depuis le serveur en fond.
  Future<void> loadAllUserFavorites() async {
    if (_allFavoritesLoaded) return;
    final fid = selectedFestivalId;

    // Cache local d'abord → contenu affiché tout de suite (la pastille « mise à
    // jour » signale le rafraîchissement en cours). On notifie pour rebâtir l'UI
    // avec ces données sans attendre le réseau.
    if (_allUserFavorites.isEmpty && fid != null) {
      final cached = await LocalStorageService().getAllUserFavorites(fid);
      if (cached.isNotEmpty) {
        _allUserFavorites = cached;
        dataRevision.value++;
      }
    }

    try {
      final allFavorites = await ApiService.fetchUserFavorites();
      if (allFavorites is Map<int, Map<int, UserFavorite>>) {
        _allUserFavorites = allFavorites;
      } else {
        final favoritesMap = allFavorites as Map<int, UserFavorite>;
        _allUserFavorites = {};
        for (final entry in favoritesMap.entries) {
          final userId = entry.key;
          final userFav = entry.value;
          _allUserFavorites.putIfAbsent(userId, () => {});
          _allUserFavorites[userId]![userFav.setId] = userFav;
        }
      }
      _allFavoritesLoaded = true;
      if (fid != null) {
        await LocalStorageService().saveAllUserFavorites(_allUserFavorites, fid);
      }
    } catch (e) {
      _showErrorMessage('Impossible de charger les favoris des utilisateurs : $e');
      _allFavoritesLoaded = false;
    }
  }

  // Charge TOUS les tags du festival (tous utilisateurs). Même logique
  // stale-while-revalidate que les favoris de tous.
  Future<void> loadDjTags() async {
    if (_djTagsLoaded) return;
    final fid = selectedFestivalId;

    if (_djTags.isEmpty && fid != null) {
      final cached = await LocalStorageService().getDjTags(fid);
      if (cached.isNotEmpty) {
        _djTags = cached;
        dataRevision.value++;
      }
    }

    try {
      _djTags = await ApiService.fetchDjTags();
      _djTagsLoaded = true;
      if (fid != null) await LocalStorageService().saveDjTags(_djTags, fid);
    } catch (e) {
      _showErrorMessage('Impossible de charger les tags : $e');
      _djTagsLoaded = false;
    }
  }

  /// Ajoute un tag sur un set (optimiste + sync serveur). Idempotent : ne crée
  /// pas de doublon si l'utilisateur courant a déjà ce tag sur ce set.
  Future<void> addDjTag(int setId, String rawTag) async {
    final tag = DjTag.normalize(rawTag);
    if (tag.isEmpty || _userId == null) return;

    final alreadyMine = _djTags.any(
      (t) => t.setId == setId && t.userId == _userId && t.tag == tag,
    );
    if (alreadyMine) return;

    final optimistic = DjTag(userId: _userId!, setId: setId, tag: tag);
    _djTags.add(optimistic);

    try {
      final saved = await ApiService.addDjTag(_userId!, setId, tag);
      // Le serveur peut renormaliser différemment : on réaligne le cache.
      if (saved != tag) {
        _djTags.remove(optimistic);
        final exists = _djTags.any(
          (t) => t.setId == setId && t.userId == _userId && t.tag == saved,
        );
        if (!exists) _djTags.add(DjTag(userId: _userId!, setId: setId, tag: saved));
      }
    } catch (e) {
      _djTags.remove(optimistic);
      _showErrorMessage('Impossible d\'ajouter le tag.');
    }
  }

  /// Supprime SON propre tag sur un set (optimiste + sync serveur).
  Future<void> removeDjTag(int setId, String tag) async {
    if (_userId == null) return;
    DjTag? removed;
    _djTags.removeWhere((t) {
      if (t.setId == setId && t.userId == _userId && t.tag == tag) {
        removed = t;
        return true;
      }
      return false;
    });
    if (removed == null) return;

    try {
      await ApiService.deleteDjTag(_userId!, setId, tag);
    } catch (e) {
      _djTags.add(removed!);
      _showErrorMessage('Impossible de supprimer le tag.');
    }
  }

  // Charge les favoris de l'utilisateur connecté
  Future<void> loadFavorites(int userId) async {
    final fid = selectedFestivalId;
    _userId = userId;

    // Déjà préchargé (favoris de tous, tâche secondaire) → copie locale, instantané.
    if (_allFavoritesLoaded && _allUserFavorites.containsKey(userId)) {
      _userFavorites = Map.from(_allUserFavorites[userId]!); // shallow, anti-aliasing
      return;
    }

    // Stale-while-revalidate : on affiche le cache disque immédiatement (pas de
    // GET bloquant sur le chemin critique du splash) et on rafraîchit en fond.
    if (fid != null) {
      final cached = await LocalStorageService().getUserFavorites(fid);
      if (cached.isNotEmpty) {
        _userFavorites = cached;
        _refreshFavoritesInBackground(userId, fid);
        return;
      }
    }

    // Aucun cache (1er lancement) → fetch bloquant.
    try {
      final serverFavorites = await ApiService.fetchUserFavorites(userId) as Map<int, UserFavorite>;
      _userFavorites = serverFavorites;
      if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);
    } catch (e) {
      _showErrorMessage('Impossible de charger les favoris depuis le serveur.');
      if (fid != null) _userFavorites = await LocalStorageService().getUserFavorites(fid);
      rethrow;
    }
  }

  // Rafraîchit les favoris/notes de l'utilisateur en arrière-plan (SWR). Avale
  // les erreurs (cache affiché valable), abandonne si le festival ou l'user a
  // changé, et notifie [dataRevision] si de nouvelles données arrivent.
  Future<void> _refreshFavoritesInBackground(int userId, int fid) async {
    try {
      final fresh = await ApiService.fetchUserFavorites(userId) as Map<int, UserFavorite>;
      if (fid != selectedFestivalId || userId != _userId) return;
      _userFavorites = fresh;
      await LocalStorageService().saveUserFavorites(_userFavorites, fid);
      dataRevision.value++;
    } catch (_) {
      // best-effort : le cache déjà affiché reste valable
    }
  }

  // Met à jour la photo d'un utilisateur
  void updateUserPhoto(int userId, String? photoUrl) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(photoUrl: photoUrl);
    }
    // Met aussi à jour le cache lu par les avatars (équipe, AppBar) → la
    // nouvelle photo apparaît sans attendre un rechargement complet.
    _photoUrls[userId] = photoUrl;
    // Persiste pour que la nouvelle photo survive au prochain lancement.
    LocalStorageService().savePhotoUrls(_photoUrls).ignore();
  }

  // Met à jour la localisation d'un utilisateur + scène
  void updateUserLocation(int userId, double lat, double lng, {String? stage}) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        lastLat: lat,
        lastLng: lng,
        lastLocation: stage ?? _users[index].lastLocation,
      );
    }
  }

  // Met à jour le téléphone d'un utilisateur
  void updateUserPhone(int userId, String phoneNumber) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(phoneNumber: phoneNumber);
    }
    // Persiste : le numéro survit au redémarrage même avant le 1er fetch réseau.
    LocalStorageService().saveUsers(_users).ignore();
  }

  // Réinitialisation des données (utilisateur). Conserve le festival sélectionné.
  void reset() {
    _timetable = [];
    _userFavorites = {};
    _allUserFavorites = {};
    _allFavoritesLoaded = false;
    _djTags = [];
    _djTagsLoaded = false;
    _userId = null;
    _selectedDay = 'friday';
    _filterMode = FavoriteFilterMode.normal;
    _users = [];
    _userEvents = [];
    _photoUrls.clear();
    _photosLoaded = false;
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    LocalStorageService().saveSelectedDay(day);
  }

  void setFilterMode(FavoriteFilterMode mode) {
    _filterMode = mode;
  }

  // Alias pour la compatibilité ascendante (helpers, etc.)
  void setShowFavoritesOnly(bool value) =>
      setFilterMode(value ? FavoriteFilterMode.myFavorites : FavoriteFilterMode.normal);

  void setShowAllUsersFavorites(bool value) =>
      setFilterMode(value ? FavoriteFilterMode.teamFavorites : FavoriteFilterMode.normal);

  // Toggle favori pour un set_id
  Future<void> toggleFavorite(int setId) async {
    final fid = selectedFestivalId;
    final current = _userFavorites[setId];
    final newIsFavorite = current == null ? true : !current.isFavorite;

    _userFavorites[setId] = UserFavorite(
      setId: setId,
      isFavorite: newIsFavorite,
      notation: current?.notation,
    );

    if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);

    // Replanifie les rappels de sets favoris (ce favori vient de changer).
    if (_userId != null) NotificationScheduler.rescheduleAll(_userId!).ignore();

    if (_userId != null) {
      try {
        final result = await ApiService.toggleUserFavorite(_userId!, setId);
        _userFavorites[setId] = _userFavorites[setId]!.copyWith(isFavorite: result);
        if (_allUserFavorites.containsKey(_userId)) {
          _allUserFavorites[_userId]![setId] = _userFavorites[setId]!;
        }
      } catch (e) {
        _showErrorMessage('Impossible de synchroniser avec le serveur.');
      }
    }
  }

  // Met à jour la notation
  Future<void> rateFavorite(int setId, int? notation) async {
    final fid = selectedFestivalId;
    bool currentIsFavorite = false;
    if (_allUserFavorites.containsKey(_userId) && _allUserFavorites[_userId]!.containsKey(setId)) {
      currentIsFavorite = _allUserFavorites[_userId]![setId]!.isFavorite;
    } else if (_userFavorites.containsKey(setId)) {
      currentIsFavorite = _userFavorites[setId]!.isFavorite;
    }

    // Reconstruction explicite pour pouvoir effacer la notation (null).
    _userFavorites[setId] = UserFavorite(
      setId: setId,
      isFavorite: currentIsFavorite,
      notation: notation,
    );

    if (_userId != null) {
      _allUserFavorites.putIfAbsent(_userId!, () => {})[setId] = _userFavorites[setId]!;
    }

    if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);

    if (_userId != null) {
      try {
        await ApiService.rateUserFavorite(_userId!, setId, notation);
      } catch (e) {
        _showErrorMessage('Impossible de synchroniser la notation.');
      }
    }
  }

  // Synchronise les notations en arrière-plan.
  //
  // Déclenchée notamment à la mise en arrière-plan de l'app
  // (didChangeAppLifecycleState → paused/detached). Sur ce cycle, l'OS coupe
  // souvent le réseau en plein vol → un échec ici est NORMAL et sans gravité
  // (toggle/rate synchronisent déjà chacun de leur côté en avant-plan). On reste
  // donc SILENCIEUX : afficher une SnackBar « impossible de synchroniser » à ce
  // moment-là la fait surgir au retour dans l'app (« impossible de charger les
  // favoris ») alors que rien n'est cassé. Best-effort, on avale l'erreur.
  Future<void> syncFavorites() async {
    if (_userId == null) return;
    final fid = selectedFestivalId;
    try {
      for (final entry in _userFavorites.entries) {
        final setId = entry.key;
        final fav = entry.value;
        if (fav.notation != null) {
          await ApiService.rateUserFavorite(_userId!, setId, fav.notation);
        }
      }
      if (_allUserFavorites.containsKey(_userId!)) {
        _allUserFavorites[_userId!] = Map.from(_userFavorites);
      }
      if (fid != null) await LocalStorageService().saveUserFavorites(_userFavorites, fid);
    } catch (e) {
      // Best-effort silencieux : voir le commentaire ci-dessus.
      debugPrint('syncFavorites (background) a échoué, ignoré : $e');
    }
  }

  // Charge les scènes (stale-while-revalidate). Affiche le cache local
  // IMMÉDIATEMENT puis rafraîchit depuis le serveur en arrière-plan (pastille).
  Future<void> loadStages() async {
    if (_stages.isNotEmpty) return;
    final fid = selectedFestivalId;
    if (fid == null) throw Exception('Aucun festival sélectionné.');

    // Cache local d'abord → affichage instantané, refresh réseau en fond.
    final cached = await LocalStorageService().getStages(fid);
    if (cached.isNotEmpty) {
      _stages = cached;
      _refreshStagesInBackground(fid);
      return;
    }

    // Aucun cache (1er accès) → fetch bloquant.
    _isLoadingStages = true;
    _beginLoad(LoadDomain.stages);
    try {
      _stages = await ApiService.fetchStages();
      await LocalStorageService().saveStages(_stages, fid);
    } catch (e) {
      _showErrorMessage('Impossible de charger les scènes depuis le serveur.');
      _stages = await LocalStorageService().getStages(fid);
      rethrow;
    } finally {
      _isLoadingStages = false;
      _endLoad(LoadDomain.stages);
    }
  }

  bool _stagesRefreshing = false;

  // Rafraîchit les scènes en arrière-plan (SWR). Avale les erreurs (le cache
  // déjà affiché reste valable), abandonne si le festival a changé, notifie
  // [dataRevision] si de nouvelles données arrivent.
  Future<void> _refreshStagesInBackground(int fid) async {
    if (_stagesRefreshing) return;
    _stagesRefreshing = true;
    _beginLoad(LoadDomain.stages);
    try {
      final fresh = await ApiService.fetchStages();
      if (fid != selectedFestivalId) return;
      _stages = fresh;
      await LocalStorageService().saveStages(_stages, fid);
      dataRevision.value++;
    } catch (_) {
      // best-effort : le cache déjà affiché reste valable
    } finally {
      _stagesRefreshing = false;
      _endLoad(LoadDomain.stages);
    }
  }

  // Met à jour une scène
  Future<void> updateStage(String stageName, Map<String, dynamic> coordinates) async {
    final fid = selectedFestivalId;
    try {
      final index = _stages.indexWhere((s) => s.stage == stageName);
      if (index != -1) {
        _stages[index] = _stages[index].copyWith(
          latAvg: coordinates['lat_avg']?.toDouble(),
          lonAvg: coordinates['lon_avg']?.toDouble(),
          latAvd: coordinates['lat_avd']?.toDouble(),
          lonAvd: coordinates['lon_avd']?.toDouble(),
          latArg: coordinates['lat_arg']?.toDouble(),
          lonArg: coordinates['lon_arg']?.toDouble(),
          latArd: coordinates['lat_ard']?.toDouble(),
          lonArd: coordinates['lon_ard']?.toDouble(),
          latRallyPoint: coordinates['lat_rally_point']?.toDouble(),
          lonRallyPoint: coordinates['lon_rally_point']?.toDouble(),
        );
      }

      await ApiService.updateStage(stageName, coordinates);
      if (fid != null) await LocalStorageService().saveStages(_stages, fid);
    } catch (e) {
      _showErrorMessage('Impossible de mettre à jour la scène.');
      rethrow;
    }
  }

  // ========== EVENT MANAGEMENT ==========

  /// Événements en cache local (affichage instantané avant le rafraîchissement
  /// réseau). Vide si aucun cache.
  Future<List<Event>> getCachedUserEvents(int userId) async {
    final fid = selectedFestivalId;
    if (fid == null) return [];
    return LocalStorageService().getUserEvents(fid, userId);
  }

  Future<void> loadUserEvents(int userId) async {
    _isLoadingEvents = true;
    _beginLoad(LoadDomain.events);
    final fid = selectedFestivalId;
    try {
      _userEvents = (await ApiService.fetchUserEvents(userId))
          .map((e) => Event.fromJson(e))
          .toList();
      if (fid != null) {
        await LocalStorageService().saveUserEvents(_userEvents, fid, userId);
      }
    } catch (e) {
      // Repli sur le cache pour ne pas vider l'affichage en cas de coupure.
      if (fid != null) {
        final cached = await LocalStorageService().getUserEvents(fid, userId);
        if (cached.isNotEmpty) _userEvents = cached;
      }
      _showErrorMessage('Impossible de charger les événements : $e');
      rethrow;
    } finally {
      _isLoadingEvents = false;
      _endLoad(LoadDomain.events);
    }
  }

  /// Crée l'événement côté serveur. L'affichage optimiste (insertion immédiate
  /// dans la liste) est géré par l'appelant (EventsPage) pour un retour
  /// instantané ; ici on ne fait que l'I/O réseau + les effets de bord.
  /// Pour "perdu", recharge les utilisateurs (le backend a recalculé les scènes).
  Future<void> createEventRemote(int userId, String eventType) async {
    await ApiService.createEvent(userId: userId, eventType: eventType);
    if (eventType == 'perdu') {
      await loadUsers();
    }
  }

  /// Supprime le dernier événement côté serveur (l'optimisme est géré par l'appelant).
  Future<void> deleteLastEventRemote(int userId) async {
    await ApiService.deleteLastEvent(userId);
  }

  // ========== GÉOLOCALISATION ==========
  Future<void> updateGeoloc({
    required int userId,
    required double lat,
    required double lng,
    String? stage,
  }) async {
    try {
      await ApiService.updateGeoloc(
        userId: userId,
        lat: lat,
        lng: lng,
        stage: stage,
      );
      updateUserLocation(userId, lat, lng, stage: stage);
    } catch (e) {
      _showErrorMessage('Impossible de mettre à jour la géolocalisation : $e');
      rethrow;
    }
  }
}
