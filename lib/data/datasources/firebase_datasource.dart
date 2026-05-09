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

  /// Initialize user profile only (no album data — lazy init).
  Future<void> initializeUser(String uid, String username) async {
    await _db.child('users/$uid').set({
      'username': username,
    });
  }

  /// Initialize album data for a user (called on first sticker toggle).
  Future<void> initializeAlbum(
      String uid, String albumId, int totalStickers) async {
    final Map<String, dynamic> stickers = {};
    for (int i = 1; i <= totalStickers; i++) {
      stickers[i.toString()] = false;
    }
    await _db.child('users/$uid/albums/$albumId').set(stickers);
  }

  /// Check if album data exists for a user.
  Future<bool> albumExists(String uid, String albumId) async {
    final snapshot = await _db.child('users/$uid/albums/$albumId').get();
    return snapshot.exists;
  }

  /// Get all sticker states for a user's album.
  Future<Map<int, bool>> getAlbumStickers(String uid, String albumId) async {
    final snapshot = await _db.child('users/$uid/albums/$albumId').get();
    if (!snapshot.exists) return {};
    return _parseStickers(snapshot.value);
  }

  /// Update a single sticker's collected state.
  Future<void> updateSticker(
      String uid, String albumId, int stickerId, bool collected) async {
    await _db
        .child('users/$uid/albums/$albumId/${stickerId.toString()}')
        .set(collected);
  }

  /// Push entire album state to Firebase.
  Future<void> pushAlbumStickers(
      String uid, String albumId, Map<int, bool> stickers) async {
    final Map<String, dynamic> fbStickers = {};
    stickers.forEach((id, collected) {
      fbStickers[id.toString()] = collected;
    });
    await _db.child('users/$uid/albums/$albumId').set(fbStickers);
  }

  /// Get the username for a UID.
  Future<String?> getUsername(String uid) async {
    final snapshot = await _db.child('users/$uid/username').get();
    return snapshot.value as String?;
  }

  /// Listen to sticker changes for a specific album in real-time.
  Stream<Map<int, bool>> watchAlbumStickers(String uid, String albumId) {
    return _db.child('users/$uid/albums/$albumId').onValue.map((event) {
      if (event.snapshot.value == null) return <int, bool>{};
      return _parseStickers(event.snapshot.value);
    });
  }

  // ─── Migration ─────────────────────────────────────────────

  /// Check if old-format card data exists (users/$uid/cards).
  Future<bool> hasLegacyCards(String uid) async {
    final snapshot = await _db.child('users/$uid/cards').get();
    return snapshot.exists;
  }

  /// Read old-format card data.
  Future<Map<int, bool>> getLegacyCards(String uid) async {
    final snapshot = await _db.child('users/$uid/cards').get();
    if (!snapshot.exists) return {};
    return _parseStickers(snapshot.value);
  }

  /// Delete old-format card data after migration.
  Future<void> deleteLegacyCards(String uid) async {
    await _db.child('users/$uid/cards').remove();
  }

  // ─── Parsing ───────────────────────────────────────────────

  /// Parse sticker data from Firebase, handling both List and Map formats.
  Map<int, bool> _parseStickers(dynamic data) {
    final Map<int, bool> stickers = {};

    if (data is List) {
      for (int i = 0; i < data.length; i++) {
        if (data[i] != null) {
          stickers[i] = data[i] == true;
        }
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        final id = int.tryParse(key.toString());
        if (id != null) {
          stickers[id] = value == true;
        }
      });
    }

    return stickers;
  }
}
