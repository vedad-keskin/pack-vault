import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pack_vault/data/models/album.dart';
import 'package:pack_vault/data/models/category.dart';
import 'package:pack_vault/data/models/sticker.dart';
import 'package:pack_vault/data/models/page_layout.dart';

/// Loads and queries sticker data for the currently active album.
///
/// Usage:
///   await StickerRepository.loadAlbum(album);
///   final stickers = StickerRepository.stickersForPage(1);
class StickerRepository {
  StickerRepository._();

  static Album? _activeAlbum;
  static List<Sticker> _stickers = [];
  static List<Category> _categories = [];
  static List<PageLayout> _pages = [];
  /// Cache of total sticker counts per album id (survives album switches).
  static final Map<String, int> _albumTotalStickers = {};

  static Album? get activeAlbum => _activeAlbum;
  static List<Category> get categories => _categories;
  static int get totalStickers => _stickers.length;
  static int get totalPages => _pages.length;
  static bool get isLoaded => _activeAlbum != null;

  /// Get cached total sticker count for any album that was previously loaded.
  static int? totalStickersForAlbum(String albumId) => _albumTotalStickers[albumId];

  /// Load an album's data from its JSON asset.
  static Future<void> loadAlbum(Album album) async {
    if (_activeAlbum?.id == album.id) return; // already loaded

    final jsonStr = await rootBundle.loadString(album.dataAsset);
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    _categories = (data['categories'] as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();

    _pages = (data['pages'] as List)
        .map((p) => PageLayout.fromJson(p as Map<String, dynamic>))
        .toList();

    _stickers = (data['stickers'] as List)
        .map((s) => Sticker.fromJson(s as Map<String, dynamic>))
        .toList();

    _activeAlbum = album;
    _albumTotalStickers[album.id] = _stickers.length;
  }

  /// All stickers on a given page.
  static List<Sticker> stickersForPage(int page) =>
      _stickers.where((s) => s.page == page).toList();

  /// All stickers belonging to a category.
  static List<Sticker> stickersForCategory(int categoryId) =>
      _stickers.where((s) => s.categoryId == categoryId).toList();

  /// Page layout definition for a page number.
  static PageLayout layoutForPage(int page) =>
      _pages.firstWhere((p) => p.page == page);

  /// 0-indexed page index for jumping to a category's first page.
  static int firstPageIndexForCategory(int categoryId) {
    final idx = _pages.indexWhere((p) => p.categoryId == categoryId);
    return idx >= 0 ? idx : 0;
  }

  /// Get category by ID.
  static Category categoryById(int id) =>
      _categories.firstWhere((c) => c.id == id);

  /// Clear loaded data (e.g. when switching albums).
  static void clear() {
    _activeAlbum = null;
    _stickers = [];
    _categories = [];
    _pages = [];
  }
}
