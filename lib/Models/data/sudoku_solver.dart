class SudokuSolver {
  /// Solves the Sudoku puzzle using backtracking
  /// Returns true if solved, false if unsolvable
  bool solve(List<List<int>> grid) {
    return _solveRecursive(grid);
  }
  
  /// Validates if the current state is valid
  bool isValid(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] != 0) {
          int num = grid[row][col];
          grid[row][col] = 0; // Temporarily remove to check
          if (!_isValidPlacement(grid, row, col, num)) {
            grid[row][col] = num; // Restore
            return false;
          }
          grid[row][col] = num; // Restore
        }
      }
    }
    return true;
  }
  
  /// Checks if a specific move is valid
  bool isValidMove(List<List<int>> grid, int row, int col, int num) {
    if (num == 0) return true; // Empty cell is always valid
    return _isValidPlacement(grid, row, col, num);
  }
  
  /// Gets all possible valid numbers for a cell
  List<int> getPossibleNumbers(List<List<int>> grid, int row, int col) {
    if (grid[row][col] != 0) return [];
    
    List<int> possible = [];
    for (int num = 1; num <= 9; num++) {
      if (_isValidPlacement(grid, row, col, num)) {
        possible.add(num);
      }
    }
    return possible;
  }
  
  /// Checks if the puzzle is completely solved
  bool isSolved(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) return false;
        if (!isValidMove(grid, row, col, grid[row][col])) return false;
      }
    }
    return true;
  }
  
  /// Provides a hint by finding a cell that can be filled
  Map<String, int>? getHint(List<List<int>> grid, List<List<int>> solution) {
    // Find an empty cell and return its solution
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          return {
            'row': row,
            'col': col,
            'value': solution[row][col],
          };
        }
      }
    }
    return null;
  }
  
  /// Recursive backtracking solver
  bool _solveRecursive(List<List<int>> grid) {
    // Find empty cell
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          // Try numbers 1-9
          for (int num = 1; num <= 9; num++) {
            if (_isValidPlacement(grid, row, col, num)) {
              grid[row][col] = num;
              
              if (_solveRecursive(grid)) {
                return true;
              }
              
              grid[row][col] = 0; // Backtrack
            }
          }
          return false;
        }
      }
    }
    return true; // All cells filled
  }
  
  /// Validates number placement according to Sudoku rules
  bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (x != col && grid[row][x] == num) return false;
    }
    
    // Check column
    for (int x = 0; x < 9; x++) {
      if (x != row && grid[x][col] == num) return false;
    }
    
    // Check 3x3 box
    int boxRow = row - row % 3;
    int boxCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int currentRow = boxRow + i;
        int currentCol = boxCol + j;
        if (currentRow != row && currentCol != col && 
            grid[currentRow][currentCol] == num) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Counts how many cells are filled correctly
  int getCorrectCellsCount(List<List<int>> grid, List<List<int>> solution) {
    int count = 0;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] != 0 && grid[row][col] == solution[row][col]) {
          count++;
        }
      }
    }
    return count;
  }
}