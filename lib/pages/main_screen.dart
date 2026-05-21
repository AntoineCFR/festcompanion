import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'events_page.dart';
import 'lineup_page.dart';
import 'timetable_page.dart';
import '../widgets/main/main_drawer.dart';
import '../widgets/main/main_app_bar.dart';
import '../widgets/main/main_bottom_nav_bar.dart';

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
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: MainDrawer(
        username: widget.username,
        userId: widget.userId,
        onLogout: _logout,
      ),
      appBar: MainAppBar(
        username: widget.username,
        userId: widget.userId,
        onMenuPressed: _openDrawer,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          HomePage(username: widget.username, userId: widget.userId),
          EventsPage(username: widget.username, userId: widget.userId),
          LineupPage(username: widget.username, userId: widget.userId),
          TimetablePage(username: widget.username, userId: widget.userId),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}