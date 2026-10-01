import 'dart:math' as math;

import 'package:camera/camera.dart';

import '../domain/models/ball_detection.dart';
import '../domain/models/bounding_box.dart';
import '../domain/models/detection_config.dart';
import '../domain/models/detection_result.dart';
import '../domain/models/person_detection.dart';
import '../domain/models/point2d.dart';
import '../domain/models/pose_keypoints.dart';
import '../domain/repositories/pose_detector.dart';

/// DEVELOPMENT & TESTING ONLY.
///
/// Simulates realistic person, football, and foot trajectories (alternating left
/// and right toe taps) to validate the end-to-end computer vision pipeline, UI animations,
/// and Riverpod state controllers when testing without a physical model file.
///
/// NOTE: THIS IS NOT THE PRODUCTION DETECTOR.
/// Production builds must use [UltralyticsPoseDetector].
class MockPoseDetector implements PoseDetector {
  bool _isInitialized = false;
  double _timeCounter = 0.0;
  final math.Random _random = math.Random();

  @override
  bool get isInitialized => _isInitialized;

  @override
  String get name => 'MockPoseDetector (DEMO / DEV MODE)';

  @override
  Future<void> initialize({DetectionConfig? config}) async {
    // Simulate brief initialization delay
    await Future.delayed(const Duration(milliseconds: 300));
    _isInitialized = true;
    _timeCounter = 0.0;
  }

  @override
  Future<DetectionResult?> processFrame(
    CameraImage image, {
    int sensorOrientation = 90,
    bool isFrontCamera = false,
  }) async {
    if (!_isInitialized) return null;

    final stopwatch = Stopwatch()..start();

    // Advance simulation time (approximately 30ms step)
    _timeCounter += 0.08;

    // Fixed football position in normalized coordinates [0.50, 0.72] with radius 0.07
    const ballCenter = Point2D(x: 0.50, y: 0.72);
    const ballRadius = 0.07;
    final ballBox = BoundingBox.fromCenter(
      center: ballCenter,
      width: ballRadius * 2.0,
      height: ballRadius * 2.0,
    );

    final ball = BallDetection(
      boundingBox: ballBox,
      confidence: 0.88 + _random.nextDouble() * 0.08,
    );

    // Simulate alternating foot tapping pattern:
    // Left foot taps on even cycles, Right foot taps on odd cycles
    // Sine wave motion between rest position (away: y=0.55) and ball contact (contact: y=0.72)
    final cycle = math.sin(_timeCounter);
    final isLeftFootActive = (_timeCounter ~/ math.pi) % 2 == 0;

    double leftFootY;
    double rightFootY;

    if (isLeftFootActive) {
      // Left foot moves down to ball (y=0.71) when cycle > 0
      final progress = math.max(0.0, cycle);
      leftFootY =
          0.55 + progress * 0.16; // ranges from 0.55 (away) to 0.71 (contact)
      rightFootY = 0.55; // right foot stays back
    } else {
      // Right foot moves down to ball
      final progress = math.max(0.0, -cycle);
      rightFootY = 0.55 + progress * 0.16; // ranges from 0.55 to 0.71
      leftFootY = 0.55; // left foot stays back
    }

    final leftFoot = Point2D(x: 0.46, y: leftFootY);
    final rightFoot = Point2D(x: 0.54, y: rightFootY);

    final pose = PoseKeypoints(
      leftAnkle: leftFoot,
      leftAnkleConfidence: 0.85,
      rightAnkle: rightFoot,
      rightAnkleConfidence: 0.85,
      leftKnee: const Point2D(x: 0.45, y: 0.42),
      leftKneeConfidence: 0.88,
      rightKnee: const Point2D(x: 0.55, y: 0.42),
      rightKneeConfidence: 0.88,
      leftHip: const Point2D(x: 0.46, y: 0.28),
      leftHipConfidence: 0.90,
      rightHip: const Point2D(x: 0.54, y: 0.28),
      rightHipConfidence: 0.90,
    );

    final personBox = BoundingBox.fromLTRB(0.35, 0.10, 0.65, 0.80);
    final person = PersonDetection(
      boundingBox: personBox,
      confidence: 0.92,
      pose: pose,
    );

    // Simulate realistic inference duration (35 - 55 ms)
    final latency = Duration(milliseconds: 35 + _random.nextInt(20));
    stopwatch.stop();

    return DetectionResult(
      person: person,
      ball: ball,
      pose: pose,
      inferenceTime: latency,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}
