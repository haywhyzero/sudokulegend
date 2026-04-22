import 'package:flutter/material.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  int currentMonth = 8; // August
  int currentYear = 2025;

  // Days that have dashed circles (completed days)
  final Set<int> completedDays = {2, 4, 12, 13, 14, 15, 17, 25};

  // Today's highlighted day (solid circle)
  final int todayDay = 25;

  String get monthName {
    const months = [
      '',
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
    return months[currentMonth];
  }

  int get daysInMonth => DateTime(currentYear, currentMonth + 1, 0).day;

  int get firstWeekday {
    // 0=Sun, 1=Mon, ..., 6=Sat
    int wd = DateTime(currentYear, currentMonth, 1).weekday;
    return wd % 7; // Flutter: Mon=1..Sun=7 -> convert to Sun=0
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Trophy hero section
            _buildTrophySection(),

            // Calendar card
            Expanded(child: _buildCalendarCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: 22,
            ),
          ),
          const Spacer(),
          const Text(
            'Daily Challenge',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Badge + count
          Row(
            children: [
              _buildBadgeIcon(),
              const SizedBox(width: 4),
              const Text(
                '7/31',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon() {
    return SizedBox(
      width: 26,
      height: 28,
      child: CustomPaint(painter: BadgePainter()),
    );
  }

  Widget _buildTrophySection() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
      ),
      child: Stack(
        children: [Positioned(right: 24, bottom: 0, child: _buildTrophy())],
      ),
    );
  }

  Widget _buildTrophy() {
    return SizedBox(
      width: 130,
      height: 150,
      child: CustomPaint(painter: TrophyPainter()),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3D5A80),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Month navigator
          _buildMonthNavigator(),
          const SizedBox(height: 16),
          // Day headers
          _buildDayHeaders(),
          const SizedBox(height: 8),
          // Calendar grid
          Expanded(child: _buildCalendarGrid()),
          // Buttons
          _buildButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            '$monthName $currentYear',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              if (currentMonth > 1) {
                currentMonth--;
              } else {
                currentMonth = 12;
                currentYear--;
              }
            }),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white70,
              size: 16,
              textDirection: TextDirection.rtl,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if (currentMonth < 12) {
                currentMonth++;
              } else {
                currentMonth = 1;
                currentYear++;
              }
            }),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map(
              (d) => SizedBox(
                width: 44,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(rows, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - firstWeekday + 1;

              if (day < 1 || day > daysInMonth) {
                return const SizedBox(width: 44, height: 44);
              }

              return _buildDayCell(day);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(int day) {
    final isToday = day == todayDay;
    final isCompleted = completedDays.contains(day);

    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: isToday
              ? BoxDecoration(color: Colors.white, shape: BoxShape.circle)
              : null,
          child: isCompleted && !isToday
              ? CustomPaint(
                  painter: DashedCirclePainter(),
                  child: Center(
                    child: Text(
                      '$day',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isToday
                          ? const Color(0xFF3D5A80)
                          : Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Continue button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    color: Color(0xFF3D5A80),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Color(0xFF3D5A80), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '00:08:42',
                      style: TextStyle(
                        color: Color(0xFF3D5A80),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Restart button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                'Restart',
                style: TextStyle(
                  color: Color(0xFF3D5A80),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painters ──────────────────────────────────────────────────────────

class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    const dashCount = 16;
    const dashAngle = 2 * 3.14159 / dashCount;
    const gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
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

class BadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = const Color(0xFFFFB300);
    final darkGold = Paint()..color = const Color(0xFFE65100);

    // Pentagon/shield shape
    final path = Path();
    final cx = size.width / 2;
    path.moveTo(cx, 0);
    path.lineTo(size.width, size.height * 0.35);
    path.lineTo(size.width * 0.82, size.height);
    path.lineTo(size.width * 0.18, size.height);
    path.lineTo(0, size.height * 0.35);
    path.close();

    canvas.drawPath(path, gold);

    // Star in center
    final starPaint = Paint()..color = Colors.white.withOpacity(0.9);
    _drawStar(canvas, Offset(cx, size.height * 0.55), 6, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * 3.14159 / 180;
      final innerAngle = outerAngle + 36 * 3.14159 / 180;
      final outerX = center.dx + radius * cos(outerAngle);
      final outerY = center.dy + radius * sin(outerAngle);
      final innerX = center.dx + (radius * 0.45) * cos(innerAngle);
      final innerY = center.dy + (radius * 0.45) * sin(innerAngle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);

  double _cos(double x) {
    // Taylor approximation
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldLight = const Color(0xFFFFD54F);
    final goldMid = const Color(0xFFFFB300);
    final goldDark = const Color(0xFFE65100);
    final shadow = Colors.black.withOpacity(0.15);

    final w = size.width;
    final h = size.height;

    // ── Cup body ──────────────────────────────────────────────────
    final cupGrad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [goldDark, goldLight, goldMid],
    );

    final cupRect = Rect.fromLTWH(w * 0.22, h * 0.04, w * 0.56, h * 0.52);
    final cupPath = Path()
      ..moveTo(w * 0.22, h * 0.04)
      ..lineTo(w * 0.78, h * 0.04)
      ..lineTo(w * 0.68, h * 0.56)
      ..quadraticBezierTo(w * 0.5, h * 0.65, w * 0.32, h * 0.56)
      ..close();

    canvas.drawPath(
      cupPath,
      Paint()
        ..shader = cupGrad.createShader(cupRect)
        ..style = PaintingStyle.fill,
    );

    // ── Handles ───────────────────────────────────────────────────
    final handlePaint = Paint()
      ..color = goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    // Left handle
    final leftHandlePath = Path()
      ..moveTo(w * 0.24, h * 0.12)
      ..cubicTo(w * 0.02, h * 0.12, w * 0.02, h * 0.44, w * 0.26, h * 0.44);
    canvas.drawPath(leftHandlePath, handlePaint);

    // Right handle
    final rightHandlePath = Path()
      ..moveTo(w * 0.76, h * 0.12)
      ..cubicTo(w * 0.98, h * 0.12, w * 0.98, h * 0.44, w * 0.74, h * 0.44);
    canvas.drawPath(rightHandlePath, handlePaint);

    // ── Stem ──────────────────────────────────────────────────────
    final stemRect = Rect.fromLTWH(w * 0.43, h * 0.62, w * 0.14, h * 0.14);
    canvas.drawRect(stemRect, Paint()..color = goldMid);

    // ── Base ──────────────────────────────────────────────────────
    final basePath = Path()
      ..moveTo(w * 0.28, h * 0.76)
      ..lineTo(w * 0.72, h * 0.76)
      ..lineTo(w * 0.76, h * 0.82)
      ..lineTo(w * 0.24, h * 0.82)
      ..close();

    canvas.drawPath(basePath, Paint()..color = goldDark);

    // Base platform
    final platPath = Path()
      ..moveTo(w * 0.20, h * 0.82)
      ..lineTo(w * 0.80, h * 0.82)
      ..lineTo(w * 0.80, h * 0.90)
      ..lineTo(w * 0.20, h * 0.90)
      ..close();

    final platGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [goldMid, goldDark],
    );
    canvas.drawPath(
      platPath,
      Paint()
        ..shader = platGrad.createShader(
          Rect.fromLTWH(w * 0.20, h * 0.82, w * 0.60, h * 0.08),
        )
        ..style = PaintingStyle.fill,
    );

    // ── Shine on cup ─────────────────────────────────────────────
    final shinePath = Path()
      ..moveTo(w * 0.34, h * 0.08)
      ..lineTo(w * 0.42, h * 0.08)
      ..lineTo(w * 0.38, h * 0.38)
      ..lineTo(w * 0.30, h * 0.38)
      ..close();

    canvas.drawPath(shinePath, Paint()..color = Colors.white.withOpacity(0.25));

    // ── Star highlight ────────────────────────────────────────────
    _drawStar(
      canvas,
      Offset(w * 0.56, h * 0.28),
      w * 0.09,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * 3.14159265 / 180;
      final innerAngle = outerAngle + 36 * 3.14159265 / 180;
      final outerX = center.dx + radius * _cos(outerAngle);
      final outerY = center.dy + radius * _sin(outerAngle);
      final innerX = center.dx + (radius * 0.45) * _cos(innerAngle);
      final innerY = center.dy + (radius * 0.45) * _sin(innerAngle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 12; i++) {
      t *= -x * x / ((2 * i - 1) * (2 * i));
      r += t;
    }
    return r;
  }

  double _sin(double x) {
    double r = x, t = x;
    for (int i = 1; i <= 12; i++) {
      t *= -x * x / ((2 * i) * (2 * i + 1));
      r += t;
    }
    return r;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
