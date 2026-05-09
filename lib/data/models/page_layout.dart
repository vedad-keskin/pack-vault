/// Defines how stickers are visually arranged on a single page.
///
/// Layout types are resolved to row definitions via static maps.
/// New layout types can be added for future albums with different
/// sticker-per-page counts or grid arrangements.
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
  };

  static const Map<String, int> _layoutWideIndex = {
    'wide_8': 0,
    'wide_7': 0,
  };
}
