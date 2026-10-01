import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../camera/data/camera_service.dart';
import '../../camera/domain/camera_state.dart';
import '../../detection/data/mock_pose_detector.dart';
import '../../detection/data/ultralytics_pose_detector.dart';
import '../../detection/domain/models/detection_result.dart';
import '../../detection/domain/repositories/pose_detector.dart';
import '../domain/models/tap_detection_config.dart';
import '../domain/models/tap_event.dart';
import '../domain/models/tap_state.dart';
import '../domain/services/toe_tap_detector.dart';
import 'trainer_state.dart';

/// Presentation state notifier for the Toe Tap Trainer.
/// Coordinates camera streaming, ML pose detection, and the toe-tap state machine.
class TrainerController extends StateNotifier<TrainerState> {
  final CameraService _cameraService;
  late PoseDetector _poseDetector;
  final ToeTapDetector _toeTapDetector;

  // FPS calculation window
  final List<DateTime> _frameTimestamps = [];
  Timer? _tapFeedbackTimer;

  TrainerController({
    required CameraService cameraService,
    PoseDetector? poseDetector,
    ToeTapDetector? toeTapDetector,
  }) : _cameraService = cameraService,
       _toeTapDetector =
           toeTapDetector ?? ToeTapDetector(config: const TapDetectionConfig()),
       super(const TrainerState()) {
    _poseDetector = poseDetector ?? MockPoseDetector(); // Default to Mock for development if model weights pending
    state = state.copyWith(
      isUsingMockDetector: _poseDetector is MockPoseDetector,
    );
  }

  /// Initializes the camera and pose detector.
  Future<void> initialize() async {
    state = state.copyWith(
      status: AppStatus.initializing,
      statusMessage: 'Loading vision model...',
    );

    try {
      // 1. Initialize detector
      await _poseDetector.initialize();

      // 2. Initialize camera
      final cameraState = await _cameraService.initialize();
      if (cameraState.status == CameraStatus.permissionDenied) {
        state = state.copyWith(
          status: AppStatus.error,
          errorMessage:
              'Camera permission denied. Please grant permission in settings.',
        );
        return;
      }

      if (cameraState.status == CameraStatus.error) {
        state = state.copyWith(
          status: AppStatus.error,
          errorMessage: cameraState.errorMessage ?? 'Camera error occurred.',
        );
        return;
      }

      state = state.copyWith(
        status: AppStatus.ready,
        statusMessage: 'Camera ready. Tap START to train.',
      );
    } catch (e) {
      state = state.copyWith(
        status: AppStatus.error,
        errorMessage: 'Initialization failed: $e',
      );
    }
  }

  /// Begins real-time frame streaming and toe-tap counting.
  Future<void> startTraining() async {
    if (state.status == AppStatus.running) return;

    if (!_cameraService.isInitialized) {
      await initialize();
    }

    state = state.copyWith(
      status: AppStatus.running,
      statusMessage: 'Tracking active',
      sessionStartTime: state.sessionStartTime ?? DateTime.now(),
    );

    await _cameraService.startImageStream((
      CameraImage image, {
      required int sensorOrientation,
      required bool isFrontCamera,
    }) async {
      await _processCameraFrame(
        image,
        sensorOrientation: sensorOrientation,
        isFrontCamera: isFrontCamera,
      );
    });
  }

  /// Pauses image streaming while keeping camera preview intact.
  Future<void> stopTraining() async {
    if (state.status != AppStatus.running) return;

    await _cameraService.stopImageStream();
    state = state.copyWith(
      status: AppStatus.paused,
      statusMessage: 'Training paused',
    );
  }

  /// Resets tap counter, stats, and state machine trackers.
  void resetTraining() {
    _toeTapDetector.reset();
    _frameTimestamps.clear();

    state = state.copyWith(
      tapCount: 0,
      leftTapCount: 0,
      rightTapCount: 0,
      lastTapFoot: null,
      lastTapTimestamp: null,
      sessionStartTime: null,
      fps: 0.0,
      tapState: TapState.away,
      showTapAnimation: false,
      statusMessage: state.status == AppStatus.running
          ? 'Tracking active (Reset)'
          : 'Ready to train?',
    );
  }

  /// Toggles developer debug overlay mode.
  void toggleDebug() {
    state = state.copyWith(isDebugMode: !state.isDebugMode);
  }

  /// Switches between the production UltralyticsPoseDetector and MockPoseDetector.
  Future<void> toggleDetector({bool? useMock}) async {
    final newUseMock = useMock ?? !state.isUsingMockDetector;
    if (newUseMock == state.isUsingMockDetector) return;

    final wasRunning = state.status == AppStatus.running;
    if (wasRunning) await stopTraining();

    await _poseDetector.dispose();
    _poseDetector = newUseMock ? MockPoseDetector() : UltralyticsPoseDetector();

    try {
      await _poseDetector.initialize();
      state = state.copyWith(
        isUsingMockDetector: newUseMock,
        statusMessage: 'Switched to ${_poseDetector.name}',
      );
    } catch (e) {
      // If production model fails to load, gracefully notify user
      state = state.copyWith(
        statusMessage: 'Failed to switch: $e',
        errorMessage: '$e',
      );
    }

    if (wasRunning) await startTraining();
  }

  /// Core frame processing pipeline:
  /// Camera Frame -> YOLO Pose Detector -> Person/Ball/Foot Keypoints -> Distance -> Toe Tap Detector -> State Update
  Future<void> _processCameraFrame(
    CameraImage image, {
    required int sensorOrientation,
    required bool isFrontCamera,
  }) async {
    if (state.status != AppStatus.running) return;

    final now = DateTime.now();
    _updateFps(now);

    try {
      // 1. Run inference
      final DetectionResult? result = await _poseDetector.processFrame(
        image,
        sensorOrientation: sensorOrientation,
        isFrontCamera: isFrontCamera,
      );

      if (result == null) return;

      // 2. Feed into ToeTapDetector state machine
      final TapEvent? tap = _toeTapDetector.process(
        ball: result.ball,
        pose: result.pose,
        timestamp: result.timestamp,
      );

      // 3. Status text determination
      String statusMsg = 'Tracking';
      if (result.ball == null && result.person == null) {
        statusMsg = 'Person and ball not detected';
      } else if (result.ball == null) {
        statusMsg = 'Ball not detected';
      } else if (result.person == null) {
        statusMsg = 'Person not detected';
      }

      // 4. Update state if a valid debounced tap occurred
      if (tap != null) {
        final newTapCount = state.tapCount + 1;
        final newLeftCount = tap.foot.displayName == 'LEFT'
            ? state.leftTapCount + 1
            : state.leftTapCount;
        final newRightCount = tap.foot.displayName == 'RIGHT'
            ? state.rightTapCount + 1
            : state.rightTapCount;

        _triggerTapFeedbackAnimation();

        state = state.copyWith(
          tapCount: newTapCount,
          leftTapCount: newLeftCount,
          rightTapCount: newRightCount,
          lastTapFoot: tap.foot,
          lastTapTimestamp: tap.timestamp,
          latestDetection: result,
          latencyMs: result.inferenceTime.inMilliseconds,
          tapState: _toeTapDetector.activeState,
          statusMessage: statusMsg,
          showTapAnimation: true,
        );
      } else {
        state = state.copyWith(
          latestDetection: result,
          latencyMs: result.inferenceTime.inMilliseconds,
          tapState: _toeTapDetector.activeState,
          statusMessage: statusMsg,
        );
      }
    } catch (e) {
      debugPrint('Non-fatal frame inference error: $e');
    }
  }

  void _triggerTapFeedbackAnimation() {
    _tapFeedbackTimer?.cancel();
    state = state.copyWith(showTapAnimation: true);
    _tapFeedbackTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        state = state.copyWith(showTapAnimation: false);
      }
    });
  }

  void _updateFps(DateTime now) {
    _frameTimestamps.add(now);
    // Keep timestamps from the last 1.5 seconds
    _frameTimestamps.removeWhere(
      (ts) => now.difference(ts).inMilliseconds > 1500,
    );

    if (_frameTimestamps.length > 1) {
      final durationSec =
          now.difference(_frameTimestamps.first).inMicroseconds / 1000000.0;
      if (durationSec > 0.1) {
        final calculatedFps = (_frameTimestamps.length - 1) / durationSec;
        state = state.copyWith(fps: calculatedFps);
      }
    }
  }

  /// Manages Flutter App Lifecycle state changes (resumed, paused, inactive, detached).
  Future<void> handleLifecycleChange(AppLifecycleState lifecycle) async {
    switch (lifecycle) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (state.status == AppStatus.running) {
          await stopTraining();
        }
        break;
      case AppLifecycleState.resumed:
        if (!_cameraService.isInitialized) {
          await initialize();
        }
        break;
      case AppLifecycleState.detached:
        await dispose();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    _tapFeedbackTimer?.cancel();
    _cameraService.dispose();
    _poseDetector.dispose();
    super.dispose();
  }
}
