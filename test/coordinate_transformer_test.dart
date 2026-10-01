import 'package:test/test.dart';

import '../lib/core/utils/coordinate_transformer.dart';
import '../lib/features/detection/domain/models/bounding_box.dart';
import '../lib/features/detection/domain/models/point2d.dart';

void main() {
  group('CoordinateTransformer Tests', () {
    test('Portrait transformation (90 degrees sensor orientation)', () {
      final transformer = CoordinateTransformer(
        imageSize: const CanvasSize(640, 480),
        previewSize: const CanvasSize(480, 640),
        sensorOrientation: 90,
        isFrontCamera: false,
        fillPreview: false,
      );

      // Model center point (0.5, 0.5)
      final centerPoint = const Point2D(x: 0.5, y: 0.5);
      final screenPoint = transformer.toScreenPoint(centerPoint);

      // In rotated coordinate space (x' = 1 - y = 0.5, y' = x = 0.5)
      expect(screenPoint.x, closeTo(240.0, 1.0));
      expect(screenPoint.y, closeTo(320.0, 1.0));
    });

    test('Front camera horizontal mirroring', () {
      final rearTransformer = CoordinateTransformer(
        imageSize: const CanvasSize(640, 640),
        previewSize: const CanvasSize(640, 640),
        sensorOrientation: 0,
        isFrontCamera: false,
      );

      final frontTransformer = CoordinateTransformer(
        imageSize: const CanvasSize(640, 640),
        previewSize: const CanvasSize(640, 640),
        sensorOrientation: 0,
        isFrontCamera: true,
      );

      final point = const Point2D(x: 0.20, y: 0.50);
      final rearScreen = rearTransformer.toScreenPoint(point);
      final frontScreen = frontTransformer.toScreenPoint(point);

      // Front screen x should be mirrored: 1.0 - 0.20 = 0.80 -> 512px vs 128px
      expect(rearScreen.x, closeTo(128.0, 0.1));
      expect(frontScreen.x, closeTo(512.0, 0.1));
      expect(frontScreen.y, equals(rearScreen.y));
    });

    test('BoundingBox coordinate transformation preserves validity', () {
      final transformer = CoordinateTransformer(
        imageSize: const CanvasSize(640, 640),
        previewSize: const CanvasSize(320, 320),
        sensorOrientation: 0,
        isFrontCamera: false,
      );

      final modelBox = BoundingBox.fromLTRB(0.1, 0.2, 0.4, 0.6);
      final screenBox = transformer.toScreenBox(modelBox);

      expect(screenBox.left, closeTo(32.0, 0.1));
      expect(screenBox.top, closeTo(64.0, 0.1));
      expect(screenBox.right, closeTo(128.0, 0.1));
      expect(screenBox.bottom, closeTo(192.0, 0.1));
      expect(screenBox.width, closeTo(96.0, 0.1));
      expect(screenBox.height, closeTo(128.0, 0.1));
    });

    test('Radius scale maps accurately', () {
      final transformer = CoordinateTransformer(
        imageSize: const CanvasSize(640, 640),
        previewSize: const CanvasSize(320, 320),
        sensorOrientation: 0,
      );

      const normalizedRadius = 0.10; // 10% of width
      final screenRadius = transformer.toScreenRadius(normalizedRadius);

      expect(screenRadius, closeTo(32.0, 0.1));
    });
  });
}
