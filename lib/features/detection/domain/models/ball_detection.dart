import 'bounding_box.dart';
import 'point2d.dart';

/// Represents a detected football in the camera frame.
class BallDetection {
  final BoundingBox boundingBox;
  final double confidence;

  const BallDetection({required this.boundingBox, required this.confidence});

  /// The center point of the football.
  Point2D get center => boundingBox.center;

  /// The effective radius of the football.
  double get radius => boundingBox.radius;

  @override
  String toString() =>
      'BallDetection(confidence: ${confidence.toStringAsFixed(2)}, center: $center, radius: ${radius.toStringAsFixed(3)})';
}
