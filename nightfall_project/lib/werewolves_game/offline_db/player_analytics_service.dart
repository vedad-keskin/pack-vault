import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameRecord {
  final int roleId;
  final String roleName;
  final int allianceId;
  final String winningTeam;
  final bool won;
  final int pointsEarned;
  final DateTime playedAt;

  GameRecord({
    required this.roleId,
    required this.roleName,
    required this.allianceId,
    required this.winningTeam,
    required this.won,
    required this.pointsEarned,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
    'roleId': roleId,
    'roleName': roleName,
    'allianceId': allianceId,
    'winningTeam': winningTeam,
    'won': won,
    'pointsEarned': pointsEarned,
    'playedAt': playedAt.toIso8601String(),
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      roleId: json['roleId'] as int,
      roleName: json['roleName'] as String,
      allianceId: json['allianceId'] as int,
      winningTeam: json['winningTeam'] as String,
      won: json['won'] as bool,
      pointsEarned: json['pointsEarned'] as int,
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }
}

class PlayerAnalyticsService {
  static const String _storageKey = 'werewolf_player_analytics';

  Future<Map<String, List<GameRecord>>> loadAllAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_storageKey);
    if (json == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((playerId, records) {
        final list = (records as List<dynamic>)
            .map((r) => GameRecord.fromJson(r as Map<String, dynamic>))
            .toList();
        return MapEntry(playerId, list);
      });
    } catch (_) {
      return {};
    }
  }

  Future<List<GameRecord>> loadPlayerAnalytics(String playerId) async {
    final all = await loadAllAnalytics();
    return all[playerId] ?? [];
  }

  Future<void> recordGame(Map<String, GameRecord> playerRecords) async {
    final all = await loadAllAnalytics();

    for (final entry in playerRecords.entries) {
      final playerId = entry.key;
      final record = entry.value;
      all.putIfAbsent(playerId, () => []);
      all[playerId]!.add(record);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      all.map((k, v) => MapEntry(k, v.map((r) => r.toJson()).toList())),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clearAllAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
