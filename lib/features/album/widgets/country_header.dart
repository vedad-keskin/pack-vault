import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/data/models/country.dart';

/// Displays country name, flag, and collection progress at the top of each album page.
class CountryHeader extends StatelessWidget {
  final Country country;
  final int collectedCount;
  final int totalCount;
  final int pageNumber;
  final int totalPages;

  const CountryHeader({
    super.key,
    required this.country,
    required this.collectedCount,
    required this.totalCount,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = collectedCount == totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isComplete
              ? AppColors.goalGold.withValues(alpha: 0.4)
              : AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pitchDark,
              border: Border.all(
                color: isComplete
                    ? AppColors.goalGold.withValues(alpha: 0.5)
                    : AppColors.divider,
                width: 1.5,
              ),
              boxShadow: [
                if (isComplete)
                  BoxShadow(
                    color: AppColors.goalGoldGlow.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  country.badgeAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Country name & page
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country.name,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Page $pageNumber of $totalPages',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Collection progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.goalGold.withValues(alpha: 0.15)
                  : AppColors.pitchDark,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: isComplete
                    ? AppColors.goalGold.withValues(alpha: 0.5)
                    : AppColors.cardBorderUncollected,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isComplete)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.star, color: AppColors.goalGold, size: 14),
                  ),
                Text(
                  '$collectedCount/$totalCount',
                  style: GoogleFonts.orbitron(
                    color: isComplete ? AppColors.goalGold : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
