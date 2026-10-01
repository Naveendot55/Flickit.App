import 'bounding_box.dart';
import 'pose_keypoints.dart';

/// Represents a detected person with bounding box, confidence, and pose keypoints.
class PersonDetection {
  final BoundingBox boundingBox;
  final double confidence;
  final PoseKeypoints pose;

  const PersonDetection({
    required this.boundingBox,
    required this.confidence,
    required this.pose,
  });

  @override
  String toString() =>
      'PersonDetection(confidence: ${confidence.toStringAsFixed(2)}, bbox: $boundingBox, pose: $pose)';
}
