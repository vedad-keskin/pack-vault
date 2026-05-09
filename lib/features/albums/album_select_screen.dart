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

/// Grid of available sticker albums.
class AlbumSelectScreen extends StatelessWidget {
  const AlbumSelectScreen({super.key});

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
    // Load album data
    await StickerRepository.loadAlbum(album);

    if (context.mounted) {
      Navigator.of(context).push(
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final albums = AlbumRepository.albums;

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
                const SizedBox(height: 16),

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
                const SizedBox(height: 20),

                // Album grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return _AlbumCard(
                        album: album,
                        onTap: () => _openAlbum(context, album),
                      );
                    },
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

/// A single album card in the grid.
class _AlbumCard extends StatefulWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard>
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
              color: AppColors.cardBorderUncollected,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Album cover
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusLg)),
                  child: Image.asset(
                    widget.album.coverAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.pitchDark,
                      child: const Icon(Icons.collections_bookmark,
                          color: AppColors.textMuted, size: 48),
                    ),
                  ),
                ),
              ),
              // Album name
              Expanded(
                flex: 1,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Center(
                    child: Text(
                      widget.album.name.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
