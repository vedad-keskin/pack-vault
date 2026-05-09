/// Defines how stickers are visually arranged on a single page.
///
/// Layout types are resolved to row definitions via static maps.
/// Indices refer to positions in the page's sticker list (0-indexed).
/// An index of -1 represents an empty space in the grid.
class PageLayout {
  final int page;
  final int categoryId;
  final String layoutType;

  const PageLayout({
    required this.page,
    required this.categoryId,
    required this.layoutType,
  });

  factory PageLayout.fromJson(Map<String, dynamic> json) {
    return PageLayout(
      page: json['page'] as int,
      categoryId: json['categoryId'] as int,
      layoutType: json['layout'] as String,
    );
  }

  /// Row definitions for this layout (indices into the page's sticker list).
  /// -1 means empty space.
  List<List<int>> get rows => _layoutRows[layoutType] ?? _layoutRows['grid_9']!;

  /// Index of the wide (2-column) card, if any.
  int? get wideIndex => _layoutWideIndex[layoutType];

  // ─── Layout Templates ──────────────────────────────────────
  // Add new entries here for future album layouts.

  static const Map<String, List<List<int>>> _layoutRows = {
    'wide_8': [
      [0, 1],
      [2, 3, 4],
      [5, 6, 7],
    ],
    'grid_9': [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
    ],
    'wide_7': [
      [0, 1],
      [2, 3, 4],
      [5, 6],
    ],
    // Panini album: country page A (10 stickers)
    // __ __ X1 X2
    // X3 X4 X5 X6
    // X7 X8 X9 X10
    'panini_a': [
      [-1, -1, 0, 1],
      [2, 3, 4, 5],
      [6, 7, 8, 9],
    ],
    // Panini album: country page B (10 stickers)
    // X11 X12 [X13 wide]
    // X14 X15 X16 X17
    // __  X18 X19 X20
    'panini_b': [
      [0, 1, 2],
      [3, 4, 5, 6],
      [-1, 7, 8, 9],
    ],
    // 4-column grid: 12 stickers
    'grid_12': [
      [0, 1, 2, 3],
      [4, 5, 6, 7],
      [8, 9, 10, 11],
    ],
    // 4-column grid: 11 stickers (one empty slot top-left)
    'grid_11': [
      [-1, 0, 1, 2],
      [3, 4, 5, 6],
      [7, 8, 9, 10],
    ],
  };

  static const Map<String, int> _layoutWideIndex = {
    'wide_8': 0,
    'wide_7': 0,
    'panini_b': 2,
  };
}
