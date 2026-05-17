// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/app_data_manager.dart';
import '../services/api_service.dart';

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
  bool _locationEnabled = false;
  bool _isUploading = false;

  // ✅ Méthode centralisée et sécurisée pour les SnackBars
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLocationEnabled();
    _initUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _locationEnabled = prefs.getBool('location_enabled') ?? false;
      });
    }
  }

  Future<void> _saveLocationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_enabled', value);
  }

  void _initUserData() {
    final appData = AppDataManager();
    final user = appData.users.firstWhere(
      (u) => u['id'] == widget.userId,
      orElse: () => <String, dynamic>{},
    );
    _phoneController.text = user['phone_number']?.toString() ?? '';
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _uploadPhoto() async {
    if (!mounted) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_photos/${widget.userId}.jpg');
      await ref.putFile(File(image.path));

      if (!mounted) return;
      final photoUrl = await ref.getDownloadURL();

      final appData = AppDataManager();
      appData.updateUserPhoto(widget.userId, photoUrl);

      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Photo mise à jour !');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Erreur : $e');
      }
    }
  }

  Future<void> _refreshLocation() async {
    if (!mounted) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showSnackBar('Autorisation de localisation refusée.');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        final appData = AppDataManager();
        appData.updateUserLocation(widget.userId, position.latitude, position.longitude);
        await ApiService.updateUserLocation(
          widget.userId,
          position.latitude,
          position.longitude,
        );
        _showSnackBar('Localisation rafraîchie et sauvegardée !');
      }
    } catch (e) {
      _showSnackBar('Erreur : $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;

    try {
      await ApiService.updateUserPhone(widget.userId, _phoneController.text);

      final appData = AppDataManager();
      appData.updateUserPhone(widget.userId, _phoneController.text);

      _showSnackBar('Numéro de téléphone mis à jour !');
    } catch (e) {
      _showSnackBar('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppDataManager();
    final user = appData.users.firstWhere(
      (u) => u['id'] == widget.userId,
      orElse: () => <String, dynamic>{},
    );
    final photoUrl = appData.getPhotoUrl(widget.userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Photo de profil
                GestureDetector(
                  onTap: _uploadPhoto,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: photoUrl != null
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.white54)
                            : null,
                      ),
                      if (_isUploading)
                        const CircularProgressIndicator(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajouter une photo',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 30),

                // Champ username
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  style: const TextStyle(color: Colors.white),
                  controller: TextEditingController(text: widget.username),
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // Champ user_id
                TextField(
                  decoration: InputDecoration(
                    labelText: 'ID Utilisateur',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  style: const TextStyle(color: Colors.white),
                  controller: TextEditingController(text: widget.userId.toString()),
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // Numéro de téléphone
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Format : +33 1 23 45 67 89',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                ),
                const SizedBox(height: 16),

                // Toggle localisation
                Row(
                  children: [
                    const Text(
                      'Activer la localisation',
                      style: TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Switch(
                      value: _locationEnabled,
                      onChanged: (bool value) async {
                        if (value) {
                          LocationPermission permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                            if (permission != LocationPermission.whileInUse &&
                                permission != LocationPermission.always) {
                              _showSnackBar('Autorisation de localisation refusée. Impossible d\'activer.');
                              return;
                            }
                          }
                          try {
                            final position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                            );
                            if (mounted) {
                              setState(() {
                                _locationEnabled = true;
                              });
                              await _saveLocationEnabled(true);
                              final appData = AppDataManager();
                              appData.updateUserLocation(
                                widget.userId,
                                position.latitude,
                                position.longitude,
                              );
                              await ApiService.updateUserLocation(
                                widget.userId,
                                position.latitude,
                                position.longitude,
                              );
                              _showSnackBar('Localisation activée et sauvegardée !');
                            }
                          } catch (e) {
                            _showSnackBar('Erreur de localisation : $e');
                            return;
                          }
                        } else {
                          setState(() {
                            _locationEnabled = false;
                          });
                          await _saveLocationEnabled(false);
                        }
                      },
                      activeThumbColor: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Latitude et Longitude
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        style: const TextStyle(color: Colors.white),
                        controller: TextEditingController(
                          text: user['last_lat']?.toStringAsFixed(6) ?? '',
                        ),
                        enabled: false,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _refreshLocation,
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        style: const TextStyle(color: Colors.white),
                        controller: TextEditingController(
                          text: user['last_lng']?.toStringAsFixed(6) ?? '',
                        ),
                        enabled: false,
                      ),
                    ),
                  ],
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