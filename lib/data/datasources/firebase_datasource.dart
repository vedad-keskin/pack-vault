import 'package:firebase_database/firebase_database.dart';

/// Raw Firebase Realtime Database CRUD operations.
class FirebaseDatasource {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

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

    final Map<int, bool> cards = {};
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      data.forEach((key, value) {
        final id = int.tryParse(key.toString());
        if (id != null) {
          cards[id] = value == true;
        }
      });
    }
    return cards;
  }

  /// Update a single card's collected state.
  Future<void> updateCard(String uid, int cardId, bool collected) async {
    await _db.child('users/$uid/cards/${cardId.toString()}').set(collected);
  }

  /// Update multiple cards at once.
  Future<void> updateCards(
      String uid, Map<int, bool> cardUpdates) async {
    final Map<String, dynamic> updates = {};
    cardUpdates.forEach((id, collected) {
      updates['users/$uid/cards/${id.toString()}'] = collected;
    });
    await _db.update(updates);
  }

  /// Get the username for a UID.
  Future<String?> getUsername(String uid) async {
    final snapshot = await _db.child('users/$uid/username').get();
    return snapshot.value as String?;
  }

  /// Listen to card changes in real-time.
  Stream<Map<int, bool>> watchUserCards(String uid) {
    return _db.child('users/$uid/cards').onValue.map((event) {
      final Map<int, bool> cards = {};
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          final id = int.tryParse(key.toString());
          if (id != null) {
            cards[id] = value == true;
          }
        });
      }
      return cards;
    });
  }
}
