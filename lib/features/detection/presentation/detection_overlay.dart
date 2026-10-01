import 'package:flutter/material.dart';

import '../../../core/utils/coordinate_transformer.dart';
import '../../toe_tap/domain/models/tap_state.dart';
import '../domain/models/detection_result.dart';

/// CustomPainter that renders football bounding box, pose skeleton,
/// foot contact zone, and optional developer debug metrics over the camera preview.
class DetectionOverlayPainter extends CustomPainter {
  final DetectionResult? detection;
  final TapState tapState;
  final bool isDebugMode;
  final Size imageSize;
  final int sensorOrientation;
  final bool isFrontCamera;

  DetectionOverlayPainter({
    required this.detection,
    required this.tapState,
    required this.isDebugMode,
    this.imageSize = const Size(640, 640),
    this.sensorOrientation = 90,
    this.isFrontCamera = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detection == null) return;

    final transformer = CoordinateTransformer(
      imageSize: CanvasSize(imageSize.width, imageSize.height),
      previewSize: CanvasSize(size.width, size.height),
      sensorOrientation: sensorOrientation,
      isFrontCamera: isFrontCamera,
      fillPreview: true,
    );

    // 1. Draw Football and Contact Zone
    if (detection!.ball != null) {
      final ball = detection!.ball!;
      final screenBallCenter = transformer.toScreenPoint(ball.center);
      final screenBallRadius = transformer.toScreenRadius(ball.radius);

      // Contact Zone Circle
      final zonePaint = Paint()
        ..color =
            (tapState == TapState.contact
                    ? const Color(0xFFFF3366)
                    : const Color(0xFF00FFA3))
                .withOpacity(0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(screenBallCenter.x, screenBallCenter.y),
        screenBallRadius * 1.35,
        zonePaint,
      );

      final zoneBorderPaint = Paint()
        ..color =
            (tapState == TapState.contact
                    ? const Color(0xFFFF3366)
                    : const Color(0xFF00FFA3))
                .withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(screenBallCenter.x, screenBallCenter.y),
        screenBallRadius * 1.35,
        zoneBorderPaint,
      );

      // Ball Outer Ring
      final ballPaint = Paint()
        ..color = const Color(0xFFFF9100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(
        Offset(screenBallCenter.x, screenBallCenter.y),
        screenBallRadius,
        ballPaint,
      );

      // Ball Center Point
      final ballCenterPaint = Paint()
        ..color = const Color(0xFFFF9100)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(screenBallCenter.x, screenBallCenter.y),
        4.0,
        ballCenterPaint,
      );

      // Ball Label
      _drawText(
        canvas,
        '⚽ BALL (${(ball.confidence * 100).toInt()}%)',
        Offset(
          screenBallCenter.x - 45,
          screenBallCenter.y - screenBallRadius - 22,
        ),
        const Color(0xFFFF9100),
      );
    }

    // 2. Draw Person Skeleton & Feet Keypoints
    if (detection!.pose != null) {
      final pose = detection!.pose!;

      // Left Foot (Cyan)
      if (pose.leftFootPoint != null && pose.leftFootConfidence >= 0.25) {
        final screenLeft = transformer.toScreenPoint(pose.leftFootPoint!);
        _drawKeypoint(
          canvas,
          screenLeft,
          const Color(0xFF00E5FF),
          'L FOOT',
          pose.leftFootConfidence,
        );

        // Draw line from Knee to Ankle if Knee is available
        if (pose.leftKnee != null && pose.leftKneeConfidence >= 0.25) {
          final screenKnee = transformer.toScreenPoint(pose.leftKnee!);
          _drawLine(
            canvas,
            screenKnee,
            screenLeft,
            const Color(0xFF00E5FF).withOpacity(0.6),
          );
        }
      }

      // Right Foot (Neon Green)
      if (pose.rightFootPoint != null && pose.rightFootConfidence >= 0.25) {
        final screenRight = transformer.toScreenPoint(pose.rightFootPoint!);
        _drawKeypoint(
          canvas,
          screenRight,
          const Color(0xFF00FFA3),
          'R FOOT',
          pose.rightFootConfidence,
        );

        // Draw line from Knee to Ankle if Knee is available
        if (pose.rightKnee != null && pose.rightKneeConfidence >= 0.25) {
          final screenKnee = transformer.toScreenPoint(pose.rightKnee!);
          _drawLine(
            canvas,
            screenKnee,
            screenRight,
            const Color(0xFF00FFA3).withOpacity(0.6),
          );
        }
      }
    }

    // 3. Optional Debug Overlay Box
    if (isDebugMode) {
      _drawDebugPanel(canvas, size);
    }
  }

  void _drawKeypoint(
    Canvas canvas,
    dynamic point,
    Color color,
    String label,
    double conf,
  ) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pGlow = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final offset = Offset(point.x, point.y);
    canvas.drawCircle(offset, 14.0, pGlow);
    canvas.drawCircle(offset, 6.0, p);

    _drawText(
      canvas,
      '$label (${(conf * 100).toInt()}%)',
      Offset(point.x - 25, point.y + 12),
      color,
    );
  }

  void _drawLine(Canvas canvas, dynamic p1, dynamic p2, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paint);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withOpacity(0.65),
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, position);
  }

  void _drawDebugPanel(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(12, size.height - 180, 220, 160);
    final bgPaint = Paint()..color = const Color(0xE60A0D14);
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    final leftConf = detection?.pose?.leftFootConfidence ?? 0.0;
    final rightConf = detection?.pose?.rightFootConfidence ?? 0.0;
    final ballConf = detection?.ball?.confidence ?? 0.0;
    final latency = detection?.inferenceTime.inMilliseconds ?? 0;

    final debugInfo =
        '''
=== VISION DEBUG ===
Latency: ${latency}ms
State: ${tapState.displayName}
Ball Conf: ${(ballConf * 100).toStringAsFixed(1)}%
L-Foot Conf: ${(leftConf * 100).toStringAsFixed(1)}%
R-Foot Conf: ${(rightConf * 100).toStringAsFixed(1)}%
Ball Detected: ${detection?.ball != null ? "YES" : "NO"}
Person Detected: ${detection?.person != null ? "YES" : "NO"}
''';

    final span = TextSpan(
      text: debugInfo,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontSize: 10.5,
        fontFamily: 'monospace',
        height: 1.3,
      ),
    );

    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout(maxWidth: 200);

    tp.paint(canvas, const Offset(20, 12 + 10));
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) => true;
}
