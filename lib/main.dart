// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudokulegend/Models/state%20management/game_persistent.dart';
import 'package:sudokulegend/Models/state%20management/settings_provider.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:sudokulegend/Screens/pages/statistics/stats.dart';
// import 'package:sudokulegend/Screens/pages/daily%20challenge/daily_challenge_page.dart';
import 'package:sudokulegend/Widgets/notification_service.dart';
import 'package:sudokulegend/Screens/pages/daily%20challenge/daily_challenge_screen.dart';
import 'package:sudokulegend/Screens/pages/home_tab.dart';
import 'package:sudokulegend/Screens/pages/leaderboard/leaderboard_auth_gate.dart';
// import 'package:sudokulegend/Screens/pages/leaderboard/leaderboard_page.dart';
import 'package:sudokulegend/Screens/pages/settings/settings_page.dart';
// import 'package:sudokulegend/Screens/pages/statistics/statistics_page.dart';
import 'package:sudokulegend/Widgets/themes.dart';
import 'package:sudokulegend/firebase_options.dart';
import 'package:sudokulegend/splash_screen.dart';
 


void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sync completed games if user is authenticated and has connectivity
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.ethernet;
      if (hasConnection) {
        await SudokuStorageService.instance.syncCompletedGamesToFirebase();
      }
    } catch (e) {
      debugPrint('[main] Error checking connectivity or syncing: $e');
    }
  }

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.enableNotifications(); // Enable by default for challenges

  await SudokuStorageService.instance.saveFirstUseDate();

  final savedData = (await SudokuStorageService.instance.loadActiveGame()) ??
      <String, dynamic>{};

  // Pre-load settings to avoid theme flicker
  final prefs = await SharedPreferences.getInstance();
  final settingsRaw = prefs.getString('game_settings');
  final initialSettings = settingsRaw != null 
      ? GameSettings.fromJson(jsonDecode(settingsRaw)) 
      : const GameSettings();

  runApp(ProviderScope(overrides: [
    saveGameProvider.overrideWith((ref) => savedData),
    settingsProvider.overrideWith(() => SettingsNotifier(initialSettings)),
  ], child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptheme = ref.watch(settingsProvider);
    final mode = switch (apptheme.theme) {
      AppTheme.light => ThemeMode.light,
      AppTheme.dark => ThemeMode.dark,
      AppTheme.system => ThemeMode.system
    };
    return  MaterialApp(
      title: 'Sudoku Legend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
         pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      ),
      darkTheme: darkMode(),
      themeMode: mode,
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    // This would typically involve a stream listener from NotificationService
    // For simplicity, we assume tapping the notification sets the index
    // to 2 (Daily Challenge Screen)
  }

  final List<Widget> _tabs = [
    const HomeTab(),
    const LeaderboardAuthGate(),
    const DailyChallengeScreen(),
    const StatisticsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
        indicatorColor: const Color.fromARGB(0, 255, 255, 255).withValues(),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => DailyChallengeScreen()));
          } else {
          setState(() => _currentIndex = index);
          }
          },
        labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return const TextStyle(color: Color(0xFF53698A), fontSize: 12,);
          return TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            overflow: TextOverflow.ellipsis
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.home, color: Color(0xFF53698A),), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined, color: Colors.grey[400],), selectedIcon: Icon(Icons.leaderboard, color: Color(0xFF53698A),), label: 'Leaderboard', ),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.emoji_events, color: Color(0xFF53698A),), label: 'Challenges'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF53698A),), label: 'Staistics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.settings, color: Color(0xFF53698A),), label: 'Settings'),
        ],
      ),
    );
  }
}
