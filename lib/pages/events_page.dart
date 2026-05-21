import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/app_data_manager.dart';
import '../widgets/events/event_wheel.dart';
import '../widgets/events/recent_events_list.dart';

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

class _EventsPageState extends State<EventsPage> {
  bool _isLoading = true;
  List<Event> _events = [];
  bool _showingSos = false;
  DateTime? _sosPressStart;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      await AppDataManager().loadUserEvents(widget.userId);
      if (mounted) {
        setState(() {
          _events = (AppDataManager().userEvents);
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
      _sosPressStart = DateTime.now();
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

  void _handleSosLongPress() {
    final duration = DateTime.now().difference(_sosPressStart!);
    setState(() => _showingSos = false);

    if (duration >= const Duration(seconds: 5)) {
      _submitEvent('sos');
    }
  }

  Future<void> _submitEvent(String eventType) async {
    try {
      await AppDataManager().addEvent(widget.userId, eventType);

      if (mounted) {
        // _events est la même référence que AppDataManager()._userEvents :
        // addEvent() a déjà inséré le nouvel Event — on déclenche juste
        // un rebuild pour rafraîchir l'UI.
        setState(() {});

        String message = Event.labels[eventType] ?? eventType;
        if (eventType == 'sos') {
          message = 'SOS envoyé ! Tous les utilisateurs ont été notifiés.';
        } else if (eventType == 'perdu') {
          message = 'Signalement "perdu" envoyé ! La localisation a été mise à jour.';
        } else {
          message = '$message enregistré !';
        }
        AppDataManager().showSnackBar(message);
      }
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur: $e');
    }
  }

  Future<void> _deleteLastEvent() async {
    try {
      await AppDataManager().deleteLastEvent(widget.userId);
      if (mounted) setState(() {});
    } catch (_) {
      // L'erreur est déjà affichée par AppDataManager via showSnackBar.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Colors.grey[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Roue — 3/5 de l'espace
                Expanded(
                  flex: 3,
                  child: _showingSos
                      ? _buildSosHolder()
                      : EventWheel(onEventSelected: _handleEventSelected),
                ),
                const Divider(color: Colors.white12, height: 1, thickness: 1),
                // Historique — 2/5 de l'espace
                Expanded(
                  flex: 2,
                  child: RecentEventsList(
                    events: _events,
                    onDeleteLast: _events.isNotEmpty ? _deleteLastEvent : null,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSosHolder() {
    return GestureDetector(
      onLongPressEnd: (_) => _handleSosLongPress(),
      onLongPressCancel: () => setState(() => _showingSos = false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Maintenez pour SOS', style: TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.red[700],
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color.fromRGBO(255, 0, 0, 0.5), blurRadius: 20)],
            ),
            child: const Icon(Icons.warning_amber, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('Maintenez 5 secondes', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _showingSos = false),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

}