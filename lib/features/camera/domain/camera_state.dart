import 'package:camera/camera.dart';

enum CameraStatus {
  uninitialized,
  permissionDenied,
  initializing,
  ready,
  streaming,
  paused,
  error,
}

class AppCameraState {
  final CameraStatus status;
  final CameraDescription? selectedCamera;
  final List<CameraDescription> availableCameras;
  final CameraController? controller;
  final String? errorMessage;
  final bool isFrontCamera;
  final int sensorOrientation;

  const AppCameraState({
    this.status = CameraStatus.uninitialized,
    this.selectedCamera,
    this.availableCameras = const [],
    this.controller,
    this.errorMessage,
    this.isFrontCamera = false,
    this.sensorOrientation = 90,
  });

  bool get isReady =>
      (status == CameraStatus.ready || status == CameraStatus.streaming) &&
      controller != null &&
      controller!.value.isInitialized;

  bool get isStreaming => status == CameraStatus.streaming;

  AppCameraState copyWith({
    CameraStatus? status,
    CameraDescription? selectedCamera,
    List<CameraDescription>? availableCameras,
    CameraController? controller,
    String? errorMessage,
    bool? isFrontCamera,
    int? sensorOrientation,
  }) {
    return AppCameraState(
      status: status ?? this.status,
      selectedCamera: selectedCamera ?? this.selectedCamera,
      availableCameras: availableCameras ?? this.availableCameras,
      controller: controller ?? this.controller,
      errorMessage: errorMessage ?? this.errorMessage,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      sensorOrientation: sensorOrientation ?? this.sensorOrientation,
    );
  }
}
