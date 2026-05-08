import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WerewolfGameSettingsService {
  static const String _rolesKey = 'werewolf_selected_roles';
  static const String _playerCountKey = 'werewolf_last_player_count';

  Future<void> saveSelectedRoles(Map<int, int> roles, int playerCount) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert Map<int, int> to Map<String, int> for JSON encoding
    final stringMap = roles.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_rolesKey, jsonEncode(stringMap));
    await prefs.setInt(_playerCountKey, playerCount);
  }

  Future<Map<int, int>?> loadSelectedRoles(int currentPlayerCount) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt(_playerCountKey);

    // Only return saved selection if player count matches
    if (savedCount != currentPlayerCount) return null;

    final String? rolesJson = prefs.getString(_rolesKey);
    if (rolesJson == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(rolesJson);
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (e) {
      return null;
    }
  }
}
