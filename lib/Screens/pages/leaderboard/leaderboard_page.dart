import 'package:flutter/material.dart';
import 'package:sudokulegend/Screens/pages/settings/profile_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
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
    return Scaffold(
      appBar: AppBar(
        leading: null,
        title: Text(
          "Leaderboad",
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                GestureDetector(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 13, child: Icon(Icons.flag_circle)),
                      Icon(Icons.arrow_drop_down_sharp),
                    ],
                  ),
                ),
                SizedBox(width: 3),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 13,
                    child: Image.asset(
                      'assets/images/403024_avatar_boy_male_user_young_icon.png',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: GestureDetector(
              onTap: _openmodaloverlay,
              child: Container(
                width: 90,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
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

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    "User Name",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Score",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Rank",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Leaderboard rows
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                LeaderboardRow(
                  name: "Dahak",
                  score: 5345,
                  rank: "1st",
                  highlight: true,
                ),
                LeaderboardRow(
                  name: "Joe",
                  score: 5234,
                  rank: "2nd",
                  highlight: true,
                ),
                LeaderboardRow(
                  name: "Sam",
                  score: 5112,
                  rank: "3rd",
                  highlight: true,
                ),
                LeaderboardRow(name: "John", score: 4567, rank: "4th"),
                LeaderboardRow(name: "Smith08", score: 4229, rank: "5th"),
                LeaderboardRow(name: "Biggie", score: 3002, rank: "6th"),
                LeaderboardRow(name: "Alex43", score: 2882, rank: "7th"),
                LeaderboardRow(name: "Kelly", score: 2765, rank: "8th"),
                LeaderboardRow(name: "Rose1", score: 1889, rank: "9th"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardRow extends StatelessWidget {
  final String name;
  final int score;
  final String rank;
  final bool highlight;

  const LeaderboardRow({
    super.key,
    required this.name,
    required this.score,
    required this.rank,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE3F2FD) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green[100],
            child: Icon(Icons.person, color: Colors.green[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              score.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              rank,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: highlight ? Colors.blue[700] : Colors.grey[700],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
