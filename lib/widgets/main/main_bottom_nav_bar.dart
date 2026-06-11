import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
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
      selectedFontSize: 12,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.whatshot), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Line-up'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Timetable'),
      ],
    );
  }
}