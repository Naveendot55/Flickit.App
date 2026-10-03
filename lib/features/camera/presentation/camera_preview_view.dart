import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../detection/presentation/detection_overlay.dart';
import '../../../shared/widgets/metric_chip.dart';
import '../domain/camera_state.dart';

/// Renders the camera feed with overlaid detection keypoints, bounding boxes,
/// and live detection status chips.
class CameraPreviewView extends ConsumerWidget {
  final VoidCallback? onRetryPermission;

  const CameraPreviewView({super.key, this.onRetryPermission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraService = ref.watch(cameraServiceProvider);
    final trainerState = ref.watch(trainerControllerProvider);

    final controller = cameraService.controller;
    final isCameraReady = controller != null && controller.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF0F1420),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Live Feed or Placeholder
            if (isCameraReady)
              CameraPreview(controller)
            else
              _buildPlaceholder(context, trainerState.errorMessage),

            // 2. CustomPainter for Pose Skeleton, Football Bounding Box, Contact Zone
            if (isCameraReady)
              CustomPaint(
                painter: DetectionOverlayPainter(
                  detection: trainerState.latestDetection,
                  tapState: trainerState.tapState,
                  isDebugMode: trainerState.isDebugMode,
                  imageSize:
                      controller.value.previewSize ?? const Size(640, 640),
                  sensorOrientation:
                      cameraService.currentDescription?.sensorOrientation ?? 90,
                  isFrontCamera:
                      cameraService.currentDescription?.lensDirection ==
                      CameraLensDirection.front,
                ),
              ),

            // 3. Top Detection Entity Chips
            Positioned(
              top: 14,
              left: 12,
              right: 12,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    MetricChip(
                      label: 'PERSON',
                      isDetected:
                          trainerState.latestDetection?.hasPerson ?? false,
                    ),
                    const SizedBox(width: 6),
                    MetricChip(
                      label: 'BALL',
                      isDetected:
                          trainerState.latestDetection?.hasBall ?? false,
                      activeColor: const Color(0xFFFF9100),
                    ),
                    const SizedBox(width: 6),
                    MetricChip(
                      label: 'LEFT FOOT',
                      isDetected:
                          trainerState.latestDetection?.hasLeftFoot ?? false,
                      activeColor: const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 6),
                    MetricChip(
                      label: 'RIGHT FOOT',
                      isDetected:
                          trainerState.latestDetection?.hasRightFoot ?? false,
                    ),
                  ],
                ),
              ),
            ),

            // 4. Center / Bottom Live Status Pill (● Tracking / ○ Ball not detected)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(trainerState.statusMessage)
                          .withOpacity(0.6),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(trainerState.statusMessage),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trainerState.statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String msg) {
    if (msg.contains('Tracking')) return const Color(0xFF00FFA3);
    if (msg.contains('not detected') || msg.contains('unavailable')) {
      return const Color(0xFFFF9100);
    }
    return const Color(0xFF00E5FF);
  }

  Widget _buildPlaceholder(BuildContext context, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              size: 48,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(
              error ?? 'Initializing camera sensor...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (error != null && onRetryPermission != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetryPermission,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Grant Camera Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFF00FFA3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
