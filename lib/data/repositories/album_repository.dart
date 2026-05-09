import 'package:pack_vault/data/models/album.dart';

/// Registry of all available sticker albums.
class AlbumRepository {
  AlbumRepository._();

  static const List<Album> albums = [
    Album(
      id: 'wc2026',
      name: 'World Cup 2026',
      dataAsset: 'lib/data/albums/wc2026.json',
    ),
    // Future albums go here:
    // Album(id: 'ucl2026', name: 'Champions League 2025/26', ...),
  ];

  static Album getById(String id) =>
      albums.firstWhere((a) => a.id == id);
}
