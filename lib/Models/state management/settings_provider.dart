import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudokulegend/Widgets/themes.dart';

// Model class
class GameSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notification;
  final bool timer;
  final bool smartHint;
  final bool mistakes;
  final bool score;
  final bool highlightSameNo;
  final bool highlightRegion;
  final AppTheme theme;

  const GameSettings({
    this.soundEnabled = false,
    this.vibrationEnabled = false,
    this.notification = true,
    this.timer = true,
    this.smartHint = true,
    this.mistakes = true,
    this.score = true,
    this.highlightSameNo = false,
    this.highlightRegion = false,
    this.theme = AppTheme.system,
  });

  GameSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notification,
    bool? timer,
    bool? smartHint,
    bool? mistakes,
    bool? score,
    bool? highlightSameNo,
    bool? highlightRegion,
    AppTheme? theme,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notification: notification ?? this.notification,
      timer: timer ?? this.timer,
      smartHint: smartHint ?? this.smartHint,
      mistakes: mistakes ?? this.mistakes,
      score: score ?? this.score,
      highlightSameNo: highlightSameNo ?? this.highlightSameNo,
      highlightRegion: highlightRegion ?? this.highlightRegion,
      theme: theme ?? this.theme,
    );
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    soundEnabled: json['soundEnabled'] ?? false,
    vibrationEnabled: json['vibrationEnabled'] ?? false,
    notification: json['notification'] ?? true,
    timer: json['timer'] ?? true,
    smartHint: json['smartHint'] ?? true,
    mistakes: json['mistakes'] ?? true,
    score: json['score'] ?? true,
    highlightSameNo: json['highlightSameNo'] ?? false,
    highlightRegion: json['highlightRegion'] ?? false,
    theme: json['theme'] != null 
        ? AppTheme.values[json['theme'] as int] 
        : AppTheme.system,
  );

  Map<String, dynamic> toJson() => {
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'notification': notification,
    'timer': timer,
    'smartHint': smartHint,
    'mistakes': mistakes,
    'score': score,
    'highlightSameNo': highlightSameNo,
    'highlightRegion': highlightRegion,
    'theme': theme.index
  };
}

// Notifier class
class SettingsNotifier extends Notifier<GameSettings> {
  final GameSettings? _initialSettings;
  SettingsNotifier([this._initialSettings]);

  static const String _key = "game_settings";
  @override
  GameSettings build() {
    if (_initialSettings == null) _loadSettings();

    listenSelf((previous, next) {
      if (previous != next) {
        _saveSettings(next);
      }
    });

    return _initialSettings ?? const GameSettings();
  }


  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      state = GameSettings.fromJson(json);
    }
  }

  Future<void> _saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(settings.toJson());
    await prefs.setString(_key, json);
  }

  void toggleSound(bool val) {
    state = state.copyWith(soundEnabled: val);
  }

  void toggleVibrate(bool val) {
    state = state.copyWith(vibrationEnabled: val);
  }

 void toggleNotification(bool val) {
    state = state.copyWith(notification: val);
  }

 void toggleTimer(bool val) {
    state = state.copyWith(timer: val);
  }

 void toggleSmartHint(bool val) {
    state = state.copyWith(smartHint: val);
  }

 void toggleMistakes(bool val) {
    state = state.copyWith(mistakes: val);
  }

 void toggleScore(bool val) {
    state = state.copyWith(score: val);
  }

 void toggleHighlightSameNo(bool val) {
    state = state.copyWith(highlightSameNo: val);
  }

 void toggleHighlightRegion(bool val) {
    state = state.copyWith(highlightRegion: val);
  }

 void setTheme(AppTheme val) {
  state = state.copyWith(theme: val);
 }

   

}

final settingsProvider = NotifierProvider<SettingsNotifier, GameSettings>(
  () => SettingsNotifier(),
);
