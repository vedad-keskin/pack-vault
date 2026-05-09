import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';

/// Manages the user's sticker collection. Firebase is the source of truth.
///
/// Flow:
///   1. On startListening: load from SharedPreferences cache instantly → show UI
///   2. Subscribe to Firebase stream → replace local state with Firebase data
///   3. On toggleCard: update UI optimistically + push to Firebase
///   4. Firebase RTDB disk persistence handles offline write queueing
class CollectionService extends ChangeNotifier {
  final FirebaseDatasource _datasource = FirebaseDatasource();

  Map<int, bool> _cards = {};
  bool _isLoading = true;
  String? _uid;
  StreamSubscription? _subscription;

  Map<int, bool> get cards => _cards;
  bool get isLoading => _isLoading;
  int get collectedCount => _cards.values.where((v) => v).length;
  int get totalCards => 432;
  double get progress => totalCards > 0 ? collectedCount / totalCards : 0;

  bool isCollected(int cardId) => _cards[cardId] ?? false;

  // === Local Storage Keys ===
  static String _cardsKey(String uid) => 'cards_$uid';

  /// Load cards from SharedPreferences cache for instant startup display.
  /// This is only a fast-start cache; Firebase data replaces it once it arrives.
  Future<void> _loadFromLocal(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cardsKey(uid));
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        _cards = decoded.map((k, v) => MapEntry(int.parse(k), v == true));
        _isLoading = false;
        notifyListeners();
        debugPrint('Loaded ${_cards.values.where((v) => v).length} cards from local cache');
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
  /// Loads local cache first for instant display, then Firebase replaces it.
  void startListening(String uid) {
    if (_uid == uid && !_isLoading) return; // Already listening to this user

    _uid = uid;
    _isLoading = true;
    notifyListeners();

    // Step 1: Load from local cache for instant UI
    _loadFromLocal(uid).then((_) {
      // Step 2: Subscribe to Firebase — it is the source of truth
      _subscription?.cancel();
      _subscription = _datasource.watchUserCards(uid).listen(
        (firebaseCards) {
          if (firebaseCards.isNotEmpty) {
            // Firebase is source of truth — always accept its data.
            // This ensures changes from other devices are picked up.
            _cards = firebaseCards;
            _saveToLocal();
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

  /// Toggle a card's collected state. Updates UI optimistically,
  /// then pushes to Firebase (queued automatically if offline).
  Future<void> toggleCard(int cardId) async {
    if (_uid == null) return;

    final newState = !(_cards[cardId] ?? false);

    // Optimistic UI update + local cache
    _cards[cardId] = newState;
    notifyListeners();
    _saveToLocal();

    // Push to Firebase (RTDB persistence queues if offline)
    try {
      await _datasource.updateCard(_uid!, cardId, newState);
    } catch (e) {
      // Don't revert UI — Firebase RTDB persistence will retry automatically.
      debugPrint('Firebase sync error (will retry): $e');
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
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
