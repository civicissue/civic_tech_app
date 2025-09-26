import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'features/community/ui/community_screen.dart';
import 'features/report/ui/create_report_screen.dart';
import 'features/report/ui/my_reports_screen.dart';
import 'features/community/ui/community_list_screen.dart';
import 'features/rewards/ui/leaderboard_screen.dart';
import 'features/profile/ui/profile_screen.dart';

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final appInitProvider = FutureProvider<void>((ref) async {
  // Firebase is already initialized in main(), so just add polish delay
  await Future<void>.delayed(const Duration(milliseconds: 600));
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase before anything else
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
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
      home: const AppRoot(),
    );
  }
}

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInit = ref.watch(appInitProvider);
    final authState = ref.watch(authStateProvider);

    return appInit.when(
      data: (_) => authState.when(
        data: (user) =>
            user != null ? const CivicTechApp() : const LoginScreen(),
        loading: () => const _LoadingScreen(),
        error: (e, _) => _ErrorScreen(error: e.toString()),
      ),
      loading: () => const _SplashScreen(),
      error: (e, _) => _ErrorScreen(error: e.toString()),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: Center(
        child: _Glass(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: const Text(
            'CivicTech',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0E0E10),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class CivicTechApp extends ConsumerStatefulWidget {
  const CivicTechApp({super.key});

  @override
  ConsumerState<CivicTechApp> createState() => _CivicTechAppState();
}

class _CivicTechAppState extends ConsumerState<CivicTechApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      CreateReportScreen(),
      MyReportsScreen(),
      CommunityScreen(),
      CommunityListScreen(),
      LeaderboardScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicTech'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authStateProvider);
              return auth.when(
                data: (user) => user != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Text(
                                    (user.displayName ?? user.email ?? 'U')
                                        .characters
                                        .first
                                        .toUpperCase(),
                                  )
                                : null,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_a_photo_outlined),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'My Reports',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Leaders',
          ),
        ],
      ),
    );
  }
}

// Legacy placeholder pages removed in favor of real screens

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
