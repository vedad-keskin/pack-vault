import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/data/models/sticker.dart';

/// Individual sticker tile with collected/uncollected visual states.
/// Tap to toggle. Shows bounce + golden glow when collected.
class StickerTile extends StatefulWidget {
  final Sticker sticker;
  final bool isCollected;
  final VoidCallback onToggle;
  final bool isBig;

  const StickerTile({
    super.key,
    required this.sticker,
    required this.isCollected,
    required this.onToggle,
    this.isBig = false,
  });

  @override
  State<StickerTile> createState() => _StickerTileState();
}

class _StickerTileState extends State<StickerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(from: 0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final collected = widget.isCollected;
    final big = widget.isBig;

    final numberSize = big ? 22.0 : 17.0;
    final nameSize = big ? 13.0 : 11.0;
    final iconSize = big ? 28.0 : 24.0;

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: collected
                ? AppColors.cardCollected
                : AppColors.cardUncollected,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(
              color: collected
                  ? AppColors.cardBorderCollected
                  : AppColors.cardBorderUncollected,
              width: collected ? 2 : 1,
            ),
            boxShadow: collected
                ? [
                    BoxShadow(
                      color:
                          AppColors.pitchGreenGlow.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              if (collected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusSm),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.goalGold.withValues(alpha: 0.05),
                          Colors.transparent,
                          AppColors.goalGold.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: big ? 8 : 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${widget.sticker.id}',
                        style: GoogleFonts.orbitron(
                          color: collected
                              ? AppColors.goalGold
                              : AppColors.textMuted,
                          fontSize: numberSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: big ? 8 : 4),
                      if (widget.sticker.name.isNotEmpty)
                        Text(
                          widget.sticker.name,
                          style: GoogleFonts.inter(
                            color: collected
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: nameSize,
                            fontWeight:
                                big ? FontWeight.w500 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: big ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: big ? 10 : 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: collected
                            ? Icon(
                                Icons.check_circle,
                                key: const ValueKey('collected'),
                                color: AppColors.pitchGreenGlow,
                                size: iconSize,
                              )
                            : Icon(
                                Icons.radio_button_unchecked,
                                key: const ValueKey('uncollected'),
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.5),
                                size: iconSize,
                              ),
                      ),
                    ],
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
