/// A sticker album definition.
/// Albums are registered statically in AlbumRepository.
class Album {
  final String id;
  final String name;
  final String dataAsset;

  const Album({
    required this.id,
    required this.name,
    required this.dataAsset,
  });

  /// Cover image path for album selection grid.
  String get coverAsset => 'assets/albums/$id.png';
}
