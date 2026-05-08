import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/data/models/sticker_card.dart';
import 'package:pack_vault/data/models/country.dart';
import 'package:pack_vault/data/repositories/card_repository.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/album/widgets/country_header.dart';
import 'package:pack_vault/features/album/widgets/sticker_card_tile.dart';

/// A single album page showing cards with the country header.
///
/// Odd pages (8 cards) layout:
///   Row 1: 1 wide card (2/3) + 1 regular card (1/3)
///   Row 2: 3 regular cards
///   Row 3: 3 regular cards
///
/// Even pages (9 cards): standard 3×3 grid.
class AlbumPage extends StatelessWidget {
  final int pageNumber;

  const AlbumPage({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final cards = CardRepository.cardsForPage(pageNumber);
    final countryId = CardRepository.countryForPage(pageNumber);
    final country = Country.getById(countryId);
    final countryCards = CardRepository.cardsForCountry(countryId);
    final isOddPage = cards.length != 9;

    return Consumer<CollectionService>(
      builder: (context, collection, _) {
        final countryCollected = countryCards
            .where((c) => collection.isCollected(c.id))
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                CountryHeader(
                  country: country,
                  collectedCount: countryCollected,
                  totalCount: countryCards.length,
                  pageNumber: pageNumber,
                  totalPages: CardRepository.totalPages,
                ),
                const SizedBox(height: 10),

                if (isOddPage)
                  _buildOddPageLayout(cards, collection)
                else
                  _buildEvenPageGrid(cards, collection),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Even pages: 3×3 grid (9 cards)
  Widget _buildEvenPageGrid(List<StickerCard> cards, CollectionService collection) {
    return _buildRows(cards, collection, [3, 3, 3]);
  }

  /// Odd pages: row 1 has big+small, then 3+3
  Widget _buildOddPageLayout(List<StickerCard> cards, CollectionService collection) {
    const double spacing = AppSizes.cardGridSpacing;
    final remaining = cards.length - 2; // first 2 in row 1
    final row2Count = remaining >= 3 ? 3 : remaining;
    final row3Count = remaining - row2Count;

    return Column(
      children: [
        // Row 1: wide card (2 cols) + 1 regular card
        AspectRatio(
          aspectRatio: 2.4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Big card — 2/3 width
              Expanded(
                flex: 2,
                child: _tile(cards[0], collection, isBig: true),
              ),
              const SizedBox(width: spacing),
              // Regular card — 1/3 width
              Expanded(
                flex: 1,
                child: _tile(cards[1], collection),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.cardGridSpacing),

        // Row 2: 3 cards
        _buildCardRow(cards.sublist(2, 2 + row2Count), collection),

        if (row3Count > 0) ...[
          const SizedBox(height: AppSizes.cardGridSpacing),
          // Row 3: remaining cards
          _buildCardRow(cards.sublist(2 + row2Count), collection),
        ],
      ],
    );
  }

  /// Builds rows from a layout pattern like [3, 3, 3]
  Widget _buildRows(List<StickerCard> cards, CollectionService collection, List<int> rowCounts) {
    final rows = <Widget>[];
    int index = 0;

    for (int i = 0; i < rowCounts.length; i++) {
      final count = rowCounts[i];
      if (index >= cards.length) break;
      final end = (index + count).clamp(0, cards.length);

      if (i > 0) rows.add(const SizedBox(height: AppSizes.cardGridSpacing));
      rows.add(_buildCardRow(cards.sublist(index, end), collection));
      index = end;
    }

    return Column(children: rows);
  }

  /// A single row of equal-width card tiles
  Widget _buildCardRow(List<StickerCard> rowCards, CollectionService collection) {
    return AspectRatio(
      aspectRatio: 2.6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < rowCards.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.cardGridSpacing),
            Expanded(child: _tile(rowCards[i], collection)),
          ],
        ],
      ),
    );
  }

  Widget _tile(StickerCard card, CollectionService collection, {bool isBig = false}) {
    return StickerCardTile(
      card: card,
      isCollected: collection.isCollected(card.id),
      onToggle: () => collection.toggleCard(card.id),
      isBig: isBig,
    );
  }
}
