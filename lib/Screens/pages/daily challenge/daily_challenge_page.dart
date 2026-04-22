import 'package:flutter/material.dart';

class DailyChallengePage extends StatefulWidget {
  const DailyChallengePage({super.key});

  @override
  State<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends State<DailyChallengePage> {
  DateTime currentMonth = DateTime(2025, 8);
  
  // Completed days (with dashed circles)
  final Set<int> completedDays = {2, 4, 12, 13, 14, 15, 17};
  
  // Current day being played
  final int currentDay = 25;
  
  // Trophy count
  final int trophiesEarned = 7;
  final int totalTrophies = 31;

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Daily Challenge",
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  '$trophiesEarned/$totalTrophies',
                  style: const TextStyle(
                    // color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Trophy Image
          Container(
            height: 140,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomPaint(
              size: const Size(180, 140),
              painter: TrophyPainter(),
            ),
          ),

          // Month Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    // color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                    onPressed: _previousMonth,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getMonthYear(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    // color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    // color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                    onPressed: _nextMonth,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Calendar Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5B7C99),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Weekday Headers
                  _buildWeekdayHeaders(),
                  const SizedBox(height: 8),
                  // Calendar Grid
                  Expanded(child: _buildCalendarGrid()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Continue Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF5B7C99),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        // Navigate to continue game
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Continue',
                              style: TextStyle(
                                color: Color(0xFF5B7C99),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF5B7C99),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '00:08:42',
                                  style: TextStyle(
                                    color: Color(0xFF5B7C99),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Restart Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        // Restart challenge
                      },
                      child: const Center(
                        child: Text(
                          'Restart',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];

    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildDayCell(day));
    }

    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 4,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(int day) {
    final isCompleted = completedDays.contains(day);
    final isCurrent = day == currentDay;
    final isFuture = day > currentDay;

    return GestureDetector(
      onTap: () {
        if (!isFuture) {
          // Handle day tap - could show that day's challenge
          // print('Tapped day $day');
        }
      },
      child: Container(
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dashed circle for completed days
            if (isCompleted)
              CustomPaint(
                size: const Size(40, 40),
                painter: DashedCirclePainter(),
              ),
            
            // Solid white circle for current day
            if (isCurrent)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            
            // Day number
            Text(
              '$day',
              style: TextStyle(
                color: isCurrent
                    ? const Color(0xFF5B7C99)
                    : isFuture
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white,
                fontSize: 16,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthYear() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[currentMonth.month - 1]} ${currentMonth.year}';
  }
}

// Dashed Circle Painter for completed days
class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    const dashLength = 4.0;
    const gapLength = 4.0;
    const totalCircumference = 3.14159 * 2 * 20; // 2πr
    const totalDashes = totalCircumference / (dashLength + gapLength);

    for (int i = 0; i < totalDashes; i++) {
      final startAngle = (i * (dashLength + gapLength) / radius);
      final sweepAngle = dashLength / radius;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Trophy Painter
class TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Trophy cup - gold color
    paint.color = const Color(0xFFD4AF37);
    
    // Main cup body
    final cupPath = Path();
    cupPath.moveTo(size.width * 0.35, size.height * 0.35);
    cupPath.lineTo(size.width * 0.4, size.height * 0.6);
    cupPath.lineTo(size.width * 0.6, size.height * 0.6);
    cupPath.lineTo(size.width * 0.65, size.height * 0.35);
    cupPath.close();
    canvas.drawPath(cupPath, paint);

    // Left handle
    paint.color = const Color(0xFFD4AF37);
    final leftHandle = Path();
    leftHandle.moveTo(size.width * 0.35, size.height * 0.4);
    leftHandle.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.45,
      size.width * 0.3,
      size.height * 0.5,
    );
    leftHandle.lineTo(size.width * 0.35, size.height * 0.48);
    leftHandle.close();
    canvas.drawPath(leftHandle, paint);

    // Right handle
    final rightHandle = Path();
    rightHandle.moveTo(size.width * 0.65, size.height * 0.4);
    rightHandle.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.45,
      size.width * 0.7,
      size.height * 0.5,
    );
    rightHandle.lineTo(size.width * 0.65, size.height * 0.48);
    rightHandle.close();
    canvas.drawPath(rightHandle, paint);

    // Cup top rim
    paint.color = const Color(0xFFFFD700);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.33,
        size.width * 0.36,
        size.height * 0.04,
      ),
      paint,
    );

    // Base - dark color
    paint.color = const Color(0xFF2C2C2C);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.6,
        size.width * 0.24,
        size.height * 0.08,
      ),
      paint,
    );

    // Bottom base
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.68,
        size.width * 0.3,
        size.height * 0.06,
      ),
      paint,
    );

    // Highlight on cup
    paint.color = const Color(0xFFFFE55C);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.45,
        size.height * 0.38,
        size.width * 0.08,
        size.height * 0.2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}