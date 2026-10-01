import 'package:camera/camera.dart';

import '../models/detection_result.dart';
import '../models/detection_config.dart';

/// Contract for pose and football detectors.
/// Enables seamless swapping between production YOLO inference and development/mock engines.
abstract class PoseDetector {
  /// Whether the detector model is loaded and ready for inference.
  bool get isInitialized;

  /// Human-readable name of the detector implementation.
  String get name;

  /// Initializes the detector, loading weights, labels, and allocating tensors.
  Future<void> initialize({DetectionConfig? config});

  /// Processes a single camera frame and returns high-level detection results.
  /// Implementations must not block the UI thread and should handle format conversion internally.
  Future<DetectionResult?> processFrame(
    CameraImage image, {
    int sensorOrientation = 90,
    bool isFrontCamera = false,
  });

  /// Releases model resources and native buffers.
  Future<void> dispose();
}
