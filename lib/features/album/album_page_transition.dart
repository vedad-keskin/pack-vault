import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Album-like page transition for the PageView.
/// Creates a 3D page-curl effect with depth shadow.
class AlbumPageTransformer {
  /// Wraps a PageView child with the album flip transform.
  /// [position] is the page offset from the current page (-1 to 1).
  static Widget transform(Widget child, double position) {
    // Clamp position
    final pos = position.clamp(-1.0, 1.0);
    final absPos = pos.abs();

    // Slight scale reduction for pages going out
    final scale = 1.0 - (absPos * 0.08);

    // 3D rotation around Y axis for page-flip feel
    final rotationY = pos * 0.4; // radians

    // Depth translation
    final translateZ = -absPos * 60;

    // Shadow opacity based on position
    final shadowOpacity = (absPos * 0.4).clamp(0.0, 0.35);

    return Transform(
      alignment: pos < 0 ? Alignment.centerRight : Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002) // perspective
        ..rotateY(rotationY)
        ..scaleByVector3(Vector3(scale, scale, 1.0))
        ..translateByVector3(Vector3(0.0, 0.0, translateZ)),
      child: Stack(
        children: [
          child,
          // Shadow overlay for depth
          if (absPos > 0.01)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: shadowOpacity),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
