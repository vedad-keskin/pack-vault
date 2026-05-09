/// A sticker album definition.
/// Albums are registered statically in AlbumRepository.
class Album {
  final String id;
  final String name;
  final String dataAsset;
  /// Scale factor for sticker number font size (1.0 = default).
  final double stickerFontScale;

  const Album({
    required this.id,
    required this.name,
    required this.dataAsset,
    this.stickerFontScale = 1.0,
  });

  /// Cover image path for album selection grid.
  String get coverAsset => 'assets/albums/$id.png';
}
