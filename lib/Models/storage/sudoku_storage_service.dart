// ============================================================
//  SudokuStorageService
//  A single reusable class for:
//    1. Saving / loading game data locally (SharedPreferences)
//    2. Displaying a leaderboard widget
//    3. Syncing leaderboard data to/from Cloud Firestore

//
//  ─────────────────────────────────────────────────────────────
//  CLOUD FIRESTORE SETUP (read carefully before deploying)
//  ─────────────────────────────────────────────────────────────
//
//  1. Go to https://console.firebase.google.com → your project
//     → Firestore Database → Create database (production mode).
//
//  2. Collection structure:
//
//     leaderboard/          ← top-level collection
//       {userId}/           ← document ID = unique player ID
//         displayName : String   // e.g. "Alice"
//         score       : Number   // higher = better
//         difficulty  : String   // "easy" | "medium" | "hard" | "expert"
//         timeSeconds : Number   // completion time (lower = better)
//         completedAt : Timestamp
//
//  3. Security Rules (Firestore console → Rules tab):
//
//     rules_version = '2';
//     service cloud.firestore {
//       match /databases/{database}/documents {
//         match /leaderboard/{userId} {
//           // Only the authenticated owner may write their own doc
//           allow read: if true;
//           allow write: if request.auth != null
//                        && request.auth.uid == userId;
//         }
//       }
//     }
//
//  4. Composite index (needed for the leaderboard query):
//     Firestore console → Indexes → Add composite index:
//       Collection : leaderboard
//       Fields     : difficulty (Ascending) + score (Descending)
//       Query scope: Collection
//
//  5. Make sure Firebase is initialised in main.dart BEFORE
//     calling any service method:
//
//     void main() async {
//       WidgetsFlutterBinding.ensureInitialized();
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );
//       runApp(const MyApp());
//     }
// ============================================================

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sudokulegend/Screens/pages/statistics/stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Data model ───────────────────────────────────────────────

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int score;
  final String difficulty;
  final int timeSeconds;
  final DateTime completedAt;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.difficulty,
    required this.timeSeconds,
    required this.completedAt,
  });

  /// Build from a Firestore document snapshot.
  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      userId: doc.id,
      displayName: d['displayName'] as String? ?? 'Anonymous',
      score: (d['score'] as num?)?.toInt() ?? 0,
      difficulty: d['difficulty'] as String? ?? 'medium',
      timeSeconds: (d['timeSeconds'] as num?)?.toInt() ?? 0,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-ready map.
  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'score': score,
        'difficulty': difficulty,
        'timeSeconds': timeSeconds,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  String get formattedTime {
    final m = timeSeconds ~/ 60;
    final s = timeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── Service class ─────────────────────────────────────────────

class SudokuStorageService {
  // ── Singleton ──────────────────────────────────────────────
  SudokuStorageService._();
  static final SudokuStorageService instance = SudokuStorageService._();

  // ── Constants ──────────────────────────────────────────────
  static const String _gameDataKeyPrefix = 'sudoku_game_';
  static const String _activeGameKey = 'sudoku_active_game';
  // static const String _leaderboardCollection = 'leaderboard';
  static const String _nextSlotNumberKey = 'sudoku_next_slot_number';

  /// Gets the current slot number to use for a new game, then increments
  /// the counter for the *next* new game.
  /// Returns the slot number to be used for the current new game.
  Future<int> getAndIncrementGameSlotNumber() async {
    final prefs = await SharedPreferences.getInstance();
    int slotToUse = prefs.getInt(_nextSlotNumberKey) ?? 1;
    await prefs.setInt(_nextSlotNumberKey, slotToUse + 1);
    return slotToUse;
  }

  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════
  //  SECTION 1 — LOCAL GAME DATA  (SharedPreferences)
  // ════════════════════════════════════════════════════════════

  /// Save any game state map under a named [slot].
  ///
  /// Usage:
  /// ```dart
  /// await SudokuStorageService.instance.saveGame(
  ///   slot: 'slot_1',
  ///   data: {
  ///     'board': [...],
  ///     'difficulty': 'hard',
  ///     'elapsedSeconds': 142,
  ///     'hintsUsed': 2,
  ///   },
  /// );
  /// ```
  Future<bool> saveGame({
    String slot = 'default',
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_gameDataKeyPrefix$slot';
      // Stamp the save time automatically
      data['_savedAt'] = DateTime.now().toIso8601String();
      final json = jsonEncode(data);
      final success = await prefs.setString(key, json);

      // Automatically trigger statistics recalculation when a game is finished
      if (success && (data['isCompleted'] == true || data['isGameOver'] == true)) {
        await updateStatistics();
      }

      return success;
    } catch (e) {
      debugPrint('[SudokuStorageService] saveGame error: $e');
      return false;
    }
  }

  /// Load a previously saved game from [slot].
  /// Returns `null` if no data is found.
  ///
  /// Usage:
  /// ```dart
  /// final data = await SudokuStorageService.instance.loadGame(slot: 'slot_1');
  /// if (data != null) { /* restore board */ }
  /// ```
  Future<Map<String, dynamic>?> loadGame({String slot = 'default'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_gameDataKeyPrefix$slot';
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[SudokuStorageService] loadGame error: $e');
      return null;
    }
  }

  /// Save the "active" (in-progress) game — shorthand for the current session.
  Future<bool> saveActiveGame(Map<String, dynamic> data) =>
      saveGame(slot: _activeGameKey, data: data);

  /// Load the active in-progress game.
  Future<Map<String, dynamic>?> loadActiveGame() =>
      loadGame(slot: _activeGameKey);

  /// Delete the active in-progress game.
  Future<bool> deleteActiveGame() => deleteGame(slot: _activeGameKey);

  /// Clear a specific save slot.
  Future<bool> deleteGame({String slot = 'default'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.remove('$_gameDataKeyPrefix$slot');
    } catch (e) {
      debugPrint('[SudokuStorageService] deleteGame error: $e');
      return false;
    }
  }

  // Returns a list of all saved slot names (without the prefix).
  Future<List<String>> listSavedSlots() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((k) => k.startsWith(_gameDataKeyPrefix))
        .map((k) => k.replaceFirst(_gameDataKeyPrefix, ''))
        .toList();
  }

  // Returns a list of all saved games
  Future<List<Map<String, dynamic>>> listSavedGames() async {
    List<Map<String, dynamic>> gamesArray = [];
    Map<String, dynamic>? game;
    final prefs = await SharedPreferences.getInstance();
    final listofSavedSlots = await listSavedSlots();
    for (var iter in listofSavedSlots) {
      final raw = prefs.getString('$_gameDataKeyPrefix$iter');
      if (raw != null) {
        game = jsonDecode(raw) as Map<String, dynamic>;
        gamesArray.add(game);
      }
      
    }
    return gamesArray;
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 4 — STATISTICS CALCULATION
  // ════════════════════════════════════════════════════════════

  /// Recalculates statistics for all difficulties based on saved game history
  /// and persists them using the DifficultyStats local storage logic.
  Future<void> updateStatistics() async {
    final allGames = await listSavedGames();

    // Group games by difficulty level
    final Map<String, List<Map<String, dynamic>>> groupedGames = {};
    for (var game in allGames) {
      // Only process games that have reached a final state (Won or Lost)
      final bool isFinalState = (game['isCompleted'] == true || game['isGameOver'] == true);
      if (isFinalState && game.containsKey('level')) {
        final String level = game['level'].toString();
        groupedGames.putIfAbsent(level, () => []).add(game);
      }
    }

    for (var entry in groupedGames.entries) {
      final String level = entry.key;
      final List<Map<String, dynamic>> games = entry.value;

      // Sort by save date to accurately calculate win streaks
      games.sort((a, b) {
        final DateTime dateA = DateTime.tryParse(a['_savedAt'] ?? '') ?? DateTime(0);
        final DateTime dateB = DateTime.tryParse(b['_savedAt'] ?? '') ?? DateTime(0);
        return dateA.compareTo(dateB);
      });

      int gamesPlayed = games.length;
      int gamesWon = 0;
      int gamesLost = 0;
      int currentStreak = 0;
      int maxStreak = 0;
      int winWithNoMistakes = 0;
      int bestTimeSeconds = 0;
      int highScore = 0;

      for (var game in games) {
        final bool isWon = game['isCompleted'] == true;
        final bool isLost = game['isGameOver'] == true;

        if (isWon) {
          gamesWon++;
          currentStreak++;
          if (currentStreak > maxStreak) maxStreak = currentStreak;

          // Stats specific to won games
          final int mistakes = (game['mistakes'] as num?)?.toInt() ?? 0;
          if (mistakes == 0) winWithNoMistakes++;

          final int time = (game['secondsElapsed'] as num?)?.toInt() ?? 0;
          if (time > 0 && (bestTimeSeconds == 0 || time < bestTimeSeconds)) {
            bestTimeSeconds = time;
          }

          final int score = (game['score'] as num?)?.toInt() ?? 0;
          if (score > highScore) highScore = score;
        } else if (isLost) {
          gamesLost++;
          currentStreak = 0;
        }
      }

      final stats = DifficultyStats(
        gamesPlayed: gamesPlayed,
        gamesWon: gamesWon,
        gamesLost: gamesLost,
        winStreaks: maxStreak,
        winWithNoMistakes: winWithNoMistakes,
        winRate: gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0,
        bestTimeSeconds: bestTimeSeconds,
        highScore: highScore,
      );

      // Save the calculated stats using the model's persistence logic
      await stats.saveLocally(level);
    }
  }

  /// Wrapper for loading local statistics for a given difficulty.
  Future<DifficultyStats> loadStatistics(String difficulty) async {
    return DifficultyStats.loadLocally(difficulty);
  }

  // ════════════════════════════════════════════════════════════
  //  SECTION 2 — FIRESTORE SYNC
  // ════════════════════════════════════════════════════════════

  // /// Push a player's score to Firestore.
  // /// Call this after a player successfully completes a puzzle.
  // ///
  // /// Usage:
  // /// ```dart
  // /// await SudokuStorageService.instance.syncScoreToFirebase(
  // ///   entry: LeaderboardEntry(
  // ///     userId: FirebaseAuth.instance.currentUser!.uid,
  // ///     displayName: 'Alice',
  // ///     score: 4800,
  // ///     difficulty: 'hard',
  // ///     timeSeconds: 183,
  // ///     completedAt: DateTime.now(),
  // ///   ),
  // /// );
  // /// ```
  // Future<void> syncScoreToFirebase({required LeaderboardEntry entry}) async {
  //   try {
  //     await _firestore
  //         .collection(_leaderboardCollection)
  //         .doc(entry.userId)
  //         .set(entry.toFirestore(), SetOptions(merge: true));
  //     debugPrint('[SudokuStorageService] Score synced for ${entry.userId}');
  //   } on FirebaseException catch (e) {
  //     debugPrint('[SudokuStorageService] Firestore sync error: ${e.message}');
  //     rethrow;
  //   }
  // }

  // /// Fetch the top [limit] leaderboard entries for a given [difficulty].
  // /// Pass `difficulty: null` to fetch across all difficulties.
  // ///
  // /// Usage:
  // /// ```dart
  // /// final entries = await SudokuStorageService.instance
  // ///     .fetchLeaderboard(difficulty: 'hard', limit: 20);
  // /// ```
  // Future<List<LeaderboardEntry>> fetchLeaderboard({
  //   String? difficulty,
  //   int limit = 50,
  // }) async {
  //   try {
  //     Query<Map<String, dynamic>> query =
  //         _firestore.collection(_leaderboardCollection);

  //     if (difficulty != null) {
  //       query = query.where('difficulty', isEqualTo: difficulty);
  //     }

  //     // Requires the composite index described in the setup comment above
  //     query = query.orderBy('score', descending: true).limit(limit);

  //     final snapshot = await query.get();
  //     return snapshot.docs.map(LeaderboardEntry.fromFirestore).toList();
  //   } on FirebaseException catch (e) {
  //     debugPrint('[SudokuStorageService] fetchLeaderboard error: ${e.message}');
  //     return [];
  //   }
  // }

  // // ════════════════════════════════════════════════════════════
  // //  SECTION 3 — LEADERBOARD WIDGET
  // // ════════════════════════════════════════════════════════════

  // /// Returns a ready-to-use leaderboard widget.
  // ///
  // /// Usage — embed anywhere (full screen, bottom sheet, dialog):
  // /// ```dart
  // /// // As a full page:
  // /// Navigator.push(
  // ///   context,
  // ///   MaterialPageRoute(
  // ///     builder: (_) => Scaffold(
  // ///       body: SudokuStorageService.instance.buildLeaderboardWidget(
  // ///         difficulty: 'hard',
  // ///       ),
  // ///     ),
  // ///   ),
  // /// );
  // ///
  // /// // Inside a bottom sheet:
  // /// showModalBottomSheet(
  // ///   context: context,
  // ///   isScrollControlled: true,
  // ///   builder: (_) => SizedBox(
  // ///     height: MediaQuery.of(context).size.height * 0.75,
  // ///     child: SudokuStorageService.instance.buildLeaderboardWidget(),
  // ///   ),
  // /// );
  // /// ```
  // Widget buildLeaderboardWidget({
  //   String? difficulty,
  //   int limit = 50,
  //   String? highlightUserId,
  // }) {
  //   return _LeaderboardWidget(
  //     service: this,
  //     difficulty: difficulty,
  //     limit: limit,
  //     highlightUserId: highlightUserId,
  //   );
  // }

}

// ── Internal leaderboard widget ───────────────────────────────

// class _LeaderboardWidget extends StatefulWidget {
//   final SudokuStorageService service;
//   final String? difficulty;
//   final int limit;
//   final String? highlightUserId;

//   const _LeaderboardWidget({
//     required this.service,
//     this.difficulty,
//     this.limit = 50,
//     this.highlightUserId,
//   });

//   @override
//   State<_LeaderboardWidget> createState() => _LeaderboardWidgetState();
// }

// class _LeaderboardWidgetState extends State<_LeaderboardWidget> {
//   static const _difficulties = ['all', 'easy', 'medium', 'hard', 'expert'];

//   late String _selectedDifficulty;
//   late Future<List<LeaderboardEntry>> _future;

//   @override
//   void initState() {
//     super.initState();
//     _selectedDifficulty = widget.difficulty ?? 'all';
//     _loadData();
//   }

//   void _loadData() {
//     final diff =
//         _selectedDifficulty == 'all' ? null : _selectedDifficulty;
//     _future = widget.service.fetchLeaderboard(
//       difficulty: diff,
//       limit: widget.limit,
//     );
//   }

//   void _onDifficultyChanged(String diff) {
//     setState(() {
//       _selectedDifficulty = diff;
//       _loadData();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // ── Title bar ──────────────────────────────────────────
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//           decoration: const BoxDecoration(
//             color: Color(0xFF3D5A80),
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: const Text(
//             '🏆  Leaderboard',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 0.4,
//             ),
//           ),
//         ),

//         // ── Difficulty filter ──────────────────────────────────
//         Container(
//           color: const Color(0xFF3D5A80),
//           padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: _difficulties.map((d) {
//                 final selected = d == _selectedDifficulty;
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8),
//                   child: ChoiceChip(
//                     label: Text(
//                       d[0].toUpperCase() + d.substring(1),
//                       style: TextStyle(
//                         color: selected
//                             ? const Color(0xFF3D5A80)
//                             : Colors.white70,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 12,
//                       ),
//                     ),
//                     selected: selected,
//                     selectedColor: Colors.white,
//                     backgroundColor: const Color(0xFF4E6F96),
//                     side: BorderSide.none,
//                     onSelected: (_) => _onDifficultyChanged(d),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),

//         // ── Entry list ─────────────────────────────────────────
//         Expanded(
//           child: FutureBuilder<List<LeaderboardEntry>>(
//             future: _future,
//             builder: (context, snap) {
//               if (snap.connectionState == ConnectionState.waiting) {
//                 return const Center(
//                   child: CircularProgressIndicator(
//                     color: Color(0xFF3D5A80),
//                   ),
//                 );
//               }

//               if (snap.hasError) {
//                 return Center(
//                   child: Text(
//                     'Failed to load leaderboard.\n${snap.error}',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                 );
//               }

//               final entries = snap.data ?? [];

//               if (entries.isEmpty) {
//                 return const Center(
//                   child: Text(
//                     'No scores yet.\nBe the first! 🎯',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Color(0xFF3D5A80),
//                       height: 1.6,
//                     ),
//                   ),
//                 );
//               }

//               return ListView.separated(
//                 padding: const EdgeInsets.symmetric(
//                     vertical: 12, horizontal: 16),
//                 itemCount: entries.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 8),
//                 itemBuilder: (_, i) => _LeaderboardRow(
//                   rank: i + 1,
//                   entry: entries[i],
//                   isHighlighted:
//                       entries[i].userId == widget.highlightUserId,
//                 ),
//               );
//             },
//           ),
//         ),

//         // ── Refresh ────────────────────────────────────────────
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//           child: OutlinedButton.icon(
//             onPressed: () => setState(_loadData),
//             icon: const Icon(Icons.refresh, size: 16),
//             label: const Text('Refresh'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: const Color(0xFF3D5A80),
//               side: const BorderSide(color: Color(0xFF3D5A80)),
//               minimumSize: const Size.fromHeight(40),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ── Single leaderboard row ────────────────────────────────────

// class _LeaderboardRow extends StatelessWidget {
//   final int rank;
//   final LeaderboardEntry entry;
//   final bool isHighlighted;

//   const _LeaderboardRow({
//     required this.rank,
//     required this.entry,
//     this.isHighlighted = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isMedal = rank <= 3;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: isHighlighted
//             ? const Color(0xFFE8F0FE)
//             : isMedal
//                 ? const Color(0xFFFFFDE7)
//                 : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isHighlighted
//               ? const Color(0xFF3D5A80)
//               : isMedal
//                   ? const Color(0xFFFFD54F)
//                   : const Color(0xFFE0E0E0),
//           width: isHighlighted ? 1.5 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Rank / medal
//           SizedBox(
//             width: 32,
//             child: Text(
//               rank == 1
//                   ? '🥇'
//                   : rank == 2
//                       ? '🥈'
//                       : rank == 3
//                           ? '🥉'
//                           : '#$rank',
//               style: TextStyle(
//                 fontSize: rank <= 3 ? 20 : 13,
//                 fontWeight: FontWeight.w700,
//                 color: const Color(0xFF3D5A80),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),

//           // Name + difficulty badge
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   entry.displayName,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                     color: Color(0xFF1A2B3C),
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 2),
//                 _DifficultyBadge(difficulty: entry.difficulty),
//               ],
//             ),
//           ),

//           // Time
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '${entry.score} pts',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                   fontSize: 14,
//                   color: Color(0xFF3D5A80),
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Row(
//                 children: [
//                   const Icon(Icons.timer_outlined,
//                       size: 11, color: Colors.grey),
//                   const SizedBox(width: 2),
//                   Text(
//                     entry.formattedTime,
//                     style: const TextStyle(
//                         fontSize: 11, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DifficultyBadge extends StatelessWidget {
//   final String difficulty;

//   const _DifficultyBadge({required this.difficulty});

//   Color get _color {
//     switch (difficulty.toLowerCase()) {
//       case 'easy':
//         return Colors.green;
//       case 'medium':
//         return Colors.orange;
//       case 'hard':
//         return Colors.red;
//       case 'expert':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: _color.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(color: _color.withOpacity(0.4)),
//       ),
//       child: Text(
//         difficulty[0].toUpperCase() + difficulty.substring(1),
//         style: TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//           color: _color,
//         ),
//       ),
//     );
//   }
// }
