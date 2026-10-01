import 'package:flutter/material.dart';

enum ButtonVariant { primary, danger, secondary }

/// An interactive sports-tech action button with touch bounce animation.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  LinearGradient get _gradient {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return const LinearGradient(
          colors: [Color(0xFF00FFA3), Color(0xFF00D2FF)],
        );
      case ButtonVariant.danger:
        return const LinearGradient(
          colors: [Color(0xFFFF3366), Color(0xFFFF5252)],
        );
      case ButtonVariant.secondary:
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        );
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return const Color(0xFF0A0D14);
      case ButtonVariant.danger:
      case ButtonVariant.secondary:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _animController.forward() : null,
      onTapUp: isEnabled
          ? (_) {
              _animController.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _animController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.45,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(14),
              border: widget.variant == ButtonVariant.secondary
                  ? Border.all(color: Colors.white.withOpacity(0.18), width: 1)
                  : null,
              boxShadow: [
                if (widget.variant == ButtonVariant.primary && isEnabled)
                  BoxShadow(
                    color: const Color(0xFF00FFA3).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                if (widget.variant == ButtonVariant.danger && isEnabled)
                  BoxShadow(
                    color: const Color(0xFFFF3366).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: _textColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
