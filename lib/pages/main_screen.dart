import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../helpers/featured_helper.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'featured_page.dart';
import 'events_page.dart';
import 'lineup_page.dart';
import 'timetable_page.dart';
import 'trending_page.dart';
import 'tag_browser_page.dart';
import '../widgets/main/main_drawer.dart';
import '../widgets/main/main_app_bar.dart';
import '../widgets/main/main_bottom_nav_bar.dart';

/// Choix de la page d'atterrissage (onglet 0).
/// - auto : « Live » si le festival est en cours, sinon « Accueil ».
/// - home / featured : forcé depuis le drawer.
enum LandingMode { auto, home, featured }

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
  LandingMode _landingMode = LandingMode.auto;
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

  /// L'onglet 0 doit-il afficher « Live » ?
  bool get _landingShowsFeatured {
    switch (_landingMode) {
      case LandingMode.home:
        return false;
      case LandingMode.featured:
        return true;
      case LandingMode.auto:
        return FeaturedHelper.isFestivalLive();
    }
  }

  void _goToLanding(LandingMode mode) {
    setState(() {
      _landingMode = mode;
      _currentIndex = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: MainDrawer(
        username: widget.username,
        userId: widget.userId,
        onLogout: _logout,
        onShowHome: () => _goToLanding(LandingMode.home),
        onShowFeatured: () => _goToLanding(LandingMode.featured),
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
          _landingShowsFeatured
              ? FeaturedPage(username: widget.username, userId: widget.userId)
              : HomePage(username: widget.username, userId: widget.userId),
          EventsPage(username: widget.username, userId: widget.userId),
          LineupPage(username: widget.username, userId: widget.userId),
          TimetablePage(username: widget.username, userId: widget.userId),
          const TrendingView(),
          const TagBrowserView(),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        landingIsLive: _landingShowsFeatured,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Toute navigation par la barre du bas RÉTABLIT la logique auto de
            // l'onglet « Accueil » (Accueil avant le festival, « Live »
            // pendant). Le choix « Live » fait depuis le drawer n'est donc
            // qu'un aperçu ponctuel, il ne remplace plus l'accueil en permanence.
            _landingMode = LandingMode.auto;
          });
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}