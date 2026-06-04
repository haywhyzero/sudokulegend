// ignore_for_file: use_build_context_synchronously

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:sudokulegend/Models/state%20management/game_persistent.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:sudokulegend/Screens/pages/game/game_page.dart';
import 'package:sudokulegend/main.dart';

class GameResultContent extends ConsumerStatefulWidget {
  const GameResultContent({
    super.key,
    required this.isChallenge,
  });

  final bool isChallenge;

  @override
  ConsumerState<GameResultContent> createState() => _GameResultContentState();
}
class _GameResultContentState extends ConsumerState<GameResultContent> {

  String _formatTime(int seconds) {
    final int hours = (seconds ~/ 3600);
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final h = hours > 0 ? '$hours:' : '';

    return "$h$m:$s";
  }

  void _newGame() async {

    final newGameSlotNo = await SudokuStorageService.instance.getAndIncrementGameSlotNumber();
    final gameData = ref.read(saveCompletedGameProvider);
    final difficulty = gameData['level'] ?? 'Medium';
    final slotNo = gameData['slotNo'] ?? newGameSlotNo;
    final day = gameData['day'] ?? DateTime.now().day;
     final difficulties = ['Easy', 'Medium', 'Hard', 'Expert', 'Master', 'Extreme'];
    final randomDifficulty = difficulties[DateTime.now().microsecond % difficulties.length];


    if (widget.isChallenge) {
      await SudokuStorageService.instance.deleteGame(slot: "daily_challenge_active");
      ref.read(saveCompletedGameProvider.notifier).state = {};
      Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            GamePage(level: randomDifficulty, isContd: false, slotNo: slotNo, challengeDay: day, isDailyChallenge: true,),
      ),
    );
    } else {
      await SudokuStorageService.instance.deleteActiveGame();
      ref.read(saveCompletedGameProvider.notifier).state = {};
      Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            GamePage(level: difficulty, isContd: false, slotNo: newGameSlotNo, isDailyChallenge: false,),
      ),
    );
    }
  }
  @override
  Widget build(BuildContext context) {
    final gameData = ref.watch(saveCompletedGameProvider);

    if (gameData.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No game data available'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                ),
                child: const Text('Back To Home'),
              ),
            ],
          ),
        ),
      );
    }

    final difficulty = gameData['level'] ?? 'Medium';
    final time = _formatTime(gameData['secondsElapsed'] ?? 0);
    final score = (gameData['score'] ?? 0).toString();
    final mistakes = (gameData['mistakes'] ?? 0).toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,

      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            "Congratulations!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black87
                  : Colors.white,
            ),
          ),

          const SizedBox(height: 25),

          // Trophy Image
          Image.asset("assets/images/trophy3.png", height: 150, width: 150),

          const SizedBox(height: 20),

          // Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 25),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black26
                        : Colors.white,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _RowItem(label: "Difficulty", value: difficulty),
                  SizedBox(height: 14),
                  _RowItem(label: "Time", value: time),
                  SizedBox(height: 14),
                  _RowItem(label: "Score", value: score),
                  SizedBox(height: 14),
                  _RowItem(label: "Mistakes", value: mistakes),
                  SizedBox(height: 14),
                if (!widget.isChallenge)  _RowItem(label: "Ranking", value: "3rd >", boldValue: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 35),

          // New Game Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                onPressed: _newGame,
                child: const Text(
                  "New Game",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          GestureDetector(
            onTap: () {
              // Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
            child: Text(
              "Back To Home",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final bool boldValue;

  const _RowItem({
    required this.label,
    required this.value,
    this.boldValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: boldValue ? FontWeight.w700 : FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : Colors.white70,
          ),
        ),
      ],
    );
  }
}
