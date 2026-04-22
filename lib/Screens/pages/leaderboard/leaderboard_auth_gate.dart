import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sudokulegend/Screens/pages/leaderboard/leaderboard.dart';
import 'package:sudokulegend/Screens/pages/leaderboard/sync_data_page.dart';

class LeaderboardAuthGate extends StatelessWidget {
  const LeaderboardAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still resolving auth state 
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        // Signed in → show leaderboard
        if (snapshot.hasData && snapshot.data != null) {
          return LeaderboardPage();
        }

        // Not signed in → show sign-in screen
        return const SyncDataPage();
      },
    );
  }
}


// ignore: unused_element
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

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


class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

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

