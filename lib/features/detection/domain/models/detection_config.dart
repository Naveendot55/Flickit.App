/// Configuration options for YOLO detection filtering and model thresholds.
class DetectionConfig {
  final double minPersonConfidence;
  final double minBallConfidence;
  final double minKeypointConfidence;
  final double iouThreshold;
  final int maxDetections;

  const DetectionConfig({
    this.minPersonConfidence = 0.50,
    this.minBallConfidence = 0.40,
    this.minKeypointConfidence = 0.40,
    this.iouThreshold = 0.45,
    this.maxDetections = 10,
  });

  DetectionConfig copyWith({
    double? minPersonConfidence,
    double? minBallConfidence,
    double? minKeypointConfidence,
    double? iouThreshold,
    int? maxDetections,
  }) {
    return DetectionConfig(
      minPersonConfidence: minPersonConfidence ?? this.minPersonConfidence,
      minBallConfidence: minBallConfidence ?? this.minBallConfidence,
      minKeypointConfidence:
          minKeypointConfidence ?? this.minKeypointConfidence,
      iouThreshold: iouThreshold ?? this.iouThreshold,
      maxDetections: maxDetections ?? this.maxDetections,
    );
  }
}
