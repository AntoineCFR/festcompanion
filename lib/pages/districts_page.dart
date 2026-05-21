import 'package:flutter/material.dart';
import '../models/district_model.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/location_helper.dart';
import '../widgets/districts/district_card.dart';

class DistrictsPage extends StatefulWidget {
  final String username;
  final int userId;

  const DistrictsPage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<DistrictsPage> createState() => _DistrictsPageState();
}

class _DistrictsPageState extends State<DistrictsPage> {
  List<District> _districts = [];
  bool _isLoading = true;
  String? _selectedDistrict;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Charge districts et utilisateurs en parallèle
      await Future.wait([
        AppDataManager().loadDistricts(),
        AppDataManager().loadUsers(),
      ]);

      if (!mounted) return;

      final districts = List<District>.from(AppDataManager().districts)
        ..sort((a, b) => a.district.compareTo(b.district));

      final user = AppDataManager().users.firstWhere(
        (u) => u.id == widget.userId,
        orElse: () => User(id: -1, username: '', userRole: 'user'),
      );

      setState(() {
        _districts = districts;
        _selectedDistrict = districts.isNotEmpty ? districts.first.district : null;
        _userRole = user.userRole;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isAdmin => _userRole == 'admin';

  Future<void> _setCoordinates(String districtName, String corner) async {
    // Vérifie que le widget est toujours monté AVANT toute opération async
    if (!mounted) return;

    try {
      final currentLocation = await LocationHelper.tryGetCurrentPosition();
      if (currentLocation == null) {
        AppDataManager().showSnackBar('Impossible de récupérer votre position.');
        return;
      }

      // Vérifie à nouveau avant d'ouvrir la dialog
      if (!mounted) return;

      // Demande de confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Confirmer'),
          content: Text(
            'Voulez-vous définir la position actuelle pour le $corner de $districtName ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      // Vérifie une dernière fois avant de modifier l'état
      if (confirm != true || !mounted) return;

      final districtIndex = _districts.indexWhere((d) => d.district == districtName);
      if (districtIndex == -1) return;

      final district = _districts[districtIndex];
      final coordinates = <String, dynamic>{
        'lat_avg': district.latAvg,
        'lon_avg': district.lonAvg,
        'lat_avd': district.latAvd,
        'lon_avd': district.lonAvd,
        'lat_arg': district.latArg,
        'lon_arg': district.lonArg,
        'lat_ard': district.latArd,
        'lon_ard': district.lonArd,
        'lat_rally_point': district.latRallyPoint,
        'lon_rally_point': district.lonRallyPoint,
      };

      // Met à jour selon le coin
      switch (corner) {
        case 'avd':
          coordinates['lat_avd'] = currentLocation.latitude;
          coordinates['lon_avd'] = currentLocation.longitude;
          break;
        case 'avg':
          coordinates['lat_avg'] = currentLocation.latitude;
          coordinates['lon_avg'] = currentLocation.longitude;
          break;
        case 'arg':
          coordinates['lat_arg'] = currentLocation.latitude;
          coordinates['lon_arg'] = currentLocation.longitude;
          break;
        case 'ard':
          coordinates['lat_ard'] = currentLocation.latitude;
          coordinates['lon_ard'] = currentLocation.longitude;
          break;
        case 'rally':
          coordinates['lat_rally_point'] = currentLocation.latitude;
          coordinates['lon_rally_point'] = currentLocation.longitude;
          break;
      }

      await AppDataManager().updateDistrict(districtName, coordinates);

      // Vérifie une dernière fois avant setState
      if (!mounted) return;

      setState(() {
        _districts[districtIndex] = district.copyWith(
          latAvg: corner == 'avg' ? currentLocation.latitude : district.latAvg,
          lonAvg: corner == 'avg' ? currentLocation.longitude : district.lonAvg,
          latAvd: corner == 'avd' ? currentLocation.latitude : district.latAvd,
          lonAvd: corner == 'avd' ? currentLocation.longitude : district.lonAvd,
          latArg: corner == 'arg' ? currentLocation.latitude : district.latArg,
          lonArg: corner == 'arg' ? currentLocation.longitude : district.lonArg,
          latArd: corner == 'ard' ? currentLocation.latitude : district.latArd,
          lonArd: corner == 'ard' ? currentLocation.longitude : district.lonArd,
          latRallyPoint: corner == 'rally' ? currentLocation.latitude : district.latRallyPoint,
          lonRallyPoint: corner == 'rally' ? currentLocation.longitude : district.lonRallyPoint,
        );
      });
      AppDataManager().showSnackBar('Coordonnées mises à jour !');
    } catch (e) {
      if (mounted) {
        AppDataManager().showSnackBar('Erreur: $e');
      }
    }
  }

  void _openInGoogleMaps(double lat, double lng) async {
    final success = await LocationHelper.openInGoogleMaps(
      latitude: lat,
      longitude: lng,
    );
    if (!success && mounted) {
      AppDataManager().showSnackBar('Impossible d\'ouvrir Google Maps.');
    }
  }

  void _showDistrictPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: _districts
            .map(
              (d) => ListTile(
                title: Text(
                  d.district,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: d.district == _selectedDistrict
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: d.district == _selectedDistrict
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _selectedDistrict = d.district);
                  Navigator.pop(ctx);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _selectedDistrict != null
        ? _districts.where((d) => d.district == _selectedDistrict).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Districts'),
        backgroundColor: Colors.grey[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bandeau sélecteur — cliquable
                GestureDetector(
                  onTap: _districts.isNotEmpty ? _showDistrictPicker : null,
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedDistrict ?? 'Aucun district',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                // Carte du district sélectionné
                if (current != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DistrictCard(
                        district: current,
                        isAdmin: _isAdmin,
                        onSetCoordinates: _setCoordinates,
                        onOpenInMaps: _openInGoogleMaps,
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Aucun district disponible',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}