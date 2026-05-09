import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/core/widgets/football_background.dart';
import 'package:pack_vault/core/widgets/loading_indicator.dart';
import 'package:pack_vault/data/models/album.dart';
import 'package:pack_vault/data/repositories/sticker_repository.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/stickers/sticker_page_screen.dart';
import 'package:pack_vault/features/stickers/widgets/collection_stats.dart';

/// Grid showing all categories for the selected album.
class CategorySelectScreen extends StatefulWidget {
  final Album album;
  const CategorySelectScreen({super.key, required this.album});

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final collection = context.read<CollectionService>();
      if (auth.isLoggedIn) {
        collection.startListening(
          auth.uid,
          widget.album.id,
          StickerRepository.totalStickers,
        );
      }
    });
  }

  void _navigateToCategory(int categoryId) {
    final pageIndex = StickerRepository.firstPageIndexForCategory(categoryId);
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => StickerPageScreen(
          album: widget.album,
          initialPage: pageIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final categories = StickerRepository.categories;

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

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final catStickers =
                            StickerRepository.stickersForCategory(category.id);
                        final collected = catStickers
                            .where((s) => collection.isCollected(s.id))
                            .length;

                        return _CategoryCard(
                          name: category.name,
                          badgeAsset:
                              widget.album.badgeAsset(category.id),
                          collectedCount: collected,
                          totalCount: catStickers.length,
                          onTap: () => _navigateToCategory(category.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single category card in the grid.
class _CategoryCard extends StatefulWidget {
  final String name;
  final String badgeAsset;
  final int collectedCount;
  final int totalCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.badgeAsset,
    required this.collectedCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.03), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete =
        widget.collectedCount == widget.totalCount && widget.totalCount > 0;
    final progress =
        widget.totalCount > 0 ? widget.collectedCount / widget.totalCount : 0.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: isComplete
                  ? AppColors.goalGold.withValues(alpha: 0.5)
                  : AppColors.cardBorderUncollected,
              width: isComplete ? 1.5 : 1,
            ),
            boxShadow: [
              if (isComplete)
                BoxShadow(
                  color: AppColors.goalGoldGlow.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isComplete)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.goalGold.withValues(alpha: 0.06),
                          Colors.transparent,
                          AppColors.goalGold.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pitchDark.withValues(alpha: 0.6),
                        border: Border.all(
                          color: isComplete
                              ? AppColors.goalGold.withValues(alpha: 0.4)
                              : AppColors.divider,
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (isComplete)
                            BoxShadow(
                              color: AppColors.goalGoldGlow
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            widget.badgeAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.category,
                              color: AppColors.textMuted,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Name
                    Text(
                      widget.name,
                      style: GoogleFonts.outfit(
                        color: isComplete
                            ? AppColors.goalGold
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.cardBorderUncollected,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete
                              ? AppColors.goalGold
                              : AppColors.pitchGreenGlow,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Count
                    Text(
                      '${widget.collectedCount}/${widget.totalCount}',
                      style: GoogleFonts.orbitron(
                        color: isComplete
                            ? AppColors.goalGold
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
