import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'package:provider/provider.dart';

class ShamanInspectionDialog extends StatefulWidget {
  final String playerName;
  final WerewolfRole role;
  final VoidCallback onClose;

  const ShamanInspectionDialog({
    super.key,
    required this.playerName,
    required this.role,
    required this.onClose,
  });

  @override
  State<ShamanInspectionDialog> createState() => _ShamanInspectionDialogState();
}

class _ShamanInspectionDialogState extends State<ShamanInspectionDialog>
    with TickerProviderStateMixin {
  // ─── Shaman colour palette ───
  static const Color shamanColor = Color(0xFFE8720C);
  static const Color crimsonSmoke = Color(0xFF8B2500);
  static const Color emberGlow = Color(0xFFFF6B35);
  static const Color spiritRed = Color(0xFFB22222);
  static const Color deepVoid = Color(0xFF0A0E14);
  static const Color nightBlue = Color(0xFF0D1B2A);

  // ─── Animation controllers ───
  late AnimationController _pulseController;
  late AnimationController _revealController;
  late AnimationController _smokeController;
  late AnimationController _runeController;
  late AnimationController _shimmerController;
  late AnimationController _imageRevealController;

  // ─── Animations ───
  late Animation<double> _pulseAnimation;
  late Animation<double> _revealOpacity;
  late Animation<double> _revealScale;
  late Animation<double> _smokeFade;
  late Animation<double> _imageClip; // 0→1 vertical slash reveal
  late Animation<double> _imageScale; // 1.3→1.0 overshoot slam
  late Animation<double> _imageFlash; // 0→1→0 brightness flash

  // ─── State ───
  int _stage = 0;
  String _typedText = '';
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _revealOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _revealScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _smokeFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _runeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // ─── Image reveal: mystical radial portal + scale slam + flash ───
    _imageRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _imageClip = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageRevealController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _imageScale = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageRevealController,
        curve: const Interval(0.15, 0.85, curve: Curves.elasticOut),
      ),
    );
    _imageFlash =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
        ]).animate(
          CurvedAnimation(
            parent: _imageRevealController,
            curve: const Interval(0.0, 0.55),
          ),
        );

    _startChannelingSequence();
  }

  Future<void> _startChannelingSequence() async {
    final lang = context.read<LanguageService>();
    final channelingText = lang.translate('shaman_channeling');

    if (!mounted) return;
    final soundService = context.read<SoundSettingsService>();
    soundService.stopAll();

    if (!soundService.isMuted) {
      try {
        await soundService.playGlobal(
          'audio/werewolves/shamans_reckoning.mp3',
          loop: false,
        );
      } catch (_) {}
    }

    // Start typing the channeling text over the audio
    await _typeText(channelingText);

    // Wait for the remaining time until 8 seconds have elapsed from audio start.
    // Typing takes roughly (text.length * 35ms). We want the total delay
    // from audio start to reveal to be ~8000ms.
    // The typing + any overhead is roughly accounted for; we add extra wait.
    final typingDuration = channelingText.length * 35;
    final elapsed =
        typingDuration; // approximate ms elapsed since audio started
    final remainingDelay = 7500 - elapsed;
    if (remainingDelay > 0) {
      await Future.delayed(Duration(milliseconds: remainingDelay));
    }

    if (!mounted) return;
    setState(() => _stage = 1);
    _revealController.forward();
    // Start the image reveal slightly after the overall reveal begins
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _imageRevealController.forward();
    });
  }

  Future<void> _typeText(String text) async {
    _typedText = '';
    final completer = Completer<void>();
    int idx = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (idx < text.length && mounted) {
        setState(() => _typedText += text[idx]);
        idx++;
      } else {
        timer.cancel();
        completer.complete();
      }
    });
    return completer.future;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    _smokeController.dispose();
    _runeController.dispose();
    _shimmerController.dispose();
    _imageRevealController.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  Color _getRoleAllianceColor(int allianceId) {
    switch (allianceId) {
      case 1:
        return const Color(0xFF4CC9F0);
      case 2:
        return const Color(0xFFE63946);
      case 3:
        return const Color(0xFF9D4EDD);
      default:
        return Colors.white;
    }
  }

  // ═════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final roleColor = _getRoleAllianceColor(widget.role.allianceId);
    final screenH = MediaQuery.of(context).size.height;

    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: screenH * 0.9,
              decoration: BoxDecoration(
                color: deepVoid,
                border: Border.all(
                  color: shamanColor.withOpacity(0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shamanColor.withOpacity(_pulseAnimation.value),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: crimsonSmoke.withOpacity(
                      _pulseAnimation.value * 0.4,
                    ),
                    blurRadius: 56,
                    spreadRadius: 6,
                  ),
                  // Extra deep outer glow for dramatic presence
                  BoxShadow(
                    color: emberGlow.withOpacity(_pulseAnimation.value * 0.15),
                    blurRadius: 80,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: ClipRect(child: child),
            );
          },
          child: _stage == 0
              ? _buildChanneling(lang)
              : _buildRevealed(lang, roleColor),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  STAGE 0   ─  Channeling spirits
  // ═════════════════════════════════════════════════════════════════
  Widget _buildChanneling(LanguageService lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Triple-layer mystic gradient background ──
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [
                    const Color(0xFF1A0A0A).withOpacity(0.95),
                    const Color(0xFF120505),
                    const Color(0xFF0D0505),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.35, 0.6, 1.0],
                ),
              ),
            ),

            // ── Animated fog layer ──
            AnimatedBuilder(
              animation: _smokeController,
              builder: (context, _) {
                final t = _smokeController.value;
                return CustomPaint(
                  size: Size(w, h),
                  painter: _FogLayerPainter(
                    progress: t,
                    color1: crimsonSmoke.withOpacity(0.06),
                    color2: spiritRed.withOpacity(0.04),
                  ),
                );
              },
            ),

            // ── Vignette overlay ──
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // ── Rising crimson smoke particles (30) ──
            ...List.generate(30, (i) => _buildSmokeParticle(i, w, h)),

            // ── Orbital spirit wisps (12) ──
            ...List.generate(12, (i) => _buildSpiritWisp(i, w, h)),

            // ── Enhanced ritual circle with pentagram ──
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _runeController]),
                builder: (context, _) {
                  final glow = 0.3 + _pulseAnimation.value * 0.5;
                  return SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _RitualCirclePainter(
                        color: shamanColor.withOpacity(glow),
                        innerGlow: crimsonSmoke.withOpacity(glow * 0.6),
                        progress: _runeController.value,
                        emberColor: emberGlow.withOpacity(glow * 0.4),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Central shaman eye icon with concentric rings ──
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _runeController]),
                builder: (context, _) {
                  final breathe = 0.9 + _pulseAnimation.value * 0.1;
                  return Transform.scale(
                    scale: breathe,
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer decorative rune ring
                          Transform.rotate(
                            angle: _runeController.value * math.pi * 2,
                            child: CustomPaint(
                              size: const Size(110, 110),
                              painter: _RuneRingPainter(
                                color: shamanColor.withOpacity(
                                  0.3 + _pulseAnimation.value * 0.3,
                                ),
                              ),
                            ),
                          ),
                          // Inner glowing circle
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  shamanColor.withOpacity(0.15),
                                  crimsonSmoke.withOpacity(0.08),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(
                                color: shamanColor.withOpacity(
                                  0.5 + _pulseAnimation.value * 0.4,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: shamanColor.withOpacity(
                                    _pulseAnimation.value * 0.8,
                                  ),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: emberGlow.withOpacity(
                                    _pulseAnimation.value * 0.4,
                                  ),
                                  blurRadius: 48,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.visibility,
                              color: shamanColor.withOpacity(
                                0.6 + _pulseAnimation.value * 0.4,
                              ),
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Typed channeling text with shimmer ──
            Positioned(
              left: 24,
              right: 24,
              bottom: 100,
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [shamanColor, emberGlow, shamanColor],
                        stops: [
                          (_shimmerController.value - 0.2).clamp(0.0, 1.0),
                          _shimmerController.value,
                          (_shimmerController.value + 0.2).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      _typedText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.vt323(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 3,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: crimsonSmoke.withOpacity(0.9),
                            blurRadius: 16,
                          ),
                          Shadow(
                            color: shamanColor.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                          Shadow(
                            color: emberGlow.withOpacity(0.3),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Ornate header ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildOrnateHeader(lang),
            ),

            // ── Footer ──
            Positioned(bottom: 0, left: 0, right: 0, child: _buildFooter(lang)),
          ],
        );
      },
    );
  }

  // ── Turbulent smoke particles ──
  Widget _buildSmokeParticle(int index, double width, double height) {
    final random = math.Random(index);
    final startX = random.nextDouble();
    final size = 30.0 + random.nextDouble() * 90;
    final delay = random.nextDouble() * 1.5;
    final turbulence = 0.08 + random.nextDouble() * 0.12;
    // Alternate between crimson and ember colours
    final useEmber = index % 3 == 0;

    return AnimatedBuilder(
      animation: _smokeController,
      builder: (context, _) {
        final t = ((_smokeController.value + (delay / 3.0)) % 1.0);
        final y = 1.0 - t;
        // Turbulent sine-wave path
        final x =
            startX +
            math.sin(t * math.pi * 3 + index * 0.7) * turbulence +
            math.sin(t * math.pi * 5 + index * 1.3) * turbulence * 0.4;
        final opacity = (1.0 - t) * (t < 0.15 ? t / 0.15 : 1.0) * 0.45;
        final scale = 0.4 + t * 1.8;

        return Positioned(
          left: width * x - (size * scale) / 2,
          top: height * (0.25 + y * 0.75) - (size * scale) / 2,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (useEmber ? emberGlow : crimsonSmoke).withOpacity(0.6),
                      (useEmber ? shamanColor : spiritRed).withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Orbital spirit wisps ──
  Widget _buildSpiritWisp(int index, double width, double height) {
    final random = math.Random(index + 100);
    final orbitRadius = 0.12 + random.nextDouble() * 0.25;
    final phase = random.nextDouble() * math.pi * 2;
    final speed = 0.6 + random.nextDouble() * 0.8;
    final baseSize = 4.0 + random.nextDouble() * 5;

    return AnimatedBuilder(
      animation: _smokeController,
      builder: (context, _) {
        final angle = _smokeController.value * math.pi * 2 * speed + phase;
        final pulse =
            math.sin(_smokeController.value * math.pi * 4 + phase) * 0.5 + 0.5;
        final size = baseSize + pulse * 4;
        // Orbit around the center of the dialog
        final cx = width / 2;
        final cy = height * 0.42;
        final x = cx + math.cos(angle) * width * orbitRadius;
        final y = cy + math.sin(angle) * height * orbitRadius * 0.6;

        return Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shamanColor.withOpacity(0.3 + pulse * 0.5),
              boxShadow: [
                BoxShadow(
                  color: emberGlow.withOpacity(pulse * 0.7),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: shamanColor.withOpacity(pulse * 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  STAGE 1   ─  Role Revealed
  // ═════════════════════════════════════════════════════════════════
  static const double _imageAspectRatio = 880 / 1184;

  Widget _buildRevealed(LanguageService lang, Color roleColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Breathing radial background ──
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            final r = 0.9 + _pulseAnimation.value * 0.15;
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: r,
                  colors: [const Color(0xFF12202F), nightBlue, deepVoid],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),

        // ── Lingering smoke overlay (fades out during reveal) ──
        AnimatedBuilder(
          animation: _revealController,
          builder: (context, _) {
            if (_smokeFade.value <= 0) return const SizedBox.shrink();
            return IgnorePointer(
              child: Container(
                color: Color.lerp(
                  Colors.transparent,
                  const Color(0xFF1A0505),
                  _smokeFade.value * 0.5,
                )!,
              ),
            );
          },
        ),

        // ── Floating ember particles in reveal ──
        ...List.generate(8, (i) => _buildRevealEmber(i)),

        // ── Main content ──
        FadeTransition(
          opacity: _revealOpacity,
          child: ScaleTransition(
            scale: _revealScale,
            child: Column(
              children: [
                _buildOrnateHeader(lang),

                // ── "Spirits reveal the truth" shimmer banner ──
                _buildShimmerBanner(lang),

                // ── Role image with pixel frame ──
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      double imgW, imgH;
                      if (w / h > _imageAspectRatio) {
                        imgH = h;
                        imgW = h * _imageAspectRatio;
                      } else {
                        imgW = w;
                        imgH = w / _imageAspectRatio;
                      }
                      return Center(
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _revealController,
                            _imageRevealController,
                          ]),
                          builder: (context, _) {
                            final glow = _revealOpacity.value * 0.5;
                            final clip = _imageClip.value;
                            final imgScale = _imageScale.value;
                            final flash = _imageFlash.value;
                            return Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: shamanColor.withOpacity(glow),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: roleColor.withOpacity(glow * 0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: imgW,
                                height: imgH,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // Role image with fade+scale reveal
                                    Opacity(
                                      opacity: clip.clamp(0.0, 1.0),
                                      child: Transform.scale(
                                        scale: imgScale,
                                        child: Image.asset(
                                          widget.role.imagePath,
                                          width: imgW,
                                          height: imgH,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),

                                    // Brief ember flash overlay
                                    if (flash > 0)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Container(
                                            color: shamanColor.withOpacity(
                                              flash * 0.3,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // ── Corner bracket frame overlay ──
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _PixelFramePainter(
                                          color: shamanColor.withOpacity(
                                            0.4 + glow * 0.3,
                                          ),
                                          accentColor: roleColor.withOpacity(
                                            0.3 + glow * 0.2,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ── Player name overlay with scanlines ──
                                    Positioned(
                                      top: 12,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.0),
                                              Colors.black.withOpacity(0.8),
                                              Colors.black.withOpacity(0.8),
                                              Colors.black.withOpacity(0.0),
                                            ],
                                            stops: const [0.0, 0.15, 0.85, 1.0],
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          widget.playerName.toUpperCase(),
                                          style: GoogleFonts.vt323(
                                            color: Colors.white,
                                            fontSize: 28,
                                            letterSpacing: 4,
                                            shadows: [
                                              Shadow(
                                                color: shamanColor.withOpacity(
                                                  0.7,
                                                ),
                                                blurRadius: 14,
                                              ),
                                              Shadow(
                                                color: emberGlow.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 8,
                                              ),
                                              const Shadow(
                                                color: Colors.black,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),

                                    // ── Role name overlay ──
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              deepVoid.withOpacity(0.85),
                                              deepVoid,
                                            ],
                                            stops: const [0.0, 0.4, 1.0],
                                          ),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          28,
                                          20,
                                          20,
                                        ),
                                        child: _buildOrnateRoleBox(
                                          lang,
                                          roleColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                _buildFooter(lang),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Floating ember particles during reveal ──
  Widget _buildRevealEmber(int index) {
    final random = math.Random(index + 200);
    final startX = random.nextDouble();
    final startY = 0.5 + random.nextDouble() * 0.4;
    final speed = 0.4 + random.nextDouble() * 0.6;
    final phase = random.nextDouble() * math.pi * 2;

    return AnimatedBuilder(
      animation: _smokeController,
      builder: (context, _) {
        final t =
            (_smokeController.value * speed + phase / (math.pi * 2)) % 1.0;
        final pulse = math.sin(t * math.pi * 3) * 0.5 + 0.5;
        final size = 3.0 + pulse * 3;
        final x = startX + math.sin(t * math.pi * 2) * 0.05;
        final y = startY - t * 0.4;
        final opacity = (1.0 - t) * pulse * 0.6;

        return Positioned(
          left: MediaQuery.of(context).size.width * x,
          top: MediaQuery.of(context).size.height * y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emberGlow.withOpacity(opacity.clamp(0.0, 1.0)),
              boxShadow: [
                BoxShadow(
                  color: shamanColor.withOpacity(opacity.clamp(0.0, 0.4)),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Shimmer banner: "Spirits reveal the truth" ──
  Widget _buildShimmerBanner(LanguageService lang) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                shamanColor.withOpacity(0.15),
                crimsonSmoke.withOpacity(0.1),
              ],
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0xFF415A77), width: 2),
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [shamanColor, emberGlow, shamanColor, shamanColor],
                stops: [
                  0.0,
                  _shimmerController.value,
                  (_shimmerController.value + 0.15).clamp(0.0, 1.0),
                  1.0,
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Text(
              lang.translate('shaman_spirits_reveal'),
              style: GoogleFonts.pressStart2p(
                color: Colors.white,
                fontSize: 12,
                shadows: [
                  Shadow(color: shamanColor.withOpacity(0.6), blurRadius: 8),
                  Shadow(color: crimsonSmoke.withOpacity(0.4), blurRadius: 4),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  // ── Ornate role name box with double-border ──
  Widget _buildOrnateRoleBox(LanguageService lang, Color roleColor) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final breathe = _pulseAnimation.value;
        return Container(
          // Outer pixel border
          decoration: BoxDecoration(
            border: Border.all(
              color: roleColor.withOpacity(0.4 + breathe * 0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: roleColor.withOpacity(0.3 + breathe * 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: roleColor.withOpacity(0.15 + breathe * 0.1),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Container(
            // Inner content box
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  roleColor.withOpacity(0.15 + breathe * 0.05),
                  roleColor.withOpacity(0.25 + breathe * 0.05),
                  roleColor.withOpacity(0.15 + breathe * 0.05),
                ],
              ),
              border: Border.all(color: roleColor.withOpacity(0.9), width: 2.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              lang.translate(widget.role.translationKey).toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(
                color: roleColor,
                fontSize: 18,
                height: 1.3,
                shadows: [
                  Shadow(color: roleColor.withOpacity(0.8), blurRadius: 10),
                  Shadow(color: roleColor.withOpacity(0.5), blurRadius: 6),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS  ─  Header & Footer
  // ═════════════════════════════════════════════════════════════════

  Widget _buildOrnateHeader(LanguageService lang) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                shamanColor.withOpacity(0.25),
                crimsonSmoke.withOpacity(0.15),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: shamanColor.withOpacity(
                  0.4 + _pulseAnimation.value * 0.3,
                ),
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Ornate diamond divider ──
              _buildOrnateDivider(),
              const SizedBox(height: 6),
              // ── Title ──
              Text(
                lang.translate('shaman_vision_title').toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  color: shamanColor,
                  fontSize: 11,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: shamanColor.withOpacity(0.7), blurRadius: 10),
                    Shadow(color: crimsonSmoke.withOpacity(0.4), blurRadius: 6),
                    Shadow(color: emberGlow.withOpacity(0.2), blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _buildOrnateDivider(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrnateDivider() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final glowColor = Color.lerp(
          shamanColor.withOpacity(0.6),
          emberGlow,
          _pulseAnimation.value,
        )!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: glowColor,
                shape: BoxShape.circle,
              ),
            ),
            // Left line
            Container(
              width: 36,
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [glowColor.withOpacity(0), glowColor],
                ),
              ),
            ),
            // Central diamond
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: glowColor,
                  border: Border.all(
                    color: shamanColor.withOpacity(0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Right line
            Container(
              width: 36,
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [glowColor, glowColor.withOpacity(0)],
                ),
              ),
            ),
            // Right dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: glowColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(LanguageService lang) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: shamanColor.withOpacity(
                  0.2 + _pulseAnimation.value * 0.15,
                ),
                width: 1.5,
              ),
            ),
          ),
          child: PixelButton(
            label: _stage == 1
                ? lang.translate('understood_button')
                : lang.translate('processing'),
            color: _stage == 1 ? shamanColor : Colors.grey,
            onPressed: _stage == 1 ? widget.onClose : null,
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═════════════════════════════════════════════════════════════════════════════

/// Fog layer – subtle moving mist in the channeling background
class _FogLayerPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  _FogLayerPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final t = (progress + i * 0.2) % 1.0;
      final cx = size.width * (0.2 + math.sin(t * math.pi * 2 + i) * 0.3);
      final cy = size.height * (0.3 + math.cos(t * math.pi + i * 0.5) * 0.25);
      final radius = size.width * (0.25 + math.sin(t * math.pi + i) * 0.1);
      paint.shader = RadialGradient(
        colors: [i.isEven ? color1 : color2, Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FogLayerPainter old) =>
      old.progress != progress;
}

/// Enhanced ritual circle with pentagram, three rings, and rune segments
class _RitualCirclePainter extends CustomPainter {
  final Color color;
  final Color innerGlow;
  final double progress;
  final Color emberColor;

  _RitualCirclePainter({
    required this.color,
    required this.innerGlow,
    required this.progress,
    required this.emberColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // ── Outer glow ──
    final glowPaint = Paint()
      ..color = innerGlow.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, maxR * 0.88, glowPaint);

    // ── Three concentric rings ──
    for (int ring = 0; ring < 3; ring++) {
      final r = maxR * (0.55 + ring * 0.17);
      final strokeW = ring == 1 ? 2.0 : 1.2;
      final opacity = ring == 1 ? 0.7 : 0.35;
      final ringPaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW;
      canvas.drawCircle(center, r, ringPaint);
    }

    // ── Arc segments between outer two rings ──
    final arcPaint = Paint()
      ..color = emberColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final startAngle = (i / 6) * 2 * math.pi + progress * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxR * 0.80),
        startAngle,
        math.pi / 8,
        false,
        arcPaint,
      );
    }

    // ── Pentagram ──
    final pentaPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final pentaR = maxR * 0.52;
    final pentaVertices = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * math.pi - math.pi / 2 + progress * math.pi * 2;
      pentaVertices.add(
        Offset(
          center.dx + pentaR * math.cos(angle),
          center.dy + pentaR * math.sin(angle),
        ),
      );
    }
    // Draw the star (connect every other vertex)
    for (int i = 0; i < 5; i++) {
      final from = pentaVertices[i];
      final to = pentaVertices[(i + 2) % 5];
      canvas.drawLine(from, to, pentaPaint);
    }

    // ── 12 rotating rune segments along the outer ring ──
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + progress * 2 * math.pi;
      final r1 = maxR * 0.83;
      final r2 = maxR * 0.90;
      final x1 = center.dx + r1 * math.cos(angle);
      final y1 = center.dy + r1 * math.sin(angle);
      final x2 = center.dx + r2 * math.cos(angle);
      final y2 = center.dy + r2 * math.sin(angle);

      final segOpacity =
          0.3 + 0.5 * math.sin(progress * math.pi * 2 + i * 0.52).abs();
      final segPaint = Paint()
        ..color = color.withOpacity(segOpacity)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), segPaint);
    }

    // ── Center orb ──
    final orbGlow = Paint()
      ..color = color.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 6, orbGlow);
    final orbPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _RitualCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.innerGlow != innerGlow ||
        oldDelegate.progress != progress ||
        oldDelegate.emberColor != emberColor;
  }
}

/// Decorative rune ring drawn around the central shaman eye
class _RuneRingPainter extends CustomPainter {
  final Color color;

  _RuneRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;

    // Dashed outer ring
    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 16; i++) {
      final startAngle = (i / 16) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        math.pi / 24,
        false,
        dashPaint,
      );
    }

    // Small dots at cardinal positions
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi;
      final dx = center.dx + r * math.cos(angle);
      final dy = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuneRingPainter old) => old.color != color;
}

/// Pixel frame with corner brackets for the revealed role image
class _PixelFramePainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _PixelFramePainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bracketLen = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Top-left
    canvas.drawLine(Offset(0, bracketLen), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(bracketLen, 0), paint);
    canvas.drawLine(Offset(4, bracketLen - 4), const Offset(4, 4), accentPaint);
    canvas.drawLine(const Offset(4, 4), Offset(bracketLen - 4, 4), accentPaint);

    // Top-right
    canvas.drawLine(
      Offset(size.width, bracketLen),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - bracketLen, 0),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - bracketLen),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(bracketLen, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width, size.height - bracketLen),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - bracketLen, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelFramePainter old) =>
      old.color != color || old.accentColor != accentColor;
}
