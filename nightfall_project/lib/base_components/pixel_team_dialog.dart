import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PixelTeamDialog extends StatelessWidget {
  const PixelTeamDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black, // Outer black border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(8, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF778DA9), // Metallic frame
            border: Border.symmetric(
              vertical: const BorderSide(color: Color(0xFF415A77), width: 4),
              horizontal: const BorderSide(color: Color(0xFFE0E1DD), width: 4),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            color: const Color(0xFF0D1B2A), // Dark blueprint background
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle('NIGHTFALL PROJECT'),
                const SizedBox(height: 8),
                _buildSubtitle('TEAM CREDITS'),
                const SizedBox(height: 24),
                _buildCreditRow(
                  'LEAD DEVELOPER',
                  'Vedad Keskin',
                  labelColor: const Color(0xFF48CAE4), // Bright Cyan
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 15),
                _buildCreditRow(
                  'GAME DESIGN',
                  'Nidal Keskin',
                  valueColor: Colors.white,
                  labelColor: const Color(
                    0xFF9B5DE5,
                  ), // Vivid Lavender / Creative Purple
                ),
                const SizedBox(height: 15),
                _buildCreditRow(
                  'ART DESIGN',
                  'Iman-Bejana Keskin',
                  labelColor: const Color(0xFFF72585), // Neon Pink
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 15),
                _buildCreditRow(
                  'QA TESTING',
                  'Amar Bešić',
                  labelColor: const Color(0xFF06D6A0), // Emerald Green
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 15),
                _buildCreditRow(
                  'HOTSPOT PROVIDER',
                  'Said Keskin',
                  labelColor: const Color(0xFFFF9F1C), // Orange
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 15),
                
                _buildCreditRow(
  'CERTIFIED HATER',
  'Benjamin Cero',
  labelColor: const Color(0xFFFF595E), // angry red 😄
  valueColor: Colors.white,
),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E1DD)),
                    ),
                    child: Text(
                      'CLOSE',
                      style: GoogleFonts.pressStart2p(
                        color: const Color(0xFFE0E1DD),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.pressStart2p(
        color: const Color(0xFFE0E1DD),
        fontSize: 18,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: GoogleFonts.pressStart2p(
        color: const Color(0xFF415A77),
        fontSize: 10,
        letterSpacing: 2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCreditRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: GoogleFonts.pressStart2p(
                color: labelColor ?? const Color(0xFF415A77),
                fontSize: 10,
              ),
            ),
          if (label.isNotEmpty) const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.vt323(
              color: valueColor ?? Colors.white,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
