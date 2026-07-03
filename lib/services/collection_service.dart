import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';
import 'package:pack_vault/data/repositories/sticker_repository.dart';
import 'package:pack_vault/data/repositories/album_repository.dart';

/// Manages the user's sticker collection for a specific album.
///
/// Flow:
///   1. startListening(uid, albumId, totalStickers)
///   2. Load from SharedPreferences cache → show UI instantly
///   3. Subscribe to Firebase stream → replace local state
///   4. On toggleSticker: update optimistically + push to Firebase
class CollectionService extends ChangeNotifier {
  final FirebaseDatasource _datasource = FirebaseDatasource();

  Map<String, bool> _stickers = {};
  bool _isLoading = true;
  String? _uid;
  String? _activeAlbumId;
  int _totalStickers = 0;
  StreamSubscription? _subscription;

  Map<String, bool> get stickers => _stickers;
  bool get isLoading => _isLoading;
  String? get activeAlbumId => _activeAlbumId;
  int get collectedCount => _stickers.values.where((v) => v).length;
  int get totalStickers => _totalStickers;
  double get progress => _totalStickers > 0 ? collectedCount / _totalStickers : 0;

  bool isCollected(String stickerId) => _stickers[stickerId] ?? false;

  // === Local Storage Keys ===
  static String _cacheKey(String uid, String albumId) => 'stickers_${uid}_$albumId';

  /// Read cached progress for ANY album without changing active state.
  /// Returns {collected, total}. Used by AlbumSelectScreen for per-album counts.
  static Future<Map<String, int>> getCachedAlbumProgress(
      String uid, String albumId, int totalStickers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey(uid, albumId));
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        final collected = decoded.values.where((v) => v == true).length;
        return {'collected': collected, 'total': totalStickers};
      }
    } catch (e) {
      debugPrint('getCachedAlbumProgress error: $e');
    }
    return {'collected': 0, 'total': totalStickers};
  }

  /// Resolve album progress: local cache first, then Firebase fallback.
  /// Used by AlbumSelectScreen on first login when SharedPreferences is empty.
  Future<Map<String, int>> loadAlbumProgress(
      String uid, String albumId, int totalStickers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey(uid, albumId));
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        final collected = decoded.values.where((v) => v == true).length;
        return {'collected': collected, 'total': totalStickers};
      }

      await _migrateIfNeeded(uid, albumId);
      final stickers = await _datasource.getAlbumStickers(uid, albumId);
      if (stickers.isNotEmpty) {
        await _saveAlbumToLocal(uid, albumId, stickers);
      }
      final collected = stickers.values.where((v) => v).length;
      return {'collected': collected, 'total': totalStickers};
    } catch (e) {
      debugPrint('loadAlbumProgress error: $e');
      return {'collected': 0, 'total': totalStickers};
    }
  }

  /// Persist sticker map for a specific album (no active-album state required).
  Future<void> _saveAlbumToLocal(
      String uid, String albumId, Map<String, bool> stickers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> encoded = stickers.map(
        (k, v) => MapEntry(k, v),
      );
      await prefs.setString(_cacheKey(uid, albumId), json.encode(encoded));
    } catch (e) {
      debugPrint('Album local save error: $e');
    }
  }

  /// Load stickers from SharedPreferences cache for instant startup display.
  Future<void> _loadFromLocal(String uid, String albumId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey(uid, albumId));
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        _stickers = decoded.map((k, v) => MapEntry(k, v == true));
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
        (k, v) => MapEntry(k, v),
      );
      await prefs.setString(
          _cacheKey(_uid!, _activeAlbumId!), json.encode(encoded));
    } catch (e) {
      debugPrint('Local save error: $e');
    }
  }

  /// Pre-load cached collection data (call from splash before UI renders).
  /// This sets the initial state so AlbumSelectScreen never shows 0%.
  Future<void> preloadFromCache(
      String uid, String albumId, int totalStickers) async {
    _uid = uid;
    _activeAlbumId = albumId;
    _totalStickers = totalStickers;
    await _loadFromLocal(uid, albumId);
  }

  /// Start listening to sticker collection changes for the given album.
  void startListening(String uid, String albumId, int totalStickers) {
    // Already fully subscribed to this album
    if (_uid == uid && _activeAlbumId == albumId && _subscription != null) {
      return;
    }

    // Check if cache was pre-loaded (same uid+album, has data, not loading)
    final wasPreloaded =
        _uid == uid && _activeAlbumId == albumId && !_isLoading;

    _uid = uid;
    _activeAlbumId = albumId;
    _totalStickers = totalStickers;

    if (!wasPreloaded) {
      // Fresh start — show loading, read cache
      _isLoading = true;
      notifyListeners();

      _migrateIfNeeded(uid, albumId).then((_) {
        _loadFromLocal(uid, albumId).then((_) {
          _subscribeToFirebase(uid, albumId);
        });
      });
    } else {
      // Cache was pre-loaded — skip loading state, just subscribe to Firebase
      _migrateIfNeeded(uid, albumId).then((_) {
        _subscribeToFirebase(uid, albumId);
      });
    }
  }

  /// Subscribe to Firebase real-time updates for an album.
  void _subscribeToFirebase(String uid, String albumId) {
    _subscription?.cancel();
    _subscription = _datasource.watchAlbumStickers(uid, albumId).listen(
      (firebaseStickers) {
        if (firebaseStickers.isNotEmpty) {
          _stickers = firebaseStickers;
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
  Future<void> toggleSticker(String stickerId) async {
    if (_uid == null || _activeAlbumId == null) return;

    // If this is the first interaction with this album in Firebase,
    // initialize all stickers as false first.
    if (_stickers.length < _totalStickers) {
      await _initializeAlbumInFirebase();
    }

    final newState = !(_stickers[stickerId] ?? false);

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

  /// Initialize all stickers as false in Firebase and local state.
  /// Called once when user first interacts with a new album.
  Future<void> _initializeAlbumInFirebase() async {
    if (_uid == null || _activeAlbumId == null) return;

    // Ensure album data is loaded so we can read all sticker IDs
    final album = AlbumRepository.albums.firstWhere(
      (a) => a.id == _activeAlbumId,
      orElse: () => AlbumRepository.albums.first,
    );
    await StickerRepository.loadAlbum(album);

    // Build full map: preserve any existing collected states
    final Map<String, bool> fullMap = {};
    for (final stickerId in _getAllStickerIds()) {
      fullMap[stickerId] = _stickers[stickerId] ?? false;
    }

    _stickers = fullMap;
    notifyListeners();
    _saveToLocal();

    // Push the full map to Firebase
    try {
      await _datasource.pushAlbumStickers(_uid!, _activeAlbumId!, fullMap);
      debugPrint('Initialized ${fullMap.length} stickers in Firebase for $_activeAlbumId');
    } catch (e) {
      debugPrint('Album init error: $e');
    }
  }

  /// Get all sticker IDs from the currently loaded StickerRepository.
  List<String> _getAllStickerIds() {
    final List<String> ids = [];
    for (final category in StickerRepository.categories) {
      final stickers = StickerRepository.stickersForCategory(category.id);
      for (final s in stickers) {
        ids.add(s.id);
      }
    }
    return ids;
  }

  /// Get collected count for a specific category's stickers.
  int collectedForCategory(List<String> stickerIds) {
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
    _isLoading = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
