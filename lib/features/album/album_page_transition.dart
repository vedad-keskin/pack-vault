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

    // Skip transform entirely when nearly settled to avoid artifacts
    if (absPos < 0.005) return child;

    // Slight scale reduction for pages going out
    final scale = 1.0 - (absPos * 0.06);

    // Gentler 3D rotation around Y axis
    final rotationY = pos * 0.3;

    // Shadow opacity based on position
    final shadowOpacity = (absPos * 0.35).clamp(0.0, 0.3);

    return Transform(
      alignment: pos < 0 ? Alignment.centerRight : Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // lighter perspective
        ..rotateY(rotationY)
        ..scaleByVector3(Vector3(scale, scale, 1.0)),
      child: Stack(
        children: [
          child,
          // Shadow overlay for depth
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: shadowOpacity,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
