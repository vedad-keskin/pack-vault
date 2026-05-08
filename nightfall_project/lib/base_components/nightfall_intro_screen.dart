import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:provider/provider.dart';

class NightfallIntroScreen extends StatefulWidget {
  final Widget next;
  final Duration totalDuration;

  const NightfallIntroScreen({
    super.key,
    required this.next,
    this.totalDuration = const Duration(milliseconds: 3200),
  });

  @override
  State<NightfallIntroScreen> createState() => _NightfallIntroScreenState();
}

class _NightfallIntroScreenState extends State<NightfallIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.totalDuration)
      ..forward();

    // Play intro sound (respects mute setting).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final sound = Provider.of<SoundSettingsService>(context, listen: false);
        // ignore: discarded_futures
        sound.playGlobal('audio/intro1.mp3', loop: false);
      } catch (_) {
        // No-op: sound is optional (e.g., in tests without provider).
      }
    });

    // Wait for intro animation to complete + extra time for fade-out to finish
    _navTimer = Timer(widget.totalDuration + const Duration(milliseconds: 400), () {
      _goNext();
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => widget.next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth fade transition - main screen fades in smoothly
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _goNext, // allow skipping
        child: Stack(
          children: [
            const Positioned.fill(child: PixelStarfieldBackground()),
            // Blood-red wash (werewolves vibe).
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final pulse = (sin(t * pi * 6) * 0.5 + 0.5);
                    final a = (0.18 + 0.18 * pulse) * (t < 0.1 ? (t / 0.1) : 1.0);
                    return ColoredBox(
                      color: const Color(0xFFB00020).withOpacity(a.clamp(0.0, 0.55)),
                    );
                  },
                ),
              ),
            ),
            // Subtle vignette / mood.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),
            // Blood moon glow behind the logo/title.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final moonIn = _easeOut(_interval(t, 0.06, 0.28));
                    final moonOut = (t > 0.88) ? (1.0 - _easeIn(_interval(t, 0.88, 1.0))) : 1.0;
                    final alpha = (0.0 + 0.55 * moonIn) * moonOut;
                    return CustomPaint(
                      painter: _BloodMoonPainter(opacity: alpha.clamp(0.0, 0.55)),
                    );
                  },
                ),
              ),
            ),
            // Scanlines + glitch flicker overlay.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  final flicker = (sin(t * pi * 18) * 0.5 + 0.5);
                  final opacity = (t < 0.15)
                      ? (t / 0.15)
                      : (t > 0.92)
                          ? ((1 - t) / 0.08)
                          : 1.0;
                  return CustomPaint(
                    painter: _ScanlineGlitchPainter(
                      time: t,
                      flicker: flicker,
                      opacity: opacity.clamp(0.0, 1.0),
                    ),
                  );
                },
              ),
            ),
            // Claw scratches (brief and nasty).
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final a = (t > 0.22 && t < 0.62)
                        ? (0.15 + 0.25 * (sin(t * pi * 10) * 0.5 + 0.5))
                        : 0.0;
                    return CustomPaint(
                      painter: _ScratchPainter(opacity: a.clamp(0.0, 0.4)),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;

                    // Logo pops in quickly, then settles.
                    final logoScale = _easeOutBack(_interval(t, 0.08, 0.42));
                    final logoFade = _easeOut(_interval(t, 0.02, 0.25));

                    // Title "glitch" offset.
                    final jitterPhase = (sin(t * pi * 26) * 0.5 + 0.5);
                    final jitter = (t > 0.18 && t < 0.68) ? (jitterPhase * 2.0) : 0.0;

                    // Progress bar fills.
                    final progress = _easeInOut(_interval(t, 0.18, 0.92));

                    // Fade everything out at the end (so transition looks clean).
                    final overallFade = (t > 0.9)
                        ? (1.0 - _easeIn(_interval(t, 0.9, 1.0)))
                        : 1.0;

                    return Opacity(
                      opacity: overallFade.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: logoFade.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: (0.75 + 0.25 * logoScale).clamp(0.0, 1.2),
                              child: _PixelLogoFrame(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    'assets/images/logo.jpg',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _GlitchTitle(
                            text: 'NIGHTFALL',
                            jitter: jitter,
                            intensity: _interval(t, 0.16, 0.7),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'PROJECT',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 14,
                              color: const Color(0xFFE0E1DD).withOpacity(0.8),
                              shadows: const [
                                Shadow(color: Colors.black, offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 34),
                          _PixelProgressBar(value: progress),
                          const SizedBox(height: 12),
                          _LoadingText(phase: t),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelLogoFrame extends StatelessWidget {
  final Widget child;
  const _PixelLogoFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            offset: const Offset(10, 10),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF778DA9).withOpacity(0.95),
          border: Border.all(color: const Color(0xFFE0E1DD).withOpacity(0.85), width: 2),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            border: Border.all(color: Colors.black.withOpacity(0.65), width: 2),
          ),
          padding: const EdgeInsets.all(6),
          child: child,
        ),
      ),
    );
  }
}

class _GlitchTitle extends StatelessWidget {
  final String text;
  final double jitter;
  final double intensity;

  const _GlitchTitle({
    required this.text,
    required this.jitter,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.pressStart2p(
      fontSize: 22,
      color: const Color(0xFFE0E1DD),
      shadows: const [
        Shadow(color: Colors.black, offset: Offset(2, 2)),
      ],
    );

    // Stronger + harsher for werewolves vibe.
    final amp = (intensity.clamp(0.0, 1.0)) * 3.4;

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(-jitter * amp, 0),
          child: Text(
            text,
            style: baseStyle.copyWith(
              color: const Color(0xFFFF1744).withOpacity(0.75),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(jitter * amp, 0),
          child: Text(
            text,
            style: baseStyle.copyWith(
              color: const Color(0xFF8E0000).withOpacity(0.65),
            ),
          ),
        ),
        Text(text, style: baseStyle),
      ],
    );
  }
}

class _PixelProgressBar extends StatelessWidget {
  final double value;
  const _PixelProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      width: 260,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            offset: const Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          border: Border.all(color: const Color(0xFF415A77), width: 2),
        ),
        padding: const EdgeInsets.all(2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: max(0.02, v),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF778DA9),
                border: Border.all(color: const Color(0xFFE0E1DD).withOpacity(0.85), width: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingText extends StatelessWidget {
  final double phase;
  const _LoadingText({required this.phase});

  @override
  Widget build(BuildContext context) {
    final dots = ((phase * 6).floor() % 4);
    final dotStr = List.filled(dots, '.').join();
    return Text(
      'loading$dotStr',
      style: GoogleFonts.vt323(
        fontSize: 22,
        color: const Color(0xFFE0E1DD).withOpacity(0.7),
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1))],
      ),
    );
  }
}

class _ScanlineGlitchPainter extends CustomPainter {
  final double time;
  final double flicker;
  final double opacity;

  _ScanlineGlitchPainter({
    required this.time,
    required this.flicker,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    // Scanlines.
    final scanPaint = Paint()..color = Colors.white.withOpacity(0.06 * opacity);
    const gap = 5.0;
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scanPaint);
    }

    // Occasional horizontal glitch bars.
    final burst = (time > 0.14 && time < 0.72) ? (0.55 + 0.75 * flicker) : 0.0;
    final barCount = (burst * 11).floor();
    if (barCount > 0) {
      final barPaint = Paint()..color = Colors.black.withOpacity(0.30 * opacity);
      final redPaint = Paint()..color = const Color(0xFFB00020).withOpacity(0.20 * opacity);
      for (int i = 0; i < barCount; i++) {
        final y = _noise(size.height, i, time) * size.height;
        final h = 10 + (_noise(22, i + 9, time) * 28);
        final dx = (_noise(1, i + 19, time) - 0.5) * 34;
        canvas.save();
        canvas.translate(dx, 0);
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), barPaint);
        if (i.isEven) {
          canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, max(2, h * 0.25)), redPaint);
        }
        canvas.restore();
      }
    }

    // Tiny vignette flicker.
    final fogPaint = Paint()
      ..color = Colors.black.withOpacity((0.10 + 0.10 * flicker) * opacity);
    canvas.drawRect(Offset.zero & size, fogPaint);
  }

  double _noise(double scale, int seed, double t) {
    // Deterministic-ish noise: seed + time (Random has no reseed API).
    final r = Random(1337 + seed + (t * 1000).floor());
    return r.nextDouble() * scale / max(1.0, scale);
  }

  @override
  bool shouldRepaint(covariant _ScanlineGlitchPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.flicker != flicker ||
        oldDelegate.opacity != opacity;
  }
}

double _interval(double t, double start, double end) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return (t - start) / (end - start);
}

double _easeOut(double x) => 1 - pow(1 - x, 2).toDouble();
double _easeIn(double x) => pow(x, 2).toDouble();
double _easeInOut(double x) => x < 0.5
    ? 2 * x * x
    : 1 - pow(-2 * x + 2, 2).toDouble() / 2;

double _easeOutBack(double x) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * pow(x - 1, 3).toDouble() + c1 * pow(x - 1, 2).toDouble();
}

class _BloodMoonPainter extends CustomPainter {
  final double opacity;
  _BloodMoonPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final center = Offset(size.width / 2, size.height / 2 - 90);
    final r = min(size.width, size.height) * 0.22;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF1744).withOpacity(opacity),
          const Color(0xFFB00020).withOpacity(opacity * 0.55),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.1));
    canvas.drawCircle(center, r * 2.1, glow);

    final moon = Paint()..color = const Color(0xFFB00020).withOpacity(opacity * 0.9);
    canvas.drawCircle(center, r, moon);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFFCDD2).withOpacity(opacity * 0.35);
    canvas.drawCircle(center, r, rim);
  }

  @override
  bool shouldRepaint(covariant _BloodMoonPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class _ScratchPainter extends CustomPainter {
  final double opacity;
  _ScratchPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final p = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(opacity)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;

    // Three diagonal “claws” on the right side.
    final x0 = size.width * 0.62;
    final y0 = size.height * 0.22;
    for (int i = 0; i < 3; i++) {
      final dx = i * 14.0;
      final dy = i * 18.0;
      canvas.drawLine(
        Offset(x0 + dx, y0 + dy),
        Offset(x0 + dx + size.width * 0.22, y0 + dy + size.height * 0.34),
        p,
      );
      // Small “tear” notch.
      canvas.drawLine(
        Offset(x0 + dx + size.width * 0.08, y0 + dy + size.height * 0.12),
        Offset(x0 + dx + size.width * 0.06, y0 + dy + size.height * 0.16),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

