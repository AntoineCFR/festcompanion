import 'package:flutter/material.dart';
import '../services/app_data_manager.dart';
import '../widgets/team/team_app_bar.dart';
import '../widgets/team/team_list.dart';
import '../helpers/team_helper.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final appData = AppDataManager();

  Future<void> _refreshUsers() async {
    try {
      await appData.loadUsers();
    } catch (e) {
      if (mounted) {
        AppDataManager().showSnackBar('Erreur : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TeamAppBar(onRefreshPressed: _refreshUsers),
      body: Container(
        color: Colors.grey[900],
        child: TeamList(
          users: appData.users,
          onCallPressed: (phoneNumber) => TeamHelper.callUser(phoneNumber),
          onLocatePressed: (lat, lng) => TeamHelper.locateUser(lat, lng),
        ),
      ),
    );
  }
}