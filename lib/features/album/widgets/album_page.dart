import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pack_vault/core/constants/app_constants.dart';

import 'package:pack_vault/data/models/country.dart';
import 'package:pack_vault/data/repositories/card_repository.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/album/widgets/country_header.dart';
import 'package:pack_vault/features/album/widgets/sticker_card_tile.dart';

/// A single album page showing cards in a grid with the country header.
class AlbumPage extends StatelessWidget {
  final int pageNumber; // 1-indexed

  const AlbumPage({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final cards = CardRepository.cardsForPage(pageNumber);
    final countryId = CardRepository.countryForPage(pageNumber);
    final country = Country.getById(countryId);

    // For country header: get all cards for this country
    final countryCards = CardRepository.cardsForCountry(countryId);

    return Consumer<CollectionService>(
      builder: (context, collection, _) {
        final countryCollected = countryCards
            .where((c) => collection.isCollected(c.id))
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Country header
              CountryHeader(
                country: country,
                collectedCount: countryCollected,
                totalCount: countryCards.length,
                pageNumber: pageNumber,
                totalPages: CardRepository.totalPages,
              ),
              const SizedBox(height: 12),

              // Card grid
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppSizes.gridColumns,
                    crossAxisSpacing: AppSizes.cardGridSpacing,
                    mainAxisSpacing: AppSizes.cardGridSpacing,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return StickerCardTile(
                      card: card,
                      isCollected: collection.isCollected(card.id),
                      onToggle: () => collection.toggleCard(card.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
