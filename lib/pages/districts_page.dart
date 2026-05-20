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
      await AppDataManager().loadDistricts();
      final districts = AppDataManager().districts;
      if (mounted) {
        setState(() {
          _districts = districts;
          _isLoading = false;
        });
      }

      // Récupère le rôle de l'utilisateur
      final users = AppDataManager().users;
      final user = users.firstWhere(
        (u) => u.id == widget.userId,
        orElse: () => User(id: -1, username: '', userRole: 'user'),
      );
      if (mounted) {
        setState(() {
          _userRole = user.userRole;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Districts'),
        backgroundColor: Colors.grey[800],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String district) {
              setState(() {
                _selectedDistrict = district;
              });
            },
            itemBuilder: (BuildContext context) => _districts
                .map((district) => PopupMenuItem<String>(
                      value: district.district,
                      child: Text(district.district),
                    ))
                .toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _districts.map((district) {
                          final isSelected = _selectedDistrict == district.district;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(district.district),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedDistrict = selected ? district.district : null;
                                });
                              },
                              backgroundColor: Colors.grey[700],
                              selectedColor: Colors.blue[700],
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._districts
                      .where((d) => _selectedDistrict == null || d.district == _selectedDistrict)
                      .map((district) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: DistrictCard(
                              district: district,
                              isAdmin: _isAdmin,
                              onSetCoordinates: _setCoordinates,
                              onOpenInMaps: _openInGoogleMaps,
                            ),
                          ))
                ],
              ),
            ),
    );
  }
}