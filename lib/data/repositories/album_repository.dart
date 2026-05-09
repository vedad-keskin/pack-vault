import 'package:pack_vault/data/models/album.dart';

/// Static registry of all available sticker albums.
class AlbumRepository {
  AlbumRepository._();

  static const List<Album> albums = [
    Album(
      id: 'wc2026',
      name: 'World Cup 2026',
      dataAsset: 'lib/data/albums/wc2026.json',
    ),
    Album(
      id: 'paniniwc2026',
      name: 'Panini World Cup 2026',
      dataAsset: 'lib/data/albums/paniniwc2026.json',
    ),
  ];
}
