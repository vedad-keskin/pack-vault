import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pack_vault/core/widgets/football_background.dart';
import 'package:pack_vault/core/widgets/loading_indicator.dart';
import 'package:pack_vault/data/models/album.dart';
import 'package:pack_vault/data/repositories/sticker_repository.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/stickers/sticker_page_transition.dart';
import 'package:pack_vault/features/stickers/widgets/sticker_page.dart';
import 'package:pack_vault/features/stickers/widgets/collection_stats.dart';
import 'package:pack_vault/features/stickers/widgets/page_indicator.dart';

/// Swipeable sticker pages for a selected album.
class StickerPageScreen extends StatefulWidget {
  final Album album;
  final int initialPage;

  const StickerPageScreen({
    super.key,
    required this.album,
    this.initialPage = 0,
  });

  @override
  State<StickerPageScreen> createState() => _StickerPageScreenState();
}

class _StickerPageScreenState extends State<StickerPageScreen> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final totalPages = StickerRepository.totalPages;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FootballBackground()),
          Column(
            children: [
              Consumer<CollectionService>(
                builder: (context, collection, _) {
                  return CollectionStats(
                    collectedCount: collection.collectedCount,
                    totalStickers: collection.totalStickers,
                    username: auth.username ?? 'Player',
                    onLogout: null,
                    onBack: () => Navigator.of(context).pop(),
                  );
                },
              ),
              Expanded(
                child: Consumer<CollectionService>(
                  builder: (context, collection, _) {
                    if (collection.isLoading) {
                      return const LoadingIndicator(
                          message: 'Loading your collection...');
                    }

                    return PageView.builder(
                      controller: _pageController,
                      itemCount: totalPages,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double position = 0;
                            if (_pageController.position.haveDimensions) {
                              position = _pageController.page! - index;
                            }
                            return StickerPageTransformer.transform(
                              child!,
                              position,
                            );
                          },
                          child: StickerPage(
                            album: widget.album,
                            pageNumber: index + 1,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: PageIndicator(
                  currentPage: _currentPage,
                  totalPages: totalPages,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
