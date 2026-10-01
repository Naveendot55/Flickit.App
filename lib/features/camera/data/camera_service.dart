import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../domain/camera_state.dart';

typedef FrameCallback = Future<void> Function(
  CameraImage image, {
  required int sensorOrientation,
  required bool isFrontCamera,
});

/// Manages camera hardware initialization, permissions, lifecycle,
/// and throttled frame streaming with non-blocking concurrency control.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  CameraDescription? _currentDescription;

  bool _isInitializing = false;
  bool _isProcessingFrame = false;
  DateTime _lastFrameProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Throttling: Interval between frames to meet target inference FPS (e.g. 12 FPS = ~83ms)
  final int _minFrameIntervalMs = (1000 / AppConstants.targetInferenceFps)
      .round();

  CameraController? get controller => _controller;
  CameraDescription? get currentDescription => _currentDescription;
  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  /// Requests permissions and initializes the primary (rear) camera.
  Future<AppCameraState> initialize({
    CameraLensDirection preferredLens = CameraLensDirection.back,
  }) async {
    if (_isInitializing) {
      return AppCameraState(
        status: CameraStatus.initializing,
        availableCameras: _availableCameras,
      );
    }

    _isInitializing = true;

    try {
      // 1. Request camera permission
      final permissionStatus = await Permission.camera.request();
      if (!permissionStatus.isGranted) {
        _isInitializing = false;
        return const AppCameraState(
          status: CameraStatus.permissionDenied,
          errorMessage: 'Camera permission is required to track toe taps.',
        );
      }

      // 2. Query available camera hardware
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _isInitializing = false;
        return const AppCameraState(
          status: CameraStatus.error,
          errorMessage: 'No cameras detected on this device.',
        );
      }

      // 3. Select preferred camera (default to rear for sports tracking)
      _currentDescription = _availableCameras.firstWhere(
        (cam) => cam.lensDirection == preferredLens,
        orElse: () => _availableCameras.first,
      );

      // 4. Dispose any previous controller
      await _controller?.dispose();

      // 5. Build and initialize new controller
      // Medium resolution (720x480 or 1280x720) gives optimal balance of speed & detection accuracy
      _controller = CameraController(
        _currentDescription!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitializing = false;

      final isFront =
          _currentDescription!.lensDirection == CameraLensDirection.front;
      final orientation = _currentDescription!.sensorOrientation;

      return AppCameraState(
        status: CameraStatus.ready,
        selectedCamera: _currentDescription,
        availableCameras: _availableCameras,
        controller: _controller,
        isFrontCamera: isFront,
        sensorOrientation: orientation,
      );
    } catch (e) {
      _isInitializing = false;
      return AppCameraState(
        status: CameraStatus.error,
        errorMessage: 'Camera initialization failed: $e',
      );
    }
  }

  /// Starts throttled frame streaming with non-blocking frame-skip policy.
  Future<void> startImageStream(FrameCallback onFrame) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isStreamingImages) return;

    final isFront =
        _currentDescription?.lensDirection == CameraLensDirection.front;
    final orientation = _currentDescription?.sensorOrientation ?? 90;

    await _controller!.startImageStream((CameraImage image) async {
      // Frame Skip Rule 1: Never queue or allow concurrent inference execution
      if (_isProcessingFrame) return;

      // Frame Skip Rule 2: Throttle to target inference rate (e.g., 10-12 FPS)
      final now = DateTime.now();
      if (now.difference(_lastFrameProcessedTime).inMilliseconds <
          _minFrameIntervalMs) {
        return;
      }

      _isProcessingFrame = true;
      _lastFrameProcessedTime = now;

      try {
        await onFrame(
          image,
          sensorOrientation: orientation,
          isFrontCamera: isFront,
        );
      } catch (e) {
        debugPrint('Frame processing error in stream callback: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  /// Stops image streaming while preserving live preview.
  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
  }

  /// Disposes camera hardware resources.
  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _isInitializing = false;
    _isProcessingFrame = false;
  }
}
