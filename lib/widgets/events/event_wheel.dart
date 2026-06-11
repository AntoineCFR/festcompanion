import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/event_model.dart';

// ---------------------------------------------------------------------------
// Structures internes
// ---------------------------------------------------------------------------

class _EventItem {
  final String type;
  final Color iconColor;
  const _EventItem(this.type, this.iconColor);
}

class _EventGroup {
  final String label;
  final IconData headerIcon;
  final Color accentColor;
  final List<_EventItem> events;
  final int flex;
  const _EventGroup({
    required this.label,
    required this.headerIcon,
    required this.accentColor,
    required this.events,
    this.flex = 1,
  });
}

const Map<String, String> _shortLabels = {
  'demi_alcool':    '½ alcool',
  'alcool':         '1 alcool',
  'eau':            'Eau',
  'quart_energie':  '¼ énergie',
  'demi_energie':   '½ énergie',
  'pleine_energie': 'Pleine',
  'hype':           'Hype !',
  'perdu':          'Perdu',
  'sos':            'SOS',
};

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class EventWheel extends StatelessWidget {
  final Function(String) onEventSelected;

  const EventWheel({super.key, required this.onEventSelected});

  List<_EventGroup> get _groups => [
        _EventGroup(
          label: 'Boisson',
          headerIcon: Icons.local_bar,
          accentColor: Colors.amber[500]!,
          events: [
            _EventItem('demi_alcool', Colors.amber[400]!),
            _EventItem('alcool',      Colors.amber[700]!),
            _EventItem('eau',         Colors.blue[400]!),
          ],
        ),
        _EventGroup(
          label: 'Énergie',
          headerIcon: Icons.electric_bolt,
          accentColor: Colors.green[500]!,
          events: [
            _EventItem('quart_energie',  Colors.lightGreen[500]!),
            _EventItem('demi_energie',   Colors.green[600]!),
            _EventItem('pleine_energie', Colors.green[800]!),
          ],
        ),
        _EventGroup(
          label: 'Hype',
          headerIcon: Icons.whatshot,
          accentColor: Colors.purple[400]!,
          flex: 1,
          events: [
            _EventItem('hype', Colors.purple[400]!),
          ],
        ),
        _EventGroup(
          label: 'Urgence',
          headerIcon: Icons.emergency,
          accentColor: Colors.red[400]!,
          events: [
            _EventItem('perdu', Colors.orange[600]!),
            _EventItem('sos',   Colors.red[500]!),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final separatorCount = groups.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < groups.length; i++) ...[
            Expanded(
              flex: groups[i].flex,
              child: _buildGroup(groups[i]),
            ),
            if (i < separatorCount) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Groupe (header + rangée de cards)
  // -------------------------------------------------------------------------
  Widget _buildGroup(_EventGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header minimaliste : icône + label colorés
        Row(
          children: [
            Icon(group.headerIcon, color: group.accentColor, size: 17),
            const SizedBox(width: 7),
            Text(
              group.label.toUpperCase(),
              style: TextStyle(
                color: group.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Cards — occupent le reste de l'espace Expanded
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: group.events
                .map((e) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildCard(e),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Card individuelle
  // -------------------------------------------------------------------------
  Widget _buildCard(_EventItem item) {
    final isSos = item.type == 'sos';

    return GestureDetector(
      onTap: () => onEventSelected(item.type),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: isSos
              ? Border.all(color: Colors.red[400]!, width: 1.5)
              : Border.all(color: Colors.white10, width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Event.icons[item.type], color: item.iconColor, size: 34),
                const SizedBox(height: 8),
                Text(
                  _shortLabels[item.type] ?? item.type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isSos) ...[
                  const SizedBox(height: 2),
                  Text(
                    'appui long',
                    style: TextStyle(color: Colors.red[300], fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
