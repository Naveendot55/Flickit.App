import 'package:test/test.dart';

import '../lib/features/detection/domain/models/ball_detection.dart';
import '../lib/features/detection/domain/models/bounding_box.dart';
import '../lib/features/detection/domain/models/point2d.dart';
import '../lib/features/detection/domain/models/pose_keypoints.dart';
import '../lib/features/toe_tap/domain/models/foot_side.dart';
import '../lib/features/toe_tap/domain/models/tap_detection_config.dart';
import '../lib/features/toe_tap/domain/models/tap_state.dart';
import '../lib/features/toe_tap/domain/services/toe_tap_detector.dart';

void main() {
  group('ToeTapDetector Algorithm & Debouncing Tests', () {
    late ToeTapDetector detector;
    final ballCenter = const Point2D(x: 0.50, y: 0.70);
    const ballRadius = 0.08; // width = 0.16
    final testBall = BallDetection(
      boundingBox: BoundingBox.fromCenter(
        center: ballCenter,
        width: ballRadius * 2.0,
        height: ballRadius * 2.0,
      ),
      confidence: 0.90,
    );

    setUp(() {
      detector = ToeTapDetector(
        config: const TapDetectionConfig(
          contactDistanceRatio: 1.30,
          releaseDistanceRatio: 1.70,
          minimumTapInterval: Duration(milliseconds: 300),
          minimumFootConfidence: 0.40,
          minimumBallConfidence: 0.40,
        ),
      );
    });

    test('1. No detection -> no tap', () {
      final tap = detector.process(
        ball: null,
        pose: null,
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      );
      expect(tap, isNull);
      expect(detector.activeState, equals(TapState.away));
    });

    test('2. Foot far from ball -> no tap', () {
      // Foot located far above the ball at y=0.40 (distance ~ 0.30, ratio ~ 3.75)
      final pose = PoseKeypoints(
        leftAnkle: const Point2D(x: 0.50, y: 0.40),
        leftAnkleConfidence: 0.85,
      );

      final tap = detector.process(
        ball: testBall,
        pose: pose,
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      );

      expect(tap, isNull);
      expect(detector.leftState, equals(TapState.away));
    });

    test('3. Foot enters contact zone -> one tap', () {
      // Step 1: Foot approaches (y=0.45, comfortably away)
      detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.45),
          leftAnkleConfidence: 0.85,
        ),
        timestamp: DateTime(2026, 1, 1, 12, 0, 0, 0),
      );

      // Step 2: Foot reaches contact zone (y=0.68, distance to center = 0.02, ratio = 0.25 <= 1.30)
      final tap = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.68),
          leftAnkleConfidence: 0.85,
        ),
        timestamp: DateTime(2026, 1, 1, 12, 0, 0, 50),
      );

      expect(tap, isNotNull);
      expect(tap!.foot, equals(FootSide.left));
      expect(detector.leftState, equals(TapState.contact));
    });

    test(
      '4. Multiple consecutive contact frames -> still one tap (debouncing)',
      () {
        final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);

        // Frame 1: First contact -> triggers tap
        final tap1 = detector.process(
          ball: testBall,
          pose: const PoseKeypoints(
            leftAnkle: Point2D(x: 0.50, y: 0.69),
            leftAnkleConfidence: 0.85,
          ),
          timestamp: t0,
        );
        expect(tap1, isNotNull, reason: 'First contact must trigger tap');

        // Frame 2: Foot remains in contact 30ms later -> NO duplicate tap
        final tap2 = detector.process(
          ball: testBall,
          pose: const PoseKeypoints(
            leftAnkle: Point2D(x: 0.50, y: 0.70),
            leftAnkleConfidence: 0.85,
          ),
          timestamp: t0.add(const Duration(milliseconds: 30)),
        );
        expect(
          tap2,
          isNull,
          reason: 'Consecutive frame in contact must NOT duplicate tap',
        );

        // Frame 3: Foot still in contact 60ms later -> NO duplicate tap
        final tap3 = detector.process(
          ball: testBall,
          pose: const PoseKeypoints(
            leftAnkle: Point2D(x: 0.50, y: 0.71),
            leftAnkleConfidence: 0.85,
          ),
          timestamp: t0.add(const Duration(milliseconds: 60)),
        );
        expect(
          tap3,
          isNull,
          reason: 'Consecutive frame in contact must NOT duplicate tap',
        );
        expect(detector.leftState, equals(TapState.contact));
      },
    );

    test('5. Foot leaves contact zone and returns -> second tap', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);

      // 1. Initial contact
      final tap1 = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.70),
          leftAnkleConfidence: 0.85,
        ),
        timestamp: t0,
      );
      expect(tap1, isNotNull);

      // 2. Foot separates beyond release threshold (ratio > 1.70: dist > 0.08 * 1.7 = 0.136 -> y <= 0.56)
      detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.50), // dist = 0.20, ratio = 2.5
          leftAnkleConfidence: 0.85,
        ),
        timestamp: t0.add(const Duration(milliseconds: 200)),
      );

      // 3. Foot returns to contact after cooldown (elapsed = 400ms > 300ms cooldown)
      final tap2 = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.69),
          leftAnkleConfidence: 0.85,
        ),
        timestamp: t0.add(const Duration(milliseconds: 400)),
      );

      expect(
        tap2,
        isNotNull,
        reason:
            'New contact after release and cooldown must trigger second tap',
      );
      expect(tap2!.foot, equals(FootSide.left));
    });

    test('6. Cooldown prevents duplicate tap within cooldown window', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);

      // 1. Tap 1
      final tap1 = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.70),
          leftAnkleConfidence: 0.85,
        ),
        timestamp: t0,
      );
      expect(tap1, isNotNull);

      // 2. Foot quickly releases
      detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.45),
          leftAnkleConfidence: 0.85,
        ),
        timestamp: t0.add(const Duration(milliseconds: 80)),
      );

      // 3. Foot enters contact zone again at 150ms (< 300ms cooldown!)
      final prematureTap = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.70),
          leftAnkleConfidence: 0.85,
        ),
        timestamp: t0.add(const Duration(milliseconds: 150)),
      );

      expect(
        prematureTap,
        isNull,
        reason: 'Tap within 300ms cooldown must be suppressed',
      );
    });

    test('7. Left foot tap is detected with correct FootSide', () {
      final tap = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.70),
          leftAnkleConfidence: 0.90,
          rightAnkle: Point2D(x: 0.80, y: 0.30), // right foot is far away
          rightAnkleConfidence: 0.90,
        ),
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      );

      expect(tap, isNotNull);
      expect(tap!.foot, equals(FootSide.left));
      expect(detector.lastTapFoot, equals(FootSide.left));
    });

    test('8. Right foot tap is detected with correct FootSide', () {
      final tap = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.20, y: 0.30), // left foot is far away
          leftAnkleConfidence: 0.90,
          rightAnkle: Point2D(x: 0.50, y: 0.70), // right foot touches ball
          rightAnkleConfidence: 0.90,
        ),
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      );

      expect(tap, isNotNull);
      expect(tap!.foot, equals(FootSide.right));
      expect(detector.lastTapFoot, equals(FootSide.right));
    });

    test('9. Missing keypoints do not crash', () {
      expect(() {
        final tap = detector.process(
          ball: testBall,
          pose: const PoseKeypoints(leftAnkle: null, rightAnkle: null),
          timestamp: DateTime(2026, 1, 1, 12, 0, 0),
        );
        expect(tap, isNull);
      }, returnsNormally);
    });

    test('10. Low confidence detections are ignored', () {
      // Foot in physical contact location, but confidence only 0.20 (< 0.40 threshold)
      final lowConfPose = const PoseKeypoints(
        leftAnkle: Point2D(x: 0.50, y: 0.70),
        leftAnkleConfidence: 0.20,
      );

      final tap = detector.process(
        ball: testBall,
        pose: lowConfPose,
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      );

      expect(tap, isNull, reason: 'Low confidence keypoints must be discarded');
    });

    test('11. Reset clears detector history and cooldown state', () {
      // Fire a tap
      final tap = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.70),
          leftAnkleConfidence: 0.90,
        ),
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      );
      expect(tap, isNotNull);
      expect(detector.leftState, equals(TapState.contact));

      // Reset
      detector.reset();
      expect(detector.leftState, equals(TapState.away));
      expect(detector.lastTapTimestamp, isNull);
      expect(detector.lastTapFoot, isNull);

      // Now immediate contact at t0 + 10ms can trigger again because cooldown was cleared
      final tapAfterReset = detector.process(
        ball: testBall,
        pose: const PoseKeypoints(
          leftAnkle: Point2D(x: 0.50, y: 0.70),
          leftAnkleConfidence: 0.90,
        ),
        timestamp: DateTime(2026, 1, 1, 12, 0, 0, 10),
      );
      expect(tapAfterReset, isNotNull);
    });
  });
}
