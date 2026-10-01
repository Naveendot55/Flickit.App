import 'dart:math' as math;

/// Represents a 2D coordinate point (normalized or pixel-space).
class Point2D {
  final double x;
  final double y;

  const Point2D({required this.x, required this.y});

  /// Euclidean distance to another point.
  double distanceTo(Point2D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Point2D operator +(Point2D other) => Point2D(x: x + other.x, y: y + other.y);
  Point2D operator -(Point2D other) => Point2D(x: x - other.x, y: y - other.y);
  Point2D operator *(double scalar) => Point2D(x: x * scalar, y: y * scalar);
  Point2D operator /(double scalar) => Point2D(x: x / scalar, y: y / scalar);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point2D &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 1e-6 &&
          (y - other.y).abs() < 1e-6;

  @override
  int get hashCode => Object.hash(x.toStringAsFixed(6), y.toStringAsFixed(6));

  @override
  String toString() =>
      'Point2D(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)})';
}
