import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sudokulegend/Models/data/difficulty_level.dart';
import 'package:sudokulegend/Models/state%20management/game_persistent.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:sudokulegend/Screens/pages/game/game_page.dart';

class Difficulties extends ConsumerStatefulWidget {
  final List<DifficultyLevel> arraydiff;
  const Difficulties({super.key, required this.arraydiff});

  @override
  ConsumerState<Difficulties> createState() => _DifficultiesState();

}
class _DifficultiesState extends ConsumerState<Difficulties> {

  String selected = "Medium";
  bool _isloading = false;

  @override
  void initState() {
    super.initState();
      // Auto-select the highest unlocked if nothing selected yet
  if (widget.arraydiff.any((l) => l.name == selected)) {
    selected = widget.arraydiff.lastWhere((l) => !l.isLocked, orElse: () => widget.arraydiff[2]).name;
  }
  }

  Future<void> _newGame(String levelName) async { // Accept levelName
    setState(() => _isloading = true,);
    try {
      // 1. Get the next available slot number for the *new* game we are about to start
      final newGameSlotNo = await SudokuStorageService.instance.getAndIncrementGameSlotNumber();

      // 2. Check if there's an active game currently in progress
      final activeGameData = await SudokuStorageService.instance.loadActiveGame();
      if (activeGameData != null) {
        // 3. If an active game exists, save it to its designated slot number
        final previousGameSlotNo = activeGameData['slotNo'];
        if (previousGameSlotNo != null) {
          await SudokuStorageService.instance.saveGame(
            data: activeGameData,
            slot: "slot_$previousGameSlotNo", // Save the previously active game to its slot
          );
        }
        // 4. Clear the active game, as a new one is starting
        await SudokuStorageService.instance.deleteActiveGame();
        // 5. Also clear the Riverpod state for the active game
        ref.read(saveGameProvider.notifier).state = {};
      }

      // 6. Pop the modal sheet
      if (mounted) Navigator.pop(context);

      // 7. Navigate to GamePage with the new game's level and assigned slot number
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => GamePage(level: levelName, isContd: false, slotNo: newGameSlotNo),
        ));
      }
    } catch (e) {
      if (mounted) { // Check mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
      }
    } finally {
      setState(() => _isloading = false); // Ensure loading state is reset
    }

    
  }

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Text(
              "New Game",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),

            // Difficulty list
            Expanded(
              child: ListView.builder(
                itemCount: widget.arraydiff.length,
                itemBuilder: (context, index) {
                  final level = widget.arraydiff[index];
                  final isSelected = level.name == selected;
                  final isLocked = level.isLocked;
                  final isGrid16 = level.name == '16x16';


                  return InkWell(
                    onTap: isLocked ? null : () async { setState(
                      () => selected = level.name
                      );
                     await _newGame(level.name); // Pass level name
                      },                                  
                    child: Opacity(
                      opacity: isLocked ? 0.45 : 1.0,   // greyed out
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: index == widget.arraydiff.length - 1
                                ? BorderSide.none
                                : BorderSide(color: Colors.grey.shade300, width: 0.8),
                          ),
                        ),
                        child: Column(  
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLocked)
                                  const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6,),
                                if (isSelected && !isLocked && _isloading)
                                  const Text("Loading...", style: TextStyle(color: Color(0xFF53698A), fontStyle: FontStyle.italic),)
                                else
                                  Text(
                                    level.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.blue[700]
                                          : (isLocked ? Colors.grey[600] : Theme.of(context).textTheme.bodyMedium!.color),
                                    ),
                                  )
                                
                                  
                              ],
                            ),
                            if (isLocked && isGrid16) ...[
                              const SizedBox(height: 6),
                              Text(
                                "feature is coming soon...",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (isLocked) ...[
                              const SizedBox(height: 6),
                              Text(
                                "Complete ${level.gamesRequiredToUnlock} ${index > 0 ? widget.arraydiff[index - 1].name : 'Hard'} games to unlock",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      );
  }
}