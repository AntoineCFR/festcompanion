import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../extensions/build_context_extensions.dart';

class LocationButton extends StatelessWidget {
  const LocationButton({super.key});

  Future<void> _openLocation(BuildContext context) async {
    final url = Uri.parse('https://www.google.com/maps?q=51.026997,5.443735');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted){
          context.showSnackBar('Impossible d\'ouvrir le lien vers Google Maps.');
        }
      }
    } catch (e) {
      if (context.mounted){
          context.showSnackBar('Impossible d\'ouvrir le lien vers Google Maps.');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white, size: 30),
            onPressed: () => _openLocation(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Parking Camping',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}