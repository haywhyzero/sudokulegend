import 'package:flutter/material.dart';

class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play', style: TextStyle(
          fontWeight: FontWeight.w500
        ),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GOAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sudoku is a logic-based number placement puzzle. The objective is to fill a 9x9 grid with digits so that each column, each row, and each of the nine 3x3 subgrids contain all of the digits from 1 to 9, without repeating any numbers within the same row, column, or subgrid.',
                style: TextStyle(fontSize: 14),
              ),
              Divider(height: 32, color: Colors.grey[300]),
              const Text(
                'RULES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Each number 1-9 must appear:.\n'
                ' • Once in each row.\n'
                ' • Once in each column.\n'
                ' • Once in each of the nine 3x3 subgrids.\n'
                'Some numbers are pre-filled - you cannot change them.\n'
                'Use logic and deduction - no guessing required!',
                style: TextStyle(fontSize: 14),
              ),
              Divider(height: 32, color: Colors.grey[300]),
              const Text(
                'CONTROLS:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Tap on a cell to select it.\n'
                '• Choose a number from the keypad to fill the selected cell.\n'
                '• Use pencil mode to write small notes in cells for possible numbers.\n'
                'Use Erase to clear a cell.\n'
                '• Use Undo to take back your last move.',
                style: TextStyle(fontSize: 14),
              ),
              Divider(height: 32, color: Colors.grey[300]),
              const Text(
                'TIPS:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Start with the rows, columns, or subgrids that have the most numbers filled in.\n'
                '• Look for numbers that can only be placed in one specific cell within a row, column, or subgrid.\n'
                '• Use pencil marks to note possible numbers for empty cells.\n'
                '• Stay patient and persistent - with practice, patterns become easier to find.',
                style: TextStyle(fontSize: 14),
              ),
              Divider(height: 32, color: Colors.grey[300]),
              const Text(
                'FEATURES:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Hints: Get help when you are stuck.\n'
                '• Pencil mode: Write small notes in cells for possible numbers.\n'
                ,
                style: TextStyle(fontSize: 14),
              ),
              Divider(height: 32, color: Colors.grey[300]),
              const Text(
                'WINNING:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• You win when all cells are filled correctly.\n',
                style: TextStyle(fontSize: 14),
              ),
              // Divider(height: 32, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}