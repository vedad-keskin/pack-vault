import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pack_vault/core/constants/app_constants.dart';

/// Top stats bar showing user info, progress, and navigation controls.
/// Used in both CategorySelectScreen and StickerPageScreen.
class CollectionStats extends StatelessWidget {
  final int collectedCount;
  final int totalStickers;
  final String username;
  final VoidCallback? onLogout;
  final VoidCallback? onBack;
  final Widget? trailing;

  const CollectionStats({
    super.key,
    required this.collectedCount,
    required this.totalStickers,
    required this.username,
    this.onLogout,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalStickers > 0 ? collectedCount / totalStickers : 0.0;
    final pct = (progress * 100).toStringAsFixed(1);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Navigation, user, logout
            Row(
              children: [
                if (onBack != null) ...[
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary, size: 18),
                    tooltip: 'Back',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                ],
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
                if (trailing != null) trailing!,
                if (onLogout != null)
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout,
                        color: AppColors.textMuted, size: 20),
                    tooltip: 'Logout',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
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
              '$collectedCount/$totalStickers ($pct%)',
              style: GoogleFonts.orbitron(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
