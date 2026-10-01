import 'package:flutter/material.dart';

/// Compact sports-tech status badge for detection entities.
class MetricChip extends StatelessWidget {
  final String label;
  final bool isDetected;
  final Color activeColor;

  const MetricChip({
    super.key,
    required this.label,
    required this.isDetected,
    this.activeColor = const Color(0xFF00FFA3),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDetected
            ? activeColor.withOpacity(0.15)
            : Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDetected
              ? activeColor.withOpacity(0.6)
              : Colors.white.withOpacity(0.12),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDetected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: isDetected ? activeColor : const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isDetected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
