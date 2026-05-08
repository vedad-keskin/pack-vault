import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';

/// Manages the user's sticker collection with offline-first local storage.
///
/// Flow:
///   1. On startListening: load from SharedPreferences instantly → show UI
///   2. Subscribe to Firebase stream → merge incoming data
///   3. On toggleCard: update SharedPreferences immediately + try Firebase
///   4. When internet resumes: Firebase persistence auto-syncs
class CollectionService extends ChangeNotifier {
  final FirebaseDatasource _datasource = FirebaseDatasource();

  Map<int, bool> _cards = {};
  bool _isLoading = true;
  String? _uid;
  StreamSubscription? _subscription;
  bool _localLoaded = false;

  Map<int, bool> get cards => _cards;
  bool get isLoading => _isLoading;
  int get collectedCount => _cards.values.where((v) => v).length;
  int get totalCards => 432;
  double get progress => totalCards > 0 ? collectedCount / totalCards : 0;

  bool isCollected(int cardId) => _cards[cardId] ?? false;

  // === Local Storage Keys ===
  static String _cardsKey(String uid) => 'cards_$uid';

  /// Load cards from SharedPreferences for instant offline display.
  Future<void> _loadFromLocal(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cardsKey(uid));
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        _cards = decoded.map((k, v) => MapEntry(int.parse(k), v == true));
        _localLoaded = true;
        _isLoading = false;
        notifyListeners();
        debugPrint('Loaded ${_cards.values.where((v) => v).length} collected cards from local storage');
      }
    } catch (e) {
      debugPrint('Local load error: $e');
    }
  }

  /// Save current card state to SharedPreferences.
  Future<void> _saveToLocal() async {
    if (_uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> encoded = _cards.map(
        (k, v) => MapEntry(k.toString(), v),
      );
      await prefs.setString(_cardsKey(_uid!), json.encode(encoded));
    } catch (e) {
      debugPrint('Local save error: $e');
    }
  }

  /// Start listening to card collection changes for the given user.
  /// Loads local data first for instant display, then syncs with Firebase.
  void startListening(String uid) {
    if (_uid == uid && !_isLoading) return; // Already listening to this user

    _uid = uid;
    _isLoading = true;
    _localLoaded = false;
    notifyListeners();

    // Step 1: Load from local storage immediately
    _loadFromLocal(uid).then((_) {
      // Step 2: Subscribe to Firebase for real-time sync
      _subscription?.cancel();
      _subscription = _datasource.watchUserCards(uid).listen(
        (firebaseCards) {
          if (firebaseCards.isNotEmpty) {
            if (_localLoaded && _cards.isNotEmpty) {
              // Merge: local wins for any cards the user toggled offline
              // But accept Firebase data for cards not in local
              bool hasChanges = false;
              for (final entry in firebaseCards.entries) {
                if (!_cards.containsKey(entry.key)) {
                  _cards[entry.key] = entry.value;
                  hasChanges = true;
                }
              }
              if (hasChanges) _saveToLocal();
            } else {
              // First load from Firebase: accept all data
              _cards = firebaseCards;
              _saveToLocal();
            }
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Collection stream error: $e');
          _isLoading = false;
          notifyListeners();
        },
      );
    });
  }

  /// Toggle a card's collected state. Updates local storage immediately,
  /// then syncs to Firebase in background.
  Future<void> toggleCard(int cardId) async {
    if (_uid == null) return;

    final newState = !(_cards[cardId] ?? false);

    // Optimistic: update UI + local storage immediately
    _cards[cardId] = newState;
    notifyListeners();
    _saveToLocal();

    // Sync to Firebase in background (will queue if offline)
    try {
      await _datasource.updateCard(_uid!, cardId, newState);
    } catch (e) {
      // Don't revert — local is source of truth.
      // Firebase will sync when connection resumes.
      debugPrint('Firebase sync error (will retry): $e');
    }
  }

  /// Push all local data to Firebase. Call when connectivity resumes.
  Future<void> syncToFirebase() async {
    if (_uid == null || _cards.isEmpty) return;
    try {
      await _datasource.pushAllCards(_uid!, _cards);
      debugPrint('Synced ${_cards.values.where((v) => v).length} cards to Firebase');
    } catch (e) {
      debugPrint('Full sync error: $e');
    }
  }

  /// Get collected count for a specific country's cards.
  int collectedForCountry(List<int> cardIds) {
    return cardIds.where((id) => _cards[id] == true).length;
  }

  /// Stop listening when user logs out.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _cards = {};
    _uid = null;
    _isLoading = true;
    _localLoaded = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
