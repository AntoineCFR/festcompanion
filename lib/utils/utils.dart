// lib/utils/utils.dart
import '../services/app_data_manager.dart';

class AppUtils {
  // Empêche l'instanciation (classe statique)
  AppUtils._();

  static String getDayName(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 'Lundi';
      case 'tuesday': return 'Mardi';
      case 'wednesday': return 'Mercredi';
      case 'thursday': return 'Jeudi';
      case 'friday': return 'Vendredi';
      case 'saturday': return 'Samedi';
      case 'sunday': return 'Dimanche';
      default: return day;
    }
  }

  /// Nom du jour de la semaine en français (depuis une DateTime).
  static String getWeekdayName(DateTime date) {
    const days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return days[date.toLocal().weekday - 1];
  }

  static String formatTime(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  /// Chemin de l'image d'un DJ, préfixé par le festival courant pour éviter
  /// les collisions entre festivals (un même DJ peut jouer à plusieurs).
  /// Ex. festival 2 + "Amelie Lens" -> lib/assets/2_amelie_lens.jpg
  static String getDjImagePath(String djName) {
    final normalized = djName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'[^\w]'), '');
    final festivalId = AppDataManager().selectedFestivalId;
    final prefix = festivalId != null ? '${festivalId}_' : '';
    return 'lib/assets/$prefix$normalized.jpg';
  }

  /// Chemins des photos pour un set : un seul pour un solo, un par artiste pour
  /// un b2b (nom de la forme "Artiste A & Artiste B"). Permet d'afficher les
  /// photos côte à côte sur la fiche DJ (les images individuelles existent en
  /// assets ; aucune image combinée n'est nécessaire).
  static List<String> getDjImagePaths(String djName) {
    final parts = djName
        .split(' & ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length <= 1) return [getDjImagePath(djName)];
    return parts.map(getDjImagePath).toList();
  }

  static String formatFullDate(DateTime date) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}