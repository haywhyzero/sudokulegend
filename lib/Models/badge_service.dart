import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Badge {
  final String id;
  final String name;
  final String description;
  bool unlocked;
  DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'unlocked': unlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    unlocked: json['unlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
  );
}

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();

  factory BadgeService() {
    return _instance;
  }

  BadgeService._internal();

  static const String _badgesKey = 'user_badges';
  // static const String _streakKey = 'daily_streak';
  // static const String _lastPlayDateKey = 'last_play_date';
  // static const String _gameCounts = 'game_counts';
  // static const String _personalBestKey = 'personal_best';

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final Map<String, Badge> _badges = {
    'speed_demon': Badge(id: 'speed_demon', name: 'Speed Demon', description: 'Complete in < 5 mins'),
    'perfect_game': Badge(id: 'perfect_game', name: 'Perfect Game', description: 'No mistakes made'),
    'master': Badge(id: 'master', name: 'Master', description: 'Complete 10 Expert levels'),
    'lightning_strike': Badge(id: 'lightning_strike', name: 'Lightning Strike', description: 'Solve under 2 minutes'),
    'time_lord': Badge(id: 'time_lord', name: 'Time Lord', description: 'Beat personal best score'),
    'blitz_solver': Badge(id: 'blitz_solver', name: 'Blitz Solver', description: 'Solve 10 puzzles under 10 minutes'),
    'flawless_touch': Badge(id: 'flawless_touch', name: 'Flawless Touch', description: '50 consecutive error-free puzzles'),
    'error_tolerance': Badge(id: 'error_tolerance', name: 'Error Tolerance', description: '100 Games with zero mistakes'),
    'pencil_free': Badge(id: 'pencil_free', name: 'Pencil-Free Pro', description: 'Complete Expert puzzles without pencil mode'),
    'daily_devotee': Badge(id: 'daily_devotee', name: 'Daily Devotee', description: '30-day daily challenge streak'),
    'unbreakable_chain': Badge(id: 'unbreakable_chain', name: 'Unbreakable Chain', description: '100-days daily challenge streak'),
    'weekend_warrior': Badge(id: 'weekend_warrior', name: 'Weekend Warrior', description: 'Solve every weekend for 3 months'),
    'iron_solver': Badge(id: 'iron_solver', name: 'Iron Solver', description: 'Never miss a day for 60 days'),
    'century_club': Badge(id: 'century_club', name: 'Century club', description: 'Solve 100 puzzles'),
    'sudoku_sage': Badge(id: 'sudoku_sage', name: 'Sudoku Sage', description: '500 puzzles solved'),
    'grid_gladiator': Badge(id: 'grid_gladiator', name: 'Grid Gladiator', description: '1,000 puzzles completed'),
    'puzzle_titan': Badge(id: 'puzzle_titan', name: 'Puzzle Titan', description: '5,000 lifetime puzzles'),
    'expert_conqueror': Badge(id: 'expert_conqueror', name: 'Expert Conqueror', description: 'Complete 50 Expert puzzles'),
    'nightmare_slayer': Badge(id: 'nightmare_slayer', name: 'Nightmare Slayer', description: 'Finish 20 Extreme puzzles'),
    'evil_tamer': Badge(id: 'evil_tamer', name: 'Evil Tamer', description: 'Solve 5 16by16 puzzles'),
    'night_owl': Badge(id: 'night_owl', name: 'Night Owl', description: 'Solve 50 puzzles between 10PM - 5AM'),
    'early_bird': Badge(id: 'early_bird', name: 'Early Bird', description: 'Solve 50 puzzles between 5AM - 8AM'),
    'hint_hero': Badge(id: 'hint_hero', name: 'Hint Hero', description: 'Complete puzzle using minimal hints'),
    'leaderboard_king': Badge(id: 'leaderboard_king', name: 'Leaderboard King', description: 'Top 10 performer in leaderboard'),
    'sudoku_legend': Badge(id: 'sudoku_legend', name: 'Sudoku Legend', description: 'All badges unlocked'),
  };

  Future<void> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final badgesJson = prefs.getString(_badgesKey);
    if (badgesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(badgesJson);
      decoded.forEach((key, value) {
        if (_badges.containsKey(key)) {
          _badges[key] = Badge.fromJson(value);
        }
      });
    }
  }
  

  Future<void> _saveBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final badgesJson = jsonEncode(
      _badges.map((key, badge) => MapEntry(key, badge.toJson()))
    );
    await prefs.setString(_badgesKey, badgesJson);
  }


  Future<void> _saveBadgesToFirebase() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final badgeIds = _badges.entries
            .where((e) => e.value.unlocked)
            .map((e) => e.key)
            .toList();
        
        await _firestore.collection('users').doc(user.uid).set({
          'badges': badgeIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving badges to Firebase: $e');
      }
    }
  }

  Future<List<Badge>> checkAchievements({
    required String difficulty,
    required int elapsedSeconds,
    required int mistakes,
    required int hintsUsed,
    required bool usedPencilMode,
    required int totalGamesCompleted,
    required int expertGamesCompleted,
    required int extremeGamesCompleted,
    required int largeGridGamesCompleted,
    required int zeroMistakeGames,
    required int consecutiveZeroMistakes,
  }) async {
    final newBadges = <Badge>[];

    // Speed Demon: Complete in < 5 mins (300 seconds)
    if (elapsedSeconds < 300 && !_badges['speed_demon']!.unlocked) {
      _badges['speed_demon']!.unlocked = true;
      _badges['speed_demon']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['speed_demon']!);
    }

    // Perfect Game: No mistakes made
    if (mistakes == 0 && !_badges['perfect_game']!.unlocked) {
      _badges['perfect_game']!.unlocked = true;
      _badges['perfect_game']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['perfect_game']!);
    }

    // Lightning Strike: Solve under 2 minutes (120 seconds)
    if (elapsedSeconds < 120 && !_badges['lightning_strike']!.unlocked) {
      _badges['lightning_strike']!.unlocked = true;
      _badges['lightning_strike']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['lightning_strike']!);
    }

    // Master: Complete 10 Expert levels
    if (expertGamesCompleted >= 10 && !_badges['master']!.unlocked) {
      _badges['master']!.unlocked = true;
      _badges['master']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['master']!);
    }

    // Century club: Solve 100 puzzles
    if (totalGamesCompleted >= 100 && !_badges['century_club']!.unlocked) {
      _badges['century_club']!.unlocked = true;
      _badges['century_club']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['century_club']!);
    }

    // Sudoku Sage: 500 puzzles solved
    if (totalGamesCompleted >= 500 && !_badges['sudoku_sage']!.unlocked) {
      _badges['sudoku_sage']!.unlocked = true;
      _badges['sudoku_sage']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['sudoku_sage']!);
    }

    // Grid Gladiator: 1,000 puzzles completed
    if (totalGamesCompleted >= 1000 && !_badges['grid_gladiator']!.unlocked) {
      _badges['grid_gladiator']!.unlocked = true;
      _badges['grid_gladiator']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['grid_gladiator']!);
    }

    // Puzzle Titan: 5,000 lifetime puzzles
    if (totalGamesCompleted >= 5000 && !_badges['puzzle_titan']!.unlocked) {
      _badges['puzzle_titan']!.unlocked = true;
      _badges['puzzle_titan']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['puzzle_titan']!);
    }

    // Expert Conqueror: Complete 50 Expert puzzles
    if (expertGamesCompleted >= 50 && !_badges['expert_conqueror']!.unlocked) {
      _badges['expert_conqueror']!.unlocked = true;
      _badges['expert_conqueror']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['expert_conqueror']!);
    }

    // Nightmare Slayer: Finish 20 Extreme puzzles
    if (extremeGamesCompleted >= 20 && !_badges['nightmare_slayer']!.unlocked) {
      _badges['nightmare_slayer']!.unlocked = true;
      _badges['nightmare_slayer']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['nightmare_slayer']!);
    }

    // Evil Tamer: Solve 5 16by16 puzzles
    if (largeGridGamesCompleted >= 5 && !_badges['evil_tamer']!.unlocked) {
      _badges['evil_tamer']!.unlocked = true;
      _badges['evil_tamer']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['evil_tamer']!);
    }

    // Error Tolerance: 100 Games with zero mistakes
    if (zeroMistakeGames >= 100 && !_badges['error_tolerance']!.unlocked) {
      _badges['error_tolerance']!.unlocked = true;
      _badges['error_tolerance']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['error_tolerance']!);
    }

    // Flawless Touch: 50 consecutive error-free puzzles
    if (consecutiveZeroMistakes >= 50 && !_badges['flawless_touch']!.unlocked) {
      _badges['flawless_touch']!.unlocked = true;
      _badges['flawless_touch']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['flawless_touch']!);
    }

    // Pencil-Free Pro: Complete Expert puzzles without pencil mode
    if (difficulty == 'Expert' && !usedPencilMode && !_badges['pencil_free']!.unlocked) {
      _badges['pencil_free']!.unlocked = true;
      _badges['pencil_free']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['pencil_free']!);
    }

    // Hint Hero: Complete puzzle using minimal hints (0-1 hint)
    if (hintsUsed <= 1 && !_badges['hint_hero']!.unlocked) {
      _badges['hint_hero']!.unlocked = true;
      _badges['hint_hero']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['hint_hero']!);
    }

    // Check for Night Owl (10PM - 5AM)
    final now = DateTime.now();
    if ((now.hour >= 22 || now.hour < 5) && !_badges['night_owl']!.unlocked) {
      // Count night owl solves - would need tracking
      _badges['night_owl']!.unlocked = true;
      _badges['night_owl']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['night_owl']!);
    }

    // Check for Early Bird (5AM - 8AM)
    if (now.hour >= 5 && now.hour < 8 && !_badges['early_bird']!.unlocked) {
      _badges['early_bird']!.unlocked = true;
      _badges['early_bird']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['early_bird']!);
    }

    // Sudoku Legend: All other badges unlocked
    final allOthersUnlocked = _badges.values
        .where((b) => b.id != 'sudoku_legend')
        .every((b) => b.unlocked);
    if (allOthersUnlocked && !_badges['sudoku_legend']!.unlocked) {
      _badges['sudoku_legend']!.unlocked = true;
      _badges['sudoku_legend']!.unlockedAt = DateTime.now();
      newBadges.add(_badges['sudoku_legend']!);
    }

    if (newBadges.isNotEmpty) {
      await _saveBadges();
      await _saveBadgesToFirebase();
    }

    return newBadges;
  }

  Map<String, Badge> getAllBadges() => _badges;

  Badge? getBadgeById(String id) => _badges[id];

  int getUnlockedCount() => _badges.values.where((b) => b.unlocked).length;
}
