import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/core/widgets/football_background.dart';
import 'package:pack_vault/core/widgets/loading_indicator.dart';
import 'package:pack_vault/data/models/country.dart';
import 'package:pack_vault/data/repositories/card_repository.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/auth/login_screen.dart';
import 'package:pack_vault/features/album/album_screen.dart';
import 'package:pack_vault/features/album/widgets/collection_stats.dart';

/// Grid screen showing all 26 countries as tappable cards.
/// Navigating to a country opens the album at that country's first page.
class CountrySelectScreen extends StatefulWidget {
  const CountrySelectScreen({super.key});

  @override
  State<CountrySelectScreen> createState() => _CountrySelectScreenState();
}

class _CountrySelectScreenState extends State<CountrySelectScreen> {
  @override
  void initState() {
    super.initState();
    // Start Firebase listener here — the first screen after login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final collection = context.read<CollectionService>();
      if (auth.isLoggedIn) {
        collection.startListening(auth.uid);
      }
    });
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
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToCountry(int countryId) {
    final pageIndex = CardRepository.firstPageIndexForCountry(countryId);
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => AlbumScreen(initialPage: pageIndex),
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

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const Positioned.fill(child: FootballBackground()),

          // Main content
          Column(
            children: [
              // Top stats bar (same as album for consistency)
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

              // Country grid
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
                      itemCount: Country.all.length,
                      itemBuilder: (context, index) {
                        final country = Country.all[index];
                        final countryCards =
                            CardRepository.cardsForCountry(country.id);
                        final collected = countryCards
                            .where((c) => collection.isCollected(c.id))
                            .length;

                        return _CountryCard(
                          country: country,
                          collectedCount: collected,
                          totalCount: countryCards.length,
                          onTap: () => _navigateToCountry(country.id),
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

/// A single country card in the grid.
class _CountryCard extends StatefulWidget {
  final Country country;
  final int collectedCount;
  final int totalCount;
  final VoidCallback onTap;

  const _CountryCard({
    required this.country,
    required this.collectedCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard>
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
              // Shimmer gradient for completed countries
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

              // Card content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge image
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
                              color:
                                  AppColors.goalGoldGlow.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            widget.country.badgeAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(
                              widget.country.flagEmoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Country name
                    Text(
                      widget.country.name,
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

                    // Count text
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
