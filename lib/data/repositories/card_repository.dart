import 'package:pack_vault/data/models/sticker_card.dart';

/// Generates all 432 sticker cards with correct page and country mapping.
///
/// Pattern:
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

  static final List<StickerCard> _cards = _generateCards();

  static List<StickerCard> get allCards => _cards;

  static const int totalPages = 51;
  static const int totalCards = 432;

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

    assert(cards.length == totalCards,
        'Expected $totalCards cards, got ${cards.length}');
    return cards;
  }
}
