import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pack_vault/core/constants/app_constants.dart';

/// Stadium floodlight animation for the login screen.
class StadiumIntro extends StatefulWidget {
  const StadiumIntro({super.key});

  @override
  State<StadiumIntro> createState() => _StadiumIntroState();
}

class _StadiumIntroState extends State<StadiumIntro>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
          painter: _StadiumPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _StadiumPainter extends CustomPainter {
  final double t;
  _StadiumPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark gradient background
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.5),
        radius: 1.5,
        colors: [
          Color(0xFF0F2027),
          AppColors.pitchDarker,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Animated light beams sweeping from top
    final beamCount = 5;
    for (int i = 0; i < beamCount; i++) {
      final phase = (t + i / beamCount) % 1.0;
      final x = size.width * (0.1 + 0.8 * phase);
      final sway = sin(t * pi * 2 + i) * 20;
      _drawBeam(canvas, size, x + sway, 0.015 + 0.01 * sin(phase * pi));
    }

    // Pitch grass gradient at bottom
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.pitchGreen.withValues(alpha: 0.15),
          AppColors.pitchGreen.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      grassPaint,
    );

    // Subtle pitch line markings
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.92),
      30,
      linePaint..style = PaintingStyle.stroke,
    );
  }

  void _drawBeam(Canvas canvas, Size size, double x, double opacity) {
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromLTWH(x - 30, 0, 60, size.height * 0.6));

    final path = Path()
      ..moveTo(x - 5, 0)
      ..lineTo(x + 5, 0)
      ..lineTo(x + 40, size.height * 0.6)
      ..lineTo(x - 40, size.height * 0.6)
      ..close();
    canvas.drawPath(path, beamPaint);
  }

  @override
  bool shouldRepaint(_StadiumPainter oldDelegate) => true;
}
