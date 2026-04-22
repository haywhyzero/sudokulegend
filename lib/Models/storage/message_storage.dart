import 'package:shared_preferences/shared_preferences.dart';

class MessageStorage {
  // final String key;

  // const MessageStorage({required this.key});

  // Save a new message
   Future<void> saveMessage(String message, String key) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = prefs.getStringList(key) ?? [];

    messages.insert(0, message); // add to top
    if (messages.length > 100) messages.removeLast(); // keep only last 10
    await prefs.setStringList(key, messages);
  }

  // Get all messages
  Future<List<String>> getMessages(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  // Clear all history
  Future<void> clearMessages(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
