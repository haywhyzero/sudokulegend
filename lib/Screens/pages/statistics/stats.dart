import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  STATS MODEL
// ══════════════════════════════════════════════════════════════════════════════

class DifficultyStats {
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int winStreaks;
  final int winWithNoMistakes;
  final double winRate; // 0.0 – 1.0
  final int bestTimeSeconds; // 0 = no record
  final int highScore;

  const DifficultyStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.winStreaks = 0,
    this.winWithNoMistakes = 0,
    this.winRate = 0,
    this.bestTimeSeconds = 0,
    this.highScore = 0,
  });

  // ── SharedPreferences key prefix ────────────────────────────────────────────
  static String _key(String difficulty, String field) =>
      'stats_${difficulty.toLowerCase()}_$field';

  /// Save to SharedPreferences (called after every completed game).
  Future<void> saveLocally(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(difficulty, 'gamesPlayed'), gamesPlayed);
    await prefs.setInt(_key(difficulty, 'gamesWon'), gamesWon);
    await prefs.setInt(_key(difficulty, 'gamesLost'), gamesLost);
    await prefs.setInt(_key(difficulty, 'winStreaks'), winStreaks);
    await prefs.setInt(
      _key(difficulty, 'winWithNoMistakes'),
      winWithNoMistakes,
    );
    await prefs.setDouble(_key(difficulty, 'winRate'), winRate);
    await prefs.setInt(_key(difficulty, 'bestTimeSeconds'), bestTimeSeconds);
    await prefs.setInt(_key(difficulty, 'highScore'), highScore);
  }

  /// Load from SharedPreferences (offline fallback).
  static Future<DifficultyStats> loadLocally(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final played = prefs.getInt(_key(difficulty, 'gamesPlayed')) ?? 0;
    final won = prefs.getInt(_key(difficulty, 'gamesWon')) ?? 0;
    final lost = prefs.getInt(_key(difficulty, 'gamesLost')) ?? 0;
    final rate = played > 0 ? won / played : 0.0;
    return DifficultyStats(
      gamesPlayed: played,
      gamesWon: won,
      gamesLost: lost,
      winStreaks: prefs.getInt(_key(difficulty, 'winStreaks')) ?? 0,
      winWithNoMistakes:
          prefs.getInt(_key(difficulty, 'winWithNoMistakes')) ?? 0,
      winRate: prefs.getDouble(_key(difficulty, 'winRate')) ?? rate,
      bestTimeSeconds: prefs.getInt(_key(difficulty, 'bestTimeSeconds')) ?? 0,
      highScore: prefs.getInt(_key(difficulty, 'highScore')) ?? 0,
    );
  }

  /// Load from Firestore (online, signed-in users).
  ///
  /// Firestore structure:
  ///   users/{uid}/stats/{difficulty}   (document per difficulty)
  ///     gamesPlayed     : number
  ///     gamesWon        : number
  ///     gamesLost       : number
  ///     winStreaks       : number
  ///     winWithNoMistakes : number
  ///     winRate         : number  (0.0 – 1.0)
  ///     bestTimeSeconds : number
  ///     highScore       : number
  static Future<DifficultyStats> loadFromFirestore(
    String uid,
    String difficulty,
  ) async {
    // final doc = await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(uid)
    //     .collection('stats')
    //     .doc(difficulty.toLowerCase())
    //     .get();

    // if (!doc.exists) return const DifficultyStats();
    // final d = doc.data()!;
    // return DifficultyStats(
    //   gamesPlayed: (d['gamesPlayed'] as num?)?.toInt() ?? 0,
    //   gamesWon: (d['gamesWon'] as num?)?.toInt() ?? 0,
    //   gamesLost: (d['gamesLost'] as num?)?.toInt() ?? 0,
    //   winStreaks: (d['winStreaks'] as num?)?.toInt() ?? 0,
    //   winWithNoMistakes: (d['winWithNoMistakes'] as num?)?.toInt() ?? 0,
    //   winRate: (d['winRate'] as num?)?.toDouble() ?? 0,
    //   bestTimeSeconds: (d['bestTimeSeconds'] as num?)?.toInt() ?? 0,
    //   highScore: (d['highScore'] as num?)?.toInt() ?? 0,
    // );
    return DifficultyStats();
  }

  String get formattedBestTime {
    if (bestTimeSeconds == 0) return '--:--';
    final m = (bestTimeSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (bestTimeSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get formattedWinRate => '${(winRate * 100).toStringAsFixed(0)}%';
}

// ══════════════════════════════════════════════════════════════════════════════
//  LOADING STRATEGY
//  Tries Firebase if user is signed in, otherwise falls back to SharedPrefs.
// ══════════════════════════════════════════════════════════════════════════════

enum _DataSource { firebase, local }

class _StatsResult {
  final DifficultyStats stats;
  final _DataSource source;
  const _StatsResult(this.stats, this.source);
}

Future<_StatsResult> _loadStats(String difficulty) async {
  // final user = FirebaseAuth.instance.currentUser;

  // // Signed in — try Firebase first
  // if (user != null) {
  //   try {
  //     final stats = await DifficultyStats.loadFromFirestore(
  //       user.uid,
  //       difficulty,
  //     );
  //     return _StatsResult(stats, _DataSource.firebase);
  //   } catch (_) {
  //     // Firebase failed (no internet) → fall through to local
  //       final stats = await DifficultyStats.loadLocally(difficulty);
  //       return _StatsResult(stats, _DataSource.local);
  //   }
  // }

  // Not signed in or Firebase failed → SharedPreferences
  final stats = await DifficultyStats.loadLocally(difficulty);
  return _StatsResult(stats, _DataSource.local);
}

// ══════════════════════════════════════════════════════════════════════════════
//  PROFILE PROVIDER (reuse yours — placeholder here)
// ══════════════════════════════════════════════════════════════════════════════

class ProfileState {
  final String name;
  final String username;
  final String? avatarUrl;
  const ProfileState({
    this.name = 'Ajayi Daniel',
    this.username = 'Dahak',
    this.avatarUrl,
  });
}

final profileProvider = Provider<ProfileState>((_) => const ProfileState());

// ══════════════════════════════════════════════════════════════════════════════
//  STATISTICS PAGE
// ══════════════════════════════════════════════════════════════════════════════

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with SingleTickerProviderStateMixin {
  static const _difficulties = ['Easy', 'Medium', 'Hard', 'Expert'];
  int _selectedIndex = 2;

  // Each difficulty gets its own Future so switching is instant after first load
  final Map<String, Future<_StatsResult>> _futures = {};

  late final AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);

    _loadForCurrent();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _loadForCurrent() {
    final diff = _difficulties[_selectedIndex];
    _futures.putIfAbsent(diff, () => _loadStats(diff));
  }

  void _onDifficultyChanged(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _loadForCurrent();
    });
    _slideCtrl
      ..reset()
      ..forward();
  }

  void _retry() {
    final diff = _difficulties[_selectedIndex];
    setState(() {
      _futures[diff] = _loadStats(diff);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final diff = _difficulties[_selectedIndex];

    return Scaffold(
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          _Header(
            profile: profile,
            difficulties: _difficulties,
            selectedIndex: _selectedIndex,
            onDifficultyChanged: _onDifficultyChanged,
          ),
      
          const SizedBox(height: 4),
      
          // ── Stats list ─────────────────────────────────────────
          Expanded(
            child: FutureBuilder<_StatsResult>(
              future: _futures[diff],
              builder: (context, snap) {
                // Loading
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _LoadingState();
                }
      
                // Error
                if (snap.hasError || !snap.hasData) {
                  return _ErrorState(onRetry: _retry);
                }
      
                final result = snap.data!;
      
                return SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _StatsList(
                      stats: result.stats,
                      source: result.source,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Header
class _Header extends StatelessWidget {
  final ProfileState profile;
  final List<String> difficulties;
  final int selectedIndex;
  final ValueChanged<int> onDifficultyChanged;

  const _Header({
    required this.profile,
    required this.difficulties,
    required this.selectedIndex,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 65,
            height: 65,
            padding: const EdgeInsets.all(2.5),
            child: ClipOval(
              child: profile.avatarUrl != null
                  ? Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _InitialsAvatar(name: profile.name),
                    )
                  : Image.asset("assets/images/403024_avatar_boy_male_user_young_icon.png", width: 20, height: 20,),
            ),
          ),

          const SizedBox(width: 12),

          // Name / username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.username,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Difficulty picker chip
          _DifficultyChip(
            difficulties: difficulties,
            selectedIndex: selectedIndex,
            onChanged: onDifficultyChanged,
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD0E8FF),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3D5A80),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DIFFICULTY CHIP  (tap → bottom sheet picker)
// ══════════════════════════════════════════════════════════════════════════════

class _DifficultyChip extends StatelessWidget {
  final List<String> difficulties;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DifficultyChip({
    required this.difficulties,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD0DCE8), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              difficulties[selectedIndex],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D5A80),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_sharp,
              size: 18,
              color: Color(0xFF3D5A80),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Difficulty',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(difficulties.length, (i) {
              final selected = i == selectedIndex;
              return ListTile(
                onTap: () {
                  Navigator.pop(context);
                  onChanged(i);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: selected
                    ? const Color(0xFF3D5A80).withOpacity(0.08)
                    : null,
                title: Text(
                  difficulties[i],
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF3D5A80)
                        : const Color(0xFF1A2B3C),
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: Color(0xFF3D5A80))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATS LIST
// ══════════════════════════════════════════════════════════════════════════════

class _StatsList extends StatelessWidget {
  final DifficultyStats stats;
  final _DataSource source;

  const _StatsList({required this.stats, required this.source});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _StatRow(
        label: 'Game Played',
        value: '${stats.gamesPlayed}',
        isEven: false,
      ),
      _StatRow(
        label: 'Game Won',
        value: '${stats.gamesWon}',
        isEven: true,
      ),
      _StatRow(
        label: 'Game Lost',
        value: '${stats.gamesLost}',
        isEven: false,
      ),
      _StatRow(
        label: 'Win Streaks',
        value: '${stats.winStreaks}',
        isEven: true,
      ),
      _StatRow(
        label: 'Win with no mistakes',
        value: '${stats.winWithNoMistakes}',
        isEven: false,
      ),
      _StatRow(
        label: 'Win Rate',
        value: stats.formattedWinRate,
        isEven: true,
      ),
      _StatRow(
        label: 'Best Time',
        value: stats.formattedBestTime,
        isEven: false,
      ),
      _StatRow(
        label: 'High Score',
        value: _formatScore(stats.highScore),
        isEven: true,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Offline / online badge
        if (source == _DataSource.local) _OfflineBanner(),

        const SizedBox(height: 4),

        // Cards
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(rows.length, (i) {
              final isLast = i == rows.length - 1;
              return Column(
                children: [
                  rows[i],
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: const Color(0xFFF0F4F8),
                      indent: 56,
                      endIndent: 0,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }


  String _formatScore(int score) {
    if (score >= 1000) {
      final s = (score / 1000).toStringAsFixed(score % 1000 == 0 ? 0 : 1);
      return '${s}k';
    }
    return score.toString();
  }
}

// ── Single stat row ───────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEven;

  const _StatRow({
    required this.label,
    required this.value,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? const Color(0xFFF7FAFD) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          // Label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3A4A5C),
              ),
            ),
          ),
          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// show offline banner
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: Color(0xFFF9A825),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing locally saved stats — sign in for live data.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.amber[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  LOADING STATE
// ══════════════════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF3D5A80),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading stats…',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Error State
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load stats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5A80),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

