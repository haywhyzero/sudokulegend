import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sudokulegend/Screens/pages/settings/profile_page.dart';
import 'package:sudokulegend/Screens/pages/sync_data_page.dart';
import 'package:sudokulegend/Widgets/helper.dart';

class ProfileAuthGate extends StatelessWidget {
  const ProfileAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still resolving auth state 
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashLoader();
        }

        // Signed in → show leaderboard
        if (snapshot.hasData && snapshot.data != null) {
          return ProfilePage();
        }

        // Not signed in → show sign-in screen
        return const SyncDataPage();
      },
    );
  }
}