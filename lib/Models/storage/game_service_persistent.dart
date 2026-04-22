import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GamePersistenceService {
  // Singleton pattern to ensure only one instance
  static final GamePersistenceService _instance = GamePersistenceService._internal();
  factory GamePersistenceService() => _instance;
  GamePersistenceService._internal();

  // Keys for current game state
  static const String _keyScore = 'current_score';
  static const String _keyTime = 'current_time_elapsed';
  static const String _keyMistakes = 'current_mistakes';
  static const String _keyGrid = 'current_grid';

  // Keys for cumulative statistics
  static const String _keyTotalGames = 'stats_total_games';
  static const String _keyTotalMistakes = 'stats_total_mistakes';
  static const String _keyBestScore = 'stats_best_score';
  static const String _keyTotalTime = 'stats_total_time'; // in seconds

  // Save current game state (call this frequently or on pause/exit)
  Future<void> saveCurrentGame({
    required int score,
    required int timeElapsedSeconds,
    required int mistakes,
    required List<List<int>> grid, // 9x9 grid with 0 for empty
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyScore, score);
    await prefs.setInt(_keyTime, timeElapsedSeconds);
    await prefs.setInt(_keyMistakes, mistakes);
    await prefs.setString(_keyGrid, jsonEncode(grid));
  }

  // Load current game state (returns null if no saved game)
  Future<Map<String, dynamic>?> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_keyScore)) {
      return null; // No saved game
    }

    final String? gridJson = prefs.getString(_keyGrid);
    final List<List<int>> grid = gridJson != null
        ? (jsonDecode(gridJson) as List)
            .map((row) => (row as List).map((cell) => cell as int).toList())
            .toList()
        : List.generate(9, (_) => List.filled(9, 0));

    return {
      'score': prefs.getInt(_keyScore) ?? 0,
      'timeElapsed': prefs.getInt(_keyTime) ?? 0,
      'mistakes': prefs.getInt(_keyMistakes) ?? 0,
      'grid': grid,
    };
  }

  // Clear the current saved game (call when starting new game or completing one)
  Future<void> clearCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyScore);
    await prefs.remove(_keyTime);
    await prefs.remove(_keyMistakes);
    await prefs.remove(_keyGrid);
  }

  // Update statistics when a game is COMPLETED
  Future<void> updateStatisticsOnCompletion({
    required int score,
    required int timeElapsedSeconds,
    required int mistakes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    int totalGames = (prefs.getInt(_keyTotalGames) ?? 0) + 1;
    int totalMistakes = (prefs.getInt(_keyTotalMistakes) ?? 0) + mistakes;
    int totalTime = (prefs.getInt(_keyTotalTime) ?? 0) + timeElapsedSeconds;

    int bestScore = prefs.getInt(_keyBestScore) ?? 0;
    if (score > bestScore) {
      bestScore = score;
    }

    await prefs.setInt(_keyTotalGames, totalGames);
    await prefs.setInt(_keyTotalMistakes, totalMistakes);
    await prefs.setInt(_keyTotalTime, totalTime);
    await prefs.setInt(_keyBestScore, bestScore);
  }

  // Load all statistics for the Statistics page
  Future<Map<String, dynamic>> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    int totalGames = prefs.getInt(_keyTotalGames) ?? 0;
    int totalMistakes = prefs.getInt(_keyTotalMistakes) ?? 0;
    int totalTime = prefs.getInt(_keyTotalTime) ?? 0;
    int bestScore = prefs.getInt(_keyBestScore) ?? 0;

    double averageTime = totalGames > 0 ? totalTime / totalGames : 0;
    double averageMistakes = totalGames > 0 ? totalMistakes / totalGames : 0;

    return {
      'totalGames': totalGames,
      'bestScore': bestScore,
      'totalMistakes': totalMistakes,
      'averageMistakes': averageMistakes,
      'totalTimeSeconds': totalTime,
      'averageTimeSeconds': averageTime.toInt(),
    };
  }

  // Optional: Check if there is a saved game
  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyScore);
  }
}