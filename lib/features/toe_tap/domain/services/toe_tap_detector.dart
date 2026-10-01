import 'dart:math' as math;

import '../../../detection/domain/models/ball_detection.dart';
import '../../../detection/domain/models/point2d.dart';
import '../../../detection/domain/models/pose_keypoints.dart';
import '../models/foot_side.dart';
import '../models/tap_detection_config.dart';
import '../models/tap_event.dart';
import '../models/tap_state.dart';

/// Tracks internal temporal state for a single foot (left or right).
class _FootTracker {
  final FootSide side;
  TapState state = TapState.away;
  Point2D? lastPosition;
  double? lastNormalizedDistance;
  DateTime? lastTimestamp;
  double velocity = 0.0; // distance change per second (negative = approaching)
  int consecutiveMissingFrames = 0;

  _FootTracker(this.side);

  void reset() {
    state = TapState.away;
    lastPosition = null;
    lastNormalizedDistance = null;
    lastTimestamp = null;
    velocity = 0.0;
    consecutiveMissingFrames = 0;
  }
}

/// Core domain service that tracks football and foot interactions,
/// executes temporal velocity and distance validation, applies state machine
/// transitions with hysteresis, and debounces toe-tap events.
class ToeTapDetector {
  final TapDetectionConfig config;

  final _FootTracker _leftTracker = _FootTracker(FootSide.left);
  final _FootTracker _rightTracker = _FootTracker(FootSide.right);

  DateTime? _lastGlobalTapTimestamp;
  FootSide? _lastTapFoot;

  ToeTapDetector({this.config = const TapDetectionConfig()});

  // State inspection getters for UI / Debug Overlay
  TapState get leftState => _leftTracker.state;
  TapState get rightState => _rightTracker.state;
  TapState get activeState =>
      _leftTracker.state == TapState.contact ||
          _rightTracker.state == TapState.contact
      ? TapState.contact
      : (_leftTracker.state == TapState.approaching ||
                _rightTracker.state == TapState.approaching
            ? TapState.approaching
            : (_leftTracker.state == TapState.release ||
                      _rightTracker.state == TapState.release
                  ? TapState.release
                  : TapState.away));

  double? get lastLeftDistance => _leftTracker.lastNormalizedDistance;
  double? get lastRightDistance => _rightTracker.lastNormalizedDistance;
  double get lastLeftVelocity => _leftTracker.velocity;
  double get lastRightVelocity => _rightTracker.velocity;
  DateTime? get lastTapTimestamp => _lastGlobalTapTimestamp;
  FootSide? get lastTapFoot => _lastTapFoot;

  /// Resets all internal trackers, history, velocities, and cooldown timestamps.
  void reset() {
    _leftTracker.reset();
    _rightTracker.reset();
    _lastGlobalTapTimestamp = null;
    _lastTapFoot = null;
  }

  /// Processes detection input for the current frame.
  /// Returns a [TapEvent] if a valid, debounced toe-tap contact transition occurred, or `null`.
  TapEvent? process({
    required BallDetection? ball,
    required PoseKeypoints? pose,
    required DateTime timestamp,
  }) {
    // 1. Validate Ball presence and confidence
    if (ball == null || ball.confidence < config.minimumBallConfidence) {
      _handleOcclusion();
      return null;
    }

    final ballCenter = ball.center;
    // Guard against zero or negative ball radius
    final ballRadius = math.max(0.001, ball.radius);

    // 2. Process Left Foot
    final leftPoint = pose?.leftFootPoint;
    final leftConfidence = pose?.leftFootConfidence ?? 0.0;
    final leftEvent = _updateFootTracker(
      tracker: _leftTracker,
      footPoint: leftPoint,
      footConfidence: leftConfidence,
      ballCenter: ballCenter,
      ballRadius: ballRadius,
      ballConfidence: ball.confidence,
      timestamp: timestamp,
    );

    // 3. Process Right Foot
    final rightPoint = pose?.rightFootPoint;
    final rightConfidence = pose?.rightFootConfidence ?? 0.0;
    final rightEvent = _updateFootTracker(
      tracker: _rightTracker,
      footPoint: rightPoint,
      footConfidence: rightConfidence,
      ballCenter: ballCenter,
      ballRadius: ballRadius,
      ballConfidence: ball.confidence,
      timestamp: timestamp,
    );

    // 4. Resolve tap event with global cooldown and arbitration
    // If both feet trigger in the exact same frame, choose the one closest to the ball.
    TapEvent? selectedEvent;
    if (leftEvent != null && rightEvent != null) {
      selectedEvent =
          (leftEvent.normalizedDistance <= rightEvent.normalizedDistance)
          ? leftEvent
          : rightEvent;
    } else {
      selectedEvent = leftEvent ?? rightEvent;
    }

    if (selectedEvent != null) {
      // Check global cooldown interval
      if (_lastGlobalTapTimestamp != null) {
        final elapsed = timestamp.difference(_lastGlobalTapTimestamp!);
        if (elapsed < config.minimumTapInterval) {
          // Suppress duplicate tap within cooldown window
          return null;
        }
      }

      _lastGlobalTapTimestamp = timestamp;
      _lastTapFoot = selectedEvent.foot;
      return selectedEvent;
    }

    return null;
  }

  TapEvent? _updateFootTracker({
    required _FootTracker tracker,
    required Point2D? footPoint,
    required double footConfidence,
    required Point2D ballCenter,
    required double ballRadius,
    required double ballConfidence,
    required DateTime timestamp,
  }) {
    // Check if foot is detected with sufficient confidence
    if (footPoint == null || footConfidence < config.minimumFootConfidence) {
      tracker.consecutiveMissingFrames++;
      if (tracker.consecutiveMissingFrames >
          config.maxMissingFramesBeforeReset) {
        tracker.state = TapState.away;
      }
      return null;
    }

    tracker.consecutiveMissingFrames = 0;

    // Euclidean distance in normalized coordinate space
    final rawDistance = footPoint.distanceTo(ballCenter);
    // Normalize by football radius:
    // When normalizedDistance <= 1.0, foot is mathematically touching/overlapping the ball circle
    // When normalizedDistance <= contactDistanceRatio (e.g. 1.30), foot is in contact range
    final normalizedDist = rawDistance / ballRadius;

    // Calculate velocity (rate of change of distance per second)
    if (tracker.lastNormalizedDistance != null &&
        tracker.lastTimestamp != null) {
      final dtSeconds =
          timestamp.difference(tracker.lastTimestamp!).inMicroseconds /
          1000000.0;
      if (dtSeconds > 0.001) {
        tracker.velocity =
            (normalizedDist - tracker.lastNormalizedDistance!) / dtSeconds;
      }
    }

    tracker.lastPosition = footPoint;
    tracker.lastNormalizedDistance = normalizedDist;
    tracker.lastTimestamp = timestamp;

    TapEvent? tapToFire;

    // STATE MACHINE TRANSITIONS WITH HYSTERESIS
    switch (tracker.state) {
      case TapState.away:
        if (normalizedDist <= config.contactDistanceRatio) {
          // Direct transition to contact
          tracker.state = TapState.contact;
          tapToFire = TapEvent(
            foot: tracker.side,
            timestamp: timestamp,
            confidence: (footConfidence + ballConfidence) / 2.0,
            normalizedDistance: normalizedDist,
          );
        } else if (normalizedDist < config.releaseDistanceRatio &&
            tracker.velocity <= config.approachVelocityThreshold) {
          tracker.state = TapState.approaching;
        }
        break;

      case TapState.approaching:
        if (normalizedDist <= config.contactDistanceRatio) {
          // Transition: APPROACHING -> CONTACT (Valid tap!)
          tracker.state = TapState.contact;
          tapToFire = TapEvent(
            foot: tracker.side,
            timestamp: timestamp,
            confidence: (footConfidence + ballConfidence) / 2.0,
            normalizedDistance: normalizedDist,
          );
        } else if (normalizedDist >= config.releaseDistanceRatio &&
            tracker.velocity > 0.0) {
          // Aborted approach
          tracker.state = TapState.away;
        }
        break;

      case TapState.contact:
        // Foot is currently in contact zone.
        // DO NOT fire another tap while in contact.
        // Hysteresis release condition: only release when distance exceeds releaseDistanceRatio (> contactDistanceRatio)
        if (normalizedDist >= config.releaseDistanceRatio) {
          tracker.state = TapState.release;
        }
        break;

      case TapState.release:
        if (normalizedDist > config.releaseDistanceRatio * 1.1) {
          // Fully separated
          tracker.state = TapState.away;
        } else if (normalizedDist <= config.contactDistanceRatio) {
          // If foot reverses before reaching away, it can trigger a new contact ONLY if cooldown has elapsed
          // Handled via state transition
          tracker.state = TapState.contact;
          tapToFire = TapEvent(
            foot: tracker.side,
            timestamp: timestamp,
            confidence: (footConfidence + ballConfidence) / 2.0,
            normalizedDistance: normalizedDist,
          );
        }
        break;
    }

    return tapToFire;
  }

  void _handleOcclusion() {
    _leftTracker.consecutiveMissingFrames++;
    _rightTracker.consecutiveMissingFrames++;
    if (_leftTracker.consecutiveMissingFrames >
        config.maxMissingFramesBeforeReset) {
      _leftTracker.state = TapState.away;
    }
    if (_rightTracker.consecutiveMissingFrames >
        config.maxMissingFramesBeforeReset) {
      _rightTracker.state = TapState.away;
    }
  }
}
