import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudokulegend/Models/storage/shared_preferences.dart';
import 'package:sudokulegend/Screens/onboarding/onboarding_page.dart';
import 'package:sudokulegend/main.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<Widget> _selectNextScreen() async {
    final localStorage = LocalStorage();
    final hasOnboarded = await localStorage.getBool("onboarding") ?? false;
    if (hasOnboarded) {
      return const MainScreen();
    } else {
      return const OnboardingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen.withScreenFunction(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 130,
            height: 130,
          ),
          Text(
            "SUDOKU LEGEND",
            style: GoogleFonts.openSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 4,
              height: 1,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF53698A),
      screenFunction: _selectNextScreen,
      splashIconSize: 250,
      duration: 3000,
      splashTransition: SplashTransition.fadeTransition,
      animationDuration: const Duration(milliseconds: 2500),
    );
  }
}
