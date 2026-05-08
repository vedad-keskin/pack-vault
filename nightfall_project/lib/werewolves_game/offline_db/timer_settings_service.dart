import 'package:shared_preferences/shared_preferences.dart';

class TimerSettingsService {
  static const String _timerModeKey = 'werewolf_timer_mode';
  static const String defaultMode = 'fiveMinutes';

  /// Get the saved timer mode
  Future<String> getTimerMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_timerModeKey) ?? defaultMode;
  }

  /// Save timer mode
  Future<void> setTimerMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timerModeKey, mode);
  }
}
