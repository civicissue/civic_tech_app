import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'features/auth/auth_gate.dart';
import 'features/community/ui/community_screen.dart';
import 'features/report/ui/create_report_screen.dart';
import 'features/report/ui/my_reports_screen.dart';
import 'features/community/ui/community_list_screen.dart';
import 'features/admin/ui/admin_screen.dart';
import 'features/rewards/ui/leaderboard_screen.dart';
import 'features/profile/ui/profile_screen.dart';

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
}

final appInitProvider = FutureProvider<void>((ref) async {
  await _initFirebase();
  await Future<void>.delayed(const Duration(milliseconds: 600)); // small polish delay
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6EA8FE),
        surface: Color(0xFF0E0E10),
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0E10),
      useMaterial3: true,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CivicTech',
      theme: theme,
      home: const AnimatedSplash(),
    );
  }
}

class AnimatedSplash extends ConsumerStatefulWidget {
  const AnimatedSplash({super.key});

  @override
  ConsumerState<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends ConsumerState<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void initState() {
    super.initState();
    ref.read(appInitProvider.future).then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 240),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0E0E10), Color(0xFF111518)]))),
          Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
              child: _Glass(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                child: const Text(
                  'CivicTech',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;
  
  @override
  Widget build(BuildContext context) {
    final pages = const [
      AuthGate(child: CreateReportScreen()),
      AuthGate(child: MyReportsScreen()),
      CommunityScreen(),
      CommunityListScreen(),
      AdminScreen(),
      LeaderboardScreen(),
      AuthGate(child: ProfileScreen()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('CivicTech')),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_a_photo_outlined), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'My Reports'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.groups_2_outlined), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Leaders'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Glass({required this.child, this.padding = const EdgeInsets.all(16)});
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}
