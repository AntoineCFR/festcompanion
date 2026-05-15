// lib/pages/main_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'home_page.dart'; // ✅ Nouveau import
import 'lineup_page.dart';
import 'timetable_page.dart';

class MainScreen extends StatefulWidget {
  final String username;
  final int userId;

  const MainScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 0: Accueil, 1: Line-up, 2: Timetable
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.clearLogin();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrema Outdoor 2026'), // ✅ Titre mis à jour
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                widget.username,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          HomePage(username: widget.username, userId: widget.userId), // ✅ Nouvelle page
          LineupPage(username: widget.username, userId: widget.userId),
          TimetablePage(username: widget.username, userId: widget.userId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem( // ✅ Nouveau bouton
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Line-up',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Timetable',
          ),
        ],
      ),
    );
  }
}