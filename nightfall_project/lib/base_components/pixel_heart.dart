import 'package:flutter/material.dart';

class PixelHeart extends StatelessWidget {
  final bool isFull;
  final double size;

  const PixelHeart({super.key, required this.isFull, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelHeartPainter(
          color: isFull
              ? const Color(0xFFE63946)
              : Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _PixelHeartPainter extends CustomPainter {
  final Color color;

  _PixelHeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // The heart is 7 pixels wide and 7 pixels high
    const int gridWidth = 7;
    const int gridHeight = 7;

    // Calculate pixel size to fit the container
    final double pixelSize = (size.width / gridWidth < size.height / gridHeight)
        ? size.width / gridWidth
        : size.height / gridHeight;

    // Calculate offsets to center the heart
    final double offsetX = (size.width - (gridWidth * pixelSize)) / 2;
    final double offsetY = (size.height - (gridHeight * pixelSize)) / 2;

    final path = Path();

    // Row 0: . X X . X X .
    path.addRect(
      Rect.fromLTWH(
        offsetX + 1 * pixelSize,
        offsetY + 0 * pixelSize,
        2 * pixelSize,
        1 * pixelSize,
      ),
    );
    path.addRect(
      Rect.fromLTWH(
        offsetX + 4 * pixelSize,
        offsetY + 0 * pixelSize,
        2 * pixelSize,
        1 * pixelSize,
      ),
    );

    // Row 1: X X X X X X X
    path.addRect(
      Rect.fromLTWH(
        offsetX + 0 * pixelSize,
        offsetY + 1 * pixelSize,
        7 * pixelSize,
        1 * pixelSize,
      ),
    );

    // Row 2: X X X X X X X
    path.addRect(
      Rect.fromLTWH(
        offsetX + 0 * pixelSize,
        offsetY + 2 * pixelSize,
        7 * pixelSize,
        1 * pixelSize,
      ),
    );

    // Row 3: X X X X X X X (Extra row for a "chunkier" heart)
    path.addRect(
      Rect.fromLTWH(
        offsetX + 0 * pixelSize,
        offsetY + 3 * pixelSize,
        7 * pixelSize,
        1 * pixelSize,
      ),
    );

    // Row 4: . X X X X X .
    path.addRect(
      Rect.fromLTWH(
        offsetX + 1 * pixelSize,
        offsetY + 4 * pixelSize,
        5 * pixelSize,
        1 * pixelSize,
      ),
    );

    // Row 5: . . X X X . .
    path.addRect(
      Rect.fromLTWH(
        offsetX + 2 * pixelSize,
        offsetY + 5 * pixelSize,
        3 * pixelSize,
        1 * pixelSize,
      ),
    );

    // Row 6: . . . X . . .
    path.addRect(
      Rect.fromLTWH(
        offsetX + 3 * pixelSize,
        offsetY + 6 * pixelSize,
        1 * pixelSize,
        1 * pixelSize,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
