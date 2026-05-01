import 'package:flutter/material.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';

/// Soft neumorphic surface -- raised or pressed/inset depending on [depth].
///
/// Use this **sparingly** for tactile interactive controls (buttons, toggles,
/// chips, input wells). For larger panels or floating overlays use [GlassCard]
/// or a flat surface with [VestiqSoftTheme.cardSoftShadow] instead.
///
/// Light source is fixed at top-left across the entire app for visual cohesion.
class SoftSurface extends StatelessWidget {
  const SoftSurface({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.depth = SoftDepth.raised,
    this.intensity = 1.0,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Surface color. Defaults to [VestiqSoftTheme.surfaceContainer] so the
  /// neumorphic shadows blend naturally with the canvas.
  final Color? color;

  final SoftDepth depth;

  /// 0..1 scale on the neumorphic shadow strength.
  final double intensity;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    final fill = color ?? soft.surfaceContainer;

    final shadows = switch (depth) {
      SoftDepth.flat => const <BoxShadow>[],
      SoftDepth.raised => _scaleShadows(soft.neumorphicRaisedShadow, intensity),
      SoftDepth.pressed =>
        _scaleShadows(soft.neumorphicPressedShadow, intensity),
    };

    Widget content = AnimatedContainer(
      duration: soft.springDuration,
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: soft.primary.withValues(alpha: 0.06),
          highlightColor: soft.primary.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }

  static List<BoxShadow> _scaleShadows(
    List<BoxShadow> shadows,
    double intensity,
  ) {
    if (intensity == 1.0) return shadows;
    return shadows
        .map(
          (s) => BoxShadow(
            color: s.color.withValues(alpha: s.color.a * intensity),
            blurRadius: s.blurRadius,
            offset: s.offset,
            spreadRadius: s.spreadRadius,
          ),
        )
        .toList();
  }
}

enum SoftDepth { flat, raised, pressed }
