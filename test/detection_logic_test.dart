import 'package:test/test.dart';

import '../lib/features/detection/data/ultralytics_pose_detector.dart';
import '../lib/features/detection/domain/models/ball_detection.dart';
import '../lib/features/detection/domain/models/bounding_box.dart';
import '../lib/features/detection/domain/models/point2d.dart';
import '../lib/features/detection/domain/models/pose_keypoints.dart';

void main() {
  group('Detection Domain Models & Logic Tests', () {
    test('Point2D Euclidean distance and vector operations', () {
      final p1 = const Point2D(x: 3.0, y: 0.0);
      final p2 = const Point2D(x: 0.0, y: 4.0);

      expect(p1.distanceTo(p2), closeTo(5.0, 1e-6));

      final sum = p1 + p2;
      expect(sum.x, equals(3.0));
      expect(sum.y, equals(4.0));

      final scaled = p1 * 2.0;
      expect(scaled.x, equals(6.0));
    });

    test('BoundingBox geometry, center, radius, and containment', () {
      final box = BoundingBox.fromLTWH(10, 20, 40, 60);

      expect(box.left, equals(10));
      expect(box.top, equals(20));
      expect(box.right, equals(50));
      expect(box.bottom, equals(80));
      expect(box.width, equals(40));
      expect(box.height, equals(60));
      expect(box.center, equals(const Point2D(x: 30, y: 50)));
      expect(box.radius, equals(25.0));

      expect(box.contains(const Point2D(x: 20, y: 30)), isTrue);
      expect(box.contains(const Point2D(x: 5, y: 30)), isFalse);
    });

    test(
      'BallDetection computes correct center and radius from BoundingBox',
      () {
        final ball = BallDetection(
          boundingBox: BoundingBox.fromCenter(
            center: const Point2D(x: 0.5, y: 0.7),
            width: 0.14,
            height: 0.14,
          ),
          confidence: 0.95,
        );

        expect(ball.center.x, closeTo(0.5, 1e-6));
        expect(ball.center.y, closeTo(0.7, 1e-6));
        expect(ball.radius, closeTo(0.07, 1e-6));
      },
    );

    test(
      'PoseKeypoints prefers toe if present, falls back cleanly to ankle',
      () {
        // 1. With ankle only
        final poseWithAnkle = const PoseKeypoints(
          leftAnkle: Point2D(x: 0.45, y: 0.65),
          leftAnkleConfidence: 0.82,
        );
        expect(
          poseWithAnkle.leftFootPoint,
          equals(const Point2D(x: 0.45, y: 0.65)),
        );
        expect(poseWithAnkle.leftFootConfidence, equals(0.82));

        // 2. With toe available
        final poseWithToe = const PoseKeypoints(
          leftAnkle: Point2D(x: 0.45, y: 0.65),
          leftAnkleConfidence: 0.82,
          leftBigToe: Point2D(x: 0.46, y: 0.68),
          leftBigToeConfidence: 0.90,
        );
        expect(
          poseWithToe.leftFootPoint,
          equals(const Point2D(x: 0.46, y: 0.68)),
        );
        expect(poseWithToe.leftFootConfidence, equals(0.90));
      },
    );

    test('UltralyticsPoseDetector parses candidate tensors and maps COCO keypoints', () {
      final detector = UltralyticsPoseDetector();

      // Create a mock YOLOv8 candidate:
      // Indices: 0..3: [cx, cy, w, h] = [0.5, 0.4, 0.3, 0.7]
      // Index 4: person conf = 0.88
      // Indices 5..55: 17 keypoints x 3 [x, y, conf]
      final candidate = List<double>.filled(57, 0.0);
      candidate[0] = 0.50; // cx
      candidate[1] = 0.40; // cy
      candidate[2] = 0.30; // w
      candidate[3] = 0.70; // h
      candidate[4] = 0.88; // person conf

      // Left ankle at COCO index 15 (offset = 5 + 15 * 3 = 50)
      candidate[50] = 0.48; // x
      candidate[51] = 0.72; // y
      candidate[52] = 0.85; // conf

      // Right ankle at COCO index 16 (offset = 5 + 16 * 3 = 53)
      candidate[53] = 0.54; // x
      candidate[54] = 0.73; // y
      candidate[55] = 0.86; // conf

      // Football class conf at index 56 = 0.92
      candidate[56] = 0.92;

      final result = detector.parseRawOutput(
        candidates: [candidate],
        latency: const Duration(milliseconds: 42),
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      );

      expect(result.person, isNotNull);
      expect(result.person!.confidence, equals(0.88));
      expect(result.pose?.leftAnkle?.x, equals(0.48));
      expect(result.pose?.leftAnkle?.y, equals(0.72));
      expect(result.pose?.rightAnkle?.x, equals(0.54));
      expect(result.pose?.rightAnkle?.y, equals(0.73));
      expect(result.ball, isNotNull);
      expect(result.ball!.confidence, equals(0.92));
    });
  });
}
