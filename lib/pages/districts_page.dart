import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/district_model.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../services/location_service.dart';
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
        orElse: () => User(id: -1, username: '', userRole: 'user'), // Retourne un User par défaut
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
    try {
      final currentLocation = await LocationService.getCurrentLocation();
      if (currentLocation == null) {
        if (mounted) {
          AppDataManager().showSnackBar('Impossible de récupérer votre position.');
        }
        return;
      }

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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        final districtIndex = _districts.indexWhere((d) => d.district == districtName);
        if (districtIndex == -1) return;

        final coordinates = <String, dynamic>{};
        final district = _districts[districtIndex];

        // Met à jour les coordonnées selon le coin
        switch (corner) {
          case 'avd':
            coordinates.addAll({
              'lat_avd': currentLocation.latitude,
              'lon_avd': currentLocation.longitude,
            });
          case 'avg':
            coordinates.addAll({
              'lat_avg': currentLocation.latitude,
              'lon_avg': currentLocation.longitude,
            });
          case 'arg':
            coordinates.addAll({
              'lat_arg': currentLocation.latitude,
              'lon_arg': currentLocation.longitude,
            });
          case 'ard':
            coordinates.addAll({
              'lat_ard': currentLocation.latitude,
              'lon_ard': currentLocation.longitude,
            });
          case 'rally':
            coordinates.addAll({
              'lat_rally_point': currentLocation.latitude,
              'lon_rally_point': currentLocation.longitude,
            });
        }

        // Ajoute les autres coordonnées existantes
        coordinates.addAll({
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
        });

        await AppDataManager().updateDistrict(districtName, coordinates);
        if (mounted) {
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
        }
      }
    } catch (e) {
      if (mounted) {
        AppDataManager().showSnackBar('Erreur: $e');
      }
    }
  }

  void _openInGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        AppDataManager().showSnackBar('Impossible d\'ouvrir Google Maps.');
      }
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
            onSelected: (district) {
              setState(() {
                _selectedDistrict = district;
              });
            },
            itemBuilder: (context) => _districts
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
                              onSelected: (selected) {
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