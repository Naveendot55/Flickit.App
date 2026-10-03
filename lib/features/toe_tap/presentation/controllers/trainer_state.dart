import '../../../detection/domain/models/detection_result.dart';

import '../../domain/models/foot_side.dart';

import '../../domain/models/tap_state.dart';

enum AppStatus {
  idle,
  initializing,
  ready,
  running,
  paused,
  error;

  String get displayTitle {
    switch (this) {
      case AppStatus.idle:
        return 'Ready to train?';
      case AppStatus.initializing:
        return 'Loading vision model...';
      case AppStatus.ready:
        return 'Camera ready';
      case AppStatus.running:
        return 'Tracking';
      case AppStatus.paused:
        return 'Training paused';
      case AppStatus.error:
        return 'Detection unavailable';
    }
  }
}

class TrainerState {
  final AppStatus status;
  final int tapCount;
  final int leftTapCount;
  final int rightTapCount;
  final FootSide? lastTapFoot;
  final DateTime? lastTapTimestamp;
  final double fps;
  final int latencyMs;
  final String statusMessage;
  final String? errorMessage;
  final bool isDebugMode;
  final bool isUsingMockDetector;
  final DetectionResult? latestDetection;
  final TapState tapState;
  final DateTime? sessionStartTime;
  final bool showTapAnimation;

  const TrainerState({
    this.status = AppStatus.idle,
    this.tapCount = 0,
    this.leftTapCount = 0,
    this.rightTapCount = 0,
    this.lastTapFoot,
    this.lastTapTimestamp,
    this.fps = 0.0,
    this.latencyMs = 0,
    this.statusMessage = 'Ready to train?',
    this.errorMessage,
    this.isDebugMode = false,
    this.isUsingMockDetector = false,
    this.latestDetection,
    this.tapState = TapState.away,
    this.sessionStartTime,
    this.showTapAnimation = false,
  });

  /// Real-time Taps Per Minute calculation
  double get tapsPerMinute {
    if (sessionStartTime == null || tapCount == 0) return 0.0;
    final elapsedMinutes =
        DateTime.now().difference(sessionStartTime!).inSeconds / 60.0;
    if (elapsedMinutes < 0.05) return 0.0;
    return tapCount / elapsedMinutes;
  }

  TrainerState copyWith({
    AppStatus? status,
    int? tapCount,
    int? leftTapCount,
    int? rightTapCount,
    FootSide? lastTapFoot,
    DateTime? lastTapTimestamp,
    double? fps,
    int? latencyMs,
    String? statusMessage,
    String? errorMessage,
    bool? isDebugMode,
    bool? isUsingMockDetector,
    DetectionResult? latestDetection,
    TapState? tapState,
    DateTime? sessionStartTime,
    bool? showTapAnimation,
  }) {
    return TrainerState(
      status: status ?? this.status,
      tapCount: tapCount ?? this.tapCount,
      leftTapCount: leftTapCount ?? this.leftTapCount,
      rightTapCount: rightTapCount ?? this.rightTapCount,
      lastTapFoot: lastTapFoot ?? this.lastTapFoot,
      lastTapTimestamp: lastTapTimestamp ?? this.lastTapTimestamp,
      fps: fps ?? this.fps,
      latencyMs: latencyMs ?? this.latencyMs,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      isDebugMode: isDebugMode ?? this.isDebugMode,
      isUsingMockDetector: isUsingMockDetector ?? this.isUsingMockDetector,
      latestDetection: latestDetection ?? this.latestDetection,
      tapState: tapState ?? this.tapState,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      showTapAnimation: showTapAnimation ?? this.showTapAnimation,
    );
  }
}
