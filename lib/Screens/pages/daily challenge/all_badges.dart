import 'package:flutter/material.dart';
import 'package:sudokulegend/Widgets/helper.dart';

class AllBadges extends StatelessWidget {
   AllBadges({super.key});

  final List<Widget> badges = [
    buildBadgeItem('Speed Demon', 'Complete in < 5 mins', true),
    buildBadgeItem('Perfect Game', 'No mistakes made', true),
    buildBadgeItem('Master', 'Complete 10 Expert levels', false),
    buildBadgeItem('Lightning Strike', 'Solve under 2 minutes', false),
    buildBadgeItem('Time Lord', 'Beat personal best score', false),
    buildBadgeItem('Blitz Solver', 'Solve 10 puzzles under 10 minutes', false),
    buildBadgeItem('Flawless Touch', '50 consecutive error-free puzzles', false),
    buildBadgeItem('Error Tolerance', '100 Games with zero mistakes', false),
    buildBadgeItem('Pencil-Free Pro', 'Complete Expert puzzles without pencil mode', false),
    buildBadgeItem('Daily Devotee', '30-day daily challenge streak', false),
    buildBadgeItem('Unbreakable Chain', '100-days daily challenge streak', false),
    buildBadgeItem('Weekend Warrior', 'Solve every weekend for 3 months', false),
    buildBadgeItem('Iron Solver', 'Never miss a day for 60 days', false),
    buildBadgeItem('Century club', 'Solve 100 puzzles', false),
    buildBadgeItem('Sudoku Sage', '500 puzzles solved', false),
    buildBadgeItem('Grid Gladiator', '1,000 puzzles completed', false),
    buildBadgeItem('Puzzle Titan', '5,000 lifetime puzzles', false),
    buildBadgeItem('Expert Conqueror', 'Complete 50 Expert puzzles', false),
    buildBadgeItem('Nightmare Slayer', 'Finish 20 Extreme puzzles', false),
    buildBadgeItem('Evil Tamer', 'Solve 5 16by16 puzzles', false),
    buildBadgeItem('Night Owl', 'Solve 50 puzzles between 10PM - 5AM', false),
    buildBadgeItem('Early Bird', 'Solve 50 puzzles between 5AM - 8AM', false),
    buildBadgeItem('Hint Hero ', ' Complete puzzle using minimal hints', false),
    buildBadgeItem('Leaderboard King', 'Top 10 performer in leaderboard', false),
    buildBadgeItem('Sudoku Legend', 'All badges unlocked', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Performance Badges', style: TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Scrollbar(
        thumbVisibility: false,
        interactive: true,
        trackVisibility: false,
        thickness: 10,
        radius: Radius.circular(8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: badges,
              ),
            ],
          ),
        ),
      ),
    );
  }


}