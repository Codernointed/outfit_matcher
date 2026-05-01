import 'package:flutter/material.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';

/// Warm linen canvas background with two subtle ambient blobs that give the
/// screen a "lit-from-behind" feel without being distracting. Place this as the
/// first child of a [Stack] or behind a [Scaffold] body to get the airy,
/// premium backdrop the design system calls for.
///
/// The blobs are extremely faint (8-12% alpha) and sit behind a tonal warm
/// gradient so glass surfaces have something to refract.
class VestiqCanvas extends StatelessWidget {
  const VestiqCanvas({
    super.key,
    this.child,
    this.showBlobs = true,
  });

  final Widget? child;

  /// When false, only the warm gradient background is drawn.
  final bool showBlobs;

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                soft.canvas,
                isDark
                    ? soft.canvas
                    : soft.surfaceContainer.withValues(alpha: 0.7),
                soft.canvas,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        if (showBlobs)
          Positioned(
            top: -120,
            right: -80,
            child: _Blob(
              color: soft.glassTintRose,
              size: 320,
              opacity: isDark ? 0.10 : 0.30,
            ),
          ),
        if (showBlobs)
          Positioned(
            bottom: -160,
            left: -100,
            child: _Blob(
              color: soft.glassTintWarm,
              size: 380,
              opacity: isDark ? 0.08 : 0.22,
            ),
          ),
        if (child != null) child!,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
