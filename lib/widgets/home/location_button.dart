import 'package:flutter/material.dart';
import '../../helpers/location_helper.dart';
import '../../services/app_data_manager.dart';
import '../../extensions/build_context_extensions.dart';

class LocationButton extends StatelessWidget {
  const LocationButton({super.key});

  Future<void> _openLocation(BuildContext context) async {
    final festival = AppDataManager().selectedFestival;
    final parking = festival?.parking;

    bool success = false;
    if (parking != null && parking.isNotEmpty) {
      // Parking renseigné pour CE festival (adresse ou "lat,lon").
      success = await LocationHelper.openMapsQuery(parking);
    } else if (festival != null && festival.city.isNotEmpty) {
      // Pas de parking renseigné : on ouvre au moins la ville du festival
      // courant — jamais le parking d'un autre festival.
      final query = festival.country.isNotEmpty
          ? '${festival.city}, ${festival.country}'
          : festival.city;
      success = await LocationHelper.openMapsQuery(query);
    }

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
            icon: const Icon(Icons.place, color: Colors.white, size: 30),
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