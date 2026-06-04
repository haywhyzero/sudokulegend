import 'package:flutter_riverpod/legacy.dart';
import 'package:sudokulegend/Models/badge_service.dart';

final allBadgesProvider = StateProvider<String>((ref) => '');
final setReminderProvider = StateProvider<String>((ref) => '');
final saveGameProvider = StateProvider<Map<String, dynamic>>((ref) => {},);
final saveCompletedGameProvider = StateProvider<Map<String, dynamic>>((ref) => {},);
final unlockedBadgesProvider = StateProvider<List<Badge>>((ref) => []);
final isPermissionProvider = StateProvider<bool>((ref) => false);
