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
import '../helpers/phone_helper.dart';

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
  bool _isEditingPhone = false; // mode édition du numéro (Éditer → Valider)
  bool _isSavingPhone = false; // sauvegarde du numéro en cours

  void _showSnackBar(String message) {
    AppDataManager().showSnackBar(message);
  }

  @override
  void initState() {
    super.initState();
    _initData();
    // L'équipe arrive en arrière-plan (cache puis réseau) : quand elle se peuple,
    // on réinjecte le user à jour → le numéro passe de « Non renseigné » à sa
    // vraie valeur sans rouvrir la page (corrige l'affichage au redémarrage).
    AppDataManager().dataRevision.addListener(_onUsersUpdated);
  }

  @override
  void dispose() {
    AppDataManager().dataRevision.removeListener(_onUsersUpdated);
    _phoneController.dispose();
    super.dispose();
  }

  void _onUsersUpdated() {
    if (!mounted || _isEditingPhone || _profileData == null) return;
    final user = AppDataManager().users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => _profileData!.user,
    );
    // Ne rebuild que si quelque chose a réellement changé (évite les rebuilds
    // inutiles à chaque dataRevision).
    if (user.phoneNumber != _profileData!.phoneNumber ||
        user.lastLat != _profileData!.latitude ||
        user.lastLng != _profileData!.longitude) {
      setState(() => _profileData = _profileData!.copyWith(user: user));
    }
  }

  /// Affichage IMMÉDIAT depuis le cache local (le user est déjà chargé au
  /// démarrage) — pas de spinner bloquant. Le consentement localisation (local)
  /// et le rafraîchissement serveur de la fiche arrivent ensuite : ce dernier en
  /// arrière-plan, signalé par la pastille + appliqué via le listener
  /// [dataRevision]. Même logique que les autres pages : variables locales d'abord.
  void _initData() {
    final user = AppDataManager().users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => User(id: widget.userId, username: widget.username),
    );
    _profileData = ProfileData(user: user);
    _phoneController.text = user.phoneNumber ?? '';
    _isLoading = false;

    // Consentement localisation (SharedPreferences, quasi instantané).
    ProfileHelper.loadLocationEnabled().then((enabled) {
      if (!mounted) return;
      setState(
          () => _profileData = _profileData?.copyWith(locationEnabled: enabled));
    });

    // Rafraîchit les données serveur (la fiche = l'enregistrement utilisateur)
    // en arrière-plan → pastille « mise à jour » + MAJ via le listener.
    AppDataManager().loadUsers().catchError((_) {});
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

    // 1) MAJ LOCALE IMMÉDIATE : on bascule le toggle, on persiste le consentement
    //    et on affiche le message TOUT DE SUITE — sans attendre le fix GPS/réseau
    //    (qui peut prendre plusieurs secondes). Le toggle = un simple consentement
    //    de partage ; la position se met à jour ensuite, en arrière-plan.
    setState(() => _profileData = _profileData?.copyWith(locationEnabled: value));
    await ProfileHelper.saveLocationEnabled(value); // SharedPreferences, instantané

    if (!value) {
      _showSnackBar('Partage de position désactivé.');
      return;
    }

    _showSnackBar('Partage de position activé. Votre position se met à jour '
        'à l\'ouverture de l\'app et lors d\'une alerte "perdu".');

    // 2) Premier fix EN ARRIÈRE-PLAN (déclenche la demande de permission au
    //    passage). Best-effort : met à jour les coordonnées affichées quand il
    //    arrive, n'annule pas le consentement en cas d'échec/refus.
    ProfileHelper.refreshLocation(widget.userId).then((_) {
      if (!mounted) return;
      setState(() {
        _profileData = _profileData?.copyWith(
          user: AppDataManager().users.firstWhere(
            (u) => u.id == widget.userId,
            orElse: () => _profileData!.user,
          ),
        );
      });
    }).catchError((_) {
      // Fix best-effort : un échec (permission refusée, GPS lent) ne remet pas
      // en cause le partage. La position se mettra à jour à la prochaine occasion.
    });
  }

  void _startEditPhone() {
    setState(() {
      _phoneController.text = _profileData?.phoneNumber ?? '';
      _isEditingPhone = true;
    });
  }

  void _cancelEditPhone() {
    setState(() {
      _phoneController.text = _profileData?.phoneNumber ?? '';
      _isEditingPhone = false;
    });
  }

  /// Valide + normalise le numéro au format français (+33 …) puis l'enregistre.
  /// Refuse une saisie invalide ou vide → plus de sauvegarde « à blanc »
  /// accidentelle (ancienne disquette) qui pouvait effacer le numéro.
  Future<void> _validatePhone() async {
    if (!mounted) return;

    final normalized = PhoneHelper.normalizeFrench(_phoneController.text);
    if (normalized == null) {
      _showSnackBar('Numéro invalide. Format attendu : +33 6 XX XX XX XX.');
      return;
    }

    setState(() => _isSavingPhone = true);
    try {
      await ProfileHelper.saveProfile(widget.userId, normalized);
      if (!mounted) return;
      setState(() {
        _profileData = _profileData?.copyWith(
          user: _profileData!.user.copyWith(phoneNumber: normalized),
        );
        _phoneController.text = normalized;
        _isEditingPhone = false;
        _isSavingPhone = false;
      });
      _showSnackBar('Numéro de téléphone mis à jour !');
    } catch (e) {
      if (mounted) setState(() => _isSavingPhone = false);
      _showSnackBar('Erreur : $e');
    }
  }

  /// Champ « Numéro de téléphone » : lecture seule + bouton Éditer, ou champ
  /// éditable + Valider/Annuler. Seule donnée modifiable de la fiche.
  Widget _buildPhoneSection() {
    final saved = _profileData?.phoneNumber;

    if (!_isEditingPhone) {
      return Row(
        children: [
          Expanded(
            child: ProfileTextField(
              labelText: 'Numéro de téléphone',
              controller: TextEditingController(
                text: (saved == null || saved.isEmpty) ? 'Non renseigné' : saved,
              ),
              enabled: false,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Modifier le numéro',
            onPressed: _startEditPhone,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileTextField(
          labelText: 'Numéro de téléphone',
          hintText: 'Format : +33 6 12 34 56 78',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isSavingPhone ? null : _cancelEditPhone,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSavingPhone ? null : _validatePhone,
                child: _isSavingPhone
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Valider'),
              ),
            ),
          ],
        ),
      ],
    );
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
      appBar: const ProfileAppBar(),
      body: FestivalBackground(
        imageKey: 'featured',
        refreshDomains: const [LoadDomain.team],
        refreshLabel: 'Mise à jour du profil…',
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
                _buildPhoneSection(),
                const SizedBox(height: 16),
                LocationToggle(
                  value: profile.locationEnabled,
                  onChanged: _handleLocationToggle,
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