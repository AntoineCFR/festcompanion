import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/profile_helper.dart';
import '../widgets/events/event_wheel.dart';
import '../widgets/events/recent_events_list.dart';
import '../widgets/events/sos_hold_button.dart';
import '../widgets/shared/festival_background.dart';

class EventsPage extends StatefulWidget {
  final String username;
  final int userId;

  const EventsPage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  // Liste LOCALE des événements (copie) : permet l'affichage optimiste
  // instantané, indépendant de la liste interne d'AppDataManager.
  List<Event> _events = [];
  bool _showingSos = false;

  // Garde la page vivante dans le PageView → revenir sur l'onglet Events
  // n'efface pas l'état et ne relance pas un chargement (fluidité).
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Seed INSTANTANÉ depuis la mémoire si déjà chargé durant la session.
    if (AppDataManager().userEvents.isNotEmpty) {
      _events = List.of(AppDataManager().userEvents);
      _isLoading = false;
    }
    _loadEvents();
  }

  /// Affiche d'abord ce qu'on a (mémoire → cache disque) SANS bloquer la roue,
  /// puis rafraîchit depuis le serveur en arrière-plan.
  Future<void> _loadEvents() async {
    // Cache disque pour un affichage immédiat au tout premier accès (avant que
    // le réseau réponde) sans écraser un éventuel seed mémoire déjà présent.
    if (_events.isEmpty) {
      final cached = await AppDataManager().getCachedUserEvents(widget.userId);
      if (mounted && _events.isEmpty && cached.isNotEmpty) {
        setState(() {
          _events = cached;
          _isLoading = false;
        });
      }
    }

    // Rafraîchissement réseau en arrière-plan.
    try {
      await AppDataManager().loadUserEvents(widget.userId);
      if (mounted) {
        setState(() {
          _events = List.of(AppDataManager().userEvents);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleEventSelected(String eventType) {
    if (eventType == 'sos') {
      setState(() => _showingSos = true);
      return;
    }
    _showConfirmationDialog(eventType);
  }

  void _showConfirmationDialog(String eventType) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Confirmez-vous "${Event.labels[eventType]}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true) _submitEvent(eventType);
    });
  }

  /// Déclaration OPTIMISTE : on affiche l'événement immédiatement, puis on
  /// synchronise avec le serveur en arrière-plan. En cas d'échec, rollback.
  Future<void> _submitEvent(String eventType) async {
    final event = Event(
      userId: widget.userId,
      timestamp: DateTime.now(),
      eventType: eventType,
    );

    setState(() => _events = [event, ..._events]);

    String message = Event.labels[eventType] ?? eventType;
    if (eventType == 'sos') {
      message = 'SOS envoyé ! Tous les utilisateurs ont été notifiés.';
    } else if (eventType == 'perdu') {
      message = 'Signalement "perdu" envoyé ! La localisation a été mise à jour.';
    } else {
      message = '$message enregistré !';
    }
    AppDataManager().showSnackBar(message);

    try {
      // Hype : on rafraîchit d'abord MA position pour que le serveur connaisse
      // ma scène (incluse dans le push). Best-effort (gated sur le partage).
      if (eventType == 'hype') {
        await ProfileHelper.refreshLocationIfEnabled(widget.userId);
      }
      await AppDataManager().createEventRemote(widget.userId, eventType);
    } catch (e) {
      if (mounted) {
        setState(() => _events = _events.where((e2) => !identical(e2, event)).toList());
        AppDataManager().showSnackBar('Échec de l\'envoi, événement annulé.');
      }
    }
  }

  /// Suppression OPTIMISTE du dernier événement, avec rollback si échec.
  Future<void> _deleteLastEvent() async {
    if (_events.isEmpty) return;
    final removed = _events.first;

    setState(() => _events = _events.sublist(1));

    try {
      await AppDataManager().deleteLastEventRemote(widget.userId);
    } catch (e) {
      if (mounted) {
        setState(() => _events = [removed, ..._events]);
        AppDataManager().showSnackBar('Échec de la suppression.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // requis par AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: AppTheme.surface,
      ),
      // La ROUE est toujours affichée immédiatement (action principale) ; seul
      // l'historique attend les données, et uniquement au tout premier accès
      // (cache vide) — sinon il s'affiche instantanément.
      body: FestivalBackground(
        imageKey: 'featured',
        refreshDomains: const [LoadDomain.events],
        refreshLabel: 'Mise à jour des événements…',
        child: Column(
          children: [
            // Roue — 3/5 de l'espace
            Expanded(
              flex: 3,
              child: _showingSos
                  ? SosHoldButton(
                      onCompleted: () {
                        setState(() => _showingSos = false);
                        _submitEvent('sos');
                      },
                      onCancel: () => setState(() => _showingSos = false),
                    )
                  : EventWheel(onEventSelected: _handleEventSelected),
            ),
            const Divider(color: Colors.white12, height: 1, thickness: 1),
            // Historique — 2/5 de l'espace
            Expanded(
              flex: 2,
              child: _isLoading && _events.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RecentEventsList(
                      events: _events,
                      onDeleteLast:
                          _events.isNotEmpty ? _deleteLastEvent : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
