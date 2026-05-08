import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WerewolfPlayer {
  final String id;
  final String name;
  final int points;

  WerewolfPlayer({required this.id, required this.name, this.points = 0});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'points': points};

  factory WerewolfPlayer.fromJson(Map<String, dynamic> json) {
    return WerewolfPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      points: (json['points'] as int?) ?? 0,
    );
  }
}

class WerewolfPlayerService {
  static const String _storageKey = 'werewolf_players';

  Future<List<WerewolfPlayer>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playersJson = prefs.getString(_storageKey);

    if (playersJson == null) {
      // Initialize default
      return _saveDefaultPlayer();
    }

    try {
      final List<dynamic> decoded = jsonDecode(playersJson);
      final List<WerewolfPlayer> players = decoded
          .map((json) => WerewolfPlayer.fromJson(json))
          .toList();

      if (players.isEmpty) {
        return _saveDefaultPlayer();
      }

      return players;
    } catch (e) {
      return _saveDefaultPlayer();
    }
  }

  Future<List<WerewolfPlayer>> _saveDefaultPlayer() async {
    final defaultPlayer = WerewolfPlayer(id: '1', name: 'Vedo', points: 0);
    await savePlayers([defaultPlayer]);
    return [defaultPlayer];
  }

  Future<void> savePlayers(List<WerewolfPlayer> players) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(players.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<List<WerewolfPlayer>> addPlayer(
    List<WerewolfPlayer> currentPlayers,
    String name,
  ) async {
    final newPlayer = WerewolfPlayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      points: 0,
    );
    final updatedList = [...currentPlayers, newPlayer];
    await savePlayers(updatedList);
    return updatedList;
  }

  Future<List<WerewolfPlayer>> removePlayer(
    List<WerewolfPlayer> currentPlayers,
    String id,
  ) async {
    if (currentPlayers.length <= 1) {
      throw Exception('Cannot remove the last player');
    }
    final updatedList = currentPlayers.where((p) => p.id != id).toList();
    await savePlayers(updatedList);
    return updatedList;
  }

  Future<List<WerewolfPlayer>> updatePlayer(
    List<WerewolfPlayer> currentPlayers,
    String id,
    String newName,
  ) async {
    final updatedList = currentPlayers.map((p) {
      if (p.id == id) {
        return WerewolfPlayer(id: id, name: newName, points: p.points);
      }
      return p;
    }).toList();
    await savePlayers(updatedList);
    return updatedList;
  }

  Future<List<WerewolfPlayer>> resetPlayersPoints(
    List<WerewolfPlayer> currentPlayers,
  ) async {
    final updatedList = currentPlayers
        .map((p) => WerewolfPlayer(id: p.id, name: p.name, points: 0))
        .toList();
    await savePlayers(updatedList);
    return updatedList;
  }
}
