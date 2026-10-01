import '../../features/detection/domain/models/bounding_box.dart';
import '../../features/detection/domain/models/point2d.dart';

/// 2D dimensions representing image frame or preview viewport size.
/// Defined independently of dart:ui so transformations can run inside
/// background isolates, command line tools, and pure-Dart unit tests.
class CanvasSize {
  final double width;
  final double height;

  const CanvasSize(this.width, this.height);

  @override
  String toString() => 'CanvasSize(${width}x$height)';
}

/// Coordinate transformer that maps coordinates between:
/// 1. YOLO model normalized coordinates [0.0, 1.0]
/// 2. Camera sensor frames (accounting for 90/270 degree rotation and front-camera mirroring)
/// 3. Flutter UI preview coordinates (accounting for viewport dimensions and BoxFit scaling)
class CoordinateTransformer {
  final CanvasSize imageSize;
  final CanvasSize previewSize;
  final int sensorOrientation;
  final bool isFrontCamera;
  final bool fillPreview;

  const CoordinateTransformer({
    required this.imageSize,
    required this.previewSize,
    this.sensorOrientation = 90,
    this.isFrontCamera = false,
    this.fillPreview = true,
  });

  /// Transforms a normalized [0, 1] model Point2D into screen/preview canvas coordinates.
  Point2D toScreenPoint(Point2D normalizedPoint) {
    // Step 1: Rotate and mirror normalized point according to camera sensor
    final oriented = _orientNormalizedPoint(
      normalizedPoint,
      sensorOrientation: sensorOrientation,
      isFrontCamera: isFrontCamera,
    );

    // Step 2: Compute scale and offsets for preview fitting
    // If the sensor is rotated 90 or 270, the sensor width/height are swapped in portrait
    final effectiveImageWidth =
        (sensorOrientation == 90 || sensorOrientation == 270)
        ? imageSize.height
        : imageSize.width;
    final effectiveImageHeight =
        (sensorOrientation == 90 || sensorOrientation == 270)
        ? imageSize.width
        : imageSize.height;

    final scaleX = previewSize.width / effectiveImageWidth;
    final scaleY = previewSize.height / effectiveImageHeight;

    double scale;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (fillPreview) {
      // BoxFit.cover: crop excess
      scale = scaleX > scaleY ? scaleX : scaleY;
      offsetX = (previewSize.width - effectiveImageWidth * scale) / 2.0;
      offsetY = (previewSize.height - effectiveImageHeight * scale) / 2.0;
    } else {
      // BoxFit.contain: letterbox
      scale = scaleX < scaleY ? scaleX : scaleY;
      offsetX = (previewSize.width - effectiveImageWidth * scale) / 2.0;
      offsetY = (previewSize.height - effectiveImageHeight * scale) / 2.0;
    }

    final screenX = oriented.x * effectiveImageWidth * scale + offsetX;
    final screenY = oriented.y * effectiveImageHeight * scale + offsetY;

    return Point2D(x: screenX, y: screenY);
  }

  /// Transforms a normalized BoundingBox into preview canvas coordinates.
  BoundingBox toScreenBox(BoundingBox normalizedBox) {
    final p1 = toScreenPoint(
      Point2D(x: normalizedBox.left, y: normalizedBox.top),
    );
    final p2 = toScreenPoint(
      Point2D(x: normalizedBox.right, y: normalizedBox.bottom),
    );

    return BoundingBox.fromLTRB(p1.x, p1.y, p2.x, p2.y);
  }

  /// Transforms a normalized radius (relative to width) to preview screen pixels.
  double toScreenRadius(double normalizedRadius) {
    final effectiveImageWidth =
        (sensorOrientation == 90 || sensorOrientation == 270)
        ? imageSize.height
        : imageSize.width;
    final effectiveImageHeight =
        (sensorOrientation == 90 || sensorOrientation == 270)
        ? imageSize.width
        : imageSize.height;

    final scaleX = previewSize.width / effectiveImageWidth;
    final scaleY = previewSize.height / effectiveImageHeight;
    final scale = fillPreview
        ? (scaleX > scaleY ? scaleX : scaleY)
        : (scaleX < scaleY ? scaleX : scaleY);

    return normalizedRadius * effectiveImageWidth * scale;
  }

  /// Applies rotation (0, 90, 180, 270) and optional horizontal mirroring to a [0, 1] point.
  static Point2D _orientNormalizedPoint(
    Point2D p, {
    required int sensorOrientation,
    required bool isFrontCamera,
  }) {
    double x = p.x;
    double y = p.y;

    if (isFrontCamera) {
      x = 1.0 - x; // Mirror horizontally
    }

    switch (sensorOrientation) {
      case 90:
        return Point2D(x: 1.0 - y, y: x);
      case 180:
        return Point2D(x: 1.0 - x, y: 1.0 - y);
      case 270:
        return Point2D(x: y, y: 1.0 - x);
      case 0:
      default:
        return Point2D(x: x, y: y);
    }
  }
}
