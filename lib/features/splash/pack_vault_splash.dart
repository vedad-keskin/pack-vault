import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pack_vault/firebase_options.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';
import 'package:pack_vault/data/repositories/card_repository.dart';

/// Premium football-themed splash screen.
/// Animates the logo while initializing Firebase + loading card data.
class PackVaultSplash extends StatefulWidget {
  final Widget Function(bool firebaseReady) nextBuilder;
  final Duration minDuration;

  const PackVaultSplash({
    super.key,
    required this.nextBuilder,
    this.minDuration = const Duration(milliseconds: 3400),
  });

  @override
  State<PackVaultSplash> createState() => _PackVaultSplashState();
}

class _PackVaultSplashState extends State<PackVaultSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _navigated = false;
  bool _firebaseReady = false;
  String _statusText = 'Warming up...';
  double _initProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.minDuration,
    )..forward();

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _initialize();
  }

  Future<void> _initialize() async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Load card database
    _updateStatus('Loading card database...', 0.15);
    await CardRepository.loadCards();
    _updateStatus('Cards loaded', 0.35);

    // Step 2: Try Firebase
    _updateStatus('Connecting to Firebase...', 0.5);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseDatasource.enablePersistence();
      _firebaseReady = true;
      _updateStatus('Connected!', 0.9);
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      _updateStatus('Offline mode', 0.9);
    }

    _updateStatus(_firebaseReady ? 'Ready!' : 'Playing offline', 1.0);

    // Wait for minimum splash duration
    final elapsed = stopwatch.elapsed;
    final remaining = widget.minDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    // Wait a bit more for the fade-out animation
    await Future.delayed(const Duration(milliseconds: 500));
    _goNext();
  }

  void _updateStatus(String text, double progress) {
    if (!mounted) return;
    setState(() {
      _statusText = text;
      _initProgress = progress;
    });
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => widget.nextBuilder(_firebaseReady),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_initProgress >= 1.0) _goNext();
        },
        child: Stack(
          children: [
            // === Background: dark pitch gradient ===
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF040D1A),
                      Color(0xFF0A1628),
                      Color(0xFF0D1F35),
                    ],
                  ),
                ),
              ),
            ),

            // === Animated football particles ===
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballParticlePainter(time: t),
              ),
            ),

            // === Stadium glow behind logo ===
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(builder: (_) {
                  final glowIn = _easeOut(_interval(t, 0.05, 0.3));
                  final pulse = (sin(t * pi * 4) * 0.5 + 0.5);
                  final glowAlpha = (0.15 + 0.12 * pulse) * glowIn;
                  final glowOut = t > 0.9 ? (1.0 - _interval(t, 0.9, 1.0)) : 1.0;
                  return CustomPaint(
                    painter: _StadiumGlowPainter(
                      opacity: (glowAlpha * glowOut).clamp(0.0, 0.4),
                    ),
                  );
                }),
              ),
            ),

            // === Pitch lines overlay ===
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(builder: (_) {
                  final lineAlpha = _easeOut(_interval(t, 0.1, 0.4));
                  final lineOut = t > 0.88 ? (1.0 - _interval(t, 0.88, 1.0)) : 1.0;
                  return CustomPaint(
                    painter: _PitchLinePainter(
                      opacity: (lineAlpha * lineOut * 0.08).clamp(0.0, 0.1),
                    ),
                  );
                }),
              ),
            ),

            // === Vignette ===
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // === Main content ===
            SafeArea(
              child: Center(
                child: Builder(builder: (_) {
                  // Logo animations
                  final logoScale = _easeOutBack(_interval(t, 0.05, 0.35));
                  final logoFade = _easeOut(_interval(t, 0.02, 0.2));

                  // Title animations
                  final titleFade = _easeOut(_interval(t, 0.15, 0.4));
                  final titleSlide = 1.0 - _easeOut(_interval(t, 0.15, 0.4));

                  // Subtitle
                  final subFade = _easeOut(_interval(t, 0.25, 0.5));

                  // Progress bar
                  final barFade = _easeOut(_interval(t, 0.2, 0.4));

                  // Fire shimmer on title
                  final shimmer = sin(t * pi * 6) * 0.5 + 0.5;

                  // Fade everything out at end
                  final fadeOut = t > 0.88
                      ? (1.0 - _easeIn(_interval(t, 0.88, 1.0)))
                      : 1.0;

                  return Opacity(
                    opacity: fadeOut.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // === Logo ===
                        Opacity(
                          opacity: logoFade.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: (0.6 + 0.4 * logoScale).clamp(0.0, 1.15),
                            child: _LogoFrame(shimmer: shimmer),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // === Title: PACK VAULT ===
                        Opacity(
                          opacity: titleFade.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, titleSlide * 20),
                            child: _FireTitle(shimmer: shimmer),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // === Subtitle ===
                        Opacity(
                          opacity: subFade.clamp(0.0, 1.0),
                          child: Text(
                            'STICKER ALBUM TRACKER',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              letterSpacing: 3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // === Progress bar ===
                        Opacity(
                          opacity: barFade.clamp(0.0, 1.0),
                          child: _FireProgressBar(
                            value: _initProgress,
                            shimmer: shimmer,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // === Status text ===
                        Opacity(
                          opacity: barFade.clamp(0.0, 1.0),
                          child: _StatusText(text: _statusText, phase: t),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logo Frame ──────────────────────────────────────────────────────
class _LogoFrame extends StatelessWidget {
  final double shimmer;
  const _LogoFrame({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.firePrimary.withValues(alpha: 0.15 + 0.1 * shimmer),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.goalGold.withValues(alpha: 0.08 + 0.05 * shimmer),
            blurRadius: 60,
            spreadRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/logo.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─── Fire Title ──────────────────────────────────────────────────────
class _FireTitle extends StatelessWidget {
  final double shimmer;
  const _FireTitle({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            const Color(0xFFFF3D00),
            const Color(0xFFFF6D00),
            const Color(0xFFFFD700),
            const Color(0xFFFF6D00),
            const Color(0xFFFF3D00),
          ],
          stops: [
            0.0,
            (0.25 + shimmer * 0.15).clamp(0.0, 1.0),
            0.5,
            (0.75 - shimmer * 0.15).clamp(0.0, 1.0),
            1.0,
          ],
        ).createShader(bounds);
      },
      child: Text(
        'PACK VAULT',
        style: GoogleFonts.orbitron(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 4,
        ),
      ),
    );
  }
}

// ─── Progress Bar ────────────────────────────────────────────────────
class _FireProgressBar extends StatelessWidget {
  final double value;
  final double shimmer;
  const _FireProgressBar({required this.value, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      width: 260,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          widthFactor: max(0.02, v),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: [
                  AppColors.firePrimary,
                  AppColors.fireSecondary,
                  Color.lerp(AppColors.goalGold, AppColors.fireSecondary, shimmer)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.firePrimary.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Text ─────────────────────────────────────────────────────
class _StatusText extends StatelessWidget {
  final String text;
  final double phase;
  const _StatusText({required this.text, required this.phase});

  @override
  Widget build(BuildContext context) {
    final dots = ((phase * 8).floor() % 4);
    final dotStr = text.endsWith('...') || text.endsWith('!')
        ? ''
        : List.filled(dots, '.').join();

    return Text(
      '$text$dotStr',
      style: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Stadium Glow Painter ────────────────────────────────────────────
class _StadiumGlowPainter extends CustomPainter {
  final double opacity;
  _StadiumGlowPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final center = Offset(size.width / 2, size.height / 2 - 60);
    final r = min(size.width, size.height) * 0.25;

    // Green stadium glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4CAF50).withValues(alpha: opacity),
          const Color(0xFF1B5E20).withValues(alpha: opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.5));
    canvas.drawCircle(center, r * 2.5, glow);

    // Inner warm glow (fire/gold)
    final warm = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6D00).withValues(alpha: opacity * 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.2));
    canvas.drawCircle(center, r * 1.2, warm);
  }

  @override
  bool shouldRepaint(covariant _StadiumGlowPainter old) => old.opacity != opacity;
}

// ─── Pitch Line Painter ──────────────────────────────────────────────
class _PitchLinePainter extends CustomPainter {
  final double opacity;
  _PitchLinePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Center circle
    canvas.drawCircle(Offset(cx, cy), 80, paint);

    // Center line
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()..color = const Color(0xFF4CAF50).withValues(alpha: opacity * 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PitchLinePainter old) => old.opacity != opacity;
}

// ─── Football Particles ──────────────────────────────────────────────
class _FootballParticlePainter extends CustomPainter {
  final double time;
  _FootballParticlePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rng = Random(42);
    const count = 35;

    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final particleSize = 1.5 + rng.nextDouble() * 2.5;

      // Slow drift upward
      final y = (baseY - time * speed * size.height * 0.15) % size.height;
      final x = baseX + sin(time * pi * 2 + i) * 8;

      // Fade based on position and time
      final fadeIn = (time * 3).clamp(0.0, 1.0);
      final fadeOut = time > 0.85 ? (1.0 - (time - 0.85) / 0.15) : 1.0;
      final alpha = (0.15 + 0.2 * rng.nextDouble()) * fadeIn * fadeOut;

      final isGold = i % 5 == 0;
      final color = isGold
          ? const Color(0xFFFFD700).withValues(alpha: alpha)
          : const Color(0xFF4CAF50).withValues(alpha: alpha * 0.7);

      canvas.drawCircle(Offset(x, y), particleSize, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _FootballParticlePainter old) => old.time != time;
}

// ─── Easing helpers ──────────────────────────────────────────────────
double _interval(double t, double start, double end) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return (t - start) / (end - start);
}

double _easeOut(double x) => 1 - pow(1 - x, 2).toDouble();
double _easeIn(double x) => pow(x, 2).toDouble();

double _easeOutBack(double x) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * pow(x - 1, 3).toDouble() + c1 * pow(x - 1, 2).toDouble();
}
