import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/data/models/album.dart';
import 'package:pack_vault/data/models/sticker.dart';
import 'package:pack_vault/data/models/page_layout.dart';
import 'package:pack_vault/data/repositories/sticker_repository.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/stickers/widgets/category_header.dart';
import 'package:pack_vault/features/stickers/widgets/sticker_tile.dart';

/// A single sticker page with layout driven by PageLayout definitions.
class StickerPage extends StatelessWidget {
  final Album album;
  final int pageNumber;

  const StickerPage({super.key, required this.album, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final stickers = StickerRepository.stickersForPage(pageNumber);
    final layout = StickerRepository.layoutForPage(pageNumber);
    final category = StickerRepository.categoryById(layout.categoryId);
    final catStickers =
        StickerRepository.stickersForCategory(category.id);

    return Consumer<CollectionService>(
      builder: (context, collection, _) {
        final catCollected = catStickers
            .where((s) => collection.isCollected(s.id))
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              CategoryHeader(
                name: category.name,
                badgeAsset: album.badgeAsset(category.id),
                collectedCount: catCollected,
                totalCount: catStickers.length,
                pageNumber: pageNumber,
                totalPages: StickerRepository.totalPages,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildLayout(
                              stickers, layout, collection),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Build rows from the PageLayout definition.
  List<Widget> _buildLayout(
    List<Sticker> stickers,
    PageLayout layout,
    CollectionService collection,
  ) {
    final rows = layout.rows;
    final wideIndex = layout.wideIndex;
    final widgets = <Widget>[];

    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      if (rowIdx > 0) {
        widgets.add(const SizedBox(height: AppSizes.cardGridSpacing));
      }

      final indices = rows[rowIdx];

      // Check if this row contains the wide card
      if (wideIndex != null && indices.contains(wideIndex)) {
        // Wide row: first card is wide (2/3), second is regular (1/3)
        widgets.add(AspectRatio(
          aspectRatio: 2.4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < indices.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSizes.cardGridSpacing),
                Expanded(
                  flex: indices[i] == wideIndex ? 2 : 1,
                  child: _tile(
                    stickers[indices[i]],
                    collection,
                    isBig: indices[i] == wideIndex,
                  ),
                ),
              ],
            ],
          ),
        ));
      } else {
        // Regular row of equal-width cards
        widgets.add(AspectRatio(
          aspectRatio: 2.6,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < indices.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSizes.cardGridSpacing),
                Expanded(
                    child: _tile(stickers[indices[i]], collection)),
              ],
            ],
          ),
        ));
      }
    }

    return widgets;
  }

  Widget _tile(Sticker sticker, CollectionService collection,
      {bool isBig = false}) {
    return StickerTile(
      sticker: sticker,
      isCollected: collection.isCollected(sticker.id),
      onToggle: () => collection.toggleSticker(sticker.id),
      isBig: isBig,
    );
  }
}
