import 'package:flutter/material.dart';

class SoftFadeIn extends StatelessWidget {
  const SoftFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 360),
    this.offset = 14,
  });

  final Widget child;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class AnimatedNavIconFrame extends StatelessWidget {
  const AnimatedNavIconFrame({
    super.key,
    required this.icon,
    required this.active,
  });

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: active ? 0.94 : 1, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF10316B) : const Color(0xFFF4F7FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : const Color(0xFF10316B),
          size: 22,
        ),
      ),
    );
  }
}
