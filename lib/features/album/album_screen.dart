import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pack_vault/core/widgets/football_background.dart';
import 'package:pack_vault/core/widgets/loading_indicator.dart';
import 'package:pack_vault/data/repositories/card_repository.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/auth/login_screen.dart';
import 'package:pack_vault/features/album/widgets/album_page.dart';
import 'package:pack_vault/features/album/widgets/collection_stats.dart';
import 'package:pack_vault/features/album/widgets/page_indicator.dart';
import 'package:pack_vault/features/album/album_page_transition.dart';

/// Main album screen with swipeable pages and collection tracking.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Start listening to Firebase after the first frame (providers ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final collection = context.read<CollectionService>();
      if (auth.isLoggedIn) {
        collection.startListening(auth.uid);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onLogout() {
    final auth = context.read<AuthService>();
    final collection = context.read<CollectionService>();
    collection.stopListening();
    auth.logout();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, a, b) => const LoginScreen(),
        transitionsBuilder: (_, animation, a2, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const Positioned.fill(child: FootballBackground()),

          // Main content
          Column(
            children: [
              // Top stats bar
              Consumer<CollectionService>(
                builder: (context, collection, _) {
                  return CollectionStats(
                    collectedCount: collection.collectedCount,
                    totalCards: collection.totalCards,
                    username: auth.username ?? 'Player',
                    onLogout: _onLogout,
                  );
                },
              ),

              // Album pages
              Expanded(
                child: Consumer<CollectionService>(
                  builder: (context, collection, _) {
                    if (collection.isLoading) {
                      return const LoadingIndicator(
                          message: 'Loading your collection...');
                    }

                    return PageView.builder(
                      controller: _pageController,
                      itemCount: CardRepository.totalPages,
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
                            return AlbumPageTransformer.transform(
                              child!,
                              position,
                            );
                          },
                          child: AlbumPage(pageNumber: index + 1),
                        );
                      },
                    );
                  },
                ),
              ),

              // Page indicator at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: PageIndicator(
                  currentPage: _currentPage,
                  totalPages: CardRepository.totalPages,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
