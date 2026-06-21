import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// L'onglet 0 affiche-t-il la page « Live » (festival en cours) plutôt que
  /// l'accueil ? → le libellé et l'icône du 1er onglet suivent ce mode.
  final bool landingIsLive;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.landingIsLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.background,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white38,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: [
        // 1er onglet dynamique : « Accueil » avant le festival, « Live » pendant.
        landingIsLive
            ? const BottomNavigationBarItem(
                icon: Icon(Icons.sensors), label: 'Live')
            : const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.whatshot), label: 'Events'),
        const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Line-up'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.schedule), label: 'Timetable'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), label: 'Tendances'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.search), label: 'Search'),
      ],
    );
  }
}