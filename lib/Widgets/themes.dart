import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudokulegend/Models/state%20management/settings_provider.dart';

enum AppTheme { light, dark, system }

// final themeModeProvider = StateProvider<AppTheme>((ref) => AppTheme.system);

class Themes extends ConsumerStatefulWidget {
  const Themes({super.key});

  @override
  ConsumerState<Themes> createState() => _ThemesState();
}

class _ThemesState extends ConsumerState<Themes> {
  @override
  Widget build(BuildContext context) {
    final current = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text("Theme")
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(78, 114, 114, 114)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              _buildThemeTile(
                title: "Light",
                icon: Icons.light_mode_outlined,
                mode: AppTheme.light,
                isSelected: current.theme == AppTheme.light,
                onTap: () {
                  ref.read(settingsProvider.notifier).setTheme(AppTheme.light);
                },
              ),
              Divider(
                color: const Color.fromARGB(78, 114, 114, 114),
                height: 0.5,
                indent: 10,
                endIndent: 10,
              ),
              _buildThemeTile(
                title: "Dark",
                icon: Icons.dark_mode_outlined,
                mode: AppTheme.dark,
                isSelected: current.theme == AppTheme.dark,
                onTap: () {
                  ref.read(settingsProvider.notifier).setTheme(AppTheme.dark);
                },
              ),
              Divider(
                color: const Color.fromARGB(78, 114, 114, 114),
                height: 0.5,
                indent: 10,
                endIndent: 10,
              ),
              _buildThemeTile(
                title: "System",
                icon: Icons.circle_outlined,
                mode: AppTheme.system,
                isSelected: current.theme == AppTheme.system,
                onTap: () {
                  ref.read(settingsProvider.notifier).setTheme(AppTheme.system);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile({
    required String title,
    required IconData icon,
    required AppTheme mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      // leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: isSelected ? Icon(CupertinoIcons.check_mark) : null,
      onTap: onTap,
    );
  }
}

ThemeData darkMode() {
  final kmyDarkColorScheme = ColorScheme.fromSeed(
    seedColor: Color.fromARGB(255, 41, 54, 74),
    brightness: Brightness.dark,
  );
  return ThemeData().copyWith(
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      foregroundColor: kmyDarkColorScheme.copyWith().onPrimaryContainer,
      backgroundColor: kmyDarkColorScheme.copyWith().primaryContainer,
    ),
    scaffoldBackgroundColor: Colors.black,
    iconTheme: IconThemeData().copyWith(color: Colors.white),
    colorScheme: kmyDarkColorScheme,
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.openSans(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: Colors.white54,
      ),
      titleLarge: GoogleFonts.robotoSerif(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white54,
      ),
      titleMedium: GoogleFonts.robotoSerif(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white54,
      ),
      bodyMedium: GoogleFonts.openSans(color: Colors.white54),
      bodySmall: GoogleFonts.openSans(color: Colors.white),
      labelSmall: GoogleFonts.openSans(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kmyDarkColorScheme.onSecondaryContainer,
        foregroundColor: kmyDarkColorScheme.onSecondary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom()),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: kmyDarkColorScheme.copyWith().primary,
      unselectedItemColor: kmyDarkColorScheme.copyWith().secondary,
    ),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: Colors.black),
    cardTheme: CardThemeData(),
    bottomSheetTheme: BottomSheetThemeData(),
    inputDecorationTheme: InputDecorationThemeData(
      prefixIconColor: Colors.white,
      hintStyle: TextStyle(color: Colors.white24),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(color: Colors.black),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateColor.resolveWith(
          (context) => Colors.black,
        ),
      ),
    ),
  );
}
