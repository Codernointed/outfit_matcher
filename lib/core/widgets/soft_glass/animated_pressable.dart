import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';

/// A generic press wrapper that adds spring-physics scale-down on touch and
/// spring-back on release. Use this around any interactive surface (cards,
/// chips, list rows, custom buttons) to make taps feel alive.
class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale,
    this.duration = const Duration(milliseconds: 140),
    this.releaseDuration = const Duration(milliseconds: 240),
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Press scale. Defaults to [VestiqSoftTheme.pressScale] (0.96).
  final double? scale;

  final Duration duration;
  final Duration releaseDuration;
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.releaseDuration,
    value: 1.0,
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (widget.haptic) {
      HapticFeedback.selectionClick();
    }
    _controller.animateTo(0.0, curve: Curves.easeOutCubic);
  }

  void _release() {
    _controller.animateTo(1.0, curve: Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    final pressScale = widget.scale ?? context.vestiqSoft.pressScale;
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: widget.onTap == null && widget.onLongPress == null
          ? null
          : (_) => _press(),
      onTapUp: widget.onTap == null && widget.onLongPress == null
          ? null
          : (_) => _release(),
      onTapCancel: widget.onTap == null && widget.onLongPress == null
          ? null
          : _release,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Lerp from 1.0 (released) to pressScale (pressed).
          final scale = 1.0 - (1.0 - pressScale) * (1.0 - _controller.value);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
