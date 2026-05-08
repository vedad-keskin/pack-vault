import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';

class PixelDialog extends StatelessWidget {
  final String title;
  final Color color;
  final Color accentColor;
  final String? soundPath;
  final VoidCallback? onPressed;
  final double? titleFontSize;
  final bool useGlobalPlayer;

  const PixelDialog({
    super.key,
    required this.title,
    required this.color,
    required this.accentColor,
    this.soundPath,
    this.onPressed,
    this.titleFontSize,
    this.useGlobalPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      // Layer 1: Outer Border / Shadow Base
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Semi-transparent outer border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(12, 12), // Deep shadow
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4), // Thickness of outer black border
      child: Container(
        // Layer 2: Main Frame Color (Silver/Stone)
        decoration: BoxDecoration(
          color: const Color(0xFF778DA9).withOpacity(0.9), // Stone Grey
          border: Border.symmetric(
            vertical: BorderSide(
              color: const Color(0xFF415A77).withOpacity(0.9),
              width: 4,
            ), // Side accents
            horizontal: BorderSide(
              color: const Color(0xFFE0E1DD).withOpacity(0.9),
              width: 4,
            ), // Top/Bottom highlights
          ),
        ),
        padding: const EdgeInsets.all(4), // Thickness of metallic frame
        child: Container(
          // Layer 3: Inner Inset Border
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A).withOpacity(0.85), // Inner BG base
            border: Border.all(color: Colors.black.withOpacity(0.6), width: 2),
          ),
          child: Container(
            // Actual Content Background
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            color: const Color(0xFF0D1B2A), // Dark Night Blue
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B263B).withOpacity(0.9),
                    border: Border.all(
                      color: const Color(0xFF415A77).withOpacity(0.9),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    title,
                    style: GoogleFonts.pressStart2p(
                      color: const Color(0xFFE0E1DD),
                      fontSize: titleFontSize ?? 24,
                      shadows: [
                        const Shadow(
                          color: Color(0xFF000000),
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                PixelButton(
                  label: context.watch<LanguageService>().translate('play_now'),
                  color: const Color(0xFF415A77),
                  soundPath: soundPath,
                  onPressed: onPressed,
                  useGlobalPlayer: useGlobalPlayer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
