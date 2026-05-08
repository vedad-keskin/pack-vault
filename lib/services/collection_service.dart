import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';

/// Manages the user's sticker collection state and syncs with Firebase.
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

  /// Start listening to card collection changes for the given user.
  void startListening(String uid) {
    _uid = uid;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _datasource.watchUserCards(uid).listen(
      (cards) {
        _cards = cards;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Collection stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Toggle a card's collected state. Optimistic update.
  Future<void> toggleCard(int cardId) async {
    if (_uid == null) return;

    final newState = !(_cards[cardId] ?? false);

    // Optimistic: update UI immediately
    _cards[cardId] = newState;
    notifyListeners();

    // Sync to Firebase in background
    try {
      await _datasource.updateCard(_uid!, cardId, newState);
    } catch (e) {
      // Revert on failure
      _cards[cardId] = !newState;
      notifyListeners();
      debugPrint('Toggle card error: $e');
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
