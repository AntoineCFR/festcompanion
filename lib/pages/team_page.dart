import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/team_helper.dart';
import '../helpers/profile_helper.dart';
import '../widgets/team/team_list.dart';
import '../widgets/shared/festival_background.dart';
import 'user_profile_page.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // L'équipe est chargée en arrière-plan peu après le démarrage
    // (loadSecondaryData) → si elle est déjà là, on l'affiche INSTANTANÉMENT
    // sans spinner. Les photos sont en cache (cached_network_image +
    // _photoUrls, 1×/session). Sinon, _loadData la récupère à la demande.
    if (AppDataManager().users.isNotEmpty) _isLoading = false;
    _loadData();
  }

  Future<void> _loadData() async {
    // 1) Rafraîchit la liste en arrière-plan (positions à jour). On ne bloque
    //    l'affichage que s'il n'y a vraiment rien à montrer (1er accès à froid).
    try {
      await AppDataManager().loadUsers();
    } catch (e) {
      if (mounted && AppDataManager().users.isEmpty) {
        AppDataManager().showSnackBar('Erreur chargement équipe : $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // 2) Rafraîchir MA position en arrière-plan : un fix GPS peut prendre
    //    plusieurs secondes et n'a pas à retarder l'affichage de l'équipe.
    //    Une fois obtenu, on rafraîchit l'UI pour refléter ma nouvelle scène.
    final myId = AppDataManager().userId;
    if (myId != null) {
      ProfileHelper.refreshLocationIfEnabled(myId).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = AppDataManager().users;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Équipe'),
        backgroundColor: AppTheme.surface,
      ),
      body: FestivalBackground(
        imageKey: 'featured',
        child: _isLoading && users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun membre',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : TeamList(
                    users: users,
                    onCallPressed: (phone) => TeamHelper.callUser(phone),
                    onLocatePressed: (lat, lng) =>
                        TeamHelper.locateUser(lat, lng),
                    onTap: (User user) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(user: user),
                      ),
                    ),
                  ),
      ),
    );
  }
}