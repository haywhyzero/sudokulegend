import 'package:flutter/material.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:sudokulegend/Screens/pages/game/game_page.dart';
import 'package:sudokulegend/main.dart';

class GameOver extends StatelessWidget {
   const GameOver({
    super.key,
    required this.difficulty,
    required this.time,
    required this.score,
  });

  final String difficulty;
  final int time;
  final int score;

  
  String _formatTime(int seconds) {
    final int hours = (seconds ~/ 3600);
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final h = hours > 0 ? '$hours:' : '';
    return "$h$m:$s";
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,

      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            "Game Over!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black87
                  : Colors.white,
            ),
          ),
          Text(
            "Too Many Mistakes!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black87
                  : Colors.white,
            ),
          ),


          // emoji Image
          Image.asset(
            "assets/icons/gameOver.gif",
            height: 170,
            width: 170,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.emoji_emotions),
          ),

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
                  Divider(
                    color: const Color.fromARGB(78, 114, 114, 114),
                    height: 0.5,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _RowItem(label: "Time", value: _formatTime(time)),
                  Divider(
                    color: const Color.fromARGB(78, 114, 114, 114),
                    height: 0.5,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _RowItem(label: "Score", value: score.toString()),
                
                ],
              ),
            ),
          ),

          const SizedBox(height: 35),

          // Continue Game
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
                onPressed: () {
                 
                },
                child: const Text(
                  "Continue Game",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

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
                onPressed: () async {
                   final newGameSlotNo = await SudokuStorageService.instance.getAndIncrementGameSlotNumber();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          GamePage(level: difficulty, isContd: false, slotNo: newGameSlotNo,),
                    ),
                  );
                  }
                },
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

  const _RowItem({
    required this.label,
    required this.value,
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
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : Colors.white70,
          ),
        ),
      ],
    );
  }
}
