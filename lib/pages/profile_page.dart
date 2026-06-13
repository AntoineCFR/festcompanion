import 'package:flutter/material.dart';
import '../services/app_data_manager.dart';
import '../models/user_model.dart';
import '../models/profile_data_model.dart';
import '../widgets/profile/profile_app_bar.dart';
import '../widgets/profile/profile_photo.dart';
import '../widgets/profile/profile_text_field.dart';
import '../widgets/profile/location_toggle.dart';
import '../widgets/profile/coordinates_section.dart';
import '../widgets/shared/festival_background.dart';
import '../helpers/profile_helper.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final int userId;

  const ProfilePage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _phoneController = TextEditingController();
  ProfileData? _profileData;
  bool _isLoading = true; // ✅ État de chargement explicite

  void _showSnackBar(String message) {
    AppDataManager().showSnackBar(message);
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (!mounted) return;

    try {
      final locationEnabled = await ProfileHelper.loadLocationEnabled();
      final user = AppDataManager().users.firstWhere(
        (u) => u.id == widget.userId,
        orElse: () => User(id: widget.userId, username: widget.username),
      );
      setState(() {
        _profileData = ProfileData(
          user: user,
          locationEnabled: locationEnabled,
        );
        _phoneController.text = _profileData!.phoneNumber ?? '';
        _isLoading = false; // ✅ Chargement terminé
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false); // ✅ Désactive le chargement même en cas d'erreur
        _showSnackBar('Erreur lors du chargement : $e');
      }
    }
  }

  Future<void> _handlePhotoUpload(String? photoUrl) async {
    if (!mounted || photoUrl == null) return;

    try {
      AppDataManager().updateUserPhoto(widget.userId, photoUrl);
      setState(() {
        _profileData = _profileData?.copyWith(
          user: _profileData!.user.copyWith(photoUrl: photoUrl),
          isUploading: false,
        );
      });
      _showSnackBar('Photo mise à jour !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    }
  }

  Future<void> _handleLocationToggle(bool value) async {
    if (!mounted) return;

    if (value) {
      try {
        // Active le partage : on prend un premier fix (demande la permission
        // "pendant l'utilisation" au passage) et on l'envoie.
        await ProfileHelper.refreshLocation(widget.userId);
        setState(() {
          _profileData = _profileData?.copyWith(
            locationEnabled: true,
            user: AppDataManager().users.firstWhere(
              (u) => u.id == widget.userId,
              orElse: () => _profileData!.user,
            ),
          );
        });
        await ProfileHelper.saveLocationEnabled(true);
        _showSnackBar('Partage de position activé. Votre position se met à jour '
            'à l\'ouverture de l\'app et lors d\'une alerte "perdu".');
      } catch (e) {
        setState(() => _profileData = _profileData?.copyWith(locationEnabled: false));
        _showSnackBar('Erreur de localisation : $e');
      }
    } else {
      setState(() => _profileData = _profileData?.copyWith(locationEnabled: false));
      await ProfileHelper.saveLocationEnabled(false);
      _showSnackBar('Partage de position désactivé.');
    }
  }

  Future<void> _refreshLocation() async {
    if (!mounted) return;

    try {
      setState(() => _profileData = _profileData?.copyWith(isUploading: true));
      await ProfileHelper.refreshLocation(widget.userId);
      setState(() {
        _profileData = _profileData?.copyWith(
          isUploading: false,
          user: AppDataManager().users.firstWhere(
            (u) => u.id == widget.userId,
            orElse: () => _profileData!.user,
          ),
        );
      });
      _showSnackBar('Localisation rafraîchie et sauvegardée !');
    } catch (e) {
      setState(() => _profileData = _profileData?.copyWith(isUploading: false));
      _showSnackBar('Erreur : $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;

    try {
      await ProfileHelper.saveProfile(widget.userId, _phoneController.text);
      setState(() {
        _profileData = _profileData?.copyWith(
          user: _profileData!.user.copyWith(phoneNumber: _phoneController.text),
        );
      });
      _showSnackBar('Numéro de téléphone mis à jour !');
    } catch (e) {
      _showSnackBar('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Gestion des états de chargement et d'erreur
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 40),
              const SizedBox(height: 20),
              const Text('Impossible de charger le profil'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initData, // ✅ Bouton pour réessayer
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profileData!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ProfileAppBar(onSavePressed: _saveProfile),
      body: FestivalBackground(
        imageKey: 'featured',
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                ProfilePhoto(
                  userId: widget.userId,
                  onPhotoUploaded: _handlePhotoUpload,
                  isUploading: profile.isUploading,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajouter une photo',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                ProfileTextField(
                  labelText: 'Nom d\'utilisateur',
                  controller: TextEditingController(text: widget.username),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                ProfileTextField(
                  labelText: 'ID Utilisateur',
                  controller: TextEditingController(text: widget.userId.toString()),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                ProfileTextField(
                  labelText: 'Numéro de téléphone',
                  hintText: 'Format : +33 1 23 45 67 89',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                LocationToggle(
                  value: profile.locationEnabled,
                  onChanged: _handleLocationToggle,
                  onLocationRefresh: _refreshLocation,
                ),
                const SizedBox(height: 16),
                CoordinatesSection(
                  latitude: profile.latitude,
                  longitude: profile.longitude,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}