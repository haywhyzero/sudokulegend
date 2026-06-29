import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sudokulegend/Models/data/difficulty_level.dart';
import 'package:sudokulegend/Models/state%20management/game_persistent.dart';
import 'package:sudokulegend/Models/state%20management/settings_provider.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:sudokulegend/Screens/pages/game/game_page.dart';
import 'package:sudokulegend/Widgets/difficulties.dart';
import 'package:sudokulegend/Widgets/menu_button.dart';
import 'package:sudokulegend/Widgets/notification_service.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  late List<DifficultyLevel> levels;

  @override
  void initState() {
    super.initState();

    updateStats();

    // _initGame();
    int hardGamesCompleted = 0; //from SharedPreferences
    int expertGamesCompleted = 0;
    int masterGamesCompleted = 0;
    int extremeGamesCompleted = 0;
    levels = [
      DifficultyLevel("Easy", 0, false),
      DifficultyLevel("Medium", 0, false),
      DifficultyLevel("Hard", 0, false),
      DifficultyLevel("Expert", 10, hardGamesCompleted < 10),
      DifficultyLevel("Master", 15, expertGamesCompleted < 15),
      DifficultyLevel("Extreme", 20, masterGamesCompleted < 20),
      DifficultyLevel("16x16", 50, extremeGamesCompleted < 50),
    ];
  }

  void updateStats() async {
    await SudokuStorageService.instance.updateStatistics();
    await requestPermissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> requestPermissions() async {
    try {
      var cameraStatus = await Permission.camera.request();
      var storageStatus = await Permission.photos.request();
      var audioStatus = await Permission.audio.request();
      var notificationStatus = await Permission.notification.request();

      if (cameraStatus.isGranted &&
          storageStatus.isGranted &&
          audioStatus.isGranted &&
          notificationStatus.isGranted) {
        ref.read(isPermissionProvider.notifier).state = true;
      } else if (cameraStatus.isDenied ||
          storageStatus.isDenied ||
          audioStatus.isDenied ||
          notificationStatus.isDenied) {
        ref.read(isPermissionProvider.notifier).state = false;
        ref.read(settingsProvider.notifier).toggleNotification(false);
      } else if (cameraStatus.isPermanentlyDenied ||
          audioStatus.isPermanentlyDenied ||
          notificationStatus.isPermanentlyDenied) {
        openAppSettings();
      }
    } catch (e) {
      debugPrint("e: $e");
    }
  }

  String _formatTime(int seconds) {
    final int hours = (seconds ~/ 3600);
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final h = hours > 0 ? '$hours:' : '';

    return "$h$m:$s";
  }

  void _openmodaloverlay() {
    showModalBottomSheet(
      // isScrollControlled: true,
      context: context,
      // backgroundColor: Colors.transparent,
      showDragHandle: true,
      enableDrag: true,
      builder: (context) => Difficulties(arraydiff: levels),
    );
  }

  void _dailyChallenge() async {
    final levels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master', 'Extreme'];
    final notif = NotificationService();
    final hasPlayed = await notif.hasPlayedTodayCheck();
    final random = Random();
    final rand = random.nextInt(6);
    final newGameSlotNo = await SudokuStorageService.instance
        .getAndIncrementGameSlotNumber();
    final data = await SudokuStorageService.instance.loadGame(
      slot: 'daily_challenge_active',
    );
    final today = DateTime.now().day;
    bool contd = hasPlayed
        ? data != null
              ? true
              : false
        : data != null && data['day'] == today
        ? true
        : false;
    final day = hasPlayed
        ? data != null
              ? data['day']
              : today - 1
        : today;
    final slotNo = data != null ? data['slotNo'] : newGameSlotNo;
    final level = data != null ? data['level'] : levels[rand];
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GamePage(
            isDailyChallenge: true,
            level: level,
            isContd: contd,
            challengeDay: day,
            slotNo: slotNo,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(saveGameProvider);
    final gameTime = gameState['secondsElapsed'];

    final String continueSubtitle = gameTime != null
        ? "Resume: ${_formatTime(gameTime)} - ${gameState['level'].toString().toUpperCase()}"
        : "No saved game";

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipPath(
                clipper: BottomCurveClipper(),
                child: Container(
                  width: double.infinity,
                  height: 300,
                  color: const Color(0xFF53698A),
                  child: Padding(
                    padding: const EdgeInsets.all(45.0),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Image.asset(
                          "assets/images/logo.png",
                          width: 120,
                          height: 120,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "SUDOKU LEGEND",
                          style: GoogleFonts.openSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            letterSpacing: 4,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8),

              // New Game Button
              MenuButton(
                title: "NEW GAME",
                subtitle: "Start your jounery...",
                color: const Color(0xFF53698A),
                isColor: true,
                isBorder: false,
                height: 70,
                width: 300,
                onTap: () {
                  _openmodaloverlay();
                },
              ),

              const SizedBox(height: 16),

              // Continue Button
              MenuButton(
                title: "CONTINUE",
                subtitle: continueSubtitle,
                color: const Color.fromARGB(255, 255, 255, 255),
                isColor: false,
                isBorder: true,
                borderColor: const Color(0xFF53698A),
                height: 70,
                width: 300,
                onTap: gameTime == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GamePage(
                              level: gameState['level'],
                              isContd: true,
                              slotNo: gameState['slotNo'],
                            ),
                          ),
                        ); // Pass slotNo
                      },
              ),
              const SizedBox(height: 16),
              // Daily Challenge Button
              MenuButton(
                title: "DAILY CHALLENGE",
                subtitle: "Shafter, daily ritual vibe",
                color: const Color(0xFF53698A),
                isColor: true,
                isBorder: false,
                height: 70,
                width: 300,
                onTap: _dailyChallenge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;

    path.lineTo(0, height - 80);

    path.quadraticBezierTo(width * 0.5, height + 40, width, height - 80);

    path.lineTo(width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
