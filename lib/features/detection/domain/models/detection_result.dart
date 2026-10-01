import 'ball_detection.dart';
import 'person_detection.dart';
import 'pose_keypoints.dart';

/// Encapsulates the complete inference output for a single processed camera frame.
class DetectionResult {
  final PersonDetection? person;
  final BallDetection? ball;
  final PoseKeypoints? pose;
  final Duration inferenceTime;
  final DateTime timestamp;

  const DetectionResult({
    this.person,
    this.ball,
    this.pose,
    required this.inferenceTime,
    required this.timestamp,
  });

  bool get hasPerson => person != null;
  bool get hasBall => ball != null;
  bool get hasPose => pose != null;
  bool get hasLeftFoot => pose?.hasLeftFoot ?? false;
  bool get hasRightFoot => pose?.hasRightFoot ?? false;

  @override
  String toString() =>
      'DetectionResult(person: $hasPerson, ball: $hasBall, latency: ${inferenceTime.inMilliseconds}ms)';
}
