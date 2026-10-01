import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/camera/data/camera_service.dart';
import '../features/detection/data/mock_pose_detector.dart';
import '../features/detection/domain/repositories/pose_detector.dart';
import '../features/toe_tap/domain/models/tap_detection_config.dart';
import '../features/toe_tap/domain/services/toe_tap_detector.dart';
import '../features/toe_tap/presentation/controllers/trainer_controller.dart';
import '../features/toe_tap/presentation/controllers/trainer_state.dart';

/// Singleton CameraService provider
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// PoseDetector provider (defaults to MockPoseDetector for demo/dev, swappable to UltralyticsPoseDetector)
final poseDetectorProvider = Provider<PoseDetector>((ref) {
  final detector = MockPoseDetector();
  ref.onDispose(() => detector.dispose());
  return detector;
});

/// ToeTapDetector domain service provider
final toeTapDetectorProvider = Provider<ToeTapDetector>((ref) {
  return ToeTapDetector(config: const TapDetectionConfig());
});

/// Primary state notifier provider driving the Flickit UI
final trainerControllerProvider =
    StateNotifierProvider<TrainerController, TrainerState>((ref) {
      final cameraService = ref.watch(cameraServiceProvider);
      final poseDetector = ref.watch(poseDetectorProvider);
      final toeTapDetector = ref.watch(toeTapDetectorProvider);

      return TrainerController(
        cameraService: cameraService,
        poseDetector: poseDetector,
        toeTapDetector: toeTapDetector,
      );
    });
