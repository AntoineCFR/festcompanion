import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/app_data_manager.dart';
import '../helpers/team_helper.dart';
import '../helpers/profile_helper.dart';
import '../widgets/team/team_list.dart';
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Rafraîchit ma propre position (si partage activé) avant d'afficher l'équipe.
      final myId = AppDataManager().userId;
      if (myId != null) {
        await ProfileHelper.refreshLocationIfEnabled(myId);
      }
      await AppDataManager().loadUsers();
    } catch (e) {
      if (mounted) AppDataManager().showSnackBar('Erreur chargement équipe : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = AppDataManager().users;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Équipe'),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
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
                  onLocatePressed: (lat, lng) => TeamHelper.locateUser(lat, lng),
                  onTap: (User user) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(user: user),
                    ),
                  ),
                ),
    );
  }
}