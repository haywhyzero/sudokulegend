import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudokulegend/Models/state%20management/game_persistent.dart';
import 'package:sudokulegend/Models/state%20management/settings_provider.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
// import 'package:sudokulegend/Screens/pages/daily%20challenge/daily_challenge_page.dart';
import 'package:sudokulegend/Screens/pages/daily%20challenge/daily_challenge_screen.dart';
import 'package:sudokulegend/Screens/pages/home_tab.dart';
import 'package:sudokulegend/Screens/pages/leaderboard/leaderboard_auth_gate.dart';
// import 'package:sudokulegend/Screens/pages/leaderboard/leaderboard_page.dart';
import 'package:sudokulegend/Screens/pages/settings/settings_page.dart';
// import 'package:sudokulegend/Screens/pages/statistics/statistics_page.dart';
import 'package:sudokulegend/Widgets/themes.dart';
import 'package:sudokulegend/firebase_options.dart';
import 'package:sudokulegend/splash_screen.dart';

import 'Screens/pages/statistics/stats.dart';


void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

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
      theme: ThemeData.light(),
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

  final List<Widget> _tabs = [
    const HomeTab(),
    // const LeaderboardPage(),
    const LeaderboardAuthGate(),
    // const DailyChallengePage(),
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
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return const TextStyle(color: Color(0xFF53698A), fontSize: 12,);
          return TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.home, color: Color(0xFF53698A),), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined, color: Colors.grey[400],), selectedIcon: Icon(Icons.leaderboard, color: Color(0xFF53698A),), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.emoji_events, color: Color(0xFF53698A),), label: 'Challenges'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF53698A),), label: 'Staistics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined, color: Colors.grey[400]), selectedIcon: Icon(Icons.settings, color: Color(0xFF53698A),), label: 'Settings'),
        ],
      ),
    );
  }
}
