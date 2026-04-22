
import 'package:flutter_riverpod/legacy.dart';



final setReminderProvider = StateProvider<String>((ref) => '');
final saveGameProvider = StateProvider<Map<String, dynamic>>((ref) => {},);
final saveCompletedGameProvider = StateProvider<Map<String, dynamic>>((ref) => {},);
final themeProvider = StateProvider<String>((ref) => '');
final notificationProvider = StateProvider<bool>((ref) => false);
final timerProvider = StateProvider<bool>((ref) => true,);
final smartHintProvider = StateProvider<bool>((ref) => true,);
final mistakesProvider = StateProvider<bool>((ref) => true,);
final scoreProvider = StateProvider<bool>((ref) => true,);
final highlightSameNoProvider = StateProvider<bool>((ref) => false,);
final highlightRegionProvider = StateProvider<bool>((ref) => false,);