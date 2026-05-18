import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_data_manager.dart';

class TeamHelper {
  static Future<void> callUser(String phoneNumber) async {
    final cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedPhoneNumber.isEmpty) {
      AppDataManager().showSnackBar('Aucun numéro de téléphone valide.');
      return;
    }

    final url = Uri.parse('tel:$cleanedPhoneNumber');
    try {
      await launchUrl(url);
    } on PlatformException catch (_) {
      // ✅ Fallback si l'appel échoue (copie le numéro)
      await Clipboard.setData(ClipboardData(text: cleanedPhoneNumber));
      AppDataManager().showSnackBar('Impossible d\'appeler. Numéro copié : $cleanedPhoneNumber');
    } catch (e) {
      AppDataManager().showSnackBar('Erreur : $e');
    }
  }

  static Future<void> locateUser(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      AppDataManager().showSnackBar('Aucune coordonnée enregistrée.');
      return;
    }

    final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    try {
      await launchUrl(url);
    } catch (e) {
      AppDataManager().showSnackBar('Impossible d\'ouvrir la carte.');
    }
  }
}