// lib/pages/team_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../services/app_data_manager.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final appData = AppDataManager();

  // ✅ Méthode centralisée et sécurisée pour les SnackBars
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _callUser(String phoneNumber) async {
    final cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedPhoneNumber.isEmpty) {
      _showSnackBar('Aucun numéro de téléphone valide.');
      return;
    }

    final url = Uri.parse('tel:$cleanedPhoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await Clipboard.setData(ClipboardData(text: cleanedPhoneNumber));
        _showSnackBar('Impossible d\'appeler. Numéro copié : $cleanedPhoneNumber');
      }
    } catch (e) {
      _showSnackBar('Erreur : $e');
    }
  }

  Future<void> _locateUser(dynamic lat, dynamic lng) async {
    final double? latitude = lat?.toDouble();
    final double? longitude = lng?.toDouble();

    if (latitude == null || longitude == null) {
      _showSnackBar('Aucune coordonnée enregistrée.');
      return;
    }

    final url = Uri.parse('https://www.google.com/maps?q=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackBar('Impossible d\'ouvrir la carte.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Équipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              try {
                await appData.loadUsers();
              } catch (e) {
                _showSnackBar('Erreur : $e'); // ✅ Utilise _showSnackBar
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: appData.users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: appData.users.length,
                itemBuilder: (context, index) {
                  final user = appData.users[index];
                  final userId = user['id'] as int;
                  final photoUrl = appData.getPhotoUrl(userId);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[800],
                    child: ListTile(
                      leading: photoUrl != null
                          ? CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[700],
                              backgroundImage: CachedNetworkImageProvider(photoUrl),
                            )
                          : CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[700],
                              child: Icon(Icons.account_circle, color: Colors.white),
                            ),
                      title: Text(
                        user['username'] ?? 'Inconnu',
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.white),
                            onPressed: (user['phone_number']?.toString().isNotEmpty == true)
                                ? () => _callUser(user['phone_number']?.toString() ?? '')
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.location_on, color: Colors.white),
                            onPressed: (user['last_lat'] != null && user['last_lng'] != null)
                                ? () => _locateUser(user['last_lat'], user['last_lng'])
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}