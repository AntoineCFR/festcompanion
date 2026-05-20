import 'package:flutter/material.dart';
import '../../helpers/location_helper.dart';
import '../../extensions/build_context_extensions.dart';

class LocationButton extends StatelessWidget {
  const LocationButton({super.key});

  Future<void> _openLocation(BuildContext context) async {
    final success = await LocationHelper.openFestivalLocation();
    if (!success && context.mounted) {
      context.showSnackBar('Impossible d\'ouvrir Google Maps');
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