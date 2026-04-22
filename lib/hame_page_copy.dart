import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sudokulegend/Models/data/sudoku_generator.dart';
import 'package:sudokulegend/Models/state%20management/game_controller.dart';



class GamePage extends ConsumerStatefulWidget {
  final String level;
  final bool isContd;
  const GamePage({super.key, required this.level, required this.isContd});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> with WidgetsBindingObserver {
  // Game State
  bool _isPaused = false;
  int? _selectedCellIndex;
  final int _maxHints = 2;
  Timer? _timer;

  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Save game when app is paused or becomes inactive
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _saveGame();
    }
  }

  Future<void> _initGame() async {
    if (widget.isContd) {
      // Game state is already loaded by home_tab, just start the timer.
    } else {
      _startNewGame();
    }
    _startTimer();
  }

  SudokuDifficulty _getDifficultyFromString(String level) {
    SudokuDifficulty difficulty;
    switch (widget.level.toLowerCase()) {
      case 'easy':
        difficulty = SudokuDifficulty.easy;
        break;
      case 'medium':
        difficulty = SudokuDifficulty.medium;
        break;
      case 'hard':
        difficulty = SudokuDifficulty.hard;
        break;
      case 'expert':
        difficulty = SudokuDifficulty.expert;
        break;
      default:
        difficulty = SudokuDifficulty.medium;
    }
    return difficulty;
  }

  void _startNewGame() {
    final difficulty = _getDifficultyFromString(widget.level);
    ref.read(sudokuGameProvider.notifier).startNewGame(difficulty);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        final notifier = ref.read(sudokuGameProvider.notifier);
        final currentSeconds = ref.read(sudokuGameProvider)?.secondsElapsed ?? 0;
        notifier.updateTimer(currentSeconds + 1);
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
    _showPausedDialog();
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _placeNumber(int number) {
    if (_selectedCellIndex == null || _isPaused) return;

    final row = _selectedCellIndex! ~/ 9;
    final col = _selectedCellIndex! % 9;
    final notifier = ref.read(sudokuGameProvider.notifier);
    notifier.placeNumber(row, col, number);

    // Check for game over or win conditions after placing a number
    final gameState = ref.read(sudokuGameProvider);
    if (gameState == null) return;

    if (gameState.mistakesCount >= 3) {
      _showGameOver();
    }

    if (gameState.isCompleted) {
      _showWinDialog();
    }
  }

  void _eraseCell() {
    if (_selectedCellIndex == null || _isPaused) return;
    final row = _selectedCellIndex! ~/ 9;
    final col = _selectedCellIndex! % 9;
    ref.read(sudokuGameProvider.notifier).clearCell(row, col);
  }

  void _undo() {
    // ref.read(sudokuGameProvider.notifier).undo();
  }


  void _showPausedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Paused'),
        content: FloatingActionButton.extended(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _togglePause();
                                  },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text("Resume"),
                              ),
      ),
    );
  }

  void _useHint() {
    final notifier = ref.read(sudokuGameProvider.notifier);
    final gameState = ref.read(sudokuGameProvider);

    if (gameState == null || gameState.hintsUsed >= _maxHints) {
      _showHintLimitDialog();
      return;
    }
    notifier.useHint();
  }

  void _showHintLimitDialog() {
    // Use ref.read inside a callback, not ref.watch
    final gameState = ref.read(sudokuGameProvider);
    if (gameState == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Hints Left'),
        content: Text('You have used all ${gameState.hintsUsed} hints for this game.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    final gameState = ref.read(sudokuGameProvider);
    if (gameState == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You solved the puzzle!'),
            const SizedBox(height: 16),
            Text('Time: ${_formatTime(gameState.secondsElapsed)}'),
            Text('Score: 0'), // Score logic can be added to controller
            Text('Mistakes: ${gameState.mistakesCount}/3'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ref.read(sudokuGameProvider.notifier).clearGame();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('You made 3 mistakes. Better luck next time!'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(sudokuGameProvider.notifier).clearGame();
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ref.read(sudokuGameProvider.notifier).clearGame();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

// Save game
Future<void> _saveGame() async {
  final gameState = ref.read(sudokuGameProvider);
  if (gameState != null) {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(gameState.toJson());
    await prefs.setString('saved_game', json);
  }
}

@override
void dispose() {
  _timer?.cancel();
  _saveGame(); // Save game on leaving the page
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

void showScorePopup(int row, int col, int value) {
  final overlay = Overlay.of(context);

  final position = _cellOffset(row, col);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: position.dx - 16,
      top: position.dy - 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        builder: (_, t, child) {
          return Opacity(
            opacity: 1 - t,
            child: Transform.translate(
              offset: Offset(0, -30 * t),
              child: child,
            ),
          );
        },
        child: Text(
          "+$value",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 36, 56, 75),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(milliseconds: 700), () {
    entry.remove();
  });
}

Offset _cellOffset(int row, int col) {
  final RenderBox gridBox =
      _gridKey.currentContext!.findRenderObject() as RenderBox;

  final gridPosition = gridBox.localToGlobal(Offset.zero);

  final cellSize = gridBox.size.width / 9;

  return Offset(
    gridPosition.dx + col * cellSize + cellSize / 2,
    gridPosition.dy + row * cellSize + cellSize / 2,
  );
}





  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(sudokuGameProvider);

    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildTopTool("0", "Score"), // Score logic can be added
        centerTitle: true,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_circle_outline, size: 32),
                    onPressed:  _togglePause,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // The Board Area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Stack(
                  children: [
                    // Actual Grid
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: _buildSudokuGrid(gameState),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.only(bottom: 20, top: 10, left: 16, right: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopTool(gameState.difficulty.name[0].toUpperCase() + gameState.difficulty.name.substring(1), "Mode"),
                    _buildTopTool(_formatTime(gameState.secondsElapsed), "Time"),
                  ],
                ),
              ],
            ),
          ),

          // Controls & Numpad
          Container(
            padding: const EdgeInsets.only(bottom: 30, top: 10, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tools Row
                Container(
                   decoration: BoxDecoration(
                      border: Border.fromBorderSide(BorderSide(
                        width: 1,
                        color: Color(0xFF53698A),
                          )),
                          borderRadius: BorderRadius.circular(8)
                        ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolBtn("Erase", Icons.cleaning_services_outlined, true, _eraseCell),
                      _buildToolBtn("Undo", Icons.rotate_left, true, _undo),
                      _buildToolBtn(
                        "Pencil", 
                        Icons.edit,
                        true,
                        () => ref.read(sudokuGameProvider.notifier).toggleNotesMode(),
                        isActive: gameState.notesMode,
                      ),
                      _buildToolBtn("Mistakes", "${gameState.mistakesCount}/3", false, () {}),
                      _buildToolBtn("Hints", Icons.lightbulb_outline, true, _useHint),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(9, (index) {
                          return _buildNumberKey(index + 1);
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTool(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(subtitle, textAlign: TextAlign.end, style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.8))),
        const SizedBox(height: 5),
        Text(title, style: TextStyle(fontWeight: FontWeight.w500),),
      ],
    );
  }

  Widget _buildSudokuGrid(SudokuGameState gameState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: GridView.builder(
        key: _gridKey,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 81,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
        itemBuilder: (context, index) {
          final int row = index ~/ 9;
          final int col = index % 9;
          
          final bool rightBorder = (col + 1) % 3 == 0 && col != 8;
          final bool bottomBorder = (row + 1) % 3 == 0 && row != 8;
          
          final bool isSelected = _selectedCellIndex == index;
          final cellData = gameState.grid[row][col];


          Color bgColor = Colors.white;
          if (isSelected) {
            bgColor = Colors.blue.withOpacity(0.2);

          } else if (cellData.isError) {
            bgColor = Colors.red.withOpacity(0.1);
          }

          return GestureDetector(
            onTap: () => setState(() { _selectedCellIndex = index; }),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  right: BorderSide(
                    width: rightBorder ? 2.0 : 0.5,
                    color: rightBorder ? Colors.black87 : Colors.grey[300]!,
                  ),
                  bottom: BorderSide(
                    width: bottomBorder ? 2.0 : 0.5,
                    color: bottomBorder ? Colors.black87 : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Center(
                child: cellData.value != 0
                  ? Text(
                      "${cellData.value}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: cellData.isInitial ? FontWeight.bold : FontWeight.normal,
                        color: cellData.isInitial
                            ? Colors.black87
                            : cellData.isError
                                ? Colors.red
                                : const Color(0xFF53698A),
                      ),
                    )
                  : cellData.notes.isNotEmpty
                      ? _buildPencilMarks(cellData.notes)
                      : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPencilMarks(List<int> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 9,
      itemBuilder: (context, index) {
        final number = index + 1;
        return Center(
          child: notes.contains(number)
              ? Text(
                  '$number',
                  style: const TextStyle(fontSize: 8, color: Color.fromARGB(255, 151, 146, 146), fontWeight: FontWeight.bold),
                  
                )
              : null,
        );
      },
    );
  }

  Widget _buildToolBtn(String label, dynamic icon, bool isIcon, VoidCallback onTap, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive ? const Color(0xFF53698A) : Colors.white.withValues(alpha: 0.4),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: isIcon ? Icon(icon, color: isActive ? Colors.white : Colors.black87, size: 24) : Text("$icon"),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color.fromARGB(115, 0, 0, 0))),
      ],
    );
  }

  Widget _buildNumberKey(int number) {
    bool isOdd = number % 2 != 0;
    return Material(
      color: isOdd ? const Color(0xFF53698A) : Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _placeNumber(number),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 30,
          height: 40,
          child: Center(
            child: Text(
              "$number",
              style: TextStyle(
                fontSize: 24,
                color: isOdd ? Colors.white : const Color(0xFF53698A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }





}