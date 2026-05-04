import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/select_location_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const IndekskosApp());
}

// Shell route with bottom navigation
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen()),
        GoRoute(path: '/favorite', builder: (context, state) => const _PlaceholderScreen(title: 'Favorite', icon: Icons.favorite_outline)),
        GoRoute(path: '/booking', builder: (context, state) => const _PlaceholderScreen(title: 'My Booking', icon: Icons.calendar_today_outlined)),
        GoRoute(path: '/profile', builder: (context, state) => const _PlaceholderScreen(title: 'Profile', icon: Icons.person_outline)),
      ],
    ),
    GoRoute(path: '/detail/:id', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) {
      final id = int.parse(state.pathParameters['id']!);
      return DetailScreen(listingId: id);
    }),
    GoRoute(path: '/admin/login', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const AdminLoginScreen()),
    GoRoute(path: '/admin/dashboard', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const AdminDashboardScreen()),
  ],
);

class IndekskosApp extends StatefulWidget {
  const IndekskosApp({super.key});

  @override
  State<IndekskosApp> createState() => _IndekskosAppState();
}

class _IndekskosAppState extends State<IndekskosApp> {
  bool _checkingLocation = true;
  bool _locationSet = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isSet = prefs.getBool('location_set') ?? false;
    setState(() {
      _locationSet = isSet;
      _checkingLocation = false;
    });
  }

  void _onLocationComplete() {
    setState(() => _locationSet = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLocation) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      );
    }

    if (!_locationSet) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          textTheme: GoogleFonts.interTextTheme(),
          useMaterial3: true,
        ),
        home: SelectLocationScreen(onComplete: _onLocationComplete),
      );
    }

    return MaterialApp.router(
      title: 'Indekskos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

/// Main scaffold with bottom navigation bar.
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/favorite')) return 2;
    if (location.startsWith('/booking')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/'); break;
              case 1: context.go('/explore'); break;
              case 2: context.go('/favorite'); break;
              case 3: context.go('/booking'); break;
              case 4: context.go('/profile'); break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'Favorite'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'My Booking'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screen for tabs not yet implemented.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Segera hadir', style: TextStyle(color: Colors.grey[400])),
        ]),
      ),
    );
  }
}
