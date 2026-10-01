import 'foot_side.dart';

/// Represents a validated toe tap event on the football.
class TapEvent {
  final FootSide foot;
  final DateTime timestamp;
  final double confidence;
  final double normalizedDistance;

  const TapEvent({
    required this.foot,
    required this.timestamp,
    required this.confidence,
    required this.normalizedDistance,
  });

  @override
  String toString() =>
      'TapEvent(${foot.displayName}, time: ${timestamp.toIso8601String()}, dist: ${normalizedDistance.toStringAsFixed(2)}, conf: ${confidence.toStringAsFixed(2)})';
}
