import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';

/// Manages the user's sticker collection for a specific album.
///
/// Flow:
///   1. startListening(uid, albumId, totalStickers)
///   2. Load from SharedPreferences cache → show UI instantly
///   3. Subscribe to Firebase stream → replace local state
///   4. On toggleSticker: update optimistically + push to Firebase
///   5. Lazy init: album data created in Firebase on first toggle
class CollectionService extends ChangeNotifier {
  final FirebaseDatasource _datasource = FirebaseDatasource();

  Map<int, bool> _stickers = {};
  bool _isLoading = true;
  String? _uid;
  String? _activeAlbumId;
  int _totalStickers = 0;
  bool _albumInitialized = false;
  StreamSubscription? _subscription;

  Map<int, bool> get stickers => _stickers;
  bool get isLoading => _isLoading;
  String? get activeAlbumId => _activeAlbumId;
  int get collectedCount => _stickers.values.where((v) => v).length;
  int get totalStickers => _totalStickers;
  double get progress => _totalStickers > 0 ? collectedCount / _totalStickers : 0;

  bool isCollected(int stickerId) => _stickers[stickerId] ?? false;

  // === Local Storage Keys ===
  static String _cacheKey(String uid, String albumId) => 'stickers_${uid}_$albumId';

  /// Load stickers from SharedPreferences cache for instant startup display.
  Future<void> _loadFromLocal(String uid, String albumId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey(uid, albumId));
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        _stickers = decoded.map((k, v) => MapEntry(int.parse(k), v == true));
        _isLoading = false;
        notifyListeners();
        debugPrint('Loaded $collectedCount stickers from local cache ($albumId)');
      }
    } catch (e) {
      debugPrint('Local load error: $e');
    }
  }

  /// Save current sticker state to SharedPreferences.
  Future<void> _saveToLocal() async {
    if (_uid == null || _activeAlbumId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> encoded = _stickers.map(
        (k, v) => MapEntry(k.toString(), v),
      );
      await prefs.setString(
          _cacheKey(_uid!, _activeAlbumId!), json.encode(encoded));
    } catch (e) {
      debugPrint('Local save error: $e');
    }
  }

  /// Start listening to sticker collection changes for the given album.
  void startListening(String uid, String albumId, int totalStickers) {
    if (_uid == uid && _activeAlbumId == albumId && !_isLoading) return;

    _uid = uid;
    _activeAlbumId = albumId;
    _totalStickers = totalStickers;
    _albumInitialized = false;
    _isLoading = true;
    notifyListeners();

    // Step 1: Migrate legacy data if needed (one-time)
    _migrateIfNeeded(uid, albumId).then((_) {
      // Step 2: Load from local cache for instant UI
      _loadFromLocal(uid, albumId).then((_) {
        // Step 3: Subscribe to Firebase — source of truth
        _subscription?.cancel();
        _subscription = _datasource.watchAlbumStickers(uid, albumId).listen(
          (firebaseStickers) {
            if (firebaseStickers.isNotEmpty) {
              _stickers = firebaseStickers;
              _albumInitialized = true;
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
    });
  }

  /// Migrate old users/$uid/cards data to users/$uid/albums/wc2026.
  Future<void> _migrateIfNeeded(String uid, String albumId) async {
    if (albumId != 'wc2026') return; // only migrate for the original album

    try {
      final hasLegacy = await _datasource.hasLegacyCards(uid);
      if (!hasLegacy) return;

      debugPrint('Migrating legacy card data to albums/wc2026...');
      final legacyCards = await _datasource.getLegacyCards(uid);
      if (legacyCards.isNotEmpty) {
        await _datasource.pushAlbumStickers(uid, 'wc2026', legacyCards);
        await _datasource.deleteLegacyCards(uid);
        debugPrint('Migration complete: ${legacyCards.length} stickers moved');
      }
    } catch (e) {
      debugPrint('Migration error (non-fatal): $e');
    }
  }

  /// Toggle a sticker's collected state.
  /// Lazy-initializes album data in Firebase on first toggle.
  Future<void> toggleSticker(int stickerId) async {
    if (_uid == null || _activeAlbumId == null) return;

    final newState = !(_stickers[stickerId] ?? false);

    // Lazy init: create album data in Firebase if not yet done
    if (!_albumInitialized) {
      try {
        final exists =
            await _datasource.albumExists(_uid!, _activeAlbumId!);
        if (!exists) {
          await _datasource.initializeAlbum(
              _uid!, _activeAlbumId!, _totalStickers);
        }
        _albumInitialized = true;
      } catch (e) {
        debugPrint('Lazy init error: $e');
      }
    }

    // Optimistic UI update + local cache
    _stickers[stickerId] = newState;
    notifyListeners();
    _saveToLocal();

    // Push to Firebase
    try {
      await _datasource.updateSticker(
          _uid!, _activeAlbumId!, stickerId, newState);
    } catch (e) {
      debugPrint('Firebase sync error (will retry): $e');
    }
  }

  /// Get collected count for a specific category's stickers.
  int collectedForCategory(List<int> stickerIds) {
    return stickerIds.where((id) => _stickers[id] == true).length;
  }

  /// Stop listening when user logs out or switches album.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _stickers = {};
    _uid = null;
    _activeAlbumId = null;
    _totalStickers = 0;
    _albumInitialized = false;
    _isLoading = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
