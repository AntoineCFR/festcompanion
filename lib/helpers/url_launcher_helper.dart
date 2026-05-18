import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchUrlWithFallback(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.parse(url);
  try {
    // ✅ Appel direct à launchUrl (sans canLaunchUrl)
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $url')),
      );
    }
  }
}