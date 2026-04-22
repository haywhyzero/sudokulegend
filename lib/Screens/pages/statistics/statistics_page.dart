import 'package:flutter/material.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String selectedDifficulty = "Hard";

  final List<String> difficulties = [
    "Easy",
    "Medium",
    "Hard",
    "Expert",
    "Master",
    "Extreme",
    "16x16",
  ];

  final Map<String, Map<String, dynamic>> mockStats = {
    "Hard": {
      "Games Played": 29,
      "Game Won": 24,
      "Game Lost": 5,
      "Win Streaks": 4,
      "Win with no mistakes": 17,
      "Win Rate": "76%",
      "Best Time": "09:43",
      "High Score": 5345,
    },
    // You can add other difficulties later
  };

  void _openmodaloverlay() {
    showModalBottomSheet(
      // isScrollControlled: true,
      context: context,
      // backgroundColor: Colors.transparent,
      showDragHandle: true,
      enableDrag: true,
      builder: (context) {
        return Center(child: Text("Filter by difficulty"));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = mockStats[selectedDifficulty] ?? mockStats["Hard"]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Statistics",
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        // actions: const [
        //   Padding(
        //     padding: EdgeInsets.only(right: 16),
        //     child: Icon(Icons.share_outlined, color: Colors.black),
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.green[100],
                  child: Image.asset(
                    "assets/images/403024_avatar_boy_male_user_young_icon.png",
                    width: 50,
                    height: 50,
                    errorBuilder: (err, error, tracestack) =>
                        const Icon(Icons.person, size: 40, color: Colors.green),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ajayi Daniel",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Dahak",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Difficulty Dropdown
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: GestureDetector(
                    onTap: _openmodaloverlay,
                    child: Container(
                      width: 90,
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.black26
                              : Colors.white54,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Hard"), // replace with last unlocked difficulty
                          SizedBox(width: 5),
                          Icon(Icons.arrow_drop_down_sharp),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Stats List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              children: [
                _buildStatRow("Games Played", stats["Games Played"].toString()),
                _buildStatRow(
                  "Game Won",
                  stats["Game Won"].toString(),
                  highlight: true,
                ),
                _buildStatRow("Game Lost", stats["Game Lost"].toString()),
                _buildStatRow("Win Streaks", stats["Win Streaks"].toString()),
                _buildStatRow(
                  "Win with no mistakes",
                  stats["Win with no mistakes"].toString(),
                ),
                _buildStatRow("Win Rate", stats["Win Rate"], highlight: true),
                _buildStatRow("Best Time", stats["Best Time"]),
                _buildStatRow(
                  "High Score",
                  stats["High Score"].toString(),
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFE3F2FD)
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black87
                  : highlight
                      ? Colors.black87
                      : Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight
                  ? Colors.blue[700]
                  : Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
        ],
      ),
    );
  }
}
