import 'package:firebase_database/firebase_database.dart';

/// Raw Firebase Realtime Database CRUD operations.
class FirebaseDatasource {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static bool _persistenceEnabled = false;

  /// Enable disk persistence for offline support. Call once at app start.
  static Future<void> enablePersistence() async {
    if (!_persistenceEnabled) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000); // 10MB
      _persistenceEnabled = true;
    }
  }

  /// Initialize user node with all 432 cards set to false.
  Future<void> initializeUserCards(String uid, String username) async {
    final Map<String, dynamic> cards = {};
    for (int i = 1; i <= 432; i++) {
      cards[i.toString()] = false;
    }
    await _db.child('users/$uid').set({
      'username': username,
      'cards': cards,
    });
  }

  /// Check if a user node exists.
  Future<bool> userExists(String uid) async {
    final snapshot = await _db.child('users/$uid').get();
    return snapshot.exists;
  }

  /// Get all card states for a user.
  Future<Map<int, bool>> getUserCards(String uid) async {
    final snapshot = await _db.child('users/$uid/cards').get();
    if (!snapshot.exists) return {};
    return _parseCards(snapshot.value);
  }

  /// Update a single card's collected state.
  Future<void> updateCard(String uid, int cardId, bool collected) async {
    await _db.child('users/$uid/cards/${cardId.toString()}').set(collected);
  }

  /// Update multiple cards at once.
  Future<void> updateCards(String uid, Map<int, bool> cardUpdates) async {
    final Map<String, dynamic> updates = {};
    cardUpdates.forEach((id, collected) {
      updates['users/$uid/cards/${id.toString()}'] = collected;
    });
    await _db.update(updates);
  }

  /// Push entire local state to Firebase (sync after offline edits).
  Future<void> pushAllCards(String uid, Map<int, bool> cards) async {
    final Map<String, dynamic> fbCards = {};
    cards.forEach((id, collected) {
      fbCards[id.toString()] = collected;
    });
    await _db.child('users/$uid/cards').set(fbCards);
  }

  /// Get the username for a UID.
  Future<String?> getUsername(String uid) async {
    final snapshot = await _db.child('users/$uid/username').get();
    return snapshot.value as String?;
  }

  /// Listen to card changes in real-time.
  Stream<Map<int, bool>> watchUserCards(String uid) {
    return _db.child('users/$uid/cards').onValue.map((event) {
      if (event.snapshot.value == null) return <int, bool>{};
      return _parseCards(event.snapshot.value);
    });
  }

  /// Parse card data from Firebase, handling both List and Map formats.
  /// Firebase returns a List when keys are sequential integers,
  /// and a Map otherwise.
  Map<int, bool> _parseCards(dynamic data) {
    final Map<int, bool> cards = {};

    if (data is List) {
      // Firebase returned sequential numeric keys as a List
      for (int i = 0; i < data.length; i++) {
        if (data[i] != null) {
          cards[i] = data[i] == true;
        }
      }
    } else if (data is Map) {
      // Normal Map format
      data.forEach((key, value) {
        final id = int.tryParse(key.toString());
        if (id != null) {
          cards[id] = value == true;
        }
      });
    }

    return cards;
  }
}
