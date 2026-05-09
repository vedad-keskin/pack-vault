/// A category within an album (e.g. a country, club, or league).
/// Categories are loaded from each album's JSON data.
class Category {
  final int id;
  final String name;

  const Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
