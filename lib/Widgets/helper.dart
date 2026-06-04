import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class SplashLoader extends StatelessWidget {
  const SplashLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F6FB),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3D5A80),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}



String formatTime(int seconds) {
    final int hours = (seconds ~/ 3600);
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final h = hours > 0 ? '$hours:' : '';
    return "$h$m:$s";
}



Widget buildBadgeItem(String title, String subtitle, bool unlocked) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: unlocked ? Border.all(color: const Color(0xFFFFB300), width: 1.5) : null,
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Image.asset("assets/images/trophy.png"),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
}

// Snackbar
void showSnackBar({
  required BuildContext context,
  required String message,
  Color? bgColor,
  bool persist = false,
  bool showCloseIcon = false,
  Color? fgColor,
}) {
   ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(color: fgColor),
            ),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            persist: persist,
            showCloseIcon: showCloseIcon,
          ),
        );
}

// Flutter Toast
// Widget showToast() {
//   return Toast
// };




