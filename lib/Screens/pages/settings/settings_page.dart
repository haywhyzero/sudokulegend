// ignore_for_file: use_build_context_synchronously

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudokulegend/Models/state%20management/game_persistent.dart';
import 'package:sudokulegend/Models/state%20management/settings_provider.dart';
import 'package:sudokulegend/Models/storage/sudoku_storage_service.dart';
import 'package:sudokulegend/Screens/pages/settings/how_to_play.dart';
import 'package:sudokulegend/Screens/pages/settings/profile.dart';
// import 'package:sudokulegend/Screens/pages/settings/profile_page.dart';
import 'package:sudokulegend/Widgets/svg_icon.dart';
import 'package:sudokulegend/Widgets/themes.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool isloading = false;

  void deleteData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ref.read(saveGameProvider).clear();
    ref.read(saveGameProvider.notifier).state = {};
    await SudokuStorageService.instance.deleteActiveGame();
    setState(() {
      isloading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You have successfully deleted all your data!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Reset Data'),
            content: isloading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    ],
                  )
                : const Text(
                    'Are you sure you want to delete all data? This action cannot be undone.',
                  ),
            actions: isloading
                ? []
                : [
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          isloading = true;
                        });
                        deleteData();
                        Navigator.pop(context);
                      },
                      child: Text('Yes'),
                    ),

                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(),
                      child: Text('No'),
                    ),
                  ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final color = Theme.of(context).brightness == Brightness.light
            ? Colors.black87
            : Colors.white54;
    final mode = switch (settings.theme) {
      AppTheme.light => Icon(
        Icons.light_mode_outlined,
        color: color,
      ),
      AppTheme.dark => Icon(
        Icons.dark_mode_outlined,
        color: color,
      ),
      AppTheme.system => Svgicon(
        assetName: "Theme",
      ),
    };
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Profile Section
          _buildProfileTile(),
          const SizedBox(height: 8),
          // How To Play
          _buildNavigationTile(
            icon: Image.asset('assets/icons/howtoplay.png', width: 22, height: 22,),
            title: 'How To Play',
            subtitle: 'Learn the rules and basics of Sudoku',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HowToPlay()),
              );
            },
          ),
          const SizedBox(height: 8),
          // Vibrate
          _buildSwitchTile(
            icon: Svgicon(assetName: "Vibrate"),
            title: 'Vibrate',
            value: settings.vibrationEnabled,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleVibrate(val);
            }),
          ),
          // Sound Effect
          _buildSwitchTile(
            icon: Svgicon(assetName: "Sound"),
            title: 'Sound Effect',
            value: settings.soundEnabled,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleSound(val);
            }),
          ),
          // Themes
          _buildThemeTile(currentTheme: settings.theme.name, icon: mode),
          // Notification
          _buildSwitchTile(
            icon: Svgicon(assetName: "Notification"),
            title: 'Notification',
            value: settings.notification,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleNotification(val);
            }),
          ),
          // Timer
          _buildSwitchTile(
            icon: Svgicon(assetName: "Time"),
            title: 'Timer',
            value: settings.timer,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleTimer(val);
            }),
          ),
          // Smart Hint
          _buildSwitchTile(
            icon: Svgicon(assetName: "Hint"),
            title: 'Smart Hint',
            subtitle: 'Shows the next best move using logic',
            value: settings.smartHint,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleSmartHint(val);
            }),
          ),
          // Mistake Limit
          _buildSwitchTile(
            icon: Svgicon(assetName: "mistakes"),
            title: 'Mistakes',
            subtitle: '3 mistakes allowed',
            value: settings.mistakes,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleMistakes(val);
            }),
          ),
          // Score
          _buildSwitchTile(
            icon: Svgicon(assetName: "score"),
            title: 'Score',
            subtitle: 'Display total points',
            value: settings.score,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleScore(val);
            }),
          ),
          // Highlight Same Number
          _buildSwitchTile(
            icon: Svgicon(assetName: "highlightsameno"),
            title: 'Highlight Same Number',
            subtitle: 'Highlight all cells with the same number',
            value: settings.highlightSameNo,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleHighlightSameNo(val);
            }),
          ),
          // Region Highlight
          _buildSwitchTile(
            icon: Image.asset('assets/icons/region.png', width: 22, height: 22, color: color),
            title: 'Region Highlight',
            subtitle: 'Highlight the selected row, column and box',
            value: settings.highlightRegion,
            onChanged: (val) => setState(() {
              ref.read(settingsProvider.notifier).toggleHighlightRegion(val);
            }),
          ),
          const SizedBox(height: 8),
          // Delete Account
          _buildNavigationTile(
            icon: Svgicon(assetName: "Delete"),
            title: 'Reset Data',
            onTap: showResetDialog,
          ),
          const SizedBox(height: 8),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListTile(
              leading: Svgicon(assetName: "Logout", color: Colors.red,),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 32),
          // Version and Links
          Center(
            child: Column(
              children: [
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                    const Text(
                      '  |  ',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Terms of Service',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileTile() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.green[100],
          child: Image.asset(
            'assets/images/403024_avatar_boy_male_user_young_icon.png',
          ),
        ),
        title: const Text(
          'Dahak',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'ajaydaniel@gmail.com',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ProfilePage()));
        },
      ),
    );
  }

  Widget _buildNavigationTile({
    required Widget icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required Widget icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SwitchListTile(
        secondary:  icon,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildThemeTile({required String currentTheme, required Widget icon}) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        leading: icon,
        title: const Text(
          'Themes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentTheme,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () {
          // Show theme picker
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => Themes()));
        },
      ),
    );
  }
}
