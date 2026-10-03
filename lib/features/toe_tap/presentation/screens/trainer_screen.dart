import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../camera/presentation/camera_preview_view.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../controllers/trainer_controller.dart';
import '../controllers/trainer_state.dart';
import '../widgets/animated_counter.dart';
import '../widgets/tap_indicator.dart';

/// Main sports-tech training screen for the Flickit Toe Tap Counter.
class TrainerScreen extends ConsumerStatefulWidget {
  const TrainerScreen({super.key});

  @override
  ConsumerState<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends ConsumerState<TrainerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize camera and detector on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerControllerProvider.notifier).initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(trainerControllerProvider.notifier).handleLifecycleChange(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trainerState = ref.watch(trainerControllerProvider);
    final controller = ref.read(trainerControllerProvider.notifier);

    final isRunning = trainerState.status == AppStatus.running;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              // 1. TOP HEADER
              _buildHeader(context, trainerState, controller),

              const SizedBox(height: 10),

              // 2. CAMERA FEED WITH DETECTION OVERLAY
              Expanded(
                flex: 5,
                child: CameraPreviewView(
                  onRetryPermission: () => controller.initialize(),
                ),
              ),

              const SizedBox(height: 12),

              // 3. TAP FEEDBACK NOTIFICATION
              TapIndicator(
                visible: trainerState.showTapAnimation,
                foot: trainerState.lastTapFoot,
              ),

              const SizedBox(height: 8),

              // 4. HERO TOE TAP COUNTER & STATS
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  children: [
                    AnimatedCounter(
                      count: trainerState.tapCount,
                      leftCount: trainerState.leftTapCount,
                      rightCount: trainerState.rightTapCount,
                      tapsPerMin: trainerState.tapsPerMinute,
                      animateTap: trainerState.showTapAnimation,
                    ),
                    const SizedBox(height: 10),
                    // Diagnostics: FPS & Latency
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricPill(
                          'FPS',
                          trainerState.fps > 0
                              ? trainerState.fps.toStringAsFixed(1)
                              : '--',
                          const Color(0xFF00FFA3),
                        ),
                        Container(
                          height: 14,
                          width: 1,
                          color: Colors.white.withOpacity(0.12),
                        ),
                        _buildMetricPill(
                          'LATENCY',
                          '${trainerState.latencyMs}ms',
                          const Color(0xFF00E5FF),
                        ),
                        Container(
                          height: 14,
                          width: 1,
                          color: Colors.white.withOpacity(0.12),
                        ),
                        _buildMetricPill(
                          'STATUS',
                          trainerState.status.displayName,
                          trainerState.status == AppStatus.running
                              ? const Color(0xFF00FFA3)
                              : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 5. BOTTOM CONTROLS (START / STOP, RESET, DEBUG)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: isRunning ? 'STOP' : 'START',
                      icon: isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      variant: isRunning
                          ? ButtonVariant.danger
                          : ButtonVariant.primary,
                      onPressed: () {
                        if (isRunning) {
                          controller.stopTraining();
                        } else {
                          controller.startTraining();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: AppButton(
                      label: 'RESET',
                      icon: Icons.refresh_rounded,
                      variant: ButtonVariant.secondary,
                      onPressed: () => controller.resetTraining(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TrainerState state,
    TrainerController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Flickit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('⚽', style: TextStyle(fontSize: 18)),
              ],
            ),
            const Text(
              'TOE TAP TRAINER',
              style: TextStyle(
                color: Color(0xFF00FFA3),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Model Mode Toggle (Prod vs Dev Mock)
            GestureDetector(
              onTap: () => controller.toggleDetector(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isUsingMockDetector
                      ? const Color(0xFFFF9100).withOpacity(0.18)
                      : const Color(0xFF00FFA3).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isUsingMockDetector
                        ? const Color(0xFFFF9100).withOpacity(0.5)
                        : const Color(0xFF00FFA3).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  state.isUsingMockDetector ? 'DEV MODE' : 'PROD MODEL',
                  style: TextStyle(
                    color: state.isUsingMockDetector
                        ? const Color(0xFFFF9100)
                        : const Color(0xFF00FFA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Debug Mode Toggle
            IconButton(
              onPressed: () => controller.toggleDebug(),
              icon: Icon(
                Icons.bug_report_rounded,
                color: state.isDebugMode
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              tooltip: 'Toggle Debug Overlay',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

extension AppStatusExt on AppStatus {
  String get displayName {
    switch (this) {
      case AppStatus.idle:
        return 'IDLE';
      case AppStatus.initializing:
        return 'INIT';
      case AppStatus.ready:
        return 'READY';
      case AppStatus.running:
        return 'RUNNING';
      case AppStatus.paused:
        return 'PAUSED';
      case AppStatus.error:
        return 'ERROR';
    }
  }
}
