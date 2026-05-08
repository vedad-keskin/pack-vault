import 'package:flutter/material.dart';
import 'dart:math';

class PixelStarfieldBackground extends StatefulWidget {
  const PixelStarfieldBackground({super.key});

  @override
  State<PixelStarfieldBackground> createState() =>
      _PixelStarfieldBackgroundState();
}

class _PixelStarfieldBackgroundState extends State<PixelStarfieldBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Generate stars
    for (int i = 0; i < 50; i++) {
      _stars.add(
        Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextBool() ? 2 : 4,
          speed: 0.2 + _random.nextDouble() * 0.5,
        ),
      );
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
          painter: StarPainter(_stars, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class Star {
  double x;
  double y;
  final double size;
  final double speed;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1B263B), // Deep Midnight Blue
          Color(0xFF000000), // Pure Black
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final starPaint = Paint()..color = Colors.white.withOpacity(0.4);

    for (var star in stars) {
      // Calculate animated Y position
      // Move downwards
      double currentY = (star.y + (animationValue * star.speed)) % 1.0;

      canvas.drawRect(
        Rect.fromLTWH(
          star.x * size.width,
          currentY * size.height,
          star.size,
          star.size,
        ),
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(StarPainter oldDelegate) => true;
}
