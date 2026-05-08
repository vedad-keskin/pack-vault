import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';

class GuardScannerDialog extends StatefulWidget {
  final String playerName;
  final bool isWerewolf;
  final VoidCallback onClose;

  const GuardScannerDialog({
    super.key,
    required this.playerName,
    required this.isWerewolf,
    required this.onClose,
  });

  @override
  State<GuardScannerDialog> createState() => _GuardScannerDialogState();
}

class _GuardScannerDialogState extends State<GuardScannerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  int _stage = 0; // 0: Init, 1: Scanning, 2: Result

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Sequence
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _stage = 1);
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _scanController.stop();
        setState(() => _stage = 2);
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final isThreat = widget.isWerewolf;
    final primaryColor = _stage == 2
        ? (isThreat ? const Color(0xFFE63946) : const Color(0xFF06D6A0))
        : const Color(0xFFFFD166); // Yellow default

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          border: Border.all(color: primaryColor, width: 4),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: primaryColor.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.translate('royal_guard_check'),
                    style: GoogleFonts.vt323(color: primaryColor, fontSize: 18),
                  ),
                  if (_stage < 2)
                    Text(
                      _stage == 0
                          ? lang.translate('approaching')
                          : lang.translate('searching'),
                      style: GoogleFonts.pressStart2p(
                        color: primaryColor,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),

            // Main Display
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Grid Background
                  CustomPaint(
                    painter: GridPainter(color: primaryColor.withOpacity(0.1)),
                  ),

                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile Icon Placeholder
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: primaryColor.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.playerName.toUpperCase(),
                          style: GoogleFonts.vt323(
                            color: Colors.white,
                            fontSize: 32,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_stage < 2)
                          Text(
                            lang.translate('looking_for_mark'),
                            style: GoogleFonts.vt323(
                              color: primaryColor,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Scanning Line
                  if (_stage < 2)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Positioned(
                          top:
                              _scanController.value * 280, // Approximate height
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Result Overlay
                  if (_stage == 2)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                  color: Colors.black,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isThreat
                                          ? Icons.warning_amber_rounded
                                          : Icons.verified_user_outlined,
                                      color: primaryColor,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    // Modified text as requested
                                    Text(
                                      isThreat
                                          ? lang.translate('monster_found')
                                          : lang.translate('citizen_cleared'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.pressStart2p(
                                        color: primaryColor,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Added W and V symbols and modified subject text
                                    Text(
                                      isThreat
                                          ? lang.translate('target_is_werewolf')
                                          : lang.translate(
                                              'target_is_villager',
                                            ),
                                      style: GoogleFonts.vt323(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isThreat ? "W" : "V",
                                      style: GoogleFonts.pressStart2p(
                                        color: primaryColor,
                                        fontSize: 40,
                                        shadows: [
                                          Shadow(
                                            color: primaryColor.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PixelButton(
                label: _stage == 2
                    ? lang.translate('close_button')
                    : lang.translate('processing'),
                color: _stage == 2 ? const Color(0xFF415A77) : Colors.grey,
                onPressed: _stage == 2 ? widget.onClose : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 20.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
