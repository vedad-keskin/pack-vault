import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/core/widgets/football_background.dart';
import 'package:pack_vault/data/models/album.dart';
import 'package:pack_vault/data/repositories/album_repository.dart';
import 'package:pack_vault/data/repositories/sticker_repository.dart';
import 'package:pack_vault/services/auth_service.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:pack_vault/features/auth/login_screen.dart';
import 'package:pack_vault/features/categories/category_select_screen.dart';

/// Album selection screen — one album per row, horizontal card layout.
class AlbumSelectScreen extends StatefulWidget {
  const AlbumSelectScreen({super.key});

  @override
  State<AlbumSelectScreen> createState() => _AlbumSelectScreenState();
}

class _AlbumSelectScreenState extends State<AlbumSelectScreen> {
  /// Per-album progress: albumId → {collected, total}
  final Map<String, Map<String, int>> _albumProgress = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllAlbumProgress());
  }

  /// Load cached progress for every album.
  Future<void> _loadAllAlbumProgress() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) return;

    // Pre-load all albums so totalStickersForAlbum() has data
    for (final album in AlbumRepository.albums) {
      await StickerRepository.loadAlbum(album);
    }

    // Now read cached progress using the stored totals
    for (final album in AlbumRepository.albums) {
      final total = StickerRepository.totalStickersForAlbum(album.id) ?? 0;
      final progress = await CollectionService.getCachedAlbumProgress(
        auth.uid,
        album.id,
        total,
      );

      if (mounted) {
        setState(() {
          _albumProgress[album.id] = progress;
        });
      }
    }

    // Also use live CollectionService data for the active album
    _syncLiveProgress();
  }

  /// Sync live CollectionService counts into _albumProgress for the active album.
  void _syncLiveProgress() {
    final collection = context.read<CollectionService>();
    if (collection.activeAlbumId != null) {
      setState(() {
        _albumProgress[collection.activeAlbumId!] = {
          'collected': collection.collectedCount,
          'total': collection.totalStickers,
        };
      });
    }
  }

  void _onLogout(BuildContext context) {
    final auth = context.read<AuthService>();
    final collection = context.read<CollectionService>();
    collection.stopListening();
    StickerRepository.clear();
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

  void _openAlbum(BuildContext context, Album album) async {
    // Load album data (no-op if already loaded)
    await StickerRepository.loadAlbum(album);
    if (!context.mounted) return;

    // Switch collection service to this album
    final auth = context.read<AuthService>();
    final collection = context.read<CollectionService>();
    if (auth.isLoggedIn) {
      collection.startListening(
        auth.uid,
        album.id,
        StickerRepository.totalStickers,
      );
    }

    await Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => CategorySelectScreen(album: album),
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

    // Refresh all album progress when returning
    if (mounted) {
      _loadAllAlbumProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final albums = AlbumRepository.albums;

    // Keep live progress in sync for the active album
    final collection = context.watch<CollectionService>();
    if (collection.activeAlbumId != null && !collection.isLoading) {
      // Update cached progress for the active album with live data
      final liveProgress = {
        'collected': collection.collectedCount,
        'total': collection.totalStickers,
      };
      // Only update if different to avoid infinite rebuilds
      final current = _albumProgress[collection.activeAlbumId!];
      if (current == null ||
          current['collected'] != liveProgress['collected'] ||
          current['total'] != liveProgress['total']) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _albumProgress[collection.activeAlbumId!] = liveProgress;
            });
          }
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FootballBackground()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_soccer,
                          color: AppColors.pitchGreenGlow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        auth.username ?? 'Player',
                        style: GoogleFonts.orbitron(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _onLogout(context),
                        icon: const Icon(Icons.logout,
                            color: AppColors.textMuted, size: 20),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'MY ALBUMS',
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.firePrimary, AppColors.goalGold],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 24),

                // Album list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final album in albums)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AlbumRow(
                            album: album,
                            collected: _albumProgress[album.id]?['collected'] ?? 0,
                            total: _albumProgress[album.id]?['total'] ?? 0,
                            totalCategories: StickerRepository.totalCategoriesForAlbum(album.id) ?? 0,
                            totalPages: StickerRepository.totalPagesForAlbum(album.id) ?? 0,
                            onTap: () => _openAlbum(context, album),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const _ComingSoonSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Horizontal album card: cover left | info right
// ═══════════════════════════════════════════════════════════════

class _AlbumRow extends StatefulWidget {
  final Album album;
  final int collected;
  final int total;
  final int totalCategories;
  final int totalPages;
  final VoidCallback onTap;

  const _AlbumRow({
    required this.album,
    required this.collected,
    required this.total,
    required this.totalCategories,
    required this.totalPages,
    required this.onTap,
  });

  @override
  State<_AlbumRow> createState() => _AlbumRowState();
}

class _AlbumRowState extends State<_AlbumRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.01), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.01, end: 1.0), weight: 25),
    ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.total > 0 ? widget.collected / widget.total : 0.0;
    final pct = (progress * 100).toStringAsFixed(1);
    final isComplete = progress >= 1.0;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTap: () {
          _controller.forward(from: 0);
          widget.onTap();
        },
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: isComplete
                  ? AppColors.goalGold.withValues(alpha: 0.4)
                  : AppColors.cardBorderUncollected,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (isComplete)
                BoxShadow(
                  color: AppColors.goalGoldGlow.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            children: [
              // ── Left: cover image ──
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppSizes.radiusLg)),
                child: SizedBox(
                  width: 110,
                  height: 130,
                  child: Image.asset(
                    widget.album.coverAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.pitchDark,
                      child: const Icon(Icons.collections_bookmark,
                          color: AppColors.textMuted, size: 36),
                    ),
                  ),
                ),
              ),

              // ── Right: info ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Album name
                      Text(
                        widget.album.name.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Stats row
                      Row(
                        children: [
                          _StatLabel(
                            icon: Icons.style,
                            text: '${widget.total}',
                            color: AppColors.pitchGreenGlow,
                          ),
                          const SizedBox(width: 14),
                          _StatLabel(
                            icon: Icons.flag,
                            text: '${widget.totalCategories}',
                            color: AppColors.goalGold,
                          ),
                          const SizedBox(width: 14),
                          _StatLabel(
                            icon: Icons.auto_stories,
                            text: '${widget.totalPages}',
                            color: AppColors.fireSecondary,
                          ),
                        ],
                      ),

                      const Spacer(),

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
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Progress text
                      Row(
                        children: [
                          Text(
                            '${widget.collected}/${widget.total}',
                            style: GoogleFonts.orbitron(
                              color: isComplete
                                  ? AppColors.goalGold
                                  : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$pct%',
                            style: GoogleFonts.orbitron(
                              color: isComplete
                                  ? AppColors.goalGold
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact stat label: icon + number.
class _StatLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  "More Albums Coming Soon" footer
// ═══════════════════════════════════════════════════════════════

class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 48,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.pitchDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    i == 0
                        ? Icons.emoji_events
                        : i == 1
                            ? Icons.stadium
                            : Icons.sports_soccer,
                    color: AppColors.textMuted.withValues(alpha: 0.25),
                    size: 22,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            'MORE ALBUMS COMING SOON',
            style: GoogleFonts.orbitron(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Champions League, Euro, and more',
            style: GoogleFonts.inter(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
