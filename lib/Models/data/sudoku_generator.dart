import 'dart:math';

class SudokuGenerator {
  final Random _random = Random();
  
  /// Generates a complete valid Sudoku grid
  List<List<int>> generateCompleteGrid() {
    List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(grid);
    return grid;
  }
  
  /// Generates a Sudoku puzzle with clues removed based on difficulty
  /// Returns a map with 'puzzle' and 'solution'
  Map<String, List<List<int>>> generatePuzzle(SudokuDifficulty difficulty) {
    List<List<int>> solution = generateCompleteGrid();
    List<List<int>> puzzle = _deepCopy(solution);
    
    int cellsToRemove = _getCellsToRemove(difficulty);
    _removeNumbers(puzzle, cellsToRemove);
    
    return {
      'puzzle': puzzle,
      'solution': solution,
    };
  }
  
  /// Fills the grid using backtracking
  bool _fillGrid(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
          
          for (int num in numbers) {
            if (_isValidPlacement(grid, row, col, num)) {
              grid[row][col] = num;
              
              if (_fillGrid(grid)) {
                return true;
              }
              
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }
  
  /// Checks if a number can be placed at the given position
  bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (grid[row][x] == num) return false;
    }
    
    // Check column
    for (int x = 0; x < 9; x++) {
      if (grid[x][col] == num) return false;
    }
    
    // Check 3x3 box
    int boxRow = row - row % 3;
    int boxCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[boxRow + i][boxCol + j] == num) return false;
      }
    }
    
    return true;
  }
  
  /// Removes numbers from the grid to create the puzzle
  void _removeNumbers(List<List<int>> grid, int count) {
    List<int> positions = List.generate(81, (i) => i)..shuffle(_random);
    
    for (int i = 0; i < count && i < positions.length; i++) {
      int pos = positions[i];
      int row = pos ~/ 9;
      int col = pos % 9;
      grid[row][col] = 0;
    }
  }
  
  /// Determines how many cells to remove based on difficulty
  int _getCellsToRemove(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return 35 + _random.nextInt(5); 
      case SudokuDifficulty.medium:
        return 40 + _random.nextInt(10);
      case SudokuDifficulty.hard:
        return 50 + _random.nextInt(7); 
      case SudokuDifficulty.expert:
        return 55 + _random.nextInt(6);
      case SudokuDifficulty.master:
        return 65 + _random.nextInt(2);
      case SudokuDifficulty.extreme:
        return 70 + _random.nextInt(2);
      
    }
  }
  
  /// Creates a deep copy of the grid
  List<List<int>> _deepCopy(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }
}

enum SudokuDifficulty {
  easy,
  medium,
  hard,
  expert,
  master,
  extreme
}