/// A category within an album (e.g. a country, club, or league).
/// Categories are loaded from each album's JSON data.
class Category {
  final int id;
  final String name;
  final int badgeAssetId; // maps to assets/badges/{badgeAssetId}.png

  const Category({
    required this.id,
    required this.name,
    required this.badgeAssetId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      badgeAssetId: (json['badgeAssetId'] as int?) ?? json['id'] as int,
    );
  }

  /// Badge image asset path. Badges are shared across albums.
  String get badgeAsset => 'assets/badges/$badgeAssetId.png';
}
