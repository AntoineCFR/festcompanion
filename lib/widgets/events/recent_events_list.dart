import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/event_model.dart';

/// Section « Mes derniers événements » : titre + liste scrollable de tuiles.
/// Conçue pour être placée dans un [Expanded] afin d'occuper une part
/// proportionnelle de l'écran (sous la roue, dans EventsPage).
class RecentEventsList extends StatelessWidget {
  final List<Event> events;
  /// Appelé quand l'utilisateur supprime la dernière entrée (icône poubelle
  /// sur la première tuile). Null = bouton masqué.
  final VoidCallback? onDeleteLast;

  const RecentEventsList({super.key, required this.events, this.onDeleteLast});

  // ── Couleur associée à chaque type d'événement ───────────────────────────
  static Color colorForType(String type) {
    if (type == 'sos') return Colors.red;
    if (type == 'perdu') return Colors.orange;
    if (Event.alcoholTypes.contains(type)) return Colors.amber;
    if (Event.energyTypes.contains(type)) return Colors.green;
    if (Event.hydrationTypes.contains(type)) return Colors.blue;
    if (Event.hypeTypes.contains(type)) return Colors.purple;
    return Colors.white54;
  }

  // ── Formatage horodatage : "Ven. 23 · 14:32" (heure locale) ────────────
  static String _formatTimestamp(DateTime ts) {
    final local = ts.toLocal(); // UTC → fuseau horaire de l'appareil
    const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
    final dayName = days[local.weekday - 1];
    final time = '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
    return '$dayName ${local.day} · $time';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre ────────────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Mes derniers événements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // ── Liste / état vide ────────────────────────────────────────────────
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun événement déclaré.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _EventTile(
                    event: events[index],
                    onDelete: index == 0 ? onDeleteLast : null,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Tuile individuelle ───────────────────────────────────────────────────────
class _EventTile extends StatelessWidget {
  final Event event;
  /// Si non null, affiche une icône poubelle permettant de supprimer cet événement.
  final VoidCallback? onDelete;
  const _EventTile({required this.event, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = RecentEventsList.colorForType(event.eventType);
    final icon = Event.icons[event.eventType] ?? Icons.circle;
    final label = Event.labels[event.eventType] ?? event.eventType;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Icône dans un cercle coloré semi-transparent
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            // Horodatage
            Text(
              RecentEventsList._formatTimestamp(event.timestamp),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            // Poubelle — uniquement sur la première tuile
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    color: Colors.white38, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
