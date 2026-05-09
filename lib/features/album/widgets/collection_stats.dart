import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pack_vault/core/constants/app_constants.dart';

/// Top bar showing overall collection progress and stats.
class CollectionStats extends StatelessWidget {
  final int collectedCount;
  final int totalCards;
  final String username;
  final VoidCallback onLogout;
  final VoidCallback? onBack;

  const CollectionStats({
    super.key,
    required this.collectedCount,
    required this.totalCards,
    required this.username,
    required this.onLogout,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCards > 0 ? collectedCount / totalCards : 0.0;
    final pct = (progress * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: AppColors.pitchGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Back button + Username + Logout
            Row(
              children: [
                // Back button (when navigating from country select)
                if (onBack != null) ...[
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary, size: 18),
                    tooltip: 'Back to countries',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                ],
                // User info
                const Icon(Icons.sports_soccer,
                    color: AppColors.pitchGreenGlow, size: 20),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                // Logout
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout,
                      color: AppColors.textMuted, size: 20),
                  tooltip: 'Logout',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Full-width progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.cardBorderUncollected,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0
                      ? AppColors.goalGold
                      : AppColors.pitchGreenGlow,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$collectedCount/$totalCards ($pct%)',
              style: GoogleFonts.orbitron(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

