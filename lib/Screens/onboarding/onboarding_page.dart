// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:sudokulegend/Models/storage/shared_preferences.dart';
import 'package:sudokulegend/main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _localStorage = LocalStorage();
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_PageData> pages = [
    _PageData(
      image: 'assets/images/onboarding1.jpeg', 
      text:
          'Step into a world where numbers dance and puzzles come alive! Relax, \nfocus, and enjoy each challenge as you sharpen \nyour mind and master the grid.',
    ),
    _PageData(
      image: 'assets/images/onboarding2.jpeg', 
      text:
          'From its origins to your hands, Sudoku has always inspired thinkers. \nEvery puzzle here is designed to challenge \nand reward your persistence.',
    ),
    _PageData(
      image: 'assets/images/onboarding3.jpeg',
      text:
          'The grid is your battlefield, logic your weapon, \nOutsmart the puzzle, conquer the chaos, \nand claim your victory.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: pages.length,
            itemBuilder: (_, index) {
              final page = pages[index];
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () async {
                          await _localStorage.saveBool("onboarding", true);
                         Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                        );
                        },
                        child: const Text('Skip', style: TextStyle(color: Colors.black54)),
                      ),
                    ),
      
                    const Spacer(flex: 2),

                    Image.asset(
                      page.image,
                      fit: BoxFit.contain,
                    ),
      
                    const Spacer(flex: 2),
                    
                    Text(
                      page.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),
      
                    const Spacer(flex: 3),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == i ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == i ? const Color(0xFF5C6BC0) : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
      
                    const SizedBox(height: 40),
      
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _currentIndex == 0
                              ? null
                              : () => _controller.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  ),
                          child: const Text('Previous', style: TextStyle(color: Colors.black54)),
                        ),
                        if (_currentIndex == pages.length - 1)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C6BC0),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () async {
                              await _localStorage.saveBool("onboarding", true);
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const MainScreen()),
                                );
                            },
                            child: Text('Get Started',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                          else
                            TextButton(onPressed: () {
                               _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                            }, child: Text('Next'))
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final String image;
  final String text;
  _PageData({required this.image, required this.text});
}