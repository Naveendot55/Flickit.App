import 'package:flutter/material.dart';

import '../../domain/models/foot_side.dart';

/// Flashing sports badge indicating a detected tap event with foot side.
class TapIndicator extends StatelessWidget {
  final bool visible;
  final FootSide? foot;

  const TapIndicator({super.key, required this.visible, this.foot});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: visible ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        scale: visible ? 1.0 : 0.8,
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: foot == FootSide.left
                  ? [const Color(0xFF00E5FF), const Color(0xFF0091EA)]
                  : [const Color(0xFF00FFA3), const Color(0xFF00C853)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    (foot == FootSide.left
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF00FFA3))
                        .withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF0A0D14),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'TAP DETECTED! ${foot != null ? '(${foot!.displayName})' : ''}',
                style: const TextStyle(
                  color: Color(0xFF0A0D14),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
