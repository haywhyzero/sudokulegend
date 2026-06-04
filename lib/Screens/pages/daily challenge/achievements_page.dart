import 'package:flutter/material.dart' hide Badge;
import 'package:sudokulegend/Models/badge_service.dart';
import 'daily_challenge_screen.dart';
import 'package:sudokulegend/Widgets/helper.dart';
import 'all_badges.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final badgeService = BadgeService();
  List<Badge> _allBadges = [];
  List<Map<String, dynamic>> _claimedMonths = [];

  @override
  void initState() {
    super.initState();
    initAchievement();
    _loadClaimedMonths();
  }

  void initAchievement() async {
    await badgeService.loadBadges();
    final allBadges = badgeService.getAllBadges();
    final badges = allBadges.values
                    .where((element) => element.unlocked)
                    .take(4).toList();
    _allBadges = badges;
  }

  Future<void> _loadClaimedMonths() async {
    final prefs = await SharedPreferences.getInstance();
    final claimedMonthsJson = prefs.getStringList('claimed_monthly_trophies') ?? [];
    final months = <Map<String, dynamic>>[];

    for (var monthJson in claimedMonthsJson) {
      months.add(Map<String, dynamic>.from(
        (jsonDecode(monthJson) as Map).cast<String, dynamic>()
      ));
    }

    if (mounted) {
      setState(() {
        _claimedMonths = months;
      });
    }
  }

  Future<bool> _canClaimMonthTrophy(int month, int year) async {
    final allGames = await SudokuStorageService.instance.listSavedGames();
    final monthGames = allGames.where((game) {
      if (game['isCompleted'] != true || game['_savedAt'] == null) return false;
      final gameDate = DateTime.tryParse(game['_savedAt'] as String);
      // if (gameDate != null && gameDate.month == 2) return gameDate.month == month && gameDate.year == year;
      return gameDate != null && gameDate.month == month && gameDate.year == year;
    }).length;
    return monthGames >= 30;
  }

  Future<void> _claimMonthTrophy(int month, int year) async {
    final canClaim = await _canClaimMonthTrophy(month, year);
    if (!canClaim && mounted) {
      showSnackBar(
        context: context,
        message: 'Complete 30 games this month to claim the trophy',
        bgColor: Colors.orange,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final monthData = {
      'month': month,
      'year': year,
      'claimedAt': DateTime.now().toIso8601String(),
    };

    final claimedMonthsJson = prefs.getStringList('claimed_monthly_trophies') ?? [];
    claimedMonthsJson.add(jsonEncode(monthData));
    await prefs.setStringList('claimed_monthly_trophies', claimedMonthsJson);

    if (mounted) {
      showSnackBar(
        context: context,
        message: 'Trophy claimed! 🏆',
        bgColor: Colors.green,
      );
      await _loadClaimedMonths();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final currentMonthName = months[now.month - 1];
    final currentYear = now.year;

    final displayedMonths = _claimedMonths.length > 4
        ? _claimedMonths.sublist(_claimedMonths.length - 4)
        : _claimedMonths;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Badges & Achievements',
          style: TextStyle(color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Performance Badges'),
            const SizedBox(height: 16),
            _allBadges.isEmpty ? _buildEmptyBadgeState() :
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: _allBadges.map((e) => buildBadgeItem(e.name, e.description, e.unlocked),).toList(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [TextButton(onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => AllBadges()));
              }, child: Text("See all"))],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Monthly Challenge Trophies'),
            const SizedBox(height: 16),
            displayedMonths.isEmpty
                ? _buildEmptyMonthlyState()
                : Column(
                    children: [
                      ...displayedMonths.map((monthData) {
                        final month = monthData['month'] as int;
                        final year = monthData['year'] as int;
                        return _buildMonthlyTrophyCard(month, year);
                      }).toList(),
                      if (_claimedMonths.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => _showAllMonthlyTrophies(context),
                              child: const Text('View All Monthly Trophies'),
                            ),
                          ),
                        ),
                    ],
                  ),
            const SizedBox(height: 32),
            _buildSectionTitle('Current Month Trophy'),
            const SizedBox(height: 16),
            _buildCurrentMonthTrophy(currentMonthName, currentYear),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMonthlyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'No Monthly Trophies Yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete 30 games in a month to claim a trophy',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBadgeState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'No Badges unlocked Yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Click see all to see all badges',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMonthlyTrophyCard(int month, int year) {
    final monthName = _getMonthName(month);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(painter: TrophyPainter()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName $year 👑',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Monthly Champion',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthTrophy(String monthName, int year) {
    final isFeb = monthName == "February";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(painter: TrophyPainter()),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName $year Champion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isFeb ? 'Complete 28 games this month to claim this trophy' :
                  'Complete 30 games this month to claim this trophy.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _claimMonthTrophy(DateTime.now().month, DateTime.now().year),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Claim Trophy'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllMonthlyTrophies(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Monthly Trophies (${_claimedMonths.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _claimedMonths.length,
                itemBuilder: (context, index) {
                  final monthData = _claimedMonths[index];
                  final month = monthData['month'] as int;
                  final year = monthData['year'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMonthlyTrophyCard(month, year),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3D5A80),
      ),
    );
  }
}
