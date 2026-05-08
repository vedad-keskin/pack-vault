import 'package:flutter/material.dart';

class PixelSwipeIndicator extends StatefulWidget {
  final bool isRight;
  final VoidCallback onTap;
  final bool visible;

  const PixelSwipeIndicator({
    super.key,
    required this.isRight,
    required this.onTap,
    required this.visible,
  });

  @override
  State<PixelSwipeIndicator> createState() => _PixelSwipeIndicatorState();
}

class _PixelSwipeIndicatorState extends State<PixelSwipeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: widget.visible ? 0.8 : 0.0,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    widget.isRight ? _animation.value : -_animation.value,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      border: Border.all(color: Colors.white12, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      size: const Size(48, 48),
                      painter: _PixelArrowPainter(
                        isRight: widget.isRight,
                        isHovering: _isHovering,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelArrowPainter extends CustomPainter {
  final bool isRight;
  final bool isHovering;

  _PixelArrowPainter({required this.isRight, required this.isHovering});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isHovering ? Colors.amberAccent : Colors.white;
    final shadowPaint = Paint()..color = Colors.black;

    const double blockSize = 4.0;

    // Stylish double chevron pixel pattern
    final List<List<int>> pattern = isRight
        ? [
            [1, 0, 0, 0, 1, 0, 0, 0, 0],
            [1, 1, 0, 0, 1, 1, 0, 0, 0],
            [0, 1, 1, 0, 0, 1, 1, 0, 0],
            [0, 0, 1, 1, 0, 0, 1, 1, 0],
            [0, 0, 0, 1, 0, 0, 0, 1, 1],
            [0, 0, 1, 1, 0, 0, 1, 1, 0],
            [0, 1, 1, 0, 0, 1, 1, 0, 0],
            [1, 1, 0, 0, 1, 1, 0, 0, 0],
            [1, 0, 0, 0, 1, 0, 0, 0, 0],
          ]
        : [
            [0, 0, 0, 0, 1, 0, 0, 0, 1],
            [0, 0, 0, 1, 1, 0, 0, 1, 1],
            [0, 0, 1, 1, 0, 0, 1, 1, 0],
            [0, 1, 1, 0, 0, 1, 1, 0, 0],
            [1, 1, 0, 0, 0, 1, 0, 0, 0],
            [0, 1, 1, 0, 0, 1, 1, 0, 0],
            [0, 0, 1, 1, 0, 0, 1, 1, 0],
            [0, 0, 0, 1, 1, 0, 0, 1, 1],
            [0, 0, 0, 0, 1, 0, 0, 0, 1],
          ];

    void drawPattern(Paint p, Offset offset) {
      for (int y = 0; y < pattern.length; y++) {
        for (int x = 0; x < pattern[y].length; x++) {
          if (pattern[y][x] == 1) {
            canvas.drawRect(
              Rect.fromLTWH(
                offset.dx + (x * blockSize),
                offset.dy + (y * blockSize),
                blockSize,
                blockSize,
              ),
              p,
            );
          }
        }
      }
    }

    double patternWidth = pattern[0].length * blockSize;
    double patternHeight = pattern.length * blockSize;
    Offset centerOffset = Offset(
      (size.width - patternWidth) / 2,
      (size.height - patternHeight) / 2,
    );

    // Draw shadow
    drawPattern(shadowPaint, centerOffset + const Offset(4, 4));

    // Draw main arrow
    drawPattern(paint, centerOffset);

    // Sparkle highlight
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.9);
    if (isRight) {
      canvas.drawRect(
        Rect.fromLTWH(centerOffset.dx + 28, centerOffset.dy + 16, 4, 4),
        highlightPaint,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(centerOffset.dx, centerOffset.dy + 16, 4, 4),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
