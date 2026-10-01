/// Configuration parameters for the toe-tap state machine and contact algorithms.
class TapDetectionConfig {
  /// Distance ratio threshold to trigger contact: distance / ballRadius <= contactDistanceRatio.
  /// Standard football radius is ~11cm; contact zone is usually within 1.0 - 1.35x radius.
  final double contactDistanceRatio;

  /// Distance ratio threshold for releasing contact (hysteresis): distance / ballRadius >= releaseDistanceRatio.
  /// Must be strictly greater than [contactDistanceRatio] to prevent boundary chatter.
  final double releaseDistanceRatio;

  /// Minimum time window between valid taps to debounce multi-frame contacts.
  final Duration minimumTapInterval;

  /// Minimum model confidence for keypoints (ankle/toe).
  final double minimumFootConfidence;

  /// Minimum model confidence for the football detection.
  final double minimumBallConfidence;

  /// Required velocity (distance change / second) when moving towards ball to be considered 'approaching'.
  /// Negative velocity means distance is decreasing.
  final double approachVelocityThreshold;

  /// Tolerance count for temporary occlusion before resetting tracking state.
  final int maxMissingFramesBeforeReset;

  const TapDetectionConfig({
    this.contactDistanceRatio = 1.30,
    this.releaseDistanceRatio = 1.70,
    this.minimumTapInterval = const Duration(milliseconds: 320),
    this.minimumFootConfidence = 0.40,
    this.minimumBallConfidence = 0.40,
    this.approachVelocityThreshold = -0.15,
    this.maxMissingFramesBeforeReset = 6,
  }) : assert(
         contactDistanceRatio < releaseDistanceRatio,
         'contactDistanceRatio ($contactDistanceRatio) must be less than releaseDistanceRatio ($releaseDistanceRatio) for hysteresis',
       );

  TapDetectionConfig copyWith({
    double? contactDistanceRatio,
    double? releaseDistanceRatio,
    Duration? minimumTapInterval,
    double? minimumFootConfidence,
    double? minimumBallConfidence,
    double? approachVelocityThreshold,
    int? maxMissingFramesBeforeReset,
  }) {
    return TapDetectionConfig(
      contactDistanceRatio: contactDistanceRatio ?? this.contactDistanceRatio,
      releaseDistanceRatio: releaseDistanceRatio ?? this.releaseDistanceRatio,
      minimumTapInterval: minimumTapInterval ?? this.minimumTapInterval,
      minimumFootConfidence:
          minimumFootConfidence ?? this.minimumFootConfidence,
      minimumBallConfidence:
          minimumBallConfidence ?? this.minimumBallConfidence,
      approachVelocityThreshold:
          approachVelocityThreshold ?? this.approachVelocityThreshold,
      maxMissingFramesBeforeReset:
          maxMissingFramesBeforeReset ?? this.maxMissingFramesBeforeReset,
    );
  }
}
