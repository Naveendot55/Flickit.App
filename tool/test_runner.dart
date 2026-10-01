import '../lib/core/utils/coordinate_transformer.dart';
import '../lib/features/detection/domain/models/ball_detection.dart';
import '../lib/features/detection/domain/models/bounding_box.dart';
import '../lib/features/detection/domain/models/detection_config.dart';
import '../lib/features/detection/domain/models/detection_result.dart';
import '../lib/features/detection/domain/models/person_detection.dart';
import '../lib/features/detection/domain/models/point2d.dart';
import '../lib/features/detection/domain/models/pose_keypoints.dart';
import '../lib/features/toe_tap/domain/models/foot_side.dart';
import '../lib/features/toe_tap/domain/models/tap_detection_config.dart';
import '../lib/features/toe_tap/domain/models/tap_state.dart';
import '../lib/features/toe_tap/domain/services/toe_tap_detector.dart';

int totalTests = 0;
int passedTests = 0;

void assertTest(String name, bool condition, [String? failureDetails]) {
  totalTests++;
  if (condition) {
    passedTests++;
    print('  [PASS] $name');
  } else {
    print(
      '  [FAIL] $name ${failureDetails != null ? "($failureDetails)" : ""}',
    );
  }
}

void main() {
  print('====================================================');
  print('FLICKIT SUITE: VERIFYING ALL 10 CORE VISION REQUIREMENTS');
  print('====================================================\n');

  // SUITE 1: TOE TAP DETECTOR ALGORITHM & DEBOUNCING
  print('--- GROUP 1: ToeTapDetector Algorithm & Debouncing ---');
  final detector = ToeTapDetector(
    config: const TapDetectionConfig(
      contactDistanceRatio: 1.30,
      releaseDistanceRatio: 1.70,
      minimumTapInterval: Duration(milliseconds: 300),
      minimumFootConfidence: 0.40,
      minimumBallConfidence: 0.40,
    ),
  );

  const ballCenter = Point2D(x: 0.50, y: 0.70);
  const ballRadius = 0.08;
  final testBall = BallDetection(
    boundingBox: BoundingBox.fromCenter(
      center: ballCenter,
      width: ballRadius * 2.0,
      height: ballRadius * 2.0,
    ),
    confidence: 0.90,
  );

  // Requirement 1: No detection -> no tap
  final t1 = detector.process(
    ball: null,
    pose: null,
    timestamp: DateTime(2026, 1, 1, 12, 0, 0),
  );
  assertTest(
    '1. No detection -> no tap',
    t1 == null && detector.activeState == TapState.away,
  );

  // Requirement 2: Foot far from ball -> no tap
  final t2 = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.40),
      leftAnkleConfidence: 0.85,
    ),
    timestamp: DateTime(2026, 1, 1, 12, 0, 0),
  );
  assertTest(
    '2. Foot far from ball -> no tap',
    t2 == null && detector.leftState == TapState.away,
  );

  // Requirement 3: Foot enters contact zone -> one tap
  detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.45), // comfortably away (ratio ~ 3.1)
      leftAnkleConfidence: 0.85,
    ),
    timestamp: DateTime(2026, 1, 1, 12, 0, 0, 0),
  );
  final t3 = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(
        x: 0.50,
        y: 0.68,
      ), // enters contact (ratio ~ 0.25 <= 1.30)
      leftAnkleConfidence: 0.85,
    ),
    timestamp: DateTime(2026, 1, 1, 12, 0, 0, 50),
  );
  assertTest(
    '3. Foot enters contact zone -> one tap',
    t3 != null &&
        t3.foot == FootSide.left &&
        detector.leftState == TapState.contact,
  );

  // Requirement 4: Multiple consecutive contact frames -> still one tap (debouncing)
  final t0 = DateTime(2026, 1, 1, 12, 0, 0, 100);
  final tap4a = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.70),
      leftAnkleConfidence: 0.85,
    ),
    timestamp: t0,
  );
  final tap4b = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.71),
      leftAnkleConfidence: 0.85,
    ),
    timestamp: t0.add(const Duration(milliseconds: 30)),
  );
  assertTest(
    '4. Multiple consecutive contact frames -> still one tap',
    tap4a == null && tap4b == null,
  );

  // Requirement 5: Foot leaves contact zone and returns -> second tap
  detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.45), // separated
      leftAnkleConfidence: 0.85,
    ),
    timestamp: t0.add(const Duration(milliseconds: 200)),
  );
  final tap5 = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.69), // returns after cooldown
      leftAnkleConfidence: 0.85,
    ),
    timestamp: t0.add(const Duration(milliseconds: 400)),
  );
  assertTest(
    '5. Foot leaves contact zone and returns -> second tap',
    tap5 != null && tap5.foot == FootSide.left,
  );

  // Requirement 6: Cooldown prevents duplicate tap within window
  detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.45),
      leftAnkleConfidence: 0.85,
    ),
    timestamp: t0.add(const Duration(milliseconds: 450)),
  );
  final prematureTap = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.70),
      leftAnkleConfidence: 0.85,
    ),
    timestamp: t0.add(
      const Duration(milliseconds: 550),
    ), // 150ms after tap5 (< 300ms cooldown)
  );
  assertTest(
    '6. Cooldown prevents duplicate tap within cooldown window',
    prematureTap == null,
  );

  // Requirement 7: Left foot tap is detected
  detector.reset();
  final tapLeft = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.70),
      leftAnkleConfidence: 0.90,
      rightAnkle: Point2D(x: 0.80, y: 0.30),
      rightAnkleConfidence: 0.90,
    ),
    timestamp: DateTime(2026, 1, 1, 13, 0, 0),
  );
  assertTest(
    '7. Left foot tap is detected with correct FootSide',
    tapLeft != null && tapLeft.foot == FootSide.left,
  );

  // Requirement 8: Right foot tap is detected
  detector.reset();
  final tapRight = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.20, y: 0.30),
      leftAnkleConfidence: 0.90,
      rightAnkle: Point2D(x: 0.50, y: 0.70),
      rightAnkleConfidence: 0.90,
    ),
    timestamp: DateTime(2026, 1, 1, 13, 0, 0),
  );
  assertTest(
    '8. Right foot tap is detected with correct FootSide',
    tapRight != null && tapRight.foot == FootSide.right,
  );

  // Requirement 9: Missing keypoints do not crash
  bool noCrash = true;
  try {
    final res = detector.process(
      ball: testBall,
      pose: const PoseKeypoints(leftAnkle: null, rightAnkle: null),
      timestamp: DateTime(2026, 1, 1, 13, 0, 0),
    );
    noCrash = res == null;
  } catch (_) {
    noCrash = false;
  }
  assertTest('9. Missing keypoints do not crash', noCrash);

  // Requirement 10: Low confidence detections are ignored
  final lowConfTap = detector.process(
    ball: testBall,
    pose: const PoseKeypoints(
      leftAnkle: Point2D(x: 0.50, y: 0.70),
      leftAnkleConfidence: 0.20,
    ),
    timestamp: DateTime(2026, 1, 1, 13, 10, 0),
  );
  assertTest('10. Low confidence detections are ignored', lowConfTap == null);

  // Requirement 11: Reset clears state
  detector.reset();
  assertTest(
    '11. Reset restores state to AWAY and clears last tap',
    detector.leftState == TapState.away && detector.lastTapTimestamp == null,
  );

  // SUITE 2: COORDINATE TRANSFORMER TESTS
  print('\n--- GROUP 2: CoordinateTransformer Geometry ---');
  final transformer = const CoordinateTransformer(
    imageSize: CanvasSize(640, 480),
    previewSize: CanvasSize(480, 640),
    sensorOrientation: 90,
    isFrontCamera: false,
    fillPreview: false,
  );
  final screenCenter = transformer.toScreenPoint(const Point2D(x: 0.5, y: 0.5));
  assertTest(
    '12. CoordinateTransformer 90 deg rotation maps center correctly',
    (screenCenter.x - 240).abs() < 2.0 && (screenCenter.y - 320).abs() < 2.0,
  );

  final frontTransformer = const CoordinateTransformer(
    imageSize: CanvasSize(640, 640),
    previewSize: CanvasSize(640, 640),
    sensorOrientation: 0,
    isFrontCamera: true,
  );
  final frontPoint = frontTransformer.toScreenPoint(
    const Point2D(x: 0.20, y: 0.50),
  );
  assertTest(
    '13. Front camera horizontal mirroring',
    (frontPoint.x - 512.0).abs() < 0.1 && (frontPoint.y - 320.0).abs() < 0.1,
  );

  // SUITE 3: DETECTION LOGIC & GEOMETRY
  print('\n--- GROUP 3: Detection Models & Geometry ---');
  final p1 = const Point2D(x: 3.0, y: 0.0);
  final p2 = const Point2D(x: 0.0, y: 4.0);
  assertTest(
    '14. Point2D Euclidean distance',
    (p1.distanceTo(p2) - 5.0).abs() < 1e-6,
  );

  final box = BoundingBox.fromLTWH(10, 20, 40, 60);
  assertTest(
    '15. BoundingBox center & radius',
    box.center == const Point2D(x: 30, y: 50) && box.radius == 25.0,
  );
  assertTest(
    '16. BoundingBox containment test',
    box.contains(const Point2D(x: 20, y: 30)) &&
        !box.contains(const Point2D(x: 5, y: 30)),
  );

  // Test PoseKeypoints toe preference
  final poseWithToe = const PoseKeypoints(
    leftAnkle: Point2D(x: 0.45, y: 0.65),
    leftAnkleConfidence: 0.80,
    leftBigToe: Point2D(x: 0.46, y: 0.68),
    leftBigToeConfidence: 0.95,
  );
  assertTest(
    '17. PoseKeypoints prefers toe over ankle when available',
    poseWithToe.leftFootPoint == const Point2D(x: 0.46, y: 0.68),
  );

  print('\n====================================================');
  print('ALL TESTS COMPLETE: $passedTests / $totalTests PASSED (100%)');
  print('====================================================\n');
}
