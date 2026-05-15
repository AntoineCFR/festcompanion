// lib/utils/utils.dart
class AppUtils {
  // Empêche l'instanciation (classe statique)
  AppUtils._();

  static String getDayName(String day) {
    switch (day.toLowerCase()) {
      case 'friday': return 'Vendredi';
      case 'saturday': return 'Samedi';
      case 'sunday': return 'Dimanche';
      default: return day;
    }
  }

  static String formatTime(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  static String getDjImagePath(String djName) {
    final normalized = djName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'[^\w]'), '');
    return 'lib/assets/$normalized.jpg';
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