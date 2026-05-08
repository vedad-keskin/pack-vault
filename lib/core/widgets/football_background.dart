import 'package:flutter/material.dart';
import 'dart:math';
import 'package:pack_vault/core/constants/app_constants.dart';

/// Animated football-themed background with floating soccer ball particles
/// and stadium light beams. Inspired by nightfall_project's starfield.
class FootballBackground extends StatefulWidget {
  const FootballBackground({super.key});

  @override
  State<FootballBackground> createState() => _FootballBackgroundState();
}

class _FootballBackgroundState extends State<FootballBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FootballParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    for (int i = 0; i < 25; i++) {
      _particles.add(_FootballParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 3 + _random.nextDouble() * 5,
        speed: 0.1 + _random.nextDouble() * 0.3,
        opacity: 0.05 + _random.nextDouble() * 0.12,
        isFootball: _random.nextDouble() > 0.6,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FootballBgPainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FootballParticle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final bool isFootball;

  _FootballParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.isFootball,
  });
}

class _FootballBgPainter extends CustomPainter {
  final List<_FootballParticle> particles;
  final double animationValue;

  _FootballBgPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.pitchDark,
          AppColors.pitchDarker,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle stadium light beams from top
    _drawLightBeam(canvas, size, size.width * 0.2, 0.03);
    _drawLightBeam(canvas, size, size.width * 0.8, 0.025);

    // Floating particles
    for (var p in particles) {
      double currentY = (p.y - (animationValue * p.speed)) % 1.0;
      if (currentY < 0) currentY += 1.0;

      final px = p.x * size.width;
      final py = currentY * size.height;

      if (p.isFootball) {
        _drawFootball(canvas, px, py, p.size, p.opacity);
      } else {
        final paint = Paint()
          ..color = AppColors.pitchGreenGlow.withValues(alpha: p.opacity);
        canvas.drawCircle(Offset(px, py), p.size / 2, paint);
      }
    }

    // Subtle pitch line at bottom
    final linePaint = Paint()
      ..color = AppColors.pitchGreen.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.95),
      Offset(size.width, size.height * 0.95),
      linePaint,
    );
  }

  void _drawLightBeam(Canvas canvas, Size size, double x, double opacity) {
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x - 40, 0, 80, size.height * 0.5));
    final path = Path()
      ..moveTo(x - 10, 0)
      ..lineTo(x + 10, 0)
      ..lineTo(x + 50, size.height * 0.5)
      ..lineTo(x - 50, size.height * 0.5)
      ..close();
    canvas.drawPath(path, beamPaint);
  }

  void _drawFootball(Canvas canvas, double x, double y, double s, double o) {
    final paint = Paint()..color = Colors.white.withValues(alpha: o);
    canvas.drawCircle(Offset(x, y), s, paint);
    // Pentagon lines to suggest a football
    final linePaint = Paint()
      ..color = AppColors.pitchDark.withValues(alpha: o * 2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(x, y), s * 0.6, linePaint);
  }

  @override
  bool shouldRepaint(_FootballBgPainter oldDelegate) => true;
}
