import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int score;
  final String difficulty;
  final String? avatarUrl;
  final bool hasAllBadges;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.difficulty,
    this.avatarUrl,
    this.hasAllBadges = false,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final badges = d['badges'] as List? ?? [];
    final hasAllBadges = badges.contains('sudoku_legend');

    return LeaderboardEntry(
      userId: doc.id,
      displayName: d['displayName'] as String? ?? 'Anonymous',
      score: (d['score'] as num?)?.toInt() ?? 0,
      difficulty: d['difficulty'] as String? ?? 'medium',
      avatarUrl: d['avatarUrl'] as String?,
      hasAllBadges: hasAllBadges,
    );
  }
}


class LeaderboardPage extends StatefulWidget {
  /// Pass the current user's ID to highlight their row.
  final String? currentUserId;

  const LeaderboardPage({super.key, this.currentUserId});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  // Difficulty tabs
  static const _difficulties = ['Easy', 'Medium', 'Hard', 'Expert'];
  int _selectedIndex = 0;

  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onDifficultyChanged(int index) {
    if (index == _selectedIndex) return;
    _fadeCtrl.reverse().then((_) {
      setState(() => _selectedIndex = index);
      _fadeCtrl.forward();
    });
  }

  // Firestore stream for the selected difficulty
  Stream<List<LeaderboardEntry>> _stream() {
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .where('difficulty',
            isEqualTo: _difficulties[_selectedIndex].toLowerCase())
        .orderBy('score', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map(LeaderboardEntry.fromFirestore).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _Header(currentUserId: widget.currentUserId),
            _DifficultySelector(
              difficulties: _difficulties,
              selectedIndex: _selectedIndex,
              onChanged: _onDifficultyChanged,
            ),
            const SizedBox(height: 8),
            _ColumnHeaders(),
            Expanded(
              child: StreamBuilder<List<LeaderboardEntry>>(
                stream: _stream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3D5A80),
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  if (snap.hasError) {
                    return _ErrorState(message: snap.error.toString());
                  }

                  final entries = snap.data ?? [];

                  if (entries.isEmpty) {
                    return const _EmptyState();
                  }

                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: entries.length,
                      itemBuilder: (_, i) => _LeaderboardRow(
                        rank: i + 1,
                        entry: entries[i],
                        isCurrentUser:
                            entries[i].userId == widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String? currentUserId;
  const _Header({this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Flag + avatar cluster
          Row(
            children: [
              // Country flag chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Nigerian flag emoji as placeholder — swap with your flag widget
                    const Text('🇳🇬', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down,
                        size: 16, color: Colors.grey[600]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // User avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD0E8FF),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: const DecorationImage(
                    // Replace with your actual avatar asset/network image
                    image: AssetImage('assets/images/avatar_placeholder.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Difficulty selector ───────────────────────────────────────────────────────

class _DifficultySelector extends StatelessWidget {
  final List<String> difficulties;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DifficultySelector({
    required this.difficulties,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dropdown-style pill — tap opens a simple bottom sheet picker
          GestureDetector(
            onTap: () => _showPicker(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    difficulties[selectedIndex],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: Color(0xFF3D5A80)),
                ],
              ),
            ),
          ),
        ],
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
            // Handle
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
            const SizedBox(height: 16),
            ...List.generate(difficulties.length, (i) {
              final selected = i == selectedIndex;
              return ListTile(
                onTap: () {
                  Navigator.pop(context);
                  onChanged(i);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: selected
                    ? const Color(0xFF3D5A80).withOpacity(0.08)
                    : null,
                title: Text(
                  difficulties[i],
                  style: TextStyle(
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF3D5A80)
                        : const Color(0xFF1A2B3C),
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded,
                        color: Color(0xFF3D5A80))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Column headers ────────────────────────────────────────────────────────────

class _ColumnHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF8A9BB0),
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        children: [
          // Avatar placeholder width
          const SizedBox(width: 44),
          const Text('USER NAME', style: style),
          const Spacer(),
          const Text('SCORE', style: style),
          const SizedBox(width: 32),
          const Text('RANK', style: style),
        ],
      ),
    );
  }
}

// ── Leaderboard row ───────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    this.isCurrentUser = false,
  });

  String get _rankLabel {
    switch (rank) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${rank}th';
    }
  }

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB300); // gold
      case 2:
        return const Color(0xFF90A4AE); // silver
      case 3:
        return const Color(0xFFBF8B5E); // bronze
      default:
        return const Color(0xFF8A9BB0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alternating row background
    final isEven = rank % 2 == 0;
    final bg = isCurrentUser
        ? const Color(0xFFDCEEFF)
        : isEven
            ? const Color(0xFFEAF2FB)
            : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF3D5A80), width: 1.5)
            : null,
        boxShadow: isCurrentUser
            ? [
                BoxShadow(
                  color: const Color(0xFF3D5A80).withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD0E8FF),
                    border: Border.all(
                      color: rank <= 3 ? _rankColor : Colors.white,
                      width: rank <= 3 ? 2.5 : 1.5,
                    ),
                  ),
                  child: entry.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            entry.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _DefaultAvatar(name: entry.displayName),
                          ),
                        )
                      : _DefaultAvatar(name: entry.displayName),
                ),
                // Crown for rank 1
                if (rank == 1)
                  Positioned(
                    top: -10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '👑',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // ── Name ────────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrentUser || rank <= 3
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: const Color(0xFF1A2B3C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.hasAllBadges)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('👑', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),

            // ── Score ────────────────────────────────────────────
            SizedBox(
              width: 72,
              child: Text(
                _formatScore(entry.score),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3 ? _rankColor : const Color(0xFF3D5A80),
                ),
              ),
            ),

            // ── Rank badge ───────────────────────────────────────
            SizedBox(
              width: 44,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? _rankColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _rankLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _rankColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(score % 1000 == 0 ? 0 : 1)}k';
    }
    return score.toString();
  } 
}

// ── Default avatar (initials) ─────────────────────────────────────────────────

class _DefaultAvatar extends StatelessWidget {
  final String name;
  const _DefaultAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF3D5A80),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3D5A80).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: Color(0xFF3D5A80),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No scores yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to complete a puzzle!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Could not load leaderboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
