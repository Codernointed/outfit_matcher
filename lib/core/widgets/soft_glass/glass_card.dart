import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';

/// Glassmorphism 2.0 frosted panel.
///
/// Layers (bottom -> top):
///   1. [BackdropFilter] gaussian blur on the painted content behind the card
///   2. semi-transparent fill in the active brightness's glass color
///   3. optional warm/rose tint gradient
///   4. 1px luminous border to simulate light catching the glass edge
///   5. child content
///
/// Performance notes:
///   - Always wrapped in a [ClipRRect] so the blur doesn't bleed.
///   - Avoid placing inside a [ListView]; use [SoftCard] for list items instead.
///   - Wrap in a [RepaintBoundary] when used near animated content.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blurSigma,
    this.fillOpacity,
    this.borderOpacity,
    this.tint = GlassTint.none,
    this.tintOpacity = 0.35,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.shadow = GlassShadow.floating,
    this.strong = false,
    this.border = true,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;

  /// Override blur sigma. Defaults to [VestiqSoftTheme.glassBlurMedium].
  final double? blurSigma;

  /// Override fill opacity. Defaults to theme's glass fill opacity.
  final double? fillOpacity;

  /// Override border opacity. Defaults to theme's glass border opacity.
  final double? borderOpacity;

  final GlassTint tint;
  final double tintOpacity;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final GlassShadow shadow;

  /// Use the higher fill opacity for situations that need extra legibility
  /// (e.g. modals, sheets, primary nav).
  final bool strong;

  final bool border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = fillOpacity ??
        (strong ? soft.glassFillOpacityStrong : soft.glassFillOpacity);
    final borderOp = borderOpacity ?? soft.glassBorderOpacity;
    final blur = blurSigma ?? soft.glassBlurMedium;

    final fillColor = soft.glassFill.withValues(alpha: fill);
    final borderColor = soft.glassBorder.withValues(alpha: borderOp);

    Color? tintColor;
    switch (tint) {
      case GlassTint.warm:
        tintColor = soft.glassTintWarm.withValues(alpha: tintOpacity);
        break;
      case GlassTint.rose:
        tintColor = soft.glassTintRose.withValues(alpha: tintOpacity);
        break;
      case GlassTint.none:
        tintColor = null;
        break;
    }

    final shadows = switch (shadow) {
      GlassShadow.none => const <BoxShadow>[],
      GlassShadow.soft => soft.cardSoftShadow,
      GlassShadow.floating => soft.glassFloatingShadow,
    };

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: tintColor == null
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tintColor.withValues(alpha: tintOpacity),
                      tintColor.withValues(alpha: tintOpacity * 0.4),
                    ],
                  ),
            border: border
                ? Border.all(
                    color: borderColor,
                    width: isDark ? 0.6 : 1.0,
                  )
                : null,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (shadows.isNotEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: content,
      );
    }

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

    return RepaintBoundary(child: content);
  }
}

/// Optional warm/rose tint applied behind the glass fill.
enum GlassTint { none, warm, rose }

/// Shadow profile applied around the glass card.
enum GlassShadow { none, soft, floating }
