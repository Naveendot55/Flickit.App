/// Application-wide constants for Flickit Toe Tap Counter.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Flickit';
  static const String appSubtitle = 'TOE TAP TRAINER';

  // Target inference frames per second
  static const int targetInferenceFps = 12;

  // Maximum inference queue size (frame dropping policy: always process latest)
  static const int maxFrameQueueSize = 1;

  // Keypoint Indices for standard 17-keypoint COCO Pose format:
  // 0: nose, 1: left_eye, 2: right_eye, 3: left_ear, 4: right_ear,
  // 5: left_shoulder, 6: right_shoulder, 7: left_elbow, 8: right_elbow,
  // 9: left_wrist, 10: right_wrist, 11: left_hip, 12: right_hip,
  // 13: left_knee, 14: right_knee, 15: left_ankle, 16: right_ankle
  static const int cocoLeftAnkleIdx = 15;
  static const int cocoRightAnkleIdx = 16;
  static const int cocoLeftKneeIdx = 13;
  static const int cocoRightKneeIdx = 14;

  // Model Asset Paths
  static const String defaultModelPath = 'assets/models/yolov8n_pose.tflite';
  static const String defaultLabelsPath = 'assets/models/labels.txt';
}
