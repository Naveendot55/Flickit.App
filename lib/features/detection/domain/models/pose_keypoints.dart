import 'point2d.dart';

/// Semantic representation of pose keypoints extracted from YOLO Pose.
/// Encapsulates left/right ankle, knee, and hip keypoints with their detection confidence.
class PoseKeypoints {
  final Point2D? leftAnkle;
  final Point2D? rightAnkle;
  final double leftAnkleConfidence;
  final double rightAnkleConfidence;

  final Point2D? leftKnee;
  final Point2D? rightKnee;
  final double leftKneeConfidence;
  final double rightKneeConfidence;

  final Point2D? leftHip;
  final Point2D? rightHip;
  final double leftHipConfidence;
  final double rightHipConfidence;

  // Optional extended foot/toe keypoints if supported by 26/133 keypoint models
  final Point2D? leftBigToe;
  final Point2D? rightBigToe;
  final double leftBigToeConfidence;
  final double rightBigToeConfidence;

  const PoseKeypoints({
    this.leftAnkle,
    this.rightAnkle,
    this.leftAnkleConfidence = 0.0,
    this.rightAnkleConfidence = 0.0,
    this.leftKnee,
    this.rightKnee,
    this.leftKneeConfidence = 0.0,
    this.rightKneeConfidence = 0.0,
    this.leftHip,
    this.rightHip,
    this.leftHipConfidence = 0.0,
    this.rightHipConfidence = 0.0,
    this.leftBigToe,
    this.rightBigToe,
    this.leftBigToeConfidence = 0.0,
    this.rightBigToeConfidence = 0.0,
  });

  /// Best estimate for left foot contact point (prefers toe if available, else ankle).
  Point2D? get leftFootPoint => leftBigToe ?? leftAnkle;
  double get leftFootConfidence =>
      leftBigToe != null ? leftBigToeConfidence : leftAnkleConfidence;

  /// Best estimate for right foot contact point (prefers toe if available, else ankle).
  Point2D? get rightFootPoint => rightBigToe ?? rightAnkle;
  double get rightFootConfidence =>
      rightBigToe != null ? rightBigToeConfidence : rightAnkleConfidence;

  bool get hasLeftFoot => leftFootPoint != null && leftFootConfidence > 0.0;
  bool get hasRightFoot => rightFootPoint != null && rightFootConfidence > 0.0;

  @override
  String toString() =>
      'PoseKeypoints(L-Ankle: $leftAnkle ($leftAnkleConfidence), R-Ankle: $rightAnkle ($rightAnkleConfidence))';
}
