import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pack_vault/data/models/sticker_card.dart';

/// Generates all 432 sticker cards with correct page and country mapping.
///
/// Player names are loaded from cards_database.json (editable).
/// The page/country structure is computed:
///   Odd pages  → 8 cards
///   Even pages → 9 cards
///   Last page (51) → 7 cards
///
/// Country mapping:
///   Pages 1-2  → Country 1 (Mexico)
///   Pages 3-4  → Country 2 (Switzerland)
///   ...
///   Pages 49-50 → Country 25 (Bosnia and Herzegovina)
///   Page 51     → Country 26 (Legends)
class CardRepository {
  CardRepository._();

  static List<StickerCard> _cards = [];
  static bool _loaded = false;

  static List<StickerCard> get allCards => _cards;
  static bool get isLoaded => _loaded;

  static const int totalPages = 51;
  static const int totalCards = 432;

  /// Load card names from the JSON asset. Call once at app start.
  static Future<void> loadCards() async {
    if (_loaded) return;

    try {
      final jsonStr = await rootBundle.loadString('lib/data/cards_database.json');
      final List<dynamic> jsonList = json.decode(jsonStr);

      _cards = jsonList.map((item) => StickerCard(
        id: item['id'] as int,
        fullName: (item['fullName'] as String?) ?? '',
        page: item['page'] as int,
        countryId: item['countryId'] as int,
      )).toList();
    } catch (e) {
      // Fallback to generated cards if JSON fails
      _cards = _generateCards();
    }

    _loaded = true;
  }

  /// Returns the number of cards for a given page number.
  static int cardsPerPage(int page) {
    if (page == totalPages) return 7;
    return page.isOdd ? 8 : 9;
  }

  /// Returns the country ID for a given page number.
  static int countryForPage(int page) {
    if (page == totalPages) return 26;
    return ((page - 1) ~/ 2) + 1;
  }

  /// Returns all cards for a specific page.
  static List<StickerCard> cardsForPage(int page) {
    return _cards.where((c) => c.page == page).toList();
  }

  /// Returns all cards for a specific country.
  static List<StickerCard> cardsForCountry(int countryId) {
    return _cards.where((c) => c.countryId == countryId).toList();
  }

  /// Fallback generator if JSON can't be loaded.
  static List<StickerCard> _generateCards() {
    final List<StickerCard> cards = [];
    int cardId = 1;

    for (int page = 1; page <= totalPages; page++) {
      final int count = cardsPerPage(page);
      final int country = countryForPage(page);

      for (int i = 0; i < count; i++) {
        cards.add(StickerCard(
          id: cardId,
          page: page,
          countryId: country,
        ));
        cardId++;
      }
    }

    return cards;
  }
}
