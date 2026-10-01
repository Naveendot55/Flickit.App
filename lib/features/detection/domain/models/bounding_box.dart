import 'dart:math' as math;

import 'point2d.dart';

/// Represents a bounding box in 2D space (normalized [0, 1] or absolute pixel values).
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory BoundingBox.fromLTRB(
    double left,
    double top,
    double right,
    double bottom,
  ) {
    return BoundingBox(
      left: math.min(left, right),
      top: math.min(top, bottom),
      right: math.max(left, right),
      bottom: math.max(top, bottom),
    );
  }

  factory BoundingBox.fromLTWH(
    double left,
    double top,
    double width,
    double height,
  ) {
    return BoundingBox.fromLTRB(left, top, left + width, top + height);
  }

  factory BoundingBox.fromCenter({
    required Point2D center,
    required double width,
    required double height,
  }) {
    final halfW = width / 2.0;
    final halfH = height / 2.0;
    return BoundingBox.fromLTRB(
      center.x - halfW,
      center.y - halfH,
      center.x + halfW,
      center.y + halfH,
    );
  }

  double get width => (right - left).abs();
  double get height => (bottom - top).abs();

  /// Center point of the bounding box.
  Point2D get center => Point2D(x: left + width / 2.0, y: top + height / 2.0);

  /// Approximate radius (half the average of width and height) for circular objects like a football.
  double get radius => (width + height) / 4.0;

  /// Check if a point is contained within this bounding box.
  bool contains(Point2D point) {
    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }

  @override
  String toString() =>
      'BoundingBox(l: ${left.toStringAsFixed(3)}, t: ${top.toStringAsFixed(3)}, r: ${right.toStringAsFixed(3)}, b: ${bottom.toStringAsFixed(3)})';
}
