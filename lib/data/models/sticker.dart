/// A single sticker within an album.
class Sticker {
  final int id;
  final String name;
  final int page;
  final int categoryId;

  const Sticker({
    required this.id,
    this.name = '',
    required this.page,
    required this.categoryId,
  });

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      page: json['page'] as int,
      categoryId: json['categoryId'] as int,
    );
  }
}
