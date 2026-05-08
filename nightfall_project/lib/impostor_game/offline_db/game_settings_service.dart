import 'package:shared_preferences/shared_preferences.dart';

class GameSettingsService {
  static const String _hintsEnabledKey = 'impostor_hints_enabled';

  /// Loads the hints setting. Defaults to `true` (ON) if not set.
  Future<bool> loadHintsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hintsEnabledKey) ?? true;
  }

  /// Saves the hints setting.
  Future<void> saveHintsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintsEnabledKey, enabled);
  }
}
