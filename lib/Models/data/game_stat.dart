// final uuid = Uuid();
class GameStat {
  GameStat({
    required this.id,
    required this.completedAt,
    required this.difficulty,
    required this.time,
    required this.score,
    this.completed = false,
    this.username,
  });

  final String id;
  final DateTime completedAt;
  final String difficulty;
  final int time;
  final int score;
  final bool completed;
  final String? username;

  Map<String, dynamic> toJSON() => {
    "id": id,
    "completedAt": completedAt.toIso8601String(),
    "difficulty": difficulty,
    "time": time,
    "score": score,
    "completed": completed,
    "username": username,
  };

  factory GameStat.fromJson(Map<String, dynamic> json) => GameStat(
    id: json['id'] as String,
    completedAt: DateTime.parse(json['completedAt']),
    difficulty: json['difficulty'] as String,
    time: json['time'] as int,
    score: json['score'] as int,
    completed: json['completed'] as bool? ?? true,
    username: json['username'] as String?
  );
}
