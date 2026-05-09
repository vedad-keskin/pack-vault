import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pack_vault/firebase_options.dart';
import 'package:pack_vault/core/constants/app_constants.dart';
import 'package:pack_vault/data/datasources/firebase_datasource.dart';
import 'package:pack_vault/data/repositories/album_repository.dart';
import 'package:pack_vault/data/repositories/sticker_repository.dart';
import 'package:pack_vault/services/collection_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

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

    _updateStatus('Initializing', 0.15);

    // Pre-load the first album's data from bundled JSON
    _updateStatus('Loading albums', 0.3);
    final albums = AlbumRepository.albums;
    if (albums.isNotEmpty) {
      await StickerRepository.loadAlbum(albums.first);
    }

    _updateStatus('Connecting to Firebase', 0.55);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseDatasource.enablePersistence();
      _firebaseReady = true;

      // Pre-load cached collection data so album screen never shows 0%
      _updateStatus('Loading collection', 0.8);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && StickerRepository.isLoaded) {
        final collection = context.read<CollectionService>();
        await collection.preloadFromCache(
          user.uid,
          StickerRepository.activeAlbum!.id,
          StickerRepository.totalStickers,
        );
      }

      _updateStatus('Connected!', 0.9);
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      _updateStatus('Offline mode', 0.9);
    }

    _updateStatus('', 1.0);

    final elapsed = stopwatch.elapsed;
    final remaining = widget.minDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

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
                      Color(0xFF020A14),
                      Color(0xFF0A1628),
                      Color(0xFF081220),
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

            // === Stadium floodlight beams ===
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(builder: (_) {
                  final beamIn = _easeOut(_interval(t, 0.03, 0.25));
                  final sweep = sin(t * pi * 3) * 0.5 + 0.5;
                  final beamOut = t > 0.88 ? (1.0 - _interval(t, 0.88, 1.0)) : 1.0;
                  return CustomPaint(
                    painter: _FloodlightPainter(
                      opacity: (beamIn * beamOut * 0.35).clamp(0.0, 0.35),
                      sweep: sweep,
                    ),
                  );
                }),
              ),
            ),

            // === Stadium glow behind logo ===
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(builder: (_) {
                  final glowIn = _easeOut(_interval(t, 0.05, 0.3));
                  final pulse = (sin(t * pi * 4) * 0.5 + 0.5);
                  final glowAlpha = (0.18 + 0.14 * pulse) * glowIn;
                  final glowOut = t > 0.9 ? (1.0 - _interval(t, 0.9, 1.0)) : 1.0;
                  return CustomPaint(
                    painter: _StadiumGlowPainter(
                      opacity: (glowAlpha * glowOut).clamp(0.0, 0.45),
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
                      opacity: (lineAlpha * lineOut * 0.06).clamp(0.0, 0.08),
                    ),
                  );
                }),
              ),
            ),

            // === Light sweep overlay ===
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(builder: (_) {
                  final sweepPhase = (t * 2.5) % 1.0;
                  final sweepAlpha = t > 0.1 && t < 0.85 ? 0.06 : 0.0;
                  return CustomPaint(
                    painter: _LightSweepPainter(
                      phase: sweepPhase,
                      opacity: sweepAlpha,
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
                    center: const Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

            // === Main content ===
            SafeArea(
              child: Center(
                child: Builder(builder: (_) {
                  final logoScale = _easeOutBack(_interval(t, 0.05, 0.38));
                  final logoFade = _easeOut(_interval(t, 0.02, 0.2));
                  final titleFade = _easeOut(_interval(t, 0.18, 0.42));
                  final titleSlide = 1.0 - _easeOut(_interval(t, 0.18, 0.42));
                  final subFade = _easeOut(_interval(t, 0.28, 0.5));
                  final barFade = _easeOut(_interval(t, 0.22, 0.42));
                  final shimmer = sin(t * pi * 5) * 0.5 + 0.5;
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
                            scale: (0.5 + 0.5 * logoScale).clamp(0.0, 1.1),
                            child: _LogoDisplay(shimmer: shimmer),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // === Title: STICKR ===
                        Opacity(
                          opacity: titleFade.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, titleSlide * 16),
                            child: _FireTitle(shimmer: shimmer),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // === Subtitle ===
                        Opacity(
                          opacity: subFade.clamp(0.0, 1.0),
                          child: Text(
                            'STICKERS COLLECTING',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              letterSpacing: 4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 44),

                        // === Stadium scoreboard progress ===
                        Opacity(
                          opacity: barFade.clamp(0.0, 1.0),
                          child: _ScoreboardProgress(
                            value: _initProgress,
                            shimmer: shimmer,
                          ),
                        ),
                        const SizedBox(height: 16),

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

            // === Version label ===
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Builder(builder: (_) {
                final vFade = _easeOut(_interval(t, 0.35, 0.55));
                final fadeOut = t > 0.88
                    ? (1.0 - _easeIn(_interval(t, 0.88, 1.0)))
                    : 1.0;
                return Opacity(
                  opacity: (vFade * fadeOut).clamp(0.0, 1.0),
                  child: Text(
                    'Nightfall Project  v1.0.1',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logo Display ────────────────────────────────────────────────────
class _LogoDisplay extends StatelessWidget {
  final double shimmer;
  const _LogoDisplay({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E90FF).withValues(alpha: 0.15 + 0.12 * shimmer),
            blurRadius: 50,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.goalGold.withValues(alpha: 0.08 + 0.06 * shimmer),
            blurRadius: 70,
            spreadRadius: 15,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/logo.png',
          width: 170,
          height: 170,
          fit: BoxFit.cover,
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow shadow layer
        Transform.translate(
          offset: Offset(shimmer * 1.5, 0),
          child: Text(
            'STICKR',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.firePrimary.withValues(alpha: 0.3),
              letterSpacing: 6,
            ),
          ),
        ),
        // Main title with gradient
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFFF3D00),
                Color(0xFFFF6D00),
                Color(0xFFFFD700),
                Color(0xFFFF6D00),
                Color(0xFFFF3D00),
              ],
              stops: [
                0.0,
                (0.2 + shimmer * 0.15).clamp(0.0, 1.0),
                0.5,
                (0.8 - shimmer * 0.15).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Text(
            'STICKR',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Scoreboard Progress Bar ─────────────────────────────────────────
class _ScoreboardProgress extends StatelessWidget {
  final double value;
  final double shimmer;
  const _ScoreboardProgress({required this.value, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final pct = (v * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Percentage display
        Text(
          '$pct%',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: v >= 1.0
                ? AppColors.goalGold
                : AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        // Stadium-style segmented bar
        SizedBox(
          width: 280,
          height: 6,
          child: CustomPaint(
            painter: _SegmentedBarPainter(
              value: v,
              shimmer: shimmer,
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentedBarPainter extends CustomPainter {
  final double value;
  final double shimmer;
  _SegmentedBarPainter({required this.value, required this.shimmer});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const segments = 30;
    const gap = 2.0;
    final segW = (size.width - (segments - 1) * gap) / segments;

    for (int i = 0; i < segments; i++) {
      final x = i * (segW + gap);
      final segProgress = (i + 1) / segments;
      final filled = segProgress <= value;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, segW, size.height),
        const Radius.circular(1.5),
      );

      if (filled) {
        // Fire gradient for filled segments
        final segShimmer = (shimmer + i * 0.03) % 1.0;
        final color = Color.lerp(
          const Color(0xFFFF5500),
          const Color(0xFFFFD700),
          segShimmer,
        )!;
        final paint = Paint()..color = color;
        canvas.drawRRect(rect, paint);

        // Glow on last filled segment
        if ((segProgress - value).abs() < 1.0 / segments) {
          final glowPaint = Paint()
            ..color = const Color(0xFFFFD700).withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawRRect(rect, glowPaint);
        }
      } else {
        final paint = Paint()
          ..color = const Color(0xFF1A2A44).withOpacity(0.8);
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedBarPainter old) =>
      old.value != value || old.shimmer != shimmer;
}

// ─── Status Text ─────────────────────────────────────────────────────
class _StatusText extends StatelessWidget {
  final String text;
  final double phase;
  const _StatusText({required this.text, required this.phase});

  @override
  Widget build(BuildContext context) {
    final isTerminal = text.endsWith('!') || text == 'Playing offline';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isTerminal)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              text == 'Ready!' ? Icons.check_circle : Icons.cloud_off,
              color: text == 'Ready!'
                  ? AppColors.pitchGreenGlow
                  : AppColors.goalGoldDim,
              size: 14,
            ),
          ),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Floodlight Painter ──────────────────────────────────────────────
class _FloodlightPainter extends CustomPainter {
  final double opacity;
  final double sweep;
  _FloodlightPainter({required this.opacity, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    // Two stadium floodlight beams from top corners
    _drawBeam(canvas, size, size.width * (0.15 + sweep * 0.1), opacity * 0.8);
    _drawBeam(canvas, size, size.width * (0.85 - sweep * 0.1), opacity * 0.6);
    // Center subtle beam
    _drawBeam(canvas, size, size.width * 0.5, opacity * 0.3);
  }

  void _drawBeam(Canvas canvas, Size size, double x, double alpha) {
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: alpha),
          Colors.white.withValues(alpha: alpha * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromLTWH(x - 50, 0, 100, size.height * 0.6));

    final path = Path()
      ..moveTo(x - 8, 0)
      ..lineTo(x + 8, 0)
      ..lineTo(x + 60, size.height * 0.6)
      ..lineTo(x - 60, size.height * 0.6)
      ..close();
    canvas.drawPath(path, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _FloodlightPainter old) =>
      old.opacity != opacity || old.sweep != sweep;
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

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6D00).withValues(alpha: opacity * 0.5),
          const Color(0xFF4CAF50).withValues(alpha: opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.8));
    canvas.drawCircle(center, r * 2.8, glow);

    final warm = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6D00).withValues(alpha: opacity * 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.0));
    canvas.drawCircle(center, r * 1.0, warm);
  }

  @override
  bool shouldRepaint(covariant _StadiumGlowPainter old) => old.opacity != opacity;
}

// ─── Light Sweep Painter ─────────────────────────────────────────────
class _LightSweepPainter extends CustomPainter {
  final double phase;
  final double opacity;
  _LightSweepPainter({required this.phase, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final sweepX = phase * size.width * 1.4 - size.width * 0.2;
    const sweepW = 120.0;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(sweepX, 0, sweepW, size.height));

    canvas.drawRect(
      Rect.fromLTWH(sweepX, 0, sweepW, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LightSweepPainter old) =>
      old.phase != phase || old.opacity != opacity;
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

    canvas.drawCircle(Offset(cx, cy), 80, paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
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
    const count = 40;

    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.2 + rng.nextDouble() * 0.6;
      final particleSize = 1.0 + rng.nextDouble() * 2.5;

      final y = (baseY - time * speed * size.height * 0.12) % size.height;
      final x = baseX + sin(time * pi * 2 + i * 0.7) * 10;

      final fadeIn = (time * 3).clamp(0.0, 1.0);
      final fadeOut = time > 0.85 ? (1.0 - (time - 0.85) / 0.15) : 1.0;
      final alpha = (0.12 + 0.18 * rng.nextDouble()) * fadeIn * fadeOut;

      final isGold = i % 6 == 0;
      final isFire = i % 8 == 0;
      final Color color;
      if (isGold) {
        color = const Color(0xFFFFD700).withValues(alpha: alpha);
      } else if (isFire) {
        color = const Color(0xFFFF6D00).withValues(alpha: alpha * 0.8);
      } else {
        color = const Color(0xFF4CAF50).withValues(alpha: alpha * 0.6);
      }

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
