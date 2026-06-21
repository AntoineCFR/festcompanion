/// Une entrée du « Journal » : une notification programmée générée par le
/// serveur (push quotidienne, vanne horaire, clôture ou palmarès). Le serveur
/// est la source de vérité (même contenu pour tout le groupe, même si une push
/// a été manquée). `pushed` = false → entrée visible au journal mais jamais
/// poussée (ex. lignes de palmarès du lendemain).
class JournalEntry {
  final String slotKey;
  final String? day; // jour festival concerné ('saturday'…), nullable
  final String? scheduledLocal; // 'HH:MM' prévu, nullable
  final String? theme; // 'trending' | 'airtag' | … | 'closing' | 'palmares'
  final String title;
  final String body;
  final bool pushed;
  final DateTime createdAt;

  const JournalEntry({
    required this.slotKey,
    this.day,
    this.scheduledLocal,
    this.theme,
    required this.title,
    required this.body,
    required this.pushed,
    required this.createdAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseCreated(dynamic v) {
      if (v is String) {
        return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    return JournalEntry(
      slotKey: json['slot_key'] as String? ?? '',
      day: json['day'] as String?,
      scheduledLocal: json['scheduled_local'] as String?,
      theme: json['theme'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      pushed: json['pushed'] as bool? ?? false,
      createdAt: parseCreated(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'slot_key': slotKey,
        'day': day,
        'scheduled_local': scheduledLocal,
        'theme': theme,
        'title': title,
        'body': body,
        'pushed': pushed,
        'created_at': createdAt.toIso8601String(),
      };
}
