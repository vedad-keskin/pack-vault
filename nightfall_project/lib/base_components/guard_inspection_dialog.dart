import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';

class GuardInspectionDialog extends StatefulWidget {
  final String playerName;
  final bool isWerewolf;
  final VoidCallback onClose;

  const GuardInspectionDialog({
    super.key,
    required this.playerName,
    required this.isWerewolf,
    required this.onClose,
  });

  @override
  State<GuardInspectionDialog> createState() => _GuardInspectionDialogState();
}

class _GuardInspectionDialogState extends State<GuardInspectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _imageController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _imageOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Entry Animation (Pop in)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    // Continuous Pulse Animation (Glow)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Image Reveal Animation (Slam in)
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _imageScaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _imageOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    // Start sequence
    _entryController.forward();
    _imageController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();

    final Color allianceColor = widget.isWerewolf
        ? const Color(0xFFE63946) // Red
        : const Color(0xFF06D6A0); // Green

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  border: Border.all(color: allianceColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: allianceColor.withOpacity(_pulseAnimation.value),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: allianceColor.withOpacity(
                        _pulseAnimation.value * 0.5,
                      ),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  color: allianceColor.withOpacity(0.2),
                  child: Text(
                    lang.translate('royal_guard_check').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pressStart2p(
                      color: allianceColor,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Image Content
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.playerName.toUpperCase(),
                          style: GoogleFonts.vt323(
                            color: Colors.white,
                            fontSize: 36,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: allianceColor.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isWerewolf
                              ? lang.translate('target_is_werewolf')
                              : lang.translate('target_is_villager'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.vt323(
                            color: allianceColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Image with Animated Reveal
                        AnimatedBuilder(
                          animation: _imageController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _imageScaleAnimation.value,
                              child: Opacity(
                                opacity: _imageOpacityAnimation.value,
                                child: AspectRatio(
                                  aspectRatio: 880 / 1034,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: allianceColor.withOpacity(0.4),
                                        width: 3,
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          widget.isWerewolf
                                              ? 'assets/images/guard_werewolves.png'
                                              : 'assets/images/guard_villagers.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [
                                        if (widget.isWerewolf)
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: PixelButton(
                    label: lang.translate('understood_button'),
                    color: allianceColor.withOpacity(0.8),
                    onPressed: widget.onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
