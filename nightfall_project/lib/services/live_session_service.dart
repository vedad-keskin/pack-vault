import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/player_analytics_service.dart';

class LiveSessionService extends ChangeNotifier {
  static const String _prefsKey = 'live_session_code';

  String? _sessionCode;
  bool _isSyncing = false;

  String? get sessionCode => _sessionCode;
  bool get isSyncing => _isSyncing;
  bool get hasSession => _sessionCode != null;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> loadExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCode = prefs.getString(_prefsKey);
    notifyListeners();
  }

  Future<String> createSession() async {
    final code = await _generateUniqueCode();
    _sessionCode = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);

    await _db.child('sessions/$code').set({
      'createdAt': ServerValue.timestamp,
      'ownerUid': _uid,
    });

    notifyListeners();
    return code;
  }

  Future<void> syncLeaderboard(
    List<WerewolfPlayer> players,
    Map<String, List<GameRecord>> analytics,
  ) async {
    if (_sessionCode == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final Map<String, dynamic> playersData = {};
      for (final player in players) {
        final playerAnalytics = analytics[player.id] ?? [];
        playersData[player.id] = {
          'name': player.name,
          'points': player.points,
          'analytics': playerAnalytics.map((r) => r.toJson()).toList(),
        };
      }

      await _db.child('sessions/$_sessionCode/players').set(playersData);
    } catch (e) {
      debugPrint('LiveSession sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession() async {
    if (_sessionCode != null) {
      try {
        await _db.child('sessions/$_sessionCode').remove();
      } catch (e) {
        debugPrint('LiveSession delete error: $e');
      }
    }

    _sessionCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rng = Random.secure();

    for (int attempt = 0; attempt < 10; attempt++) {
      final code = List.generate(
        6,
        (_) => chars[rng.nextInt(chars.length)],
      ).join();

      final snapshot = await _db.child('sessions/$code').get();
      if (!snapshot.exists) return code;
    }

    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
