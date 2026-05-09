import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pack_vault/core/constants/app_constants.dart';

/// Dot-style page indicator for the sticker PageView.
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    const visibleRange = 4;
    final start = (currentPage - visibleRange).clamp(0, totalPages - 1);
    final end = (currentPage + visibleRange + 1).clamp(0, totalPages);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chevron_left,
            color: currentPage > 0
                ? AppColors.textSecondary
                : Colors.transparent,
            size: 18,
          ),
          const SizedBox(width: 4),

          if (start > 0) ...[
            _dot(false),
            const SizedBox(width: 3),
          ],
          for (int i = start; i < end; i++) ...[
            _dot(i == currentPage),
            if (i < end - 1) const SizedBox(width: 3),
          ],
          if (end < totalPages) ...[
            const SizedBox(width: 3),
            _dot(false),
          ],

          const SizedBox(width: 8),

          Text(
            '${currentPage + 1} / $totalPages',
            style: GoogleFonts.orbitron(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: currentPage < totalPages - 1
                ? AppColors.textSecondary
                : Colors.transparent,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 12 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active
            ? AppColors.pitchGreenGlow
            : AppColors.cardBorderUncollected,
        borderRadius: BorderRadius.circular(3),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.pitchGreenGlow.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}
