// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sudokulegend/Models/data/sudoku_generator.dart';
import 'package:sudokulegend/Models/data/sudoku_solver.dart';

/// Model for cell state
class CellState {
  final int value;
  final bool isInitial; // Original clue
  final bool isError; // User made a mistake
  final List<int> notes; // Pencil marks
  
  CellState({
    this.value = 0,
    this.isInitial = false,
    this.isError = false,
    this.notes = const [],
  });
  
  CellState copyWith({
    int? value,
    bool? isInitial,
    bool? isError,
    List<int>? notes,
  }) {
    return CellState(
      value: value ?? this.value,
      isInitial: isInitial ?? this.isInitial,
      isError: isError ?? this.isError,
      notes: notes ?? this.notes,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isInitial': isInitial,
      'isError': isError,
      'notes': notes,
    };
  }
  
  factory CellState.fromJson(Map<String, dynamic> json) {
    return CellState(
      value: json['value'] ?? 0,
      isInitial: json['isInitial'] ?? false,
      isError: json['isError'] ?? false,
      notes: List<int>.from(json['notes'] ?? []),
    );
  }
}

/// Main game state
class SudokuGameState {
  final List<List<CellState>> grid;
  final List<List<int>> solution;
  final SudokuDifficulty difficulty;
  final int mistakesCount;
  final int hintsUsed;
  final int secondsElapsed;
  final bool isCompleted;
  final bool notesMode;
  
  SudokuGameState({
    required this.grid,
    required this.solution,
    required this.difficulty,
    this.mistakesCount = 0,
    this.hintsUsed = 0,
    this.secondsElapsed = 0,
    this.isCompleted = false,
    this.notesMode = false,
  });
  
  SudokuGameState copyWith({
    List<List<CellState>>? grid,
    List<List<int>>? solution,
    SudokuDifficulty? difficulty,
    int? mistakesCount,
    int? hintsUsed,
    int? secondsElapsed,
    bool? isCompleted,
    bool? notesMode,
  }) {
    return SudokuGameState(
      grid: grid ?? this.grid,
      solution: solution ?? this.solution,
      difficulty: difficulty ?? this.difficulty,
      mistakesCount: mistakesCount ?? this.mistakesCount,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      isCompleted: isCompleted ?? this.isCompleted,
      notesMode: notesMode ?? this.notesMode,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'grid': grid.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
      'solution': solution,
      'difficulty': difficulty.index,
      'mistakesCount': mistakesCount,
      'hintsUsed': hintsUsed,
      'secondsElapsed': secondsElapsed,
      'isCompleted': isCompleted,
      'notesMode': notesMode,
    };
  }
  
  factory SudokuGameState.fromJson(Map<String, dynamic> json) {
    return SudokuGameState(
      grid: (json['grid'] as List).map((row) => 
        (row as List).map((cell) => CellState.fromJson(cell)).toList()
      ).toList(),
      solution: (json['solution'] as List).map((row) => 
        List<int>.from(row)
      ).toList(),
      difficulty: SudokuDifficulty.values[json['difficulty']],
      mistakesCount: json['mistakesCount'] ?? 0,
      hintsUsed: json['hintsUsed'] ?? 0,
      secondsElapsed: json['secondsElapsed'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      notesMode: json['notesMode'] ?? false,
    );
  }
}

/// Game state notifier
class SudokuGameNotifier extends StateNotifier<SudokuGameState?> {
  final SudokuGenerator _generator = SudokuGenerator();
  final SudokuSolver _solver = SudokuSolver();
  
  SudokuGameNotifier() : super(null);
  
  /// Start a new game
  void startNewGame(SudokuDifficulty difficulty) {
    final puzzle = _generator.generatePuzzle(difficulty);
    final puzzleGrid = puzzle['puzzle']!;
    final solution = puzzle['solution']!;
    
    // Create grid with cell states
    List<List<CellState>> grid = List.generate(9, (row) {
      return List.generate(9, (col) {
        final value = puzzleGrid[row][col];
        return CellState(
          value: value,
          isInitial: value != 0,
        );
      });
    });
    
    state = SudokuGameState(
      grid: grid,
      solution: solution,
      difficulty: difficulty,
    );    
  }
  
  /// Place a number in a cell
  void placeNumber(int row, int col, int number) {
    if (state == null) return;
    if (state!.grid[row][col].isInitial) return; // Can't modify clues
    
    final newGrid = _deepCopyGrid(state!.grid);
    final currentCell = newGrid[row][col];
    
    if (state!.notesMode) {
      // Toggle note
      List<int> newNotes = List.from(currentCell.notes);
      if (newNotes.contains(number)) {
        newNotes.remove(number);
      } else {
        newNotes.add(number);
        newNotes.sort();
      }
      newGrid[row][col] = currentCell.copyWith(notes: newNotes);
    } else {
      // Place number
      final isCorrect = number == state!.solution[row][col];      
      
      newGrid[row][col] = currentCell.copyWith(
        value: number,
        isError: !isCorrect,
        notes: [], // Clear notes when placing number
      );
      
      final newMistakes = isCorrect ? state!.mistakesCount : state!.mistakesCount + 1;
      
      state = state!.copyWith(
        grid: newGrid,
        mistakesCount: newMistakes,
      );
      
      // Check if puzzle is solved
      _checkCompletion();
    }
  }
  
  /// Clear a cell
  void clearCell(int row, int col) {
    if (state == null) return;
    if (state!.grid[row][col].isInitial) return;
    
    final newGrid = _deepCopyGrid(state!.grid);
    newGrid[row][col] = CellState();
    
    state = state!.copyWith(grid: newGrid);
  }
  
  /// Get a hint
  void useHint() {
    if (state == null) return;
    
    final hint = _solver.getHint(
      _gridToIntGrid(state!.grid),
      state!.solution,
    );
    
    if (hint != null) {
      final row = hint['row']!;
      final col = hint['col']!;
      final value = hint['value']!;
      
      final newGrid = _deepCopyGrid(state!.grid);
      newGrid[row][col] = CellState(value: value, isInitial: false);
      
      state = state!.copyWith(
        grid: newGrid,
        hintsUsed: state!.hintsUsed + 1,
      );
      
      _checkCompletion();
    }
  }
  
  /// Toggle notes mode
  void toggleNotesMode() {
    if (state == null) return;
    state = state!.copyWith(notesMode: !state!.notesMode);
  }
  
  /// Update timer
  void updateTimer(int seconds) {
    if (state == null) return;
    state = state!.copyWith(secondsElapsed: seconds);
  }
  
  /// Check if puzzle is completed
  void _checkCompletion() {
    if (state == null) return;
    
    final currentGrid = _gridToIntGrid(state!.grid);
    if (_solver.isSolved(currentGrid)) {
      state = state!.copyWith(isCompleted: true);
    }
  }

  /// Used to load a game state from an external source (like SharedPreferences)
  void setGameState(SudokuGameState loadedState) {
    state = loadedState;
  }
  
  /// Clears the current game from memory
  void clearGame() {
    state = null;
  }
  
  /// Helper: Convert CellState grid to int grid
  List<List<int>> _gridToIntGrid(List<List<CellState>> grid) {
    return grid.map((row) => row.map((cell) => cell.value).toList()).toList();
  }
  
  /// Helper: Deep copy grid
  List<List<CellState>> _deepCopyGrid(List<List<CellState>> grid) {
    return grid.map((row) => row.map((cell) => cell).toList()).toList();
  }
}

/// Provider for game state
final sudokuGameProvider = StateNotifierProvider<SudokuGameNotifier, SudokuGameState?>(
  (ref) => SudokuGameNotifier(),
);