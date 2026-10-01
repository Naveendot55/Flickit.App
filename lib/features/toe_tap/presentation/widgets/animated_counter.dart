import 'package:flutter/material.dart';

/// Animated sports-tech counter widget with scale and bounce effects on every tap.
class AnimatedCounter extends StatefulWidget {
  final int count;
  final int leftCount;
  final int rightCount;
  final double tapsPerMin;
  final bool animateTap;

  const AnimatedCounter({
    super.key,
    required this.count,
    required this.leftCount,
    required this.rightCount,
    required this.tapsPerMin,
    required this.animateTap,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.28,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.28,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 60,
      ),
    ]).animate(_animController);

    _glowAnimation = ColorTween(
      begin: const Color(0xFF00FFA3),
      end: const Color(0xFF00E5FF),
    ).animate(_animController);
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count && widget.count > 0) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        const Text(
          'TOE TAPS',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),

        // Hero Tap Counter with scale/bounce
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: _glowAnimation.value!.withOpacity(0.6),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Sub-metrics: Left Count | Rate | Right Count
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFootCount('LEFT', widget.leftCount, const Color(0xFF00E5FF)),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 24,
              width: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            Column(
              children: [
                Text(
                  widget.tapsPerMin.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Color(0xFF00FFA3),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'TAPS / MIN',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 24,
              width: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            _buildFootCount(
              'RIGHT',
              widget.rightCount,
              const Color(0xFF00FFA3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFootCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
