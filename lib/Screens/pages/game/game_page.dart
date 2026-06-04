import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudokulegend/Models/state%20management/settings_provider.dart';
import 'package:sudokulegend/Models/badge_service.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:sudokulegend/Screens/pages/game/game_over.dart';
import 'package:sudokulegend/Widgets/svg_icon.dart';
import 'package:sudokulegend/main.dart';
import 'package:vibration/vibration.dart';
import 'package:sudokulegend/Widgets/notification_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sudokulegend/Models/data/sudoku_generator.dart';
import 'package:sudokulegend/Models/state%20management/game_persistent.dart';
import 'package:sudokulegend/Screens/pages/game/game_result_page.dart';

class GamePage extends ConsumerStatefulWidget {
  final String level;
  final bool isContd;
  final int slotNo;
  final bool isDailyChallenge;
  final int? challengeDay;
  const GamePage({
    super.key, 
    required this.level, 
    required this.isContd, 
    required this.slotNo,
    this.isDailyChallenge = false,
    this.challengeDay,
  });

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class CellData {
  int? value;
  bool isInitial;
  bool isError;
  List<int> notes;

  CellData({
    this.value,
    this.isInitial = false,
    this.isError = false,
    this.notes = const [],
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'isInitial': isInitial,
        'isError': isError,
        'notes': notes,
      };

  factory CellData.fromJson(Map<String, dynamic> json) => CellData(
        value: json['value'],
        isInitial: json['isInitial'] ?? false,
        isError: json['isError'] ?? false,
        notes: List<int>.from(json['notes'] ?? []),
      );
}

class _GamePageState extends ConsumerState<GamePage>
    with WidgetsBindingObserver {
  // Game State
  bool _isPaused = false;
  bool _isPencilMode = false;
  int _score = 0;
  int _mistakes = 0;
  int _secondsElapsed = 0;
  int? _selectedCellIndex;
  int _hintsUsed = 2;
  final int _maxHints = 0;
  Timer? _timer;
  late AudioPlayer _audioPlayer;
  bool _isUndo = false;
  // ignore: unused_field
  Timer? _autoSaveTimer;
  int streakCombo = 0;

  Set<int> _completionHighlight = {};
  Timer? _completionHighlightTimer;

  Map<String, int> levelScore = {
    'Easy': 100,
    'Medium': 200,
    'Hard': 300,
    'Expert': 400,
    'Master': 500,
    'Extreme': 600,
  };

  final GlobalKey _gridKey = GlobalKey();
  final SudokuGenerator _generator = SudokuGenerator();

  List<CellData> _board = List.generate(81, (_) => CellData());
  List<List<int>> _solution = [];
  final List<int> _undoStack = [];

  Set<int> _regionIndices(int index) {
    final row = index ~/ 9;
    final col = index % 9;
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;

    final result = <int>{};
    for (int c = 0; c < 9; c++) {
      result.add(row * 9 + c);
    }
    for (int r = 0; r < 9; r++) {
      result.add(r * 9 + col);
    }
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        result.add(r * 9 + c);
      }
    }
    result.remove(index);
    return result;
  }

  Set<int> _sameNumberIndices(int index) {
    final value = _board[index].value;
    if (value == null) return {};
    final result = <int>{};
    for (int i = 0; i < 81; i++) {
      if (i != index && _board[i].value == value) result.add(i);
    }
    return result;
  }

  void _checkCompletionHighlight(int index) {
    final row = index ~/ 9;
    final col = index % 9;
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;

    final newHighlight = <int>{};

    final rowIndices = List.generate(9, (c) => row * 9 + c);
    if (rowIndices
        .every((i) => _board[i].value != null && !_board[i].isError)) {
      newHighlight.addAll(rowIndices);
    }

    final colIndices = List.generate(9, (r) => r * 9 + col);
    if (colIndices
        .every((i) => _board[i].value != null && !_board[i].isError)) {
      newHighlight.addAll(colIndices);
    }

    final boxIndices = <int>[];
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        boxIndices.add(r * 9 + c);
      }
    }
    if (boxIndices
        .every((i) => _board[i].value != null && !_board[i].isError)) {
      newHighlight.addAll(boxIndices);
    }

    if (newHighlight.isNotEmpty) {
      _completionHighlightTimer?.cancel();
      setState(() => _completionHighlight = newHighlight);
      _completionHighlightTimer =
          Timer(const Duration(milliseconds: 2200), () {
        if (mounted) setState(() => _completionHighlight = {});
      });
    }
  }

  int? _pickRandomHintIndex() {
    final emptyCells = <int>[];
    for (int i = 0; i < 81; i++) {
      if (_board[i].value == null && !_board[i].isInitial) {
        emptyCells.add(i);
      }
    }
    if (emptyCells.isEmpty) return null;
    emptyCells.shuffle(Random());
    return emptyCells.first;
  }

  String _hintExplanation(int row, int col, int value) {
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;

    final rowsWithValue = <int>[];
    for (int r = boxRow; r < boxRow + 3; r++) {
      if (r == row) continue;
      for (int c = 0; c < 9; c++) {
        if (_board[r * 9 + c].value == value) {
          rowsWithValue.add(r + 1);
          break;
        }
      }
    }

    final colsWithValue = <int>[];
    for (int c = boxCol; c < boxCol + 3; c++) {
      if (c == col) continue;
      for (int r = 0; r < 9; r++) {
        if (_board[r * 9 + c].value == value) {
          colsWithValue.add(c + 1);
          break;
        }
      }
    }

    if (rowsWithValue.isNotEmpty && colsWithValue.isNotEmpty) {
      return 'Row${rowsWithValue.length > 1 ? 's' : ''} '
          '${rowsWithValue.join(' & ')} and '
          'column${colsWithValue.length > 1 ? 's' : ''} '
          '${colsWithValue.join(' & ')} already contain $value, '
          'so this is the only valid cell in this box.';
    } else if (rowsWithValue.isNotEmpty) {
      return 'Row${rowsWithValue.length > 1 ? 's' : ''} '
          '${rowsWithValue.join(' & ')} already contain $value, '
          'eliminating other cells in this box.';
    } else if (colsWithValue.isNotEmpty) {
      return 'Column${colsWithValue.length > 1 ? 's' : ''} '
          '${colsWithValue.join(' & ')} already contain $value, '
          'so this cell is the only option.';
    } else {
      return '$value is the only number that fits here — '
          'all other digits already appear in the same row, column, or box.';
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _initAudio();
    _initGame();
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    try { // TODO: Fix: Audio not loading from asset
      await _audioPlayer.setAsset('assets/audios/correct.mp3');
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  Future<void> _initGame() async {
    if (widget.isContd) {
      await _loadGame();
    } else {
      _startNewGame();
    }
    _startTimer();
  }

  void _startNewGame() {
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
      case 'master':
        difficulty = SudokuDifficulty.master;
        break;
      case 'extreme':
        difficulty = SudokuDifficulty.extreme;
        break;
      default:
        difficulty = SudokuDifficulty.medium;
    }

    final puzzle = _generator.generatePuzzle(difficulty);
    final puzzleGrid = puzzle['puzzle']!;
    _solution = puzzle['solution']!;

    _board = List.generate(81, (index) {
      final row = index ~/ 9;
      final col = index % 9;
      final value = puzzleGrid[row][col];
      return CellData(value: value == 0 ? null : value, isInitial: value != 0);
    });

    _mistakes = 0;
    _score = 0;
    _secondsElapsed = 0;
    _hintsUsed = 2;
    _undoStack.clear();
    _completionHighlight = {};

    setState(() {});
    _saveGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) _saveGame();
    if (state == AppLifecycleState.inactive) _saveGame();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    _completionHighlightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int score() {
    int sc = Random().nextInt(50) + 50;
    int rand = Random().nextInt(100);
    if (streakCombo >= 30) {
      sc = levelScore[widget.level]! * 2 + rand;
    } else if (streakCombo >= 15) {
      sc = levelScore[widget.level]! * 2 + rand;
    } else if (streakCombo >= 10) {
      sc = levelScore[widget.level]! * 2 + rand;
    } else if (streakCombo >= 8) {
      sc = levelScore[widget.level]! * 2 + rand;
    } else if (streakCombo >= 5) {
      sc = levelScore[widget.level]! * 2 + rand;
    }
    return sc;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        if (mounted) {
          setState(() => _secondsElapsed++);
          if (_secondsElapsed % 10 == 0) _saveGame();
        }
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) _showPausedDialog();
  }

  void _restartGame() async {
     final gameData = {
      'board': _board.map((cell) => cell.toJson()).toList(),
      'solution': _solution,
      'mistakes': _mistakes,
      'score': _score,
      'secondsElapsed': _secondsElapsed,
      'hintsUsed': _hintsUsed,
      'level': widget.level,
      'slotNo': widget.slotNo, 
      'isCompleted': false,
    };
    // Save the current state of the game to its numbered slot as "not completed"
    await SudokuStorageService.instance.saveGame(
      slot: "slot_${widget.slotNo}", // Save to its specific slot
      data: gameData,
    );

    // Clear the active game (as it's being restarted)
    await SudokuStorageService.instance.deleteActiveGame();
    Future.microtask(() {
      if (mounted) ref.read(saveGameProvider.notifier).state = {};
    });

    // Start a brand new game for the *same* slot number
    setState(() => _startNewGame());
  }

  String _formatTime(int seconds) {
    final int hours = (seconds ~/ 3600);
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final h = hours > 0 ? '$hours:' : '';
    return "$h$m:$s";
  }

  void _placeNumber(int number) {
    if (_selectedCellIndex == null || _isPaused) return;
    if (_board[_selectedCellIndex!].isInitial) return;
    if (_board[_selectedCellIndex!].value != null) return;


    final row = _selectedCellIndex! ~/ 9;
    final col = _selectedCellIndex! % 9;

    setState(() {
      if (_isPencilMode) {
        List<int> newNotes = List.from(_board[_selectedCellIndex!].notes);
        if (newNotes.contains(number)) {
          newNotes.remove(number);
        } else {
          newNotes.add(number);
          newNotes.sort();
        }
        _board[_selectedCellIndex!].notes = newNotes;
      } else {
        _undoStack.add(_selectedCellIndex!);

        final correctValue = _solution[row][col];
        final isCorrect = number == correctValue;

        // if (_board[_selectedCellIndex!].value != null) _board[_selectedCellIndex!].value = number;

      
        final settings = ref.read(settingsProvider);

        _board[_selectedCellIndex!].value = number;
        _board[_selectedCellIndex!].isError = !isCorrect;
        _board[_selectedCellIndex!].notes = [];

        if (!isCorrect) {
          if (!settings.mistakes) {
            _mistakes = 0;
            if (settings.vibrationEnabled) Vibration.vibrate(duration: 200);
            _isUndo = false;
            streakCombo = 0;
          } else{
          _mistakes++;
          if (settings.vibrationEnabled) Vibration.vibrate(duration: 200);
          if (_mistakes >= 3) _showGameOver();
          _isUndo = false;
          streakCombo = 0;
          }
        } else {
          if (settings.soundEnabled) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.play();
          }
          final sc = score();
          _score += sc;
          showScorePopup(row, col, sc);
          _isUndo = true;
          streakCombo += 1;
          _checkCompletionHighlight(_selectedCellIndex!);
          _checkWin();
        }
      }
    });

    _saveGame();
  }

  void _eraseCell() {
    if (_selectedCellIndex == null || _isPaused) return;
    if (_board[_selectedCellIndex!].isInitial) return;

    setState(() {
      _undoStack.add(_selectedCellIndex!);
      _board[_selectedCellIndex!].value = null;
      _board[_selectedCellIndex!].isError = false;
      _board[_selectedCellIndex!].notes = [];
    });

    _saveGame();
  }

  void _undo() {
    if (_undoStack.isEmpty || _isPaused || _isUndo) return;

    final lastIndex = _undoStack.removeLast();
    setState(() {
      _board[lastIndex].value = null;
      _board[lastIndex].isError = false;
      _board[lastIndex].notes = [];
    });

    _saveGame();
  }

  void _showPausedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Center(child: Text('Pause')),
          content: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(97, 187, 185, 185),
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopTool(_formatTime(_secondsElapsed), "Time"),
                      _buildTopTool(widget.level, "Mode"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTopTool("$_score", "Score"),
                  if (widget.isDailyChallenge) _buildTopTool("${widget.challengeDay}", "Challenge Day"),
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _togglePause();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateColor.resolveWith(
                    (_) => const Color(0xFF53698A),
                  ),
                ),
                child: const Text(
                  "Resume",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _restartGame();
                  _togglePause();
                },
                child: const Text(
                  "Restart",
                  style: TextStyle(color: Color(0xFF53698A)),
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }

  void _useHint() {
    if (_hintsUsed <= _maxHints) {
      _showHintLimitDialog();
      return;
    }

    final hintIndex = _pickRandomHintIndex();
    if (hintIndex == null) return;

    final row = hintIndex ~/ 9;
    final col = hintIndex % 9;
    final hintValue = _solution[row][col];

    setState(() => _selectedCellIndex = hintIndex);

    _showHintBottomSheet(hintIndex, hintValue);
  }

  void _showHintBottomSheet(int index, int value) {
    final row = index ~/ 9;
    final col = index % 9;
    final explanation = _hintExplanation(row, col, value);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 5, 24, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hints',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black87
                                : Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _board[index].value = value;
                        _board[index].isError = false;
                        _board[index].notes = [];
                        _score += 60;
                        _selectedCellIndex = index;
                        showScorePopup(row, col, 60);
                        _hintsUsed--;
                        _checkCompletionHighlight(index);
                        _checkWin();
                      });
                      _saveGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53698A),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHintLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Hints Left'),
        content: Text('You have used all $_maxHints hints for this game.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkWin() async {
    bool allFilled = true;
    bool allCorrect = true;

    for (int i = 0; i < 81; i++) {
      if (_board[i].value == null) {
        allFilled = false;
        break;
      }
      final row = i ~/ 9;
      final col = i % 9;
      if (_board[i].value != _solution[row][col]) {
        allCorrect = false;
        break;
      }
    }

    if (allFilled && allCorrect) {
      _timer?.cancel();
      _isPaused = true;
      await _saveCompletedGame();
      // SudokuStorageService.instance.deleteActiveGame();
      
      if (widget.isDailyChallenge) {
        _saveToAchievements();
        if (widget.challengeDay == DateTime.now().day) NotificationService().markTodayAsPlayed();
        await SudokuStorageService.instance.deleteGame(slot: "daily_challenge_active");
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => GameResultContent(isChallenge: widget.isDailyChallenge,)),
      );
    }
  }

  void _showGameOver() async {
    _timer?.cancel();
    _isPaused = true;
    final gameData = {
      'board': _board.map((cell) => cell.toJson()).toList(),
      'solution': _solution,
      'mistakes': _mistakes,
      'score': _score,
      'secondsElapsed': _secondsElapsed,
      'hintsUsed': _hintsUsed,
      'level': widget.level,
      'slotNo': widget.slotNo,
      'isCompleted': false,
      'isGameOver': true,
    };
    await SudokuStorageService.instance.saveGame(
      slot: "slot_${widget.slotNo}",
      data: gameData,
    );

    if (mounted) {
      setState(() {
        Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => GameOver(
        difficulty: widget.level,
        score: _score,
        time: _secondsElapsed,
      )));
      });

    }
  }

  void _saveToAchievements() async {
    // Badge logic milestones
    final bool isSpeedDemon = _secondsElapsed < 300; // < 5 minutes
    final bool isPerfectGame = _mistakes == 0;
    final bool isHighScorer = _score > 30000;
    final bool isMaster = widget.level == 'Expert' || widget.level == 'Master' || widget.level == 'Extreme';

    final achievementData = {
      'date': DateTime.now().toIso8601String(),
      'day': widget.challengeDay,
      'score': _score,
      'time': _secondsElapsed,
      'difficulty': widget.level,
      'mistakes': _mistakes,
      'badges': {
        'speed_demon': isSpeedDemon,
        'perfect_game': isPerfectGame,
        'high_scorer': isHighScorer,
        'master_tier': isMaster,
      }
    };
    
    // Save a permanent record for the achievements page
    await SudokuStorageService.instance.saveGame(
      slot: "achievement_${DateTime.now().millisecondsSinceEpoch}",
      data: achievementData,
    );
  }

  Future<void> _saveCompletedGame() async {
    final gameData = {
      'board': _board.map((cell) => cell.toJson()).toList(),
      'solution': _solution,
      'mistakes': _mistakes,
      'score': _score,
      'secondsElapsed': _secondsElapsed,
      'hintsUsed': _hintsUsed,
      'level': widget.level,
      'slotNo': widget.slotNo,
      'isCompleted': true,
      'day': widget.challengeDay,
    };

    if (widget.isDailyChallenge) {
      final now = DateTime.now();
      gameData['isDailyChallenge'] = true;
      gameData['dailyDay'] = widget.challengeDay;
      gameData['dailyMonth'] = now.month;
      gameData['dailyYear'] = now.year;
    }

    await SudokuStorageService.instance.saveGame(
      slot: "slot_${widget.slotNo}",
      data: gameData,
    );
    ref.read(saveCompletedGameProvider.notifier).state = gameData;


    // Check for badge achievements
    final badgeService = BadgeService();
    await badgeService.loadBadges();

    final allGames = await SudokuStorageService.instance.listSavedGames();
    final totalGames = allGames.where((g) => g['isCompleted'] == true && g['day'] != null).length;
    final expertGames = allGames
        .where((g) => g['isCompleted'] == true && g['level'] == 'Expert' && g['day'] != null)
        .length;
    final extremeGames = allGames
        .where((g) => g['isCompleted'] == true && g['level'] == 'Extreme' && g['day'] != null)
        .length;
    final zeroMistakeGames = allGames
        .where((g) => g['isCompleted'] == true && (g['mistakes'] ?? 0) == 0 && g['day'] != null)
        .length;


    final newBadges = await badgeService.checkAchievements(
      difficulty: widget.level,
      elapsedSeconds: _secondsElapsed,
      mistakes: _mistakes,
      hintsUsed: _hintsUsed,
      usedPencilMode: false,
      totalGamesCompleted: totalGames,
      expertGamesCompleted: expertGames, 
      extremeGamesCompleted: extremeGames,
      largeGridGamesCompleted: 0,
      zeroMistakeGames: zeroMistakeGames,
      consecutiveZeroMistakes: 0,
    );
    ref.read(unlockedBadgesProvider.notifier).state = newBadges; 

    // Attempt to sync completed game to Firebase
    try {
      await SudokuStorageService.instance.syncCompletedGamesToFirebase();
    } catch (e) {
      debugPrint('Error syncing game: $e');
    }

  
  }

  void _saveGame() async {
    final gameData = {
      'board': _board.map((cell) => cell.toJson()).toList(),
      'solution': _solution,
      'mistakes': _mistakes,
      'score': _score,
      'secondsElapsed': _secondsElapsed,
      'hintsUsed': _hintsUsed,
      'level': widget.level,
      'slotNo': widget.slotNo,
      'isCompleted': false,
      'day': widget.challengeDay,
    };
    
    if (widget.isDailyChallenge) {
      await SudokuStorageService.instance.saveGame(slot: 'daily_challenge_active', data: gameData);
    } else {
      await SudokuStorageService.instance.saveActiveGame(gameData);
    }

    Future.microtask(() {
      if (mounted && !widget.isDailyChallenge) ref.read(saveGameProvider.notifier).state = gameData;
    });
  }

  Future<void> _loadGame() async {
    final data = widget.isDailyChallenge 
        ? await SudokuStorageService.instance.loadGame(slot: 'daily_challenge_active')
        : await SudokuStorageService.instance.loadActiveGame();

    if (data != null) {
      if (data['mistakes'] >= 3) {
        setState(() {
          _showGameOver();
        });
      }
      setState(() {
        _board = (data['board'] as List)
            .map((cell) => CellData.fromJson(cell))
            .toList();
        _solution = (data['solution'] as List)
            .map((row) => List<int>.from(row))
            .toList();
        _mistakes = data['mistakes'] ?? 0;
        _score = data['score'] ?? 0;
        _secondsElapsed = data['secondsElapsed'] ?? 0;
        _hintsUsed = data['hintsUsed'] ?? 0;
      });
      Future.microtask(() {
         _checkWin();
    });
    } else {
      _startNewGame();
    }
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
          builder: (_, t, child) => Opacity(
            opacity: 1,
            child: Transform.translate(
              offset: Offset(0, -30 * t),
              child: child,
            ),
          ),
          child: Text(
            "+$value",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 37, 92, 142),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), () => entry.remove());
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

  // Build 
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // print("sol: $_solution");

    // icon color so tool button stays consistent
    final toolIconColor =
        Theme.of(context).brightness == Brightness.light
            ? Colors.black87
            : Colors.white70;
    final toolPencilColor = Theme.of(context).brightness == Brightness.light
            ? _isPencilMode ?  Colors.white70 : Colors.black87
            : Colors.white70;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            _saveGame();
            if(widget.  isDailyChallenge) {
              Navigator.pop(context);
            } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
            }
          },
        ),
        title: settings.score
            ? _buildTopTool("$_score", "Score")
            : const Text(""),
        centerTitle: true,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_circle_outline,
                      size: 32,
                    ),
                    onPressed: _togglePause,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Board ────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: _buildSudokuGrid(
                        highlightSameNo: settings.highlightSameNo,
                        highlightRegion: settings.highlightRegion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Info row (mode / time) ───────────────────────────────
          Container(
            padding: const EdgeInsets.only(
                bottom: 20, top: 10, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopTool(widget.level, "Mode"),
                settings.timer ? 
                _buildTopTool(_formatTime(_secondsElapsed), "Time") : Text(""),
              ],
            ),
          ),

          // ── Controls ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.only(
                bottom: 30, top: 10, left: 16, right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF5F7FA)
                  : Colors.black,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Tool bar ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(
                      const BorderSide(width: 1, color: Color(0xFF53698A)),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Erase — uses your custom Svgicon widget
                      _buildToolBtn(
                        label: "Erase",
                        icon: Svgicon(
                          assetName: "Eraser",
                          color: toolIconColor,
                        ),
                        onTap: _eraseCell,
                      ),

                      // Undo
                      _buildToolBtn(
                        label: "Undo",
                        icon: Svgicon(
                          assetName: "Undo",
                          color: toolIconColor,
                        ),
                        onTap: _undo,
                      ),

                      // Pencil — icon color flips when active
                      _buildToolBtn(
                        label: "Pencil",
                        icon: Svgicon(
                          assetName: "pencil",
                          color: toolPencilColor,
                          isColor: true,
                        ),
                        onTap: () =>
                            setState(() => _isPencilMode = !_isPencilMode),
                        isActive: _isPencilMode,
                      ),

                      // Mistakes — plain text label, no icon
                      settings.mistakes ?
                      _buildToolBtn(
                        label: "Mistakes",
                        icon: Text(
                          "$_mistakes/3",
                          style: TextStyle(
                            color: toolIconColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {},
                      ) : Text(""),

                      // Hints — icon + red badge overlay
                      settings.smartHint ?
                      Stack(
                        children: [
                          _buildToolBtn(
                            label: "Hints",
                            icon: Svgicon(
                          assetName: "Hint",
                          color: toolIconColor,
                        ),
                            onTap: _useHint,
                          ),
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minHeight: 7,
                                minWidth: 14,
                              ),
                              child: Text(
                                '$_hintsUsed',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 8),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ) : Text(""),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Number keys ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(
                          9,
                          (i) => _buildNumberKey(i + 1),
                        ),
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

  //  Helper Widgets
  Widget _buildTopTool(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildToolBtn({
    required String label,
    required Widget icon,    
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive
              ? const Color(0xFF53698A)
              : Theme.of(context).brightness == Brightness.light
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: icon, 
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSudokuGrid({
    required bool highlightSameNo,
    required bool highlightRegion,
  }) {
    final Set<int> regionSet =
        (highlightRegion && _selectedCellIndex != null)
            ? _regionIndices(_selectedCellIndex!)
            : {};

    final Set<int> sameNoSet =
        (highlightSameNo && _selectedCellIndex != null)
            ? _sameNumberIndices(_selectedCellIndex!)
            : {};

    return Container(
      // Grid border
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black87
              : Colors.white70,
          width: 2,
        ),
      ),
      child: GridView.builder(
        key: _gridKey,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 81,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemBuilder: (context, index) {
          final int row = index ~/ 9;
          final int col = index % 9;

          final bool rightBorder = (col + 1) % 3 == 0 && col != 8;
          final bool bottomBorder = (row + 1) % 3 == 0 && row != 8;

          final bool isSelected = _selectedCellIndex == index;
          final cellData = _board[index];

          final bool isCompletion = _completionHighlight.contains(index);
          final bool isInRegion = regionSet.contains(index);
          final bool isSameNumber = sameNoSet.contains(index);

          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          Color bgColor;

          if (isSelected) {
            // Selected cell takes priority. If it's an error, show red background.
            bgColor = cellData.isError ? Colors.red : const Color(0xFF53698A);
          } else if (isCompletion) {
            bgColor = const Color(0xFF53698A);
          } else if (isSameNumber) {
            // Same number highlight is slightly lighter than selection to distinguish
            bgColor = const Color(0xFF53698A).withOpacity(0.6);
          } else if (cellData.isError) {
            // Non-selected error cells get a light red tint
            bgColor = Colors.red.withOpacity(0.15);
          } else if (isInRegion) {
            bgColor = isDark ? const Color(0xFF1E2D3D) : const Color(0xFFE8EEF4);
          } else {
            bgColor = isDark ? Colors.black : Colors.white70;
          }

          // Determine Text Color
          Color textColor;
          if (isSelected || isCompletion || isSameNumber) {
            // These states have dark backgrounds, so we use white text
            textColor = Colors.white70;
          } else if (cellData.isError) {
            textColor = Colors.red;
          } else if (cellData.isInitial) {
            // Initial numbers: Black in Light Mode, White in Dark Mode
            textColor = isDark ? Colors.white60 : Colors.black87;
          } else {
            textColor = isDark
                ? const Color.fromARGB(255, 123, 176, 255)
                : const Color(0xFF53698A);
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedCellIndex = index),
            child: Container(
              // Cell border
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  right: BorderSide(
                    width: rightBorder ? 2.0 : 0.5,
                    color: rightBorder
                        ? Theme.of(context).brightness == Brightness.light
                            ? Colors.black87
                            : Colors.white70
                        : Theme.of(context).brightness == Brightness.light
                            ? const Color.fromARGB(255, 182, 177, 177)
                            : Colors.grey[200]!,
                  ),
                  bottom: BorderSide(
                    width: bottomBorder ? 2.0 : 0.5,
                    color: bottomBorder
                        ? Theme.of(context).brightness == Brightness.light
                            ? Colors.black87
                            : Colors.white70
                        : Theme.of(context).brightness == Brightness.light
                            ? const Color.fromARGB(255, 182, 177, 177)
                            : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Center(
                child: cellData.value != null
                    ? Text(
                        "${cellData.value}",
                        style: TextStyle(
                          fontSize: 20,
                          color: textColor,
                          fontWeight: cellData.isInitial
                              ? FontWeight.w700
                              : FontWeight.w500,
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
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final number = index + 1;
        return Center(
          child: notes.contains(number)
              ? Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color.fromARGB(255, 126, 170, 221),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildNumberKey(int number) {
    final isOdd = number % 2 != 0;
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